extends MarginContainer


@export var load_lap_file := false

var insim := InSim.new()
var outgauge := OutGauge.new()
var outsim := OutSim.new()

var recorder := Recorder.new()

var live_delta: LiveDelta = null

@onready var help_button := %HelpButton as Button
@onready var help_popup := %HelpPopup as PopupPanel
@onready var close_help_button := %CloseHelpButton as Button

@onready var insim_address := %InSimAddress as LineEdit
@onready var insim_port := %InSimPort as LineEdit
@onready var outgauge_address := %OutGaugeAddress as LineEdit
@onready var outgauge_port := %OutGaugePort as LineEdit
@onready var outsim_address := %OutSimAddress as LineEdit
@onready var outsim_port := %OutSimPort as LineEdit
@onready var outsim_options := %OutSimOptions as LineEdit
@onready var insim_button := %InSimButton as Button
@onready var insim_status := %ConnectionStatusLabel as RichTextLabel

@onready var driver_button := %DriverButton as Button
@onready var driver_label := %DriverLabel as RichTextLabel
@onready var record_button := %RecordButton as Button


func _ready() -> void:
	connect_signals()
	add_child(insim)
	add_child(outgauge)
	add_child(outsim)

	live_delta = LiveDelta.new(insim)
	add_child(live_delta)


func _exit_tree() -> void:
	close_telemetry()


func close_telemetry() -> void:
	if recorder.recording:
		recorder.stop_recording()
	insim.close()
	outgauge.close()
	outsim.close()
	insim_button.text = "Connect to InSim"


func connect_signals() -> void:
	var _discard := help_button.pressed.connect(show_help)
	_discard = close_help_button.pressed.connect(hide_help)
	_discard = insim_button.pressed.connect(_on_insim_button_pressed)

	_discard = driver_button.pressed.connect(_on_refresh_target_driver_pressed)
	_discard = record_button.pressed.connect(_on_record_button_pressed)
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


func hide_help() -> void:
	help_popup.hide()


func initialize_insim(address := "127.0.0.1", port := 29_999) -> void:
	var initialization_data := InSimInitializationData.new()
	initialization_data.i_name = "GIS Telemetry"
	initialization_data.flags |= InSim.InitFlag.ISF_LOCAL | InSim.InitFlag.ISF_MSO_COLS \
			| InSim.InitFlag.ISF_CON | InSim.InitFlag.ISF_OBH | InSim.InitFlag.ISF_HLV
	insim.initialize(address, port, initialization_data, false, false)


func initialize_outgauge(address := "127.0.0.1", port := 29_998) -> void:
	outgauge.initialize(address, port)


func initialize_outsim(options: int, address := "127.0.0.1", port := 29_997) -> void:
	outsim.initialize(options, address, port)


func initialize_telemetry() -> void:
	initialize_insim()
	initialize_outgauge()
	var outsim_options_value := 0x1ff
	var line_edit_hex_value := outsim_options.text.strip_edges().hex_to_int()
	if outsim_options.text != "" and (outsim_options.text == "0" or line_edit_hex_value != 0):
		outsim_options_value = line_edit_hex_value
	initialize_outsim(outsim_options_value)


func show_help() -> void:
	help_popup.popup_centered()


#region callbacks
func _on_insim_button_pressed() -> void:
	if insim.insim_connected:
		close_telemetry()
		insim_status.text = "Status: [color=ff0000]Disconnected[/color]"
	else:
		initialize_telemetry()


func _on_driver_updated(driver_name: String, car: String) -> void:
	driver_label.text = "Target: %s (%s)" % [LFSText.lfs_colors_to_bbcode(driver_name), car]


func _on_record_button_pressed() -> void:
	if not insim.insim_connected:
		return
	if recorder.recording:
		recorder.stop_recording()
		live_delta.recording = false
	else:
		recorder.start_recording()
		live_delta.recording = true


func _on_refresh_target_driver_pressed() -> void:
	pass
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))


func _on_telemetry_ended() -> void:
	record_button.text = "Start recording"


func _on_telemetry_started() -> void:
	record_button.text = "Stop recording"
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))
#endregion


#region InSim/OutSim/OutGauge
func _on_insim_connected() -> void:
	insim_status.text = "Status: [color=00ff00]Connected[/color]"
	insim_button.text = "Disonnect from InSim"
	await insim.isp_ver_received
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_SST))


func _on_insim_timeout() -> void:
	if recorder.recording:
		recorder.stop_recording()
	close_telemetry()
	insim_status.text = "Status: [color=ff0000]Timed out[/color]"


func _on_lap_received(packet: InSimLAPPacket) -> void:
	if not recorder.recording:
		return
	if packet.plid != recorder.player_id:
		return
	recorder.save_lap(packet)
	if recorder.current_lap:
		if not live_delta.current_lap:
			live_delta.current_lap = recorder.current_lap
		live_delta.update_lap()
		recorder.end_current_lap()


func _on_outgauge_packet_received(packet: OutGaugePacket) -> void:
	recorder.save_outgauge_packet(packet)


func _on_outsim_packet_received(packet: OutSimPacket) -> void:
	recorder.save_outsim_packet(packet)

	if not live_delta.recording:
		return
	if live_delta.current_lap != recorder.current_lap:
		live_delta.current_lap = recorder.current_lap
	live_delta.update_live_delta()


func _on_pitlane_received(packet: InSimPLAPacket) -> void:
	if (
		not recorder.current_lap
		or packet.plid != recorder.player_id
	):
		return
	if packet.fact == InSim.PitLane.PITLANE_EXIT:
		recorder.current_lap.outlap = true
	elif packet.fact < InSim.PitLane.PITLANE_NUM:
		recorder.current_lap.inlap = true


func _on_player_connection_received(packet: InSimNPLPacket) -> void:
	if packet.plid != recorder.player_id:
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
	if packet.value in [InSim.Vote.VOTE_RESTART, InSim.Vote.VOTE_QUALIFY]:
		recorder.end_current_lap()
	elif packet.value == InSim.Vote.VOTE_END:
		recorder.stop_recording()


func _on_split_received(packet: InSimSPXPacket) -> void:
	if packet.plid != recorder.player_id:
		return
	recorder.save_sector(packet)
	if not live_delta.current_lap:
		live_delta.current_lap = recorder.current_lap
	live_delta.update_sector()


func _on_state_received(packet: InSimSTAPacket) -> void:
	recorder.track = packet.track
	recorder.weather = packet.weather
	recorder.wind = packet.wind
	if recorder.recording:
		return
	recorder.player_id = packet.view_plid
	insim.send_packet(InSimTinyPacket.new(1, InSim.Tiny.TINY_NPL))
#endregion
