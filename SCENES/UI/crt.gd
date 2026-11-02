extends CanvasLayer

@export var player: Frog

# HUD elements
@onready var pulls_label: RichTextLabel = $UI/PULLS_LEFT
@onready var bugs_label: RichTextLabel = $UI/FLIES_LEFT
@onready var level_label: Label = $UI/TopLeftBar/LevelBadge/LevelLabel
@onready var restart_btn: Button = $UI/TopLeftBar/RestartBtn
@onready var menu_btn: Button = $UI/TopLeftBar/MenuBtn
@onready var big_pull_btn: Button = $UI/BigPullBtn

# Win modal elements
@onready var win_modal: Control = $UI/WinModal
@onready var win_panel: PanelContainer = $UI/WinModal/CenterContainer/PanelContainer
@onready var win_title: Label = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/WinTitle
@onready var star_1: Label = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star1
@onready var star_2: Label = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star2
@onready var star_3: Label = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/StarsRow/Star3
@onready var stats_label: Label = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/StatsLabel
@onready var replay_btn: Button = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/ActionsRow/ReplayBtn
@onready var levels_btn: Button = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/ActionsRow/LevelsBtn
@onready var next_btn: Button = $UI/WinModal/CenterContainer/PanelContainer/VBoxContainer/ActionsRow/NextBtn

var shake_timer := 0.0
var base_position: Vector2
var is_win_active := false

func _ready() -> void:
	if pulls_label:
		base_position = pulls_label.position
	if player:
		_bind_player(player)

	# Update level label and listen for changes
	GameManager.level_changed.connect(_on_level_changed)
	update_level_label(GameManager.current_level_index)

	# Hook up HUD buttons
	if restart_btn:
		restart_btn.pressed.connect(func():
			if not is_win_active:
				GameManager.restart_level()
		)
	if menu_btn:
		menu_btn.pressed.connect(func():
			GameManager.return_to_menu()
		)
	if big_pull_btn:
		big_pull_btn.pressed.connect(func():
			if player and not is_win_active:
				player.pull_frog()
		)

	# Hook up Win Modal buttons
	if replay_btn:
		replay_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.restart_level()
		)
	if levels_btn:
		levels_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.return_to_menu()
		)
	if next_btn:
		next_btn.pressed.connect(func():
			win_modal.visible = false
			is_win_active = false
			GameManager.next_level()
		)

	# Initially hide win modal
	if win_modal:
		win_modal.visible = false

func setup_player(p: Frog) -> void:
	player = p
	player.ui_node = self
	is_win_active = false
	if win_modal:
		win_modal.visible = false
	update_level_label(GameManager.current_level_index)
	_bind_player(player)

func _on_level_changed(new_index: int) -> void:
	is_win_active = false
	if win_modal:
		win_modal.visible = false
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
		var color_tag := "[color=white]"
		if player.remaining_pulls == 1:
			color_tag = "[color=orange]"
		elif player.remaining_pulls <= 0:
			color_tag = "[color=red]"
			
		pulls_label.text = "Pulls: " + color_tag + str(player.remaining_pulls) + "[/color]"
		
		if shake_timer > 0.0:
			shake_timer -= delta
			pulls_label.position.x = base_position.x + sin(Time.get_ticks_msec() * 0.1) * 6.0
		else:
			pulls_label.position = base_position

	# --- Bugs Label Styling ---
	if bugs_label:
		var bug_color := "[color=yellow]"
		if player.collected_bugs < player.required_bugs:
			bug_color = "[color=orange]"
		else:
			bug_color = "[color=green]"
			
		bugs_label.text = "Bugs: " + bug_color + str(player.collected_bugs) + "/" + str(player.required_bugs) + "[/color]"

	# --- Pull Button Active State / Juice ---
	if big_pull_btn:
		var can_pull := player.tongue_path.size() > 1 and not player.is_latching and not player.is_dead
		if can_pull:
			var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.04
			big_pull_btn.scale = Vector2(pulse, pulse)
			big_pull_btn.pivot_offset = big_pull_btn.size * 0.5
		else:
			big_pull_btn.scale = Vector2.ONE


func trigger_out_of_pulls_effect() -> void:
	shake_timer = 0.35

func _on_player_pulled() -> void:
	if pulls_label:
		var tween := create_tween()
		tween.tween_property(pulls_label, "scale", Vector2(1.15, 1.15), 0.05)
		tween.tween_property(pulls_label, "scale", Vector2.ONE, 0.1)
	if big_pull_btn:
		var btn_tw := create_tween()
		btn_tw.tween_property(big_pull_btn, "scale", Vector2(0.9, 0.9), 0.06)
		btn_tw.tween_property(big_pull_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

func show_win_modal(stars: int, pulls_remaining: int) -> void:
	if not win_modal:
		GameManager.next_level()
		return
		
	is_win_active = true
	win_modal.visible = true
	win_modal.modulate.a = 0.0
	win_panel.scale = Vector2(0.8, 0.8)
	win_panel.pivot_offset = win_panel.size * 0.5

	# Update stats text
	if stats_label:
		var performance_note := "Great Job!"
		if stars == 3:
			performance_note = "★ PERFECT CLEAR! ★"
		elif stars == 2:
			performance_note = "Nice Stretch!"
		stats_label.text = "%s\nPulls Left: %d" % [performance_note, pulls_remaining]

	# Update Next button text on final level
	if next_btn:
		if GameManager.current_level_index + 1 >= GameManager.levels.size():
			next_btn.text = "FINISH ➔"
		else:
			next_btn.text = "NEXT ➔"

	# Prepare stars (initially dim)
	var star_nodes: Array[Label] = [star_1, star_2, star_3]
	var dim_color := Color(0.2, 0.3, 0.45, 0.4)
	var gold_color := Color(1.0, 0.88, 0.2, 1.0)
	
	for s_label: Label in star_nodes:
		if s_label:
			s_label.modulate = dim_color
			s_label.scale = Vector2(0.6, 0.6)
			s_label.pivot_offset = s_label.size * 0.5

	# Animate Modal Panel in
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(win_modal, "modulate:a", 1.0, 0.25)
	tw.tween_property(win_panel, "scale", Vector2.ONE, 0.3)

	# Sequentially pop stars
	await get_tree().create_timer(0.28).timeout
	for i in range(stars):
		var s: Label = star_nodes[i]
		if s:
			s.modulate = gold_color
			var star_tw := create_tween()
			star_tw.tween_property(s, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			star_tw.tween_property(s, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			if OS.get_name() == "Android" or OS.get_name() == "iOS":
				Input.vibrate_handheld(25)
			await get_tree().create_timer(0.18).timeout
