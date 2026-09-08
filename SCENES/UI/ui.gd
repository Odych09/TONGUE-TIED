extends Control


@export var player: Frog
@onready var pulls_left: Label = $PULLS_LEFT

func _process(_delta: float) -> void:
	pulls_left.text = "Pulls remaining: " + str(player.remaining_pulls)
