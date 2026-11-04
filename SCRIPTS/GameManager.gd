extends Node

signal level_changed(level_index: int)
signal game_completed
signal progress_updated

@export var levels: Array[PackedScene] = [
	preload("uid://blcmaj1t2lsax"), # Level 1
	preload("uid://dnwf35rfeye1v"), # Level 2
	preload("uid://djfmmw7uj4s3g"), # Level 3
	preload("uid://dobdlhfuyt1ch"), # Level 4
	preload("uid://bv6kn6ymg25ab"), # Level 5
	preload("uid://nouh0jhg46jy"), # Level 6
	preload("uid://bpq0011blrqpn"), # Level 7
	preload("uid://cxm1tr8v0auuf"), # Level 8
	preload("uid://cgw8ien5i4353"), # Level 9
	preload("uid://cwsog6cunrn5u"), # Level 10
	preload("uid://c3cn4qsnmwell"), # Level 11
	preload("uid://6p3sgtylm6dn"), # Level 12 (scene 13)
	preload("uid://ctyp6d243bhfo"), # Level 13 (scene 15)
	preload("uid://etlbcg3fcwcg"), # Level 14 (scene 16)
	preload("uid://c1p5den7ox4hc")  # Level 15 (scene 17)
]

const SAVE_PATH := "user://save_data.json"


var current_level_index: int = 0
var current_level_instance: Node = null
var level_container: Node = null

var unlocked_level: int = 0
var level_stars: Dictionary = {} # int -> int (1..3)

var haptics_enabled: bool = true
var music_enabled: bool = true
var sfx_enabled: bool = true
var crt_enabled: bool = true
var master_volume: float = 1.0

signal settings_changed

#func _ready() -> void:
	#load_progress()

func setup_level_container(container: Node) -> void:
	level_container = container
	load_level(current_level_index, false)

func next_level() -> void:
	if current_level_index + 1 >= levels.size():
		emit_signal("game_completed")
		return_to_menu()
		return
	load_level(current_level_index + 1, true)

func restart_level() -> void:
	load_level(current_level_index, true)

func return_to_menu() -> void:
	if TransitionLayer:
		await TransitionLayer.transition_out()
	get_tree().change_scene_to_file("res://SCENES/main_home.tscn")
	if TransitionLayer:
		TransitionLayer.transition_in()

func return_to_title() -> void:
	if TransitionLayer:
		await TransitionLayer.transition_out()
	get_tree().change_scene_to_file("res://SCENES/LEVELS/MainMenu.tscn")
	if TransitionLayer:
		TransitionLayer.transition_in()

func load_level(index: int, use_transition: bool = true) -> void:
	if index >= levels.size():
		emit_signal("game_completed")
		return_to_menu()
		return
		
	current_level_index = index

	if use_transition and TransitionLayer:
		await TransitionLayer.transition_out()

	if is_instance_valid(current_level_instance):
		current_level_instance.queue_free()

	current_level_instance = levels[current_level_index].instantiate()
	if level_container:
		level_container.add_child(current_level_instance)

	emit_signal("level_changed", current_level_index)

	if use_transition and TransitionLayer:
		await TransitionLayer.transition_in()

func complete_level(level_idx: int, stars: int) -> void:
	# Update stars to the player's performance on this playthrough
	level_stars[str(level_idx)] = stars
	
	# Unlock next level if not already unlocked
	if level_idx + 1 > unlocked_level and level_idx + 1 < levels.size():
		unlocked_level = level_idx + 1
		
	save_progress()
	progress_updated.emit()

func get_level_stars(level_idx: int) -> int:
	return int(level_stars.get(str(level_idx), 0))

func is_level_unlocked(level_idx: int) -> bool:
	return level_idx <= unlocked_level

func save_progress() -> void:
	var data := {
		"unlocked_level": unlocked_level,
		"level_stars": level_stars,
		"haptics_enabled": haptics_enabled,
		"music_enabled": music_enabled,
		"sfx_enabled": sfx_enabled,
		"crt_enabled": crt_enabled,
		"master_volume": master_volume
	}
	#cloud
	var bytes = JSON.stringify(data).to_utf8_buffer()
	if SaveManager:
		SaveManager.save_game("SaveData", bytes)
		print("SaveSendToCloud")
	
	#local backup
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if !SaveManager.isPrevSnapShot:
		unlocked_level = 0
		current_level_index = 0
		progress_updated.emit()
		settings_changed.emit()
		return
	var save_data_bytes = SaveManager.oldSnapShot
	if save_data_bytes is Dictionary:
		unlocked_level = int(save_data_bytes.get("unlocked_level", 0))
		level_stars = save_data_bytes.get("level_stars", {})
		haptics_enabled = bool(save_data_bytes.get("haptics_enabled", true))
		music_enabled = bool(save_data_bytes.get("music_enabled", true))
		sfx_enabled = bool(save_data_bytes.get("sfx_enabled", true))
		crt_enabled = bool(save_data_bytes.get("crt_enabled", true))
		master_volume = float(save_data_bytes.get("master_volume", 1.0))
		var db := linear_to_db(master_volume) if master_volume > 0.001 else -80.0
		AudioServer.set_bus_volume_db(0, db)
		unlocked_level = clamp(unlocked_level, 0, levels.size() - 1)
		current_level_index = unlocked_level
		progress_updated.emit()
		settings_changed.emit()

func set_music_enabled(val: bool) -> void:
	music_enabled = val
	save_progress()
	settings_changed.emit()

func set_haptics_enabled(val: bool) -> void:
	haptics_enabled = val
	save_progress()
	settings_changed.emit()

func set_sfx_enabled(val: bool) -> void:
	sfx_enabled = val
	save_progress()
	settings_changed.emit()

func set_crt_enabled(val: bool) -> void:
	crt_enabled = val
	save_progress()
	settings_changed.emit()

func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	var db := linear_to_db(master_volume) if master_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(0, db)
	save_progress()
	settings_changed.emit()
