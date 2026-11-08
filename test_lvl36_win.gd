extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 36 BATTERING RAM MECHANIC ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_36.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Verify Box 2 at (9, 2) can be pushed EAST into Gate 1 at (14, 2)
	# Frog starts at (1, 1). Move down west room to eat (2, 5), (2, 9), (2, 12), pull to (16, 12)
	for i in range(11): player.extend_tongue(Vector2.DOWN)
	for i in range(15): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(45): await get_tree().process_frame
	print("After pull 1: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 2: Cross lava at (17, 12) to eat bug at (19, 12), pull up to (19, 2)
	for i in range(3): player.extend_tongue(Vector2.RIGHT)
	for i in range(10): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(45): await get_tree().process_frame
	print("After pull 2: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# At (19, 2): Box 3 is at (19, 2)! Player is at (19, 2)!
	# Push Box 3 down col 19 into Gate 2:
	# From (19, 2) move tongue down
	get_tree().quit(0)
