extends Node2D

@onready var level_holder: Node2D = $LevelHolder
@onready var crt_overlay: Node = $CRT
@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	if bgm_player and has_node("/root/MusicManager"):
		bgm_player.stop()
		bgm_player.stream = null
	if has_node("/root/MusicManager"):
		MusicManager.play_game_music()
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.settings_changed.connect(_update_audio_settings)
	_update_audio_settings()
	GameManager.setup_level_container(level_holder)
	_bind_player_to_crt()

	var transition_layer := get_node_or_null("/root/TransitionLayer")
	if transition_layer and transition_layer.has_method("transition_in"):
		transition_layer.transition_in()

func _update_audio_settings() -> void:
	if bgm_player and not has_node("/root/MusicManager"):
		bgm_player.volume_db = 0.0 if GameManager.music_enabled else -80.0


func _on_level_changed(_index: int) -> void:
	_bind_player_to_crt()

func _bind_player_to_crt() -> void:
	await get_tree().process_frame
	var player := level_holder.find_child("Player", true, false) as Frog
	if player and crt_overlay and crt_overlay.has_method("setup_player"):
		crt_overlay.setup_player(player)
