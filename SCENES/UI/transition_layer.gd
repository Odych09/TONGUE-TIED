extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.visible = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func transition_out() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.visible = true
	var mat := color_rect.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func transition_in() -> void:
	var mat := color_rect.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	color_rect.visible = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

