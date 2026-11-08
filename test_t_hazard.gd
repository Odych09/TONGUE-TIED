extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_33.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Starting pos: ", player.position)
	# Check adjacent tiles:
	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var next_tile = player.get_tile_type_at(player.position + dir * 128)
		print("Dir ", dir, " tile type: ", next_tile)
	
	# In Level 33, row 1 is: #P...T....T....T...W.#
	# Player is at (1, 1). To the right:
	# (2, 1) is .
	# (3, 1) is .
	# (4, 1) is .
	# (5, 1) is T
	print("Extending right 4 times towards T...")
	player.extend_tongue(Vector2.RIGHT)
	player.extend_tongue(Vector2.RIGHT)
	player.extend_tongue(Vector2.RIGHT)
	print("Tongue path before hitting T: ", player.tongue_path.size())
	player.extend_tongue(Vector2.RIGHT)
	print("Tongue path immediately after hitting T: ", player.tongue_path.size())
	await get_tree().create_timer(0.25).timeout
	print("Tongue path after 0.25s: ", player.tongue_path.size())
	
	get_tree().quit(0)
