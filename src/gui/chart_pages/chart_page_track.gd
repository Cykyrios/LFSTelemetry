class_name ChartPageTrack
extends ChartPage


func _init() -> void:
	super()
	name = "Track"


func _draw_charts() -> void:
	super()
	var grid_container := GridContainer.new()
	grid_container.columns = 2
	scroll_container.add_child(grid_container)

	var main_x_pos: Array[float] = []
	var main_y_pos: Array[float] = []
	var reference_x_pos: Array[float] = []
	var reference_y_pos: Array[float] = []
	if main_lap:
		main_x_pos = chart_creator.get_data(main_lap, "x_pos")
		main_y_pos = chart_creator.get_data(main_lap, "y_pos")
	if reference_lap:
		reference_x_pos = chart_creator.get_data(reference_lap, "x_pos")
		reference_y_pos = chart_creator.get_data(reference_lap, "y_pos")

	var chart_speed := Chart.new()
	chart_speed.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_speed.chart_area.custom_minimum_size = Vector2(500, 500)
	grid_container.add_child(chart_speed)
	chart_speed.equal_aspect = true
	if reference_lap:
		chart_speed.add_data(reference_x_pos, reference_y_pos, "Reference")
		var color_data: Array[float] = []
		color_data.assign((chart_creator.get_data(reference_lap, "speed")))
		chart_speed.chart_data[-1].color_data = color_data
		chart_speed.chart_data[-1].color_map = ColorMapViridis.new()
		chart_speed.chart_data[-1].title = "Reference"
	if main_lap:
		chart_speed.add_data(main_x_pos, main_y_pos)
		var color_data: Array[float] = []
		color_data.assign((chart_creator.get_data(main_lap, "speed")))
		chart_speed.chart_data[-1].color_data = color_data
		chart_speed.chart_data[-1].color_map = ColorMapD3RdYlGn.new()
		chart_speed.chart_data[-1].title = "Speed [km/h]"
		var legend := DrawableLegend.generate_contour_legend("Speed [km/h]",
				chart_speed.chart_data[-1].color_map, 9,
				chart_speed.chart_data[-1].color_data.min() as float,
				chart_speed.chart_data[-1].color_data.max() as float)
		chart_speed.drawables.append(legend)

	var chart_pedals := Chart.new()
	chart_pedals.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_pedals.chart_area.custom_minimum_size = Vector2(500, 500)
	grid_container.add_child(chart_pedals)
	chart_pedals.equal_aspect = true
	if main_lap:
		chart_pedals.add_data(main_x_pos, main_y_pos, "Pedal Input")
		chart_pedals.set_chart_data_color(chart_pedals.chart_data[-1], Color.GOLD)
		chart_pedals.add_data(main_x_pos, main_y_pos, "Reference")
		var color_data: Array[float] = []
		color_data.assign(chart_creator.get_data(main_lap, "throttle"))
		color_data.assign(color_data.map(func(value: float) -> float: return maxf(value, 0)))
		chart_pedals.chart_data[-1].color_data = color_data.duplicate()
		chart_pedals.chart_data[-1].color_map = ColorMap.create_from_color_samples(
				[Color(Color.WEB_GREEN, 0), Color.WEB_GREEN])
		chart_pedals.add_data(main_x_pos, main_y_pos, "Reference")
		color_data.assign(chart_creator.get_data(main_lap, "brake"))
		chart_pedals.chart_data[-1].color_data = color_data.duplicate()
		chart_pedals.chart_data[-1].color_map = ColorMap.create_from_color_samples(
				[Color(Color.CRIMSON, 0), Color.CRIMSON])

	refresh_charts()
