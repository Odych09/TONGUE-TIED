extends Control

@onready var play_button: Button = get_node_or_null("BottomAction/PlayButton")
@onready var back_button: Button = get_node_or_null("TopBar/BackButton")

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.mouse_entered.connect(_on_button_hover.bind(play_button))
		play_button.mouse_exited.connect(_on_button_unhover.bind(play_button))
		play_button.pivot_offset = play_button.size * 0.5
		play_button.resized.connect(func(): if play_button: play_button.pivot_offset = play_button.size * 0.5)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.mouse_entered.connect(_on_button_hover.bind(back_button))
		back_button.mouse_exited.connect(_on_button_unhover.bind(back_button))
		back_button.pivot_offset = back_button.size * 0.5
		back_button.resized.connect(func(): if back_button: back_button.pivot_offset = back_button.size * 0.5)

func _on_button_hover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_play_pressed() -> void:
	if play_button:
		play_button.disabled = true
		var tw := create_tween()
		tw.tween_property(play_button, "scale", Vector2(0.94, 0.94), 0.08)
		tw.tween_property(play_button, "scale", Vector2(1.0, 1.0), 0.1)

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file("res://SCENES/seasons/RoyalInfinityGame.tscn")

	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func _on_back_pressed() -> void:
	if back_button:
		back_button.disabled = true
		var tw := create_tween()
		tw.tween_property(back_button, "scale", Vector2(0.94, 0.94), 0.08)
		tw.tween_property(back_button, "scale", Vector2(1.0, 1.0), 0.1)

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file("res://SCENES/main_home.tscn")

	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()
