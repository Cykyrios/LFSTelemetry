class_name TrackPath
extends RefCounted


var finish_line_idx := 0
var nodes: Array[PathNode] = []


func get_path_length() -> float:
	if nodes.is_empty():
		return 0
	var length := 0.0
	for i in nodes.size():
		length += (nodes[i].position - nodes[i - 1].position).length()
	return length
