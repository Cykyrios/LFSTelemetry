extends MarginContainer


var main_lap: LapData = null
var reference_lap: LapData = null

@onready var telemetry_vbox := %TelemetryVBox as VBoxContainer
@onready var load_main_lap_button := %MainLapButton as Button
@onready var main_driver_label := %MainDriverLabel as RichTextLabel
@onready var load_reference_lap_button := %ReferenceLapButton as Button
@onready var reference_driver_label := %ReferenceDriverLabel as RichTextLabel
@onready var scroll_container := %ScrollContainer as ScrollContainer


func _ready() -> void:
	connect_signals()
	print_laps()


func connect_signals() -> void:
	var _discard := load_main_lap_button.pressed.connect(_on_load_main_lap_pressed)
	_discard = load_reference_lap_button.pressed.connect(_on_load_reference_lap_pressed)


func draw_charts() -> void:
	while scroll_container.get_child_count() > 0:
		var child := scroll_container.get_children()[-1]
		scroll_container.remove_child(child)
		child.queue_free()
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(vbox)
	var chart_speed := Chart.new()
	vbox.add_child(chart_speed)
	chart_speed.chart_area.custom_minimum_size = Vector2(400, 200)
	var chart_steer := Chart.new()
	vbox.add_child(chart_steer)
	chart_steer.chart_area.custom_minimum_size = Vector2(400, 100)
	var chart_rpm := Chart.new()
	vbox.add_child(chart_rpm)
	chart_rpm.chart_area.custom_minimum_size = Vector2(400, 100)
	var chart_gear := Chart.new()
	vbox.add_child(chart_gear)
	chart_gear.chart_area.custom_minimum_size = Vector2(400, 100)
	var chart_throttle := Chart.new()
	vbox.add_child(chart_throttle)
	chart_throttle.chart_area.custom_minimum_size = Vector2(400, 100)
	var chart_brake := Chart.new()
	vbox.add_child(chart_brake)
	chart_brake.chart_area.custom_minimum_size = Vector2(400, 100)
	var chart_path := Chart.new()
	vbox.add_child(chart_path)
	chart_path.chart_area.custom_minimum_size = Vector2(500, 500)
	if reference_lap:
		chart_speed.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "speed") as Array[float], "Reference")
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_speed.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "speed") as Array[float], "Speed [km/h]")
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.LIGHT_GREEN)
	if reference_lap:
		chart_steer.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "steer") as Array[float], "Reference")
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_steer.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "steer") as Array[float], "Steering [°]")
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.DEEP_SKY_BLUE)
	chart_steer.y_axis_primary.symmetric = true
	if reference_lap:
		chart_rpm.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "rpm") as Array[float], "Reference")
		chart_rpm.set_chart_data_color(chart_rpm.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_rpm.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "rpm") as Array[float], "RPM")
		chart_rpm.set_chart_data_color(chart_rpm.chart_data[-1], Color.VIOLET)
	if reference_lap:
		chart_gear.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "gear") as Array[float], "Reference")
		chart_gear.set_chart_data_color(chart_gear.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_gear.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "gear") as Array[float], "Gear")
		chart_gear.set_chart_data_color(chart_gear.chart_data[-1], Color.GOLD)
	if reference_lap:
		chart_throttle.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "throttle") as Array[float], "Reference")
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_throttle.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "throttle") as Array[float], "Throttle [%]")
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.LIME_GREEN)
	if reference_lap:
		chart_brake.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "brake") as Array[float], "Reference")
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_brake.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "brake") as Array[float], "Brake [%]")
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.CRIMSON)
	if reference_lap:
		chart_path.add_data(get_data(reference_lap, "x_pos") as Array[float],
				get_data(reference_lap, "y_pos") as Array[float], "Reference")
		var color_data: Array[float] = []
		color_data.assign((get_data(reference_lap, "speed") as Array[float]))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapViridis.new()
		chart_path.chart_data[-1].title = "Reference"
	if main_lap:
		chart_path.add_data(get_data(main_lap, "x_pos") as Array[float],
				get_data(main_lap, "y_pos") as Array[float])
		var color_data: Array[float] = []
		color_data.assign((get_data(main_lap, "speed") as Array[float]))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapD3RdYlGn.new()
		chart_path.chart_data[-1].title = "Speed [km/h]"
	chart_path.equal_aspect = true
	chart_path.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_speed.queue_redraw()
	chart_steer.queue_redraw()
	chart_rpm.queue_redraw()
	chart_gear.queue_redraw()
	chart_path.queue_redraw()
	if main_lap:
		var power_chart := Chart.new()
		vbox.add_child(power_chart)
		power_chart.chart_area.custom_minimum_size = Vector2(500, 300)
		var power_data: Array[float] = []
		var rpm_data := get_data(main_lap, "rpm") as Array[float]
		var torque_data := get_data(main_lap, "torque") as Array[float]
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
		power_chart.add_data(rpms, torques, "Torque [N.m]")
		power_chart.add_secondary_y_axis()
		power_chart.chart_data[-1].set_y_axis(power_chart.y_axis_secondary)
		power_chart.add_data(rpms, powers, "Power [kW]")
		power_chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		power_chart.queue_redraw()
	if main_lap:
		var rpm_hbox := HBoxContainer.new()
		vbox.add_child(rpm_hbox)
		var rpm_vbox_left := VBoxContainer.new()
		rpm_hbox.add_child(rpm_vbox_left)
		rpm_vbox_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rpm_vbox_right := VBoxContainer.new()
		rpm_hbox.add_child(rpm_vbox_right)
		rpm_vbox_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rpm_vbox_right.size_flags_stretch_ratio = 2
		var chart_rpm_g := Chart.new()
		rpm_vbox_right.add_child(chart_rpm_g)
		chart_rpm_g.chart_area.custom_minimum_size = Vector2(400, 300)
		var speed_data := get_data(main_lap, "speed") as Array[float]
		var rpm_data := get_data(main_lap, "rpm") as Array[float]
		var g_data := get_data(main_lap, "g_lon") as Array[float]
		var throttle_data := get_data(main_lap, "throttle") as Array[float]
		var gear_data := get_data(main_lap, "gear") as Array[float]
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
		chart_rpm_g.queue_redraw()
		var chart_glon := Chart.new()
		rpm_vbox_right.add_child(chart_glon)
		chart_glon.chart_area.custom_minimum_size = Vector2(400, 300)
		chart_glon.add_data(speed_filtered, g_filtered, "Lon. G vs Speed [G]")
		chart_glon.chart_data[-1].plot_type = ChartData.PlotType.SCATTER
		chart_glon.chart_data[-1].color_data = gear_filtered
		chart_glon.chart_data[-1].color_map = ColorMapTurbo.new()
		chart_glon.queue_redraw()
	await get_tree().process_frame


func get_data(lap: LapData, data_type: String) -> Array[float]:
	var array: Array[float] = []
	match data_type:
		"time":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.time))
		"lap_distance":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.lap_distance))
		"indexed_distance":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.indexed_distance))
		"auto_distance":
			if lap.car_data[int(lap.car_data.size() / 2.0)].indexed_distance > 0:
				array.assign(lap.car_data.map(func(data: CarData) -> float:
					return data.indexed_distance))
			elif reference_lap:
				array.assign(reference_lap.car_data.map(func(data: CarData) -> float:
					return data.lap_distance))
			else:
				array.assign(lap.car_data.map(func(data: CarData) -> float: return data.lap_distance))
		"speed":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.speed))
		"steer":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.steering))
		"gear":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.gear))
		"rpm":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.rpm))
		"x_pos":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.position.x))
		"y_pos":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.position.y))
		"throttle":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.throttle))
		"brake":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.brake))
		"torque":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.max_torque_at_rpm))
		"g_lon":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.g_forces.y))
		"g_lat":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.g_forces.x))
	return array


func load_lap() -> LapData:
	var file_dialog := FileDialog.new()
	add_child(file_dialog)
	file_dialog.min_size = Vector2i(600, 400)
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.current_dir = "user://tlm"
	file_dialog.filters = ["*.tlm ; Telemetry files"]
	file_dialog.popup_centered()
	await file_dialog.file_selected
	var path := file_dialog.current_path
	var lap_io := LapDataIO.new()
	return lap_io.load_lap_file(path)


func print_laps() -> void:
	var lap_io := LapDataIO.new()
	var directories := DirAccess.get_directories_at("user://tlm")
	for directory in directories:
		var session_path := "user://tlm/%s" % [directory]
		var files := DirAccess.get_files_at(session_path)
		var file_count := files.size()
		for i in file_count:
			var index := file_count - 1 - i
			if files[index].get_extension() != "tlm":
				files.remove_at(index)
		file_count = files.size()
		if file_count > 0:
			print(directory)
		var print_sectors := func print_sectors(sectors: Array[SectorData]) -> String:
			var text := ""
			for sector in sectors:
				if text != "":
					text += " + "
				text += "S%d %s" % [sector.sector_number,
						Utils.get_lap_time_string(sector.sector_time)]
			return text
		for file in files:
			var lap := lap_io.load_lap_file("%s/%s" % [session_path, file], true)
			print("- %s" % ["%s%s" % [Utils.get_lap_time_string(lap.lap_time),
					"" if lap.sectors.is_empty() else " (%s)" % [print_sectors.call(lap.sectors)]]])


#region callbacks
func _on_load_main_lap_pressed() -> void:
	main_lap = await load_lap()
	main_driver_label.text = "Driver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(main_lap.driver),
			main_lap.car]
	draw_charts()


func _on_load_reference_lap_pressed() -> void:
	reference_lap = await load_lap()
	reference_driver_label.text = "Driver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(
			reference_lap.driver), reference_lap.car]
	draw_charts()
#endregion
