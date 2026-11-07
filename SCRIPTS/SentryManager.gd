extends Node

## SentryManager
## Autonomous, non-intrusive observer for Sentry SDK.
## Automatically populates Sentry User context and Gameplay Breadcrumbs
## by listening to existing autoload signals without modifying any gameplay code.

var _last_scene_name: String = ""

func _ready() -> void:
	if not ClassDB.class_exists(&"SentrySDK"):
		print("[SentryManager] SentrySDK not available in ClassDB, skipping.")
		return

	# Defer connection to ensure other autoload nodes have initialized
	call_deferred("_initialize_observers")

func _initialize_observers() -> void:
	if not is_inside_tree():
		return
	_connect_lootlocker()
	_connect_gamemanager()
	_connect_scene_tracker()
	print("[SentryManager] Sentry observers connected successfully.")

# -------------------------------------------------------------------------
# User Context (LootLocker & Google Play)
# -------------------------------------------------------------------------

func _connect_lootlocker() -> void:
	var ll = get_node_or_null("/root/LootLockerManager")
	if not ll:
		return

	if not ll.auth_status_changed.is_connected(_on_lootlocker_auth):
		ll.auth_status_changed.connect(_on_lootlocker_auth)

	if not ll.player_name_changed.is_connected(_on_lootlocker_name_changed):
		ll.player_name_changed.connect(_on_lootlocker_name_changed)

	# Apply cached or existing user data immediately if present
	if ll.is_authenticated:
		_set_sentry_user(str(ll.player_id), ll.get_effective_player_name())
	elif ll.player_name != "":
		_set_sentry_user("", ll.player_name)

func _on_lootlocker_auth(success: bool) -> void:
	if not success:
		return
	var ll = get_node_or_null("/root/LootLockerManager")
	if ll:
		_set_sentry_user(str(ll.player_id), ll.get_effective_player_name())
		add_breadcrumb("Player authenticated: " + ll.get_effective_player_name(), "auth")

func _on_lootlocker_name_changed(new_name: String) -> void:
	var ll = get_node_or_null("/root/LootLockerManager")
	var pid: String = str(ll.player_id) if (ll and ll.player_id > 0) else ""
	_set_sentry_user(pid, new_name)

func _set_sentry_user(p_id: String, p_name: String) -> void:
	if not ClassDB.class_exists(&"SentryUser"):
		return
	var user = SentryUser.new()
	if p_id != "" and p_id != "0":
		user.id = p_id
	if p_name != "":
		user.username = p_name
	SentrySDK.set_user(user)

# -------------------------------------------------------------------------
# Gameplay Breadcrumbs (GameManager)
# -------------------------------------------------------------------------

func _connect_gamemanager() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	if not gm.level_changed.is_connected(_on_level_changed):
		gm.level_changed.connect(_on_level_changed)

	if not gm.game_completed.is_connected(_on_game_completed):
		gm.game_completed.connect(_on_game_completed)

func _on_level_changed(level_index: int) -> void:
	add_breadcrumb("Entered Level %d" % [level_index + 1], "gameplay")

func _on_game_completed() -> void:
	add_breadcrumb("Player completed all levels!", "gameplay")

# -------------------------------------------------------------------------
# Scene Navigation Tracking
# -------------------------------------------------------------------------

func _connect_scene_tracker() -> void:
	if is_inside_tree() and get_tree():
		get_tree().tree_changed.connect(_check_scene_change)

func _check_scene_change() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	var current = tree.current_scene
	if current and current.name != _last_scene_name:
		_last_scene_name = current.name
		add_breadcrumb("Scene loaded: " + _last_scene_name, "navigation")

# -------------------------------------------------------------------------
# Public Helpers
# -------------------------------------------------------------------------

func add_breadcrumb(message: String, category: String = "game") -> void:
	if not ClassDB.class_exists(&"SentryBreadcrumb"):
		return
	var crumb = SentryBreadcrumb.create(message)
	crumb.category = category
	SentrySDK.add_breadcrumb(crumb)

func capture_message(message: String) -> void:
	if ClassDB.class_exists(&"SentrySDK"):
		SentrySDK.capture_message(message)
