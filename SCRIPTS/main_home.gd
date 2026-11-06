extends Control

# Visual references
@onready var bg_rect: ColorRect = $BG/ColorRect

# Scroll & Map
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas
@onready var props_container: Control = $ScrollContainer/MapCanvas/PropsContainer
@onready var path_glow: Line2D = $ScrollContainer/MapCanvas/PathGlow
@onready var path_line: Line2D = $ScrollContainer/MapCanvas/PathLine
@onready var nodes_container: Control = $ScrollContainer/MapCanvas/NodesContainer

# HUD
@onready var back_btn: Button = $UI/TopBar/MarginContainer/HBoxContainer/BackButton
@onready var stars_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/StarsBadge/StarsLabel
@onready var coins_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/CoinsBadge/CoinsLabel
@onready var leaderboard_btn: Button = $UI/TopBar/MarginContainer/HBoxContainer/LeaderboardButton
@onready var settings_btn: Button = $UI/TopBar/MarginContainer/HBoxContainer/SettingsButton
@onready var quick_play_btn: Button = $UI/BottomBar/QuickPlayButton

# Level Info Modal
@onready var level_modal: Control = $LevelModal
@onready var modal_panel: PanelContainer = $LevelModal/CenterContainer/PanelContainer
@onready var modal_title: Label = $LevelModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ModalTitle
@onready var modal_stars_row: HBoxContainer = $LevelModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsRow
@onready var modal_status_label: Label = $LevelModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var modal_start_btn: Button = $LevelModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var modal_close_btn: Button = $LevelModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

# Settings Modal
@onready var settings_modal: Control = $SettingsModal
@onready var settings_panel: PanelContainer = $SettingsModal/CenterContainer/PanelContainer
@onready var volume_slider: HSlider = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var volume_label: Label = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeRow/HeaderRow/VolumeValue
@onready var fullscreen_check: CheckBox = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FullscreenRow/FullscreenCheck
@onready var play_games_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayGamesRow/PlayGamesButton
@onready var play_games_label: Label = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayGamesRow/PGLabel
@onready var settings_back_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsBackButton

# Leaderboard Modal
var leaderboard_modal: Control

# Toast Message
@onready var toast_panel: PanelContainer = $UI/ToastPanel
@onready var toast_label: Label = $UI/ToastPanel/ToastLabel

# Audio
@onready var hover_sfx: AudioStreamPlayer = $Audio/HoverSFX
@onready var click_sfx: AudioStreamPlayer = $Audio/ClickSFX
@onready var back_sfx: AudioStreamPlayer = $Audio/BackSFX
@onready var bgm_player: AudioStreamPlayer = $Audio/BGMPlayer

# Assets
const FONT_GORDITAS := preload("res://ASSETS/FONT/Gorditas-Bold.ttf")
const PAD_TEX := preload("res://ASSETS/TILES/pad1.png")
const FROG_TEX := preload("res://ASSETS/TILES/frog1.png")
const FLY_TEX := preload("res://ASSETS/TILES/fly1.png")

# Winding path level coordinates (15 levels, climbing from bottom to top)
const LEVEL_POSITIONS: Array[Vector2] = [
	Vector2(960, 3180),  # Level 1
	Vector2(700, 2960),  # Level 2
	Vector2(520, 2720),  # Level 3
	Vector2(720, 2480),  # Level 4
	Vector2(1060, 2260), # Level 5
	Vector2(1360, 2040), # Level 6
	Vector2(1420, 1800), # Level 7
	Vector2(1180, 1580), # Level 8
	Vector2(820, 1380),  # Level 9
	Vector2(560, 1180),  # Level 10
	Vector2(540, 960),   # Level 11
	Vector2(840, 760),   # Level 12
	Vector2(1180, 580),  # Level 13
	Vector2(1380, 400),  # Level 14
	Vector2(960, 220)    # Level 15 (Boss / Finale!)
]

# World Biomes & Candy Crush-style Theming
const BIOMES: Array[Dictionary] = [
	{
		"name": "Emerald Lagoon",
		"btn_title": "🌴 WORLD 1: LAGOON ▾",
		"subtitle": "Tropical Oasis",
		"water_deep": Color(0.01, 0.42, 0.48, 1.0),
		"water_mid": Color(0.04, 0.68, 0.68, 1.0),
		"water_bright": Color(0.14, 0.88, 0.84, 1.0),
		"caustic_color": Color(0.85, 1.0, 0.96, 0.50),
		"shimmer_color": Color(0.85, 1.0, 0.95, 1.0),
		"path_modulate": Color(1.0, 1.0, 1.0, 1.0),
		"path_glow": Color(0.01, 0.32, 0.35, 0.40),
		"props_modulate": Color(1.0, 1.0, 1.0, 1.0),
		"pad_modulate": Color(1.0, 1.0, 1.0, 1.0),
		"badge_color": Color(0.35, 0.95, 0.75, 1.0),
	},
	{
		"name": "Twilight Swamp",
		"btn_title": "🌙 WORLD 2: TWILIGHT ▾",
		"subtitle": "Mystic Orchid Bog",
		"water_deep": Color(0.14, 0.04, 0.28, 1.0),
		"water_mid": Color(0.32, 0.10, 0.54, 1.0),
		"water_bright": Color(0.66, 0.22, 0.88, 1.0),
		"caustic_color": Color(1.0, 0.52, 0.94, 0.60),
		"shimmer_color": Color(1.0, 0.75, 1.0, 1.0),
		"path_modulate": Color(0.82, 0.58, 1.0, 1.0),
		"path_glow": Color(0.38, 0.08, 0.52, 0.55),
		"props_modulate": Color(0.82, 0.72, 1.0, 1.0),
		"pad_modulate": Color(0.85, 0.75, 1.0, 1.0),
		"badge_color": Color(0.92, 0.45, 1.0, 1.0),
	},
	{
		"name": "Molten Citadel",
		"btn_title": "🔥 WORLD 3: MOLTEN ▾",
		"subtitle": "Amber Sunken Ruins",
		"water_deep": Color(0.28, 0.06, 0.02, 1.0),
		"water_mid": Color(0.64, 0.16, 0.04, 1.0),
		"water_bright": Color(0.96, 0.48, 0.08, 1.0),
		"caustic_color": Color(1.0, 0.88, 0.32, 0.65),
		"shimmer_color": Color(1.0, 0.95, 0.6, 1.0),
		"path_modulate": Color(1.0, 0.68, 0.35, 1.0),
		"path_glow": Color(0.55, 0.12, 0.02, 0.60),
		"props_modulate": Color(1.0, 0.78, 0.65, 1.0),
		"pad_modulate": Color(1.0, 0.82, 0.68, 1.0),
		"badge_color": Color(1.0, 0.68, 0.2, 1.0),
	}
]

# State variables
var current_chapter: int = 0
var chapter_btn: Button = null
var biome_tween: Tween = null
var selected_level_index: int = 0
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_dist: float = 0.0
var scroll_velocity_y: float = 0.0
var active_frog_sprite: Sprite2D = null
var active_glow_panel: Panel = null
var elapsed_time: float = 0.0
var toast_tween: Tween = null
var is_transitioning: bool = false

func _ready() -> void:
	# Hide modals on start
	level_modal.visible = false
	settings_modal.visible = false
	toast_panel.visible = false
	toast_panel.modulate.a = 0.0

	# Initialize Leaderboard Modal
	leaderboard_modal = get_node_or_null("LeaderboardModal")
	if not leaderboard_modal:
		var lb_scene = load("res://SCENES/UI/LeaderboardModal.tscn")
		if lb_scene:
			leaderboard_modal = lb_scene.instantiate()
			leaderboard_modal.name = "LeaderboardModal"
			add_child(leaderboard_modal)
	if leaderboard_modal:
		leaderboard_modal.visible = false

	# Ensure CRT state
	#crt_overlay.visible = GameManager.crt_enabled

	# Initialize settings & Play Games
	_init_settings_values()
	_init_play_games()

	# Connect Top & Bottom HUD
	back_btn.pressed.connect(_on_back_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quick_play_btn.pressed.connect(_on_quick_play_pressed)

	_hook_btn_animations(back_btn)
	_hook_btn_animations(leaderboard_btn)
	_hook_btn_animations(settings_btn)
	_hook_btn_animations(quick_play_btn)

	# Connect Level Modal
	modal_start_btn.pressed.connect(_on_modal_start_pressed)
	modal_close_btn.pressed.connect(_close_level_modal)
	_hook_btn_animations(modal_start_btn)
	_hook_btn_animations(modal_close_btn)

	var dimmer := level_modal.get_node_or_null("Dimmer") as Control
	if dimmer:
		dimmer.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_level_modal()
		)

	# Connect Settings Modal
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	_hook_btn_animations(settings_back_btn)
	_hook_btn_animations(play_games_btn)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


	# Setup background audio (handled globally by MusicManager if available)
	if bgm_player:
		if has_node("/root/MusicManager"):
			bgm_player.stop()
			bgm_player.stream = null
		elif not bgm_player.playing:
			bgm_player.play()

	# Auto-select chapter based on unlocked level
	if GameManager.unlocked_level >= 15:
		current_chapter = int(GameManager.unlocked_level / 15)
	else:
		current_chapter = 0

	_setup_chapter_button()
	_apply_biome_theme(false)

	# Generate level map nodes and path
	_build_winding_path()
	_build_level_nodes()
	_update_hud_counters()

	# Auto-focus scroll onto highest unlocked level
	await get_tree().process_frame
	_auto_scroll_to_current_level()

	# Transition in
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func _hook_btn_animations(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.custom_minimum_size * 0.5 if btn.custom_minimum_size != Vector2.ZERO else btn.size * 0.5
	btn.mouse_entered.connect(func():
		_play_hover()
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.16)
	)
	btn.mouse_exited.connect(func():
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.16)
	)

func _process(delta: float) -> void:
	elapsed_time += delta

	# 1. Smooth Inertia Scrolling
	if not is_dragging and abs(scroll_velocity_y) > 0.5:
		scroll_container.scroll_vertical -= int(scroll_velocity_y * delta)
		scroll_velocity_y = lerp(scroll_velocity_y, 0.0, delta * 9.0)
		var max_s: int = int(map_canvas.custom_minimum_size.y - scroll_container.size.y)
		scroll_container.scroll_vertical = clampi(scroll_container.scroll_vertical, 0, max_s)

	# 2. Animate Frog on Active Level Pad
	if is_instance_valid(active_frog_sprite):
		var bob := sin(elapsed_time * 3.5) * 6.0
		var breath := sin(elapsed_time * 4.0) * 0.04
		active_frog_sprite.position.y = active_frog_sprite.get_meta("base_y", 0.0) + bob
		active_frog_sprite.scale = Vector2(1.3 * (1.0 + breath), 1.3 * (1.0 - breath))

	# 3. Animate Glow Ring on Active Level Pad
	if is_instance_valid(active_glow_panel):
		active_glow_panel.modulate.a = 0.7 + sin(elapsed_time * 3.5) * 0.3

	# 4. Animate ambient floating props (lotus flowers & pads)
	if is_instance_valid(props_container):
		for prop in props_container.get_children():
			if prop.name.begins_with("Lotus") or prop.name.begins_with("PadLotus"):
				var base_y = prop.get_meta("base_y", -999.0)
				if base_y == -999.0:
					base_y = prop.position.y
					prop.set_meta("base_y", base_y)
				prop.position.y = base_y + sin(elapsed_time * 2.2 + prop.position.x * 0.02) * 4.0

# --- Touch & Mouse Inertia Dragging ---

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_launch_level(GameManager.levels.size() - 1)
		return

	if level_modal.visible or settings_modal.visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_pos = event.position
				drag_dist = 0.0
				scroll_velocity_y = 0.0
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var delta_y: float = event.relative.y
		scroll_container.scroll_vertical -= int(delta_y)
		scroll_velocity_y = delta_y / maxf(get_process_delta_time(), 0.001)
		drag_dist += abs(delta_y) + abs(event.relative.x)

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			drag_start_pos = event.position
			drag_dist = 0.0
			scroll_velocity_y = 0.0
		else:
			is_dragging = false
	elif event is InputEventScreenDrag and is_dragging:
		var delta_y: float = event.relative.y
		scroll_container.scroll_vertical -= int(delta_y)
		scroll_velocity_y = delta_y / maxf(get_process_delta_time(), 0.001)
		drag_dist += abs(delta_y) + abs(event.relative.x)

# --- Chapter / World System ---

func _setup_chapter_button() -> void:
	var total_chapters: int = int(ceil(float(GameManager.levels.size()) / 15.0))
	if total_chapters <= 1:
		return

	var hbox := $UI/TopBar/MarginContainer/HBoxContainer as HBoxContainer
	if not hbox:
		return

	chapter_btn = Button.new()
	chapter_btn.name = "ChapterButton"
	chapter_btn.custom_minimum_size = Vector2(250, 56)
	chapter_btn.add_theme_font_override("font", FONT_GORDITAS)
	chapter_btn.add_theme_font_size_override("font_size", 19)
	chapter_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
	chapter_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85, 1.0))
	chapter_btn.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 1.0))
	chapter_btn.add_theme_constant_override("outline_size", 6)

	var sb_norm := load("res://ASSETS/UI/panels/wood_badge.svg") as Texture2D
	if sb_norm:
		var st := StyleBoxTexture.new()
		st.texture = sb_norm
		st.texture_margin_left = 18.0
		st.texture_margin_right = 18.0
		st.texture_margin_top = 10.0
		st.texture_margin_bottom = 10.0
		chapter_btn.add_theme_stylebox_override("normal", st)
		chapter_btn.add_theme_stylebox_override("hover", st)
		chapter_btn.add_theme_stylebox_override("pressed", st)

	chapter_btn.pressed.connect(_on_chapter_button_pressed)
	_hook_btn_animations(chapter_btn)

	# Place nicely in top bar after Back button
	hbox.add_child(chapter_btn)
	hbox.move_child(chapter_btn, 1)

	_update_chapter_button_text()

func _update_chapter_button_text() -> void:
	if is_instance_valid(chapter_btn):
		var biome_idx := clampi(current_chapter, 0, BIOMES.size() - 1)
		var biome: Dictionary = BIOMES[biome_idx]
		chapter_btn.text = biome.btn_title
		chapter_btn.add_theme_color_override("font_color", biome.badge_color)

func _apply_biome_theme(animate: bool = true) -> void:
	var biome_idx := clampi(current_chapter, 0, BIOMES.size() - 1)
	var biome: Dictionary = BIOMES[biome_idx]
	var mat := bg_rect.material as ShaderMaterial
	if not mat:
		return

	if biome_tween and biome_tween.is_valid():
		biome_tween.kill()

	if not animate:
		mat.set_shader_parameter("water_deep", biome.water_deep)
		mat.set_shader_parameter("water_mid", biome.water_mid)
		mat.set_shader_parameter("water_bright", biome.water_bright)
		mat.set_shader_parameter("caustic_color", biome.caustic_color)
		mat.set_shader_parameter("shimmer_color", biome.shimmer_color)
		path_line.self_modulate = biome.path_modulate
		path_glow.default_color = biome.path_glow
		if is_instance_valid(props_container):
			props_container.modulate = biome.props_modulate
	else:
		var cur_deep = mat.get_shader_parameter("water_deep")
		var cur_mid = mat.get_shader_parameter("water_mid")
		var cur_bright = mat.get_shader_parameter("water_bright")
		var cur_caustic = mat.get_shader_parameter("caustic_color")
		var cur_shimmer = mat.get_shader_parameter("shimmer_color")
		if cur_deep == null: cur_deep = biome.water_deep
		if cur_mid == null: cur_mid = biome.water_mid
		if cur_bright == null: cur_bright = biome.water_bright
		if cur_caustic == null: cur_caustic = biome.caustic_color
		if cur_shimmer == null: cur_shimmer = biome.shimmer_color

		biome_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		biome_tween.tween_method(func(c: Color): mat.set_shader_parameter("water_deep", c), cur_deep, biome.water_deep, 0.65)
		biome_tween.tween_method(func(c: Color): mat.set_shader_parameter("water_mid", c), cur_mid, biome.water_mid, 0.65)
		biome_tween.tween_method(func(c: Color): mat.set_shader_parameter("water_bright", c), cur_bright, biome.water_bright, 0.65)
		biome_tween.tween_method(func(c: Color): mat.set_shader_parameter("caustic_color", c), cur_caustic, biome.caustic_color, 0.65)
		biome_tween.tween_method(func(c: Color): mat.set_shader_parameter("shimmer_color", c), cur_shimmer, biome.shimmer_color, 0.65)
		biome_tween.tween_property(path_line, "self_modulate", biome.path_modulate, 0.65)
		biome_tween.tween_property(path_glow, "default_color", biome.path_glow, 0.65)
		if is_instance_valid(props_container):
			biome_tween.tween_property(props_container, "modulate", biome.props_modulate, 0.65)

func _show_world_banner() -> void:
	var biome_idx := clampi(current_chapter, 0, BIOMES.size() - 1)
	var biome: Dictionary = BIOMES[biome_idx]
	_show_toast("✦ %s ✦\n%s" % [biome.name.to_upper(), biome.subtitle])

func _on_chapter_button_pressed() -> void:
	click_sfx.play()
	var total_chapters: int = int(ceil(float(GameManager.levels.size()) / 15.0))
	current_chapter = (current_chapter + 1) % total_chapters
	_update_chapter_button_text()
	_apply_biome_theme(true)
	_build_winding_path()
	_build_level_nodes()
	_auto_scroll_to_current_level()
	_show_world_banner()

# --- Path & Nodes Construction ---

func _build_winding_path() -> void:
	path_glow.clear_points()
	path_line.clear_points()

	var start_idx: int = current_chapter * 15
	var remaining: int = GameManager.levels.size() - start_idx
	var count: int = clampi(remaining, 0, LEVEL_POSITIONS.size())
	if count <= 0:
		return

	# Create a smooth Catmull-Rom or cubic spline passing through each level position
	var curve := Curve2D.new()
	for i in range(count):
		var pt := LEVEL_POSITIONS[i]
		if i == 0:
			curve.add_point(pt, Vector2.ZERO, Vector2(-80, -90))
		elif i == count - 1:
			curve.add_point(pt, Vector2(0, 90), Vector2.ZERO)
		else:
			var prev_pt := LEVEL_POSITIONS[i - 1]
			var next_pt := LEVEL_POSITIONS[i + 1]
			var tangent := (next_pt - prev_pt).normalized() * 110.0
			curve.add_point(pt, -tangent, tangent)

	# Bake smoothed curve points into lines
	var baked_pts := curve.get_baked_points()
	for pt in baked_pts:
		path_glow.add_point(pt + Vector2(0, 8))
		path_line.add_point(pt)

func _build_level_nodes() -> void:
	for child in nodes_container.get_children():
		child.queue_free()
	active_frog_sprite = null
	active_glow_panel = null

	var biome_idx := clampi(current_chapter, 0, BIOMES.size() - 1)
	var biome: Dictionary = BIOMES[biome_idx]

	var start_idx: int = current_chapter * 15
	var remaining: int = GameManager.levels.size() - start_idx
	var count: int = clampi(remaining, 0, LEVEL_POSITIONS.size())
	var current_unlocked := GameManager.unlocked_level

	for j in range(count):
		var global_level_idx: int = start_idx + j
		var pos: Vector2 = LEVEL_POSITIONS[j]
		var is_unlocked := GameManager.is_level_unlocked(global_level_idx)
		var is_current := (global_level_idx == current_unlocked)
		var stars := GameManager.get_level_stars(global_level_idx)

		# Master node container
		var node_btn := Button.new()
		node_btn.name = "Level_%d" % (global_level_idx + 1)
		node_btn.flat = true
		node_btn.custom_minimum_size = Vector2(170, 170)
		node_btn.position = pos - Vector2(85, 85)
		node_btn.pivot_offset = Vector2(85, 85)

		# 1. Lilypad Sprite
		var pad_sprite := Sprite2D.new()
		pad_sprite.texture = PAD_TEX
		pad_sprite.position = Vector2(85, 85)
		pad_sprite.scale = Vector2(1.9, 1.9)
		pad_sprite.name = "PadSprite"

		if not is_unlocked:
			pad_sprite.modulate = Color(biome.pad_modulate.r * 0.42, biome.pad_modulate.g * 0.50, biome.pad_modulate.b * 0.48, 0.72)
		else:
			pad_sprite.modulate = biome.pad_modulate
		node_btn.add_child(pad_sprite)

		# 2. Glowing Indicator Ring for Active Level
		if is_current:
			var glow_panel := Panel.new()
			glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow_panel.size = Vector2(160, 160)
			glow_panel.position = Vector2(5, 5)
			var glow_sb := StyleBoxFlat.new()
			glow_sb.draw_center = false
			glow_sb.set_border_width_all(4)
			glow_sb.border_color = biome.badge_color
			glow_sb.set_corner_radius_all(80)
			glow_sb.shadow_color = Color(biome.badge_color.r, biome.badge_color.g, biome.badge_color.b, 0.65)
			glow_sb.shadow_size = 18
			glow_panel.add_theme_stylebox_override("panel", glow_sb)
			active_glow_panel = glow_panel
			node_btn.add_child(glow_panel)

		# 3. Mascot Frog sitting on active level!
		if is_current:
			var frog_sprite := Sprite2D.new()
			frog_sprite.texture = FROG_TEX
			frog_sprite.position = Vector2(85, 52)
			frog_sprite.scale = Vector2(1.3, 1.3)
			frog_sprite.set_meta("base_y", 52.0)
			frog_sprite.name = "ActiveFrog"
			active_frog_sprite = frog_sprite
			node_btn.add_child(frog_sprite)

		# 4. Level Number / Lock Label
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size = Vector2(170, 50)
		label.position = Vector2(0, 58 if not is_current else 82)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT_GORDITAS)
		label.add_theme_font_size_override("font_size", 34 if not is_current else 26)

		if is_unlocked:
			label.text = str(global_level_idx + 1)
			label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35, 1.0) if is_current else Color(1.0, 1.0, 1.0, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 1.0))
			label.add_theme_constant_override("outline_size", 10)
		else:
			label.text = "🔒"
			label.add_theme_font_size_override("font_size", 28)
			label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.8, 0.75))
			label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 1.0))
			label.add_theme_constant_override("outline_size", 6)
		node_btn.add_child(label)

		# 5. Stars earned badge (under lilypad)
		if is_unlocked:
			var stars_box := HBoxContainer.new()
			stars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
			stars_box.position = Vector2(15, 142)
			stars_box.size = Vector2(140, 26)
			stars_box.add_theme_constant_override("separation", 4)

			for s in range(3):
				var star_lbl := Label.new()
				star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				star_lbl.add_theme_font_override("font", FONT_GORDITAS)
				star_lbl.add_theme_font_size_override("font_size", 22)
				if s < stars:
					star_lbl.text = "★"
					star_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22, 1.0))
					star_lbl.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 1.0))
					star_lbl.add_theme_constant_override("outline_size", 6)
				else:
					star_lbl.text = "★"
					star_lbl.add_theme_color_override("font_color", Color(0.2, 0.32, 0.26, 0.45))
				stars_box.add_child(star_lbl)

			node_btn.add_child(stars_box)

		# Hover & Click Events
		if is_unlocked or OS.is_debug_build():
			node_btn.mouse_entered.connect(_on_node_hover.bind(node_btn))
			node_btn.mouse_exited.connect(_on_node_unhover.bind(node_btn))
			node_btn.pressed.connect(_on_node_clicked.bind(global_level_idx))
		else:
			node_btn.mouse_filter = Control.MOUSE_FILTER_PASS

		nodes_container.add_child(node_btn)

func _on_node_hover(btn: Button) -> void:
	_play_hover()
	if not is_instance_valid(btn):
		return
	var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.18)

func _on_node_unhover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.18)

func _on_node_clicked(level_idx: int) -> void:
	# Avoid triggering if the user was dragging/swiping
	if drag_dist > 25.0:
		return
	click_sfx.play()
	_open_level_modal(level_idx)

# --- Auto Scroll ---

func _auto_scroll_to_current_level() -> void:
	var start_idx: int = current_chapter * 15
	var relative_idx: int = clampi(GameManager.unlocked_level - start_idx, 0, LEVEL_POSITIONS.size() - 1)
	var target_y: float = LEVEL_POSITIONS[relative_idx].y
	var viewport_h: float = scroll_container.size.y if scroll_container.size.y > 0 else 1080.0
	var max_scroll: float = maxf(map_canvas.custom_minimum_size.y - viewport_h, 0.0)
	var target_scroll: float = clampf(target_y - (viewport_h * 0.5), 0.0, max_scroll)

	# Set initially or glide smoothly
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(scroll_container, "scroll_vertical", int(target_scroll), 0.85)

# --- HUD & Counter Updates ---

func _update_hud_counters() -> void:
	# 1. Total Stars
	var total_stars: int = 0
	for i in range(GameManager.levels.size()):
		total_stars += GameManager.get_level_stars(i)
	var max_stars: int = GameManager.levels.size() * 3
	stars_label.text = "⭐ %d / %d" % [total_stars, max_stars]

	# 2. Coins badge (future proofed)
	coins_label.text = "🪙 0"

	# 3. Quick Play button text
	var next_lvl := GameManager.unlocked_level + 1
	if next_lvl > GameManager.levels.size():
		next_lvl = GameManager.levels.size()
	quick_play_btn.text = "    ▶  PLAY LEVEL %d" % next_lvl

# --- Level Modal Dialog ---

func _open_level_modal(level_idx: int) -> void:
	selected_level_index = level_idx
	modal_title.text = "LEVEL %d" % (level_idx + 1)

	# Check for ASCII level title
	var txt_path := "res://LEVELS_DATA/level_%d.txt" % (level_idx + 1)
	if FileAccess.file_exists(txt_path):
		var f := FileAccess.open(txt_path, FileAccess.READ)
		if f:
			while not f.eof_reached():
				var l := f.get_line().strip_edges()
				if l.to_lower().begins_with("name:"):
					var lvl_name := l.substr(5).strip_edges()
					if lvl_name != "":
						modal_title.text = "LVL %d: %s" % [level_idx + 1, lvl_name]
					break
				if l == "" or (l.begins_with("#") and not l.to_lower().begins_with("# name:")):
					continue
				if not l.contains(":"):
					break

	var stars := GameManager.get_level_stars(level_idx)
	for i in range(modal_stars_row.get_child_count()):
		var star_lbl := modal_stars_row.get_child(i) as Label
		if star_lbl:
			if i < stars:
				star_lbl.modulate = Color(1.0, 0.88, 0.2, 1.0)
			else:
				star_lbl.modulate = Color(0.25, 0.35, 0.3, 0.45)

	if stars >= 3:
		modal_status_label.text = "Mastered! (3 Stars)"
		modal_status_label.modulate = Color(0.18, 0.58, 0.16)
	elif stars > 0:
		modal_status_label.text = "Completed (%d Stars)" % stars
		modal_status_label.modulate = Color(0.68, 0.44, 0.08)
	else:
		modal_status_label.text = "Ready to leap!"
		modal_status_label.modulate = Color(0.32, 0.2, 0.1)

	level_modal.visible = true
	level_modal.modulate.a = 0.0
	modal_panel.scale = Vector2(0.85, 0.85)
	modal_panel.pivot_offset = modal_panel.size * 0.5

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(level_modal, "modulate:a", 1.0, 0.22)
	tw.tween_property(modal_panel, "scale", Vector2.ONE, 0.25)

func _close_level_modal() -> void:
	back_sfx.play()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(level_modal, "modulate:a", 0.0, 0.18)
	tw.tween_property(modal_panel, "scale", Vector2(0.85, 0.85), 0.18)
	await tw.finished
	level_modal.visible = false

func _on_modal_start_pressed() -> void:
	_launch_level(selected_level_index)

func _on_quick_play_pressed() -> void:
	click_sfx.play()
	var target_idx = clamp(GameManager.unlocked_level, 0, GameManager.levels.size() - 1)
	_launch_level(target_idx)

func _launch_level(level_idx: int) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	click_sfx.play()

	# Store level in GameManager
	GameManager.current_level_index = level_idx

	# Transition out
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file("res://SCENES/LEVELS/main.tscn")

# --- Top Bar Actions ---

func _on_back_pressed() -> void:
	back_sfx.play()
	get_tree().change_scene_to_file("res://SCENES/LEVELS/MainMenu.tscn")

func _on_leaderboard_pressed() -> void:
	click_sfx.play()
	if not leaderboard_modal:
		var lb_scene = load("res://SCENES/UI/LeaderboardModal.tscn")
		if lb_scene:
			leaderboard_modal = lb_scene.instantiate()
			leaderboard_modal.name = "LeaderboardModal"
			add_child(leaderboard_modal)
	if leaderboard_modal:
		if leaderboard_modal.has_method("open"):
			leaderboard_modal.open()
		else:
			leaderboard_modal.visible = true

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_panel.visible = true
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	toast_tween.tween_interval(2.8)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

# --- Settings Modal ---

func _on_settings_pressed() -> void:
	click_sfx.play()
	settings_modal.visible = true
	settings_modal.modulate.a = 0.0
	settings_panel.scale = Vector2(0.85, 0.85)
	settings_panel.pivot_offset = settings_panel.size * 0.5

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(settings_modal, "modulate:a", 1.0, 0.22)
	tw.tween_property(settings_panel, "scale", Vector2.ONE, 0.26)

func _on_settings_back_pressed() -> void:
	back_sfx.play()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(settings_modal, "modulate:a", 0.0, 0.18)
	tw.tween_property(settings_panel, "scale", Vector2(0.85, 0.85), 0.18)
	await tw.finished
	settings_modal.visible = false

func _init_settings_values() -> void:
	if bgm_player and not has_node("/root/MusicManager"):
		bgm_player.volume_db = 0.0 if GameManager.music_enabled else -80.0

	volume_slider.value = GameManager.master_volume
	volume_label.text = "%d%%" % int(GameManager.master_volume * 100.0)

	var is_fullscreen := (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = is_fullscreen
	
func _init_play_games() -> void:
	if not GodotPlayGameServices:
		return
	play_games_btn.pressed.connect(func():
		click_sfx.play()
		if GodotPlayGameServices.is_signed_in:
			GodotPlayGameServices.show_profile()
		else:
			GodotPlayGameServices.sign_in()
	)
	GodotPlayGameServices.user_authenticated.connect(func(authenticated: bool):
		if authenticated:
			play_games_btn.text = "PROFILE"
			play_games_label.text = "GOOGLE PLAY: SIGNED IN"
		else:
			play_games_btn.text = "SIGN IN"
			play_games_label.text = "GOOGLE PLAY GAMES"
	)
	GodotPlayGameServices.current_player_loaded.connect(func(player: PlayGamesPlayer):
		if player:
			play_games_label.text = "PLAY: %s" % player.display_name
	)
	if GodotPlayGameServices.is_signed_in:
		play_games_btn.text = "PROFILE"
		play_games_label.text = "GOOGLE PLAY: SIGNED IN"

func _on_volume_changed(val: float) -> void:
	GameManager.set_master_volume(val)
	volume_label.text = "%d%%" % int(val * 100.0)

func _on_fullscreen_toggled(pressed: bool) -> void:
	click_sfx.play()
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _play_hover() -> void:
	hover_sfx.pitch_scale = randf_range(0.96, 1.08)
	hover_sfx.play()
