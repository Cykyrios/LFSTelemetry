class_name Chart
extends Control


var chart_data: Array[ChartData] = []

var x_margin := 0.02
var y_margin := 0.02
var x_plot_min := INF
var x_plot_max := -INF
var y_plot_min := INF
var y_plot_max := -INF

var series_colors := ColorMapD3Category10.new().colors

var equal_aspect := false
var zero_centered := false


func _ready() -> void:
	pass


func _draw() -> void:
	_update_plot_extents()
	_draw_background()
	_draw_gridlines()
	_draw_data()


func add_data(data_x: Array[float], data_y: Array[float]) -> void:
	chart_data.append(ChartData.new(data_x, data_y))


func clear_chart() -> void:
	chart_data.clear()


func get_max_x() -> float:
	var max_x := -INF
	for data in chart_data:
		max_x = maxf(max_x, data.x_data.max() as float)
	return max_x


func get_max_y() -> float:
	var max_y := -INF
	for data in chart_data:
		max_y = maxf(max_y, data.y_data.max() as float)
	return max_y


func get_min_x() -> float:
	var min_x := INF
	for data in chart_data:
		min_x = minf(min_x, data.x_data.min() as float)
	return min_x


func get_min_y() -> float:
	var min_y := INF
	for data in chart_data:
		min_y = minf(min_y, data.y_data.min() as float)
	return min_y


func set_chart_data_color(data: ChartData, color: Color) -> void:
	var _discard := data.color_data.resize(data.y_data.size())
	data.color_map = ColorMap.create_from_color_samples([color], 1)


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.2, 0.2, 0.2, 1))


func _draw_data() -> void:
	for i in chart_data.size():
		var series := chart_data[i]
		var x_data := series.x_data
		var y_data := series.y_data
		var points := PackedVector2Array()
		var point_count := mini(x_data.size(), y_data.size())
		var _discard := points.resize(point_count)

		var x_plot_margin := (x_plot_max - x_plot_min) * x_margin
		var y_plot_margin := (y_plot_max - y_plot_min) * y_margin
		for j in point_count:
			points[j] = Vector2(
				remap(x_data[j], x_plot_min - x_plot_margin, x_plot_max + x_plot_margin, 0, size.x),
				remap(y_data[j], y_plot_min - y_plot_margin, y_plot_max + y_plot_margin, size.y, 0)
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
		match series.plot_type:
			ChartData.PlotType.LINE:
				draw_polyline_colors(points, colors, 1, true)
			ChartData.PlotType.SCATTER:
				for j in point_count:
					draw_arc(points[j], 4, 0, 2 * PI, 7, colors[j], 0.5, true)


func _draw_gridlines() -> void:
	var vertical_lines := 6
	var vertical_sublines := 2
	var horizontal_lines := 3
	var horizontal_sublines := 1
	var main_color := Color(0.5, 0.5, 0.5, 1)
	var sub_color := Color(0.5, 0.5, 0.5, 0.3)
	for i in vertical_lines:
		var line_pos_x := size.x * (x_margin + i / (vertical_lines as float - 1) * (1 - 2 * x_margin))
		draw_line( Vector2(line_pos_x, 0), Vector2(line_pos_x, size.y), main_color)
		if i == vertical_lines - 1:
			break
		var main_interval := size.x * (1 - 2 * x_margin) / (vertical_lines as float - 1)
		for j in vertical_sublines:
			var subline_pos_x := line_pos_x + main_interval * (j + 1) / (vertical_sublines as float + 1)
			draw_line( Vector2(subline_pos_x, 0), Vector2(subline_pos_x, size.y), sub_color)
	for i in horizontal_lines:
		var line_pos_y := size.y * (y_margin + i / (horizontal_lines as float - 1) * (1 - 2 * y_margin))
		draw_line( Vector2(0, line_pos_y), Vector2(size.x, line_pos_y), main_color)
		if i == horizontal_lines - 1:
			break
		var main_interval := size.y * (1 - 2 * y_margin) / (horizontal_lines as float - 1)
		for j in horizontal_sublines:
			var subline_pos_y := line_pos_y + main_interval * (j + 1) / (horizontal_sublines as float + 1)
			draw_line( Vector2(0, subline_pos_y), Vector2(size.x, subline_pos_y), sub_color)


func _update_plot_extents() -> void:
	var x_min := get_min_x()
	var x_max := get_max_x()
	var y_min := get_min_y()
	var y_max := get_max_y()
	var x_range := x_max - x_min
	var y_range := y_max - y_min
	if is_zero_approx(x_range):
		x_min -= 1
		x_max += 1
	if is_zero_approx(y_range):
		y_min -= 1
		y_max += 1
	if equal_aspect:
		var chart_aspect := size.x / size.y
		var bounded_range := x_range if x_range / size.x > y_range / size.y else y_range
		var x_equal_range := bounded_range * (1.0 if bounded_range == x_range else chart_aspect)
		var y_equal_range := bounded_range * (1.0 if bounded_range == y_range else 1 / chart_aspect)
		x_plot_min = x_min - (x_equal_range - x_range) / 2.0
		x_plot_max = x_max + (x_equal_range - x_range) / 2.0
		y_plot_min = y_min - (y_equal_range - y_range) / 2.0
		y_plot_max = y_max + (y_equal_range - y_range) / 2.0
	else:
		x_plot_max = x_max
		x_plot_min = x_min
		if zero_centered:
			var y_abs := maxf(absf(y_max), absf(y_min))
			y_plot_max = y_abs
			y_plot_min = -y_abs
		else:
			y_plot_max = y_max
			y_plot_min = y_min
