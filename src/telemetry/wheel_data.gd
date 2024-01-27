class_name WheelData
extends RefCounted


enum WheelIndex {
	REAR_LEFT,
	REAR_RIGHT,
	FRONT_LEFT,
	FRONT_RIGHT,
}

var suspension_deflection := 0.0
var steer := 0.0
var lateral_force := 0.0
var longitudinal_force := 0.0
var vertical_load := 0.0
var angular_velocity := 0.0
var lean_relative_to_road := 0.0

var air_temperature := 0.0
var touching := false
var slip_fraction := 0.0
var slip_ratio := 0.0
var tangent_slip_angle := 0.0


func fill_data_from_outsim_wheel(outsim_wheel: OutSimWheel) -> void:
	suspension_deflection = outsim_wheel.susp_deflect
	steer = outsim_wheel.steer
	lateral_force = outsim_wheel.x_force
	longitudinal_force = outsim_wheel.y_force
	vertical_load = outsim_wheel.vertical_load
	angular_velocity = outsim_wheel.ang_vel
	lean_relative_to_road = outsim_wheel.lean_rel_to_road
	air_temperature = outsim_wheel.air_temp
	touching = true if outsim_wheel.touching > 0 else false
	slip_fraction = outsim_wheel.slip_fraction / 255.0
	slip_ratio = outsim_wheel.slip_ratio
	tangent_slip_angle = outsim_wheel.tan_slip_angle
