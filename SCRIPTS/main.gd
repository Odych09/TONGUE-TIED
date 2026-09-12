extends Node2D


func _ready() -> void:
	setup_next_level();
	GameManager.ChangeLevel.connect(setup_next_level);

func setup_next_level():
	GameManager.CurrentLevel += 1;
	
	if GameManager.LevelData.size() < GameManager.CurrentLevel:
		#add game completed in future
		get_tree().quit(0)
		return;
		
	if GameManager.CurrentLevelScene:
		GameManager.CurrentLevelScene.queue_free();
	GameManager.CurrentLevelScene = GameManager.LevelData[GameManager.CurrentLevel].instantiate();
	self.add_child(GameManager.CurrentLevelScene);
