extends Control

## Dedicated controller for the Seasonal Event Card in main_home.
## Manages live countdown to Dec 15, idle floating animations, hover lift,
## sound feedback, and scene transitions to Royal Infinity.

@export_group("Event Schedule")
## Target end year
@export var end_year: int = 2026
## Target end month (1-12, December = 12)
@export var end_month: int = 12
## Target end day (1-31, ends Dec 15)
@export var end_day: int = 15
## Target end hour (0-23)
@export var end_hour: int = 23
## Target end minute (0-59)
@export var end_minute: int = 59
## Target end second (0-59)
@export var end_second: int = 59

@export_group("Navigation")
## Scene to launch when PLAY EVENT is pressed
@export_file("*.tscn") var target_scene: String = "res://SCENES/seasons/RoyalInfinity.tscn"

@export_group("Animation")
## Enable subtle organic idle floating
@export var enable_floating: bool = true
## Float bob amplitude in pixels
@export var float_amplitude: float = 4.0
## Float duration in seconds
@export var float_duration: float = 2.2

# Node references
@onready var card_panel: PanelContainer = get_node_or_null("CardPanel")
@onready var timer_label: Label = get_node_or_null("CardPanel/Margin/VBox/TimerRow/TimerBadge/TimerMargin/TimerLabel")
@onready var play_button: Button = get_node_or_null("CardPanel/Margin/VBox/PlayEventButton")

# State & Tweens
var _float_tween: Tween = null
var _hover_tween: Tween = null
var _base_pos_y: float = 0.0
var _timer_update_accum: float = 0.0
var _is_transitioning: bool = false

# Audio players
var _hover_sfx: AudioStreamPlayer = null
var _click_sfx: AudioStreamPlayer = null

func _ready() -> void:
	# Center pivot for clean scaling animations
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.5) if size != Vector2.ZERO else Vector2(170.0, 225.0)
	resized.connect(func():
		pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	)

	_setup_audio()
	_update_countdown()

	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		_hook_btn_animations(play_button)

	if is_instance_valid(card_panel):
		card_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_play_pressed()
		)
		card_panel.mouse_entered.connect(_on_hover)
		card_panel.mouse_exited.connect(_on_unhover)

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

	_start_float_animation()

func _process(delta: float) -> void:
	_timer_update_accum += delta
	if _timer_update_accum >= 1.0:
		_timer_update_accum = 0.0
		_update_countdown()

func _setup_audio() -> void:
	# Attempt to reuse existing audio players from MainHome HUD
	var current_scene := get_tree().current_scene
	if is_instance_valid(current_scene):
		_hover_sfx = current_scene.get_node_or_null("Audio/HoverSFX")
		_click_sfx = current_scene.get_node_or_null("Audio/ClickSFX")

	# Safe fallback if players are missing
	if not _hover_sfx:
		_hover_sfx = AudioStreamPlayer.new()
		var stream = load("res://AUDIO/ui_hover.wav")
		if stream:
			_hover_sfx.stream = stream
		add_child(_hover_sfx)

	if not _click_sfx:
		_click_sfx = AudioStreamPlayer.new()
		var stream = load("res://AUDIO/ui_click.wav")
		if stream:
			_click_sfx.stream = stream
		add_child(_click_sfx)

func _get_target_timestamp() -> int:
	var date_dict := {
		"year": end_year,
		"month": end_month,
		"day": end_day,
		"hour": end_hour,
		"minute": end_minute,
		"second": end_second
	}
	return int(Time.get_unix_time_from_datetime_dict(date_dict))

func _update_countdown() -> void:
	if not is_instance_valid(timer_label):
		return

	var now: int = int(Time.get_unix_time_from_system())
	var target: int = _get_target_timestamp()
	var diff: int = target - now

	if diff <= 0:
		timer_label.text = "⏳ Event Ended"
		if is_instance_valid(play_button):
			play_button.disabled = true
			play_button.text = "EVENT ENDED"
		return

	var days: int = diff / 86400
	var hours: int = (diff % 86400) / 3600
	var minutes: int = (diff % 3600) / 60
	var seconds: int = diff % 60

	if days > 0:
		timer_label.text = "⏳ Ends in: %dd %02dh %02dm" % [days, hours, minutes]
	else:
		timer_label.text = "⏳ Ends in: %02dh %02dm %02ds" % [hours, minutes, seconds]

func _start_float_animation() -> void:
	if not enable_floating:
		return
	_base_pos_y = position.y
	if _float_tween and _float_tween.is_valid():
		_float_tween.kill()
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(self, "position:y", _base_pos_y - float_amplitude, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(self, "position:y", _base_pos_y + (float_amplitude * 0.7), float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_hover() -> void:
	if _is_transitioning:
		return
	_play_hover()
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.16)

func _on_unhover() -> void:
	if _is_transitioning:
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.16)

func _hook_btn_animations(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.custom_minimum_size * 0.5 if btn.custom_minimum_size != Vector2.ZERO else btn.size * 0.5
	btn.mouse_entered.connect(func():
		_play_hover()
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.14)
	)
	btn.mouse_exited.connect(func():
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.14)
	)

func _play_hover() -> void:
	if is_instance_valid(_hover_sfx):
		_hover_sfx.pitch_scale = randf_range(0.96, 1.08)
		_hover_sfx.play()

func _play_click() -> void:
	if is_instance_valid(_click_sfx):
		_click_sfx.play()

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_play_click()

	if is_instance_valid(play_button):
		play_button.disabled = true

	if _float_tween and _float_tween.is_valid():
		_float_tween.kill()

	# Punchy squash & bounce
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK)

	# Transition out
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file(target_scene)
