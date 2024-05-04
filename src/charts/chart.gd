class_name Chart
extends GridContainer


const AXIS_PADDING := Vector2(60, 25)

var font := preload("res://src/charts/RecursiveSansLnrSt-Regular.otf")

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


func _ready() -> void:
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
	edge_top.custom_minimum_size = AXIS_PADDING * Vector2(0, 1)
	edge_left.custom_minimum_size = AXIS_PADDING * Vector2(1, 0)
	edge_right.custom_minimum_size = AXIS_PADDING * Vector2(1, 0)
	edge_bottom.custom_minimum_size = AXIS_PADDING * Vector2(0, 1)
	chart_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	chart_area.chart_data = chart_data


func _draw() -> void:
	for axis: Axis in [x_axis_primary, x_axis_secondary]:
		if axis:
			axis.figure_size = chart_area.size.x
	for axis: Axis in [y_axis_primary, y_axis_secondary]:
		if axis:
			axis.figure_size = chart_area.size.y
	var x_axes: Array[Axis] = []
	var y_axes: Array[Axis] = []
	for series in chart_data:
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		var offset := Vector2.ZERO
		var tick_offset := 3
		var tick_size := 4
		var direction := 1
		var opposite_label := 0
		var font_size := 12
		if x_axes.find(x_axis) < 0:
			x_axes.append(x_axis)
			var locations := x_axis.major_ticks.locator.get_tick_locations()
			var values := x_axis.major_ticks.locator.get_tick_values(x_axis.view_min, x_axis.view_max)
			var labels := x_axis.major_ticks.formatter.format_ticks(values)
			if x_axis.position == Axis.Position.BOTTOM_LEFT:
				offset = edge_bottom.position
			else:
				offset = edge_top.position
				direction = -1
			for i in labels.size():
				var axis_pos := remap(locations[i], x_axis.view_min, x_axis.view_max,
						0, chart_area.size.x)
				if axis_pos < 0 or axis_pos > chart_area.size.x:
					continue
				var text := TextLine.new()
				var _discard := text.add_string(labels[i], font, font_size)
				var pos := Vector2(offset.x + axis_pos, offset.y)
				draw_line(pos, pos + Vector2(0, direction * tick_size), Color.WHITE)
				var label_offset := pos + Vector2(
					-text.get_line_width() / 2,
					direction * (tick_size + tick_offset) - opposite_label * (
							text.get_line_ascent() + text.get_line_descent())
				)
				text.draw(get_canvas_item(), label_offset)
		if y_axes.find(y_axis) < 0:
			y_axes.append(y_axis)
			var locations := y_axis.major_ticks.locator.get_tick_locations()
			var values := y_axis.major_ticks.locator.get_tick_values(y_axis.view_min, y_axis.view_max)
			var labels := y_axis.major_ticks.formatter.format_ticks(values)
			if y_axis.position == Axis.Position.BOTTOM_LEFT:
				offset = edge_left.position + edge_left.size * Vector2(1, 0)
				direction = -1
				opposite_label = 1
			else:
				offset = edge_right.position
			for i in labels.size():
				var axis_pos := remap(locations[i], y_axis.view_min, y_axis.view_max,
						chart_area.size.y, 0)
				if axis_pos < 0 or axis_pos > chart_area.size.y:
					continue
				var text := TextLine.new()
				var _discard := text.add_string(labels[i], font, font_size)
				var pos := Vector2(offset.x, offset.y + axis_pos)
				draw_line(pos, pos + Vector2(direction * tick_size, 0), Color.WHITE)
				var label_offset := Vector2(
					direction * (tick_offset + tick_size) - opposite_label * text.get_line_width(),
					-text.get_line_ascent() / 2
				)
				text.draw(get_canvas_item(), pos + label_offset)


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
