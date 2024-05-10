class_name DrawableArea
extends Drawable


var axis: Axis = null
var start := 0.0
var end := 0.0
var color := Color.WHITE


func _init(area_axis: Axis, area_start: float, area_end: float, area_color: Color) -> void:
	axis = area_axis
	start = area_start
	end = area_end
	color = area_color
