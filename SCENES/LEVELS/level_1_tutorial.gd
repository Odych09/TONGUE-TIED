extends Node2D

## Mobile Tutorial Hint for Level 1
## Demonstrates touch gestures: Swipe to stretch tongue, then Tap to pull frog.
## Self-contained, non-intrusive, and ignores all mouse/touch inputs.

@onready var hand: Sprite2D = $Hand
@onready var label: Label = $Label
@onready var arrow_line: Line2D = $ArrowLine

var player: Frog = null
var current_step: int = 0 # 0 = Swipe, 1 = Pull, 2 = Finished
var active_tween: Tween = null
var idle_pull_timer: float = 0.0
var original_pos: Vector2 = Vector2.ZERO

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

	_start_swipe_tutorial()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or current_step == 2:
		return

	# --- Stage 1: Swipe to Stretch ---
	if current_step == 0:
		# If player has stretched their tongue (path > 1) or is currently latching
		if player.tongue_path.size() > 1:
			_transition_to_pull_tutorial()
		return

	# --- Stage 2: Tap to Pull ---
	if current_step == 1:
		# If player pulls the frog or tongue retracts
		if player.is_latching or player.tongue_path.size() <= 1:
			_finish_tutorial()
			return

func _start_swipe_tutorial() -> void:
	current_step = 0
	label.text = tr("SWIPE TO STRETCH")
	label.modulate.a = 0.0
	hand.modulate.a = 0.0
	arrow_line.modulate.a = 0.0
	
	# Setup arrow pointing to the right towards the first bug
	arrow_line.clear_points()
	arrow_line.add_point(Vector2(20, 0))
	arrow_line.add_point(Vector2(220, 0))
	
	_loop_swipe_animation()

func _loop_swipe_animation() -> void:
	if current_step != 0 or not is_instance_valid(player):
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
	current_step = 1
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Hide arrow line
	arrow_line.visible = false

	# Short delay before showing "TAP TO PULL" so player has a chance to do it themselves
	active_tween = create_tween()
	active_tween.tween_property(hand, "modulate:a", 0.0, 0.15)
	active_tween.tween_property(label, "modulate:a", 0.0, 0.15)
	active_tween.chain().tween_interval(0.8)
	active_tween.chain().tween_callback(_start_pull_animation)

func _start_pull_animation() -> void:
	if current_step != 1 or not is_instance_valid(player) or player.tongue_path.size() <= 1:
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	# Update position to current frog position
	position = player.position
	hand.position = Vector2(0, -20)
	hand.scale = Vector2(0.85, 0.85)
	label.text = tr("TAP TO PULL")

	active_tween = create_tween()
	
	# Fade in
	active_tween.set_parallel(true)
	active_tween.tween_property(hand, "modulate:a", 0.95, 0.2)
	active_tween.tween_property(label, "modulate:a", 1.0, 0.2)
	
	# Tap frog animation (tap down & up)
	active_tween.chain().tween_property(hand, "scale", Vector2(0.68, 0.68), 0.18).set_trans(Tween.TRANS_BACK)
	active_tween.tween_property(hand, "scale", Vector2(0.85, 0.85), 0.18)
	active_tween.tween_interval(0.2)
	active_tween.chain().tween_property(hand, "scale", Vector2(0.68, 0.68), 0.18).set_trans(Tween.TRANS_BACK)
	active_tween.tween_property(hand, "scale", Vector2(0.85, 0.85), 0.18)
	
	# Repeat pull loop
	active_tween.chain().tween_interval(0.5)
	active_tween.chain().tween_callback(_start_pull_animation)

func _finish_tutorial() -> void:
	current_step = 2
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(hand, "modulate:a", 0.0, 0.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.2)
	if arrow_line:
		tw.tween_property(arrow_line, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
