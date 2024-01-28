class_name Telemetry
extends RefCounted


const INSIM_TIME_OFFSET := 3.0

var player_id := 0
var recorded_laps: Array[LapData] = []
var current_lap: LapData = null
var recording := false


func end_current_lap() -> void:
	EventBus.telemetry_ended.emit()
	recording = false
	current_lap = null
	process_lap_data(recorded_laps[-1])


func process_lap_data(lap: LapData) -> void:
	lap.sort_packets()
	lap.fill_car_data()
	lap.write_to_file("user://telemetry_%s.csv" % [Time.get_datetime_string_from_datetime_dict(
			Time.get_datetime_dict_from_system(), true)])


func save_outgauge_packet(packet: OutGaugePacket) -> void:
	if not current_lap:
		return
	current_lap.outgauge_data.append(packet)


func save_outsim_packet(packet: OutSimPacket) -> void:
	if not current_lap:
		return
	current_lap.outsim_data.append(packet)


func save_sector(packet: InSimSPXPacket) -> void:
	if not current_lap:
		return
	if packet.player_id != player_id:
		return
	var sector_data := SectorData.new()
	sector_data.sector_number = packet.split
	sector_data.split_time = packet.split_time / 1000.0
	var sector_time := sector_data.split_time
	for i in current_lap.sectors.size():
		sector_time -= current_lap.sectors[i].sector_time
	sector_data.sector_time = sector_time
	sector_data.total_time = packet.elapsed_time / 1000.0 + INSIM_TIME_OFFSET
	current_lap.sectors.append(sector_data)


func save_lap(packet: InSimLAPPacket) -> void:
	if not current_lap:
		return
	if packet.player_id != player_id:
		return
	current_lap.lap_number = packet.laps_done
	current_lap.lap_time = packet.lap_time / 1000.0
	current_lap.total_time = packet.elapsed_time / 1000.0 + INSIM_TIME_OFFSET
	var split_packet := InSimSPXPacket.new()
	split_packet.player_id = packet.player_id
	split_packet.split = 0 if current_lap.sectors.is_empty() or current_lap.sectors[-1].sector_number == 0 \
			else current_lap.sectors[-1].sector_number + 1
	split_packet.split_time = packet.lap_time
	split_packet.elapsed_time = packet.elapsed_time
	save_sector(split_packet)


func start_new_lap() -> void:
	EventBus.telemetry_started.emit()
	recording = true
	current_lap = LapData.new()
	recorded_laps.append(current_lap)
