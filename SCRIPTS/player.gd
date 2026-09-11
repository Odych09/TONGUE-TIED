extends CharacterBody2D

class_name Frog

const TILE_SIZE = 128

@export var tilemap_layer: TileMapLayer
@export var max_pulls: int = 5
@export var required_bugs: int = 1
var ui_node;

var remaining_pulls = 0
var collected_bugs = 0
var tongue_path = []
var is_latching = false
var is_dead = false

var shake_strength = 0.0
var shake_fade = 5.0

@onready var tongue_line = $Line2D
@onready var sprite = $Sprite2D
@export var camera: Camera2D

signal player_pulled

func _ready():
	remaining_pulls = max_pulls
	tongue_line.top_level = true
	position = get_tile_center(position)
	tongue_path.append(position)
	update_tongue_visuals()

func _process(delta):
	if is_latching and tongue_line.get_point_count() > 0:
		tongue_line.set_point_position(0, position)
		
	if shake_strength > 0.0:
		shake_strength = lerpf(shake_strength, 0.0, shake_fade * delta)
		if camera:
			camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		if camera:
			camera.offset = Vector2.ZERO

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		return

	if is_latching or is_dead:
		return
		
	var direction = Vector2.ZERO
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

func extend_tongue(direction: Vector2):
	var current_head = tongue_path.back()
	var next_pos = current_head + (direction * TILE_SIZE)
	
	if tongue_path.size() > 1 and next_pos.is_equal_approx(tongue_path[tongue_path.size() - 2]):
		tongue_path.pop_back()
		update_tongue_visuals()
		return
	
	for p in tongue_path:
		if p.is_equal_approx(next_pos):
			return
			
	var tile_type = get_tile_type_at(next_pos)
	
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

func push_tile_box(box_world_pos: Vector2, direction: Vector2):
	var next_world_pos = box_world_pos + (direction * TILE_SIZE)
	var next_tile_type = get_tile_type_at(next_world_pos)
	
	if next_tile_type == "wall" or next_tile_type == "pushable_box":
		shake_strength = 10.0
		return
		
	var map_pos = tilemap_layer.local_to_map(tilemap_layer.to_local(box_world_pos))
	var next_map_pos = map_pos + Vector2i(direction)
	
	if next_tile_type == "water":
		tilemap_layer.erase_cell(map_pos)
		tilemap_layer.erase_cell(next_map_pos)
		
		tongue_path.append(box_world_pos)
		update_tongue_visuals()
		
		var tween = create_tween()
		tween.tween_interval(0.1)
		tween.tween_callback(func():
			tongue_path.pop_back()
			update_tongue_visuals()
		)
		return
	
	if next_tile_type != "":
		shake_strength = 10.0
		return
		
	var source_id = tilemap_layer.get_cell_source_id(map_pos)
	var atlas_coords = tilemap_layer.get_cell_atlas_coords(map_pos)
	var alt_tile = tilemap_layer.get_cell_alternative_tile(map_pos)
	
	tilemap_layer.erase_cell(map_pos)
	tilemap_layer.set_cell(next_map_pos, source_id, atlas_coords, alt_tile)
	
	tongue_path.append(box_world_pos)
	update_tongue_visuals()
	
	var tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(func():
		tongue_path.pop_back()
		update_tongue_visuals()
	)

func pull_frog():
	if tongue_path.size() > 1:
		if remaining_pulls <= 0:
			shake_strength = 15.0
			if ui_node and ui_node.has_method("trigger_out_of_pulls_effect"):
				ui_node.trigger_out_of_pulls_effect()
			return
			
		remaining_pulls -= 1
		is_latching = true
		emit_signal("player_pulled")
		
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1)
		tween.tween_callback(traverse_tongue)

func traverse_tongue():
	if tongue_path.size() <= 1:
		reset_tongue()
		return
		
	var next_pos = tongue_path[1]
	
	var tile_type = get_tile_type_at(next_pos)
	if tile_type == "frog_hazard":
		kill_frog(next_pos)
		return
	
	var direction = (next_pos - position).normalized()
	sprite.rotation = direction.angle()
	
	var tween = create_tween()
	tween.tween_property(self, "position", next_pos, 0.08).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func():
		tongue_path.pop_front()
		update_tongue_visuals()
		
		var current_tile_pos = tilemap_layer.local_to_map(tilemap_layer.to_local(position))
		var current_tile_type = get_tile_type_at(position)
		
		if current_tile_type == "bug":
			collected_bugs += 1
			tilemap_layer.erase_cell(current_tile_pos)
		
		if current_tile_type == "water":
			if tongue_path.size() <= 1:
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
		
	var layer_index = tilemap_layer.tile_set.get_custom_data_layer_by_name("type")
	if layer_index < 0:
		return ""
		
	var local_pos = tilemap_layer.to_local(world_pos)
	var map_pos = tilemap_layer.local_to_map(local_pos)
	
	var tile_data = tilemap_layer.get_cell_tile_data(map_pos)
	if tile_data:
		var custom_data = tile_data.get_custom_data("type")
		if custom_data != null:
			return str(custom_data)
			
	return ""

func get_tile_center(pos: Vector2) -> Vector2:
	var grid_pos = floor(pos / TILE_SIZE)
	return (grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

func update_tongue_visuals():
	tongue_line.clear_points()
	for p in tongue_path:
		tongue_line.add_point(p)

func reset_tongue():
	tongue_path.clear()
	tongue_path.append(position)
	update_tongue_visuals()
	is_latching = false
	
	shake_strength = 20.0
	sprite.rotation = 0
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.05)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func hurt_tongue(hazard_pos: Vector2):
	shake_strength = 10.0
	tongue_path.append(hazard_pos)
	update_tongue_visuals()
	tongue_line.modulate = Color.RED
	var timer_tween = create_tween()
	timer_tween.tween_interval(0.1)
	timer_tween.tween_callback(func():
		tongue_path.pop_back()
		update_tongue_visuals()
		tongue_line.modulate = Color.WHITE
	)

func kill_frog(death_pos: Vector2):
	is_dead = true
	shake_strength = 30.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", death_pos, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "rotation", PI * 4, 0.3)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3)
	tween.chain().tween_callback(func():
		get_tree().reload_current_scene()
	)

func trigger_win():
	is_dead = true
	shake_strength = 5.0
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	tween.chain().tween_callback(func():
		get_tree().reload_current_scene()
	)
