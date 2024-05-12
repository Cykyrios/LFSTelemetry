class_name ChartCreator
extends RefCounted


var main_lap: LapData = null
var reference_lap: LapData = null


func _init(main: LapData, ref_lap: LapData) -> void:
	main_lap = main
	reference_lap = ref_lap


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
			array.assign(lap.car_data.map(func(data: CarData) -> float: return GISUtils.convert_speed(
					data.speed, GISUtils.SpeedUnit.METER_PER_SECOND, GISUtils.SpeedUnit.KPH)))
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
			array.assign(lap.car_data.map(func(data: CarData) -> float: return 100 * data.throttle))
		"brake":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return 100 * data.brake))
		"torque":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.max_torque_at_rpm))
		"g_lon":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.g_forces.y))
		"g_lat":
			array.assign(lap.car_data.map(func(data: CarData) -> float: return data.g_forces.x))
		"suspension_speed_rl":
			array.assign(lap.car_data.map(func(data: CarData) -> float:
				return 1000 * data.wheel_data[WheelData.WheelIndex.REAR_LEFT].suspension_speed))
		"suspension_speed_rr":
			array.assign(lap.car_data.map(func(data: CarData) -> float:
				return 1000 * data.wheel_data[WheelData.WheelIndex.REAR_RIGHT].suspension_speed))
		"suspension_speed_fl":
			array.assign(lap.car_data.map(func(data: CarData) -> float:
				return 1000 * data.wheel_data[WheelData.WheelIndex.FRONT_LEFT].suspension_speed))
		"suspension_speed_fr":
			array.assign(lap.car_data.map(func(data: CarData) -> float:
				return 1000 * data.wheel_data[WheelData.WheelIndex.FRONT_RIGHT].suspension_speed))
	return array
