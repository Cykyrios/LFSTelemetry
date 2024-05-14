extends MarginContainer


var main_lap: LapData = null
var reference_lap: LapData = null

@onready var telemetry_vbox := %TelemetryVBox as VBoxContainer
@onready var main_lap_button := %MainLapButton as MenuButton
@onready var main_lap_label := %MainLapInfo as RichTextLabel
@onready var reference_lap_button := %ReferenceLapButton as MenuButton
@onready var reference_lap_label := %ReferenceLapInfo as RichTextLabel
@onready var chart_tabs := %ChartTabs as TabContainer


func _ready() -> void:
	connect_signals()
	print_laps()
	add_chart_pages()
	generate_pth_file()


func generate_pth_file() -> void:
	var points := 46
	var packet := LFSPacket.new()
	packet.resize_buffer(16 + 4 * points * 40)
	packet.add_string_as_utf8(6, "LFSPTH")
	packet.add_byte(0)
	packet.add_byte(0)
	packet.add_int(4 * points)
	packet.add_int(30)
	var multiplier := 65536.0
	var drive_limit := 5.0
	var road_limit := 7.5
	for i in 4:
		var x0 := 0.0
		var y0 := 0.0
		var xi := 0.0
		var yi := 0.0
		var a0 := 0.0
		if i == 0:
			x0 = 0
			y0 = -2000
			xi = 0
			yi = 1000
			a0 = 45
		elif i == 1:
			x0 = 0
			y0 = -1000
			xi = 1000
			yi = 0
			a0 = -45
		elif i == 2:
			x0 = 1000
			y0 = -1000
			xi = 0
			yi = -1000
			a0 = -135
		else:
			x0 = 1000
			y0 = -2000
			xi = -1000
			yi = 0
			a0 = 135
		for j in points:
			var pos := Vector3(
				x0 + xi * (j as float / points),
				y0 + yi * (j as float / points),
				2
			) * multiplier
			var angle := a0 - 90 * (j as float / points)
			angle = wrapf(angle, -180, 180)
			var direction := Vector3(0, 1, 0).rotated(Vector3(0, 0, 1), deg_to_rad(angle))
			packet.add_int(int(pos.x))
			packet.add_int(int(pos.y))
			packet.add_int(int(pos.z))
			packet.add_float(direction.x)
			packet.add_float(direction.y)
			packet.add_float(direction.z)
			packet.add_float(-road_limit / cos(deg_to_rad(45 - 90 * (j as float / points))))
			packet.add_float(road_limit / cos(deg_to_rad(45 - 90 * (j as float / points))))
			packet.add_float(-drive_limit / cos(deg_to_rad(45 - 90 * (j as float / points))))
			packet.add_float(drive_limit / cos(deg_to_rad(45 - 90 * (j as float / points))))
		var file := FileAccess.open("test.pth", FileAccess.WRITE)
		if FileAccess.get_open_error() != OK:
			push_error("Could not open file for writing")
			return
		file.store_buffer(packet.buffer)


func add_chart_pages() -> void:
	var chart_page_compare := ChartPageCompare.new()
	chart_tabs.add_child(chart_page_compare)
	var chart_page_driver := ChartPageDriver.new()
	chart_tabs.add_child(chart_page_driver)
	var chart_page_rpm := ChartPageRPM.new()
	chart_tabs.add_child(chart_page_rpm)
	var chart_page_dampers := ChartPageDampers.new()
	chart_tabs.add_child(chart_page_dampers)
	var chart_page_track := ChartPageTrack.new()
	chart_tabs.add_child(chart_page_track)
	var chart_page_test := ChartPageTest.new()
	chart_tabs.add_child(chart_page_test)


func connect_signals() -> void:
	var _discard := main_lap_button.get_popup().id_pressed.connect(_on_main_lap_pressed)
	_discard = reference_lap_button.get_popup().id_pressed.connect(_on_reference_lap_pressed)
	_discard = chart_tabs.tab_changed.connect(_on_tab_changed)


func get_lap_info(lap: LapData) -> String:
	if not lap:
		return ""
	return "Track: %s, lap %d (%s)" % [lap.track, lap.lap_number,
			Utils.get_lap_time_string(lap.lap_time)] \
			+ "\nDriver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(lap.driver), lap.car]


func load_lap() -> LapData:
	var file_dialog := FileDialog.new()
	add_child(file_dialog)
	file_dialog.min_size = Vector2i(600, 400)
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.current_dir = "user://tlm"
	file_dialog.filters = ["*.tlm ; Telemetry files"]
	file_dialog.popup_centered()
	await file_dialog.file_selected
	var path := file_dialog.current_path
	var lap_io := LapDataIO.new()
	return lap_io.load_lap_file(path)


func print_laps() -> void:
	var lap_io := LapDataIO.new()
	var directories := DirAccess.get_directories_at("user://tlm")
	for directory in directories:
		var session_path := "user://tlm/%s" % [directory]
		var files := DirAccess.get_files_at(session_path)
		var file_count := files.size()
		for i in file_count:
			var index := file_count - 1 - i
			if files[index].get_extension() != "tlm":
				files.remove_at(index)
		file_count = files.size()
		if file_count > 0:
			print(directory)
		var print_sectors := func print_sectors(sectors: Array[SectorData]) -> String:
			var text := ""
			for sector in sectors:
				if text != "":
					text += " + "
				text += "S%d %s" % [sector.sector_number,
						Utils.get_lap_time_string(sector.sector_time)]
			return text
		for file in files:
			var lap := lap_io.load_lap_file("%s/%s" % [session_path, file], true)
			print("- %s" % ["%s%s" % [Utils.get_lap_time_string(lap.lap_time),
					"" if lap.sectors.is_empty() else " (%s)" % [print_sectors.call(lap.sectors)]]])


func redraw_current_tab() -> void:
	var current_page := chart_tabs.get_child(chart_tabs.current_tab)
	if current_page is ChartPage:
		(current_page as ChartPage).draw_charts()


#region callbacks
func _on_main_lap_pressed(id: int) -> void:
	if id == 0:
		main_lap = await load_lap()
	elif id == 1:
		main_lap = null
	main_lap_label.text = get_lap_info(main_lap)
	for child in chart_tabs.get_children():
		if child is ChartPage:
			(child as ChartPage).main_lap = main_lap
			(child as ChartPage).stale = true
	redraw_current_tab()


func _on_reference_lap_pressed(id: int) -> void:
	if id == 0:
		reference_lap = await load_lap()
	elif id == 1:
		reference_lap = null
	reference_lap_label.text = get_lap_info(reference_lap)
	for child in chart_tabs.get_children():
		if child is ChartPage:
			(child as ChartPage).reference_lap = reference_lap
			(child as ChartPage).stale = true
	redraw_current_tab()


func _on_tab_changed(idx: int) -> void:
	var tab := chart_tabs.get_child(idx)
	if tab is ChartPage:
		var chart_page := tab as ChartPage
		if chart_page.stale:
			chart_page.draw_charts()
#endregion
