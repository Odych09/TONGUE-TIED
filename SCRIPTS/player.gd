class_name Frog
extends CharacterBody2D

signal player_pulled

const TILE_SIZE: float = 128.0

@export var tilemap_layer: TileMapLayer
@export var max_pulls: int = 5
@export var required_bugs: int = 1
@export var camera: Camera2D

@onready var tongue_line: Line2D = $Line2D
@onready var sprite: Sprite2D = $Sprite2D

var ui_node: Node
var remaining_pulls: int = 0
var collected_bugs: int = 0
var tongue_path: Array[Vector2] = []
var is_latching: bool = false
var is_dead: bool = false

var touch_start_pos: Vector2 = Vector2.ZERO
var is_touch_active: bool = false
const SWIPE_THRESHOLD: float = 38.0

var shake_strength: float = 0.0
var shake_fade: float = 5.0

# Tongue Tip & Idle Animation variables
var tongue_tip: Node2D = null
var idle_timer: float = 0.0
var blink_timer: float = 0.0
var next_blink_interval: float = 3.5
var is_blinking: bool = false

func trigger_haptic(ms: int = 20) -> void:
	if not GameManager.haptics_enabled:
		return
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		Input.vibrate_handheld(ms)

func _ready() -> void:
	remaining_pulls = max_pulls
	tongue_line.top_level = true
	tongue_line.width = 24.0
	tongue_line.default_color = Color(1.0, 0.38, 0.68, 1.0)
	
	if not camera:
		camera = find_child("Camera2D", true, false) as Camera2D
	if not camera and get_viewport():
		camera = get_viewport().get_camera_2d()
		
	_create_tongue_tip()
	position = get_tile_center(position)
	tongue_path.append(position)
	update_tongue_visuals()

func _create_tongue_tip() -> void:
	tongue_tip = Node2D.new()
	tongue_tip.top_level = true
	tongue_tip.z_index = 3
	tongue_tip.visible = false
	add_child(tongue_tip)
	tongue_tip.draw.connect(_draw_tongue_tip)

func _draw_tongue_tip() -> void:
	if not tongue_tip:
		return
	var radius := 18.0
	tongue_tip.draw_circle(Vector2.ZERO, radius, Color(0.78, 0.15, 0.45, 1.0))
	tongue_tip.draw_circle(Vector2.ZERO, radius - 3.0, Color(1.0, 0.42, 0.72, 1.0))
	tongue_tip.draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.28, Color(1.0, 0.9, 0.95, 0.85))

func _process(delta: float) -> void:
	if is_latching and tongue_line.get_point_count() > 0:
		tongue_line.set_point_position(0, position)
		
	if shake_strength > 0.0:
		shake_strength = lerpf(shake_strength, 0.0, shake_fade * delta)
		if camera:
			camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		if camera:
			camera.offset = Vector2.ZERO

	# Idle breathing and eye blinking
	if not is_latching and not is_dead:
		idle_timer += delta
		blink_timer += delta
		if tongue_path.size() <= 1 and not is_blinking:
			var breath := sin(idle_timer * 2.8)
			sprite.scale.x = 1.0 + breath * 0.035
			sprite.scale.y = 1.0 - breath * 0.03
			
		if blink_timer >= next_blink_interval and not is_blinking and tongue_path.size() <= 1:
			_trigger_blink()

func _trigger_blink() -> void:
	is_blinking = true
	blink_timer = 0.0
	next_blink_interval = randf_range(3.5, 5.5)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.15, 0.6), 0.07).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func(): is_blinking = false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ui_node and ui_node.has_method("toggle_pause"):
			ui_node.toggle_pause()
			return

	if Input.is_key_pressed(KEY_R):
		if not (ui_node and ui_node.get("is_paused") == true):
			GameManager.restart_level()
			return

	if ui_node and ui_node.get("is_paused") == true:
		return

	if is_latching or is_dead:
		return

	# Touch & Mouse Swipe Gestures
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_active = true
			touch_start_pos = event.position
		else:
			is_touch_active = false
	elif event is InputEventScreenDrag:
		if is_touch_active:
			_process_swipe(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_touch_active = true
				touch_start_pos = event.position
			else:
				is_touch_active = false
	elif event is InputEventMouseMotion:
		if is_touch_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_process_swipe(event.position)
		
	var direction := Vector2.ZERO
	if event.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed("ui_up"):
		direction = Vector2.UP
		
	if direction != Vector2.ZERO:
		extend_tongue(direction)
		
	if event.is_action_pressed("ui_accept"):
		pull_frog()

func _process_swipe(current_pos: Vector2) -> void:
	if is_latching or is_dead:
		return
	var diff := current_pos - touch_start_pos
	if diff.length() >= SWIPE_THRESHOLD:
		var dir := Vector2.ZERO
		if abs(diff.x) > abs(diff.y):
			dir = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
		else:
			dir = Vector2.DOWN if diff.y > 0 else Vector2.UP
		
		extend_tongue(dir)
		touch_start_pos = current_pos


func rotate_to_direction(direction: Vector2, duration: float = 0.1) -> void:
	if direction == Vector2.ZERO:
		return
	# + PI/2 offset aligns Godot's RIGHT (0 rad) to the sprite's UP resting pose
	var target_angle := direction.angle() + (PI / 2.0)
	var angle_diff := angle_difference(sprite.rotation, target_angle)
	
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", sprite.rotation + angle_diff, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func extend_tongue(direction: Vector2) -> void:
	var current_head := tongue_path.back() as Vector2
	var next_pos := current_head + (direction * TILE_SIZE)
	
	if tongue_path.size() > 1 and next_pos.is_equal_approx(tongue_path[tongue_path.size() - 2]):
		tongue_path.pop_back()
		update_tongue_visuals()
		trigger_haptic(12)
		return
	
	for p in tongue_path:
		if p.is_equal_approx(next_pos):
			return

	# Snappily turn the frog toward the tongue direction on initial extension
	if tongue_path.size() == 1:
		rotate_to_direction(direction, 0.12)

	# Juicy lean/stretch toward extension direction
	var stretch_vec := Vector2(1.15, 0.88) if abs(direction.x) > 0.1 else Vector2(0.88, 1.15)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", stretch_vec, 0.05).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

	var tile_type := get_tile_type_at(next_pos)
	
	if tile_type == "pushable_box":
		push_tile_box(next_pos, direction)
		return
		
	if tile_type == "wall":
		return
	elif tile_type == "tongue_hazard":
		hurt_tongue(next_pos)
		return
	
	tongue_path.append(next_pos)
	update_tongue_visuals()
	trigger_haptic(15)

func push_tile_box(box_world_pos: Vector2, direction: Vector2) -> void:
	var next_world_pos := box_world_pos + (direction * TILE_SIZE)
	var next_tile_type := get_tile_type_at(next_world_pos)
	
	if next_tile_type == "wall" or next_tile_type == "pushable_box":
		shake_strength = 10.0
		trigger_haptic(25)
		return
		
	var map_pos := tilemap_layer.local_to_map(tilemap_layer.to_local(box_world_pos))
	var next_map_pos := map_pos + Vector2i(direction)
	
	if next_tile_type == "water":
		spawn_water_splash(next_world_pos)
		tilemap_layer.erase_cell(map_pos)
		tilemap_layer.erase_cell(next_map_pos)
		tongue_path.append(box_world_pos)
		update_tongue_visuals()
		
		var tween := create_tween()
		tween.tween_interval(0.1)
		tween.tween_callback(func():
			tongue_path.pop_back()
			update_tongue_visuals()
		)
		return
	
	if next_tile_type != "":
		shake_strength = 10.0
		trigger_haptic(25)
		return
		
	var source_id := tilemap_layer.get_cell_source_id(map_pos)
	var atlas_coords := tilemap_layer.get_cell_atlas_coords(map_pos)
	var alt_tile := tilemap_layer.get_cell_alternative_tile(map_pos)
	
	trigger_haptic(25)
	spawn_box_slide_dust(next_world_pos, direction)
	tilemap_layer.erase_cell(map_pos)
	tilemap_layer.set_cell(next_map_pos, source_id, atlas_coords, alt_tile)
	
	tongue_path.append(box_world_pos)
	update_tongue_visuals()
	
	var tween := create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(func():
		tongue_path.pop_back()
		update_tongue_visuals()
	)

func pull_frog() -> void:
	if tongue_path.size() > 1:
		if remaining_pulls <= 0:
			shake_strength = 15.0
			trigger_haptic(35)
			if ui_node and ui_node.has_method("trigger_out_of_pulls_effect"):
				ui_node.trigger_out_of_pulls_effect()
			return
			
		remaining_pulls -= 1
		is_latching = true
		player_pulled.emit()
		trigger_haptic(30)
		
		var music_mgr := get_node_or_null("/root/MusicManager")
		if music_mgr and music_mgr.has_method("play_push_sfx"):
			music_mgr.play_push_sfx()
		
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.25, 0.75), 0.08).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "scale", Vector2(0.75, 1.25), 0.08)
		tween.tween_callback(traverse_tongue)

func traverse_tongue() -> void:
	if tongue_path.size() <= 1:
		reset_tongue()
		return
		
	var next_pos := tongue_path[1]
	var tile_type := get_tile_type_at(next_pos)
	
	if tile_type == "frog_hazard":
		kill_frog(next_pos)
		return
	
	var direction := (next_pos - position).normalized()
	rotate_to_direction(direction, 0.06)
	
	var tween := create_tween()
	tween.tween_property(self, "position", next_pos, 0.08).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func():
		tongue_path.pop_front()
		update_tongue_visuals()
		
		var current_tile_pos := tilemap_layer.local_to_map(tilemap_layer.to_local(position))
		var current_tile_type := get_tile_type_at(position)
		
		if current_tile_type == "bug":
			collected_bugs += 1
			tilemap_layer.erase_cell(current_tile_pos)
			spawn_bug_eat_effect(position)
		
		if current_tile_type == "water" and tongue_path.size() <= 1:
			kill_frog(position)
			return
		
		if current_tile_type == "win":
			if collected_bugs >= required_bugs:
				trigger_win()
				return
			else:
				shake_strength = 8.0
			
		traverse_tongue()
	)

func get_tile_type_at(world_pos: Vector2) -> String:
	if not tilemap_layer or not tilemap_layer.tile_set:
		return ""
		
	var layer_index := tilemap_layer.tile_set.get_custom_data_layer_by_name("type")
	if layer_index < 0:
		return ""
		
	var local_pos := tilemap_layer.to_local(world_pos)
	var map_pos := tilemap_layer.local_to_map(local_pos)
	
	var tile_data := tilemap_layer.get_cell_tile_data(map_pos)
	if tile_data:
		var custom_data = tile_data.get_custom_data("type")
		if custom_data != null:
			return str(custom_data)
			
	return ""

func get_tile_center(pos: Vector2) -> Vector2:
	var grid_pos := (pos / TILE_SIZE).floor()
	return (grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

func update_tongue_visuals() -> void:
	tongue_line.clear_points()
	for p in tongue_path:
		tongue_line.add_point(p)
		
	if tongue_tip:
		if tongue_path.size() > 1:
			tongue_tip.visible = true
			tongue_tip.global_position = tongue_path.back()
			tongue_tip.queue_redraw()
		else:
			tongue_tip.visible = false

func reset_tongue() -> void:
	tongue_path.clear()
	tongue_path.append(position)
	update_tongue_visuals()
	is_latching = false
	shake_strength = 16.0
	
	# Smoothly return to standard UP orientation with juicy bouncy landing
	var angle_diff := angle_difference(sprite.rotation, 0.0)
	
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", sprite.rotation + angle_diff, 0.18)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.35, 0.65), 0.06)
	tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func hurt_tongue(hazard_pos: Vector2) -> void:
	trigger_haptic(50)
	shake_strength = 12.0
	tongue_path.append(hazard_pos)
	update_tongue_visuals()
	tongue_line.modulate = Color.RED
	
	var timer_tween := create_tween()
	timer_tween.tween_interval(0.1)
	timer_tween.tween_callback(func():
		tongue_path.pop_back()
		update_tongue_visuals()
		tongue_line.modulate = Color.WHITE
	)

func kill_frog(death_pos: Vector2) -> void:
	is_dead = true
	trigger_haptic(75)
	shake_strength = 28.0
	spawn_death_effect(death_pos)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", death_pos, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "rotation", PI * 4, 0.3)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3)
	tween.chain().tween_callback(func():
		GameManager.restart_level()
	)

func trigger_win() -> void:
	is_dead = true
	trigger_haptic(45)
	shake_strength = 5.0
	spawn_bug_eat_effect(position)
	
	# Calculate stars earned based on remaining pulls
	var stars: int = 1
	if remaining_pulls >= max_pulls - 1:
		stars = 3
	elif remaining_pulls >= 1:
		stars = 2
	else:
		stars = 1
		
	GameManager.complete_level(GameManager.current_level_index, stars)
	
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	tween.chain().tween_callback(func():
		if ui_node and ui_node.has_method("show_win_modal"):
			ui_node.show_win_modal(stars, remaining_pulls)
		else:
			GameManager.next_level()
	)

# --- PARTICLE & JUICE EFFECTS ---

func spawn_water_splash(world_pos: Vector2) -> void:
	shake_strength = 18.0
	trigger_haptic(40)
	
	var parent_node := get_parent() if get_parent() else self
	
	# Droplet fountain
	var particles := CPUParticles2D.new()
	particles.top_level = true
	particles.z_index = 10
	particles.global_position = world_pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 20
	particles.lifetime = 0.55
	particles.direction = Vector2.UP
	particles.spread = 75.0
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 260.0
	particles.gravity = Vector2(0, 520)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color(0.35, 0.85, 1.0, 0.95)
	parent_node.add_child(particles)
	
	# Concentric expanding ripples
	var ripple := Node2D.new()
	ripple.top_level = true
	ripple.z_index = 1
	ripple.global_position = world_pos
	parent_node.add_child(ripple)
	
	var r_radius: Array[float] = [10.0]
	var r_alpha: Array[float] = [1.0]
	ripple.draw.connect(func():
		ripple.draw_arc(Vector2.ZERO, r_radius[0], 0.0, TAU, 32, Color(0.5, 0.9, 1.0, r_alpha[0]), 3.0)
		ripple.draw_arc(Vector2.ZERO, max(5.0, r_radius[0] * 0.6), 0.0, TAU, 32, Color(0.7, 0.95, 1.0, r_alpha[0] * 0.7), 2.0)
	)
	var tw := create_tween()
	tw.tween_method(func(val: float):
		r_radius[0] = lerpf(10.0, 60.0, val)
		r_alpha[0] = lerpf(1.0, 0.0, val)
		ripple.queue_redraw()
	, 0.0, 1.0, 0.55)
	tw.tween_callback(func():
		ripple.queue_free()
		particles.queue_free()
	)

func spawn_bug_eat_effect(world_pos: Vector2) -> void:
	shake_strength = 12.0
	trigger_haptic(35)
	
	var parent_node := get_parent() if get_parent() else self
	
	# Golden starburst particles
	var particles := CPUParticles2D.new()
	particles.top_level = true
	particles.z_index = 10
	particles.global_position = world_pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 22
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 240.0
	particles.gravity = Vector2(0, 180)
	particles.scale_amount_min = 3.5
	particles.scale_amount_max = 7.0
	particles.color = Color(1.0, 0.92, 0.25, 1.0)
	parent_node.add_child(particles)
	
	# Floating "+1" score popup
	var label := Label.new()
	label.top_level = true
	label.z_index = 15
	label.text = "+1"
	label.global_position = world_pos - Vector2(25, 30)
	label.modulate = Color(1.0, 0.95, 0.3, 1.0)
	var font = load("res://ASSETS/FONT/Gorditas-Bold.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 34)
	parent_node.add_child(label)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "global_position:y", label.global_position.y - 65.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15)
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_delay(0.15)
	tw.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.2)
	tw.chain().tween_callback(func():
		label.queue_free()
		particles.queue_free()
	)

func spawn_death_effect(world_pos: Vector2) -> void:
	var parent_node := get_parent() if get_parent() else self
	var particles := CPUParticles2D.new()
	particles.top_level = true
	particles.z_index = 10
	particles.global_position = world_pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 25
	particles.lifetime = 0.45
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2(0, 100)
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 10.0
	particles.color = Color(0.9, 0.3, 0.3, 0.9)
	parent_node.add_child(particles)
	
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(particles.queue_free)

func spawn_box_slide_dust(world_pos: Vector2, dir: Vector2) -> void:
	var parent_node := get_parent() if get_parent() else self
	var particles := CPUParticles2D.new()
	particles.top_level = true
	particles.z_index = 2
	particles.global_position = world_pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 8
	particles.lifetime = 0.35
	particles.direction = -dir
	particles.spread = 45.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(0.85, 0.95, 1.0, 0.6)
	parent_node.add_child(particles)
	
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(particles.queue_free)
