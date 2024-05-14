class_name ChartCreator
extends RefCounted


var main_lap: LapData = null
var reference_lap: LapData = null


func _init(main: LapData, ref_lap: LapData) -> void:
	main_lap = main
	reference_lap = ref_lap


func downsample_data(x_data: Array[float], y_data: Array[float], threshold: int) -> Array[Vector2]:
	var data_points := x_data.size()
	var data: Array[Vector2] = []
	var _discard := data.resize(data_points)
	for i in data_points:
		data[i] = Vector2(x_data[i], y_data[i])
	if threshold < 2 or threshold > data_points:
		return data
	if threshold as float / data_points > 0.5:  # Downsampling "not worth it"
		return data
	var downsampled: Array[Vector2] = []
	_discard = downsampled.resize(threshold)
	downsampled[0] = data[0]
	var step := (data_points as float - 2) / (threshold - 2)
	var a := 0
	var idx := 0
	for i in threshold - 2:
		var avg_x := 0.0
		var avg_y := 0.0
		var avg_start := floori((i + 1) * step) + 1
		var avg_end := floori((i + 2) * step) + 1
		if avg_end > data_points:
			avg_end = data_points
		var avg_length := avg_end - avg_start
		while avg_start < avg_end:
			avg_x += data[avg_start].x
			avg_y += data[avg_start].y
			avg_start += 1
		avg_x /= avg_length
		avg_y /= avg_length

		var range_offset := floori(i * step) + 1
		var range_to := floori((i + 1) * step) + 1
		var ax := data[a].x
		var ay := data[a].y
		var max_area := -1.0
		while range_offset < range_to:
			var area := absf((ax - avg_x) * (data[range_offset].y - ay) \
					- (ax - data[range_offset].x) * (avg_y - ay)) / 2.0
			if area > max_area:
				max_area = area
				idx = range_offset
			range_offset += 1
		downsampled[i + 1] = data[idx]
		a = idx
	downsampled[-1] = data[-1]
	return downsampled


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
