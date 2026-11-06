extends CanvasLayer

@export var player: Frog

# Sounds
const CLICK_SOUND = preload("res://AUDIO/ui_click.wav")
const HOVER_SOUND = preload("res://AUDIO/ui_hover.wav")
var _sfx_player: AudioStreamPlayer

# Top HUD elements
@onready var pulls_badge: Control = $UI.get_node_or_null("PullsBadge")
@onready var pulls_label: RichTextLabel = $UI.get_node_or_null("PullsBadge/PULLS_LEFT") if $UI.get_node_or_null("PullsBadge/PULLS_LEFT") else $UI.get_node_or_null("PULLS_LEFT")
@onready var flies_badge: Control = $UI.get_node_or_null("FliesBadge")
@onready var bugs_label: RichTextLabel = $UI.get_node_or_null("FliesBadge/FLIES_LEFT") if $UI.get_node_or_null("FliesBadge/FLIES_LEFT") else $UI.get_node_or_null("FLIES_LEFT")
@onready var level_badge: Control = $UI.get_node_or_null("TopLeftBar/LevelBadge")
@onready var level_label: Label = $UI.get_node_or_null("TopLeftBar/LevelBadge/LevelLabel")
@onready var restart_btn: Button = $UI.get_node_or_null("TopLeftBar/RestartBtn")
@onready var menu_btn: Button = $UI.get_node_or_null("TopLeftBar/MenuBtn")
@onready var big_pull_btn: Button = $UI.get_node_or_null("BigPullBtn")

# Win modal elements
@onready var win_modal: Control = $UI.get_node_or_null("WinModal")
@onready var win_panel: PanelContainer = $UI.get_node_or_null("WinModal/CenterContainer/PanelContainer")
@onready var win_title: Label = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/WinTitle", "CenterContainer/PanelContainer/VBoxContainer/WinTitle"])
@onready var star_1: Label = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsRow/Star1", "CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star1"])
@onready var star_2: Label = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsRow/Star2", "CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star2"])
@onready var star_3: Label = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsRow/Star3", "CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star3"])
@onready var stats_label: Label = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsLabel", "CenterContainer/PanelContainer/VBoxContainer/StatsLabel"])
@onready var replay_btn: Button = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ReplayBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ReplayBtn"])
@onready var levels_btn: Button = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/LevelsBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/LevelsBtn"])
@onready var next_btn: Button = _resolve_node("UI/WinModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/NextBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/NextBtn"])

# Pause modal elements
@onready var pause_modal: Control = $UI.get_node_or_null("PauseModal")
@onready var pause_panel: PanelContainer = $UI.get_node_or_null("PauseModal/CenterContainer/PanelContainer")
@onready var music_toggle_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsBox/MusicToggleBtn", "CenterContainer/PanelContainer/VBoxContainer/SettingsBox/MusicToggleBtn"])
@onready var sfx_toggle_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsBox/SFXToggleBtn", "CenterContainer/PanelContainer/VBoxContainer/SettingsBox/SFXToggleBtn"])
@onready var haptics_toggle_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsBox/HapticsToggleBtn", "CenterContainer/PanelContainer/VBoxContainer/SettingsBox/HapticsToggleBtn"])
@onready var resume_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ResumeBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ResumeBtn"])
@onready var pause_restart_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseRestartBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseRestartBtn"])
@onready var pause_levels_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseLevelsBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseLevelsBtn"])
@onready var pause_home_btn: Button = _resolve_node("UI/PauseModal", ["CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseHomeBtn", "CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ButtonsRow2/PauseHomeBtn"])

@onready var crt_rect: ColorRect = $ColorRect

var shake_timer := 0.0
var base_pulls_pos: Vector2
var is_win_active := false
var is_paused := false

# Final level congratulation modal state
var congrat_modal: Control = null
var congrat_confetti_particles: Array[Dictionary] = []
var congrat_elapsed: float = 0.0

func _resolve_node(base_path: String, relative_paths: Array[String]) -> Node:
	var base := get_node_or_null(base_path)
	if not base:
		return null
	for rel in relative_paths:
		var n := base.get_node_or_null(rel)
		if n:
			return n
	return null

func _ready() -> void:
	# Audio setup
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	# Store initial badge position for shake effects
	var shake_target: Control = pulls_badge if pulls_badge else pulls_label
	if shake_target:
		base_pulls_pos = shake_target.position

	if player:
		_bind_player(player)

	# Listen for level and settings changes
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.settings_changed.connect(_update_settings_ui)
	update_level_label(GameManager.current_level_index)
	_update_settings_ui()

	# Hook up HUD buttons
	if restart_btn:
		_attach_btn_feedback(restart_btn)
		restart_btn.pressed.connect(func():
			if not is_win_active and not is_paused:
				GameManager.restart_level()
		)
	if menu_btn:
		_attach_btn_feedback(menu_btn)
		menu_btn.pressed.connect(func():
			if not is_win_active:
				toggle_pause()
		)
	if big_pull_btn:
		_attach_btn_feedback(big_pull_btn, 1.05, 0.92)
		big_pull_btn.pressed.connect(func():
			if player and not is_win_active and not is_paused:
				player.pull_frog()
		)

	# Hook up Win Modal buttons
	if replay_btn:
		_attach_btn_feedback(replay_btn)
		replay_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.restart_level()
		)
	if levels_btn:
		_attach_btn_feedback(levels_btn)
		levels_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.return_to_menu()
		)
	if next_btn:
		_attach_btn_feedback(next_btn, 1.05, 0.94)
		next_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.next_level()
		)

	# Hook up Pause Modal buttons
	if resume_btn:
		_attach_btn_feedback(resume_btn, 1.04, 0.95)
		resume_btn.pressed.connect(func():
			toggle_pause(false)
		)
	if pause_restart_btn:
		_attach_btn_feedback(pause_restart_btn)
		pause_restart_btn.pressed.connect(func():
			toggle_pause(false)
			GameManager.restart_level()
		)
	if pause_levels_btn:
		_attach_btn_feedback(pause_levels_btn)
		pause_levels_btn.pressed.connect(func():
			toggle_pause(false)
			GameManager.return_to_menu()
		)
	if pause_home_btn:
		_attach_btn_feedback(pause_home_btn)
		pause_home_btn.pressed.connect(func():
			toggle_pause(false)
			GameManager.return_to_title()
		)

	if music_toggle_btn:
		_attach_btn_feedback(music_toggle_btn)
		music_toggle_btn.pressed.connect(func():
			GameManager.set_music_enabled(!GameManager.music_enabled)
		)
	if sfx_toggle_btn:
		_attach_btn_feedback(sfx_toggle_btn)
		sfx_toggle_btn.pressed.connect(func():
			GameManager.set_sfx_enabled(!GameManager.sfx_enabled)
		)
	if haptics_toggle_btn:
		_attach_btn_feedback(haptics_toggle_btn)
		haptics_toggle_btn.pressed.connect(func():
			GameManager.set_haptics_enabled(!GameManager.haptics_enabled)
		)

	# Initially hide modals
	if win_modal:
		win_modal.visible = false
	if pause_modal:
		pause_modal.visible = false

	_update_settings_ui()

func _attach_btn_feedback(btn: Button, hover_scale: float = 1.06, press_scale: float = 0.94) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(func():
		_play_sfx(HOVER_SOUND, 0.85)
		var tw := btn.create_tween()
		btn.pivot_offset = btn.size * 0.5
		tw.tween_property(btn, "scale", Vector2(hover_scale, hover_scale), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		btn.pivot_offset = btn.size * 0.5
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		_play_sfx(CLICK_SOUND, 1.0)
		var tw := btn.create_tween()
		btn.pivot_offset = btn.size * 0.5
		tw.tween_property(btn, "scale", Vector2(press_scale, press_scale), 0.06)
	)
	btn.button_up.connect(func():
		var tw := btn.create_tween()
		btn.pivot_offset = btn.size * 0.5
		tw.tween_property(btn, "scale", Vector2(hover_scale, hover_scale) if btn.is_hovered() else Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK)
	)

func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not GameManager.sfx_enabled or not _sfx_player:
		return
	_sfx_player.stream = stream
	_sfx_player.pitch_scale = pitch
	_sfx_player.play()

func toggle_pause(paused: Variant = null) -> void:
	if paused == null:
		is_paused = !is_paused
	else:
		is_paused = bool(paused)
		
	if pause_modal:
		pause_modal.visible = is_paused
		if is_paused:
			_update_settings_ui()
			var panel = pause_panel if pause_panel else pause_modal.get_node_or_null("CenterContainer/PanelContainer")
			if panel:
				panel.scale = Vector2(0.85, 0.85)
				panel.pivot_offset = panel.size * 0.5
				var tw := create_tween()
				tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_settings_ui() -> void:
	if crt_rect:
		crt_rect.visible = GameManager.crt_enabled
	if music_toggle_btn:
		music_toggle_btn.text = "🎵 MUSIC: " + ("ON" if GameManager.music_enabled else "OFF")
	if sfx_toggle_btn:
		sfx_toggle_btn.text = "🔊 SFX: " + ("ON" if GameManager.sfx_enabled else "OFF")
	if haptics_toggle_btn:
		haptics_toggle_btn.text = "📳 VIBRATION: " + ("ON" if GameManager.haptics_enabled else "OFF")

func setup_player(p: Frog) -> void:
	player = p
	player.ui_node = self
	is_win_active = false
	is_paused = false
	if win_modal:
		win_modal.visible = false
	if pause_modal:
		pause_modal.visible = false
	if is_instance_valid(congrat_modal):
		congrat_modal.visible = false
	congrat_confetti_particles.clear()
	update_level_label(GameManager.current_level_index)
	_bind_player(player)

func _on_level_changed(new_index: int) -> void:
	is_win_active = false
	is_paused = false
	if win_modal:
		win_modal.visible = false
	if pause_modal:
		pause_modal.visible = false
	if is_instance_valid(congrat_modal):
		congrat_modal.visible = false
	congrat_confetti_particles.clear()
	update_level_label(new_index)

func update_level_label(idx: int) -> void:
	if level_label:
		level_label.text = "LEVEL %d" % (idx + 1)

func _bind_player(p: Frog) -> void:
	if not p.player_pulled.is_connected(_on_player_pulled):
		p.player_pulled.connect(_on_player_pulled)

func _process(delta: float) -> void:
	if not player:
		return
		
	# --- Pulls Label Styling ---
	if pulls_label:
		var color_tag := "[color=#ffffff]"
		if player.remaining_pulls == 1:
			color_tag = "[color=#ff9500]"
		elif player.remaining_pulls <= 0:
			color_tag = "[color=#ff4d4d]"
			
		pulls_label.text = "[center] PULLS: " + color_tag + str(player.remaining_pulls) + "[/color][/center]"
		
		var shake_target: Control = pulls_badge if pulls_badge else pulls_label
		if shake_target:
			if base_pulls_pos == Vector2.ZERO:
				base_pulls_pos = shake_target.position
			if shake_timer > 0.0:
				shake_timer -= delta
				shake_target.position.x = base_pulls_pos.x + sin(Time.get_ticks_msec() * 0.1) * 6.0
			else:
				shake_target.position = base_pulls_pos

	# --- Bugs Label Styling ---
	if bugs_label:
		var bug_color := "[color=#ffd23f]"
		if player.collected_bugs < player.required_bugs:
			bug_color = "[color=#ffb703]"
		else:
			bug_color = "[color=#9ef01a]"
			
		bugs_label.text = "[center] FLIES: " + bug_color + str(player.collected_bugs) + "/" + str(player.required_bugs) + "[/color][/center]"

	# --- Pull Button Active State / Juice ---
	if big_pull_btn:
		var can_pull := player.tongue_path.size() > 1 and not player.is_latching and not player.is_dead and not is_paused
		if can_pull:
			var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.04
			big_pull_btn.scale = Vector2(pulse, pulse)
			big_pull_btn.pivot_offset = big_pull_btn.size * 0.5
		elif not big_pull_btn.is_hovered():
			big_pull_btn.scale = Vector2.ONE

	# --- Final Level Confetti Celebration Animation ---
	if is_instance_valid(congrat_modal) and congrat_modal.visible and not congrat_confetti_particles.is_empty():
		congrat_elapsed += delta
		for p in congrat_confetti_particles:
			var node: ColorRect = p.node
			if is_instance_valid(node):
				node.position.y += p.speed_y * delta
				node.position.x = p.base_x + sin(congrat_elapsed * p.wobble + p.base_x * 0.01) * 24.0
				node.rotation += p.rot_speed * delta
				if node.position.y > 1150.0:
					node.position.y = randf_range(-140.0, -20.0)
					node.position.x = randf_range(50.0, 1870.0)
					p.base_x = node.position.x

func trigger_out_of_pulls_effect() -> void:
	shake_timer = 0.35

func _on_player_pulled() -> void:
	var pop_target: Control = pulls_badge if pulls_badge else pulls_label
	if pop_target:
		var tween := create_tween()
		pop_target.pivot_offset = pop_target.size * 0.5
		tween.tween_property(pop_target, "scale", Vector2(1.18, 1.18), 0.06)
		tween.tween_property(pop_target, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
	if big_pull_btn:
		var btn_tw := create_tween()
		big_pull_btn.pivot_offset = big_pull_btn.size * 0.5
		btn_tw.tween_property(big_pull_btn, "scale", Vector2(0.88, 0.88), 0.05)
		btn_tw.tween_property(big_pull_btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)

func show_win_modal(stars: int, pulls_remaining: int) -> void:
	# Check if this is the game's finale / last level
	var is_final: bool = false
	if GameManager:
		if GameManager.has_method("is_final_level"):
			is_final = GameManager.is_final_level()
		else:
			is_final = (GameManager.current_level_index + 1 >= GameManager.levels.size())

	if is_final:
		_show_congratulation_modal(stars, pulls_remaining)
		return

	if not win_modal:
		GameManager.next_level()
		return
		
	is_win_active = true
	win_modal.visible = true
	win_modal.modulate.a = 0.0
	var panel: PanelContainer = win_panel if win_panel else win_modal.get_node_or_null("CenterContainer/PanelContainer")
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.pivot_offset = panel.size * 0.5

	# Update stats text
	if stats_label:
		var performance_note := "Great Job!"
		if stars == 3:
			performance_note = "★ PERFECT CLEAR! ★"
		elif stars == 2:
			performance_note = "Nice Stretch!"
		stats_label.text = "%s\nPulls Left: %d" % [performance_note, pulls_remaining]

	# Update Next button text on normal levels
	if next_btn:
		next_btn.text = "NEXT ➔"

	# Prepare stars (initially dim)
	var star_nodes: Array[Label] = [star_1, star_2, star_3]
	var dim_color := Color(0.25, 0.2, 0.15, 0.4)
	var gold_color := Color(1.0, 0.88, 0.2, 1.0)
	
	for s_label: Label in star_nodes:
		if s_label:
			s_label.modulate = dim_color
			s_label.scale = Vector2(0.5, 0.5)
			s_label.pivot_offset = s_label.size * 0.5

	# Animate Modal Panel in
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(win_modal, "modulate:a", 1.0, 0.25)
	if panel:
		tw.tween_property(panel, "scale", Vector2.ONE, 0.3)

	# Sequentially pop stars
	await get_tree().create_timer(0.3).timeout
	for i in range(stars):
		var s: Label = star_nodes[i]
		if s:
			s.modulate = gold_color
			_play_sfx(CLICK_SOUND, 1.2 + i * 0.2)
			var star_tw := create_tween()
			star_tw.tween_property(s, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			star_tw.tween_property(s, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			if OS.get_name() == "Android" or OS.get_name() == "iOS":
				Input.vibrate_handheld(25)
			await get_tree().create_timer(0.2).timeout

func _show_congratulation_modal(stars: int, pulls_remaining: int) -> void:
	is_win_active = true
	
	# If already exists, clear it
	if is_instance_valid(congrat_modal):
		congrat_modal.queue_free()

	congrat_modal = Control.new()
	congrat_modal.name = "CongratulationModal"
	congrat_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	congrat_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(congrat_modal)

	# 1. Darkened Festive Cinematic Dimmer
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.04, 0.06, 0.85)
	congrat_modal.add_child(dimmer)

	# 2. Confetti Container for celebratory fireworks & falling confetti
	var confetti_box := Control.new()
	confetti_box.name = "ConfettiBox"
	confetti_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	confetti_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	congrat_modal.add_child(confetti_box)

	# Spawn celebratory confetti pieces across the top of screen
	congrat_confetti_particles.clear()
	var confetti_colors: Array[Color] = [
		Color(1.0, 0.85, 0.2),  # Gold
		Color(1.0, 0.35, 0.7),  # Radiant Pink
		Color(0.2, 0.9, 0.75),  # Turquoise
		Color(0.4, 1.0, 0.4),   # Emerald
		Color(1.0, 0.55, 0.15), # Amber
		Color(0.7, 0.45, 1.0)   # Orchid
	]
	for k in range(50):
		var p_rect := ColorRect.new()
		var p_size := Vector2(randf_range(12.0, 20.0), randf_range(8.0, 16.0))
		p_rect.size = p_size
		p_rect.color = confetti_colors[k % confetti_colors.size()]
		p_rect.pivot_offset = p_size * 0.5
		p_rect.position = Vector2(randf_range(50.0, 1870.0), randf_range(-400.0, 250.0))
		confetti_box.add_child(p_rect)
		congrat_confetti_particles.append({
			"node": p_rect,
			"speed_y": randf_range(140.0, 280.0),
			"speed_x": randf_range(-40.0, 40.0),
			"rot_speed": randf_range(-4.0, 4.0),
			"wobble": randf_range(2.0, 5.0),
			"base_x": p_rect.position.x
		})

	# 3. Center Modal Container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	congrat_modal.add_child(center)

	var panel_outer := PanelContainer.new()
	panel_outer.custom_minimum_size = Vector2(740, 580)
	var bg_tex := load("res://ASSETS/UI/panels/bg.png") as Texture2D
	if bg_tex:
		var st_outer := StyleBoxTexture.new()
		st_outer.texture = bg_tex
		st_outer.expand_margin_left = 30.0
		st_outer.expand_margin_top = 40.0
		st_outer.expand_margin_right = 40.0
		st_outer.expand_margin_bottom = 30.0
		panel_outer.add_theme_stylebox_override("panel", st_outer)
	center.add_child(panel_outer)

	var table_tex := load("res://ASSETS/UI/panels/table.png") as Texture2D
	if table_tex:
		var inner_panel := Panel.new()
		inner_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_inner := StyleBoxTexture.new()
		st_inner.texture = table_tex
		st_inner.expand_margin_left = 12.0
		st_inner.expand_margin_top = 22.0
		st_inner.expand_margin_right = 22.0
		st_inner.expand_margin_bottom = 22.0
		inner_panel.add_theme_stylebox_override("panel", st_inner)
		panel_outer.add_child(inner_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel_outer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var font_gorditas := load("res://ASSETS/FONT/Gorditas-Bold.ttf") as Font

	# Trophy & Celebration Header
	var trophy_label := Label.new()
	trophy_label.text = "🏆   🏆   🏆"
	trophy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy_label.add_theme_font_size_override("font_size", 44)
	vbox.add_child(trophy_label)

	var title_lbl := Label.new()
	title_lbl.text = "CONGRATULATIONS!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_gorditas:
		title_lbl.add_theme_font_override("font", font_gorditas)
	title_lbl.add_theme_font_size_override("font_size", 46)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.28, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 10)
	vbox.add_child(title_lbl)

	var sub_title := Label.new()
	sub_title.text = "★ YOU COMPLETED THE GAME! ★"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_gorditas:
		sub_title.add_theme_font_override("font", font_gorditas)
	sub_title.add_theme_font_size_override("font_size", 22)
	sub_title.add_theme_color_override("font_color", Color(0.35, 1.0, 0.7, 1.0))
	sub_title.add_theme_color_override("font_outline_color", Color(0.1, 0.25, 0.15, 1.0))
	sub_title.add_theme_constant_override("outline_size", 6)
	vbox.add_child(sub_title)

	# Stars Row
	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 24)
	vbox.add_child(stars_row)

	var star_nodes: Array[Label] = []
	for s_idx in range(3):
		var sl := Label.new()
		sl.text = "★"
		if font_gorditas:
			sl.add_theme_font_override("font", font_gorditas)
		sl.add_theme_font_size_override("font_size", 58)
		sl.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 1.0))
		sl.add_theme_constant_override("outline_size", 8)
		sl.modulate = Color(0.25, 0.2, 0.15, 0.4)
		sl.scale = Vector2(0.5, 0.5)
		sl.pivot_offset = Vector2(30, 30)
		stars_row.add_child(sl)
		star_nodes.append(sl)

	# Praise Text
	var total_levels := GameManager.levels.size() if GameManager else 45
	var desc_lbl := Label.new()
	desc_lbl.text = "Froggy conquered all %d levels across every World\nand returned home as the Ultimate Champion!\nPulls Left: %d" % [total_levels, pulls_remaining]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_gorditas:
		desc_lbl.add_theme_font_override("font", font_gorditas)
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85, 1.0))
	desc_lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 1.0))
	desc_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(desc_lbl)

	# Action Buttons Row
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	vbox.add_child(actions)

	var wood_tex := load("res://ASSETS/UI/panels/wood_badge.svg") as Texture2D
	var btn_green_tex := load("res://ASSETS/UI/buttons/btn.png") as Texture2D

	var replay_finale_btn := Button.new()
	replay_finale_btn.text = "↺ REPLAY"
	replay_finale_btn.custom_minimum_size = Vector2(190, 60)
	if font_gorditas:
		replay_finale_btn.add_theme_font_override("font", font_gorditas)
	replay_finale_btn.add_theme_font_size_override("font_size", 20)
	replay_finale_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1.0))
	replay_finale_btn.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.02, 1.0))
	replay_finale_btn.add_theme_constant_override("outline_size", 5)
	if wood_tex:
		var st_btn := StyleBoxTexture.new()
		st_btn.texture = wood_tex
		st_btn.texture_margin_left = 18.0
		st_btn.texture_margin_right = 18.0
		st_btn.texture_margin_top = 10.0
		st_btn.texture_margin_bottom = 10.0
		replay_finale_btn.add_theme_stylebox_override("normal", st_btn)
		replay_finale_btn.add_theme_stylebox_override("hover", st_btn)
		replay_finale_btn.add_theme_stylebox_override("pressed", st_btn)
	_attach_btn_feedback(replay_finale_btn)
	replay_finale_btn.pressed.connect(func():
		congrat_modal.visible = false
		is_win_active = false
		GameManager.restart_level()
	)
	actions.add_child(replay_finale_btn)

	var home_btn := Button.new()
	home_btn.text = "🏠 HOME MAP"
	home_btn.custom_minimum_size = Vector2(210, 60)
	if font_gorditas:
		home_btn.add_theme_font_override("font", font_gorditas)
	home_btn.add_theme_font_size_override("font_size", 21)
	home_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9, 1.0))
	home_btn.add_theme_color_override("font_outline_color", Color(0.12, 0.35, 0.05, 1.0))
	home_btn.add_theme_constant_override("outline_size", 7)
	if btn_green_tex:
		var st_grn := StyleBoxTexture.new()
		st_grn.texture = btn_green_tex
		st_grn.texture_margin_left = 65.0
		st_grn.texture_margin_right = 65.0
		st_grn.texture_margin_top = 18.0
		st_grn.texture_margin_bottom = 22.0
		home_btn.add_theme_stylebox_override("normal", st_grn)
		home_btn.add_theme_stylebox_override("hover", st_grn)
		home_btn.add_theme_stylebox_override("pressed", st_grn)
	_attach_btn_feedback(home_btn, 1.06, 0.94)
	home_btn.pressed.connect(func():
		congrat_modal.visible = false
		is_win_active = false
		GameManager.return_to_menu()
	)
	actions.add_child(home_btn)

	# Animate Modal Panel Pop-in
	congrat_modal.modulate.a = 0.0
	panel_outer.scale = Vector2(0.75, 0.75)
	panel_outer.pivot_offset = panel_outer.custom_minimum_size * 0.5
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(congrat_modal, "modulate:a", 1.0, 0.35)
	tw.tween_property(panel_outer, "scale", Vector2.ONE, 0.4)

	# Sequentially pop stars with sound
	await get_tree().create_timer(0.35).timeout
	for i in range(stars):
		var sl: Label = star_nodes[i]
		if is_instance_valid(sl):
			sl.modulate = Color(1.0, 0.88, 0.2, 1.0)
			_play_sfx(CLICK_SOUND, 1.1 + i * 0.25)
			var stw := create_tween()
			stw.tween_property(sl, "scale", Vector2(1.5, 1.5), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			stw.tween_property(sl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			if OS.get_name() == "Android" or OS.get_name() == "iOS":
				Input.vibrate_handheld(35)
			await get_tree().create_timer(0.25).timeout
