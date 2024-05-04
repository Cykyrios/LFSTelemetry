class_name LocatorMaxN
extends Locator


var intervals := 9
var auto_intervals := true
var steps: Array[float] = [1, 2, 2.5, 3, 4, 5, 10]
var integer := false
var symmetric := false
var prune_edges := false
var min_ticks := 2


func _get_tick_locations() -> Array[float]:
	axis.update_view_interval()
	return get_tick_values(axis.view_min, axis.view_max)


func _get_tick_values(vmin: float, vmax: float) -> Array[float]:
	if symmetric:
		vmax = maxf(absf(vmin), absf(vmax))
		vmin = -vmax
	if is_equal_approx(vmin, vmax):
		vmin -= 1
		vmax += 1
	var locations := _raw_ticks(vmin, vmax)
	if prune_edges:
		locations = locations.slice(1, locations.size() - 1)
	return locations


func view_limits(dmin: float, dmax: float) -> Vector2:
	if symmetric:
		dmax = maxf(absf(dmax), absf(dmin))
		dmin = -dmax
	if is_equal_approx(dmin, dmax):
		dmin -= 1
		dmax += 1
	return Vector2(dmin, dmax)


func _validate_steps() -> void:
	if steps.is_empty():
		steps = [1, 2, 5, 10]
		return
	steps.sort()
	steps.assign(steps.filter(func(value: float) -> bool: return value >= 1 and value <= 10))
	if steps[0] != 1:
		steps.push_front(1)
	if steps[-1] != 10:
		steps.push_back(10)


func _staircase() -> Array[float]:
	var smaller_steps: Array[float] = []
	smaller_steps.assign(steps.map(func(value: float) -> float: return 0.1 * value))
	smaller_steps.append_array(steps)
	smaller_steps.append(10 * steps[1])
	return smaller_steps


func _raw_ticks(vmin: float, vmax: float) -> Array[float]:
	var _intervals := intervals
	if auto_intervals:
		if axis:
			_intervals = clampi(axis.get_tick_space(), maxi(1, min_ticks - 1), 9)
		else:
			_intervals = 9
	var scale := scale_range(vmin, vmax, _intervals)
	var _steps: Array[float] = []
	_steps.assign(steps.map(func(value: float) -> float: return value * scale))
	if integer:
		_steps.assign(_steps.filter(func(value: float) -> bool:
			return value < 1 or absf(value - roundf(value)) < 1e-3))
	var raw_step := (vmax - vmin) / _intervals
	var large_steps: Array[float] = []
	large_steps.assign(_steps.filter(func(value: float) -> bool: return value >= raw_step))
	var edge_le := func edge_le(x: float, step: float) -> int:
		var d := floori(x / step)
		var m := fmod(x, step)
		if is_equal_approx(m / step, 1):
			return d + 1
		return d
	var edge_ge := func edge_ge(x: float, step: float) -> int:
		var d := floori(x / step)
		var m := fmod(x, step)
		if is_equal_approx(m / step, 0):
			return d + 1
		return d
	var istep := _steps.find((large_steps.filter(func(value: float) -> bool:
		return value > 0) as Array[float])[0])
	var ticks: Array[float] = []
	for i in range(istep, -1, -1):
		var step := _steps[i]
		if integer and floorf(vmax) - ceilf(vmin) >= min_ticks - 1:
			step = maxf(1, step)
		var best_vmin := floorf(vmin / step) * step
		var low := edge_le.call(vmin - best_vmin, step) as int
		var high := edge_ge.call(vmax - best_vmin, step) as int
		ticks.assign(range(low, high + 1).map(func(value: float) -> float:
			return value * step + best_vmin))
		var nticks := (ticks.filter(func(value: float) -> bool:
			return value <= vmax and value >= vmin)).size()
		if nticks >= min_ticks:
			break
	return ticks
