extends CanvasLayer

@export var player: Frog
@onready var pulls_label: RichTextLabel = $UI/PULLS_LEFT
@onready var bugs_label: RichTextLabel = $UI/FLIES_LEFT

var shake_timer = 0.0
var base_position: Vector2

func _ready() -> void:
	if pulls_label:
		base_position = pulls_label.position
	if player:
		player.connect("player_pulled", Callable(self, "_on_player_pulled"))

func setup_player(p : Frog):
	player = p;
	player.ui_node = self;
	if not player.player_pulled.is_connected(_on_player_pulled):
		player.player_pulled.connect(_on_player_pulled)
		
func _process(delta: float) -> void:
	if not player:
		return
		
	# --- Pulls Label Styling ---
	if pulls_label:
		var color_tag = "[color=white]"
		if player.remaining_pulls == 1:
			color_tag = "[color=orange]"
		elif player.remaining_pulls <= 0:
			color_tag = "[color=red]"
			
		pulls_label.text = "Pulls: " + color_tag + str(player.remaining_pulls) + "[/color]"
		
		if shake_timer > 0.0:
			shake_timer -= delta
			pulls_label.position.x = base_position.x + sin(Time.get_ticks_msec() * 0.1) * 6.0
		else:
			pulls_label.position = base_position

	# --- Bugs Label Styling ---
	if bugs_label:
		var bug_color = "[color=yellow]"
		if player.collected_bugs < player.required_bugs:
			bug_color = "[color=orange]"
		else:
			bug_color = "[color=green]"
			
		bugs_label.text = "Bugs: " + bug_color + str(player.collected_bugs) + "/" + str(player.required_bugs) + "[/color]"

func trigger_out_of_pulls_effect():
	shake_timer = 0.35

func _on_player_pulled():
	if pulls_label:
		var tween = create_tween()
		tween.tween_property(pulls_label, "scale", Vector2(1.15, 1.15), 0.05)
		tween.tween_property(pulls_label, "scale", Vector2(1.0, 1.0), 0.1)
