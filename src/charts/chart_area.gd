class_name ChartArea
extends Control


var font := preload("res://src/charts/RecursiveSansLnrSt-Regular.otf")

var chart_data: Array[ChartData] = []

var series_colors := ColorMapD3Category10.new().colors

var title_offset := Vector2.ZERO


func _draw() -> void:
	_update_plot_extents()
	#_draw_background()
	#_draw_gridlines()
	_draw_data()


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.2, 0.2, 0.2, 1))


func _draw_data() -> void:
	_reset_title_offset()
	for i in chart_data.size():
		var series := chart_data[i]
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		var x_data := series.x_data
		var y_data := series.y_data
		var points := PackedVector2Array()
		var point_count := mini(x_data.size(), y_data.size())
		var _discard := points.resize(point_count)

		for j in point_count:
			points[j] = Vector2(
				remap(x_data[j], x_axis.view_min, x_axis.view_max, 0, size.x),
				remap(y_data[j], y_axis.view_min, y_axis.view_max, size.y, 0)
			)
		var color_map: ColorMap = null
		if (
			not series.color_map and
			(series.color_data.is_empty() or
			series.color_data.all(func(value: float) -> bool: return is_zero_approx(value)))
		):
			color_map = ColorMap.create_from_color_samples([series_colors[i]], 1)
			_discard = series.color_data.resize(series.y_data.size())
		else:
			color_map = series.color_map
			if not color_map:
				color_map = ColorMapMagma.new()
		var normalized_color_data: Array[float] = []
		_discard = normalized_color_data.resize(series.color_data.size())
		for c in series.color_data.size():
			normalized_color_data[c] = color_map.get_normalized_value(
					series.color_data[c], series.color_min, series.color_max)
		var colors: Array[Color] = []
		colors.assign(normalized_color_data.map(color_map.get_color))
		_draw_title(series, color_map)
		match series.plot_type:
			ChartData.PlotType.LINE:
				draw_polyline_colors(points, colors, 1, true)
			ChartData.PlotType.SCATTER:
				for j in point_count:
					draw_arc(points[j], 3, 0, 2 * PI, 9, colors[j], 0.5, true)


func _draw_gridlines() -> void:
	var x_axes: Array[Axis] = []
	var y_axes: Array[Axis] = []
	for series in chart_data:
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		if x_axes.find(x_axis) < 0:
			x_axes.append(x_axis)
			var locations := x_axis.major_ticks.locator.get_tick_locations()
			for location in locations:
				var pos_x := remap(location, x_axis.data_min, x_axis.data_max, 0, size.x)
				if pos_x < 0 or pos_x > size.x:
					continue
				draw_line( Vector2(pos_x, 0), Vector2(pos_x, size.y), x_axis.major_tick_color)
			locations = x_axis.minor_ticks.locator.get_tick_locations()
			for location in locations:
				var pos_x := remap(location, x_axis.data_min, x_axis.data_max, 0, size.x)
				if pos_x < 0 or pos_x > size.x:
					continue
				draw_line( Vector2(pos_x, 0), Vector2(pos_x, size.y), x_axis.minor_tick_color)
		if y_axes.find(y_axis) < 0:
			y_axes.append(y_axis)
			var locations := y_axis.major_ticks.locator.get_tick_locations()
			for location in locations:
				var pos_y := remap(location, y_axis.data_min, y_axis.data_max, size.y, 0)
				if pos_y < 0 or pos_y > size.y:
					continue
				draw_line( Vector2(0, pos_y), Vector2(size.x, pos_y), y_axis.major_tick_color)
			locations = y_axis.minor_ticks.locator.get_tick_locations()
			for location in locations:
				var pos_y := remap(location, y_axis.data_min, y_axis.data_max, size.y, 0)
				if pos_y < 0 or pos_y > size.y:
					continue
				draw_line( Vector2(0, pos_y), Vector2(size.x, pos_y), y_axis.minor_tick_color)


func _draw_title(series: ChartData, color_map: ColorMap) -> void:
	if series.title == "Reference":
		return
	var text := TextLine.new()
	var _string := text.add_string(series.title, font, 12)
	var color := color_map.get_color(0)
	if not series.color_data.is_empty() and series.color_data.max() > 0:
		var min_color_value := series.color_data.min() as float
		var max_color_value := series.color_data.max() as float
		var mean_color_value := (min_color_value + max_color_value) / 2.0
		color = color_map.get_color(color_map.get_normalized_value(
				mean_color_value, min_color_value, max_color_value))
	text.draw(get_canvas_item(), title_offset, color)
	title_offset.y += text.get_line_ascent() + text.get_line_descent()


func _reset_title_offset() -> void:
	title_offset = Vector2(5, 2)


func _update_plot_extents() -> void:
	pass
