class_name FormatterPercent
extends Formatter


func _format_data(value: float) -> String:
	return format_percent(value)


func format_percent(value: float) -> String:
	return "%d%%" % [int(100 * value)]
