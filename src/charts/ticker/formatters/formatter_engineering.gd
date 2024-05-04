class_name FormatterEngineering
extends Formatter


const PREFIXES := {
	-12: "p",
	-9: "n",
	-6: "µ",
	-3: "m",
	0: "",
	3: "k",
	6: "M",
	9: "G",
	12: "T",
}

var unit := ""
var places := 0
var separator := ""


func _format_data(value: float) -> String:
	var s := "%s%s" % [format_engineering(value), unit]
	s = s.trim_suffix(separator)
	return fix_minus(s)


func format_engineering(value: float) -> String:
	var format := ("%%.%df" % [places]) if places >= 0 else "%f"
	var power10 := 0
	if is_zero_approx(value):
		value = 0
	else:
		power10 = int(floorf(log(absf(value)) / log(10) / 3) * 3)
	power10 = clampi(power10, PREFIXES.keys().min() as int, PREFIXES.keys().max() as int)
	var mantissa := signf(value) * absf(value) / pow(10, power10)
	if absf((format % [mantissa]).to_float()) >= 1000 and power10 < PREFIXES.keys().max() as int:
		mantissa /= 1000
		power10 += 3
	var prefix := PREFIXES[power10] as String
	var number := format % [mantissa]
	if places < 0:
		while number.ends_with("0"):
			number = number.trim_suffix("0")
		number = number.trim_suffix(".")
	return number + "%s%s" % [separator, prefix]
