extends Node

## Google Play Games Services Achievement Manager
## Handles tracking, caching, and submitting achievements without disturbing core gameplay.

const ACHIEVEMENTS := {
	"FIRST_LEAP": "CgkI5IC_49ABEAIQDA",       # Level 1 Clear
	"LILY_PAD_HOPPER": "CgkI5IC_49ABEAIQDQ",  # Level 5 Clear
	"SWAMP_NAVIGATOR": "CgkI5IC_49ABEAIQBg",  # Level 10 Clear
	"TONGUE_MASTER": "CgkI5IC_49ABEAIQBQ",    # All 15 Handcrafted Levels Clear
	"BEYOND_THE_POND": "CgkI5IC_49ABEAIQCg",  # First ASCII Level Clear
	"STARGAZER": "CgkI5IC_49ABEAIQDg",        # 15 Total Stars
	"SUPERSTAR_FROG": "CgkI5IC_49ABEAIQBw",   # 30 Total Stars
	"PERFECTIONIST": "CgkI5IC_49ABEAIQCw",    # 3-star on all 15 handcrafted levels (45 stars)
	"BUG_BUFFET": "CgkI5IC_49ABEAIQCQ",       # 50 Bugs (Incremental)
	"FROG_GOURMET": "CgkI5IC_49ABEAIQAw",     # 100 Bugs (Incremental)
	"CLUTCH_PULL": "CgkI5IC_49ABEAIQCA",      # Win with 0 remaining pulls
	"BONK": "CgkI5IC_49ABEAIQBA"              # Bonk into a wall
}

const SAVE_PATH := "user://achievements_cache.json"

var unlocked_ids: Array = []

func _ready() -> void:
	_load_cache()
	_connect_game_signals()

func _connect_game_signals() -> void:
	# Connect to GameManager progress updates
	if GameManager:
		GameManager.progress_updated.connect(_on_progress_updated)
	
	# Connect to SaveManager cloud ready
	if SaveManager and SaveManager.has_signal("save_data_ready"):
		SaveManager.save_data_ready.connect(_on_save_data_ready)
		
	# Connect to GodotPlayGameServices authentication
	if GodotPlayGameServices:
		GodotPlayGameServices.user_authenticated.connect(_on_user_authenticated)
		
	# Initial evaluation on boot
	call_deferred("check_progress")

func _on_user_authenticated(authenticated: bool) -> void:
	if authenticated:
		print("[AchievementManager] Player authenticated with Google Play. Syncing achievements...")
		_sync_unlocked_achievements()
		check_progress()

func _on_save_data_ready() -> void:
	check_progress()

func _on_progress_updated() -> void:
	check_progress()

## Evaluates all level progression and star achievements based on GameManager data
func check_progress() -> void:
	if not GameManager:
		return

	# 1. Level Completion Achievements
	if GameManager.level_stars.has("0") or GameManager.unlocked_level >= 1:
		unlock_achievement(ACHIEVEMENTS.FIRST_LEAP)

	if GameManager.level_stars.has("4") or GameManager.unlocked_level >= 5:
		unlock_achievement(ACHIEVEMENTS.LILY_PAD_HOPPER)

	if GameManager.level_stars.has("9") or GameManager.unlocked_level >= 10:
		unlock_achievement(ACHIEVEMENTS.SWAMP_NAVIGATOR)

	if GameManager.level_stars.has("14") or GameManager.unlocked_level >= 15:
		unlock_achievement(ACHIEVEMENTS.TONGUE_MASTER)

	# Check for ASCII bonus level (index >= 15)
	for key in GameManager.level_stars.keys():
		if int(key) >= 15 and int(GameManager.level_stars[key]) > 0:
			unlock_achievement(ACHIEVEMENTS.BEYOND_THE_POND)
			break

	# 2. Total Stars Achievements
	var total_stars: int = 0
	for stars in GameManager.level_stars.values():
		total_stars += int(stars)

	if total_stars >= 15:
		unlock_achievement(ACHIEVEMENTS.STARGAZER)

	if total_stars >= 30:
		unlock_achievement(ACHIEVEMENTS.SUPERSTAR_FROG)

	# 3. Perfectionist: 3 stars on all 15 handcrafted levels (levels 0..14)
	var has_all_perfect: bool = true
	for i in range(15):
		if GameManager.get_level_stars(i) < 3:
			has_all_perfect = false
			break
	if has_all_perfect and GameManager.level_stars.size() >= 15:
		unlock_achievement(ACHIEVEMENTS.PERFECTIONIST)

## Called when a player completes a level with a specific number of pulls remaining
func on_level_finished(remaining_pulls: int) -> void:
	if remaining_pulls == 0:
		unlock_achievement(ACHIEVEMENTS.CLUTCH_PULL)
	check_progress()

## Called when a bug is collected
func on_bug_collected() -> void:
	increment_achievement(ACHIEVEMENTS.BUG_BUFFET, 1)
	increment_achievement(ACHIEVEMENTS.FROG_GOURMET, 1)

## Called when the tongue bonks into a wall
func on_wall_bonked() -> void:
	unlock_achievement(ACHIEVEMENTS.BONK)

## Unlocks an achievement via AchievementsClient with local caching
func unlock_achievement(achievement_id: String) -> void:
	if not unlocked_ids.has(achievement_id):
		unlocked_ids.append(achievement_id)
		_save_cache()

	var client = get_node_or_null("/root/AchievementsClient")
	if client and client.has_method("unlock_achievement"):
		client.unlock_achievement(achievement_id)
		print("[AchievementManager] Unlock requested for: ", achievement_id)
	else:
		print("[AchievementManager] AchievementsClient not available; cached locally: ", achievement_id)

## Increments an incremental achievement
func increment_achievement(achievement_id: String, amount: int = 1) -> void:
	var client = get_node_or_null("/root/AchievementsClient")
	if client and client.has_method("increment_achievement"):
		client.increment_achievement(achievement_id, amount)
		print("[AchievementManager] Incremented ", achievement_id, " by ", amount)

## Opens the native Google Play Games Achievements UI overlay
func show_achievements() -> void:
	var client = get_node_or_null("/root/AchievementsClient")
	if client and client.has_method("show_achievements"):
		client.show_achievements()

## Syncs all locally unlocked achievements to Google Play
func _sync_unlocked_achievements() -> void:
	var client = get_node_or_null("/root/AchievementsClient")
	if client and client.has_method("unlock_achievement"):
		for id in unlocked_ids:
			client.unlock_achievement(id)

func _save_cache() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str := JSON.stringify({"unlocked": unlocked_ids})
		file.store_string(json_str)

func _load_cache() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var test_json = JSON.parse_string(file.get_as_text())
			if test_json is Dictionary and test_json.has("unlocked"):
				unlocked_ids = test_json["unlocked"]
