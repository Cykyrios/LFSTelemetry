class_name DamperHistogram
extends Histogram


var slow_speed_boundary := 0.0  ## Slow speed range
var bump_low := 0.0
var bump_high := 0.0
var bump_average := 0.0
var rebound_low := 0.0
var rebound_high := 0.0
var rebound_average := 0.0


func _init(input_data: Array[float] = [], bin_width := 0.0, max_abs_value := 0.0, slow_speed := 0.0
) -> void:
	if input_data.is_empty() or bin_width == 0 or max_abs_value == 0 or slow_speed == 0:
		return
	slow_speed_boundary = absf(slow_speed)
	generate_bins(bin_width, max_abs_value)
	generate_histogram(input_data)


func generate_histogram(input_data: Array[float], bin_limits: Array[float] = []) -> void:
	super(input_data, bin_limits)
	compute_damper_values()


func compute_damper_values() -> void:
	var point_count := binned_data.size()
	bump_low = 0
	bump_high = 0
	bump_average = 0
	rebound_low = 0
	rebound_high = 0
	rebound_average = 0
	slow_speed_boundary = absf(slow_speed_boundary)
	for value in binned_data:
		if value > 0:
			bump_average += value
			if value > slow_speed_boundary:
				bump_high += 1
			else:
				bump_low += 1
		else:
			rebound_average -= value
			if value < -slow_speed_boundary:
				rebound_high += 1
			else:
				rebound_low += 1
	bump_low /= point_count
	bump_high /= point_count
	bump_average /= point_count
	rebound_low /= point_count
	rebound_high /= point_count
	rebound_average /= point_count
