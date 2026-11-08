extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING PUSHING BOX AT (9, 1) DOWN ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_34.txt"
	add_child(node)
	
	var player = node.player_instance
	# Teleport player to (9, 2) right below box
	player.position = Vector2(9 * 128 + 64, 2 * 128 + 64)
	player.tongue_path.clear()
	player.tongue_path.append(player.position)
	
	var box_map_pos = Vector2i(9, 1)
	print("Before push: cell at (9, 1) source_id = ", node.tilemap_layer.get_cell_source_id(box_map_pos))
	
	# If player pushes UP:
	player.extend_tongue(Vector2.UP)
	print("After push UP: cell at (9, 1) source_id = ", node.tilemap_layer.get_cell_source_id(box_map_pos))
	print("Cell at (9, 0) source_id = ", node.tilemap_layer.get_cell_source_id(Vector2i(9, 0)))
	
	# Can tongue get to (9, 0)?
	var head = player.tongue_path.back()
	print("Can tongue enter (9, 0)?")
	player.extend_tongue(Vector2.UP)
	print("Tongue path after trying to enter wall: ", player.tongue_path)
	
	get_tree().quit(0)
