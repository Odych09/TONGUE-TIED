extends Node2D

const ASCII_LEVEL_SCENE: PackedScene = preload("res://SCENES/LEVELS/ascii_level.tscn")
const EVENT_LEVEL_FILE: String = "res://LEVELS_DATA/royal_infinity.txt"
const EVENT_MENU_SCENE: String = "res://SCENES/seasons/RoyalInfinity.tscn"

@onready var level_holder: Node2D = $LevelHolder
@onready var crt_overlay: Node = $CRT
@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer

var current_level_instance: AsciiLevel = null
var abyss_canvas: CanvasLayer = null
var drop_shadow: ColorRect = null

func _ready() -> void:
	if bgm_player and has_node("/root/MusicManager"):
		bgm_player.stop()
		bgm_player.stream = null
	if has_node("/root/MusicManager"):
		MusicManager.play_game_music()

	_setup_abyss_atmosphere()
	_load_event_level()

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func _setup_abyss_atmosphere() -> void:
	if is_instance_valid(abyss_canvas):
		abyss_canvas.queue_free()

	# 1. Full-screen infinite dark chasm backdrop (behind everything)
	abyss_canvas = CanvasLayer.new()
	abyss_canvas.name = "AbyssCanvas"
	abyss_canvas.layer = -100
	add_child(abyss_canvas)

	# Deep, ominous midnight slate abyss
	var abyss_rect := ColorRect.new()
	abyss_rect.name = "AbyssColor"
	abyss_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	abyss_rect.color = Color(0.04, 0.045, 0.065, 1.0)
	abyss_canvas.add_child(abyss_rect)

	# 2. Slow-drifting ethereal chasm mist deep in the void below the ruins
	var chasm_mist := CPUParticles2D.new()
	chasm_mist.name = "ChasmMist"
	chasm_mist.position = Vector2(960.0, 540.0)
	chasm_mist.amount = 22
	chasm_mist.lifetime = 12.0
	chasm_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	chasm_mist.emission_rect_extents = Vector2(1000.0, 600.0)
	chasm_mist.spread = 180.0
	chasm_mist.gravity = Vector2(10, -6)
	chasm_mist.initial_velocity_min = 6.0
	chasm_mist.initial_velocity_max = 18.0
	chasm_mist.scale_amount_min = 30.0
	chasm_mist.scale_amount_max = 65.0
	chasm_mist.color = Color(0.10, 0.12, 0.18, 0.22)
	abyss_canvas.add_child(chasm_mist)

	# 3. Soft drop shadow under the 3072x2048 floating ruin slab
	if is_instance_valid(drop_shadow):
		drop_shadow.queue_free()
	drop_shadow = ColorRect.new()
	drop_shadow.name = "RuinDropShadow"
	drop_shadow.position = Vector2(-28.0, -16.0)
	drop_shadow.size = Vector2(3072.0 + 56.0, 2048.0 + 52.0)
	drop_shadow.color = Color(0.0, 0.0, 0.0, 0.72)
	drop_shadow.z_index = -5
	level_holder.add_child(drop_shadow)

func _load_event_level() -> void:
	if is_instance_valid(current_level_instance):
		current_level_instance.queue_free()

	current_level_instance = ASCII_LEVEL_SCENE.instantiate() as AsciiLevel
	current_level_instance.level_file = EVENT_LEVEL_FILE
	level_holder.add_child(current_level_instance)

	# Remove the flat cartoon cyan water ocean layer surrounding the level
	var bg_water: TileMapLayer = current_level_instance.get_node_or_null("BackgroundWater")
	if bg_water:
		bg_water.visible = false

	# Apply eerie, high-contrast torchlit ruin lighting to the level
	current_level_instance.modulate = Color(0.96, 0.92, 0.88)

	_bind_player_and_crt()

func _bind_player_and_crt() -> void:
	await get_tree().process_frame
	var player := level_holder.find_child("Player", true, false) as Frog
	if player and crt_overlay and crt_overlay.has_method("setup_player"):
		crt_overlay.setup_player(player)

	# Enhance CRT & HUD atmosphere for the Royal Event
	if crt_overlay:
		# 1. Transform the green pond leaves into glowing golden embers rising from the abyss
		var pond: CPUParticles2D = crt_overlay.get_node_or_null("PondAmbience")
		if pond:
			pond.amount = 45
			pond.lifetime = 5.5
			pond.spread = 120.0
			pond.gravity = Vector2(0, -32)
			pond.initial_velocity_min = 12.0
			pond.initial_velocity_max = 35.0
			pond.scale_amount_min = 2.0
			pond.scale_amount_max = 5.5
			pond.color = Color(1.0, 0.82, 0.35, 0.75) # Glowing royal embers

		# 2. Deepen CRT vignette for scary, intense cinematic focus
		var crt_rect: ColorRect = crt_overlay.get_node_or_null("ColorRect")
		if crt_rect and crt_rect.material is ShaderMaterial:
			var mat: ShaderMaterial = crt_rect.material.duplicate()
			mat.set_shader_parameter("vignette", 0.58)
			crt_rect.material = mat

		# 3. Premium Royal Infinity HUD Badge
		var level_label: Label = crt_overlay.get_node_or_null("UI/TopLeftBar/LevelBadge/LevelLabel")
		if level_label:
			level_label.text = "⚜ ROYAL INFINITY ⚜"
			level_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			level_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02))
			level_label.add_theme_constant_override("outline_size", 8)

		# 4. Intercept HUD restart & menu actions for the event
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

			var pause_home_btn: Button = crt_overlay.get_node_or_null("UI/PauseModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseHomeBtn")
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
