extends Control

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var refresh_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HeaderRow/RefreshButton
@onready var back_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LeaderboardBackButton
@onready var scroll_container: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/LeaderboardScroll
@onready var leaderboard_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/LeaderboardScroll/LeaderboardList
@onready var loading_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/StatusContainer/LoadingLabel
@onready var my_rank_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MyStandingBar/MarginContainer/HBoxContainer/MyRankLabel
@onready var my_score_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MyStandingBar/MarginContainer/HBoxContainer/MyScoreLabel
@onready var click_sfx: AudioStreamPlayer = $ClickSFX
@onready var back_sfx: AudioStreamPlayer = $BackSFX

const FONT_GORDITAS := preload("res://ASSETS/FONT/Gorditas-Bold.ttf")

signal closed

# Mobile Touch & Momentum Scrolling
var is_dragging_scroll: bool = false
var scroll_pos_f: float = 0.0
var scroll_velocity_y: float = 0.0
var active_touch_id: int = -1
var velocity_samples: Array[float] = []
const VELOCITY_SAMPLES_MAX: int = 5
const SCROLL_FRICTION: float = 7.5

func _ready() -> void:
	visible = false
	back_btn.pressed.connect(close)
	refresh_btn.pressed.connect(func(): load_leaderboard(true))
	_hook_btn_animations(back_btn)
	_hook_btn_animations(refresh_btn)

	leaderboard_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dimmer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close()
	)

func open() -> void:
	visible = true
	modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	panel.pivot_offset = panel.size * 0.5

	is_dragging_scroll = false
	scroll_velocity_y = 0.0
	active_touch_id = -1
	velocity_samples.clear()
	scroll_pos_f = 0.0
	if is_instance_valid(scroll_container):
		scroll_container.scroll_vertical = 0

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.26)

	load_leaderboard(false)

func close() -> void:
	is_dragging_scroll = false
	scroll_velocity_y = 0.0
	if back_sfx:
		back_sfx.play()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.18)
	await tw.finished
	visible = false
	closed.emit()

func load_leaderboard(is_refresh: bool = false) -> void:
	if is_refresh and click_sfx:
		click_sfx.play()

	# Clear previous list
	for child in leaderboard_list.get_children():
		child.queue_free()

	loading_label.text = tr("Loading top frogs...")
	loading_label.visible = true

	# Calculate local star count
	var local_stars: int = 0
	if GameManager.level_stars and not GameManager.level_stars.is_empty():
		local_stars = GameManager.level_stars.values().reduce(func(accum, number): return accum + number, 0)

	var res: Dictionary = await LootLockerManager.get_leaderboard(50)

	if not is_instance_valid(self) or not visible:
		return
		
	if !LootLockerManager.is_authenticated and not GodotPlayGameServices.is_signed_in:
		loading_label.text = tr("Sign in to Google Play Games\nin Settings to view Leaderboards!")
		my_rank_label.text = tr("YOUR RANK: UNRANKED")
		my_score_label.text = "%d ⭐" % local_stars
		return
	elif not res.get("success", false):
		loading_label.text = tr("Could not load leaderboard.\nCheck connection and tap Refresh.")
		loading_label.visible = true
		my_rank_label.text = tr("YOUR RANK: UNRANKED")
		my_score_label.text = "%d ⭐" % local_stars
		return

	var items: Array = res.get("items", [])
	if items.is_empty():
		loading_label.text = tr("No scores submitted yet!\nComplete levels to claim #1!")
		loading_label.visible = true
	else:
		loading_label.visible = false
		for item in items:
			var row = _create_leaderboard_row(item.rank, item.name, item.score, item.is_me)
			leaderboard_list.add_child(row)

	# Update sticky standing bar
	var my_rank: int = res.get("my_rank", 0)
	var my_score: int = res.get("my_score", 0)
	var display_name: String = LootLockerManager.get_effective_player_name()
	if display_name == "":
		display_name = tr("YOU")

	if my_rank > 0:
		my_rank_label.text = "%s: #%d  (%s)" % [tr("YOUR RANK"), my_rank, display_name]
		my_score_label.text = "%d ⭐" % my_score
	else:
		my_rank_label.text = "%s: %s  (%s)" % [tr("YOUR RANK"), tr("UNRANKED"), display_name]
		my_score_label.text = "%d ⭐" % local_stars

func _create_leaderboard_row(rank: int, p_name: String, score: int, is_me: bool) -> Control:
	var panel_row := PanelContainer.new()
	panel_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_row.custom_minimum_size = Vector2(0, 52)
	panel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	if is_me:
		style.bg_color = Color(0.18, 0.45, 0.22, 0.65)
		style.border_color = Color(1.0, 0.88, 0.35, 0.95)
		style.set_border_width_all(2)
	elif rank == 1:
		style.bg_color = Color(0.72, 0.55, 0.12, 0.45)
		style.border_color = Color(1.0, 0.85, 0.25, 0.8)
		style.set_border_width_all(1)
	elif rank == 2:
		style.bg_color = Color(0.55, 0.62, 0.68, 0.35)
		style.border_color = Color(0.85, 0.9, 0.95, 0.6)
		style.set_border_width_all(1)
	elif rank == 3:
		style.bg_color = Color(0.65, 0.42, 0.25, 0.35)
		style.border_color = Color(0.9, 0.65, 0.45, 0.6)
		style.set_border_width_all(1)
	else:
		style.bg_color = Color(0.08, 0.05, 0.03, 0.32)

	panel_row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 16)
	panel_row.add_child(hbox)

	# Rank Label
	var rank_label := Label.new()
	rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_label.custom_minimum_size = Vector2(120, 0)
	rank_label.add_theme_font_override("font", FONT_GORDITAS)
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if rank == 1:
		rank_label.text = "🥇 #1"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.3, 1.0))
	elif rank == 2:
		rank_label.text = "🥈 #2"
		rank_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	elif rank == 3:
		rank_label.text = "🥉 #3"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.55, 1.0))
	else:
		rank_label.text = "#%d" % rank
		rank_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 1.0))

	rank_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	rank_label.add_theme_constant_override("outline_size", 5)
	hbox.add_child(rank_label)

	# Name Label
	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text = p_name + ("  (" + tr("YOU") + ")" if is_me else "")
	name_label.add_theme_font_override("font", FONT_GORDITAS)
	name_label.add_theme_font_size_override("font_size", 20)

	if is_me:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
	else:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88, 1.0))

	name_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 1.0))
	name_label.add_theme_constant_override("outline_size", 5)
	hbox.add_child(name_label)

	# Score Label
	var score_label := Label.new()
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label.custom_minimum_size = Vector2(140, 0)
	score_label.text = "%d ⭐" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_override("font", FONT_GORDITAS)
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
	score_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02, 1.0))
	score_label.add_theme_constant_override("outline_size", 5)
	hbox.add_child(score_label)

	return panel_row

func _hook_btn_animations(btn: Button) -> void:
	if not btn: return
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)

	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(scroll_container):
		return
	if not is_dragging_scroll and abs(scroll_velocity_y) > 2.0:
		scroll_pos_f -= scroll_velocity_y * delta
		var max_s: float = float(_get_max_scroll())
		if scroll_pos_f <= 0.0:
			scroll_pos_f = 0.0
			scroll_velocity_y = 0.0
		elif scroll_pos_f >= max_s:
			scroll_pos_f = max_s
			scroll_velocity_y = 0.0
		scroll_container.scroll_vertical = int(round(scroll_pos_f))
		scroll_velocity_y = lerp(scroll_velocity_y, 0.0, clampf(delta * SCROLL_FRICTION, 0.0, 1.0))

func _input(event: InputEvent) -> void:
	if not visible or not is_instance_valid(scroll_container):
		return

	# Touch events (Mobile / Touchscreen)
	if event is InputEventScreenTouch:
		if event.pressed:
			if scroll_container.get_global_rect().has_point(event.position):
				is_dragging_scroll = true
				active_touch_id = event.index
				scroll_pos_f = float(scroll_container.scroll_vertical)
				scroll_velocity_y = 0.0
				velocity_samples.clear()
				get_viewport().set_input_as_handled()
		else:
			if is_dragging_scroll and (active_touch_id == -1 or event.index == active_touch_id):
				is_dragging_scroll = false
				active_touch_id = -1
				_compute_release_velocity()
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if is_dragging_scroll and (active_touch_id == -1 or event.index == active_touch_id):
			var delta_y: float = event.relative.y
			scroll_pos_f -= delta_y
			_clamp_scroll()
			var dt := maxf(get_process_delta_time(), 0.001)
			_add_velocity_sample(delta_y / dt)
			get_viewport().set_input_as_handled()

	# Mouse events (Desktop / Editor testing)
	elif event is InputEventMouseButton:
		if active_touch_id != -1:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if scroll_container.get_global_rect().has_point(event.position):
					is_dragging_scroll = true
					scroll_pos_f = float(scroll_container.scroll_vertical)
					scroll_velocity_y = 0.0
					velocity_samples.clear()
					get_viewport().set_input_as_handled()
			else:
				if is_dragging_scroll:
					is_dragging_scroll = false
					_compute_release_velocity()
					get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if scroll_container.get_global_rect().has_point(event.position):
				scroll_pos_f -= 50.0
				_clamp_scroll()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if scroll_container.get_global_rect().has_point(event.position):
				scroll_pos_f += 50.0
				_clamp_scroll()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if active_touch_id != -1:
			return
		if is_dragging_scroll:
			var delta_y: float = event.relative.y
			scroll_pos_f -= delta_y
			_clamp_scroll()
			var dt := maxf(get_process_delta_time(), 0.001)
			_add_velocity_sample(delta_y / dt)
			get_viewport().set_input_as_handled()

func _add_velocity_sample(v: float) -> void:
	velocity_samples.append(v)
	if velocity_samples.size() > VELOCITY_SAMPLES_MAX:
		velocity_samples.pop_front()

func _compute_release_velocity() -> void:
	if velocity_samples.is_empty():
		scroll_velocity_y = 0.0
		return
	var sum := 0.0
	for v in velocity_samples:
		sum += v
	var avg := sum / float(velocity_samples.size())
	if abs(velocity_samples.back()) < 30.0:
		scroll_velocity_y = 0.0
	else:
		scroll_velocity_y = avg

func _get_max_scroll() -> int:
	if not is_instance_valid(scroll_container):
		return 0
	var v_bar := scroll_container.get_v_scroll_bar()
	if v_bar and v_bar.max_value > 0:
		return int(maxf(v_bar.max_value - v_bar.page, 0.0))
	if is_instance_valid(leaderboard_list):
		return int(maxf(leaderboard_list.size.y - scroll_container.size.y, 0.0))
	return 0

func _clamp_scroll() -> void:
	if not is_instance_valid(scroll_container):
		return
	var max_s: float = float(_get_max_scroll())
	scroll_pos_f = clampf(scroll_pos_f, 0.0, max_s)
	scroll_container.scroll_vertical = int(round(scroll_pos_f))
