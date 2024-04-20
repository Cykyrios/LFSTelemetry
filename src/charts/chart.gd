class_name Chart
extends Control


var chart_data: Array[ChartData] = []

var x_plot_min := INF
var x_plot_max := -INF
var y_plot_min := INF
var y_plot_max := -INF

var series_colors: Array[Color] = [
	Color(1, 0.2, 0.2),
	Color(0.2, 1, 0.2),
	Color(0.4, 0.4, 1),
]


func _ready() -> void:
	pass


func _draw() -> void:
	_draw_background()
	_draw_gridlines()
	_draw_data()


func add_data(data_x: Array[float], data_y: Array[float]) -> void:
	chart_data.append(ChartData.new(data_x, data_y))


func clear_chart() -> void:
	chart_data.clear()


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

		var x_range := x_plot_max - x_plot_min
		var y_range := y_plot_max - y_plot_min
		if is_zero_approx(x_range):
			x_plot_min -= 1
			x_plot_max += 1
			x_range = x_plot_max - x_plot_min
		if is_zero_approx(y_range):
			y_plot_min -= 1
			y_plot_max += 1
			y_range = y_plot_max - y_plot_min
		for j in point_count:
			points[j] = Vector2(remap(x_data[j], x_plot_min, x_plot_max, 0, size.x),
					remap(y_data[j], y_plot_min, y_plot_max, size.y, 0))
		var color_map: ColorMap = null
		if (
			series.color_data.is_empty() or
			series.color_data.all(func(value: float) -> bool: return is_zero_approx(value))
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
