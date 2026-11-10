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

const ASCII_LEVEL_SCENE: PackedScene = preload("res://SCENES/LEVELS/ascii_level.tscn")
const HANDCRAFTED_COUNT: int = 15
const MOBILE_CONTENT_SCALE: float = 1.22

var is_deeplink_leaderboard_redirect : bool = false;

func _ready() -> void:
	_setup_font_fallbacks()
	_init_translations()
	_init_language()
	_apply_platform_display_scale()
	scan_ascii_levels()

func _setup_font_fallbacks() -> void:
	var main_font: FontFile = load("res://ASSETS/FONT/Gorditas-Bold.ttf")
	if main_font:
		var jp_font: FontFile = load("res://ASSETS/FONT/other_lang/ZenMaruGothic-Medium.ttf")
		var cn_font: FontFile = load("res://ASSETS/FONT/other_lang/ZCOOLKuaiLe-Regular.ttf")
		var fallbacks: Array[Font] = []
		if jp_font:
			fallbacks.append(jp_font)
		if cn_font:
			fallbacks.append(cn_font)
		if not fallbacks.is_empty():
			main_font.fallbacks = fallbacks
			print("[GameManager] Registered CJK font fallbacks (JP + SC) on Gorditas-Bold.")

func _init_translations() -> void:
	# 1. If translations are loaded natively via ProjectSettings [internationalization]:
	if not TranslationServer.get_loaded_locales().is_empty():
		print("[GameManager] Translations active via ProjectSettings: ", TranslationServer.get_loaded_locales())
		return

	# 2. Try loading compiled .translation resources (works inside Android APK/AAB export)
	var loaded_any := false
	for loc in SUPPORTED_LANGUAGES:
		var res_path := "res://TRANSLATIONS/translations.%s.translation" % loc
		if ResourceLoader.exists(res_path):
			var tr_res = load(res_path)
			if tr_res is Translation:
				TranslationServer.add_translation(tr_res)
				loaded_any = true
	if loaded_any:
		print("[GameManager] Registered translation resources: ", TranslationServer.get_loaded_locales())
		return

	# 3. Fallback: Parse raw CSV (for development if not yet imported)
	const CSV_PATH := "res://TRANSLATIONS/translations.csv"
	if not FileAccess.file_exists(CSV_PATH):
		return
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		return
	var headers := file.get_csv_line(",")
	var locales: Array[String] = []
	var translations: Dictionary = {}
	for i in range(1, headers.size()):
		var loc := headers[i].strip_edges()
		locales.append(loc)
		var tr_res := Translation.new()
		tr_res.locale = loc
		translations[loc] = tr_res
	
	while not file.eof_reached():
		var row := file.get_csv_line(",")
		if row.size() < headers.size():
			continue
		var raw_key := row[0]
		var key := raw_key.strip_edges()
		if key.is_empty():
			continue
		for i in range(1, headers.size()):
			var loc := locales[i - 1]
			var msg := row[i].replace("\\n", "\n")
			(translations[loc] as Translation).add_message(key, msg)
			if raw_key != key:
				(translations[loc] as Translation).add_message(raw_key, msg)
	file.close()

	for loc in locales:
		TranslationServer.add_translation(translations[loc])
	print("[GameManager] Registered translation locales from CSV: ", locales)

func _init_language() -> void:
	# If user already picked a language from local save, it gets loaded in load_progress().
	# Otherwise, auto-detect device OS language on first launch.
	if current_language.is_empty() or current_language == "en":
		var os_lang := OS.get_locale_language().to_lower()
		if os_lang.begins_with("es"):
			current_language = "es"
		elif os_lang.begins_with("ja"):
			current_language = "ja"
		elif os_lang.begins_with("zh"):
			current_language = "zh_CN"
		else:
			current_language = "en"
	set_language(current_language, false)

func set_language(lang_code: String, do_save: bool = true) -> void:
	if not lang_code in SUPPORTED_LANGUAGES:
		lang_code = "en"
	current_language = lang_code
	TranslationServer.set_locale(lang_code)
	if do_save:
		save_progress()
	settings_changed.emit()

func cycle_language() -> String:
	var idx := SUPPORTED_LANGUAGES.find(current_language)
	if idx == -1:
		idx = 0
	var next_idx := (idx + 1) % SUPPORTED_LANGUAGES.size()
	set_language(SUPPORTED_LANGUAGES[next_idx], true)
	return SUPPORTED_LANGUAGES[next_idx]

func get_language_display_name(lang_code: String = "") -> String:
	var target := lang_code if not lang_code.is_empty() else current_language
	return LANGUAGE_DISPLAY_NAMES.get(target, "ENGLISH")

func _apply_platform_display_scale() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		get_tree().root.content_scale_factor = MOBILE_CONTENT_SCALE
		print("[GameManager] Mobile platform detected: applied content_scale_factor = ", MOBILE_CONTENT_SCALE)

func scan_ascii_levels() -> void:
	if levels.size() > HANDCRAFTED_COUNT:
		levels.resize(HANDCRAFTED_COUNT)
	
	var idx := HANDCRAFTED_COUNT + 1
	while true:
		var path := "res://LEVELS_DATA/level_%d.txt" % idx
		if FileAccess.file_exists(path):
			levels.append(ASCII_LEVEL_SCENE)
			idx += 1
		else:
			break
	print("[GameManager] Total levels registered: %d (Handcrafted: %d, ASCII: %d)" % [levels.size(), HANDCRAFTED_COUNT, levels.size() - HANDCRAFTED_COUNT])

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

# Localization
var current_language: String = "en"
const SUPPORTED_LANGUAGES: Array[String] = ["en", "es", "ja", "zh_CN"]
const LANGUAGE_DISPLAY_NAMES: Dictionary = {
	"en": "ENGLISH",
	"es": "ESPAÑOL",
	"ja": "日本語",
	"zh_CN": "简体中文"
}

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

func is_final_level(index: int = -1) -> bool:
	var check_idx := index if index >= 0 else current_level_index
	return check_idx == (levels.size() - 1)

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
		"master_volume": master_volume,
		"language": current_language,
		"leaderboard_opted_out": LootLockerManager.is_leaderboard_opted_out if has_node("/root/LootLockerManager") else false
	}
	#cloud
	var bytes = JSON.stringify(data).to_utf8_buffer()
	if SaveManager:
		SaveManager.save_game("SaveData", bytes)
	
	#local backup
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if !SaveManager.isPrevSnapShot:
		# Check local save file for saved language
		if FileAccess.file_exists(SAVE_PATH):
			var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
			if f:
				var parsed = JSON.parse_string(f.get_as_text())
				if parsed is Dictionary:
					if parsed.has("language"):
						var l = str(parsed.get("language", ""))
						if l in SUPPORTED_LANGUAGES:
							current_language = l
							TranslationServer.set_locale(current_language)
					if parsed.has("leaderboard_opted_out") and has_node("/root/LootLockerManager"):
						if bool(parsed.get("leaderboard_opted_out", false)):
							LootLockerManager.is_leaderboard_opted_out = true
							LootLockerManager._save_opt_out_status(true)
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
		if save_data_bytes.has("language"):
			var saved_lang = str(save_data_bytes.get("language", ""))
			if saved_lang in SUPPORTED_LANGUAGES:
				current_language = saved_lang
				TranslationServer.set_locale(current_language)
		if save_data_bytes.has("leaderboard_opted_out") and has_node("/root/LootLockerManager"):
			if bool(save_data_bytes.get("leaderboard_opted_out", false)):
				LootLockerManager.is_leaderboard_opted_out = true
				LootLockerManager._save_opt_out_status(true)
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
