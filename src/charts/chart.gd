class_name Chart
extends GridContainer

# Implementation takes heavy inspiration from bits of matplotlib for tick placement
# and label formatting.

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
var drawables: Array[Drawable] = []

var equal_aspect := false

var tick_offset := 3
var tick_size := 6
var font_size := 11


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

	chart_area.chart = self
	chart_area.chart_data = chart_data


func _draw() -> void:
	_draw_background()
	_draw_frame()
	var axes:= _get_active_axes()
	_update_axis_figure_sizes(axes)
	_update_axis_ranges(axes)
	_draw_chart_elements(axes)
	for drawable in drawables:
		_draw_drawable(drawable)


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


func _draw_background() -> void:
	draw_rect(Rect2(chart_area.position, chart_area.size), Color(0.2, 0.2, 0.2, 1))


func _draw_chart_elements(axes: Array[Axis]) -> void:
	for axis in axes:
		var offset := Vector2.ZERO
		var direction := 1
		var opposite_label := 0
		var is_x_axis := false

		# Set drawing parameters
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

		# Ensure axis is up to date
		var locator := axis.major_ticks.locator
		if locator is LocatorMaxN:
			(locator as LocatorMaxN).symmetric = axis.symmetric
			var limits := (locator as LocatorMaxN).view_limits(axis.view_min, axis.view_max)
			axis.set_view_limits(limits.x, limits.y)
		var vmin := axis.view_min
		var vmax := axis.view_max
		var view_range := vmax - vmin
		var margin := 0.5 * view_range * axis.margin
		axis.set_view_limits(axis.view_min - margin, axis.view_max + margin)

		var major_locations := axis.major_ticks.locator.get_tick_locations()
		var minor_locations := axis.minor_ticks.locator.get_tick_locations()
		minor_locations = minor_locations.filter(func(value: float) -> bool:
			return not major_locations.has(value))
		# Draw minor grid lines and ticks
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

		# Draw major grid lines, ticks, and labels
		var values := axis.major_ticks.locator.get_tick_values(axis.view_min, axis.view_max)
		var labels := axis.major_ticks.formatter.format_ticks(values)
		for i in major_locations.size():
			var chart_min := 0.0 if is_x_axis else chart_area.size.y
			var chart_max := chart_area.size.x if is_x_axis else 0.0
			var axis_pos := remap(major_locations[i], axis.view_min, axis.view_max, chart_min, chart_max)
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


func _draw_drawable(drawable: Drawable) -> void:
	if drawable is DrawableArea:
		_draw_drawable_area(drawable as DrawableArea)
	elif drawable is DrawableLabel:
		_draw_drawable_label(drawable as DrawableLabel)
	elif drawable is DrawableLegend:
		_draw_drawable_legend(drawable as DrawableLegend)


func _draw_drawable_area(area: DrawableArea) -> void:
	var rect := Rect2(chart_area.position, Vector2.ZERO)
	if area.axis is AxisX:
		rect.position.x += remap(area.start, area.axis.view_min, area.axis.view_max,
				0, chart_area.size.x)
		rect.size.x = remap(area.end, area.axis.view_min, area.axis.view_max,
				0, chart_area.size.x) - rect.position.x + chart_area.position.x
		rect.size.y = chart_area.size.y
	else:
		rect.position.y += remap(area.start, area.axis.view_min, area.axis.view_max,
				chart_area.size.y, 0)
		rect.size.x = chart_area.size.x
		rect.size.y = remap(area.end, area.axis.view_min, area.axis.view_max,
				chart_area.size.y, 0) - rect.position.y
	draw_rect(rect, area.color)


func _draw_drawable_label(label: DrawableLabel) -> void:
	var label_position := label.position
	if label.position_in_chart_area:
		label_position += chart_area.position
		if label.relative_position:
			label_position = Vector2(
				remap(label.position.x, 0, 1, chart_area.position.x,
						chart_area.position.x + chart_area.size.x),
				remap(label.position.y, 0, 1, chart_area.position.y + chart_area.size.y,
					chart_area.position.y)
				)
	else:
		if label.relative_position:
			label_position = Vector2(
				remap(label.position.x, 0, 1, 0, size.x),
				remap(label.position.y, 0, 1, size.y, 0)
			)
	var sizes: Array[Vector2] = []
	var max_width := 0.0
	for i in label.text_paragraph.get_line_count():
		sizes.append(label.text_paragraph.get_line_size(i))
		max_width = maxf(max_width, sizes[-1].x)
	var offsets: Array[Vector2] = []
	for i in sizes.size():
		offsets.append(Vector2(
			(max_width - sizes[i].x) / 2,
			0.0 if i == 0 else offsets[i - 1].y + sizes[i - 1].y)
		)
	for i in label.text_paragraph.get_line_count():
		label.text_paragraph.draw_line(get_canvas_item(),
				label_position + label.get_offset() + offsets[i], i, label.color)


func _draw_drawable_legend(legend: DrawableLegend) -> void:
	var margin := 5
	var offset := Vector2(-10, 10)
	var title := TextLine.new()
	var _discard := title.add_string(legend.title, font, font_size)
	var title_size := title.get_size()
	var dummy_label := TextLine.new()
	_discard = dummy_label.add_string("0.123456789", font, font_size)
	var line_height := dummy_label.get_size().y
	var labels: Array[TextLine] = []
	var max_width := 0.0
	for i in legend.values.size():
		var label := TextLine.new()
		_discard = label.add_string("%.0f" % [legend.values[i]], font, font_size)
		labels.append(label)
		max_width = maxf(max_width, label.get_line_width())
	var max_element_width := max_width + line_height + margin
	var element_offset := 0.0 if max_element_width > title_size.x else (title_size.x - max_element_width) / 2
	var legend_width := maxf(title_size.x, max_element_width) + 2 * margin
	var legend_offset := offset + Vector2(
		(chart_area.size.x if offset.x < 0 else 0.0) - legend_width,
		chart_area.size.y if offset.y < 0 else 0.0
	)
	var legend_position := chart_area.position + legend_offset
	var title_offset := title_size.y + 2
	var legend_size := Vector2(legend_width,
			title_offset + line_height * labels.size() + 2 * margin)
	draw_rect(Rect2(legend_position, legend_size), Color(0.2, 0.2, 0.2, 0.7))
	draw_rect(Rect2(legend_position, legend_size), x_axis_primary.major_tick_color, false)
	title.draw(get_canvas_item(), legend_position + Vector2(
			(legend_width - title.get_line_width()) / 2, margin))
	var color_map_h_offset := legend_width - margin - element_offset - line_height
	if legend.discrete:
		for i in labels.size():
			var idx := labels.size() - 1 - i
			var vertical_offset := title_offset + i * line_height
			labels[idx].draw(get_canvas_item(), legend_position + Vector2(
					margin + element_offset + max_width - labels[idx].get_line_width(),
					margin + vertical_offset))
			var rect := Rect2(legend_position + Vector2(color_map_h_offset,
						margin + vertical_offset), Vector2.ONE * line_height)
			draw_rect(rect, legend.colors[idx])
			draw_rect(rect, x_axis_primary.major_tick_color, false)
	else:
		title_offset += line_height / 2
		var max_height := 160
		var color_map_height := mini(max_height, roundi((labels.size() - 1) * line_height))
		var point_count := color_map_height if legend.smooth_contours else (labels.size() - 1)
		var color_map_points := PackedVector2Array()
		_discard = color_map_points.resize(color_map_height)
		var color_map_colors := PackedColorArray()
		_discard = color_map_colors.resize(color_map_height)
		for i in labels.size():
			var idx := labels.size() - 1 - i
			var vertical_offset := title_offset - line_height / 2 + i * line_height
			labels[idx].draw(get_canvas_item(), legend_position + Vector2(
					margin + element_offset + max_width - labels[idx].get_line_width(),
					margin + vertical_offset))
		if legend.smooth_contours:
			for i in point_count:
				color_map_points[i] = legend_position + Vector2(
						color_map_h_offset + line_height / 2,
						margin + title_offset + i)
				color_map_colors[i] = legend.color_map.get_color(
						(point_count - i) / (point_count as float - 1))
			draw_polyline_colors(color_map_points, color_map_colors, line_height)
		else:
			for i in point_count:
				draw_rect(Rect2(legend_position + Vector2(color_map_h_offset,
						margin + title_offset + i * line_height), Vector2.ONE * line_height),
						legend.color_map.get_color(i as float / (point_count - 1)))
		draw_rect(Rect2(legend_position + Vector2(color_map_h_offset, margin + title_offset),
				Vector2(1, labels.size() - 1) * line_height), x_axis_primary.major_tick_color,
				false)
		for i in labels.size() - 2:
			draw_line(legend_position + Vector2(color_map_h_offset,
					margin + title_offset + (i + 1) * line_height),
					legend_position + Vector2(legend_width - margin - element_offset,
					margin + title_offset + (i + 1) * line_height),
					x_axis_primary.major_tick_color)


func _draw_frame() -> void:
	draw_rect(Rect2(chart_area.position, chart_area.size), x_axis_primary.major_tick_color, false, 1)


func _get_active_axes() -> Array[Axis]:
	var axes: Array[Axis] = []
	if x_axis_secondary:
		axes.append(x_axis_secondary)
	if y_axis_secondary:
		axes.append(y_axis_secondary)
	if x_axis_primary:
		axes.append(x_axis_primary)
	if y_axis_primary:
		axes.append(y_axis_primary)
	return axes


func _update_axis_figure_sizes(axes: Array[Axis]) -> void:
	for axis in axes:
		if axis is AxisX:
			axis.figure_size = chart_area.size.x
		elif axis is AxisY:
			axis.figure_size = chart_area.size.y
		else:
			push_error("Axis is neither AxisX nor AxisY.")
			axis.figure_size = maxf(chart_area.size.x, chart_area.size.y)


func _update_axis_ranges(axes: Array[Axis]) -> void:
	for series in chart_data:
		if series.x_data.is_empty() or series.y_data.is_empty():
			push_warning("There is no data to be drawn, skipping.")
			continue
		var x_axis := series.x_axis
		var y_axis := series.y_axis
		var x_limits := x_axis.major_ticks.locator.view_limits(series.x_data.min() as float,
				series.x_data.max() as float)
		x_axis.data_min = minf(x_axis.data_min, x_limits.x)
		x_axis.data_max = maxf(x_axis.data_max, x_limits.y)
		x_axis.set_view_limits(x_limits.x, x_limits.y)
		var y_limits := y_axis.major_ticks.locator.view_limits(series.y_data.min() as float,
				series.y_data.max() as float)
		y_axis.data_min = minf(y_axis.data_min, y_limits.x)
		y_axis.data_max = maxf(y_axis.data_max, y_limits.y)
		y_axis.set_view_limits(y_limits.x, y_limits.y)
	for axis in axes:
		axis.update_view_interval()
	if not equal_aspect:
		return
	# FIXME: This does not properly transform secondary axes, simply adding the
	# additional range skews the data. This is left as is for now as the intended
	# use (track map) shouldn't require secondary axes anyway.
	var chart_aspect := chart_area.size.x / chart_area.size.y
	var ranges: Array[float] = []
	var bounded_ranges: Array[float] = []
	var max_x_range := 0.0
	var max_y_range := 0.0
	for axis in axes:
		ranges.append(axis.view_max - axis.view_min)
		if axis is AxisX:
			bounded_ranges.append(ranges[-1] / chart_area.size.x)
			max_x_range = maxf(max_x_range, ranges[-1])
		elif axis is AxisY:
			bounded_ranges.append(ranges[-1] / chart_area.size.y)
			max_y_range = maxf(max_y_range, ranges[-1])
	var bounded_range := ranges[bounded_ranges.find(bounded_ranges.max())]
	var bounded_is_x := false
	if axes[ranges.find(bounded_range)] is AxisX:
		bounded_is_x = true
	for i in axes.size():
		var axis := axes[i]
		var equal_range := bounded_range
		var max_range := 0.0
		if axis is AxisX:
			equal_range *= 1.0 if bounded_is_x else chart_aspect
			max_range = max_x_range
		else:
			equal_range *= 1.0 if not bounded_is_x else (1 / chart_aspect)
			max_range = max_y_range
		var half_range := (equal_range - max_range) / 2.0
		axis.set_view_limits(axis.view_min - half_range, axis.view_max + half_range)
