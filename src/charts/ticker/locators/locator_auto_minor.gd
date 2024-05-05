class_name LocatorAutoMinor
extends Locator


var divisions := 0


func _get_tick_locations() -> Array[float]:
	if axis.scale == Axis.Scale.LOGARITHMIC:
		push_error("LocatorAutoMinor does not work with logarithmic scale.")
		return []
	var major_locations := axis.major_ticks.locator.get_tick_locations()
	if major_locations.size() < 2:
		return []
	var major_step := major_locations[1] - major_locations[0]
	var major_step_no_exponent := 0.0
	if divisions <= 0:
		major_step_no_exponent = pow(10, log(major_step) / log(10))
		var steps: Array[float] = [1, 2.5, 5, 10]
		if steps.any(func(step: float) -> bool: return is_equal_approx(step, major_step_no_exponent)):
			divisions = 5
		else:
			divisions = 4
	var minor_step := major_step / divisions
	var vmin := axis.view_min
	var vmax := axis.view_max
	var t0 := major_locations[0]
	var tmin := roundi((vmin - t0) / minor_step)
	var tmax := roundi((vmax - t0) / minor_step) + divisions
	var locations: Array[float] = []
	var _discard := locations.resize(tmax - tmin)
	for i in locations.size():
		locations[i] = lerpf(t0, t0 + minor_step * (tmax - tmin), i as float / locations.size())
	return locations
