extends Node

const CLOUD_FILE_NAME := "save_data"
var isPrevSnapShot := false
var oldSnapShot: Dictionary = {}
var is_data_loaded := false

signal save_data_ready
signal save_data_failed

func _ready() -> void:
	SnapshotsClient.game_saved.connect(
		func(is_saved: bool, save_data_name: String, save_data_description: String): 
			print("Saved: ", is_saved, " Name: ", save_data_name, " Desc: ", save_data_description)
	)
	
	SnapshotsClient.conflict_emitted.connect(
		func(conflict: PlayGamesSnapshotConflict):
			print("Snapshot Conflict: ", conflict)
			load_local_fallback()
			is_data_loaded = true
			save_data_failed.emit()
	)
	
	SnapshotsClient.game_loaded.connect(
		func(snapshot: PlayGamesSnapshot):
			if snapshot == null or snapshot.content == null:
				print("No cloud save found - checking local fallback")
				load_local_fallback()
				is_data_loaded = true
				save_data_ready.emit()
				return
				
			var raw_content = snapshot.content
			var json: String = ""
			if raw_content is PackedByteArray:
				json = raw_content.get_string_from_utf8()
			elif raw_content is String:
				json = raw_content
			elif raw_content is Array:
				json = PackedByteArray(raw_content).get_string_from_utf8()

			var save_data = JSON.parse_string(json)
			if save_data is Dictionary:
				print("Loaded Cloud Snapshot: ", save_data)
				isPrevSnapShot = true
				oldSnapShot = save_data
				GameManager.load_progress()
				is_data_loaded = true
				save_data_ready.emit()
			else:
				print("Invalid cloud save data format - falling back to local")
				load_local_fallback()
				is_data_loaded = true
				save_data_failed.emit()
	)
	
	load_game()

func load_local_fallback() -> bool:
	var save_path := "user://save_data.json"
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				oldSnapShot = json.data
				isPrevSnapShot = true
				GameManager.load_progress()
				return true
	# If no local save file exists, still initialize default GameManager progress
	isPrevSnapShot = false
	oldSnapShot = {}
	GameManager.load_progress()
	return false

func save_game(
	description: String,
	save_data: PackedByteArray,
	file_name: String = CLOUD_FILE_NAME,
	played_time_millis: int = 0,
	progress_value: int = 0,
) -> void:
	SnapshotsClient.save_game(file_name, description, save_data, played_time_millis, progress_value)

func load_game(create_if_not_found := false, file_name: String = CLOUD_FILE_NAME) -> void:
	if GodotPlayGameServices.android_plugin:
		SnapshotsClient.load_game(file_name, create_if_not_found)
		# 5-second timeout safety net in case of network stall
		var timer := get_tree().create_timer(5.0)
		timer.timeout.connect(func():
			if not is_data_loaded:
				print("Cloud save load timed out - falling back to local save")
				load_local_fallback()
				is_data_loaded = true
				save_data_failed.emit()
		)
	else:
		# Desktop / Editor environment
		await get_tree().create_timer(0.2).timeout
		if not is_data_loaded:
			load_local_fallback()
			is_data_loaded = true
			save_data_ready.emit()
