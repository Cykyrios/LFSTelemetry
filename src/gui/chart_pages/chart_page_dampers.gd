class_name ChartPageDampers
extends ChartPage


func _init() -> void:
	super()
	name = "Dampers"


func _draw_charts() -> void:
	super()
	var suspension_grid := GridContainer.new()
	suspension_grid.columns = 2
	suspension_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suspension_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(suspension_grid)

	if main_lap:
		var chart_suspension_fl := Chart.new()
		suspension_grid.add_child(chart_suspension_fl)
		chart_suspension_fl.chart_area.custom_minimum_size = Vector2(400, 200)
		chart_suspension_fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart_suspension_fl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var chart_suspension_fr := Chart.new()
		suspension_grid.add_child(chart_suspension_fr)
		chart_suspension_fr.chart_area.custom_minimum_size = Vector2(400, 200)
		chart_suspension_fr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart_suspension_fr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var chart_suspension_rl := Chart.new()
		suspension_grid.add_child(chart_suspension_rl)
		chart_suspension_rl.chart_area.custom_minimum_size = Vector2(400, 200)
		chart_suspension_rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart_suspension_rl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var chart_suspension_rr := Chart.new()
		suspension_grid.add_child(chart_suspension_rr)
		chart_suspension_rr.chart_area.custom_minimum_size = Vector2(400, 200)
		chart_suspension_rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chart_suspension_rr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var speed_rl := chart_creator.get_data(main_lap, "suspension_speed_rl")
		var speed_rr := chart_creator.get_data(main_lap, "suspension_speed_rr")
		var speed_fl := chart_creator.get_data(main_lap, "suspension_speed_fl")
		var speed_fr := chart_creator.get_data(main_lap, "suspension_speed_fr")
		var bin_width := 10.0
		var max_speed := 200.0
		var slow_speed := 25.0
		var histogram_rl := DamperHistogram.new(speed_rl, bin_width, max_speed, slow_speed)
		var histogram_rr := DamperHistogram.new(speed_rr, bin_width, max_speed, slow_speed)
		var histogram_fl := DamperHistogram.new(speed_fl, bin_width, max_speed, slow_speed)
		var histogram_fr := DamperHistogram.new(speed_fr, bin_width, max_speed, slow_speed)
		var colors := ColorMapD3Category10.new().colors
		chart_suspension_fl.add_data(histogram_fl.bins, histogram_fl.data, "Damper vel. FL")
		chart_suspension_fl.chart_data[-1].plot_type = ChartData.PlotType.BAR
		chart_suspension_fr.add_data(histogram_fr.bins, histogram_fr.data, "Damper vel. FR")
		chart_suspension_fr.chart_data[-1].plot_type = ChartData.PlotType.BAR
		chart_suspension_rl.add_data(histogram_rl.bins, histogram_rl.data, "Damper vel. RL")
		chart_suspension_rl.chart_data[-1].plot_type = ChartData.PlotType.BAR
		chart_suspension_rr.add_data(histogram_rr.bins, histogram_rr.data, "Damper vel. RR")
		chart_suspension_rr.chart_data[-1].plot_type = ChartData.PlotType.BAR
		var add_label := func add_label(
			chart: Chart, text: String, color: Color, pos: Vector2
		) -> DrawableLabel:
			var label := DrawableLabel.new(chart.font, chart.font_size + 1, text, color,
					DrawableLabel.AlignHorizontal.CENTER, DrawableLabel.AlignVertical.CENTER)
			label.position_in_chart_area = true
			label.relative_position = true
			label.position = pos
			return label
		var set_histogram_colors := func set_histogram_colors(
			chart: Chart, histogram: DamperHistogram, color: Color
		) -> void:
			chart.chart_data[-1].color_map = ColorMap.create_from_color_samples(
					[color, color.lightened(0.4)], 2)
			chart.chart_data[-1].color_data.assign(
					chart.chart_data[-1].x_data.map(func(value: float) -> float:
						return 1 if absf(value) > histogram.slow_speed_boundary else 0))
			var drawable_area := DrawableArea.new(chart.x_axis_primary, -25, 25,
					Color(0.7, 0.7, 0.7, 0.2))
			chart.drawables.append(drawable_area)
			var vertical_pos := 0.75
			var label_color := chart.chart_data[-1].color_map.get_color(0.49)
			chart.drawables.append(add_label.call(chart, "Rebound", label_color,
					Vector2(0.25, vertical_pos + 0.12)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Avg\n%.1f" % [histogram.rebound_average],
					label_color, Vector2(0.15, vertical_pos)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Hi%%\n%.1f" % [histogram.rebound_high * 100],
					label_color, Vector2(0.25, vertical_pos)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Lo%%\n%.1f" % [histogram.rebound_low * 100],
					label_color, Vector2(0.35, vertical_pos)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Bump", label_color,
					Vector2(0.75, vertical_pos + 0.12)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Lo%%\n%.1f" % [histogram.bump_low * 100],
					label_color, Vector2(0.65, vertical_pos)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Hi%%\n%.1f" % [histogram.bump_high * 100],
					label_color, Vector2(0.75, vertical_pos)) as DrawableLabel)
			chart.drawables.append(add_label.call(chart, "Avg\n%.1f" % [histogram.bump_average],
					label_color, Vector2(0.85, vertical_pos)) as DrawableLabel)
		set_histogram_colors.call(chart_suspension_fl, histogram_fl, colors[2])
		set_histogram_colors.call(chart_suspension_fr, histogram_fr, colors[3])
		set_histogram_colors.call(chart_suspension_rl, histogram_rl, colors[0])
		set_histogram_colors.call(chart_suspension_rr, histogram_rr, colors[1])
	else:
		var label := Label.new()
		label.text = "Main lap data is required."
		scroll_container.add_child(label)

	refresh_charts()
