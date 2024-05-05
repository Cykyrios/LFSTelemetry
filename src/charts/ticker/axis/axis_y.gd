class_name AxisY
extends Axis


func get_tick_space() -> int:
	return floori(figure_size / axis_padding.y)
