class_name Locator
extends TickHelper


const MAX_TICKS := 1000


@warning_ignore("unused_parameter")
func _get_tick_values(vmin: float, vmax: float) -> Array[float]:
	push_error("tick_values must be overridden")
	return []


func _get_tick_locations() -> Array[float]:
	push_error("_get_tick_locations must be overridden")
	return []


func _view_limits(vmin: float, vmax: float) -> Vector2:
	if is_equal_approx(vmin, vmax):
		vmin -= 1
		vmax += 1
	return Vector2(vmin, vmax)


func get_tick_locations() -> Array[float]:
	return _get_tick_locations()


func scale_range(vmin: float, vmax: float, n := 1) -> float:
	var delta := absf(vmax - vmin)
	if is_zero_approx(delta):
		vmin -= 1
		vmax += 1
	var scale := pow(10, floorf(log(delta / n) / log(10)))
	return scale


func get_tick_values(vmin: float, vmax: float) -> Array[float]:
	return _get_tick_values(vmin, vmax)


func view_limits(vmin: float, vmax: float) -> Vector2:
	return _view_limits(vmin, vmax)
