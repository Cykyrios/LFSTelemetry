class_name Chart
extends GridContainer


const AXIS_PADDING := Vector2(60, 25)
const MIN_PADDING := 1 * Vector2.ONE

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

var x_axis_primary := AxisX.new()
var y_axis_primary := AxisY.new()
var x_axis_secondary: AxisX = null
var y_axis_secondary: AxisY = null

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
	edge_top.custom_minimum_size = MIN_PADDING * Vector2(0, 1)
	edge_left.custom_minimum_size = MIN_PADDING * Vector2(1, 0)
	edge_right.custom_minimum_size = MIN_PADDING * Vector2(1, 0)
	edge_bottom.custom_minimum_size = MIN_PADDING * Vector2(0, 1)
	chart_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	chart_area.chart_data = chart_data


func _draw() -> void:
	draw_rect(Rect2(chart_area.position, chart_area.size), Color(0.2, 0.2, 0.2, 1))
	draw_rect(Rect2(chart_area.position, chart_area.size), x_axis_primary.major_tick_color, false, 1)
	var axes: Array[Axis] = [x_axis_primary, y_axis_primary]
	if x_axis_secondary:
		axes.append(x_axis_secondary)
	if y_axis_secondary:
		axes.append(y_axis_secondary)
	for axis in axes:
		if axis is AxisX:
			axis.figure_size = chart_area.size.x
		elif axis is AxisY:
			axis.figure_size = chart_area.size.y
		else:
			push_error("Axis is neither AxisX nor AxisY.")
			axis.figure_size = maxf(chart_area.size.x, chart_area.size.y)
	for series in chart_data:
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		var x_limits := x_axis.major_ticks.locator.view_limits(series.x_data.min() as float,
				series.x_data.max() as float)
		x_axis.set_view_limits(x_limits.x, x_limits.y)
		var y_limits := y_axis.major_ticks.locator.view_limits(series.y_data.min() as float,
				series.y_data.max() as float)
		y_axis.set_view_limits(y_limits.x, y_limits.y)
	for axis in axes:
		var offset := Vector2.ZERO
		var tick_offset := 3
		var tick_size := 6
		var direction := 1
		var opposite_label := 0
		var font_size := 12
		var is_x_axis := false
		if axis is AxisX:
			is_x_axis = true
			if axis.draw_labels:
				if axis.position == Axis.Position.BOTTOM_LEFT:
					edge_bottom.custom_minimum_size = AXIS_PADDING * Vector2(0, 1)
				else:
					edge_top.custom_minimum_size = AXIS_PADDING * Vector2(0, 1)
			if axis.position == Axis.Position.BOTTOM_LEFT:
				offset = edge_bottom.position
			else:
				offset = edge_top.position
				direction = -1
		elif axis is AxisY:
			if axis.draw_labels:
				if axis.position == Axis.Position.BOTTOM_LEFT:
					edge_left.custom_minimum_size = AXIS_PADDING * Vector2(1, 0)
				else:
					edge_right.custom_minimum_size = AXIS_PADDING * Vector2(1, 0)
			if axis.position == Axis.Position.BOTTOM_LEFT:
				offset = edge_left.position + edge_left.size * Vector2(1, 0)
				direction = -1
				opposite_label = 1
			else:
				offset = edge_right.position
		var locator := axis.major_ticks.locator
		if locator is LocatorMaxN:
			(locator as LocatorMaxN).symmetric = axis.symmetric
			var limits := (locator as LocatorMaxN).view_limits(axis.view_min, axis.view_max)
			axis.set_view_limits(limits.x, limits.y)
		var locations := axis.major_ticks.locator.get_tick_locations()
		var values := axis.major_ticks.locator.get_tick_values(axis.view_min, axis.view_max)
		var labels := axis.major_ticks.formatter.format_ticks(values)
		var minor_locations := axis.minor_ticks.locator.get_tick_locations()
		minor_locations = minor_locations.filter(func(value: float) -> bool:
			return not locations.has(value))
		for location in minor_locations:
			var chart_min := 0.0 if is_x_axis else chart_area.size.y
			var chart_max := chart_area.size.x if is_x_axis else 0.0
			var axis_pos := remap(location, axis.view_min, axis.view_max, chart_min, chart_max)
			var chart_limit := chart_area.size.x if is_x_axis else chart_area.size.y
			if axis_pos < 0 or axis_pos > chart_limit:
				continue
			var axis_pos_vector := Vector2(axis_pos, 0) if is_x_axis else Vector2(0, axis_pos)
			var pos := offset + axis_pos_vector
			var line_start := Vector2(pos.x, chart_area.position.y) if is_x_axis \
					else Vector2(chart_area.position.x, pos.y)
			var line_direction := Vector2(0, 1) if is_x_axis else Vector2(1, 0)
			var line_end := line_start + chart_area.size * line_direction
			if axis.draw_grid:
				draw_line(line_start, line_end, axis.minor_tick_color)
			var tick_dimension := direction * tick_size * 2 / 3.0
			var tick_vector := Vector2(0, tick_dimension) if is_x_axis else Vector2(tick_dimension, 0)
			if axis.draw_ticks:
				draw_line(pos, pos + tick_vector, axis.minor_tick_color)
		for i in locations.size():
			var chart_min := 0.0 if is_x_axis else chart_area.size.y
			var chart_max := chart_area.size.x if is_x_axis else 0.0
			var axis_pos := remap(locations[i], axis.view_min, axis.view_max, chart_min, chart_max)
			var chart_limit := chart_area.size.x if is_x_axis else chart_area.size.y
			if axis_pos < 0 or axis_pos > chart_limit:
				continue
			var axis_pos_vector := Vector2(axis_pos, 0) if is_x_axis else Vector2(0, axis_pos)
			var pos := offset + axis_pos_vector
			var line_start := Vector2(pos.x, chart_area.position.y) if is_x_axis \
					else Vector2(chart_area.position.x, pos.y)
			var line_direction := Vector2(0, 1) if is_x_axis else Vector2(1, 0)
			var line_end := line_start + chart_area.size * line_direction
			if axis.draw_grid:
				draw_line(line_start, line_end, axis.major_tick_color)
			var tick_dimension := direction * tick_size
			var tick_vector := Vector2(0, tick_dimension) if is_x_axis else Vector2(tick_dimension, 0)
			if axis.draw_ticks:
				draw_line(pos, pos + tick_vector, axis.major_tick_color)
			if not axis.draw_labels:
				continue
			var text := TextLine.new()
			var _discard := text.add_string(labels[i], font, font_size)
			var label_offset := Vector2(
				-text.get_line_width() / 2,
				direction * (tick_size + tick_offset) - opposite_label * (
						text.get_line_ascent() + text.get_line_descent())
			) if is_x_axis else Vector2(
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
	x_axis_secondary = AxisX.new()
	x_axis_secondary.position = Axis.Position.TOP_RIGHT


func add_secondary_y_axis() -> void:
	y_axis_secondary = AxisY.new()
	y_axis_secondary.position = Axis.Position.TOP_RIGHT


func clear_chart() -> void:
	chart_data.clear()


func set_chart_data_color(data: ChartData, color: Color) -> void:
	var _discard := data.color_data.resize(data.y_data.size())
	data.color_map = ColorMap.create_from_color_samples([color], 1)
