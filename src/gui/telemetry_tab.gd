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
	chart_speed.custom_minimum_size = Vector2(400, 200)
	var chart_steer := Chart.new()
	vbox.add_child(chart_steer)
	chart_steer.custom_minimum_size = Vector2(400, 200)
	var chart_rpm := Chart.new()
	vbox.add_child(chart_rpm)
	chart_rpm.custom_minimum_size = Vector2(400, 200)
	var chart_gear := Chart.new()
	vbox.add_child(chart_gear)
	chart_gear.custom_minimum_size = Vector2(400, 100)
	var chart_throttle := Chart.new()
	vbox.add_child(chart_throttle)
	chart_throttle.custom_minimum_size = Vector2(400, 100)
	var chart_brake := Chart.new()
	vbox.add_child(chart_brake)
	chart_brake.custom_minimum_size = Vector2(400, 100)
	var chart_path := Chart.new()
	vbox.add_child(chart_path)
	chart_path.custom_minimum_size = Vector2(500, 500)
	if reference_lap:
		chart_speed.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "speed") as Array[float])
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_speed.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "speed") as Array[float])
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.RED.lightened(0.25))
	var xmin := chart_speed.get_min_x()
	var xmax := chart_speed.get_max_x()
	chart_speed.x_plot_min = xmin
	chart_speed.x_plot_max = xmax
	chart_speed.y_plot_min = chart_speed.get_min_y()
	chart_speed.y_plot_max = chart_speed.get_max_y()
	if reference_lap:
		chart_steer.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "steer") as Array[float])
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_steer.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "steer") as Array[float])
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.RED.lightened(0.25))
	chart_steer.x_plot_min = xmin
	chart_steer.x_plot_max = xmax
	var steering_abs := maxf(chart_steer.get_min_y(), chart_steer.get_max_y())
	chart_steer.y_plot_min = -steering_abs
	chart_steer.y_plot_max = steering_abs
	if reference_lap:
		chart_rpm.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "rpm") as Array[float])
		chart_rpm.set_chart_data_color(chart_rpm.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_rpm.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "rpm") as Array[float])
	chart_rpm.x_plot_min = xmin
	chart_rpm.x_plot_max = xmax
	chart_rpm.y_plot_min = chart_rpm.get_min_y()
	chart_rpm.y_plot_max = chart_rpm.get_max_y()
	if reference_lap:
		chart_gear.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "gear") as Array[float])
		chart_gear.set_chart_data_color(chart_gear.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_gear.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "gear") as Array[float])
	chart_gear.x_plot_min = xmin
	chart_gear.x_plot_max = xmax
	chart_gear.y_plot_min = chart_gear.get_min_y()
	chart_gear.y_plot_max = chart_gear.get_max_y()
	chart_rpm.chart_data[-1].color_data = chart_gear.chart_data[-1].y_data
	chart_rpm.chart_data[-1].color_map = ColorMapTurbo.new()
	chart_rpm.chart_data[-1].color_map.steps = int(chart_gear.y_plot_max - chart_gear.y_plot_min + 1)
	chart_gear.chart_data[-1].color_data = chart_gear.chart_data[-1].y_data
	chart_gear.chart_data[-1].color_map = ColorMapTurbo.new()
	chart_gear.chart_data[-1].color_map.steps = int(chart_gear.y_plot_max - chart_gear.y_plot_min + 1)
	if reference_lap:
		chart_throttle.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "throttle") as Array[float])
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_throttle.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "throttle") as Array[float])
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.DARK_GREEN.lightened(0.25))
	chart_throttle.x_plot_min = xmin
	chart_throttle.x_plot_max = xmax
	chart_throttle.y_plot_min = chart_throttle.get_min_y()
	chart_throttle.y_plot_max = chart_throttle.get_max_y()
	if reference_lap:
		chart_brake.add_data(get_data(reference_lap, "auto_distance") as Array[float],
				get_data(reference_lap, "brake") as Array[float])
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.GRAY)
	if main_lap:
		chart_brake.add_data(get_data(main_lap, "auto_distance") as Array[float],
				get_data(main_lap, "brake") as Array[float])
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.DARK_RED.lightened(0.25))
	chart_brake.x_plot_min = xmin
	chart_brake.x_plot_max = xmax
	chart_brake.y_plot_min = chart_brake.get_min_y()
	chart_brake.y_plot_max = chart_brake.get_max_y()
	if reference_lap:
		chart_path.add_data(get_data(reference_lap, "x_pos") as Array[float],
				get_data(reference_lap, "y_pos") as Array[float])
		var color_data: Array[float] = []
		color_data.assign((get_data(reference_lap, "speed") as Array[float]))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapViridis.new()
	if main_lap:
		chart_path.add_data(get_data(main_lap, "x_pos") as Array[float],
				get_data(main_lap, "y_pos") as Array[float])
		var color_data: Array[float] = []
		color_data.assign((get_data(main_lap, "speed") as Array[float]))
		chart_path.chart_data[-1].color_data = color_data
		chart_path.chart_data[-1].color_map = ColorMapD3RdYlGn.new()
	var path_min_x := chart_path.get_min_x()
	var path_min_y := chart_path.get_min_y()
	var path_max_x := chart_path.get_max_x()
	var path_max_y := chart_path.get_max_y()
	chart_path.x_plot_min = path_min_x - 10
	chart_path.x_plot_max = path_min_x + maxf(path_max_x - path_min_x, path_max_y - path_min_y) + 10
	chart_path.y_plot_min = path_min_y - 10
	chart_path.y_plot_max = path_min_y + maxf(path_max_x - path_min_x, path_max_y - path_min_y) + 10
	chart_path.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_speed.queue_redraw()
	chart_steer.queue_redraw()
	chart_rpm.queue_redraw()
	chart_gear.queue_redraw()
	chart_path.queue_redraw()
	if main_lap:
		var power_chart := Chart.new()
		vbox.add_child(power_chart)
		power_chart.custom_minimum_size = Vector2(500, 300)
		var power_data: Array[float] = []
		var rpm_data := get_data(main_lap, "rpm") as Array[float]
		var torque_data := get_data(main_lap, "torque") as Array[float]
		var _discard := power_data.resize(rpm_data.size())
		for i in power_data.size():
			power_data[i] = rpm_data[i] * torque_data[i] * 2 * PI / 60 / 1000
		power_chart.add_data(rpm_data, power_data)
		power_chart.x_plot_min = power_chart.chart_data[-1].x_min
		power_chart.x_plot_max = power_chart.chart_data[-1].x_max
		power_chart.y_plot_min = power_chart.chart_data[-1].y_min
		power_chart.y_plot_max = power_chart.chart_data[-1].y_max
		power_chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		power_chart.queue_redraw()
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
	#load_and_draw(path)
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
