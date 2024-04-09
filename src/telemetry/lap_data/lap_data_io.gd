class_name LapDataIO
extends RefCounted  # RefCounted or Resource?


const LATEST_LAP_DATA_VERSION := 1

var file_version := LATEST_LAP_DATA_VERSION
var header_buffer_size := 0
var sector_buffer_size := 0
var lap_buffer_size := 0
var wheel_buffer_size := 0


func export_csv(path: String, lap_data: LapData) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		return
	var general_titles: Array[String] = ["Date", "Track", "Weather", "Wind", "Driver", "Car",
			"Lap Num", "Lap Time", "Total Time"]
	for i in lap_data.sectors.size():
		general_titles.append("Sector %d" % [i])
	general_titles.append_array(["Inlap", "Outlap"])
	file.store_csv_line(PackedStringArray(general_titles))
	var general_data: Array[String] = [
		lap_data.date,
		lap_data.track,
		"%d" % [lap_data.weather],
		"%d" % [lap_data.wind],
		lap_data.driver,
		lap_data.car,
		"%d" % [lap_data.lap_number],
		"%f" % [lap_data.lap_time],
		"%f" % [lap_data.total_time],
	]
	for sector in lap_data.sectors:
		general_data.append("%f" % [sector.sector_time])
	general_data.append_array([
		"true" if lap_data.inlap else "false",
		"true" if lap_data.outlap else "false",
	])
	file.store_csv_line(PackedStringArray(general_data))
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
	for data in lap_data.car_data:
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


func load_lap_file(lap_file: String, skip_telemetry := false) -> LapData:
	var lap_data := LapData.new()
	var file := FileAccess.open(lap_file, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		push_warning("Failed to open lap file %s: error %d" % [lap_file, error])
		return lap_data
	var first_byte := file.get_8()
	file_version = first_byte
	_update_file_version(file_version)
	var packet := LFSPacket.new()
	packet.buffer = file.get_buffer(header_buffer_size)
	if file_version < 1:
		packet.buffer.reverse()
		var _discard := packet.buffer.append(first_byte)  # actually part of first data item
		packet.buffer.reverse()
	else:
		pass
	_read_header(lap_data, packet)
	var sector_count := file.get_8()
	packet.buffer = file.get_buffer(sector_count * sector_buffer_size)
	packet.data_offset = 0
	_read_sectors(lap_data, sector_count, packet)
	if skip_telemetry:
		return lap_data
	lap_data.car_data.clear()
	_read_car_data(lap_data, file)
	lap_data.compute_derived_data()
	return lap_data


func save_lap_file(path: String, lap_data: LapData) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		return
	_update_file_version(LATEST_LAP_DATA_VERSION)
	file.store_8(file_version)
	_save_header(file, lap_data)
	# NOTE: sector count not saved in header to account for offset due to version
	_save_sectors(file, lap_data)
	_save_car_data(file, lap_data)


func _read_car_data(lap_data: LapData, file: FileAccess) -> void:
	var packet := LFSPacket.new()
	while file.get_position() < file.get_length():
		packet.buffer = file.get_buffer(lap_buffer_size)
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
			packet.buffer = file.get_buffer(wheel_buffer_size)
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
		lap_data.car_data.append(data)


func _read_header(lap_data: LapData, packet: LFSPacket) -> void:
	lap_data.date = packet.read_string_as_utf8(19)
	lap_data.track = packet.read_string_as_utf8(6)
	lap_data.weather = packet.read_byte()
	lap_data.wind = packet.read_byte()
	lap_data.driver = packet.read_string_as_utf8(24)
	lap_data.car = packet.read_string_as_utf8(6)
	lap_data.lap_number = packet.read_word()
	if file_version >= 1:
		lap_data.set_lap_flags(packet.read_byte())
	lap_data.lap_time = packet.read_float()
	lap_data.total_time = packet.read_float()


func _read_sectors(lap_data: LapData, sector_count: int, packet: LFSPacket) -> void:
	lap_data.sectors.clear()
	for i in sector_count:
		var sector := SectorData.new()
		sector.sector_number = packet.read_byte()
		sector.sector_time = packet.read_float()
		sector.split_time = packet.read_float()
		sector.total_time = packet.read_float()
		lap_data.sectors.append(sector)


func _save_car_data(file: FileAccess, lap_data: LapData) -> void:
	var packet := LFSPacket.new()
	for data in lap_data.car_data:
		packet.resize_buffer(lap_buffer_size + data.wheel_data.size() * wheel_buffer_size)
		packet.data_offset = 0
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


func _save_header(file: FileAccess, lap_data: LapData) -> void:
	var packet := LFSPacket.new()
	packet.resize_buffer(header_buffer_size)
	packet.add_string_as_utf8(19, lap_data.date)
	packet.add_string_as_utf8(6, lap_data.track)
	packet.add_byte(lap_data.weather)
	packet.add_byte(lap_data.wind)
	packet.add_string_as_utf8(24, lap_data.driver)
	packet.add_string_as_utf8(6, lap_data.car)
	packet.add_word(lap_data.lap_number)
	packet.add_byte(lap_data.get_lap_flags())
	packet.add_float(lap_data.lap_time)
	packet.add_float(lap_data.total_time)
	file.store_buffer(packet.buffer)


func _save_sectors(file: FileAccess, lap_data: LapData) -> void:
	var packet := LFSPacket.new()
	var sector_count := lap_data.sectors.size()
	packet.resize_buffer(1 + sector_count * sector_buffer_size)
	packet.add_byte(sector_count)
	for sector in lap_data.sectors:
		packet.add_byte(sector.sector_number)
		packet.add_float(sector.sector_time)
		packet.add_float(sector.split_time)
		packet.add_float(sector.total_time)
	file.store_buffer(packet.buffer)


func _update_file_version(version: int) -> void:
	# First data byte should be format version, if text is found (lap date), version is 0.
	if version >= "0".unicode_at(0):
		version = 0
	file_version = version
	if version < 1:
		header_buffer_size = 66
		sector_buffer_size = 13
		lap_buffer_size = 103
		wheel_buffer_size = 42
	else:
		header_buffer_size = 68
		sector_buffer_size = 13
		lap_buffer_size = 103
		wheel_buffer_size = 42
