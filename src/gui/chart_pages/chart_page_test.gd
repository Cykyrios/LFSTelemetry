class_name ChartPageTest
extends ChartPage


var main_lap_time: Array[float] = []
var main_lap_indexed_distance: Array[float] = []
var main_lap_test: Array[float] = []
var main_lap_error: Array[float] = []
var main_x_pos: Array[float] = []
var main_y_pos: Array[float] = []
var nodes_x_pos: Array[float] = []
var nodes_y_pos: Array[float] = []


func _init() -> void:
	super()
	name = "Test"


func _draw_charts() -> void:
	super()
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(vbox)

	if stale:
		recompute_data()

	var chart_index := Chart.new()
	vbox.add_child(chart_index)
	chart_index.chart_area.custom_minimum_size = Vector2(400, 200)
	chart_index.x_axis_primary.margin = 0
	chart_index.update_minimum_size()
	if main_lap:
		#chart_index.add_data(main_lap_time, main_lap_indexed_distance, "Indexed Distance [m]")
		#chart_index.add_data(main_lap_time, main_lap_test, "Corrected Distance [m]")
		chart_index.add_data(main_lap_time, main_lap_error, "Error [m]")

	var chart_nodes := Chart.new()
	chart_nodes.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chart_nodes.chart_area.custom_minimum_size = Vector2(500, 500)
	vbox.add_child(chart_nodes)
	chart_nodes.equal_aspect = true
	if main_lap:
		chart_nodes.add_data(main_x_pos, main_y_pos)
		chart_nodes.add_data(nodes_x_pos, nodes_y_pos)
		chart_nodes.chart_data[-1].plot_type = ChartData.PlotType.SCATTER

	refresh_charts()


func recompute_data() -> void:
	if main_lap:
		main_lap_time = chart_creator.get_data(main_lap, "time")
		main_lap_indexed_distance = chart_creator.get_data(main_lap, "indexed_distance")
		var track_path := DataFixer.load_pth_file("/home/cyril/.wine/drive_c/LFS/data/smx/SO6R.pth")
		#var track_path := DataFixer.load_pth_file("test.pth")
		main_lap_test = DataFixer.fix_indexed_distance(main_lap, track_path)
		main_lap_error.clear()
		var _discard := main_lap_error.resize(main_lap_test.size())
		for i in main_lap_error.size():
			main_lap_error[i] = main_lap_test[i] - main_lap_indexed_distance[i]
		main_x_pos = chart_creator.get_data(main_lap, "x_pos")
		main_y_pos = chart_creator.get_data(main_lap, "y_pos")
		nodes_x_pos.assign(track_path.nodes.map(func(node: PathNode) -> float: return node.position.x))
		nodes_y_pos.assign(track_path.nodes.map(func(node: PathNode) -> float: return node.position.y))
	stale = false
