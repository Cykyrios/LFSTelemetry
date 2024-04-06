class_name Recorder
extends RefCounted


signal lap_data_written

## Session time vs InSim time offset (ms), usually 3 seconds in practice/quali, variable offset
## in race, should be updated as soon as possible from SPX or LAP packets' elapsed time
var elapsed_time_offset := 0

var player_id := 0
var current_lap: LapData = null
var recording := false
var session_dir := ""

var track := ""
var weather := 0
var wind := 0
var player_name := ""
var car := ""


func delete_previous_lap_data() -> void:
	if current_lap.total_time != 0 and not is_equal_approx(current_lap.total_time, 3600):
		var outgauge_size := 0
		var outsim_size := 0
		for i in current_lap.outsim_data.size():
			outsim_size += 1
			if current_lap.outsim_data[-outsim_size].outsim_pack.time == \
					int(1000 * current_lap.total_time) + elapsed_time_offset:
				break
		for i in current_lap.outgauge_data.size():
			outgauge_size += 1
			if current_lap.outgauge_data[-outgauge_size].time == \
					int(1000 * current_lap.total_time) + elapsed_time_offset:
				break
		if not current_lap.outgauge_data.is_empty():
			current_lap.outgauge_data.reverse()
			var _discard := current_lap.outgauge_data.resize(outgauge_size)
			current_lap.outgauge_data.reverse()
		if not current_lap.outsim_data.is_empty():
			current_lap.outsim_data.reverse()
			var _discard := current_lap.outsim_data.resize(outsim_size)
			current_lap.outsim_data.reverse()
	current_lap.car_data.clear()
	current_lap.date = ""
	current_lap.lap_number = 0
	current_lap.lap_time = 0
	current_lap.total_time = 0
	current_lap.sectors.clear()


func end_current_lap() -> void:
	process_lap_data(current_lap)


func process_lap_data(lap: LapData) -> void:
	var process_data_threaded := func process_data_threaded(lap_data: LapData) -> void:
		lap_data.date = Time.get_datetime_string_from_system(true, true)
		lap_data.track = track
		lap_data.weather = weather
		lap_data.wind = wind
		lap_data.car = car
		lap_data.driver = player_name
		lap_data.sort_packets()
		lap_data.fill_car_data()
		remove_excess_data(lap_data)
		var file_name := "%s %s %s %s" % [track, car, lap_data.date,
				Utils.get_lap_time_string(lap_data.lap_time)]
		lap_data.save_to_file("user://tlm/%s/%s.tlm" % [session_dir, file_name])
		call_deferred("emit_signal", "lap_data_written")
	var thread := Thread.new()
	var _discard := thread.start(process_data_threaded.bind(lap))
	await lap_data_written
	thread.wait_to_finish()
	delete_previous_lap_data()


func remove_excess_data(lap_data: LapData) -> void:
	# Use 50% data point lap distance as reference for first point "overflow".
	# This should work even with partial lap recordings.
	var half_data_index := int(lap_data.car_data.size() / 2.0)
	while lap_data.car_data[0].lap_distance > lap_data.car_data[half_data_index].lap_distance:
		lap_data.car_data.pop_front()
	while lap_data.car_data[-1].lap_distance < lap_data.car_data[half_data_index].lap_distance:
		lap_data.car_data.pop_back()
	if (
		lap_data.car_data[half_data_index].indexed_distance > 0 and
		lap_data.car_data[0].indexed_distance > lap_data.car_data[half_data_index].indexed_distance
		or lap_data.car_data[half_data_index].indexed_distance == 0 and
		lap_data.car_data[0].lap_distance > lap_data.car_data[half_data_index].lap_distance
	):
		lap_data.car_data[0].lap_distance = 0
		lap_data.car_data[0].indexed_distance = 0


func save_outgauge_packet(packet: OutGaugePacket) -> void:
	if not current_lap:
		return
	current_lap.outgauge_data.append(packet)


func save_outsim_packet(packet: OutSimPacket) -> void:
	if not current_lap:
		return
	current_lap.outsim_data.append(packet)


func save_sector(packet: InSimSPXPacket) -> void:
	if not recording or packet.player_id != player_id:
		return
	update_elapsed_time_offset(packet.elapsed_time)
	var sector_data := SectorData.new()
	sector_data.sector_number = packet.split
	sector_data.split_time = packet.split_time / 1000.0
	var sector_time := sector_data.split_time
	for i in current_lap.sectors.size():
		sector_time -= current_lap.sectors[i].sector_time
	sector_data.sector_time = sector_time
	sector_data.total_time = packet.elapsed_time / 1000.0
	current_lap.sectors.append(sector_data)


func save_lap(packet: InSimLAPPacket) -> void:
	if not recording or packet.player_id != player_id:
		return
	update_elapsed_time_offset(packet.elapsed_time)
	current_lap.lap_number = packet.laps_done
	current_lap.lap_time = packet.lap_time / 1000.0
	current_lap.total_time = packet.elapsed_time / 1000.0
	var split_packet := InSimSPXPacket.new()
	split_packet.player_id = packet.player_id
	split_packet.split = 0 if current_lap.sectors.is_empty() or current_lap.sectors[-1].sector_number == 0 \
			else current_lap.sectors[-1].sector_number + 1
	split_packet.split_time = packet.lap_time
	split_packet.elapsed_time = packet.elapsed_time
	save_sector(split_packet)


func start_recording() -> void:
	EventBus.telemetry_started.emit()
	recording = true
	session_dir = "%s %s %s" % [track, car, Time.get_datetime_string_from_system(true, true)]
	var _discard := DirAccess.make_dir_recursive_absolute("user://tlm/%s/" % [session_dir])
	current_lap = LapData.new()


func stop_recording() -> void:
	end_current_lap()
	recording = false
	EventBus.telemetry_ended.emit()


## Updates the session time vs InSim time offset for practice/quali/race sessions, where
## offset is 3 seconds for practice and quali, and a variable amount for races.[br]
## This function relies on being called as soon as a LAP or SPX packet is received,
## with a variable delay assumed to be much less than the rounding performed
## (offset is always an integer amount of seconds).
func update_elapsed_time_offset(elapsed_time: int) -> void:
	if not recording or current_lap.outgauge_data.is_empty():
		return
	if elapsed_time == 3_600_000:
		return
	var outgauge_time := current_lap.outgauge_data[-1].time
	elapsed_time_offset = 1000 * roundi((outgauge_time - elapsed_time) / 1000.0)
