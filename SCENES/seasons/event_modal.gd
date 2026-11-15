extends Control
class_name EventModal

## Controller for the Seasonal Event Modal in main_home.
## Manages live countdown to Dec 15, 2026, LIVE badge pulsing,
## idle floating animations, hover feedback, and scene transitions to Royal Infinity.

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
@export var float_amplitude: float = 3.5
## Float duration in seconds
@export var float_duration: float = 2.2

# Node references (cached via get_node_or_null for safety)
@onready var card_panel: PanelContainer = get_node_or_null("CardPanel")
@onready var play_button: Button = get_node_or_null("CardPanel/Margin/VBox/PlayEventButton")
@onready var live_badge: PanelContainer = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/LiveBadge")
@onready var live_dot: Label = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/LiveBadge/Margin/Content/LiveDot")
@onready var live_text: Label = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/LiveBadge/Margin/Content/LiveText")
@onready var timer_badge: PanelContainer = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/TimerBadge")
@onready var timer_label: Label = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/TimerBadge/Margin/Content/TimerLabel")
@onready var timer_icon: Label = get_node_or_null("CardPanel/Margin/VBox/ArtFrame/TopBar/HBox/TimerBadge/Margin/Content/TimerIcon")
@onready var back_button: Button = get_node_or_null("CardPanel/Margin/BackButton")

# State & Tweens
var _float_tween: Tween = null
var _pulse_tween: Tween = null
var _hover_tween: Tween = null
var _timer_update_accum: float = 0.0
var _is_transitioning: bool = false
var _events_btn: Button = null
var _base_pos_y: float = 0.0

# Audio players
var _hover_sfx: AudioStreamPlayer = null
var _click_sfx: AudioStreamPlayer = null
var _back_sfx: AudioStreamPlayer = null

func _ready() -> void:
	_setup_audio()
	_setup_card_pivot()
	_update_countdown()
	_start_live_pulse_animation()

	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		play_button.mouse_entered.connect(_play_hover)

	if is_instance_valid(back_button):
		back_button.pressed.connect(_on_back_pressed)
		_hook_btn_animations(back_button)

	# Connect to parent's eventsButton if present
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		_events_btn = parent_node.get_node_or_null("UI/RightBar/eventsButton") as Button
		if is_instance_valid(_events_btn):
			_events_btn.pressed.connect(_on_events_button_pressed)
			_hook_btn_animations(_events_btn)

	# If opened initially in editor/debug, trigger animations
	if visible:
		_animate_in()

func _process(delta: float) -> void:
	if not visible:
		return
	_timer_update_accum += delta
	if _timer_update_accum >= 1.0:
		_timer_update_accum = 0.0
		_update_countdown()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_modal()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_instance_valid(_events_btn) and _events_btn.get_global_rect().has_point(event.global_position):
			return
		if is_instance_valid(card_panel):
			if not card_panel.get_global_rect().has_point(event.global_position):
				close_modal()

func _setup_card_pivot() -> void:
	if not is_instance_valid(card_panel):
		return
	card_panel.pivot_offset = card_panel.size * 0.5
	if not card_panel.resized.is_connected(_on_card_resized):
		card_panel.resized.connect(_on_card_resized)

func _on_card_resized() -> void:
	if is_instance_valid(card_panel):
		card_panel.pivot_offset = card_panel.size * 0.5

func _setup_audio() -> void:
	var current_scene := get_tree().current_scene
	if is_instance_valid(current_scene):
		_hover_sfx = current_scene.get_node_or_null("Audio/HoverSFX")
		_click_sfx = current_scene.get_node_or_null("Audio/ClickSFX")
		_back_sfx = current_scene.get_node_or_null("Audio/BackSFX")

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
		timer_label.text = "Event Ended"
		if is_instance_valid(play_button):
			play_button.disabled = true
			play_button.text = "EVENT ENDED"
		return

	var days: int = diff / 86400
	var hours: int = (diff % 86400) / 3600
	var minutes: int = (diff % 3600) / 60
	var seconds: int = diff % 60

	if days > 0:
		timer_label.text = "Ends 15 Dec • %dd %02dh %02dm %02ds" % [days, hours, minutes, seconds]
	else:
		timer_label.text = "Ends 15 Dec • %02dh %02dm %02ds" % [hours, minutes, seconds]

func _start_live_pulse_animation() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	_pulse_tween = create_tween().set_loops()

	# Pulsing alpha glow on the live dot
	if is_instance_valid(live_dot):
		_pulse_tween.tween_property(live_dot, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_property(live_dot, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Subtle breathing on the live badge
	if is_instance_valid(live_badge):
		live_badge.pivot_offset = live_badge.size * 0.5
		var badge_tw := create_tween().set_loops()
		badge_tw.tween_property(live_badge, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		badge_tw.tween_property(live_badge, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_float_animation() -> void:
	if not enable_floating or not is_instance_valid(card_panel):
		return
	if _float_tween and _float_tween.is_valid():
		_float_tween.kill()
	_base_pos_y = card_panel.position.y
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(card_panel, "position:y", _base_pos_y - float_amplitude, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(card_panel, "position:y", _base_pos_y + (float_amplitude * 0.7), float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func open_modal() -> void:
	_play_click()
	visible = true
	_update_countdown()
	_animate_in()

func close_modal() -> void:
	_play_back()
	_animate_out()

func _on_events_button_pressed() -> void:
	if visible:
		close_modal()
	else:
		open_modal()

func _on_back_pressed() -> void:
	close_modal()

func _animate_in() -> void:
	if not is_instance_valid(card_panel):
		return
	card_panel.pivot_offset = card_panel.size * 0.5
	card_panel.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(card_panel, "scale", Vector2.ONE, 0.28)
	await tw.finished
	_start_float_animation()

func _animate_out() -> void:
	if _float_tween and _float_tween.is_valid():
		_float_tween.kill()
	if is_instance_valid(card_panel):
		card_panel.position.y = _base_pos_y if _base_pos_y != 0.0 else card_panel.position.y

	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	if is_instance_valid(card_panel):
		tw.tween_property(card_panel, "scale", Vector2(0.88, 0.88), 0.18)
	await tw.finished
	visible = false

func _hook_btn_animations(btn: Control) -> void:
	if not is_instance_valid(btn):
		return
	var default_scale: Vector2 = btn.scale
	btn.pivot_offset = btn.custom_minimum_size * 0.5 if btn.custom_minimum_size != Vector2.ZERO else btn.size * 0.5
	btn.mouse_entered.connect(func():
		_play_hover()
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", default_scale * 1.05, 0.14)
	)
	btn.mouse_exited.connect(func():
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", default_scale, 0.14)
	)

func _play_hover() -> void:
	if is_instance_valid(_hover_sfx):
		_hover_sfx.pitch_scale = randf_range(0.96, 1.08)
		_hover_sfx.play()

func _play_click() -> void:
	if is_instance_valid(_click_sfx):
		_click_sfx.play()

func _play_back() -> void:
	if is_instance_valid(_back_sfx):
		_back_sfx.play()

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
	if is_instance_valid(card_panel):
		var tw := create_tween()
		tw.tween_property(card_panel, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK)

	# Transition out if TransitionLayer exists
	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_out"):
		await transition_layer.transition_out()

	get_tree().change_scene_to_file(target_scene)
