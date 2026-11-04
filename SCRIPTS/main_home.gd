extends Control

# Visual references
@onready var bg_rect: ColorRect = $BG/ColorRect

# Scroll & Map
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas
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

# State variables
var selected_level_index: int = 0
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_dist: float = 0.0
var scroll_velocity_y: float = 0.0
var active_frog_sprite: Sprite2D = null
var elapsed_time: float = 0.0
var toast_tween: Tween = null
var is_transitioning: bool = false

func _ready() -> void:
	# Hide modals on start
	level_modal.visible = false
	settings_modal.visible = false
	toast_panel.visible = false
	toast_panel.modulate.a = 0.0

	# Ensure CRT state
	#crt_overlay.visible = GameManager.crt_enabled

	# Initialize settings & Play Games
	_init_settings_values()
	_init_play_games()

	# Connect Top & Bottom HUD
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.mouse_entered.connect(_play_hover)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	leaderboard_btn.mouse_entered.connect(_play_hover)
	settings_btn.pressed.connect(_on_settings_pressed)
	settings_btn.mouse_entered.connect(_play_hover)
	quick_play_btn.pressed.connect(_on_quick_play_pressed)
	quick_play_btn.mouse_entered.connect(_play_hover)

	# Connect Level Modal
	modal_start_btn.pressed.connect(_on_modal_start_pressed)
	modal_start_btn.mouse_entered.connect(_play_hover)
	modal_close_btn.pressed.connect(_close_level_modal)
	modal_close_btn.mouse_entered.connect(_play_hover)
	var dimmer := level_modal.get_node_or_null("Dimmer") as Control
	if dimmer:
		dimmer.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_level_modal()
		)

	# Connect Settings Modal
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	settings_back_btn.mouse_entered.connect(_play_hover)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Setup background audio
	if not bgm_player.playing:
		bgm_player.play()

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

# --- Touch & Mouse Inertia Dragging ---

func _input(event: InputEvent) -> void:
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

# --- Path & Nodes Construction ---

func _build_winding_path() -> void:
	path_glow.clear_points()
	path_line.clear_points()

	# Create a smooth Catmull-Rom or cubic spline passing through each level position
	var curve := Curve2D.new()
	for i in range(LEVEL_POSITIONS.size()):
		var pt := LEVEL_POSITIONS[i]
		# Add smooth control points based on surrounding positions
		if i == 0:
			curve.add_point(pt, Vector2.ZERO, Vector2(-80, -90))
		elif i == LEVEL_POSITIONS.size() - 1:
			curve.add_point(pt, Vector2(0, 90), Vector2.ZERO)
		else:
			var prev_pt := LEVEL_POSITIONS[i - 1]
			var next_pt := LEVEL_POSITIONS[i + 1]
			var tangent := (next_pt - prev_pt).normalized() * 110.0
			curve.add_point(pt, -tangent, tangent)

	# Bake smoothed curve points into lines
	var baked_pts := curve.get_baked_points()
	for pt in baked_pts:
		path_glow.add_point(pt)
		path_line.add_point(pt)

func _build_level_nodes() -> void:
	for child in nodes_container.get_children():
		child.queue_free()

	var total_levels := GameManager.levels.size()
	var current_unlocked := GameManager.unlocked_level

	for i in range(total_levels):
		var pos := LEVEL_POSITIONS[i]
		var is_unlocked := GameManager.is_level_unlocked(i)
		var is_current := (i == current_unlocked)
		var stars := GameManager.get_level_stars(i)

		# Master node container
		var node_btn := Button.new()
		node_btn.name = "Level_%d" % (i + 1)
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
			pad_sprite.modulate = Color(0.35, 0.45, 0.55, 0.72)
		else:
			pad_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
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
			glow_sb.border_color = Color(1.0, 0.88, 0.25, 0.85)
			glow_sb.set_corner_radius_all(80)
			glow_sb.shadow_color = Color(1.0, 0.85, 0.2, 0.6)
			glow_sb.shadow_size = 18
			glow_panel.add_theme_stylebox_override("panel", glow_sb)
			node_btn.add_child(glow_panel)

			# Animate pulse glow
			var pulse_tw := create_tween().set_loops()
			pulse_tw.tween_property(glow_panel, "modulate:a", 0.4, 0.9).set_trans(Tween.TRANS_SINE)
			pulse_tw.tween_property(glow_panel, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

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
			label.text = str(i + 1)
			label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35, 1.0) if is_current else Color(0.95, 0.98, 1.0, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.04, 0.12, 0.22, 1.0))
			label.add_theme_constant_override("outline_size", 10)
		else:
			label.text = "🔒"
			label.add_theme_font_size_override("font_size", 28)
			label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.7))
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
				star_lbl.add_theme_font_size_override("font_size", 20)
				if s < stars:
					star_lbl.text = "★"
					star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
					star_lbl.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.02, 0.9))
					star_lbl.add_theme_constant_override("outline_size", 6)
				else:
					star_lbl.text = "★"
					star_lbl.add_theme_color_override("font_color", Color(0.3, 0.45, 0.55, 0.45))
				stars_box.add_child(star_lbl)

			node_btn.add_child(stars_box)

		# Hover & Click Events
		if is_unlocked:
			node_btn.mouse_entered.connect(_on_node_hover.bind(node_btn))
			node_btn.mouse_exited.connect(_on_node_unhover.bind(node_btn))
			node_btn.pressed.connect(_on_node_clicked.bind(i))
		else:
			node_btn.mouse_filter = Control.MOUSE_FILTER_PASS

		nodes_container.add_child(node_btn)

func _on_node_hover(btn: Button) -> void:
	_play_hover()
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.18)

func _on_node_unhover(btn: Button) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.18)

func _on_node_clicked(level_idx: int) -> void:
	# Avoid triggering if the user was dragging/swiping
	if drag_dist > 25.0:
		return
	click_sfx.play()
	_open_level_modal(level_idx)

# --- Auto Scroll ---

func _auto_scroll_to_current_level() -> void:
	var current_idx: int = clamp(GameManager.unlocked_level, 0, LEVEL_POSITIONS.size() - 1)
	var target_y: float = LEVEL_POSITIONS[current_idx].y
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
	quick_play_btn.text = "▶  PLAY LEVEL %d" % next_lvl

# --- Level Modal Dialog ---

func _open_level_modal(level_idx: int) -> void:
	selected_level_index = level_idx
	modal_title.text = "LEVEL %d" % (level_idx + 1)

	var stars := GameManager.get_level_stars(level_idx)
	for i in range(modal_stars_row.get_child_count()):
		var star_lbl := modal_stars_row.get_child(i) as Label
		if star_lbl:
			if i < stars:
				star_lbl.modulate = Color(1.0, 0.88, 0.2, 1.0)
			else:
				star_lbl.modulate = Color(0.35, 0.45, 0.55, 0.45)

	if stars >= 3:
		modal_status_label.text = "Mastered! (3 Stars)"
		modal_status_label.modulate = Color(0.4, 1.0, 0.6)
	elif stars > 0:
		modal_status_label.text = "Completed (%d Stars)" % stars
		modal_status_label.modulate = Color(1.0, 0.9, 0.4)
	else:
		modal_status_label.text = "Ready to leap!"
		modal_status_label.modulate = Color(0.6, 0.85, 1.0)

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
	if is_transitioning:
		return
	is_transitioning = true
	back_sfx.play()

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file("res://SCENES/LEVELS/MainMenu.tscn")

func _on_leaderboard_pressed() -> void:
	click_sfx.play()
	if GodotPlayGameServices.is_signed_in:
		GodotPlayGameServices.show_all_leaderboards()
	else:
		_show_toast("Sign in to Google Play Games in Settings to view Leaderboards!")

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
	if bgm_player:
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

func _on_crt_toggled(toggled: bool) -> void:
	click_sfx.play()
	#crt_overlay.visible = toggled
	#GameManager.set_crt_enabled(toggled)

func _play_hover() -> void:
	hover_sfx.pitch_scale = randf_range(0.96, 1.08)
	hover_sfx.play()
