extends Node

## Centralized Background Music & Sound Effects Manager for TONGUE-TIED.
## Autoload: MusicManager
## Handles background music playlists (Menu & Game) with smooth cross-fading and global SFX.

signal track_changed(track_index: int, track_path: String)

enum PlaylistType {
	MENU,
	GAME
}

const MENU_PLAYLIST_PATHS: Array[String] = [
	"res://AUDIO/backgrounds/main_menu/main_menu_song1.ogg",
	"res://AUDIO/backgrounds/main_menu/main_menu_song2.ogg"
]

const GAME_PLAYLIST_PATHS: Array[String] = [
	"res://AUDIO/backgrounds/background_music1.mp3",
	"res://AUDIO/backgrounds/background_music2.mp3",
	"res://AUDIO/backgrounds/background_music3.mp3"
]

const PUSH_SFX_PATH: String = "res://AUDIO/backgrounds/push_sfx.mp3"
const COLLECT_BUG_SFX_PATH: String = "res://AUDIO/backgrounds/main_menu/collectbug_sound,ogg.ogg"

const DEFAULT_BGM_VOLUME_DB: float = -6.0
const MENU_BGM_VOLUME_DB: float = 6.0 # Lowered by 8 dB (between 5 and 10 dB)
const FADE_DURATION: float = 1.0

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

var _menu_playlist: Array[AudioStream] = []
var _game_playlist: Array[AudioStream] = []

var _current_playlist_type: PlaylistType = PlaylistType.MENU
var _current_index: int = -1
var _fade_tween: Tween
var _push_sfx_stream: AudioStream = null
var _collect_bug_sfx_stream: AudioStream = null
var _is_paused_by_user: bool = false

func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Setup BGM AudioStreamPlayer
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

	# 2. Setup SFX AudioStreamPlayer
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "PushSFXPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	# 3. Preload Menu and Game playlist audio streams
	for path in MENU_PLAYLIST_PATHS:
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream:
				_menu_playlist.append(stream)

	for path in GAME_PLAYLIST_PATHS:
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream:
				_game_playlist.append(stream)

	# 4. Preload SFX
	if ResourceLoader.exists(PUSH_SFX_PATH):
		_push_sfx_stream = load(PUSH_SFX_PATH) as AudioStream

	if ResourceLoader.exists(COLLECT_BUG_SFX_PATH):
		_collect_bug_sfx_stream = load(COLLECT_BUG_SFX_PATH) as AudioStream

	# 5. Listen for settings updates from GameManager
	if GameManager:
		GameManager.settings_changed.connect(_on_settings_changed)

	# 6. Start playing Menu playlist if music is enabled
	play_menu_music(false)

func _get_active_playlist() -> Array[AudioStream]:
	match _current_playlist_type:
		PlaylistType.MENU:
			return _menu_playlist
		PlaylistType.GAME:
			return _game_playlist
	return _menu_playlist

func _get_active_playlist_paths() -> Array[String]:
	match _current_playlist_type:
		PlaylistType.MENU:
			return MENU_PLAYLIST_PATHS
		PlaylistType.GAME:
			return GAME_PLAYLIST_PATHS
	return MENU_PLAYLIST_PATHS

## Switch to Menu music playlist with random track selection. If already playing Menu music, continues uninterrupted.
func play_menu_music(fade: bool = true) -> void:
	if _current_playlist_type == PlaylistType.MENU and _bgm_player and _bgm_player.playing:
		return
	_current_playlist_type = PlaylistType.MENU
	_current_index = -1
	var random_index: int = randi() % _menu_playlist.size() if _menu_playlist.size() > 0 else 0
	play_track(random_index, fade)

## Switch to In-Game music playlist. If already playing Game music, continues uninterrupted.
func play_game_music(fade: bool = true) -> void:
	if _current_playlist_type == PlaylistType.GAME and _bgm_player and _bgm_player.playing:
		return
	_current_playlist_type = PlaylistType.GAME
	_current_index = -1
	play_track(0, fade)

func _get_target_volume_db() -> float:
	if GameManager and "music_enabled" in GameManager and not GameManager.music_enabled:
		return -80.0
	if _current_playlist_type == PlaylistType.MENU:
		return MENU_BGM_VOLUME_DB
	return DEFAULT_BGM_VOLUME_DB

func _on_settings_changed() -> void:
	_apply_settings()

func _apply_settings() -> void:
	if not _bgm_player:
		return
	
	var enabled: bool = true
	if GameManager and "music_enabled" in GameManager:
		enabled = GameManager.music_enabled
	
	if not enabled:
		_bgm_player.volume_db = -80.0
	else:
		_bgm_player.volume_db = _get_target_volume_db()
		var active_list := _get_active_playlist()
		if not _bgm_player.playing and not _is_paused_by_user and active_list.size() > 0:
			if _current_index >= 0:
				_bgm_player.play()
			else:
				play_menu_music(false)

## Plays a specific track from the active playlist by index with optional smooth cross-fade.
func play_track(index: int, fade: bool = true) -> void:
	var active_list := _get_active_playlist()
	var active_paths := _get_active_playlist_paths()
	if active_list.is_empty():
		return
	
	index = index % active_list.size()
	if index < 0:
		index += active_list.size()
	
	_current_index = index
	var next_stream: AudioStream = active_list[_current_index]
	var target_db: float = _get_target_volume_db()

	if _current_index < active_paths.size():
		track_changed.emit(_current_index, active_paths[_current_index])

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	if fade and _bgm_player.playing and _bgm_player.volume_db > -70.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_bgm_player, "volume_db", -80.0, FADE_DURATION * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_fade_tween.tween_callback(func():
			_bgm_player.stream = next_stream
			_bgm_player.play()
		)
		_fade_tween.tween_property(_bgm_player, "volume_db", target_db, FADE_DURATION * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_bgm_player.stream = next_stream
		_bgm_player.volume_db = target_db
		_bgm_player.play()

## Advances to the next track in the active playlist.
func next_track() -> void:
	var active_list := _get_active_playlist()
	if active_list.is_empty():
		return
	if _current_playlist_type == PlaylistType.MENU and active_list.size() > 1:
		var next_idx: int = randi() % active_list.size()
		while next_idx == _current_index:
			next_idx = randi() % active_list.size()
		play_track(next_idx)
	else:
		play_track((_current_index + 1) % active_list.size())

## Moves to the previous track in the active playlist.
func previous_track() -> void:
	var active_list := _get_active_playlist()
	if active_list.is_empty():
		return
	play_track((_current_index - 1 + active_list.size()) % active_list.size())

## Called automatically when the active track ends to play the next one seamlessly.
func _on_bgm_finished() -> void:
	next_track()

## Plays the push SFX (used when pulling the frog forward).
func play_push_sfx(pitch_variation: float = 0.06) -> void:
	if not _push_sfx_stream:
		return
	
	if GameManager and "sfx_enabled" in GameManager and not GameManager.sfx_enabled:
		return
	
	if _sfx_player:
		_sfx_player.stream = _push_sfx_stream
		_sfx_player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		_sfx_player.volume_db = 8.0
		_sfx_player.play()

## Plays the bug collection SFX.
func play_collect_bug_sfx(pitch_variation: float = 0.05) -> void:
	if not _collect_bug_sfx_stream:
		return
	if GameManager and "sfx_enabled" in GameManager and not GameManager.sfx_enabled:
		return
	play_sfx(_collect_bug_sfx_stream, 8.0, randf_range(1.0 - pitch_variation, 1.0 + pitch_variation))

## Play an arbitrary one-shot SFX stream through a temporary or dedicated player.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not stream:
		return
	if GameManager and "sfx_enabled" in GameManager and not GameManager.sfx_enabled:
		return
	
	var one_shot := AudioStreamPlayer.new()
	one_shot.bus = "Master"
	one_shot.stream = stream
	one_shot.volume_db = volume_db
	one_shot.pitch_scale = pitch
	one_shot.finished.connect(one_shot.queue_free)
	add_child(one_shot)
	one_shot.play()

## Pause the background music.
func pause_music() -> void:
	_is_paused_by_user = true
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stream_paused = true

## Resume the background music.
func resume_music() -> void:
	_is_paused_by_user = false
	if _bgm_player:
		if _bgm_player.stream_paused:
			_bgm_player.stream_paused = false
		elif not _bgm_player.playing and _get_active_playlist().size() > 0:
			play_track(_current_index if _current_index >= 0 else 0, false)

## Stop background music completely.
func stop_music() -> void:
	if _bgm_player:
		_bgm_player.stop()

## Check if background music is actively playing.
func is_music_playing() -> bool:
	return _bgm_player != null and _bgm_player.playing and not _bgm_player.stream_paused

## Returns the filename of the current playlist track.
func get_current_track_name() -> String:
	var active_paths := _get_active_playlist_paths()
	if _current_index >= 0 and _current_index < active_paths.size():
		return active_paths[_current_index].get_file()
	return ""
