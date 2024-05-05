class_name Axis
extends RefCounted


var font := preload("res://src/charts/RecursiveSansLnrSt-Regular.otf")

enum Position {BOTTOM_LEFT, TOP_RIGHT}
enum Scale {Linear, Logarithmic}

var position := Position.BOTTOM_LEFT
var autoscale := true
var scale := Scale.Linear
var symmetric := false

var major_ticks: Ticker = null
var minor_ticks: Ticker = null

var data_min := -INF
var data_max := INF
var view_min := -INF
var view_max := INF

var figure_size := 0.0
var axis_padding := Vector2.ZERO

var major_tick_color := Color(0.5, 0.5, 0.5, 1)
var minor_tick_color := Color(0.5, 0.5, 0.5, 0.3)


func _init() -> void:
	major_ticks = Ticker.new()
	var major_formatter := FormatterScalar.new()
	major_formatter.scientific = false
	major_ticks.formatter = major_formatter
	major_ticks.locator = LocatorAuto.new()
	major_ticks.set_axis(self)
	minor_ticks = Ticker.new()
	var minor_formatter := FormatterScalar.new()
	minor_formatter.scientific = false
	minor_ticks.formatter = minor_formatter
	minor_ticks.locator = LocatorAuto.new()
	minor_ticks.set_axis(self)

	var text := TextLine.new()
	var _string := text.add_string("00000", font, 12)
	axis_padding.x = text.get_line_width() * 1.2
	axis_padding.y = (text.get_line_ascent() + text.get_line_descent()) * 2


func get_tick_space() -> int:
	return floori(figure_size / axis_padding.y * 2)


func set_scale(new_scale: Scale) -> void:
	scale = new_scale
	if scale == Scale.Logarithmic:
		set_view_limits(view_min, view_max)


func set_view_limits(vmin := -INF, vmax := INF) -> void:
	if scale == Scale.Logarithmic:
		vmin = maxf(vmin, 1e-6)
		vmax = maxf(vmax, 1e-6)
	if is_equal_approx(vmin, vmax):
		vmin -= 1
		vmax += 1
	view_min = vmin
	view_max = vmax


func update_view_interval() -> void:
	var limits := major_ticks.locator.view_limits(data_min, data_max)
	view_min = limits.x
	view_max = limits.y
	if is_equal_approx(view_min, view_max):
		view_min -= 1
		view_max += 1


func _update_ticks() -> void:
	pass
