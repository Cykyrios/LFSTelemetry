class_name LiveDelta
extends Node


var insim: InSim = null
var insim_delta: InSimLiveDelta = null

var reference_lap: LapData = null:
	set(lap):
		if lap and lap != reference_lap:
			clear_deltas()
		reference_lap = lap
		if reference_lap:
			create_deltas()
var current_lap: LapData = null:
	set(lap):
		current_lap = lap
		if reference_lap:
			insim_delta.sector_count = reference_lap.sectors.size()

var times: Array[float] = []
var deltas: Array[float] = []
var sector_count := 0
var current_sector := 0:
	set(sector):
		while sector > deltas.size():
			deltas.append(0)
		current_sector = sector

var freeze_lap_delta := false
var freeze_lap_delay := 5.0

var display_timer := Timer.new()


func _init(insim_instance: InSim) -> void:
	insim = insim_instance
	insim_delta = InSimLiveDelta.new(insim_instance)


func _ready() -> void:
	add_child(insim_delta)
	var _discard := display_timer.timeout.connect(update_displayed_delta)
	_discard = display_timer.timeout.connect(_on_display_timer_timeout)
	add_child(display_timer)
	display_timer.start(0.1)

	_discard = insim.connected.connect(func() -> void:
		await insim.isp_ver_received
		insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_RST))
		await insim.isp_rst_received
		insim_delta.initialize_buttons())
	_discard = insim.isp_rst_received.connect(_on_rst_received)


func clear_deltas() -> void:
	deltas.clear()


func create_deltas() -> void:
	deltas.append(360_000)
	if reference_lap:
		for sector in reference_lap.sectors:
			deltas.append(360_000)
		insim_delta.sector_count = reference_lap.sectors.size()


func freeze_delta_updates() -> void:
	freeze_lap_delta = true
	await get_tree().create_timer(freeze_lap_delay).timeout
	freeze_lap_delta = false


func update_displayed_delta() -> void:
	if freeze_lap_delta:
		return
	insim_delta.update_lap_data(insim_delta.CURRENT_LAP_COLUMN, times, current_sector)
	insim_delta.update_delta(deltas, current_sector)


func update_lap() -> void:
	update_sector()
	times[0] = current_lap.lap_time
	for sector in current_lap.sectors:
		times[sector.sector_number] = sector.sector_time
	insim_delta.update_lap_data(insim_delta.PREVIOUS_LAP_COLUMN, times)
	update_displayed_delta()
	insim_delta.clear_lap_data(insim_delta.CURRENT_LAP_COLUMN)
	freeze_delta_updates()
	current_sector = 1
	if not reference_lap or current_lap.lap_time < reference_lap.lap_time:
		reference_lap = current_lap.duplicate()
		insim_delta.update_lap_data(insim_delta.BEST_LAP_COLUMN, times)
	times.fill(360_000)


func update_sector() -> void:
	var sector := current_lap.sectors[-1]
	var sector_number := sector.sector_number
	var sector_time := sector.sector_time
	current_sector = wrapi(sector_number + 1, 0, sector_count + 1)
	deltas[sector_number] = 360_000.0 if not reference_lap \
			else (sector_time - reference_lap.sectors[sector_number - 1].sector_time)
	times[sector_number] = sector_time
	insim_delta.update_lap_data(insim_delta.CURRENT_LAP_COLUMN, times, current_sector)


func update_live_delta() -> void:
	if freeze_lap_delta:
		return
	if not reference_lap or not current_lap:
		return
	var current_data := current_lap.outsim_data
	if current_data.is_empty():
		return
	if deltas.is_empty():
		create_deltas()
	var current_time := current_data[-1].outsim_pack.gis_time \
			- current_data[0].outsim_pack.gis_time
	var current_distance := current_data[-1].outsim_pack.current_lap_distance
	var reference_idx := -1
	var reference_distance := 0.0
	var reference_data := reference_lap.outsim_data
	while (
		reference_idx < reference_lap.outsim_data.size() - 1
		and reference_distance < current_distance
	):
		reference_idx += 1
		reference_distance = reference_data[reference_idx].outsim_pack.current_lap_distance
	var reference_time := reference_data[reference_idx].outsim_pack.gis_time \
			- reference_data[0].outsim_pack.gis_time
	times[0] = current_time
	times[current_sector] = current_time
	if current_sector > 1:
			times[current_sector] -= current_lap.sectors[current_sector - 2].split_time
	deltas[0] = current_time - reference_time


func _on_display_timer_timeout() -> void:
	display_timer.start(randf_range(0.08, 0.12))


func _on_rst_received(packet: InSimRSTPacket) -> void:
	var num_sectors := 1
	for split in [packet.split1, packet.split2, packet.split3] as Array[int]:
		if split != 0 and split != 65535:
			num_sectors += 1
	sector_count = num_sectors
	var _discard := times.resize(sector_count + 1)
	_discard = deltas.resize(sector_count + 1)
	insim_delta.sector_count = sector_count
