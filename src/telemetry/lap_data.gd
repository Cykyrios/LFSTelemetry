class_name LapData
extends RefCounted


const IO_HEADER_BUFFER := 68
const IO_SECTOR_BUFFER := 13
const IO_LAP_BUFFER := 103
const IO_WHEEL_BUFFER := 42

var date := ""
var track := ""
var weather := 0
var wind := 0
var driver := ""
var car := ""
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


#region I/O
func export_csv(path: String) -> void:
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


func load_from_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		return
	var packet := LFSPacket.new()
	packet.buffer = file.get_buffer(IO_HEADER_BUFFER)
	date = packet.read_string(19)
	track = packet.read_string(6)
	weather = packet.read_byte()
	wind = packet.read_byte()
	driver = packet.read_string(24)
	car = packet.read_string(6)
	lap_number = packet.read_word()
	lap_time = packet.read_float()
	total_time = packet.read_float()
	var sector_count := packet.read_byte()
	packet.buffer = file.get_buffer(sector_count * IO_SECTOR_BUFFER)
	packet.data_offset = 0
	sectors.clear()
	for i in sector_count:
		var sector := SectorData.new()
		sector.sector_number = packet.read_byte()
		sector.sector_time = packet.read_float()
		sector.split_time = packet.read_float()
		sector.total_time = packet.read_float()
		sectors.append(sector)
	car_data.clear()
	while file.get_position() < file.get_length():
		packet.buffer = file.get_buffer(IO_LAP_BUFFER)
		packet.data_offset = 0
		var data := CarData.new()
		data.time = packet.read_float()
		data.position.x = packet.read_float()
		data.position.y = packet.read_float()
		data.position.z = packet.read_float()
		data.velocity.x = packet.read_float()
		data.velocity.y = packet.read_float()
		data.velocity.z = packet.read_float()
		data.acceleration.x = packet.read_float()
		data.acceleration.y = packet.read_float()
		data.acceleration.z = packet.read_float()
		data.orientation.x = packet.read_float()
		data.orientation.y = packet.read_float()
		data.orientation.z = packet.read_float()
		data.angular_velocity.x = packet.read_float()
		data.angular_velocity.y = packet.read_float()
		data.angular_velocity.z = packet.read_float()
		data.steering = packet.read_float()
		data.throttle = packet.read_float()
		data.brake = packet.read_float()
		data.clutch = packet.read_float()
		data.handbrake = packet.read_float()
		data.abs_on = true if packet.read_byte() > 0 else false
		data.tc_on = true if packet.read_byte() > 0 else false
		data.gear = packet.read_byte() - 1
		data.rpm = packet.read_float()
		data.max_torque_at_rpm = packet.read_float()
		data.lap_distance = packet.read_float()
		data.indexed_distance = packet.read_float()
		for i in WheelData.WheelIndex.size():
			var wheel_data := WheelData.new()
			packet.buffer = file.get_buffer(IO_WHEEL_BUFFER)
			packet.data_offset = 0
			wheel_data.suspension_deflection = packet.read_float()
			wheel_data.steer = packet.read_float()
			wheel_data.lateral_force = packet.read_float()
			wheel_data.longitudinal_force = packet.read_float()
			wheel_data.vertical_load = packet.read_float()
			wheel_data.angular_velocity = packet.read_float()
			wheel_data.lean_relative_to_road = packet.read_float()
			wheel_data.air_temperature = packet.read_byte()
			wheel_data.touching = true if packet.read_byte() > 0 else false
			wheel_data.slip_fraction = packet.read_float()
			wheel_data.slip_ratio = packet.read_float()
			wheel_data.tangent_slip_angle = packet.read_float()
			data.wheel_data.append(wheel_data)
		car_data.append(data)
	compute_derived_data()


func save_to_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		return
	var packet := LFSPacket.new()
	var sector_count := sectors.size()
	packet.resize_buffer(IO_HEADER_BUFFER + sector_count * IO_SECTOR_BUFFER)
	packet.add_string(19, date)
	packet.add_string(6, track)
	packet.add_byte(weather)
	packet.add_byte(wind)
	packet.add_string(24, driver)
	packet.add_string(6, car)
	packet.add_word(lap_number)
	packet.add_float(lap_time)
	packet.add_float(total_time)
	packet.add_byte(sector_count)
	for sector in sectors:
		packet.add_byte(sector.sector_number)
		packet.add_float(sector.sector_time)
		packet.add_float(sector.split_time)
		packet.add_float(sector.total_time)
	file.store_buffer(packet.buffer)
	for data in car_data:
		packet = LFSPacket.new()
		packet.resize_buffer(IO_LAP_BUFFER + data.wheel_data.size() * IO_WHEEL_BUFFER)
		packet.add_float(data.time)
		packet.add_float(data.position.x)
		packet.add_float(data.position.y)
		packet.add_float(data.position.z)
		packet.add_float(data.velocity.x)
		packet.add_float(data.velocity.y)
		packet.add_float(data.velocity.z)
		packet.add_float(data.acceleration.x)
		packet.add_float(data.acceleration.y)
		packet.add_float(data.acceleration.z)
		packet.add_float(data.orientation.x)
		packet.add_float(data.orientation.y)
		packet.add_float(data.orientation.z)
		packet.add_float(data.angular_velocity.x)
		packet.add_float(data.angular_velocity.y)
		packet.add_float(data.angular_velocity.z)
		packet.add_float(data.steering)
		packet.add_float(data.throttle)
		packet.add_float(data.brake)
		packet.add_float(data.clutch)
		packet.add_float(data.handbrake)
		packet.add_byte(1 if data.abs_on else 0)
		packet.add_byte(1 if data.tc_on else 0)
		packet.add_byte(data.gear + 1)
		packet.add_float(data.rpm)
		packet.add_float(data.max_torque_at_rpm)
		packet.add_float(data.lap_distance)
		packet.add_float(data.indexed_distance)
		for wheel_data in data.wheel_data:
			packet.add_float(wheel_data.suspension_deflection)
			packet.add_float(wheel_data.steer)
			packet.add_float(wheel_data.lateral_force)
			packet.add_float(wheel_data.longitudinal_force)
			packet.add_float(wheel_data.vertical_load)
			packet.add_float(wheel_data.angular_velocity)
			packet.add_float(wheel_data.lean_relative_to_road)
			packet.add_byte(wheel_data.air_temperature)
			packet.add_byte(1 if wheel_data.touching else 0)
			packet.add_float(wheel_data.slip_fraction)
			packet.add_float(wheel_data.slip_ratio)
			packet.add_float(wheel_data.tangent_slip_angle)
		file.store_buffer(packet.buffer)
#endregion
