extends "res://SCENES/UI/crt.gd"
class_name RoyalInfinityCRT

const EVENT_MENU_SCENE: String = "res://SCENES/seasons/RoyalInfinity.tscn"

func _ready() -> void:
	super._ready()
	update_level_label(0)
	_setup_royal_buttons()

func update_level_label(_idx: int) -> void:
	if level_label:
		level_label.text = "⚜ ROYAL INFINITY ⚜"
		level_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
		level_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.02))
		level_label.add_theme_constant_override("outline_size", 8)

func _setup_royal_buttons() -> void:
	# 1. Top HUD restart button
	if restart_btn:
		for conn in restart_btn.pressed.get_connections():
			restart_btn.pressed.disconnect(conn.callable)
		restart_btn.pressed.connect(func():
			if not is_paused:
				GameManager.restart_level()
		)

	# 2. Win Modal buttons
	if is_instance_valid(replay_btn):
		for conn in replay_btn.pressed.get_connections():
			replay_btn.pressed.disconnect(conn.callable)
		replay_btn.pressed.connect(func():
			GameManager.restart_level()
		)

	if is_instance_valid(levels_btn):
		for conn in levels_btn.pressed.get_connections():
			levels_btn.pressed.disconnect(conn.callable)
		levels_btn.pressed.connect(return_to_event_menu)

	if is_instance_valid(next_btn):
		next_btn.text = tr("MENU ➔")
		for conn in next_btn.pressed.get_connections():
			next_btn.pressed.disconnect(conn.callable)
		next_btn.pressed.connect(return_to_event_menu)

	# 3. Pause Modal buttons
	if is_instance_valid(pause_restart_btn):
		for conn in pause_restart_btn.pressed.get_connections():
			pause_restart_btn.pressed.disconnect(conn.callable)
		pause_restart_btn.pressed.connect(func():
			toggle_pause(false)
			GameManager.restart_level()
		)

	if is_instance_valid(pause_levels_btn):
		pause_levels_btn.text = "☰ EVENT"
		for conn in pause_levels_btn.pressed.get_connections():
			pause_levels_btn.pressed.disconnect(conn.callable)
		pause_levels_btn.pressed.connect(func():
			toggle_pause(false)
			return_to_event_menu()
		)

	if is_instance_valid(pause_home_btn):
		pause_home_btn.text = "🏠 MENU"
		for conn in pause_home_btn.pressed.get_connections():
			pause_home_btn.pressed.disconnect(conn.callable)
		pause_home_btn.pressed.connect(func():
			toggle_pause(false)
			return_to_event_menu()
		)

func show_win_modal(stars: int, pulls_remaining: int) -> void:
	if not win_modal:
		return

	is_win_active = true
	win_modal.visible = true
	win_modal.modulate.a = 0.0
	var panel: PanelContainer = win_panel if win_panel else win_modal.get_node_or_null("CenterContainer/PanelContainer")
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.pivot_offset = panel.size * 0.5

	# Royal performance praise
	if stats_label:
		var performance_note := tr("⚜ ROYAL VICTORY! ⚜")
		if stars == 3:
			performance_note = tr("★ ROYAL SOVEREIGN CLEAR! ★")
		elif stars == 2:
			performance_note = tr("★ IMPERIAL MASTER! ★")
		stats_label.text = "%s\n%s: %d" % [performance_note, tr("Pulls Left"), pulls_remaining]

	if next_btn:
		next_btn.text = tr("MENU ➔")

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
		if i < star_nodes.size() and star_nodes[i]:
			var s: Label = star_nodes[i]
			var s_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			s_tw.tween_property(s, "scale", Vector2(1.3, 1.3), 0.15)
			s_tw.parallel().tween_property(s, "modulate", gold_color, 0.12)
			s_tw.tween_property(s, "scale", Vector2.ONE, 0.1)
			_play_sfx(CLICK_SOUND, 1.0 + i * 0.18)
			await get_tree().create_timer(0.22).timeout

func return_to_event_menu() -> void:
	if GameManager and GameManager.custom_restart_handler.get_object() == get_parent():
		GameManager.custom_restart_handler = Callable()

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file(EVENT_MENU_SCENE)

	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()
