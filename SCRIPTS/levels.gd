extends Node2D

func _ready() -> void:
	var player := find_child("Player", true, false) as Frog
	var CRT := find_child("CRT", true, false)

	if player and CRT:
		CRT.setup_player(player)
