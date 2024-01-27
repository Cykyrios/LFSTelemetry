class_name Utils
extends RefCounted


static func rad_per_second_to_rpm(value: float) -> float:
	return value / (2 * PI) * 60


static func rpm_to_rad_per_second(value: float) -> float:
	return value * 2 * PI / 60
