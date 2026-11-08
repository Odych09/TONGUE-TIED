extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_35.txt"
	add_child(node)
	
	# Print all tile types in Level 35
	print("Level 35 tile types at col 5:")
	for r in range(12):
		var pos = Vector2(5 * 128 + 64, r * 128 + 64)
		print("Row ", r, ": ", node.player_instance.get_tile_type_at(pos))
	get_tree().quit(0)
