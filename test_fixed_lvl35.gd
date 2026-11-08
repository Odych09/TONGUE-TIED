extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 35 PERFECTION ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_35.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Pull 1: Move down col 1 (row 1 -> row 5), eat bug at (3, 5), land at (3, 5)
	for i in range(4): player.extend_tongue(Vector2.DOWN)
	for i in range(2): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 1: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 2: Move right along row 5 to eat bug at (10, 5), land at (10, 5)
	for i in range(7): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(35): await get_tree().process_frame
	print("After pull 2: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 3: Move right along row 5 to eat bug at (14, 5), land at (14, 5)
	for i in range(4): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(30): await get_tree().process_frame
	print("After pull 3: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 4: Move right along row 5 to eat bug at (18, 5), land at (20, 5)
	for i in range(6): player.extend_tongue(Vector2.RIGHT)
	player.pull_frog()
	for i in range(35): await get_tree().process_frame
	print("After pull 4: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	# Pull 5: Move straight up col 20 (row 5 -> row 1) directly onto W at (20, 1)!
	for i in range(4): player.extend_tongue(Vector2.UP)
	player.pull_frog()
	for i in range(40): await get_tree().process_frame
	print("After pull 5: pos = ", player.position, " dead = ", player.is_dead, " bugs = ", player.collected_bugs)
	
	if player.collected_bugs >= 4 and player.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("LEVEL 35 100% PERFECT VICTORY IN EXACTLY 5 PULLS!")
	else:
		print("LEVEL 35 FAILED!")
	get_tree().quit(0)
