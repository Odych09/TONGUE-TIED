extends Control

## Background Layers Animator for RoyalInfinity
## Handles organic multi-layer parallax sway, tree wind dynamics, living bird flight,
## and subtle interactive pointer parallax.

@export_group("Animation Speeds & Amplitudes")
@export var overall_speed: float = 1.0
@export var sway_intensity: float = 1.0
@export var wind_gust_enabled: bool = true
@export var birds_animated: bool = true
@export var pointer_parallax_enabled: bool = true
@export var parallax_intensity: float = 1.0

# Layer nodes
@onready var sky_layer: Control = get_node_or_null("1")
@onready var far_bg_layer: Control = get_node_or_null("3")
@onready var houses_layer: Control = get_node_or_null("4")
@onready var trees_cars_layer: Control = get_node_or_null("6")
@onready var fence_layer: Control = get_node_or_null("5")
@onready var road_layer: Control = get_node_or_null("2")
@onready var bird3_layer: Control = get_node_or_null("7")
@onready var bird2_layer: Control = get_node_or_null("8")
@onready var bird1_layer: Control = get_node_or_null("9")

# Transform storage
var _base_positions: Dictionary = {}
var _base_scales: Dictionary = {}

# Time & Dynamics
var _time: float = 0.0
var _wind_timer: float = 0.0
var _wind_gust: float = 0.0
var _target_wind: float = 0.0
var _next_gust_in: float = 4.0

# Interactive parallax
var _target_parallax: Vector2 = Vector2.ZERO
var _current_parallax: Vector2 = Vector2.ZERO
var _idle_pointer_timer: float = 0.0

func _ready() -> void:
	# Small initial delay so layout rects resolve cleanly
	call_deferred("_setup_layers")

func _setup_layers() -> void:
	# Standard screen reference center
	var screen_center := Vector2(960.0, 540.0)

	# Store base positions and initialize overscan scale
	# to ensure zero edge clipping during parallax or sways
	var all_layers := [
		sky_layer, far_bg_layer, houses_layer, trees_cars_layer,
		fence_layer, road_layer, bird3_layer, bird2_layer, bird1_layer
	]

	for layer in all_layers:
		if is_instance_valid(layer):
			_base_positions[layer] = layer.position
			_base_scales[layer] = layer.scale
			layer.pivot_offset = screen_center

	# Layer-specific pivot optimizations:
	# Trees & cars: pivot at ground level for natural trunk/branch sway
	if is_instance_valid(trees_cars_layer):
		trees_cars_layer.pivot_offset = Vector2(960.0, 1080.0)
		trees_cars_layer.scale = Vector2(1.03, 1.03)

	# Far and midground layers: slight overscan so sways never show empty margins
	for layer in [sky_layer, far_bg_layer, houses_layer, fence_layer, road_layer]:
		if is_instance_valid(layer):
			layer.scale = Vector2(1.025, 1.025)

	# Birds: pivot near their specific bounding centers for natural banking rotation
	# bird1: high left (center ~ 418, 60)
	if is_instance_valid(bird1_layer):
		bird1_layer.pivot_offset = Vector2(418.0, 60.0)

	# bird2: mid right (center ~ 1248, 492)
	if is_instance_valid(bird2_layer):
		bird2_layer.pivot_offset = Vector2(1248.0, 492.0)

	# bird3: high right (center ~ 1464, 98)
	if is_instance_valid(bird3_layer):
		bird3_layer.pivot_offset = Vector2(1464.0, 98.0)

func _input(event: InputEvent) -> void:
	if not pointer_parallax_enabled:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var vp_size := get_viewport_rect().size
		if vp_size.x > 0 and vp_size.y > 0:
			var ev_pos: Vector2 = event.position
			var normalized: Vector2 = (ev_pos - (vp_size * 0.5)) / (vp_size * 0.5)
			_target_parallax = normalized.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
			_idle_pointer_timer = 0.0

func _process(delta: float) -> void:
	_time += delta * overall_speed
	_update_wind(delta)
	_update_parallax(delta)

	_animate_sky()
	_animate_far_bg()
	_animate_houses()
	_animate_trees_and_cars()
	_animate_fence()
	_animate_road()

	if birds_animated:
		_animate_birds()

func _update_wind(delta: float) -> void:
	if not wind_gust_enabled:
		_wind_gust = 0.0
		return

	_wind_timer += delta
	if _wind_timer >= _next_gust_in:
		_wind_timer = 0.0
		_target_wind = randf_range(0.6, 1.0)
		_next_gust_in = randf_range(6.0, 10.0)

	# Smooth wind envelope attack and release
	_target_wind = move_toward(_target_wind, 0.0, delta * 0.45)
	_wind_gust = lerpf(_wind_gust, _target_wind, delta * 2.8)

func _update_parallax(delta: float) -> void:
	if pointer_parallax_enabled:
		_idle_pointer_timer += delta
		if _idle_pointer_timer > 3.0:
			# Slowly drift back toward center when pointer is idle
			_target_parallax = _target_parallax.lerp(Vector2.ZERO, delta * 0.8)

		_current_parallax = _current_parallax.lerp(_target_parallax * parallax_intensity, delta * 3.0)
	else:
		_current_parallax = Vector2.ZERO

# --- Layer Animation Methods ---

func _animate_sky() -> void:
	if not is_instance_valid(sky_layer) or not _base_positions.has(sky_layer):
		return

	var base_pos: Vector2 = _base_positions[sky_layer]
	var drift_x := sin(_time * 0.22) * 5.0
	var drift_y := cos(_time * 0.18) * 3.0

	sky_layer.position = base_pos + Vector2(drift_x, drift_y) + (_current_parallax * 4.0)

	# Gentle day/atmosphere light breath
	var warmth_pulse := (sin(_time * 0.35) + 1.0) * 0.5
	sky_layer.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.02, 0.985, 0.96), warmth_pulse)

func _animate_far_bg() -> void:
	if not is_instance_valid(far_bg_layer) or not _base_positions.has(far_bg_layer):
		return

	var base_pos: Vector2 = _base_positions[far_bg_layer]
	var sway_x := (sin(_time * 0.6) * 3.5 + sin(_time * 1.15) * 1.5) * sway_intensity
	var sway_y := cos(_time * 0.48) * 2.0 * sway_intensity

	far_bg_layer.position = base_pos + Vector2(sway_x, sway_y) + (_current_parallax * 8.0)

func _animate_houses() -> void:
	if not is_instance_valid(houses_layer) or not _base_positions.has(houses_layer):
		return

	var base_pos: Vector2 = _base_positions[houses_layer]
	var sway_x := (sin(_time * 0.8 + 1.0) * 5.5 + sin(_time * 1.45 + 0.5) * 2.5) * sway_intensity
	var sway_y := cos(_time * 0.65 + 0.8) * 3.2 * sway_intensity

	houses_layer.position = base_pos + Vector2(sway_x, sway_y) + (_current_parallax * 14.0)

func _animate_trees_and_cars() -> void:
	if not is_instance_valid(trees_cars_layer) or not _base_positions.has(trees_cars_layer):
		return

	var base_pos: Vector2 = _base_positions[trees_cars_layer]

	# Multi-frequency organic breeze + wind gust surge
	var sway_x := (sin(_time * 1.05 + 2.0) * 7.5 + sin(_time * 2.1) * 3.0 + (_wind_gust * 15.0)) * sway_intensity
	var sway_y := cos(_time * 0.85 + 1.4) * 3.8 * sway_intensity

	# Ground-rooted rotational sway (swaying trees in the wind)
	var sway_rot := (sin(_time * 1.05 + 1.8) * 0.005 + sin(_time * 2.4) * 0.0025 + (_wind_gust * 0.010)) * sway_intensity

	trees_cars_layer.position = base_pos + Vector2(sway_x, sway_y) + (_current_parallax * 22.0)
	trees_cars_layer.rotation = sway_rot

func _animate_fence() -> void:
	if not is_instance_valid(fence_layer) or not _base_positions.has(fence_layer):
		return

	var base_pos: Vector2 = _base_positions[fence_layer]
	var sway_x := (sin(_time * 0.9 + 2.5) * 3.0) * sway_intensity
	var sway_y := (cos(_time * 0.75 + 2.0) * 1.5) * sway_intensity

	fence_layer.position = base_pos + Vector2(sway_x, sway_y) + (_current_parallax * 28.0)

func _animate_road() -> void:
	if not is_instance_valid(road_layer) or not _base_positions.has(road_layer):
		return

	var base_pos: Vector2 = _base_positions[road_layer]
	# Very firm, grounded foreground
	var sway_x := (sin(_time * 0.65 + 3.0) * 1.5) * sway_intensity
	var sway_y := (cos(_time * 0.55 + 2.5) * 0.8) * sway_intensity

	road_layer.position = base_pos + Vector2(sway_x, sway_y) + (_current_parallax * 18.0)

func _animate_birds() -> void:
	# --- Bird 1 (High left, small soaring bird) ---
	if is_instance_valid(bird1_layer) and _base_positions.has(bird1_layer):
		var base_pos: Vector2 = _base_positions[bird1_layer]
		var bob_y := sin(_time * 2.3) * 9.0
		var glide_x := cos(_time * 0.45) * 42.0 + (_wind_gust * 10.0)
		var bank_rot := sin(_time * 0.45) * 0.045 + (_wind_gust * 0.03)
		var flap_scale := 1.0 + sin(_time * 4.8) * 0.035

		bird1_layer.position = base_pos + Vector2(glide_x, bob_y) + (_current_parallax * 10.0)
		bird1_layer.rotation = bank_rot
		bird1_layer.scale = Vector2(1.0, flap_scale)

	# --- Bird 2 (Mid right, closer soaring bird) ---
	if is_instance_valid(bird2_layer) and _base_positions.has(bird2_layer):
		var base_pos: Vector2 = _base_positions[bird2_layer]
		var bob_y := sin(_time * 1.85 + 1.5) * 15.0
		var glide_x := sin(_time * 0.36 + 0.8) * 58.0 + (_wind_gust * 18.0)
		var bank_rot := -cos(_time * 0.36 + 0.8) * 0.06 + (_wind_gust * 0.04)
		var flap_scale := 1.0 + sin(_time * 3.9 + 1.2) * 0.045

		bird2_layer.position = base_pos + Vector2(glide_x, bob_y) + (_current_parallax * 15.0)
		bird2_layer.rotation = bank_rot
		bird2_layer.scale = Vector2(1.0, flap_scale)

	# --- Bird 3 (High right, distant thermals) ---
	if is_instance_valid(bird3_layer) and _base_positions.has(bird3_layer):
		var base_pos: Vector2 = _base_positions[bird3_layer]
		var bob_y := sin(_time * 2.1 + 3.0) * 7.5
		var glide_x := cos(_time * 0.52 + 2.0) * 34.0 + (_wind_gust * 8.0)
		var bank_rot := sin(_time * 0.52 + 2.0) * 0.035 + (_wind_gust * 0.02)
		var flap_scale := 1.0 + sin(_time * 4.4 + 2.0) * 0.03

		bird3_layer.position = base_pos + Vector2(glide_x, bob_y) + (_current_parallax * 8.0)
		bird3_layer.rotation = bank_rot
		bird3_layer.scale = Vector2(1.0, flap_scale)
