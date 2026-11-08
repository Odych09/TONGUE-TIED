extends Node

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

func _ready() -> void:
	print("--- TESTING LEVEL 35 FROG_HAZARD INTERACTION ---")
	var node = Node2D.new()
	node.set_script(ASCII_LEVEL_SCRIPT)
	node.level_file = "res://LEVELS_DATA/level_35.txt"
	add_child(node)
	
	var player = node.player_instance
	print("Player initial pos: ", player.position)
	print("Extending tongue DOWN 4 times to row 5...")
	player.extend_tongue(Vector2.DOWN)
	player.extend_tongue(Vector2.DOWN)
	player.extend_tongue(Vector2.DOWN)
	player.extend_tongue(Vector2.DOWN)
	print("Tongue path size: ", player.tongue_path.size(), " points: ", player.tongue_path)
	
	print("Pulling frog...")
	player.pull_frog()
	
	# Wait several frames for tween
	for i in range(30):
		await get_tree().process_frame
		
	print("After pull: player.is_dead = ", player.is_dead)
	print("Player final pos: ", player.position)
	
	if player.is_dead:
		print("VERIFIED BUG: FROG DIED WHILE TRAVERSING OVER X!")
	else:
		print("FROG SURVIVED!")
	get_tree().quit(0)
