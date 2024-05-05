class_name Formatter
extends TickHelper


var locations: Array[float] = []


func _format_data(value: float) -> String:
	push_error("_format_data must be overridden")
	return "%f" % [value]


func format_ticks(values: Array[float]) -> Array[String]:
	locations.assign(values)
	var labels: Array[String] = []
	var _discard := labels.resize(locations.size())
	for i in locations.size():
		labels[i] = format_data(values[i])
	return labels


func format_data(value: float) -> String:
	return _format_data(value)


func fix_minus(string: String) -> String:
	return string.replace("-", "\u2212")
