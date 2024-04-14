extends MarginContainer


@export var load_lap_file := false

var insim := InSim.new()
var outgauge := OutGauge.new()
var outsim := OutSim.new()

var outsim_options := 0x1ff

var recorder := Recorder.new()

@onready var record_button := %RecordButton as Button
@onready var target_label := %TargetLabel as RichTextLabel


func _ready() -> void:
	connect_signals()
	add_child(insim)
	add_child(outgauge)
	add_child(outsim)
	initialize_insim()
	initialize_outgauge()
	initialize_outsim()
	print_laps()
	if load_lap_file:
		load_and_draw()


func _exit_tree() -> void:
	insim.close()
	outgauge.close()
	outsim.close()



func load_and_draw() -> void:
	var file_dialog := FileDialog.new()
	add_child(file_dialog)
	file_dialog.min_size = Vector2i(600, 400)
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.current_dir = "user://tlm"
	file_dialog.filters = ["*.tlm ; Telemetry files"]
	file_dialog.popup_centered()
	await file_dialog.file_selected
	var path := file_dialog.current_path
	var lap_io := LapDataIO.new()
	var lap := lap_io.load_lap_file(path)
	target_label.text = "Driver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(lap.driver), lap.car]
	var vbox := VBoxContainer.new()
	add_child(vbox)
	var chart_speed := Chart.new()
	vbox.add_child(chart_speed)
	chart_speed.custom_minimum_size = Vector2(400, 200)
	var chart_rpm := Chart.new()
	vbox.add_child(chart_rpm)
	chart_rpm.custom_minimum_size = Vector2(400, 200)
	var chart_gear := Chart.new()
	vbox.add_child(chart_gear)
	chart_gear.custom_minimum_size = Vector2(400, 200)
	var chart_path := Chart.new()
	vbox.add_child(chart_path)
	chart_path.custom_minimum_size = Vector2(500, 500)
	var get_data := func get_data(data_type: String) -> Array[float]:
		var array: Array[float] = []
		for data in lap.car_data:
			match data_type:
				"time":
					array.append(data.time)
				"distance":
					array.append(data.lap_distance)
				"speed":
					array.append(data.speed)
				"gear":
					array.append(data.gear)
				"rpm":
					array.append(data.rpm)
				"x_pos":
					array.append(data.position.x)
				"y_pos":
					array.append(data.position.y)
				"throttle":
					array.append(data.throttle)
				"brake":
					array.append(data.brake)
				"torque":
					array.append(data.max_torque_at_rpm)
		return array
	chart_speed.add_data(get_data.call("distance") as Array[float], get_data.call("speed") as Array[float])
	var xmin := chart_speed.chart_data[0].x_min
	var xmax := chart_speed.chart_data[0].x_max
	chart_speed.x_plot_min = xmin
	chart_speed.x_plot_max = xmax
	chart_speed.y_plot_min = chart_speed.chart_data[0].y_min
	chart_speed.y_plot_max = chart_speed.chart_data[0].y_max
	chart_rpm.add_data(get_data.call("distance") as Array[float], get_data.call("rpm") as Array[float])
	chart_rpm.x_plot_min = xmin
	chart_rpm.x_plot_max = xmax
	chart_rpm.y_plot_min = chart_rpm.chart_data[0].y_min
	chart_rpm.y_plot_max = chart_rpm.chart_data[0].y_max
	chart_gear.add_data(get_data.call("distance") as Array[float], get_data.call("gear") as Array[float])
	chart_gear.x_plot_min = xmin
	chart_gear.x_plot_max = xmax
	chart_gear.y_plot_min = chart_gear.chart_data[0].y_min
	chart_gear.y_plot_max = chart_gear.chart_data[0].y_max
	chart_rpm.chart_data[0].color_data = chart_gear.chart_data[0].y_data
	chart_rpm.chart_data[0].color_map = ColorMapTurbo.new()
	chart_rpm.chart_data[0].color_map.steps = int(chart_gear.y_plot_max - chart_gear.y_plot_min + 1)
	chart_path.add_data(get_data.call("x_pos") as Array[float], get_data.call("y_pos") as Array[float])
	var color_data: Array[float] = []
	color_data.assign((get_data.call("speed") as Array[float]))
	chart_path.chart_data[0].color_data = color_data
	chart_path.chart_data[0].color_map = ColorMapD3RdYlGn.new()
	var path_min_x := chart_path.chart_data[0].x_min
	var path_min_y := chart_path.chart_data[0].y_min
	var path_max_x := chart_path.chart_data[0].x_max
	var path_max_y := chart_path.chart_data[0].y_max
	chart_path.x_plot_min = path_min_x - 10
	chart_path.x_plot_max = path_min_x + maxf(path_max_x - path_min_x, path_max_y - path_min_y) + 10
	chart_path.y_plot_min = path_min_y - 10
	chart_path.y_plot_max = path_min_y + maxf(path_max_x - path_min_x, path_max_y - path_min_y) + 10
	chart_path.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_speed.queue_redraw()
	chart_rpm.queue_redraw()
	chart_gear.queue_redraw()
	chart_path.queue_redraw()
	var power_chart := Chart.new()
	vbox.add_child(power_chart)
	power_chart.custom_minimum_size = Vector2(500, 300)
	var power_data: Array[float] = []
	var rpm_data := get_data.call("rpm") as Array[float]
	var torque_data := get_data.call("torque") as Array[float]
	var _discard := power_data.resize(rpm_data.size())
	for i in power_data.size():
		power_data[i] = rpm_data[i] * torque_data[i] * 2 * PI / 60 / 1000
	power_chart.add_data(rpm_data, power_data)
	power_chart.x_plot_min = power_chart.chart_data[0].x_min
	power_chart.x_plot_max = power_chart.chart_data[0].x_max
	power_chart.y_plot_min = power_chart.chart_data[0].y_min
	power_chart.y_plot_max = power_chart.chart_data[0].y_max
	power_chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	power_chart.queue_redraw()
	await get_tree().process_frame


func connect_signals() -> void:
	var _discard := record_button.pressed.connect(_on_record_button_pressed)
	_discard = EventBus.telemetry_started.connect(_on_telemetry_started)
	_discard = EventBus.telemetry_ended.connect(_on_telemetry_ended)
	_discard = EventBus.driver_updated.connect(_on_driver_updated)

	_discard = insim.connected.connect(_on_insim_connected)
	_discard = insim.timeout.connect(_on_insim_timeout)
	_discard = insim.isp_lap_received.connect(_on_lap_received)
	_discard = insim.isp_npl_received.connect(_on_player_connection_received)
	_discard = insim.isp_pla_received.connect(_on_pitlane_received)
	_discard = insim.isp_rst_received.connect(_on_race_start_received)
	_discard = insim.isp_spx_received.connect(_on_split_received)
	_discard = insim.isp_sta_received.connect(_on_state_received)
	_discard = insim.small_vta_received.connect(_on_small_vta_received)

	_discard = outgauge.packet_received.connect(_on_outgauge_packet_received)
	_discard = outsim.packet_received.connect(_on_outsim_packet_received)


func initialize_insim() -> void:
	var initialization_data := InSimInitializationData.new()
	initialization_data.i_name = "GIS Telemetry"
	initialization_data.flags |= InSim.InitFlag.ISF_LOCAL | InSim.InitFlag.ISF_MSO_COLS \
			| InSim.InitFlag.ISF_CON | InSim.InitFlag.ISF_OBH | InSim.InitFlag.ISF_HLV
	insim.initialize("127.0.0.1", 29_999, initialization_data, false, false)


func initialize_outgauge() -> void:
	outgauge.initialize()


func initialize_outsim() -> void:
	outsim.initialize(outsim_options)


#region callbacks
func _on_driver_updated(driver_name: String, car: String) -> void:
	target_label.text = "Target: %s (%s)" % [LFSText.lfs_colors_to_bbcode(driver_name), car]


func _on_record_button_pressed() -> void:
	if recorder.recording:
		recorder.stop_recording()
	else:
		recorder.start_recording()


func _on_telemetry_ended() -> void:
	record_button.text = "Start recording"


func _on_telemetry_started() -> void:
	record_button.text = "Stop recording"
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))
#endregion


#region InSim/OutSim/OutGauge
func _on_insim_connected() -> void:
	await insim.isp_ver_received
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))


func _on_insim_timeout() -> void:
	if recorder.recording:
		recorder.stop_recording()


func _on_lap_received(packet: InSimLAPPacket) -> void:
	if not recorder.recording:
		return
	if packet.player_id != recorder.player_id:
		return
	recorder.save_lap(packet)
	if recorder.current_lap:
		recorder.end_current_lap()


func _on_outgauge_packet_received(packet: OutGaugePacket) -> void:
	recorder.save_outgauge_packet(packet)


func _on_outsim_packet_received(packet: OutSimPacket) -> void:
	recorder.save_outsim_packet(packet)


func _on_pitlane_received(packet: InSimPLAPacket) -> void:
	if (
		not recorder.current_lap
		or packet.player_id != recorder.player_id
	):
		return
	if packet.fact == InSim.PitLane.PITLANE_EXIT:
		recorder.current_lap.outlap = true
	elif packet.fact < InSim.PitLane.PITLANE_NUM:
		recorder.current_lap.inlap = true


func _on_player_connection_received(packet: InSimNPLPacket) -> void:
	if packet.player_id != recorder.player_id:
		return
	recorder.player_name = packet.player_name
	recorder.car = packet.car_name
	EventBus.driver_updated.emit(recorder.player_name, recorder.car)


func _on_race_start_received(_packet: InSimRSTPacket) -> void:
	if recorder.recording:
		recorder.end_current_lap()
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))


func _on_small_vta_received(packet: InSimSmallPacket) -> void:
	if not (recorder.recording):
		return
	if packet.value in [InSim.Vote.VOTE_END, InSim.Vote.VOTE_RESTART, InSim.Vote.VOTE_QUALIFY]:
		recorder.end_current_lap()


func _on_split_received(packet: InSimSPXPacket) -> void:
	if packet.player_id != recorder.player_id:
		return
	recorder.save_sector(packet)


func _on_state_received(packet: InSimSTAPacket) -> void:
	recorder.track = packet.track
	recorder.weather = packet.weather
	recorder.wind = packet.wind
	if recorder.recording:
		return
	recorder.player_id = packet.view_player_id
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NPL))
#endregion
