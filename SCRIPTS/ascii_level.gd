extends Node2D
class_name AsciiLevel

const TILE_SIZE: float = 128.0

# Assets and Scenes
const TILESET_PATH: String = "res://ASSETS/TILES/tileset_main.tres"
const PLAYER_SCENE: PackedScene = preload("res://SCENES/Player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://SCENES/enemy.tscn")

# Tile source IDs in tileset_main.tres
const TILE_BOX: int = 1
const TILE_BUG: int = 2
const TILE_WIN: int = 3
const TILE_FROG_HAZARD: int = 4
const TILE_TONGUE_HAZARD: int = 5
const TILE_WALL: int = 6
const TILE_WATER: int = 7
const TILE_GOOP: int = 8

# World Biomes for in-game visuals
const BIOMES_INGAME: Array[Dictionary] = [
	{
		"name": "Emerald Lagoon",
		"water_tint": Color(1.0, 1.0, 1.0, 1.0),
		"ambient_modulate": Color(1.0, 1.0, 1.0, 1.0),
		"hazard_tile": 7
	},
	{
		"name": "Twilight Swamp",
		"water_tint": Color(0.60, 0.30, 0.95, 1.0),
		"ambient_modulate": Color(0.92, 0.86, 1.0, 1.0),
		"hazard_tile": 8 # Goop hazard
	},
	{
		"name": "Molten Citadel",
		"water_tint": Color(1.0, 0.45, 0.12, 1.0),
		"ambient_modulate": Color(1.0, 0.90, 0.82, 1.0),
		"hazard_tile": 7
	}
]

@export_file("*.txt") var level_file: String = ""

var tilemap_layer: TileMapLayer
var bg_water_layer: TileMapLayer
var player_instance: Frog

var level_name: String = "ASCII Level"
var max_pulls: int = 5
var required_bugs: int = 0
var bug_count_in_map: int = 0

func _ready() -> void:
	_setup_tilemaps()
	load_and_build()

func _setup_tilemaps() -> void:
	var tileset: TileSet = load(TILESET_PATH) as TileSet

	# Background water layer (visual ocean under the level)
	bg_water_layer = TileMapLayer.new()
	bg_water_layer.name = "BackgroundWater"
	bg_water_layer.tile_set = tileset
	bg_water_layer.z_index = -1
	add_child(bg_water_layer)

	# Foreground gameplay tilemap layer
	tilemap_layer = TileMapLayer.new()
	tilemap_layer.name = "TileMapLayer"
	tilemap_layer.tile_set = tileset
	tilemap_layer.z_index = 0
	add_child(tilemap_layer)

func _get_target_level_file() -> String:
	if not level_file.is_empty() and FileAccess.file_exists(level_file):
		return level_file

	# If GameManager is active, try loading based on current level index
	if GameManager:
		var candidate := "res://LEVELS_DATA/level_%d.txt" % (GameManager.current_level_index + 1)
		if FileAccess.file_exists(candidate):
			return candidate

	# Default fallback to level 16
	if FileAccess.file_exists("res://LEVELS_DATA/level_16.txt"):
		return "res://LEVELS_DATA/level_16.txt"

	return ""

func _get_current_level_num() -> int:
	var path := _get_target_level_file()
	if not path.is_empty():
		var regex := RegEx.new()
		regex.compile("level_(\\d+)")
		var match_res := regex.search(path)
		if match_res:
			return int(match_res.get_string(1))
	if GameManager:
		return GameManager.current_level_index + 1
	return 16

func _get_current_world_index() -> int:
	var lvl_num := _get_current_level_num()
	return clampi(int((lvl_num - 1) / 15), 0, BIOMES_INGAME.size() - 1)

func load_and_build() -> void:
	var path := _get_target_level_file()
	var content := ""

	if not path.is_empty() and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			content = file.get_as_text()
			file.close()

	if content.is_empty():
		content = _get_default_fallback_map()

	_parse_and_build(content)

func _parse_and_build(raw_text: String) -> void:
	var lines := raw_text.split("\n")
	var grid_lines: Array[String] = []
	var player_grid_pos := Vector2i(-1, -1)
	var enemies_data: Array[Dictionary] = []

	var world_idx := _get_current_world_index()
	var biome_cfg: Dictionary = BIOMES_INGAME[world_idx]

	# Apply world ambient lighting mood
	self.modulate = biome_cfg.ambient_modulate

	# Reset counters
	bug_count_in_map = 0
	max_pulls = 5
	required_bugs = 0

	# 1. Parse metadata and extract map lines
	for raw_line in lines:
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("//") or line.begins_with("# "):
			continue

		# Metadata lines
		if line.begins_with("name:"):
			level_name = line.substr(5).strip_edges().trim_prefix('"').trim_suffix('"')
			continue
		elif line.begins_with("pulls:"):
			max_pulls = int(line.substr(6).strip_edges())
			continue
		elif line.begins_with("bugs:"):
			required_bugs = int(line.substr(5).strip_edges())
			continue

		# Grid line
		grid_lines.append(raw_line)

	if grid_lines.is_empty():
		push_error("AsciiLevel: No grid lines found in level data!")
		return

	var max_cols := 0
	var max_rows := grid_lines.size()

	# 2. Build foreground tiles and collect entities
	for row in range(max_rows):
		var line_str := grid_lines[row]
		max_cols = maxi(max_cols, line_str.length())

		for col in range(line_str.length()):
			var char := line_str[col]
			var map_pos := Vector2i(col, row)

			match char:
				'#':
					tilemap_layer.set_cell(map_pos, TILE_WALL, Vector2i.ZERO)
				'~':
					tilemap_layer.set_cell(map_pos, biome_cfg.hazard_tile, Vector2i.ZERO)
				'B':
					tilemap_layer.set_cell(map_pos, TILE_BOX, Vector2i.ZERO)
				'*':
					tilemap_layer.set_cell(map_pos, TILE_BUG, Vector2i.ZERO)
					bug_count_in_map += 1
				'W':
					tilemap_layer.set_cell(map_pos, TILE_WIN, Vector2i.ZERO)
				'X':
					tilemap_layer.set_cell(map_pos, TILE_FROG_HAZARD, Vector2i.ZERO)
				'T':
					tilemap_layer.set_cell(map_pos, TILE_TONGUE_HAZARD, Vector2i.ZERO)
				'P':
					player_grid_pos = map_pos
				'>':
					enemies_data.append({"pos": map_pos, "dir": Vector2.RIGHT, "steps": 3})
				'<':
					enemies_data.append({"pos": map_pos, "dir": Vector2.LEFT, "steps": 3})
				'^':
					enemies_data.append({"pos": map_pos, "dir": Vector2.UP, "steps": 3})
				'v':
					enemies_data.append({"pos": map_pos, "dir": Vector2.DOWN, "steps": 3})
				'.', ' ':
					pass # Open ground

	# Default required bugs to all bugs in map if not explicitly set
	if required_bugs <= 0:
		required_bugs = bug_count_in_map

	# 3. Fill ambient water background surrounding the map with world theme tint
	bg_water_layer.visible = true
	bg_water_layer.modulate = biome_cfg.water_tint
	var pad_x := 10
	var pad_y := 8
	for r in range(-pad_y, max_rows + pad_y):
		for c in range(-pad_x, max_cols + pad_x):
			bg_water_layer.set_cell(Vector2i(c, r), TILE_WATER, Vector2i.ZERO)

	# 4. Spawn Player
	if player_grid_pos == Vector2i(-1, -1):
		player_grid_pos = Vector2i(1, 1)

	var player_world_pos := Vector2(
		player_grid_pos.x * TILE_SIZE + (TILE_SIZE * 0.5),
		player_grid_pos.y * TILE_SIZE + (TILE_SIZE * 0.5)
	)

	player_instance = PLAYER_SCENE.instantiate() as Frog
	player_instance.name = "Player"
	player_instance.position = player_world_pos
	player_instance.tilemap_layer = tilemap_layer
	player_instance.max_pulls = max_pulls
	player_instance.required_bugs = required_bugs
	player_instance.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Create Camera2D attached to player
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = int(-128)
	cam.limit_top = int(-128)
	cam.limit_right = int((max_cols + 1) * TILE_SIZE)
	cam.limit_bottom = int((max_rows + 1) * TILE_SIZE)
	player_instance.add_child(cam)
	player_instance.camera = cam

	add_child(player_instance)

	# 5. Spawn Enemies
	for e in enemies_data:
		var enemy := ENEMY_SCENE.instantiate() as GridEnemy
		enemy.position = Vector2(
			e.pos.x * TILE_SIZE + (TILE_SIZE * 0.5),
			e.pos.y * TILE_SIZE + (TILE_SIZE * 0.5)
		)
		enemy.tilemap_layer = tilemap_layer
		enemy.player = player_instance
		enemy.patrol_direction = e.dir
		enemy.patrol_steps = e.steps
		enemy.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		add_child(enemy)

	# 6. Bind to CRT HUD if present
	await get_tree().process_frame
	var crt_overlay := get_tree().root.find_child("CRT", true, false)
	if crt_overlay and crt_overlay.has_method("setup_player"):
		crt_overlay.setup_player(player_instance)

func _get_default_fallback_map() -> String:
	return """
pulls: 4
bugs: 2

###############
#P....#.......#
#..B..#...*...#
#.....#.......#
#~~~~~#...~~~~#
#.....#.......#
#..*......W...#
###############
"""
