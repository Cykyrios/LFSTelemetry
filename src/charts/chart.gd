class_name Chart
extends GridContainer


var chart_area := ChartArea.new()
var corner_top_left := Control.new()
var corner_top_right := Control.new()
var corner_bottom_left := Control.new()
var corner_bottom_right := Control.new()
var edge_top := Control.new()
var edge_bottom := Control.new()
var edge_left := Control.new()
var edge_right := Control.new()

var x_axis_primary := Axis.new()
var y_axis_primary := Axis.new()
var x_axis_secondary: Axis = null
var y_axis_secondary: Axis = null

var chart_data: Array[ChartData] = []


func _init() -> void:
	columns = 3
	add_theme_constant_override(&"h_separation", 0)
	add_theme_constant_override(&"v_separation", 0)
	add_child(corner_top_left)
	add_child(edge_top)
	add_child(corner_top_right)
	add_child(edge_left)
	add_child(chart_area)
	add_child(edge_right)
	add_child(corner_bottom_left)
	add_child(edge_bottom)
	add_child(corner_bottom_right)
	chart_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	chart_area.chart_data = chart_data


func add_data(data_x: Array[float], data_y: Array[float], title := "") -> void:
	if title == "":
		title = "Series %d" % [chart_data.size() + 1]
	var data_series := ChartData.new(data_x, data_y, title)
	data_series.set_x_axis(x_axis_primary)
	data_series.set_y_axis(y_axis_primary)
	chart_data.append(data_series)


func add_secondary_x_axis() -> void:
	x_axis_secondary = Axis.new()
	x_axis_secondary.position = Axis.Position.TOP_RIGHT


func add_secondary_y_axis() -> void:
	y_axis_secondary = Axis.new()
	y_axis_secondary.position = Axis.Position.TOP_RIGHT


func clear_chart() -> void:
	chart_data.clear()


func set_chart_data_color(data: ChartData, color: Color) -> void:
	var _discard := data.color_data.resize(data.y_data.size())
	data.color_map = ColorMap.create_from_color_samples([color], 1)
