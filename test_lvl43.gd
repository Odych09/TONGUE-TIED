extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 43 REAL PULL SEQUENCE ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_43.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Pull 1: (1, 1) -> down to (1, 5) -> right through (2, 5) [bug 1] to (6, 5) -> up into (6, 3) [bug 2]
	for i in range(4): player.extend_tongue(Vector2.DOWN)
	for i in range(5): player.extend_tongue(Vector2.RIGHT)
	for i in range(2): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(45): await get_tree().process_frame
	print("After pull 1: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 2: From (6, 3) -> down through (6, 5) into (6, 7) [bug 3]
	for i in range(4): player.extend_tongue(Vector2.DOWN)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 2: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 3: From (6, 7) -> up to (6, 5) -> right to (13, 5) -> up into (13, 3) [bug 4]
	for i in range(2): player.extend_tongue(Vector2.UP)
	for i in range(7): player.extend_tongue(Vector2.RIGHT)
	for i in range(2): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(45): await get_tree().process_frame
	print("After pull 3: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 4: From (13, 3) -> down through (13, 5) into (13, 7) [bug 5]
	for i in range(4): player.extend_tongue(Vector2.DOWN)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 4: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 5: From (13, 7) -> up to (13, 5) -> right through (17, 5) [bug 6] to (20, 5)
	for i in range(2): player.extend_tongue(Vector2.UP)
	for i in range(7): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 5: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 6: From (20, 5) -> straight up col 20 to W at (20, 1)!
	for i in range(4): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(45): await get_tree().process_frame
	print("After pull 6: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	if player.collected_bugs >= 6 and player.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("LEVEL 43 100% PERFECT VICTORY IN EXACTLY 6 PULLS!")
	else:
		print("LEVEL 43 FAILED!")
	get_tree().quit(0)
