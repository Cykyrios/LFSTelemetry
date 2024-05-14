class_name DataFixer
extends RefCounted


static func fix_indexed_distance(lap: LapData, track_path: TrackPath) -> Array[float]:
	var point_count := lap.car_data.size()
	var indexed_distance: Array[float] = []
	var _discard := indexed_distance.resize(point_count)
	var position: Array[Vector3] = []
	_discard = position.resize(point_count)
	for i in point_count:
		position[i] = lap.car_data[i].position
		var closest_node := get_closest_node_to_pos(track_path, position[i])
		var node_idx := track_path.nodes.find(closest_node)
		var next_node := track_path.nodes[wrapi(node_idx + 1, 0, track_path.nodes.size())]
		var prev_node := track_path.nodes[node_idx - 1]
		var delta := position[i] - closest_node.position
		var node_dot := delta.dot(next_node.position - closest_node.position)
		var distance := 0.0
		if node_dot > 0:
			distance = delta.project(next_node.position - closest_node.position).length()
			indexed_distance[i] = get_path_length_up_to_node(track_path, closest_node) + distance
		else:
			distance = (position[i] - prev_node.position).project(
					prev_node.position - closest_node.position).length()
			indexed_distance[i] = get_path_length_up_to_node(track_path, prev_node) + distance
	if indexed_distance[0] > indexed_distance[-1]:
		var max_distance := indexed_distance.max() as float
		var min_distance := indexed_distance.min() as float
		var max_delta := max_distance - min_distance
		var path_length := track_path.get_path_length()
		var overflow_idx := 0
		for i in point_count:
			if is_equal_approx(absf(indexed_distance[i] - indexed_distance[i - 1]), max_delta):
				overflow_idx = i
				break
		# Offset finish line node by half track length
		# and recompute distance delta at overflow point
		track_path.finish_line_idx -= int(track_path.nodes.size() / 2.0)
		var overflow_lap := LapData.new()
		for i in 2:
			overflow_lap.car_data.append(CarData.new())
			overflow_lap.car_data[i].position = lap.car_data[overflow_idx - 1 + i].position
		var overflow_distances := fix_indexed_distance(overflow_lap, track_path)
		var overflow_offset := max_delta + overflow_distances[1] - overflow_distances[0]
		for i in point_count - overflow_idx:
			indexed_distance[overflow_idx + i] += overflow_offset
		max_distance = indexed_distance.max() as float
		if max_distance > path_length:
			var first_point := indexed_distance[0]
			for i in point_count:
				indexed_distance[i] -= first_point
	return indexed_distance


static func get_closest_node_to_pos(track_path: TrackPath, position: Vector3) -> PathNode:
	var idx := 0
	var min_distance := INF
	var num_nodes := track_path.nodes.size()
	for i in num_nodes:
		var distance := (position - track_path.nodes[i].position).length_squared()
		#print("%v\t%d\t%v\t%.12f" % [position, i, track_path.nodes[i].position, sqrt(distance)])
		if distance < min_distance:
			min_distance = distance
			idx = i
	return track_path.nodes[idx]


static func get_path_length_up_to_node(track_path: TrackPath, node: PathNode) -> float:
	var distance := 0.0
	var num_nodes := track_path.nodes.size()
	var node_idx := track_path.nodes.find(node)
	if node_idx == track_path.finish_line_idx:
		return 0
	var i := track_path.finish_line_idx
	if i > node_idx:
		i -= num_nodes
	while i < node_idx:
		distance += (track_path.nodes[i + 1].position - track_path.nodes[i].position).length()
		i += 1
	return distance


static func load_pth_file(file_path: String) -> TrackPath:
	var pth_file := PTHFile.new()
	pth_file.read_from_path(file_path)
	var track_path := TrackPath.new()
	track_path.finish_line_idx = pth_file.finish_line
	var _discard := track_path.nodes.resize(pth_file.num_nodes)
	for i in pth_file.num_nodes:
		track_path.nodes[i] = pth_file.path_nodes[i]
	#print("Num nodes: %d, finish idx: %d, length: %.1f m" % [pth_file.num_nodes,
			#pth_file.finish_line, track_path.get_path_length()])
	return track_path
