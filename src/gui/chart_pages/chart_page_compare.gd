class_name ChartPageCompare
extends ChartPage


var main_lap_distance: Array[float] = []
var main_lap_speed: Array[float] = []
var main_lap_steer: Array[float] = []
var main_lap_rpm: Array[float] = []
var main_lap_gear: Array[float] = []
var main_lap_throttle: Array[float] = []
var main_lap_brake: Array[float] = []
var reference_lap_distance: Array[float] = []
var reference_lap_speed: Array[float] = []
var reference_lap_steer: Array[float] = []
var reference_lap_rpm: Array[float] = []
var reference_lap_gear: Array[float] = []
var reference_lap_throttle: Array[float] = []
var reference_lap_brake: Array[float] = []


func _init() -> void:
	super()
	name = "Compare"


func _draw_charts() -> void:
	super()
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(vbox)

	if stale:
		recompute_data()

	var chart_speed := Chart.new()
	vbox.add_child(chart_speed)
	chart_speed.chart_area.custom_minimum_size = Vector2(400, 200)
	chart_speed.x_axis_primary.margin = 0
	chart_speed.x_axis_primary.draw_labels = false
	chart_speed.update_minimum_size()
	var chart_steer := Chart.new()
	vbox.add_child(chart_steer)
	chart_steer.chart_area.custom_minimum_size = Vector2(400, 100)
	chart_steer.x_axis_primary.margin = 0
	chart_steer.x_axis_primary.draw_labels = false
	chart_steer.y_axis_primary.symmetric = true
	chart_steer.update_minimum_size()
	var chart_rpm := Chart.new()
	vbox.add_child(chart_rpm)
	chart_rpm.chart_area.custom_minimum_size = Vector2(400, 100)
	chart_rpm.x_axis_primary.margin = 0
	chart_rpm.x_axis_primary.draw_labels = false
	chart_rpm.update_minimum_size()
	var chart_gear := Chart.new()
	vbox.add_child(chart_gear)
	chart_gear.chart_area.custom_minimum_size = Vector2(400, 100)
	chart_gear.x_axis_primary.margin = 0
	chart_gear.x_axis_primary.draw_labels = false
	chart_gear.update_minimum_size()
	var chart_throttle := Chart.new()
	vbox.add_child(chart_throttle)
	chart_throttle.chart_area.custom_minimum_size = Vector2(400, 100)
	chart_throttle.x_axis_primary.margin = 0
	chart_throttle.x_axis_primary.draw_labels = false
	chart_throttle.update_minimum_size()
	var chart_brake := Chart.new()
	vbox.add_child(chart_brake)
	chart_brake.chart_area.custom_minimum_size = Vector2(400, 100)
	chart_brake.x_axis_primary.margin = 0
	chart_brake.update_minimum_size()
	await get_tree().process_frame

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_speed,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_speed.add_data(x_data, y_data, "Reference")
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_speed,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_speed.add_data(x_data, y_data, "Speed [km/h]")
		chart_speed.set_chart_data_color(chart_speed.chart_data[-1], Color.LIGHT_GREEN)

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_steer,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_steer.add_data(x_data, y_data, "Reference")
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_steer,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_steer.add_data(x_data, y_data, "Steering [°]")
		chart_steer.set_chart_data_color(chart_steer.chart_data[-1], Color.DEEP_SKY_BLUE)

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_rpm,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_rpm.add_data(x_data, y_data, "Reference")
		chart_rpm.set_chart_data_color(chart_rpm.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_rpm,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_rpm.add_data(x_data, y_data, "RPM")
		chart_rpm.set_chart_data_color(chart_rpm.chart_data[-1], Color.VIOLET)

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_gear,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_gear.add_data(x_data, y_data, "Reference")
		chart_gear.set_chart_data_color(chart_gear.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_gear,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_gear.add_data(x_data, y_data, "Gear")
		chart_gear.set_chart_data_color(chart_gear.chart_data[-1], Color.GOLD)

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_throttle,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_throttle.add_data(x_data, y_data, "Reference")
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_throttle,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_throttle.add_data(x_data, y_data, "Throttle [%]")
		chart_throttle.set_chart_data_color(chart_throttle.chart_data[-1], Color.LIME_GREEN)
	chart_throttle.y_axis_primary.data_min = -100 if chart_throttle.chart_data[-1].y_data.any(
			func(value: float) -> bool: return value < 0) else 0
	chart_throttle.y_axis_primary.data_max = 100

	if reference_lap:
		var data := chart_creator.downsample_data(reference_lap_distance, reference_lap_brake,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_brake.add_data(x_data, y_data, "Reference")
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.GRAY)
	if main_lap:
		var data := chart_creator.downsample_data(main_lap_distance, main_lap_brake,
				roundi(2 * chart_speed.chart_area.size.x))
		var x_data: Array[float] = []
		x_data.assign(data.map(func(value: Vector2) -> float: return value.x))
		var y_data: Array[float] = []
		y_data.assign(data.map(func(value: Vector2) -> float: return value.y))
		chart_brake.add_data(x_data, y_data, "Brake [%]")
		chart_brake.set_chart_data_color(chart_brake.chart_data[-1], Color.CRIMSON)
	chart_brake.y_axis_primary.data_min = 0
	chart_brake.y_axis_primary.data_max = 100

	refresh_charts()


func recompute_data() -> void:
	if main_lap:
		main_lap_distance = chart_creator.get_data(main_lap, "auto_distance")
		main_lap_speed = chart_creator.get_data(main_lap, "speed")
		main_lap_steer = chart_creator.get_data(main_lap, "steer")
		main_lap_rpm = chart_creator.get_data(main_lap, "rpm")
		main_lap_gear = chart_creator.get_data(main_lap, "gear")
		main_lap_throttle = chart_creator.get_data(main_lap, "throttle")
		main_lap_brake = chart_creator.get_data(main_lap, "brake")
	if reference_lap:
		reference_lap_distance = chart_creator.get_data(reference_lap, "auto_distance")
		reference_lap_speed = chart_creator.get_data(reference_lap, "speed")
		reference_lap_steer = chart_creator.get_data(reference_lap, "steer")
		reference_lap_rpm = chart_creator.get_data(reference_lap, "rpm")
		reference_lap_gear = chart_creator.get_data(reference_lap, "gear")
		reference_lap_throttle = chart_creator.get_data(reference_lap, "throttle")
		reference_lap_brake = chart_creator.get_data(reference_lap, "brake")
	stale = false
