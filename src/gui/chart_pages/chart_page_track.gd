class_name ChartPageTrack
extends ChartPage


func _init() -> void:
	super()
	name = "Track"


func _draw_charts() -> void:
	super()

	var chart_path := Chart.new()
	scroll_container.add_child(chart_path)
	chart_path.chart_area.custom_minimum_size = Vector2(500, 500)
	if reference_lap:
		chart_path.add_data(chart_creator.get_data(reference_lap, "x_pos"),
				chart_creator.get_data(reference_lap, "y_pos"), "Reference")
		var color_data: Array[float] = []
		color_data.assign((chart_creator.get_data(reference_lap, "speed")))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapViridis.new()
		chart_path.chart_data[-1].title = "Reference"
	if main_lap:
		chart_path.add_data(chart_creator.get_data(main_lap, "x_pos"),
				chart_creator.get_data(main_lap, "y_pos"))
		var color_data: Array[float] = []
		color_data.assign((chart_creator.get_data(main_lap, "speed")))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapD3RdYlGn.new()
		chart_path.chart_data[-1].title = "Speed [km/h]"
		var legend := DrawableLegend.generate_contour_legend("Speed [km/h]",
				chart_path.chart_data[-1].color_map, 9,
				chart_path.chart_data[-1].color_data.min() as float,
				chart_path.chart_data[-1].color_data.max() as float)
		chart_path.drawables.append(legend)
	chart_path.equal_aspect = true
	chart_path.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	refresh_charts()
