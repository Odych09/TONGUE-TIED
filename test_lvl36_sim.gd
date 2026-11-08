extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 36 PULLS ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_36.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Start: pos = ", player.position, " pulls = ", player.remaining_pulls, " bugs = ", player.collected_bugs)
	
	# Can we get bugs in 6 pulls?
	# Bugs are:
	# (2, 5) - Bug 1
	# (2, 9) - Bug 2
	# (2, 12) - Bug 3
	# (19, 12) - Bug 4
	# Now we need 1 more bug (either 9, 9 or 11, 5).
	# To get (9, 9) or (11, 5), can the tongue reach through the central chamber?
	# Wait! Look at row 12:
	# From (2, 12) to (9, 12):
	# Is col 9 open on row 12? YES!
	# But col 9 row 11 is #!
	# So can tongue reach (9, 9)?
	get_tree().quit(0)
