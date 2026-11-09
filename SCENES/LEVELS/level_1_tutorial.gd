extends Node2D

## Mobile Tutorial Hint for Level 1
## Demonstrates:
## 0. Inspect Map Hint: Tap 🔍 to look around (timed / on inspect)
## 1. Touch Gesture: Swipe to stretch tongue
## 2. Touch Gesture: Tap to pull frog
## Self-contained, non-intrusive, and ignores all mouse/touch inputs.

@onready var hand: Sprite2D = $Hand
@onready var label: Label = $Label
@onready var arrow_line: Line2D = $ArrowLine

var player: Frog = null
var current_step: int = 0 # 0 = Inspect intro, 1 = Swipe, 2 = Pull, 3 = Finished
var active_tween: Tween = null
var inspect_intro_timer: float = 0.0
var original_pos: Vector2 = Vector2.ZERO
var has_opened_inspect: bool = false

func _ready() -> void:
	# If player has already beaten Level 1, skip tutorial completely
	if GameManager and GameManager.get_level_stars(0) > 0:
		queue_free()
		return

	# Find player in Level 1
	player = get_parent().find_child("Player", true, false) as Frog
	if not player:
		queue_free()
		return

	original_pos = player.position
	position = original_pos

	_start_inspect_intro()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or current_step == 3:
		return

	# If player touches frog or pulls tongue at any time, skip directly to pull tutorial
	if player.tongue_path.size() > 1 and current_step < 2:
		_transition_to_pull_tutorial()
		return

	# --- Stage 0: Inspect Map Intro ---
	if current_step == 0:
		var crt = player.ui_node
		if crt and crt.get("is_inspecting") == true:
			has_opened_inspect = true
			# Player is currently looking around; hide tutorial elements so view is clear
			hand.modulate.a = 0.0
			arrow_line.modulate.a = 0.0
			label.modulate.a = 0.0
			return
		elif has_opened_inspect:
			# Player exited inspect mode -> proceed to swipe
			_start_swipe_tutorial()
			return

		inspect_intro_timer += delta
		if inspect_intro_timer >= 3.0:
			_start_swipe_tutorial()
		return

	# --- Stage 1: Swipe to Stretch ---
	if current_step == 1:
		if player.tongue_path.size() > 1:
			_transition_to_pull_tutorial()
		return

	# --- Stage 2: Tap to Pull ---
	if current_step == 2:
		if player.is_latching or player.tongue_path.size() <= 1:
			_finish_tutorial()
			return

func _start_inspect_intro() -> void:
	current_step = 0
	inspect_intro_timer = 0.0
	has_opened_inspect = false
	label.text = tr("TAP 🔍 TO INSPECT MAP")
	label.modulate.a = 0.0
	hand.modulate.a = 0.0
	arrow_line.modulate.a = 0.0

	arrow_line.clear_points()
	arrow_line.add_point(Vector2(-30, -30))
	arrow_line.add_point(Vector2(-190, -140))

	_loop_inspect_intro_animation()

func _loop_inspect_intro_animation() -> void:
	if current_step != 0 or not is_instance_valid(player):
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	hand.position = Vector2(-40, -40)
	hand.scale = Vector2(0.85, 0.85)
	hand.modulate.a = 0.0
	arrow_line.modulate.a = 0.0
	label.modulate.a = 0.0

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.95, 0.25)
	active_tween.tween_property(label, "modulate:a", 1.0, 0.25)
	active_tween.tween_property(arrow_line, "modulate:a", 0.75, 0.25)
	active_tween.tween_property(hand, "scale", Vector2(0.72, 0.72), 0.2).set_trans(Tween.TRANS_BACK)

	active_tween.chain().set_parallel(true)
	active_tween.tween_property(hand, "position", Vector2(-160, -120), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	active_tween.chain().set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.0, 0.25)
	active_tween.tween_property(arrow_line, "modulate:a", 0.0, 0.25)

	active_tween.chain().tween_interval(0.35)
	active_tween.chain().tween_callback(_loop_inspect_intro_animation)

func _start_swipe_tutorial() -> void:
	current_step = 1
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	label.text = tr("SWIPE TO STRETCH")
	label.modulate.a = 0.0
	hand.modulate.a = 0.0
	arrow_line.modulate.a = 0.0

	arrow_line.clear_points()
	arrow_line.add_point(Vector2(20, 0))
	arrow_line.add_point(Vector2(220, 0))

	_loop_swipe_animation()

func _loop_swipe_animation() -> void:
	if current_step != 1 or not is_instance_valid(player):
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Start at frog
	hand.position = Vector2(0, 10)
	hand.scale = Vector2(0.85, 0.85)
	hand.modulate.a = 0.0
	arrow_line.modulate.a = 0.0
	label.modulate.a = 0.0

	active_tween = create_tween()

	# 1. Fade in & press down (touch start)
	active_tween.set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.95, 0.2)
	active_tween.tween_property(label, "modulate:a", 1.0, 0.25)
	active_tween.tween_property(arrow_line, "modulate:a", 0.75, 0.25)
	active_tween.tween_property(hand, "scale", Vector2(0.72, 0.72), 0.2).set_trans(Tween.TRANS_BACK)

	# 2. Swipe right
	active_tween.chain().set_parallel(true)
	active_tween.tween_property(hand, "position", Vector2(200, 10), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Fade out
	active_tween.chain().set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.0, 0.25)
	active_tween.tween_property(hand, "scale", Vector2(0.85, 0.85), 0.25)
	active_tween.tween_property(arrow_line, "modulate:a", 0.0, 0.25)

	# 4. Small pause and repeat
	active_tween.chain().tween_interval(0.4)
	active_tween.chain().tween_callback(_loop_swipe_animation)

func _transition_to_pull_tutorial() -> void:
	current_step = 2
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	arrow_line.visible = false

	active_tween = create_tween()
	active_tween.tween_property(hand, "modulate:a", 0.0, 0.15)
	active_tween.tween_property(label, "modulate:a", 0.0, 0.15)
	active_tween.chain().tween_interval(0.8)
	active_tween.chain().tween_callback(_start_pull_animation)

func _start_pull_animation() -> void:
	if current_step != 2 or not is_instance_valid(player) or player.tongue_path.size() <= 1:
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	position = player.position
	hand.position = Vector2(0, -20)
	hand.scale = Vector2(0.85, 0.85)
	label.text = tr("TAP TO PULL")

	active_tween = create_tween()

	active_tween.set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.95, 0.2)
	active_tween.tween_property(label, "modulate:a", 1.0, 0.2)

	active_tween.chain().tween_property(hand, "scale", Vector2(0.68, 0.68), 0.18).set_trans(Tween.TRANS_BACK)
	active_tween.tween_property(hand, "scale", Vector2(0.85, 0.85), 0.18)
	active_tween.tween_interval(0.2)
	active_tween.chain().tween_property(hand, "scale", Vector2(0.68, 0.68), 0.18).set_trans(Tween.TRANS_BACK)
	active_tween.tween_property(hand, "scale", Vector2(0.85, 0.85), 0.18)

	active_tween.chain().tween_interval(0.5)
	active_tween.chain().tween_callback(_start_pull_animation)

func _finish_tutorial() -> void:
	current_step = 3
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(hand, "modulate:a", 0.0, 0.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.2)
	if arrow_line:
		tw.tween_property(arrow_line, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
