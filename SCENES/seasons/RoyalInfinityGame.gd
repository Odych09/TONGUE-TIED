extends Node2D

const ASCII_LEVEL_SCENE: PackedScene = preload("res://SCENES/LEVELS/ascii_level.tscn")
const EVENT_LEVEL_FILE: String = "res://LEVELS_DATA/royal_infinity.txt"
const EVENT_MENU_SCENE: String = "res://SCENES/seasons/RoyalInfinity.tscn"

@onready var level_holder: Node2D = $LevelHolder
@onready var crt_overlay: Node = $CRT
@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer

var current_level_instance: AsciiLevel = null

func _ready() -> void:
	if bgm_player and has_node("/root/MusicManager"):
		bgm_player.stop()
		bgm_player.stream = null
	if has_node("/root/MusicManager"):
		MusicManager.play_game_music()

	_load_event_level()

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func _load_event_level() -> void:
	if is_instance_valid(current_level_instance):
		current_level_instance.queue_free()

	current_level_instance = ASCII_LEVEL_SCENE.instantiate() as AsciiLevel
	current_level_instance.level_file = EVENT_LEVEL_FILE
	level_holder.add_child(current_level_instance)

	_bind_player_and_crt()

func _bind_player_and_crt() -> void:
	await get_tree().process_frame
	var player := level_holder.find_child("Player", true, false) as Frog
	if player and crt_overlay and crt_overlay.has_method("setup_player"):
		crt_overlay.setup_player(player)

	# Customize HUD for the Royal Infinity Event
	if crt_overlay:
		var level_label: Label = crt_overlay.get_node_or_null("UI/TopLeftBar/LevelBadge/LevelLabel")
		if level_label:
			level_label.text = "ROYAL INFINITY"

		# Intercept HUD restart & menu actions for the event
		var restart_btn: Button = crt_overlay.get_node_or_null("UI/TopLeftBar/RestartBtn")
		if restart_btn:
			for conn in restart_btn.pressed.get_connections():
				restart_btn.pressed.disconnect(conn.callable)
			restart_btn.pressed.connect(restart_event_level)

		# Win Modal buttons
		if crt_overlay.has_method("get_node_or_null"):
			var replay_btn: Button = crt_overlay.get_node_or_null("UI/WinModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ReplayBtn")
			if replay_btn:
				for conn in replay_btn.pressed.get_connections():
					replay_btn.pressed.disconnect(conn.callable)
				replay_btn.pressed.connect(restart_event_level)

			var levels_btn: Button = crt_overlay.get_node_or_null("UI/WinModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/LevelsBtn")
			if levels_btn:
				for conn in levels_btn.pressed.get_connections():
					levels_btn.pressed.disconnect(conn.callable)
				levels_btn.pressed.connect(return_to_event_menu)

			var next_btn: Button = crt_overlay.get_node_or_null("UI/WinModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/NextBtn")
			if next_btn:
				for conn in next_btn.pressed.get_connections():
					next_btn.pressed.disconnect(conn.callable)
				next_btn.pressed.connect(return_to_event_menu)

			# Pause Modal buttons
			var pause_restart_btn: Button = crt_overlay.get_node_or_null("UI/PauseModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseRestartBtn")
			if pause_restart_btn:
				for conn in pause_restart_btn.pressed.get_connections():
					pause_restart_btn.pressed.disconnect(conn.callable)
				pause_restart_btn.pressed.connect(func():
					crt_overlay.toggle_pause(false)
					restart_event_level()
				)

			var pause_levels_btn: Button = crt_overlay.get_node_or_null("UI/PauseModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseLevelsBtn")
			if pause_levels_btn:
				for conn in pause_levels_btn.pressed.get_connections():
					pause_levels_btn.pressed.disconnect(conn.callable)
				pause_levels_btn.pressed.connect(func():
					crt_overlay.toggle_pause(false)
					return_to_event_menu()
				)

			var pause_home_btn: Button = crt_overlay.get_node_or_null("UI/PauseModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseHomeBtn",)
			if pause_home_btn:
				for conn in pause_home_btn.pressed.get_connections():
					pause_home_btn.pressed.disconnect(conn.callable)
				pause_home_btn.pressed.connect(func():
					crt_overlay.toggle_pause(false)
					return_to_event_menu()
				)

func restart_event_level() -> void:
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	_load_event_level()

	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func return_to_event_menu() -> void:
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file(EVENT_MENU_SCENE)

	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()
