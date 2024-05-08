class_name LapData
extends RefCounted


enum LapFlag {
	INLAP = 1,
	OUTLAP = 2,
}

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
var inlap := false
var outlap := false

var car_data: Array[CarData] = []

var outsim_data: Array[OutSimPacket] = []
var outgauge_data: Array[OutGaugePacket] = []


func compute_derived_data() -> void:
	for data in car_data:
		data.compute_derived_values()
	for i in car_data.size():
		if i == 0:
			continue
		var current_car := car_data[i]
		var previous_car := car_data[i - 1]
		var dt := current_car.time - previous_car.time
		for j in WheelData.WheelIndex.size():
			var current_wheel := current_car.wheel_data[j]
			var previous_wheel := previous_car.wheel_data[j]
			var suspension_delta := current_wheel.suspension_deflection \
					- previous_wheel.suspension_deflection
			current_wheel.suspension_speed = suspension_delta / dt
	# Fill first data point with zeros or copy second data point
	for j in WheelData.WheelIndex.size():
		car_data[0].wheel_data[j] = car_data[1].wheel_data[j]


func fill_car_data() -> void:
	# OutGauge is more reliable as OutSim only records in cockpit or custom views
	var data_point_count := outgauge_data.size()
	if data_point_count == 0:
		return
	var _discard := car_data.resize(data_point_count)
	var outsim_time_stamps: Array[int] = []
	_discard = outsim_time_stamps.resize(outsim_data.size())
	for i in outsim_time_stamps.size():
		outsim_time_stamps[i] = outsim_data[i].outsim_pack.time
	var first_time_stamp := outgauge_data[0].time
	for i in data_point_count:
		var new_car_data := CarData.new()
		var outgauge_packet := outgauge_data[i]
		new_car_data.timestamp = outgauge_packet.time
		new_car_data.time = (outgauge_packet.time - first_time_stamp) / 1000.0
		var dash_lights := outgauge_packet.get_lights_array(outgauge_packet.show_lights)
		new_car_data.tc_on = true if dash_lights[OutGaugePacket.DLFlags.DL_TC] == 1 else false
		new_car_data.abs_on = true if dash_lights[OutGaugePacket.DLFlags.DL_ABS] == 1 else false
		var outsim_idx := outsim_time_stamps.find(outgauge_packet.time)
		var outsim_pack := OutSimPack.new() if outsim_idx < 0 else outsim_data[outsim_idx].outsim_pack
		new_car_data.fill_data_from_outsim_pack(outsim_pack)
		car_data[i] = new_car_data


func get_lap_flags() -> int:
	var flags := 0
	flags |= (LapFlag.INLAP if inlap else 0) | (LapFlag.OUTLAP if outlap else 0)
	return flags


func set_lap_flags(flags: int) -> void:
	inlap = flags & LapFlag.INLAP
	outlap = flags & LapFlag.OUTLAP


func sort_packets() -> void:
	outsim_data.sort_custom(func(a: OutSimPacket, b: OutSimPacket) -> bool:
		return a.outsim_pack.time <= b.outsim_pack.time)
	outgauge_data.sort_custom(func(a: OutGaugePacket, b: OutGaugePacket) -> bool:
		return a.time <= b.time)
