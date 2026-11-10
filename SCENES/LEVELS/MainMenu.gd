extends Control

# Background and post-process
@onready var crt_overlay: CanvasLayer = $CRTOverlay

# Hero diorama nodes
@onready var diorama: Node2D = $Diorama
@onready var ambient_pad_1: Sprite2D = $Diorama/AmbientPad1
@onready var ambient_pad_2: Sprite2D = $Diorama/AmbientPad2
@onready var pad_shadow: Sprite2D = $Diorama/PadShadow
@onready var lily_pad: Sprite2D = $Diorama/LilyPad
@onready var frog: Sprite2D = $Diorama/Frog
@onready var fly: Sprite2D = $Diorama/Fly
@onready var tongue: Line2D = $Diorama/Tongue
@onready var title_tongue: Line2D = $UI/MarginContainer/HBoxContainer/LeftColumn/TitleBox/TitleTongueAccent

# UI components
@onready var title_box: Control = $UI/MarginContainer/HBoxContainer/LeftColumn/TitleBox
@onready var play_btn: Button = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/PlayButton
@onready var settings_btn: Button = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/SettingsButton
@onready var quit_btn: Button = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/QuitButton

# Indicator pips inside buttons
@onready var play_pip: Panel = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/PlayButton/Pip
@onready var settings_pip: Panel = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/SettingsButton/Pip
@onready var quit_pip: Panel = $UI/MarginContainer/HBoxContainer/LeftColumn/ButtonsStack/QuitButton/Pip

# Settings Modal
@onready var settings_modal: Control = $SettingsModal
@onready var settings_panel: PanelContainer = $SettingsModal/CenterContainer/PanelContainer
@onready var volume_slider = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var volume_label: Label = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VolumeRow/HeaderRow/VolumeValue
@onready var fullscreen_check: CheckBox = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FullscreenRow/FullscreenCheck
@onready var crt_check: CheckBox = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CRTRow/CRTCheck
@onready var play_games_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayGamesRow/PlayGamesButton
@onready var play_games_label: Label = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayGamesRow/PGLabel
@onready var language_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LanguageRow/LanguageButton
@onready var language_label: Label = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LanguageRow/LanguageLabel
@onready var leaderboard_opt_out_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LeaderboardRow/LeaderboardOptOutButton
@onready var delete_data_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DeleteDataRow/DeleteDataButton
@onready var settings_back_btn: Button = $SettingsModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsBackButton

# Loading Modal
@onready var loading_modal: Control = $LoadingModal
@onready var loading_spinner: Label = $LoadingModal/CenterContainer/Card/MarginContainer/VBox/Spinner
@onready var loading_status: Label = $LoadingModal/CenterContainer/Card/MarginContainer/VBox/Status



# Audio Stream Players
@onready var bgm_player: AudioStreamPlayer = $Audio/BGMPlayer
@onready var hover_sfx: AudioStreamPlayer = $Audio/HoverSFX
@onready var click_sfx: AudioStreamPlayer = $Audio/ClickSFX
@onready var back_sfx: AudioStreamPlayer = $Audio/BackSFX

# Background parallax layers (ordered from 7 = farthest sky to 1 = closest foreground)
@onready var bg_layers: Array[TextureRect] = [
	$"BG/7",
	$"BG/6",
	$"BG/5",
	$"BG/4",
	$"BG/3",
	$"BG/2",
	$"BG/1"
]

const LAYER_WEIGHTS: Array[float] = [
	0.06,  # 7: Sky & deep background canopy
	0.14,  # 6: Distant misty woods
	0.26,  # 5: Mid-distant trees
	0.42,  # 4: Midground trunks
	0.62,  # 3: Stumps and face mushrooms
	0.85,  # 2: Foreground mushrooms & moss
	1.15   # 1: Nearest ground log & roots
]
const MAX_PARALLAX_OFFSET: Vector2 = Vector2(46.0, 24.0)

# State variables
var elapsed_time: float = 0.0
var diorama_base_pos: Vector2
var pad_base_pos: Vector2
var pad_shadow_base_pos: Vector2
var frog_base_pos: Vector2
var frog_base_scale: Vector2
var fly_base_pos: Vector2
var title_base_pos: Vector2

var current_parallax: Vector2 = Vector2.ZERO
var btn_base_x: Dictionary = {}

var is_snapping: bool = false
var fly_caught: bool = false
var active_hover_btn: Button = null
var hover_tongue_prog: float = 0.0
var last_hover_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Responsive diorama positioning for any screen aspect ratio or scale
	_align_diorama_to_screen()
	if not get_viewport().size_changed.is_connected(_align_diorama_to_screen):
		get_viewport().size_changed.connect(_align_diorama_to_screen)

	# Cache base transform positions
	diorama_base_pos = diorama.position
	pad_base_pos = lily_pad.position
	pad_shadow_base_pos = pad_shadow.position
	frog_base_pos = frog.position
	frog_base_scale = frog.scale
	fly_base_pos = fly.position
	title_base_pos = title_box.position

	# Initialize background layers for parallax overscan
	for layer in bg_layers:
		if layer:
			layer.pivot_offset = Vector2(960, 540)
			layer.scale = Vector2(1.08, 1.08)
			layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Cache button base X positions
	for btn in [play_btn, settings_btn, quit_btn]:
		if btn:
			btn_base_x[btn] = btn.position.x

	# Hook up button hover & click interactions
	_setup_nav_button(play_btn, play_pip)
	_setup_nav_button(settings_btn, settings_pip)
	_setup_nav_button(quit_btn, quit_pip)

	# Settings back button hover effect
	settings_back_btn.mouse_entered.connect(func():
		hover_sfx.pitch_scale = 0.95
		hover_sfx.play()
	)

	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Hook up modal events
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	if is_instance_valid(language_btn):
		language_btn.pressed.connect(_on_language_pressed)
		language_btn.mouse_entered.connect(func():
			hover_sfx.pitch_scale = 1.05
			hover_sfx.play()
		)
	if is_instance_valid(leaderboard_opt_out_btn):
		leaderboard_opt_out_btn.pressed.connect(_on_leaderboard_opt_out_pressed)
		leaderboard_opt_out_btn.mouse_entered.connect(func():
			hover_sfx.pitch_scale = 1.05
			hover_sfx.play()
		)
	if is_instance_valid(delete_data_btn):
		delete_data_btn.pressed.connect(_on_delete_data_pressed)
		delete_data_btn.mouse_entered.connect(func():
			hover_sfx.pitch_scale = 1.05
			hover_sfx.play()
		)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	crt_check.toggled.connect(_on_crt_toggled)

	# Initialize settings state
	_init_settings_values()
	_init_play_games()

	# Start BGM if not already playing (handled globally by MusicManager if available)
	if bgm_player:
		if has_node("/root/MusicManager"):
			bgm_player.stop()
			bgm_player.stream = null
		elif not bgm_player.playing:
			bgm_player.play()

	# Draw title tongue accent
	_update_title_tongue_accent()

	# Hide modals initially
	settings_modal.visible = false

	# Cloud save loading screen connection
	if SaveManager:
		if SaveManager.is_data_loaded:
			loading_modal.visible = false
		else:
			loading_modal.visible = true
			SaveManager.save_data_ready.connect(_on_save_data_ready)
			SaveManager.save_data_failed.connect(_on_save_data_failed)
	else:
		loading_modal.visible = false

func _on_save_data_ready() -> void:
	if not is_instance_valid(loading_modal) or not loading_modal.visible:
		return
	if loading_status:
		loading_status.text = tr("✓ Save Data Synchronized!")
		loading_status.modulate = Color(0.35, 1.0, 0.7)
	_init_settings_values()
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(loading_modal, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		loading_modal.visible = false
	)

func _on_save_data_failed() -> void:
	if not is_instance_valid(loading_modal) or not loading_modal.visible:
		return
	if loading_status:
		loading_status.text = tr("Continuing with local save")
		loading_status.modulate = Color(1.0, 0.85, 0.3)
	_init_settings_values()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(loading_modal, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		loading_modal.visible = false
	)

func _init_play_games() -> void:
	if not is_instance_valid(play_games_btn):
		return
	
	if OS.get_name() != "Android":
		play_games_btn.text = "DESKTOP"
		play_games_btn.disabled = true
		return
	
	play_games_btn.mouse_entered.connect(func():
		hover_sfx.pitch_scale = 0.95
		hover_sfx.play()
	)
	
	play_games_btn.pressed.connect(func():
		click_sfx.play()
		if GodotPlayGameServices.is_signed_in:
			GodotPlayGameServices.show_achievements()
		else:
			GodotPlayGameServices.sign_in()
	)
	GodotPlayGameServices.user_authenticated.connect(func(authenticated: bool):
		if authenticated:
			play_games_btn.text = tr("PROFILE")
			play_games_label.text = tr("GOOGLE PLAY: SIGNED IN")
		else:
			play_games_btn.text = tr("SIGN IN")
			play_games_label.text = tr("GOOGLE PLAY GAMES")
	)
	
	GodotPlayGameServices.current_player_loaded.connect(func(player: PlayGamesPlayer):
		if player:
			play_games_label.text = "PLAY: %s" % player.display_name
	)
	
	if GodotPlayGameServices.is_signed_in:
		play_games_btn.text = tr("PROFILE")
		play_games_label.text = tr("GOOGLE PLAY: SIGNED IN")

func _init_settings_values() -> void:
	if bgm_player and not has_node("/root/MusicManager"):
		bgm_player.volume_db = 0.0 if GameManager.music_enabled else -80.0

	# Master volume
	volume_slider.value = GameManager.master_volume
	volume_label.text = "%d%%" % int(GameManager.master_volume * 100.0)

	# Fullscreen
	var is_fullscreen := (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = is_fullscreen

	if is_instance_valid(language_btn):
		language_btn.text = GameManager.get_language_display_name()

	_update_opt_out_button_ui()

func _update_opt_out_button_ui() -> void:
	if not is_instance_valid(leaderboard_opt_out_btn):
		return
	var is_opted: bool = LootLockerManager.is_leaderboard_opted_out if has_node("/root/LootLockerManager") else false
	if is_opted:
		leaderboard_opt_out_btn.text = tr("OPTED OUT")
		leaderboard_opt_out_btn.disabled = true
	else:
		leaderboard_opt_out_btn.text = tr("OPT OUT")
		leaderboard_opt_out_btn.disabled = false

func _on_leaderboard_opt_out_pressed() -> void:
	click_sfx.play()
	if has_node("/root/LootLockerManager"):
		LootLockerManager.opt_out_from_leaderboard()
	_update_opt_out_button_ui()

func _on_delete_data_pressed() -> void:
	click_sfx.play()
	OS.shell_open("https://akurainteractive.dpdns.org/delete-account")

func _on_language_pressed() -> void:
	click_sfx.play()
	var new_lang := GameManager.cycle_language()
	if is_instance_valid(language_btn):
		language_btn.text = GameManager.get_language_display_name(new_lang)

	# CRT effect
	#crt_overlay.visible = GameManager.crt_enabled
	#crt_check.button_pressed = GameManager.crt_enabled

func _setup_nav_button(btn: Button, pip: Panel) -> void:
	btn.mouse_entered.connect(_on_button_hover.bind(btn, pip))
	btn.mouse_exited.connect(_on_button_unhover.bind(btn, pip))
	btn.button_up.connect(func():
		if not btn.is_hovered():
			_on_button_unhover(btn, pip)
	)

func _on_button_hover(btn: Button, pip: Panel) -> void:
	if is_snapping:
		return
	active_hover_btn = btn
	hover_sfx.pitch_scale = randf_range(0.96, 1.06)
	hover_sfx.play()

	var base_x: float = btn_base_x.get(btn, 0.0)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:x", base_x + 22.0, 0.2)
	if pip:
		tw.tween_property(pip, "custom_minimum_size", Vector2(22, 22), 0.2)
		tw.tween_property(pip, "modulate", Color(1.0, 0.35, 0.75, 1.0), 0.2)

func _on_button_unhover(btn: Button, pip: Panel) -> void:
	if active_hover_btn == btn:
		active_hover_btn = null

	var base_x: float = btn_base_x.get(btn, 0.0)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:x", base_x, 0.24)
	if pip:
		tw.tween_property(pip, "custom_minimum_size", Vector2(16, 16), 0.24)
		tw.tween_property(pip, "modulate", Color(1.0, 0.45, 0.7, 0.65), 0.24)

func _process(delta: float) -> void:
	elapsed_time += delta

	# 0. 7-Layer Dynamic Parallax & Diorama Integration
	_process_parallax(delta)

	# 1. Pad Bobbing & Water Inertia
	var bob := sin(elapsed_time * 1.8) * 8.0
	var tilt := sin(elapsed_time * 1.2) * 0.035
	lily_pad.position.y = pad_base_pos.y + bob
	lily_pad.rotation = tilt
	pad_shadow.position.y = pad_shadow_base_pos.y + bob * 0.4
	pad_shadow.rotation = tilt

	# Ambient background pads subtle drift
	if ambient_pad_1:
		ambient_pad_1.position.y = 940.0 + sin(elapsed_time * 1.1) * 12.0
	if ambient_pad_2:
		ambient_pad_2.position.y = 840.0 + cos(elapsed_time * 0.9) * 10.0

	# 2. Frog Breathing Squash & Eye Direction
	if not is_snapping:
		var breath := sin(elapsed_time * 2.5) * 0.032
		frog.position.y = frog_base_pos.y + bob + breath * 15.0
		frog.scale = Vector2(frog_base_scale.x * (1.0 + breath), frog_base_scale.y * (1.0 - breath))

		# Look towards hovered button or mouse cursor
		if active_hover_btn:
			var target_look := (active_hover_btn.global_position - frog.global_position).normalized()
			frog.rotation = lerp_angle(frog.rotation, target_look.x * 0.16, 0.12)
		else:
			frog.rotation = lerp_angle(frog.rotation, 0.0, 0.08)

	# 3. Fly Buzzing Figure-8 Motion & Wing Flap
	if not fly_caught:
		var fly_x := sin(elapsed_time * 3.4) * 26.0 + cos(elapsed_time * 1.3) * 10.0
		var fly_y := cos(elapsed_time * 6.2) * 16.0 + sin(elapsed_time * 2.1) * 8.0
		fly.position = fly_base_pos + Vector2(fly_x, fly_y)
		fly.rotation = sin(elapsed_time * 9.0) * 0.1
		# Wing flap vibration
		var flap := 1.0 + sin(elapsed_time * 35.0) * 0.12
		fly.scale = Vector2(1.1 * flap, 1.1 / flap)

	# 4. Reactive Tongue on Menu Button Hover
	if not is_snapping:
		_animate_hover_tongue(delta)

	# 5. Gentle Title Float & Animated Title Tongue Accent
	title_box.position.y = title_base_pos.y + sin(elapsed_time * 1.4) * 5.0
	_update_title_tongue_accent()

	# 6. Loading Spinner Animation
	if is_instance_valid(loading_modal) and loading_modal.visible and is_instance_valid(loading_spinner):
		loading_spinner.rotation += delta * 5.0
		loading_spinner.pivot_offset = loading_spinner.size * 0.5

func _process_parallax(delta: float) -> void:
	var vp_rect := get_viewport_rect()
	var center := vp_rect.size * 0.5
	var mouse_pos := get_viewport().get_mouse_position()

	# Compute normalized mouse direction from screen center (-1.0 to 1.0)
	var mouse_vector := Vector2.ZERO
	if vp_rect.has_point(mouse_pos):
		mouse_vector = (mouse_pos - center) / center
		mouse_vector.x = clampf(mouse_vector.x, -1.0, 1.0)
		mouse_vector.y = clampf(mouse_vector.y, -1.0, 1.0)

	# Natural organic breathing / swamp wind sway (always subtly active)
	var ambient_sway := Vector2(
		sin(elapsed_time * 0.7) * 0.14 + cos(elapsed_time * 0.35) * 0.07,
		cos(elapsed_time * 0.9) * 0.09 + sin(elapsed_time * 0.45) * 0.05
	)

	var target := mouse_vector + ambient_sway
	current_parallax = current_parallax.lerp(target, delta * 3.5)

	# Apply layered depth offsets to background
	for i in range(mini(bg_layers.size(), LAYER_WEIGHTS.size())):
		var layer := bg_layers[i]
		if layer:
			var factor: float = LAYER_WEIGHTS[i]
			layer.position = current_parallax * MAX_PARALLAX_OFFSET * factor

	# Diorama (frog, lilypad, ripples) depth integration (approx layer 3 depth)
	if diorama:
		diorama.position = diorama_base_pos + current_parallax * MAX_PARALLAX_OFFSET * 0.65

func _align_diorama_to_screen() -> void:
	if not is_instance_valid(frog) or not is_instance_valid(lily_pad):
		return
	var vp_size := get_viewport_rect().size
	# Position frog center comfortably at 73% of the viewport width (never clipped on right or left)
	var target_frog_x := clampf(vp_size.x * 0.73, 900.0, 1420.0)
	var delta_x := target_frog_x - 1500.0

	lily_pad.position.x = 1500.0 + delta_x
	pad_shadow.position.x = 1500.0 + delta_x
	frog.position.x = 1500.0 + delta_x
	if is_instance_valid(fly):
		fly.position.x = 1628.0 + delta_x
	if is_instance_valid(ambient_pad_2):
		ambient_pad_2.position.x = clampf(vp_size.x - 140.0, 1200.0, 1780.0)

	pad_base_pos = lily_pad.position
	pad_shadow_base_pos = pad_shadow.position
	frog_base_pos = frog.position
	if is_instance_valid(fly):
		fly_base_pos = fly.position

func _animate_hover_tongue(delta: float) -> void:
	# Snout / mouth position on the frog (between and slightly below eyes)
	var mouth: Vector2 = frog.to_global(Vector2(-4.0, -16.0))

	if active_hover_btn and is_instance_valid(active_hover_btn):
		var btn_rect := active_hover_btn.get_global_rect()
		# Tongue targets the right side of the hovered menu button
		var target_pos := Vector2(btn_rect.end.x - 25.0, btn_rect.position.y + btn_rect.size.y * 0.5)
		last_hover_target = target_pos
		hover_tongue_prog = move_toward(hover_tongue_prog, 1.0, delta * 5.0)
	else:
		hover_tongue_prog = move_toward(hover_tongue_prog, 0.0, delta * 8.0)

	# When not hovering, keep tongue fully retracted inside mouth
	if hover_tongue_prog <= 0.01:
		tongue.clear_points()
		return

	# Beautiful organic Bezier curve stretching from mouth to hovered button
	tongue.clear_points()
	var current_tip := mouth.lerp(last_hover_target, hover_tongue_prog)
	var mid := mouth.lerp(current_tip, 0.5) + Vector2(0.0, -45.0 * sin(hover_tongue_prog * PI) + sin(elapsed_time * 6.5) * 8.0)
	for i in range(16):
		var t := float(i) / 15.0
		var pt := mouth.bezier_interpolate(mid, mid, current_tip, t)
		tongue.add_point(pt)

func _update_title_tongue_accent() -> void:
	if not title_tongue:
		return
	title_tongue.clear_points()

	# Organic undulating wave and playful curl twitch at the tip
	var wave_1 := sin(elapsed_time * 2.2) * 2.5
	var wave_2 := cos(elapsed_time * 2.8) * 3.0
	var curl_wiggle := sin(elapsed_time * 3.4) * 4.5
	var tip_wag := cos(elapsed_time * 4.0) * 3.5

	var pts: Array[Vector2] = [
		Vector2(10, 126),
		Vector2(100, 133 + wave_1 * 0.4),
		Vector2(230, 128 + wave_2 * 0.6),
		Vector2(360, 135 - wave_1 * 0.8),
		Vector2(490, 127 + wave_2 * 1.0),
		Vector2(610, 136 - wave_1 * 1.1),
		Vector2(665, 125 + curl_wiggle * 0.5),
		Vector2(688 + tip_wag * 0.4, 104 - curl_wiggle * 0.7),
		Vector2(680 - tip_wag * 0.5, 86 - curl_wiggle * 0.9),
		Vector2(656 - tip_wag * 0.8, 90 + curl_wiggle * 0.6)
	]
	for i in range(pts.size() - 1):
		var p_start := pts[i]
		var p_end := pts[i + 1]
		for step in range(4):
			var t := float(step) / 4.0
			title_tongue.add_point(p_start.lerp(p_end, t))
	title_tongue.add_point(pts[-1])

# --- Button Actions ---

func _on_play_pressed() -> void:
	if is_snapping:
		return
	is_snapping = true
	_on_button_unhover(play_btn, play_pip)
	play_btn.release_focus()
	play_btn.disabled = true
	settings_btn.disabled = true
	quit_btn.disabled = true
	click_sfx.play()

	# ALWAYS launch into the latest unlocked level!
	GameManager.current_level_index = GameManager.unlocked_level


	active_hover_btn = null
	hover_tongue_prog = 0.0

	# Frog Tongue Snap Sequence!
	var mouth := frog.to_global(Vector2(0, -18.0))
	var target_fly_pos := fly.position

	var seq := create_tween()
	# Phase 1: Rapid tongue strike towards fly (0.12s)
	seq.tween_method(func(prog: float):
		tongue.clear_points()
		var tip := mouth.lerp(target_fly_pos, prog)
		var mid := mouth.lerp(target_fly_pos, 0.5) + Vector2(0, -35.0 * sin(prog * PI))
		for i in range(8):
			var t := float(i) / 7.0
			tongue.add_point(mouth.bezier_interpolate(mid, mid, tip, t))
	, 0.0, 1.0, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Phase 2: Snap sound & latch onto fly!
	seq.tween_callback(func():
		fly_caught = true
		click_sfx.pitch_scale = 1.3
		click_sfx.play()
	)

	# Phase 3: Whip tongue and fly back to mouth (0.14s)
	seq.tween_method(func(prog: float):
		tongue.clear_points()
		var tip := target_fly_pos.lerp(mouth, prog)
		fly.position = tip
		fly.scale = Vector2(1.1, 1.1).lerp(Vector2.ZERO, prog)
		for i in range(8):
			var t := float(i) / 7.0
			tongue.add_point(mouth.lerp(tip, t))
	, 0.0, 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Phase 4: Frog swallows and does a satisfied squash bounce!
	seq.tween_callback(func():
		fly.visible = false
		tongue.clear_points()
	)
	seq.tween_property(frog, "scale", Vector2(frog_base_scale.x * 1.35, frog_base_scale.y * 0.75), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	seq.tween_property(frog, "scale", frog_base_scale, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Audio fade
	if bgm_player and bgm_player.stream:
		var audio_tw := create_tween()
		audio_tw.tween_property(bgm_player, "volume_db", -35.0, 0.35)

	await seq.finished

	# Fade out with existing TransitionLayer if available
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file("res://SCENES/main_home.tscn")

func _on_settings_pressed() -> void:
	click_sfx.play()
	_on_button_unhover(settings_btn, settings_pip)
	settings_btn.release_focus()
	settings_modal.visible = true
	settings_modal.modulate.a = 0.0
	settings_panel.scale = Vector2(0.85, 0.85)
	settings_panel.pivot_offset = settings_panel.size * 0.5

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(settings_modal, "modulate:a", 1.0, 0.22)
	tw.tween_property(settings_panel, "scale", Vector2.ONE, 0.26)

func _on_settings_back_pressed() -> void:
	back_sfx.play()
	_on_button_unhover(settings_btn, settings_pip)
	settings_btn.release_focus()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(settings_modal, "modulate:a", 0.0, 0.18)
	tw.tween_property(settings_panel, "scale", Vector2(0.85, 0.85), 0.18)
	await tw.finished
	settings_modal.visible = false

func _on_volume_changed(val: float) -> void:
	GameManager.set_master_volume(val)
	volume_label.text = "%d%%" % int(val * 100.0)

func _on_fullscreen_toggled(toggled: bool) -> void:
	click_sfx.play()
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_crt_toggled(toggled: bool) -> void:
	click_sfx.play()
	#crt_overlay.visible = toggled
	GameManager.set_crt_enabled(toggled)

func _on_quit_pressed() -> void:
	click_sfx.play()
	_on_button_unhover(quit_btn, quit_pip)
	quit_btn.release_focus()
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0)
