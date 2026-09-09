extends CharacterBody2D

class_name GridEnemy

const TILE_SIZE = 128

@export var player: Frog
@export var tilemap_layer: TileMapLayer
@export var patrol_direction: Vector2 = Vector2.RIGHT # Starting direction
@export var patrol_steps: int = 3 # Steps before turning around

var current_step = 0
var moving_forward = true
var is_moving = false

@onready var sprite = $Sprite2D
@onready var move_timer: Timer = $Timer

func _ready():
	position = get_tile_center(position)
	move_timer.timeout.connect(_on_move_timer_timeout)

func _on_move_timer_timeout():
	if is_moving or (player and player.is_dead):
		return
		
	var step_dir = patrol_direction if moving_forward else -patrol_direction
	var next_pos = position + (step_dir * TILE_SIZE)
	
	# Check if the enemy is walking into a wall tile
	if tilemap_layer and get_tile_type_at(next_pos) == "wall":
		moving_forward = not moving_forward
		return
		
	current_step += 1
	if current_step >= patrol_steps:
		current_step = 0
		moving_forward = not moving_forward
		
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", next_pos, 0.15).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_callback(func():
		is_moving = false
		
		if player and not player.is_dead:
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
