class_name Ticker
extends RefCounted


var locator: Locator = null
var formatter: Formatter = null


func set_axis(axis: Axis) -> void:
	locator.axis = axis
	formatter.axis = axis
