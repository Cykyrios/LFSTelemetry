class_name FormatterScalar
extends Formatter


var order_of_magnitude := 0
var format := ""
var scientific := true
var scientific_low := 1e-3
var scientific_high := 1e5


func _format_data(value: float) -> String:
	return format_scalar(value)


func format_scalar(value: float) -> String:
	if not scientific or absf(value) < scientific_low or absf(value) > scientific_high:
		var string := "%f" % [value]
		return trim_trailing_decimal_zeros(string)
	var e := floori(log(absf(value)) / log(10))
	var s := snappedf(value / pow(10, e), 1e-10)
	var significand := fix_minus(("%d" if is_equal_approx(s, roundi(s)) else "%f") % [s])
	while significand.ends_with("0"):
		significand = significand.trim_suffix("0")
	significand = significand.trim_suffix(".")
	if e == 0:
		return significand
	var exponent := "%d" % [e]
	return significand + "e" + exponent


func trim_trailing_decimal_separator(string: String) -> String:
	return string.trim_suffix(".")


func trim_trailing_decimal_zeros(string: String) -> String:
	if not string.contains("."):
		return string
	if not string.ends_with("."):
		while string.ends_with("0"):
			string = string.trim_suffix("0")
	return trim_trailing_decimal_separator(string)
