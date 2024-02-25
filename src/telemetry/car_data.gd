class_name CarData
extends RefCounted


const GRAVITY := 9.81

var time := 0.0

var position := Vector3.ZERO
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var orientation := Vector3.ZERO
var angular_velocity := Vector3.ZERO

var steering := 0.0
var throttle := 0.0
var brake := 0.0
var clutch := 0.0
var handbrake := 0.0

var abs_on := false
var tc_on := false

var gear := 0
var rpm := 0.0
var max_torque_at_rpm := 0.0

var lap_distance := 0.0
var indexed_distance := 0.0

var wheel_data: Array[WheelData] = []

var speed := 0.0  ## Magnitude of velocity, km/h
var g_forces := Vector3.ZERO  ## Right, Forward, Up
var local_pitch := 0.0
var local_roll := 0.0

@warning_ignore("unused_private_class_variable")
var _session_time := 0.0


func compute_derived_values() -> void:
	speed = velocity.length()
	var basis := Basis.from_euler(orientation, EULER_ORDER_ZXY)
	g_forces = acceleration * basis / GRAVITY
	local_pitch = (orientation * basis).x
	local_roll = (orientation * basis).y


func fill_data_from_outsim_pack(outsim_pack: OutSimPack) -> void:
	var outsim_main := outsim_pack.os_main
	position = Vector3(outsim_main.pos) / 65536
	velocity = outsim_main.vel
	acceleration = outsim_main.accel
	orientation = Vector3(outsim_main.pitch, outsim_main.roll, outsim_main.heading)
	angular_velocity = outsim_main.ang_vel

	var outsim_inputs := outsim_pack.os_inputs
	steering = rad_to_deg(outsim_inputs.input_steer)
	throttle = outsim_inputs.throttle
	brake = outsim_inputs.brake
	clutch = outsim_inputs.clutch
	handbrake = outsim_inputs.handbrake

	gear = outsim_pack.gear - 1  # OutSim stores reverse as 0, 1 as neutral, 2 as 1st gear, etc.
	rpm = Utils.rad_per_second_to_rpm(outsim_pack.engine_ang_vel)
	max_torque_at_rpm = outsim_pack.max_torque_at_vel

	lap_distance = outsim_pack.current_lap_distance
	indexed_distance = outsim_pack.indexed_distance

	for outsim_wheel in outsim_pack.os_wheels:
		var wheel := WheelData.new()
		wheel.fill_data_from_outsim_wheel(outsim_wheel)
		wheel_data.append(wheel)
