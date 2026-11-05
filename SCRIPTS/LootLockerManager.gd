extends Node

const LEADERBOARD_ID := "37833"

var is_authenticated: bool = false
var is_authenticating: bool = false
var player_id: int = 0
var player_name: String = ""
var public_uid: String = ""
var player_identifier: String = ""

signal auth_status_changed(success: bool)
signal player_name_changed(new_name: String)
signal score_submitted(success: bool, rank: int, score: int)

func _ready() -> void:
	# Load locally cached name if any
	var saved_name := _load_local_player_name()
	if saved_name != "":
		player_name = saved_name

	# Automatically start silent background session on boot
	start_silent_session()
	_connect_google_play_listener()

func _connect_google_play_listener() -> void:
	# Connect to GodotPlayGameServices if available in tree
	var pg = get_node_or_null("/root/GodotPlayGameServices")
	if pg and pg.has_signal("current_player_loaded"):
		pg.current_player_loaded.connect(_on_google_play_player_loaded)

func _on_google_play_player_loaded(player) -> void:
	if not player:
		return
	var g_id: String = player.player_id if "player_id" in player else ""
	var g_name: String = player.display_name if "display_name" in player else ""
	
	# If authenticated player identifier differs from Google ID, re-authenticate with Google ID
	if g_id != "" and g_id != player_identifier:
		await ensure_session(g_id)
	
	# Update player display name if non-empty
	if g_name != "":
		player_name = g_name
		_save_local_player_name(g_name)
		await set_player_name(g_name)
		
		# Immediately update leaderboard score metadata with the Google name
		var local_stars := _get_local_stars()
		if local_stars > 0:
			await submit_score(local_stars, g_name)

func start_silent_session() -> void:
	await ensure_session()

func ensure_session(custom_id: String = "") -> bool:
	if is_authenticated and custom_id == "":
		return true

	if is_authenticating:
		await auth_status_changed
		return is_authenticated

	is_authenticating = true

	var req = LL_Authentication.GuestSession.new(custom_id)
	var response = await req.send()

	is_authenticating = false

	if response and response.success:
		is_authenticated = true
		player_id = response.player_id
		if response.player_name != "":
			player_name = response.player_name
		public_uid = response.public_uid
		player_identifier = response.player_identifier
		print("[LootLockerManager] Authenticated successfully. Player ID: %d, Name: '%s'" % [player_id, player_name])
		auth_status_changed.emit(true)
		
		# Auto-resubmit score with metadata if we have local stars and an effective name
		var eff_name := get_effective_player_name()
		var stars := _get_local_stars()
		if stars > 0 and eff_name != "":
			submit_score(stars, eff_name)
			
		return true
	else:
		var err_msg = response.error_data.message if (response and response.error_data) else "Unknown error"
		print("[LootLockerManager] Authentication failed: %s" % err_msg)
		auth_status_changed.emit(false)
		return false

func get_effective_player_name() -> String:
	if player_name != "":
		return player_name
	
	# Check Google Play profile if signed in
	var pg = get_node_or_null("/root/GodotPlayGameServices")
	if pg and "current_player" in pg and pg.current_player:
		if "display_name" in pg.current_player and pg.current_player.display_name != "":
			return pg.current_player.display_name

	# Check local saved name
	var local_name := _load_local_player_name()
	if local_name != "":
		return local_name

	# Fallback to Desktop environment username for nice PC testing
	if OS.has_feature("pc") or OS.has_feature("windows") or OS.has_feature("editor"):
		var env_user := OS.get_environment("USERNAME")
		if env_user != "":
			return env_user

	return ""

func set_player_name(new_name: String) -> bool:
	var clean_name := new_name.strip_edges()
	if clean_name == "":
		return false

	_save_local_player_name(clean_name)
	player_name = clean_name
	player_name_changed.emit(clean_name)

	if not is_authenticated:
		var ok := await ensure_session()
		if not ok:
			return false

	var req = LL_Players.SetPlayerName.new(clean_name)
	var response = await req.send()

	if response and response.success:
		print("[LootLockerManager] Player name set on LootLocker: %s" % clean_name)
		return true
	else:
		print("[LootLockerManager] SetPlayerName failed, but name is saved locally and will be sent via metadata")
		return false

func submit_score(score: int, custom_metadata: String = "") -> Dictionary:
	if not is_authenticated:
		var ok := await ensure_session()
		if not ok:
			return {"success": false, "error": "Not authenticated"}

	# Determine metadata: prefer custom_metadata, otherwise use effective player name
	var meta: String = custom_metadata
	if meta == "":
		meta = get_effective_player_name()

	var req = LL_Leaderboards.SubmitScore.new(LEADERBOARD_ID, score, str(player_id), meta)
	var response = await req.send()

	if response and response.success:
		print("[LootLockerManager] Score submitted: %d, Rank: %d, Meta: '%s'" % [response.score, response.rank, meta])
		score_submitted.emit(true, response.rank, response.score)
		return {"success": true, "rank": response.rank, "score": response.score}
	else:
		var err = response.error_data.message if (response and response.error_data) else "Failed to submit score"
		print("[LootLockerManager] Submit score failed: %s" % err)
		score_submitted.emit(false, 0, score)
		return {"success": false, "error": err}

func get_leaderboard(count: int = 50) -> Dictionary:
	if not is_authenticated:
		var ok := await ensure_session()
		if not ok:
			return {"success": false, "items": [], "my_rank": 0, "my_score": 0}

	var list_req = LL_Leaderboards.GetScoreList.new(LEADERBOARD_ID, count)
	var list_res = await list_req.send()

	var my_rank := 0
	var my_score := 0

	# Query personal rank if player_id is available
	if player_id > 0:
		var rank_req = LL_Leaderboards.GetMemberRank.new(LEADERBOARD_ID, str(player_id))
		var rank_res = await rank_req.send()
		if rank_res and rank_res.success:
			my_rank = rank_res.rank
			my_score = rank_res.score

	var items: Array[Dictionary] = []
	if list_res and list_res.success and list_res.items != null:
		for item in list_res.items:
			var display := ""

			# 1. Prefer metadata (where we store display name)!
			if item.metadata != null and item.metadata.strip_edges() != "":
				display = item.metadata.strip_edges()
			# 2. Check player.name
			elif item.player and item.player.name != "":
				display = item.player.name
			# 3. Fallback to member ID
			elif item.member_id != "":
				display = "Frog #" + str(item.member_id)
			else:
				display = "Anonymous Frog"

			var is_me := (str(item.member_id) == str(player_id))
			if is_me and my_rank == 0:
				my_rank = item.rank
				my_score = item.score

			items.append({
				"rank": item.rank,
				"score": item.score,
				"name": display,
				"member_id": item.member_id,
				"is_me": is_me
			})

	return {
		"success": list_res != null and list_res.success,
		"items": items,
		"my_rank": my_rank,
		"my_score": my_score
	}

func _get_local_stars() -> int:
	if GameManager and "level_stars" in GameManager and GameManager.level_stars:
		if not GameManager.level_stars.is_empty():
			return GameManager.level_stars.values().reduce(func(accum, number): return accum + number, 0)
	return 0

func _save_local_player_name(new_name: String) -> void:
	var f = FileAccess.open("user://player_name.txt", FileAccess.WRITE)
	if f:
		f.store_string(new_name)
		f.close()

func _load_local_player_name() -> String:
	if FileAccess.file_exists("user://player_name.txt"):
		var f = FileAccess.open("user://player_name.txt", FileAccess.READ)
		if f:
			var s = f.get_as_text().strip_edges()
			f.close()
			return s
	return ""
