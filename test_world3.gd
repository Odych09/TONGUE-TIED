extends SceneTree

const ASCII_LEVEL_SCRIPT = preload("res://SCRIPTS/ascii_level.gd")

const EXPECTED_LEVELS = {
	31: {"name": "The Obsidian Portcullis", "pulls": 5, "bugs": 4, "actual_bugs": 5, "cols": 22, "rows": 12, "crocs": 0, "boxes": 2, "gates": 1},
	32: {"name": "Twin Crucible of Cinders", "pulls": 5, "bugs": 4, "actual_bugs": 5, "cols": 22, "rows": 13, "crocs": 3, "boxes": 2, "gates": 0},
	33: {"name": "The Thermal Aqueduct", "pulls": 4, "bugs": 4, "actual_bugs": 4, "cols": 22, "rows": 12, "crocs": 0, "boxes": 0, "gates": 0},
	34: {"name": "Pincer Forge", "pulls": 6, "bugs": 5, "actual_bugs": 6, "cols": 22, "rows": 14, "crocs": 4, "boxes": 4, "gates": 0},
	35: {"name": "The Geyser Caldera", "pulls": 5, "bugs": 4, "actual_bugs": 4, "cols": 22, "rows": 12, "crocs": 0, "boxes": 0, "gates": 0},
	36: {"name": "The Foundry Battering Ram", "pulls": 6, "bugs": 5, "actual_bugs": 6, "cols": 22, "rows": 14, "crocs": 0, "boxes": 3, "gates": 2},
	37: {"name": "The Cinder Paradox", "pulls": 5, "bugs": 5, "actual_bugs": 5, "cols": 22, "rows": 12, "crocs": 0, "boxes": 0, "gates": 0},
	38: {"name": "The Magma Locksmith", "pulls": 6, "bugs": 5, "actual_bugs": 5, "cols": 22, "rows": 14, "crocs": 1, "boxes": 3, "gates": 1},
	39: {"name": "Obsidian Quadrants", "pulls": 7, "bugs": 5, "actual_bugs": 5, "cols": 22, "rows": 15, "crocs": 1, "boxes": 1, "gates": 1},
	40: {"name": "The Molten Crucible", "pulls": 6, "bugs": 5, "actual_bugs": 6, "cols": 22, "rows": 14, "crocs": 0, "boxes": 3, "gates": 0},
	41: {"name": "The Infernal Switchback", "pulls": 5, "bugs": 5, "actual_bugs": 6, "cols": 22, "rows": 13, "crocs": 4, "boxes": 0, "gates": 0},
	42: {"name": "The Dragon's Throat", "pulls": 6, "bugs": 5, "actual_bugs": 5, "cols": 22, "rows": 14, "crocs": 6, "boxes": 3, "gates": 0},
	43: {"name": "Caldera of the Sunken Gods", "pulls": 6, "bugs": 6, "actual_bugs": 8, "cols": 22, "rows": 12, "crocs": 0, "boxes": 0, "gates": 0},
	44: {"name": "The Infernal Foundry", "pulls": 7, "bugs": 6, "actual_bugs": 6, "cols": 22, "rows": 14, "crocs": 2, "boxes": 3, "gates": 3},
	45: {"name": "The Master of Tongues (Infernal Sovereign)", "pulls": 8, "bugs": 7, "actual_bugs": 8, "cols": 24, "rows": 16, "crocs": 2, "boxes": 4, "gates": 3}
}

func _init() -> void:
	print("==================================================")
	print("STARTING WORLD 3 (MOLTEN CITADEL) TEST SUITE")
	print("==================================================")
	
	var pass_count := 0
	var fail_count := 0
	
	# Test 1: GameManager Level Registration
	print("\n--- Test 1: GameManager Registration ---")
	GameManager.scan_ascii_levels()
	if GameManager.levels.size() == 45:
		print("[PASS] GameManager registered exactly 45 levels (15 handcrafted + 30 ASCII).")
		pass_count += 1
	else:
		print("[FAIL] GameManager level count mismatch: %d (expected 45)" % GameManager.levels.size())
		fail_count += 1

	# Test 2: File Existence for World 3
	print("\n--- Test 2: Level Files Existence ---")
	var all_files_exist := true
	for lvl_num in range(31, 46):
		var p := "res://LEVELS_DATA/level_%d.txt" % lvl_num
		if not FileAccess.file_exists(p):
			print("[FAIL] File does not exist: %s" % p)
			all_files_exist = false
			fail_count += 1
	if all_files_exist:
		print("[PASS] All level files level_31.txt through level_45.txt exist.")
		pass_count += 1

	# Test 3: AsciiLevel Instantiation & Metadata Verification
	print("\n--- Test 3: AsciiLevel Instantiation & Field Parsing ---")
	for lvl_num in range(31, 46):
		var expected: Dictionary = EXPECTED_LEVELS[lvl_num]
		var file_path := "res://LEVELS_DATA/level_%d.txt" % lvl_num
		
		var node = Node2D.new()
		node.set_script(ASCII_LEVEL_SCRIPT)
		node.level_file = file_path
		
		# Add to root to trigger _ready() and _setup_tilemaps / load_and_build
		root.add_child(node)
		
		var level_ok := true
		
		# Name
		if node.level_name != expected["name"]:
			print("[FAIL] Lvl %d name mismatch: '%s' vs '%s'" % [lvl_num, node.level_name, expected["name"]])
			level_ok = false
			
		# Pulls
		if node.max_pulls != expected["pulls"]:
			print("[FAIL] Lvl %d max_pulls mismatch: %d vs %d" % [lvl_num, node.max_pulls, expected["pulls"]])
			level_ok = false
			
		# Required bugs
		if node.required_bugs != expected["bugs"]:
			print("[FAIL] Lvl %d required_bugs mismatch: %d vs %d" % [lvl_num, node.required_bugs, expected["bugs"]])
			level_ok = false
			
		# Actual bugs in map
		if node.bug_count_in_map != expected["actual_bugs"]:
			print("[FAIL] Lvl %d bug_count_in_map mismatch: %d vs %d" % [lvl_num, node.bug_count_in_map, expected["actual_bugs"]])
			level_ok = false
			
		# Solvability check: bugs in map must be >= required bugs
		if node.bug_count_in_map < node.required_bugs:
			print("[FATAL FAIL] Lvl %d UNSOLVABLE: bug_count_in_map (%d) < required_bugs (%d)" % [lvl_num, node.bug_count_in_map, node.required_bugs])
			level_ok = false
			
		# Player instance
		if not node.player_instance:
			print("[FAIL] Lvl %d: player_instance is null!" % lvl_num)
			level_ok = false
		else:
			if node.player_instance.max_pulls != expected["pulls"]:
				print("[FAIL] Lvl %d: player_instance.max_pulls mismatch!" % lvl_num)
				level_ok = false
			if node.player_instance.required_bugs != expected["bugs"]:
				print("[FAIL] Lvl %d: player_instance.required_bugs mismatch!" % lvl_num)
				level_ok = false
			if not node.player_instance.camera:
				print("[FAIL] Lvl %d: player Camera2D is null!" % lvl_num)
				level_ok = false
			else:
				var expected_limit_right: int = int((expected["cols"] + 1) * 128.0)
				var expected_limit_bottom: int = int((expected["rows"] + 1) * 128.0)
				if node.player_instance.camera.limit_right != expected_limit_right or node.player_instance.camera.limit_bottom != expected_limit_bottom:
					print("[FAIL] Lvl %d: Camera limits incorrect! Got (%d, %d), expected (%d, %d)" % [
						lvl_num,
						node.player_instance.camera.limit_right, node.player_instance.camera.limit_bottom,
						expected_limit_right, expected_limit_bottom
					])
					level_ok = false
					
		# Enemies count
		var enemy_count := 0
		for child in node.get_children():
			if child is GridEnemy:
				enemy_count += 1
		if enemy_count != expected["crocs"]:
			print("[FAIL] Lvl %d: Enemy count mismatch! Got %d, expected %d" % [lvl_num, enemy_count, expected["crocs"]])
			level_ok = false

		# Biome check: world index should be 2 (Molten Citadel)
		var world_idx = node._get_current_world_index()
		if world_idx != 2:
			print("[FAIL] Lvl %d: World index is %d (expected 2 for Molten Citadel)" % [lvl_num, world_idx])
			level_ok = false

		if level_ok:
			print("[PASS] Level %d (%s) fully initialized & validated: %dx%d, %d pulls, %d/%d bugs, %d crocs, World %d" % [
				lvl_num, node.level_name, expected["cols"], expected["rows"], node.max_pulls, node.required_bugs, node.bug_count_in_map, enemy_count, world_idx
			])
			pass_count += 1
		else:
			fail_count += 1
			
		node.queue_free()

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [pass_count, fail_count])
	print("==================================================")
	
	if fail_count == 0:
		print("ALL WORLD 3 VERIFICATIONS SUCCEEDED!")
		quit(0)
	else:
		print("SOME VERIFICATIONS FAILED!")
		quit(1)
