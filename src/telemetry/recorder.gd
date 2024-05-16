class_name Recorder
extends RefCounted


signal lap_data_written

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
	if current_lap.car_data.is_empty():
		return
	var last_timestamp := current_lap.car_data[-1].timestamp
	var size := current_lap.outsim_data.size()
	for i in size:
		if current_lap.outsim_data[-1 - i].outsim_pack.time <= last_timestamp:
			current_lap.outsim_data = current_lap.outsim_data.slice(size - i - 1)
			break
	size = current_lap.outgauge_data.size()
	for i in size:
		if current_lap.outgauge_data[-1 - i].time <= last_timestamp:
			current_lap.outgauge_data = current_lap.outgauge_data.slice(size - i - 1)
			break
	current_lap.car_data.clear()
	current_lap.date = ""
	current_lap.lap_number = 0
	current_lap.lap_time = 0
	current_lap.total_time = 0
	current_lap.sectors.clear()
	current_lap.inlap = false
	current_lap.outlap = false


func end_current_lap(lap_completed := true) -> void:
	process_lap_data(current_lap, lap_completed)


func process_lap_data(lap: LapData, lap_completed := true) -> void:
	var process_data_threaded := func process_data_threaded(lap_data: LapData) -> void:
		lap_data.date = Time.get_datetime_string_from_system(true, true)
		lap_data.track = track
		lap_data.weather = weather
		lap_data.wind = wind
		lap_data.car = car
		lap_data.driver = player_name
		lap_data.sort_packets()
		lap_data.fill_car_data()
		if lap_completed:
			remove_excess_data(lap_data)
		if (
			lap_data.car_data.size() > 1 and
			(lap_data.car_data[1].indexed_distance > 0 and
			lap_data.car_data[0].indexed_distance > lap_data.car_data[1].indexed_distance
			or lap_data.car_data[1].indexed_distance == 0 and
			lap_data.car_data[0].lap_distance > lap_data.car_data[1].lap_distance)
		):
			lap_data.car_data[0].lap_distance = 0
			lap_data.car_data[0].indexed_distance = 0
		var file_name := "%s %s %s %s" % [track, car, lap_data.date,
				Utils.get_lap_time_string(lap_data.lap_time)]
		if OS.has_feature("windows"):
			file_name = file_name.replace(":", "_")
		var lap_io := LapDataIO.new()
		lap_io.save_lap_file("user://tlm/%s/%s.tlm" % [session_dir, file_name], lap_data)
		call_deferred("emit_signal", "lap_data_written")
	var thread := Thread.new()
	var _discard := thread.start(process_data_threaded.bind(lap))
	await lap_data_written
	thread.wait_to_finish()
	delete_previous_lap_data()


func remove_excess_data(lap_data: LapData) -> void:
	if lap_data.car_data.is_empty():
		return
	var car_data := lap_data.car_data
	for i in car_data.size() - 1:
		if (
			car_data[-1 - i].lap_distance < car_data[-2 - i].lap_distance
			or car_data[-1 - i].lap_distance == 0 and car_data[-2 - i].lap_distance == 0
		):
			var _discard := lap_data.car_data.resize(car_data.size() - i - 1)
			break


func save_lap(packet: InSimLAPPacket) -> void:
	if not recording or packet.player_id != player_id:
		return
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
	var sector_data := SectorData.new()
	sector_data.sector_number = packet.split
	sector_data.split_time = packet.split_time / 1000.0
	var sector_time := sector_data.split_time
	for i in current_lap.sectors.size():
		sector_time -= current_lap.sectors[i].sector_time
	sector_data.sector_time = sector_time
	sector_data.total_time = packet.elapsed_time / 1000.0
	current_lap.sectors.append(sector_data)


func start_recording() -> void:
	EventBus.telemetry_started.emit()
	recording = true
	session_dir = "%s %s %s" % [track, car, Time.get_datetime_string_from_system(true, true)]
	if OS.has_feature("windows"):
		session_dir = session_dir.replace(":", "_")
	var _discard := DirAccess.make_dir_recursive_absolute("user://tlm/%s/" % [session_dir])
	current_lap = LapData.new()


func stop_recording() -> void:
	end_current_lap(false)
	recording = false
	EventBus.telemetry_ended.emit()
