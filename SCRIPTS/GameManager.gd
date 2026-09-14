extends Node

signal level_changed(level_index: int)
signal game_completed

@export var levels: Array[PackedScene] = [
	preload("uid://blcmaj1t2lsax"),
	preload("uid://dnwf35rfeye1v"),
	preload("uid://djfmmw7uj4s3g"),
	preload("uid://dobdlhfuyt1ch"),
	preload("uid://bv6kn6ymg25ab"),
	preload("uid://nouh0jhg46jy"),
	preload("uid://bpq0011blrqpn"),
	preload("uid://cxm1tr8v0auuf"),
	preload("uid://cgw8ien5i4353"),
	preload("uid://cwsog6cunrn5u"),
	preload("uid://c3cn4qsnmwell"),
	#missing where is 12??
	preload("uid://6p3sgtylm6dn"),
	preload("uid://ctyp6d243bhfo"),
	preload("uid://etlbcg3fcwcg"),
	preload("uid://c1p5den7ox4hc")
	
]

var current_level_index: int = 0
var current_level_instance: Node = null
var level_container: Node = null

func setup_level_container(container: Node) -> void:
	level_container = container
	load_level(current_level_index, false)

func next_level() -> void:
	load_level(current_level_index + 1, true)

func restart_level() -> void:
	load_level(current_level_index, true)

func load_level(index: int, use_transition: bool = true) -> void:
	if index >= levels.size():
		emit_signal("game_completed")
		get_tree().quit(0)
		return
		
	current_level_index = index

	if use_transition and TransitionLayer:
		await TransitionLayer.transition_out()

	if is_instance_valid(current_level_instance):
		current_level_instance.queue_free()

	current_level_instance = levels[current_level_index].instantiate()
	if level_container:
		level_container.add_child(current_level_instance)

	emit_signal("level_changed", current_level_index)

	if use_transition and TransitionLayer:
		await TransitionLayer.transition_in()
