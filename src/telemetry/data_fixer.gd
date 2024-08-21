class_name DataFixer
extends RefCounted


static func fix_indexed_distance(lap: LapData, track_path: TrackPath) -> Array[float]:
	var point_count := lap.car_data.size()
	var indexed_distance: Array[float] = []
	var _discard := indexed_distance.resize(point_count)
	for i in point_count:
		var current_position := lap.car_data[i].position
		var closest_node := get_closest_node_to_pos(track_path, current_position)
		var node_idx := track_path.nodes.find(closest_node)
		var next_node := track_path.nodes[wrapi(node_idx + 1, 0, track_path.nodes.size())]
		var delta := current_position - closest_node.position
		var node_dot := delta.dot(next_node.position - closest_node.position)
		if node_dot >= 0:
			var distance := delta.project(next_node.position - closest_node.position).length()
			indexed_distance[i] = get_path_length_up_to_node(track_path, closest_node) + distance
		else:
			var prev_node := track_path.nodes[node_idx - 1]
			var distance := (current_position - prev_node.position).project(
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


static func fix_indexed_distance_take2(lap: LapData, track_path: TrackPath) -> Array[float]:
	# Source: https://www.reddit.com/r/askmath/comments/tsy7qn/comment/i2uuium/
	var point_count := lap.car_data.size()
	var indexed_distance: Array[float] = []
	var _discard := indexed_distance.resize(point_count)
	for i in point_count:
		var current_position := lap.car_data[i].position
		var closest_node := get_closest_node_to_pos(track_path, current_position)
		var node_idx := track_path.nodes.find(closest_node)
		var next_node := track_path.nodes[wrapi(node_idx + 1, 0, track_path.nodes.size())]
		var delta := current_position - closest_node.position
		var node_dot := delta.dot(closest_node.direction)
		var node_1 := closest_node if node_dot >= 0 else track_path.nodes[node_idx - 1]
		var node_2 := next_node if node_dot >= 0 else closest_node
		var right_1 := node_1.direction.cross(Vector3(0, 0, 1))
		var right_2 := node_2.direction.cross(Vector3(0, 0, 1))
		var p1 := node_1.position + right_1 * node_1.limit_left
		var p2 := node_1.position + right_1 * node_1.limit_right
		var p3 := node_2.position + right_2 * node_2.limit_right
		var p4 := node_2.position + right_2 * node_2.limit_left
		var p0 := Vector3(current_position.x, current_position.y, 0)
		p1.z = 0
		p2.z = 0
		p3.z = 0
		p4.z = 0
		var a := p0.x - p1.x
		var b := p2.x - p1.x
		var c := p4.x - p1.x
		var d := p1.x - p2.x + p3.x - p4.x
		var f := p0.y - p1.y
		var g := p2.y - p1.y
		var h := p4.y - p1.y
		var j := p1.y - p2.y + p3.y - p4.y
		var v2 := d * h - c * j
		var v1 := a * j - c * g - (d * f - b * h)
		var v0 := a * g - b * f
		var normalized_distance := (-v1 + sqrt(v1 * v1 - 4 * v2 * v0)) / (2 * v2)
		if is_zero_approx(v2):
			normalized_distance = -v0 / v1
		var distance := normalized_distance * (node_2.position - node_1.position).length()
		indexed_distance[i] = get_path_length_up_to_node(track_path, node_1) + distance
	# Fix overflow
	var max_distance := indexed_distance.max() as float
	var min_distance := indexed_distance.min() as float
	var max_delta := max_distance - min_distance
	var path_length := track_path.get_path_length()
	var overflow_idx := 0
	for i in point_count:
		if absf(indexed_distance[i] - indexed_distance[i - 1]) > max_delta / 2.0:
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
	var overflow_offset := indexed_distance[overflow_idx - 1] - indexed_distance[overflow_idx] \
			+ overflow_distances[1] - overflow_distances[0]
	for i in point_count - overflow_idx:
		indexed_distance[overflow_idx + i] += overflow_offset
	max_distance = indexed_distance.max() as float
	if max_distance > path_length:
		var first_point := indexed_distance[0]
		for i in point_count:
			indexed_distance[i] -= first_point
	return indexed_distance


static func fix_indexed_distance_take3(lap: LapData, track_path: TrackPath) -> Array[float]:
	# Source: https://math.stackexchange.com/questions/
	#		3037040/normalized-coordinate-of-point-on-4-sided-concave-polygon
	# Problem: error is large
	var point_count := lap.car_data.size()
	var indexed_distance: Array[float] = []
	var _discard := indexed_distance.resize(point_count)
	for i in point_count:
		var current_position := lap.car_data[i].position
		var closest_node := get_closest_node_to_pos(track_path, current_position)
		var node_idx := track_path.nodes.find(closest_node)
		var next_node := track_path.nodes[wrapi(node_idx + 1, 0, track_path.nodes.size())]
		var delta := current_position - closest_node.position
		var node_dot := delta.dot(closest_node.direction)
		var node_1 := closest_node if node_dot >= 0 else track_path.nodes[node_idx - 1]
		var node_2 := next_node if node_dot >= 0 else closest_node
		var p1 := node_1.position + node_1.direction.cross(Vector3(0, 0, 1)) * node_1.limit_left
		var p2 := node_1.position + node_1.direction.cross(Vector3(0, 0, 1)) * node_1.limit_right
		var p3 := node_2.position + node_2.direction.cross(Vector3(0, 0, 1)) * node_2.limit_right
		var p4 := node_2.position + node_2.direction.cross(Vector3(0, 0, 1)) * node_2.limit_left
		var p0 := Vector3(current_position.x, current_position.y, 0)
		p1.z = 0
		p2.z = 0
		p3.z = 0
		p4.z = 0
		var d1 := p2 - p3
		var d2 := p4 - p3
		var d3 := p1 - p2 + p3 - p4
		var a13 := (d3.x * d2.y - d3.y * d2.x) / (d1.x * d2.y - d1.y * d2.x)
		var a23 := (d1.x * d3.y - d1.y * d3.x) / (d1.x * d2.y - d1.y * d2.x)
		var a11 := p2.x - p1.x + a13 * p2.x
		var a21 := p4.x - p1.x + a23 * p4.x
		var a31 := p1.x
		var a12 := p2.y - p1.y + a13 * p2.y
		var a22 := p4.y - p1.y+ a23 * p4.y
		var a32 := p1.y
		var basis := Basis(Vector3(a11, a12, a13), Vector3(a21, a22, a23), Vector3(a31, a32, 1))
		basis = basis.inverse()
		p0.z = 1
		var result_vector := basis * p0
		var result_point := Vector2(result_vector.x / result_vector.z, result_vector.y / result_vector.z)
		var distance := result_point.y * (node_2.position - node_1.position).length()
		indexed_distance[i] = get_path_length_up_to_node(track_path, node_1) + distance
	# Fix overflow
	var max_distance := indexed_distance.max() as float
	var min_distance := indexed_distance.min() as float
	var max_delta := max_distance - min_distance
	var path_length := track_path.get_path_length()
	var overflow_idx := 0
	for i in point_count:
		if absf(indexed_distance[i] - indexed_distance[i - 1]) > max_delta / 2.0:
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
	var overflow_offset := indexed_distance[overflow_idx - 1] - indexed_distance[overflow_idx] \
			+ overflow_distances[1] - overflow_distances[0]
	for i in point_count - overflow_idx:
		indexed_distance[overflow_idx + i] += overflow_offset
	max_distance = indexed_distance.max() as float
	if max_distance > path_length:
		var first_point := indexed_distance[0]
		for i in point_count:
			indexed_distance[i] -= first_point
	return indexed_distance


static func fix_indexed_distance_take4(lap: LapData, track_path: TrackPath) -> Array[float]:
	# same as fix_indexed_distance, but also use drive limits depending on lateral position offset
	var point_count := lap.car_data.size()
	var indexed_distance: Array[float] = []
	var _discard := indexed_distance.resize(point_count)
	for i in point_count:
		var current_position := lap.car_data[i].position
		var closest_node := get_closest_node_to_pos(track_path, current_position)
		var node_idx := track_path.nodes.find(closest_node)
		var next_node := track_path.nodes[wrapi(node_idx + 1, 0, track_path.nodes.size())]
		var delta := current_position - closest_node.position
		var node_dot := delta.dot(closest_node.direction)
		var node_1 := closest_node if node_dot >= 0 else track_path.nodes[node_idx - 1]
		var node_2 := next_node if node_dot >= 0 else closest_node
		if node_dot < 0:
			delta = current_position - node_1.position
		var distance := delta.project(node_2.position - node_1.position).length()
		indexed_distance[i] = get_path_length_up_to_node(track_path, node_1) + distance
	var max_distance := indexed_distance.max() as float
	var min_distance := indexed_distance.min() as float
	var max_delta := max_distance - min_distance
	var path_length := track_path.get_path_length()
	var overflow_idx := 0
	for i in point_count:
		if absf(indexed_distance[i] - indexed_distance[i - 1]) > max_delta / 2.0:
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
	var overflow_offset := indexed_distance[overflow_idx - 1] - indexed_distance[overflow_idx] \
			+ overflow_distances[1] - overflow_distances[0]
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
