class_name DrawableLegend
extends Drawable


const MIN_CONTOURS := 1
const MAX_CONTOURS := 12

var discrete := false
var smooth_contours := true
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
	_title: String, _color_map: ColorMap, num_contours: int, min_value: float, max_value: float
) -> DrawableLegend:
	var legend := DrawableLegend.new()
	legend.title = _title
	legend.color_map = _color_map
	var contours := clampi(num_contours, MIN_CONTOURS, MAX_CONTOURS)
	var _discard := legend.values.resize(contours + 1)
	_discard = legend.colors.resize(contours)
	var delta := max_value - min_value
	for i in contours + 1:
		legend.values[i] = min_value + i * delta / contours
	return legend
