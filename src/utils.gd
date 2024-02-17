class_name Utils
extends RefCounted


static func m_per_s_to_kph(value: float) -> float:
	return value * 3.6


static func m_per_s_to_mph(value: float) -> float:
	return value * 2.236_936_292


static func get_lap_time_string(lap_time: float) -> String:
	if lap_time < 0 or lap_time >= 6000:
		return "00:00.00"
	var minutes := floori(lap_time / 60)
	var seconds := lap_time - minutes * 60
	return "%s%05.2f" % ["" if lap_time < 60 else "%d:" % [minutes], seconds]


static func rad_per_second_to_rpm(value: float) -> float:
	return value / (2 * PI) * 60


static func rpm_to_rad_per_second(value: float) -> float:
	return value * 2 * PI / 60
