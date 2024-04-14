class_name ChartData
extends RefCounted


var x_data: Array[float] = []:
	set(value):
		x_data = value
		x_min = x_data.min()
		x_max = x_data.max()
var y_data: Array[float] = []:
	set(value):
		y_data = value
		y_min = y_data.min()
		y_max = y_data.max()
var color_data: Array[float] = []:
	set(value):
		color_data = value
		color_min = color_data.min()
		color_max = color_data.max()
var color_map: ColorMap = null

var x_min := 0.0
var x_max := 0.0
var y_min := 0.0
var y_max := 0.0
var color_min := 0.0
var color_max := 0.0


func _init(data_x: Array[float], data_y: Array[float]) -> void:
	x_data = data_x
	y_data = data_y
