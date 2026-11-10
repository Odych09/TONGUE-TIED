extends Node

#deeplink
@onready var deeplink: Deeplink = $"../Deeplink"


func _ready() -> void:
	deeplink.initialize()
	deeplink.deeplink_received.connect(_on_deeplink_received)


func _on_deeplink_received(url : DeeplinkUrl) -> void:
	print("Received URL: ", url.get_url())
	print("Path: ", url.get_path())
	var segments := url.get_path().trim_prefix("/").split("/", false)

	if segments.size() == 3:
		if segments[0] == "leaderboards" and segments[1] == "tongue-twister":
			
			call_deferred("_open_leaderboards")

func _open_leaderboards() -> void:
	GameManager.is_deeplink_leaderboard_redirect = true;
	get_tree().change_scene_to_file("res://SCENES/main_home.tscn")
