extends Node

## NetworkManager
## Handles OS-level network state detection via Android ConnectivityManager.
## 0 polling, 0% CPU/battery drain, Google Play Vitals compliant.

signal connection_changed(is_online: bool)
signal became_online
signal became_offline

var is_online: bool = true
var _native_plugin: Object = null

func _ready() -> void:
	if Engine.has_singleton("NetworkState"):
		_native_plugin = Engine.get_singleton("NetworkState")
		_native_plugin.connection_changed.connect(_on_native_connection_changed)
		is_online = _native_plugin.isConnected()
		print("[NetworkManager] Native Android NetworkState plugin active. Initial is_online = ", is_online)
	else:
		# Desktop / Editor environment
		is_online = true
		print("[NetworkManager] Running on non-Android platform. Default is_online = ", is_online)

func _on_native_connection_changed(connected: bool) -> void:
	if is_online != connected:
		is_online = connected
		print("[NetworkManager] Native connection state changed: is_online = ", is_online)
		connection_changed.emit(is_online)
		if is_online:
			became_online.emit()
		else:
			became_offline.emit()

func check_connection() -> bool:
	if _native_plugin:
		is_online = _native_plugin.isConnected()
	return is_online
