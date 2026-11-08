extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 37 SOLVABILITY ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_37.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Pull 1: Move down to (1, 4)
	player.extend_tongue(Vector2.DOWN)
	player.extend_tongue(Vector2.DOWN)
	player.extend_tongue(Vector2.DOWN)
	player.pull_frog()
	for i in range(25): await get_tree().process_frame
	print("After pull 1: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 2: Move right along row 4 to eat bugs at (2, 4) and (6, 4), land at (7, 4)
	for i in range(6): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(35): await get_tree().process_frame
	print("After pull 2: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 3: Move right along row 4 to eat bugs at (10, 4) and (14, 4), land at (15, 4)
	for i in range(8): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 3: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 4: Move right to eat bug at (18, 4), land at (20, 4)
	for i in range(5): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(30): await get_tree().process_frame
	print("After pull 4: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 5: Move up to W at (20, 1)
	for i in range(3): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(25): await get_tree().process_frame
	print("After pull 5: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	if player.collected_bugs >= 5 and player.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("LEVEL 37 WON SUCCESSFULLY!")
	else:
		print("LEVEL 37 FAILED!")
	get_tree().quit(0)
