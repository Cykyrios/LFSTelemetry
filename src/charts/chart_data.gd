class_name ChartData
extends RefCounted


enum PlotType {LINE, SCATTER, BAR}

var title := ""
var x_data: Array[float] = []:
	set(value):
		x_data = value
		update_x_axis_data_limits()
var y_data: Array[float] = []:
	set(value):
		y_data = value
		update_y_axis_data_limits()
var color_data: Array[float] = []:
	set(value):
		color_data = value
		if color_data.is_empty():
			return
		color_min = color_data.min()
		color_max = color_data.max()
var color_map: ColorMap = null
var plot_type := PlotType.LINE

var color_min := 0.0
var color_max := 0.0

var x_axis: AxisX = null
var y_axis: AxisY = null


func _init(data_x: Array[float], data_y: Array[float], series_title := "New Series") -> void:
	x_data = data_x
	y_data = data_y
	title = series_title


func set_x_axis(axis: Axis) -> void:
	x_axis = axis
	update_x_axis_data_limits()


func set_y_axis(axis: Axis) -> void:
	y_axis = axis
	update_y_axis_data_limits()


func update_x_axis_data_limits() -> void:
	if not x_axis or x_data.is_empty():
		return
	x_axis.data_min = x_data.min() as float
	x_axis.data_max = x_data.max() as float


func update_y_axis_data_limits() -> void:
	if not y_axis or y_data.is_empty():
		return
	y_axis.data_min = y_data.min() as float
	y_axis.data_max = y_data.max() as float
