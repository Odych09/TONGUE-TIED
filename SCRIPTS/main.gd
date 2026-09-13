extends Node2D

@onready var level_holder: Node2D = $LevelHolder
@onready var crt_overlay: Node = $CRT

func _ready() -> void:
	GameManager.setup_level_container(level_holder)
	GameManager.level_changed.connect(_on_level_changed)
	_bind_player_to_crt()

func _on_level_changed(_index: int) -> void:
	_bind_player_to_crt()

func _bind_player_to_crt() -> void:
	await get_tree().process_frame
	var player := level_holder.find_child("Player", true, false) as Frog
	if player and crt_overlay and crt_overlay.has_method("setup_player"):
		crt_overlay.setup_player(player)
