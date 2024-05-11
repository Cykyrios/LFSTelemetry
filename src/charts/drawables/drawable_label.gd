class_name DrawableLabel
extends Drawable


enum AlignHorizontal {LEFT, CENTER, RIGHT}
enum AlignVertical {TOP, CENTER, BOTTOM}

var font: Font = null
var font_size := 10
var text := ""
var color := Color.WHITE

var position := Vector2.ZERO
var position_in_chart_area := false
var relative_position := false

var text_paragraph := TextParagraph.new()
var align_horizontal := AlignHorizontal.CENTER
var align_vertical := AlignVertical.CENTER
var text_alignment := HORIZONTAL_ALIGNMENT_CENTER


func _init(
	_font: Font, _font_size: int, _text: String, _color: Color,
	align_h: AlignHorizontal, align_v: AlignVertical
) -> void:
	font = _font
	font_size = _font_size
	text = _text
	color = _color
	align_horizontal = align_h
	align_vertical = align_v
	var _discard := text_paragraph.add_string(text, font, font_size)
	text_paragraph.alignment = text_alignment


func get_offset() -> Vector2:
	var size := text_paragraph.get_size()
	var offset := Vector2.ZERO
	if align_horizontal == AlignHorizontal.CENTER:
		offset.x -= size.x / 2
	elif align_horizontal == AlignHorizontal.RIGHT:
		offset.x -= size.x
	if align_vertical == AlignVertical.CENTER:
		offset.y -= size.y / 2
	elif align_vertical == AlignVertical.BOTTOM:
		offset.y -= size.y
	return offset
