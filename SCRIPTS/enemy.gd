extends CharacterBody2D

class_name GridEnemy

const TILE_SIZE = 128

@export var player: Frog
@export var tilemap_layer: TileMapLayer
@export var patrol_direction: Vector2 = Vector2.RIGHT # Starting direction
@export var patrol_steps: int = 3 # Steps before turning around (<= 0 for corridor patrol until obstacle)

var current_step = 0
var moving_forward = true
var is_moving = false

@onready var sprite = $Sprite2D
@onready var move_timer: Timer = $Timer

func _ready():
	position = get_tile_center(position)
	move_timer.timeout.connect(_on_move_timer_timeout)
	update_facing(patrol_direction)

func update_facing(dir: Vector2):
	if sprite and dir != Vector2.ZERO:
		# croc1.png faces DOWN natively (PI/2 radians)
		var target_rotation = dir.angle() - (PI / 2.0)
		sprite.rotation = target_rotation

func _on_move_timer_timeout():
	if not player:
		player = get_parent().find_child("Player", true, false) as Frog
	if is_moving or (player and (player.is_dead or (player.ui_node and player.ui_node.get("is_paused") == true))):
		return
		
	var step_dir = patrol_direction if moving_forward else -patrol_direction
	var next_pos = position + (step_dir * TILE_SIZE)
	
	# Check if the enemy is walking into a wall or box
	if tilemap_layer:
		var tile_at_next := get_tile_type_at(next_pos)
		if tile_at_next == "wall" or tile_at_next == "pushable_box" or tile_at_next == "breakable_wall":
			moving_forward = not moving_forward
			current_step = 0
			step_dir = patrol_direction if moving_forward else -patrol_direction
			update_facing(step_dir)
			return
		
	is_moving = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", next_pos, 0.15).set_trans(Tween.TRANS_QUAD)
	
	# Smoothly turn sprite towards the step direction
	var target_rot = step_dir.angle() - (PI / 2.0)
	tween.tween_property(sprite, "rotation", target_rot, 0.15).set_trans(Tween.TRANS_QUAD)
	
	if patrol_steps > 0:
		current_step += 1
		if current_step >= patrol_steps:
			current_step = 0
			moving_forward = not moving_forward
	
	tween.chain().tween_callback(func():
		is_moving = false
		
		if player and not player.is_dead and not (player.ui_node and player.ui_node.get("is_paused") == true):
			# Check if the enemy hit the frog's body OR any part of its tongue path!
			var hit_target = position.is_equal_approx(player.position)
			
			if not hit_target and player.tongue_path:
				for p in player.tongue_path:
					if position.is_equal_approx(p):
						hit_target = true
						break
			
			if hit_target:
				player.kill_frog(position)
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
