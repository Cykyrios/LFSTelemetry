class_name LapData
extends RefCounted


var track := ""
var lap_number := 0
var lap_time := 0.0
var total_time := 0.0
var sectors: Array[SectorData] = []

var car_data: Array[CarData] = []
var outsim_data: Array[OutSimPacket] = []
var outgauge_data: Array[OutGaugePacket] = []


func compute_derived_data() -> void:
	for data in car_data:
		data.compute_derived_values()


func fill_car_data() -> void:
	if outsim_data.is_empty():
		return
	# OutGauge is more reliable as OutSim only records in cockpit or custom views
	var data_point_count := outgauge_data.size()
	var _discard := car_data.resize(data_point_count)
	var outsim_time_stamps: Array[int] = []
	_discard = outsim_time_stamps.resize(outsim_data.size())
	for i in outsim_time_stamps.size():
		outsim_time_stamps[i] = outsim_data[i].outsim_pack.time
	var first_time_stamp := outgauge_data[0].time
	for i in data_point_count:
		var new_car_data := CarData.new()
		var outgauge_packet := outgauge_data[i]
		new_car_data.time = (outgauge_packet.time - first_time_stamp) / 1000.0
		var dash_lights := outgauge_packet.get_lights_array(outgauge_packet.show_lights)
		new_car_data.tc_on = true if dash_lights[OutGaugePacket.DLFlags.DL_TC] == 1 else false
		new_car_data.abs_on = true if dash_lights[OutGaugePacket.DLFlags.DL_ABS] == 1 else false
		var outsim_pack := outsim_data[outsim_time_stamps.find(outgauge_packet.time)].outsim_pack
		new_car_data.fill_data_from_outsim_pack(outsim_pack)
		car_data[i] = new_car_data


func sort_packets() -> void:
	outsim_data.sort_custom(func(a: OutSimPacket, b: OutSimPacket) -> bool:
		return a.outsim_pack.time <= b.outsim_pack.time)
	outgauge_data.sort_custom(func(a: OutGaugePacket, b: OutGaugePacket) -> bool:
		return a.time <= b.time)


func write_to_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		return
	var titles := PackedStringArray(["Time", "PosX", "PosY", "PosZ", "VelX", "VelY", "VelZ",
			"AccX", "AccY", "AccZ", "RotX", "RotY", "RotZ", "AngVelX", "AngVelY", "AngVelZ",
			"Steer", "Throttle", "Brake", "Clutch", "HBrake", "ABS", "TC",
			"Gear", "RPM", "Torque", "LapDist", "IndexDist",
			"Speed", "LatG", "LonG", "VerG", "Pitch", "Roll",
			"WRLSusp", "WRLSteer", "WRLLat", "WRLLon", "WRLLoad", "WRLVel", "WRLLean",
			"WRLTemp", "WRLTouch", "WRLSlipFrac", "WRLSlipRatio", "WRLTanSlip",
			"WRRSusp", "WRRSteer", "WRRLat", "WRRLon", "WRRLoad", "WRRVel", "WRRLean",
			"WRRTemp", "WRRTouch", "WRRSlipFrac", "WRRSlipRatio", "WRRTanSlip",
			"WFLSusp", "WFLSteer", "WFLLat", "WFLLon", "WFLLoad", "WFLVel", "WFLLean",
			"WFLTemp", "WFLTouch", "WFLSlipFrac", "WFLSlipRatio", "WFLTanSlip",
			"WFRSusp", "WFRSteer", "WFRLat", "WFRLon", "WFRLoad", "WFRVel", "WFRLean",
			"WFRTemp", "WFRTouch", "WFRSlipFrac", "WFRSlipRatio", "WFRTanSlip",
			])
	file.store_csv_line(titles)
	for data in car_data:
		var values := PackedStringArray([
			data.time,
			data.position.x, data.position.y, data.position.z,
			data.velocity.x, data.velocity.y, data.velocity.z,
			data.acceleration.x, data.acceleration.y, data.acceleration.z,
			data.orientation.x, data.orientation.y, data.orientation.z,
			data.angular_velocity.x, data.angular_velocity.y, data.angular_velocity.z,
			data.steering, data.throttle, data.brake, data.clutch, data.handbrake,
			1 if data.abs_on else 0, 1 if data.tc_on else 0, data.gear, data.rpm, data.max_torque_at_rpm,
			data.lap_distance, data.indexed_distance,
			data.speed, data.g_forces.x, data.g_forces.y, data.g_forces.z, data.local_pitch, data.local_roll,
		])
		for i in data.wheel_data.size():
			values.append_array([
				data.wheel_data[i].suspension_deflection, data.wheel_data[i].steer,
				data.wheel_data[i].lateral_force, data.wheel_data[i].longitudinal_force,
				data.wheel_data[i].vertical_load, data.wheel_data[i].angular_velocity,
				data.wheel_data[i].lean_relative_to_road, data.wheel_data[i].air_temperature,
				1 if data.wheel_data[i].touching else 0, data.wheel_data[i].slip_fraction,
				data.wheel_data[i].slip_ratio, data.wheel_data[i].tangent_slip_angle,
			])
		file.store_csv_line(values)
