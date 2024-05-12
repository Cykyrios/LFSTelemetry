class_name ChartPageRPM
extends ChartPage


func _init() -> void:
	super()
	name = "RPM"


func _draw_charts() -> void:
	super()
	var rpm_hbox := HBoxContainer.new()
	rpm_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rpm_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(rpm_hbox)
	var rpm_vbox_left := VBoxContainer.new()
	rpm_vbox_left.alignment = BoxContainer.ALIGNMENT_CENTER
	rpm_vbox_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rpm_hbox.add_child(rpm_vbox_left)
	var rpm_vbox_right := VBoxContainer.new()
	rpm_vbox_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rpm_vbox_right.size_flags_stretch_ratio = 2
	rpm_hbox.add_child(rpm_vbox_right)

	if main_lap:
		var speed_data := chart_creator.get_data(main_lap, "speed") as Array[float]
		var rpm_data := chart_creator.get_data(main_lap, "rpm") as Array[float]
		var g_data := chart_creator.get_data(main_lap, "g_lon") as Array[float]
		var throttle_data := chart_creator.get_data(main_lap, "throttle") as Array[float]
		var gear_data := chart_creator.get_data(main_lap, "gear") as Array[float]
		var torque_data := chart_creator.get_data(main_lap, "torque") as Array[float]
		var power_data: Array[float] = []
		var _discard := power_data.resize(rpm_data.size())
		for i in power_data.size():
			power_data[i] = rpm_data[i] * torque_data[i] * 2 * PI / 60 / 1000
		var rpm_power_torque := []
		_discard = rpm_power_torque.resize(rpm_data.size())
		for i in rpm_data.size():
			rpm_power_torque[i] = [rpm_data[i], power_data[i], torque_data[i]]
		rpm_power_torque.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var rpms: Array[float] = []
		_discard = rpms.resize(rpm_data.size())
		rpms.assign(rpm_power_torque.map(func(value: Array) -> float: return value[0]))
		var powers: Array[float] = []
		powers.assign(rpm_power_torque.map(func(value: Array) -> float: return value[1]))
		var torques: Array[float] = []
		torques.assign(rpm_power_torque.map(func(value: Array) -> float: return value[2]))

		var power_chart := Chart.new()
		rpm_vbox_left.add_child(power_chart)
		power_chart.chart_area.custom_minimum_size = Vector2(500, 300)
		power_chart.add_data(rpms, torques, "Torque [N.m]")
		power_chart.add_data(rpms, powers, "Power [kW]")
		power_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var chart_rpm_g := Chart.new()
		chart_rpm_g.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rpm_vbox_right.add_child(chart_rpm_g)
		chart_rpm_g.chart_area.custom_minimum_size = Vector2(400, 300)
		for i in throttle_data.size():
			if throttle_data[i] < 0.5 or g_data[i] < 0.0:
				speed_data[i] = INF
				rpm_data[i] = INF
				g_data[i] = INF
				gear_data[i] = INF
		var speed_filtered: Array[float] = []
		var rpm_filtered: Array[float] = []
		var g_filtered: Array[float] = []
		var gear_filtered: Array[float] = []
		speed_filtered.assign(speed_data.filter(func(value: float) -> bool: return not is_inf(value)))
		rpm_filtered.assign(rpm_data.filter(func(value: float) -> bool: return not is_inf(value)))
		g_filtered.assign(g_data.filter(func(value: float) -> bool: return not is_inf(value)))
		gear_filtered.assign(gear_data.filter(func(value: float) -> bool: return not is_inf(value)))
		chart_rpm_g.add_data(speed_filtered, rpm_filtered, "RPM vs Speed")
		chart_rpm_g.chart_data[-1].plot_type = ChartData.PlotType.SCATTER
		chart_rpm_g.chart_data[-1].color_data = gear_filtered
		chart_rpm_g.chart_data[-1].color_map = ColorMapTurbo.new()
		var gears: Array[float] = []
		gears.assign(range(gear_filtered.min(), gear_filtered.max() + 1))
		var legend := DrawableLegend.generate_discrete_legend("Gear",
				chart_rpm_g.chart_data[-1].color_map, gears)
		chart_rpm_g.drawables.append(legend)

		var chart_glon := Chart.new()
		chart_glon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rpm_vbox_right.add_child(chart_glon)
		chart_glon.chart_area.custom_minimum_size = Vector2(400, 300)
		chart_glon.add_data(speed_filtered, g_filtered, "Lon. G vs Speed [G]")
		chart_glon.chart_data[-1].plot_type = ChartData.PlotType.SCATTER
		chart_glon.chart_data[-1].color_data = gear_filtered
		chart_glon.chart_data[-1].color_map = ColorMapTurbo.new()
		legend = DrawableLegend.generate_discrete_legend("Gear",
				chart_glon.chart_data[-1].color_map, gears)
		chart_glon.drawables.append(legend)
	else:
		var label := Label.new()
		label.text = "Main lap data is required."
		scroll_container.add_child(label)

	refresh_charts()