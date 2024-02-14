class_name Utils
extends RefCounted


static func m_per_s_to_kph(value: float) -> float:
	return value * 3.6


static func m_per_s_to_mph(value: float) -> float:
	return value * 2.236_936_292


static func rad_per_second_to_rpm(value: float) -> float:
	return value / (2 * PI) * 60


static func rpm_to_rad_per_second(value: float) -> float:
	return value * 2 * PI / 60
