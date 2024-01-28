extends MarginContainer


var insim := InSim.new()
var outgauge := OutGauge.new()
var outsim := OutSim.new()

var outsim_options := 0x1ff

var telemetry := Telemetry.new()

@onready var record_button := %RecordButton as Button


func _ready() -> void:
	add_child(insim)
	add_child(outgauge)
	add_child(outsim)
	initialize_insim()
	initialize_outgauge()
	initialize_outsim()
	connect_signals()


func connect_signals() -> void:
	var _discard := record_button.pressed.connect(_on_record_button_pressed)
	_discard = EventBus.telemetry_started.connect(_on_telemetry_started)
	_discard = EventBus.telemetry_ended.connect(_on_telemetry_ended)

	_discard = insim.isp_lap_received.connect(_on_lap_received)
	_discard = insim.isp_spx_received.connect(_on_split_received)
	_discard = insim.isp_rst_received.connect(_on_race_start_received)
	_discard = insim.isp_sta_received.connect(_on_state_received)
	_discard = insim.small_vta_received.connect(_on_small_vta_received)

	_discard = outgauge.packet_received.connect(_on_outgauge_packet_received)
	_discard = outsim.packet_received.connect(_on_outsim_packet_received)


func initialize_insim() -> void:
	var initialization_data := InSimInitializationData.new()
	initialization_data.i_name = "GIS Telemetry"
	initialization_data.flags |= InSim.InitFlag.ISF_LOCAL
	initialization_data.interval = 1
	insim.initialize(initialization_data)


func initialize_outgauge() -> void:
	outgauge.initialize()


func initialize_outsim() -> void:
	outsim.initialize(outsim_options)

#region callbacks
func _on_record_button_pressed() -> void:
	if telemetry.recording:
		telemetry.end_current_lap()
	else:
		telemetry.start_new_lap()


func _on_telemetry_started() -> void:
	record_button.text = "Stop recording"


func _on_telemetry_ended() -> void:
	record_button.text = "Start recording"

#region InSim/OutSim/OutGauge
func _on_lap_received(packet: InSimLAPPacket) -> void:
	if packet.player_id != telemetry.player_id:
		return
	telemetry.save_lap(packet)
	if telemetry.current_lap:
		telemetry.end_current_lap()
	telemetry.start_new_lap()


func _on_outgauge_packet_received(packet: OutGaugePacket) -> void:
	telemetry.save_outgauge_packet(packet)


func _on_outsim_packet_received(packet: OutSimPacket) -> void:
	telemetry.save_outsim_packet(packet)


func _on_race_start_received(_packet: InSimRSTPacket) -> void:
	if telemetry.recording:
		telemetry.end_current_lap()
	insim.send_state_request()


func _on_small_vta_received(packet: InSimSmallPacket) -> void:
	if not (telemetry.recording):
		return
	if packet.value in [InSim.Vote.VOTE_END, InSim.Vote.VOTE_RESTART, InSim.Vote.VOTE_QUALIFY]:
		telemetry.end_current_lap()


func _on_split_received(packet: InSimSPXPacket) -> void:
	if packet.player_id != telemetry.player_id:
		return
	telemetry.save_sector(packet)


func _on_state_received(packet: InSimSTAPacket) -> void:
	if telemetry.recording:
		return
	telemetry.player_id = packet.view_player_id
#endregion
#endregion
