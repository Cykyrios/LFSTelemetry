class_name ChartArea
extends Control


var font := preload("res://src/charts/RecursiveSansLnrSt-Regular.otf")

var chart: Chart = null
var chart_data: Array[ChartData] = []

var series_colors := ColorMapD3Category10.new().colors

var primary_title_offset := Vector2.ZERO
var secondary_title_offset := Vector2.ZERO


func _draw() -> void:
	if not chart:
		push_error("ChartArea has no reference to parent Chart.")
		return
	_draw_data()


func _draw_data() -> void:
	_reset_title_offsets()
	for i in chart_data.size():
		var series := chart_data[i]
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		var x_data := series.x_data
		var y_data := series.y_data
		var points := PackedVector2Array()
		var point_count := mini(x_data.size(), y_data.size())
		var _discard := points.resize(point_count)

		if series.y_data.is_empty():
			continue

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
		_discard = normalized_color_data.resize(series.y_data.size())
		var color_bounds := Vector2.ZERO if series.color_data.is_empty() else \
				Vector2(series.color_data.min() as float, series.color_data.max() as float)
		for c in series.color_data.size():
			normalized_color_data[c] = color_map.get_normalized_value(
					series.color_data[c], color_bounds.x, color_bounds.y)
		var colors: Array[Color] = []
		colors.assign(normalized_color_data.map(color_map.get_color))
		_draw_title(series, color_map)
		match series.plot_type:
			ChartData.PlotType.LINE:
				draw_polyline_colors(points, colors, 1, true)
			ChartData.PlotType.SCATTER:
				for j in point_count:
					draw_arc(points[j], 3, 0, 2 * PI, 7, colors[j])
			ChartData.PlotType.BAR:
				var zero := remap(0, y_axis.view_min, y_axis.view_max, size.y, 0)
				for j in point_count:
					var width := (points[j + 1] - points[j]).x if j == 0 else (points[j] - points[j - 1]).x
					var rect := Rect2(points[j] - Vector2(width / 2, 0), Vector2(width, zero - points[j].y))
					draw_rect(rect, colors[j])
					draw_rect(rect, colors[j].lightened(0.5), false)


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
		# Magic 0.004 (1 / 256) subtracted so stepped color maps "round down" the color.
		color = color_map.get_color(color_map.get_normalized_value(
				mean_color_value, min_color_value, max_color_value) - 0.004)
	var new_offset := text.get_line_ascent() + text.get_line_descent()
	if series.y_axis == chart.y_axis_primary:
		text.draw(get_canvas_item(), primary_title_offset, color)
		primary_title_offset.y += new_offset
	elif series.y_axis == chart.y_axis_secondary:
		var secondary_axis_offset := Vector2(size.x - text.get_line_width(), 0)
		text.draw(get_canvas_item(), secondary_title_offset + secondary_axis_offset, color)
		secondary_title_offset.y += new_offset
	else:
		push_error("Could not find axis to print series title.")


func _reset_title_offsets() -> void:
	primary_title_offset = Vector2(5, 2)
	secondary_title_offset = Vector2(-5, 2)
