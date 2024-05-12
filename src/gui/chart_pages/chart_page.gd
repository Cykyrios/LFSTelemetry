class_name ChartPage
extends ScrollContainer


var stale := false


var main_lap: LapData = null:
	set(new_lap):
		main_lap = new_lap
		update_chart_creator()
var reference_lap: LapData = null:
	set(new_lap):
		reference_lap = new_lap
		update_chart_creator()

var chart_creator: ChartCreator = null


func _draw_charts() -> void:
	while get_child_count() > 0:
		var child := get_children()[-1]
		remove_child(child)
		child.queue_free()


func draw_charts() -> void:
	_draw_charts()


func refresh_charts() -> void:
	for child in get_children():
		_refresh_charts(self)


func update_chart_creator() -> void:
	chart_creator = ChartCreator.new(main_lap, reference_lap)


func _refresh_charts(node: Node = self) -> void:
	await get_tree().process_frame
	for child in node.get_children():
		if child is Chart:
			(child as Chart).queue_redraw()
		else:
			_refresh_charts(child)
