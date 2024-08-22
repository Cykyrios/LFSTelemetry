class_name LiveDelta
extends Node


const NO_TIME := 360_000

var insim: InSim = null
var insim_delta: InSimLiveDelta = null

var recording := false:
	set(value):
		if value == true:
			_on_display_timer_timeout()
		recording = value
var previous_lap_is_best := false

var reference_lap: LapData = null:
	set(lap):
		if lap and lap != reference_lap:
			clear_deltas()
		reference_lap = lap
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
	var _discard := deltas.resize(sector_count + 1)
	deltas.fill(NO_TIME)


func freeze_delta_updates() -> void:
	var previous_lap_times := times.duplicate()
	freeze_lap_delta = true
	await get_tree().create_timer(freeze_lap_delay).timeout
	insim_delta.update_lap_data(insim_delta.PREVIOUS_LAP_COLUMN, previous_lap_times)
	if previous_lap_is_best:
		insim_delta.update_lap_data(insim_delta.BEST_LAP_COLUMN, previous_lap_times)
	insim_delta.clear_lap_data(insim_delta.CURRENT_LAP_COLUMN)
	clear_deltas()
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
	insim_delta.update_lap_data(insim_delta.CURRENT_LAP_COLUMN, times)
	if reference_lap:
		deltas[0] = current_lap.lap_time - reference_lap.lap_time
	else:
		deltas[0] = NO_TIME
	update_displayed_delta()
	freeze_delta_updates()
	current_sector = 1
	if not reference_lap or current_lap.lap_time < reference_lap.lap_time:
		previous_lap_is_best = true
		reference_lap = current_lap.duplicate()
	else:
		previous_lap_is_best = false
	times.fill(NO_TIME)


func update_sector() -> void:
	var sector := current_lap.sectors[-1]
	var sector_number := sector.sector_number
	var sector_time := sector.sector_time
	times[sector_number] = sector_time
	current_sector = wrapi(sector_number + 1, 0, sector_count + 1)
	insim_delta.update_lap_data(insim_delta.CURRENT_LAP_COLUMN, times, current_sector)
	if reference_lap:
		var reference_sector_idx := -1
		for idx in reference_lap.sectors.size():
			if reference_lap.sectors[idx].sector_number == sector_number - 1:
				reference_sector_idx = idx
				break
		deltas[sector_number] = (NO_TIME as float) if not reference_lap else (NO_TIME as float) \
				if reference_lap.sectors[reference_sector_idx].sector_time == NO_TIME \
				or sector_time == NO_TIME \
				else (sector_time - reference_lap.sectors[reference_sector_idx].sector_time)
	else:
		deltas[sector_number] = NO_TIME


func update_live_delta() -> void:
	if freeze_lap_delta:
		return
	if not reference_lap or not current_lap:
		return
	var current_data := current_lap.outsim_data
	if current_data.is_empty():
		return
	var current_time := current_data[-1].outsim_pack.gis_time \
			- current_data[0].outsim_pack.gis_time
	var has_indexed_distance := false if is_zero_approx(
			current_data[-1].outsim_pack.indexed_distance) else true
	var current_distance := current_data[-1].outsim_pack.indexed_distance if has_indexed_distance \
			else current_data[-1].outsim_pack.current_lap_distance

	var get_reference_time := func get_reference_time(lap: LapData, distance: float) -> float:
		var outsim_data := lap.outsim_data
		var idx := 0
		while outsim_data[0].outsim_pack.current_lap_distance > 1.5 and not outsim_data.is_empty():
			outsim_data.pop_front()
		if outsim_data.is_empty():
			return NO_TIME
		var half_idx := floori(outsim_data.size() / 2.0)
		var _has_indexed_distance := false if is_zero_approx(
				outsim_data[half_idx].outsim_pack.indexed_distance) else true
		while (
			idx < outsim_data.size() - 1
			and (_has_indexed_distance
					and outsim_data[idx].outsim_pack.indexed_distance < distance
			or not _has_indexed_distance
					and outsim_data[idx].outsim_pack.current_lap_distance < distance)
		):
			idx += 1
		return outsim_data[idx].outsim_pack.gis_time - outsim_data[0].outsim_pack.gis_time

	times[0] = current_time
	times[current_sector] = current_time
	if current_sector > 1:
			times[current_sector] -= current_lap.sectors[current_sector - 2].split_time
	var reference_time := get_reference_time.call(reference_lap, current_distance) as float
	if is_zero_approx(reference_time):
		reference_time = NO_TIME
	deltas[0] = (NO_TIME as float) if reference_time == NO_TIME else (current_time - reference_time)


func _on_display_timer_timeout() -> void:
	if not recording:
		return
	display_timer.start(randf_range(0.08, 0.12))


func _on_rst_received(packet: InSimRSTPacket) -> void:
	var num_sectors := 1
	for split in [packet.split1, packet.split2, packet.split3] as Array[int]:
		if split != 0 and split != 65535:
			num_sectors += 1
	sector_count = num_sectors
	var _discard := times.resize(sector_count + 1)
	times.fill(NO_TIME)
	_discard = deltas.resize(sector_count + 1)
	deltas.fill(NO_TIME)
	insim_delta.sector_count = sector_count
