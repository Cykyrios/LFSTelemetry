extends MarginContainer


var main_lap: LapData = null
var reference_lap: LapData = null

@onready var load_main_lap_button := %MainLapButton as Button
@onready var main_driver_label := %MainDriverLabel as RichTextLabel
@onready var load_reference_lap_button := %ReferenceLapButton as Button
@onready var reference_driver_label := %ReferenceDriverLabel as RichTextLabel


func _ready() -> void:
	connect_signals()
	print_laps()


func connect_signals() -> void:
	var _discard := load_main_lap_button.pressed.connect(_on_load_main_lap_pressed)
	_discard = load_reference_lap_button.pressed.connect(_on_load_reference_lap_pressed)


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
	#load_and_draw(path)
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


#region callbacks
func _on_load_main_lap_pressed() -> void:
	main_lap = await load_lap()
	main_driver_label.text = "Driver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(main_lap.driver),
			main_lap.car]


func _on_load_reference_lap_pressed() -> void:
	reference_lap = await load_lap()
	reference_driver_label.text = "Driver: %s (%s)" % [LFSText.lfs_colors_to_bbcode(
			reference_lap.driver), reference_lap.car]
#endregion
