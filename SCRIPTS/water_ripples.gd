extends Node2D

@export var ripple_count: int = 3
@export var base_radius: float = 130.0
@export var max_radius: float = 380.0
@export var aspect_ratio: float = 0.36
@export var ripple_speed: float = 0.45
@export var line_width: float = 2.6
@export var ripple_color: Color = Color(0.48, 0.90, 0.82, 0.45)

var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta * ripple_speed
	queue_redraw()

func _draw() -> void:
	for i in range(ripple_count):
		# Each ring is spaced evenly across the lifecycle 0.0 -> 1.0
		var phase := fposmod(elapsed + float(i) / float(ripple_count), 1.0)
		var current_r := lerpf(base_radius, max_radius, phase)
		
		# Alpha fades in quickly at start, then fades out smoothly to edge
		var alpha := sin(phase * PI) * ripple_color.a
		var col := Color(ripple_color.r, ripple_color.g, ripple_color.b, alpha)
		
		# Draw perspective-flattened elliptical water ring
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, aspect_ratio))
		draw_arc(Vector2.ZERO, current_r, 0.0, TAU, 64, col, line_width, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))
