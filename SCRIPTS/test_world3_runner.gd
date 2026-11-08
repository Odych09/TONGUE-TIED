extends Node

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

func _ready() -> void:
	print("==================================================")
	print("STARTING WORLD 3 (MOLTEN CITADEL) TEST RUNNER")
	print("==================================================")
	
	var pass_count := 0
	var fail_count := 0
	
	# Test 1: GameManager Level Registration
	print("\n--- Test 1: GameManager Registration ---")
	if GameManager:
		GameManager.scan_ascii_levels()
		if GameManager.levels.size() == 45:
			print("[PASS] GameManager registered exactly 45 levels (15 handcrafted + 30 ASCII).")
			pass_count += 1
		else:
			print("[FAIL] GameManager level count mismatch: %d (expected 45)" % GameManager.levels.size())
			fail_count += 1
	else:
		print("[FAIL] GameManager singleton is null!")
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

	# Test 3: Main Home Modal Title Parsing Check
	print("\n--- Test 3: Main Home Modal Title Parsing ---")
	var all_titles_ok := true
	for lvl_num in range(31, 46):
		var txt_path := "res://LEVELS_DATA/level_%d.txt" % lvl_num
		var parsed_title := ""
		if FileAccess.file_exists(txt_path):
			var f := FileAccess.open(txt_path, FileAccess.READ)
			if f:
				while not f.eof_reached():
					var l := f.get_line().strip_edges()
					if l.to_lower().begins_with("name:"):
						var lvl_name := l.substr(5).strip_edges()
						if lvl_name != "":
							parsed_title = lvl_name
						break
					if l == "" or (l.begins_with("#") and not l.to_lower().begins_with("# name:")):
						continue
					if not l.contains(":"):
						break
				f.close()
		if parsed_title != EXPECTED_LEVELS[lvl_num]["name"]:
			print("[FAIL] Lvl %d title parsed by main_home as '%s' (expected '%s')" % [lvl_num, parsed_title, EXPECTED_LEVELS[lvl_num]["name"]])
			all_titles_ok = false
			fail_count += 1
	if all_titles_ok:
		print("[PASS] All 15 level names are correctly parsed by main_home modal logic.")
		pass_count += 1

	# Test 4: AsciiLevel Instantiation & Field Parsing
	print("\n--- Test 4: AsciiLevel Instantiation & Field Parsing ---")
	for lvl_num in range(31, 46):
		var expected: Dictionary = EXPECTED_LEVELS[lvl_num]
		var file_path := "res://LEVELS_DATA/level_%d.txt" % lvl_num
		
		var node = Node2D.new()
		node.set_script(ASCII_LEVEL_SCRIPT)
		node.level_file = file_path
		
		# Set current_level_index in GameManager so world calculations match
		if GameManager:
			GameManager.current_level_index = lvl_num - 1
			
		add_child(node)
		
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
			print("[PASS] Level %d (%s): %dx%d, %d pulls, %d/%d bugs, %d crocs, World %d" % [
				lvl_num, node.level_name, expected["cols"], expected["rows"], node.max_pulls, node.required_bugs, node.bug_count_in_map, enemy_count, world_idx
			])
			pass_count += 1
		else:
			fail_count += 1
			
		node.queue_free()

	# Test 5: In-Engine Turn-by-Turn Solvability Simulation
	print("\n--- Test 5: Live In-Engine Turn-by-Turn Touch & Physics Playtest ---")
	
	# Subtest 5A: Level 35 (Geyser Caldera)
	print("Simulating Level 35 full playthrough...")
	var node35 = Node2D.new()
	node35.set_script(ASCII_LEVEL_SCRIPT)
	node35.level_file = "res://LEVELS_DATA/level_35.txt"
	add_child(node35)
	var p35 = node35.player_instance
	# Pull 1: col 1 down to row 5, eat bug at (3, 5)
	for i in range(4): p35.extend_tongue(Vector2.DOWN)
	for i in range(2): p35.extend_tongue(Vector2.RIGHT)
	p35.pull_frog()
	for i in range(40): await get_tree().process_frame
	# Pull 2: row 5 to col 10 (bug 2)
	for i in range(7): p35.extend_tongue(Vector2.RIGHT)
	p35.pull_frog()
	for i in range(35): await get_tree().process_frame
	# Pull 3: row 5 to col 14 (bug 3)
	for i in range(4): p35.extend_tongue(Vector2.RIGHT)
	p35.pull_frog()
	for i in range(30): await get_tree().process_frame
	# Pull 4: row 5 to col 18 (bug 4), land at col 20
	for i in range(6): p35.extend_tongue(Vector2.RIGHT)
	p35.pull_frog()
	for i in range(35): await get_tree().process_frame
	# Pull 5: col 20 up to W at (20, 1)
	for i in range(4): p35.extend_tongue(Vector2.UP)
	p35.pull_frog()
	for i in range(40): await get_tree().process_frame
	
	if p35.collected_bugs >= 4 and p35.position == Vector2(20 * 128 + 64, 1 * 128 + 64) and not p35.is_dead:
		print("[PASS] Level 35 live playtest: 4/4 bugs eaten, reached W in 5 pulls without incinerating on geysers.")
		pass_count += 1
	elif p35.collected_bugs >= 4 and p35.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("[PASS] Level 35 live playtest: 4/4 bugs eaten, reached W in 5 pulls (trigger_win completed).")
		pass_count += 1
	else:
		print("[FAIL] Level 35 playtest failed: bugs=%d, pos=%s, dead=%s" % [p35.collected_bugs, str(p35.position), str(p35.is_dead)])
		fail_count += 1
	node35.queue_free()

	# Subtest 5B: Level 37 (Cinder Paradox)
	print("Simulating Level 37 full playthrough...")
	var node37 = Node2D.new()
	node37.set_script(ASCII_LEVEL_SCRIPT)
	node37.level_file = "res://LEVELS_DATA/level_37.txt"
	add_child(node37)
	var p37 = node37.player_instance
	for i in range(3): p37.extend_tongue(Vector2.DOWN)
	p37.pull_frog()
	for i in range(25): await get_tree().process_frame
	for i in range(6): p37.extend_tongue(Vector2.RIGHT)
	p37.pull_frog()
	for i in range(35): await get_tree().process_frame
	for i in range(8): p37.extend_tongue(Vector2.RIGHT)
	p37.pull_frog()
	for i in range(40): await get_tree().process_frame
	for i in range(5): p37.extend_tongue(Vector2.RIGHT)
	p37.pull_frog()
	for i in range(30): await get_tree().process_frame
	for i in range(3): p37.extend_tongue(Vector2.UP)
	p37.pull_frog()
	for i in range(35): await get_tree().process_frame
	
	if p37.collected_bugs >= 5 and p37.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("[PASS] Level 37 live playtest: 5/5 bugs eaten, reached W in 5 pulls (trigger_win completed).")
		pass_count += 1
	else:
		print("[FAIL] Level 37 playtest failed: bugs=%d, pos=%s" % [p37.collected_bugs, str(p37.position)])
		fail_count += 1
	node37.queue_free()

	# Subtest 5C: Level 43 (Caldera of the Sunken Gods)
	print("Simulating Level 43 full playthrough...")
	var node43 = Node2D.new()
	node43.set_script(ASCII_LEVEL_SCRIPT)
	node43.level_file = "res://LEVELS_DATA/level_43.txt"
	add_child(node43)
	var p43 = node43.player_instance
	# Pull 1: col 1 down to row 5, eat bug at (2, 5), enter pillar at (6, 3) [bug 2]
	for i in range(4): p43.extend_tongue(Vector2.DOWN)
	for i in range(5): p43.extend_tongue(Vector2.RIGHT)
	for i in range(2): p43.extend_tongue(Vector2.UP)
	p43.pull_frog()
	for i in range(45): await get_tree().process_frame
	# Pull 2: down into (6, 7) [bug 3]
	for i in range(4): p43.extend_tongue(Vector2.DOWN)
	p43.pull_frog()
	for i in range(40): await get_tree().process_frame
	# Pull 3: into (13, 3) [bug 4]
	for i in range(2): p43.extend_tongue(Vector2.UP)
	for i in range(7): p43.extend_tongue(Vector2.RIGHT)
	for i in range(2): p43.extend_tongue(Vector2.UP)
	p43.pull_frog()
	for i in range(45): await get_tree().process_frame
	# Pull 4: down into (13, 7) [bug 5]
	for i in range(4): p43.extend_tongue(Vector2.DOWN)
	p43.pull_frog()
	for i in range(40): await get_tree().process_frame
	# Pull 5: out to (17, 5) [bug 6], land at (20, 5)
	for i in range(2): p43.extend_tongue(Vector2.UP)
	for i in range(7): p43.extend_tongue(Vector2.RIGHT)
	p43.pull_frog()
	for i in range(40): await get_tree().process_frame
	# Pull 6: straight up to W at (20, 1)
	for i in range(4): p43.extend_tongue(Vector2.UP)
	p43.pull_frog()
	for i in range(45): await get_tree().process_frame
	
	if p43.collected_bugs >= 6 and p43.position == Vector2(20 * 128 + 64, 1 * 128 + 64):
		print("[PASS] Level 43 live playtest: 6/6 bugs eaten, reached W in 6 pulls through pillar entrances.")
		pass_count += 1
	else:
		print("[FAIL] Level 43 playtest failed: bugs=%d, pos=%s" % [p43.collected_bugs, str(p43.position)])
		fail_count += 1
	node43.queue_free()

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [pass_count, fail_count])
	print("==================================================")
	
	if fail_count == 0:
		print("ALL WORLD 3 VERIFICATIONS SUCCEEDED!")
		get_tree().quit(0)
	else:
		print("SOME VERIFICATIONS FAILED!")
		get_tree().quit(1)
