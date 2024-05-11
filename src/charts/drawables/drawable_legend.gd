class_name DrawableLegend
extends Drawable


const MIN_STEPS := 2
const MAX_STEPS := 12

var discrete := false
var color_map: ColorMap = null
var values: Array[float] = []
var colors: Array[Color] = []
var title := ""


static func generate_discrete_legend(
	_title: String, _color_map: ColorMap, _values: Array[float]
) -> DrawableLegend:
	var legend := DrawableLegend.new()
	legend.title = _title
	legend.discrete = true
	legend.color_map = _color_map
	legend.values.assign(_values)
	var steps := _values.size()
	var _discard := legend.colors.resize(steps)
	for i in steps:
		legend.colors[i] = legend.color_map.get_color(legend.color_map.get_normalized_value(
				legend.values[i], legend.values[0], legend.values[-1]))
	return legend


static func generate_contour_legend(
	_title: String, _color_map: ColorMap, _steps: int, min_value: float, max_value: float
) -> DrawableLegend:
	var legend := DrawableLegend.new()
	legend.title = _title
	legend.color_map = _color_map
	var steps := clampi(_steps, MIN_STEPS, MAX_STEPS)
	var _discard := legend.values.resize(steps)
	_discard = legend.colors.resize(steps - 1)
	var delta := max_value - min_value
	for i in steps:
		legend.values[i] = min_value + i * delta / steps
		#legend.colors[i] = legend.color_map.get_color(legend.color_map.get_normalized_value(
				#legend.values[i], min_value, max_value))
	return legend
