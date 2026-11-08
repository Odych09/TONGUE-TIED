extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 36 SOLVABILITY ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_36.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Try to bridge west canal:
	# Box at (2, 3), push down into lava at (2, 3)? Wait, where is lava on west canal?
	# In row 3: col 2 is B. Where is lava?
	get_tree().quit(0)
