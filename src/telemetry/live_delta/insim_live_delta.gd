class_name InSimLiveDelta
extends Node


const NO_TIME := 360_000

const FIELDS_PER_ROW := 5
const BEST_LAP_COLUMN := 1
const PREVIOUS_LAP_COLUMN := 2
const CURRENT_LAP_COLUMN := 3
const DELTA_COLUMN := 4

var insim: InSim = null

var sector_count := 0:
	set(count):
		if count != sector_count and buttons_enabled:
			clear_buttons()
			sector_count = count
			show_buttons()
		sector_count = count

var first_button_idx := 0
var buttons_enabled := false
var delta_position := Vector2i(50, -10)
var anchor_left := true
var anchor_top := false

var margin := 1
var button_height := 4
var label_column_width := 5
var best_lap_width := 8
var previous_lap_width := 8
var current_lap_width := 8
var delta_width := 6

var text_color_ahead := LFSText.ColorCode.GREEN
var text_color_behind := LFSText.ColorCode.RED
var text_color_standard := LFSText.ColorCode.WHITE
var text_color_pending := LFSText.ColorCode.DEFAULT


func _init(insim_instance: InSim) -> void:
	insim = insim_instance


func clear_buttons() -> void:
	var packet := InSimBFNPacket.new()
	packet.subtype = InSim.ButtonFunction.BFN_CLEAR
	insim.send_packet(packet)
	buttons_enabled = false


func clear_lap_data(column: int) -> void:
	var times: Array[float] = []
	var _discard := times.resize(sector_count + 1)
	times.fill(NO_TIME)
	update_lap_data(column, times)


func create_button(
		id: int, left: int, top: int, width: int, height: int, button_style: int, text := ""
) -> InSimBTNPacket:
	var packet := InSimBTNPacket.new()
	packet.req_i = 1
	packet.click_id = first_button_idx + id
	packet.left = left
	packet.top = top
	packet.width = width
	packet.height = height
	packet.button_style = button_style
	packet.text = text
	return packet


func initialize_buttons() -> void:
	buttons_enabled = true
	var total_width := 2 * margin + label_column_width + best_lap_width \
			+ previous_lap_width + current_lap_width + delta_width
	var total_height := 2 * margin + (sector_count + 2) * button_height
	var position_left := (InSim.ButtonPosition.X_MIN + delta_position.x) if anchor_left \
			else (InSim.ButtonPosition.X_MAX + delta_position.x - total_width)
	var position_top := (InSim.ButtonPosition.Y_MIN + delta_position.y) if anchor_top \
			else (InSim.ButtonPosition.Y_MAX + delta_position.y - total_height)
	insim.send_packet(create_button(0, position_left, position_top, total_width, total_height,
			InSim.ButtonStyle.ISB_LIGHT))
	for row in sector_count + 2:
		var current_x_pos := margin
		for col in FIELDS_PER_ROW:
			var button_text := "^%d" % [text_color_standard]
			if row == 0:
				button_text += "Best" if col == 1 else "Previous" if col == 2 \
						else "Current" if col == 3 else "Delta"
			elif row == 1 and col == 0:
				button_text += "Lap"
			elif col == 0:
				button_text += "S%d" % [row - 1]
			else:
				button_text = "^%d---" % [text_color_pending]

			var current_width := label_column_width if col == 0 \
					else best_lap_width if col == BEST_LAP_COLUMN \
					else previous_lap_width if col == PREVIOUS_LAP_COLUMN \
					else current_lap_width if col == CURRENT_LAP_COLUMN \
					else delta_width
			if row == 0 and col == 0:
				current_x_pos += current_width
				continue
			insim.send_packet(create_button(
				row * FIELDS_PER_ROW + col,
				position_left + current_x_pos,
				position_top + margin + row * button_height,
				current_width,
				button_height,
				InSim.ButtonStyle.ISB_DARK,
				button_text
			))
			current_x_pos += current_width


func show_buttons() -> void:
	buttons_enabled = true
	initialize_buttons()


func update_button_text(button_id: int, text: String) -> void:
	var packet := InSimBTNPacket.new()
	packet.req_i = 1
	packet.click_id = first_button_idx + button_id
	packet.text = text
	insim.send_packet(packet)


func update_lap_data(column: int, times: Array[float], current_sector := 0) -> void:
	for i in times.size():
		var time := times[i]
		var time_string := ("^%d---" % [text_color_pending]) if time == NO_TIME \
				else "^%d%s" % [text_color_pending if current_sector != 0 \
				and (i == 0 or i == current_sector) else text_color_standard,
				GISUtils.get_time_string_from_seconds(time, 2, true)
		]
		update_button_text((i + 1) * FIELDS_PER_ROW + column, time_string)


func update_delta(deltas: Array[float], current_sector := 0) -> void:
	for i in deltas.size():
		var delta := deltas[i]
		var delta_string := "^%d---" % [text_color_pending]
		if not is_equal_approx(delta, NO_TIME):
			var text_color := text_color_standard
			if i == 0:
				text_color = text_color_behind if delta > 0 else text_color_ahead
			elif i == current_sector:
				text_color = text_color_pending
			delta_string = "^%d%s" % [text_color,
					GISUtils.get_time_string_from_seconds(delta, 2, true, true)]
		update_button_text((i + 1) * FIELDS_PER_ROW + DELTA_COLUMN, delta_string)
