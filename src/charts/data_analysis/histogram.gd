class_name Histogram
extends RefCounted


var binned_data: Array[float] = []  ## Input data with outliers removed after binning
var bins: Array[float] = []  ## Center values of each bin, one less value than [member bin_edges]
var bin_edges: Array[float] = []  ## Bin delimiters, one more value than [member bins]
var data: Array[float] = []  ## Contains percentages values for each bin
var outliers := 0.0  ## Percentage of values not fitting in the bins


func generate_bins(bin_width: float, max_abs_value: float) -> void:
	var bin_count := 2 * int(max_abs_value / bin_width) + 1
	var min_bin_edge := -bin_count * bin_width / 2.0
	bins.clear()
	var _discard := bins.resize(bin_count)
	bin_edges.clear()
	_discard = bin_edges.resize(bin_count + 1)
	for i in bin_count + 1:
		bin_edges[i] = min_bin_edge + i * bin_width
		if i < bin_count:
			bins[i] = bin_edges[i] + bin_width / 2


func generate_histogram(input_data: Array[float], bin_limits: Array[float] = []) -> void:
	if bin_limits.is_empty():
		bin_limits = bin_edges
	var bin_count := bin_limits.size() - 1
	data.clear()
	var _discard := data.resize(bin_count)
	binned_data.clear()
	_discard = binned_data.resize(input_data.size())
	var idx := 0
	for value in input_data:
		for i in bin_count + 1:
			if value < bin_limits[i]:
				if i == 0:
					break
				data[i - 1] += 1
				binned_data[idx] = value
				idx += 1
				break
		if is_equal_approx(value, bin_limits[-1]):
			data[-1] += 1
			binned_data[idx] = value
			idx += 1
	var binned_points_count := idx
	_discard = binned_data.resize(binned_points_count)
	var point_count := input_data.size()
	outliers = 1 - binned_points_count / (point_count as float)
	data.assign(data.map(func(value: float) -> float: return value / point_count))
