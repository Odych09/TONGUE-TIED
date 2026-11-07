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

	_connect_google_play_listener()
	_connect_network_listener()
	#fake_login("63822640","the_CrazyBoy")

func fake_login(g_id : String , g_name : String) -> bool:
	is_authenticating = true

	# Bind session directly to the player's permanent Google Play Games ID
	var req = LL_Authentication.GuestSession.new(g_id)
	var response = await req.send()

	is_authenticating = false

	if response and response.success:
		is_authenticated = true
		player_id = response.player_id
		public_uid = response.public_uid
		player_identifier = response.player_identifier
		print("[LootLockerManager] Authenticated via Google Play successfully! Player ID: %d, Name: '%s'" % [player_id, g_name])
		auth_status_changed.emit(true)

		# Set the player's Google Play gamer tag on LootLocker
		if g_name != "":
			await set_player_name(g_name)

		var eff_name := get_effective_player_name()
		var stars := _get_local_stars()
		if stars > 0 and eff_name != "":
			submit_score(stars, eff_name)

		return true
	else:
		var err_msg = response.error_data.message if (response and response.error_data) else "Unknown error"
		print("[LootLockerManager] LootLocker authentication failed: %s" % err_msg)
		auth_status_changed.emit(false)
		return false

func _connect_google_play_listener() -> void:
	var pg = get_node_or_null("/root/GodotPlayGameServices")
	if not pg:
		return

	if not pg.current_player_loaded.is_connected(_on_google_play_player_loaded):
		pg.current_player_loaded.connect(_on_google_play_player_loaded)

	# If player is already signed in and loaded, start auth immediately
	if "current_player" in pg and pg.current_player:
		_on_google_play_player_loaded(pg.current_player)

func _connect_network_listener() -> void:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and not nm.became_online.is_connected(_on_network_became_online):
		nm.became_online.connect(_on_network_became_online)

func _is_network_available() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm:
		return nm.is_online
	return true

func _on_network_became_online() -> void:
	print("[LootLockerManager] Network connection restored! Re-checking authentication and syncing...")

	# If Google Play is available on Android but not signed in, trigger sign-in
	var pg = get_node_or_null("/root/GodotPlayGameServices")
	if pg and "is_signed_in" in pg and not pg.is_signed_in and pg.android_plugin:
		print("[LootLockerManager] Requesting Google Play sign-in on network reconnect...")
		pg.sign_in()

	# If not yet authenticated with LootLocker, trigger session
	if not is_authenticated and not is_authenticating:
		if pg and "current_player" in pg and pg.current_player:
			var g_id: String = pg.current_player.player_id if "player_id" in pg.current_player else ""
			var g_name: String = pg.current_player.display_name if "display_name" in pg.current_player else ""
			if g_id != "":
				await login_with_google_player_id(g_id, g_name)
		elif not OS.has_feature("android"):
			var eff_name := get_effective_player_name()
			if eff_name != "":
				await fake_login(eff_name, eff_name)

	# If authenticated, submit any local stars earned offline
	if is_authenticated:
		var stars := _get_local_stars()
		var eff_name := get_effective_player_name()
		if stars > 0 and eff_name != "":
			print("[LootLockerManager] Syncing %d stars to leaderboard after reconnect..." % stars)
			submit_score(stars, eff_name)

func _on_google_play_player_loaded(player) -> void:
	if not player:
		return
	var g_id: String = player.player_id if "player_id" in player else ""
	var g_name: String = player.display_name if "display_name" in player else ""
	if g_name != "":
		player_name = g_name
		_save_local_player_name(g_name)

	if g_id == "":
		print("[LootLockerManager] No Google Play ID found on player.")
		return

	print("[LootLockerManager] Authenticating LootLocker with Google Play Player ID: %s (%s)..." % [g_id, g_name])
	await login_with_google_player_id(g_id, g_name)

func login_with_google_player_id(g_id: String, g_name: String) -> bool:
	if is_authenticated and player_identifier == g_id:
		return true

	if is_authenticating:
		await auth_status_changed
		return is_authenticated

	is_authenticating = true

	# Bind session directly to the player's permanent Google Play Games ID
	var req = LL_Authentication.GuestSession.new(g_id)
	var response = await req.send()

	is_authenticating = false

	if response and response.success:
		is_authenticated = true
		player_id = response.player_id
		public_uid = response.public_uid
		player_identifier = response.player_identifier
		print("[LootLockerManager] Authenticated via Google Play successfully! Player ID: %d, Name: '%s'" % [player_id, g_name])
		auth_status_changed.emit(true)

		# Set the player's Google Play gamer tag on LootLocker
		if g_name != "":
			await set_player_name(g_name)

		var eff_name := get_effective_player_name()
		var stars := _get_local_stars()
		if stars > 0 and eff_name != "":
			submit_score(stars, eff_name)

		return true
	else:
		var err_msg = response.error_data.message if (response and response.error_data) else "Unknown error"
		print("[LootLockerManager] LootLocker authentication failed: %s" % err_msg)
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

	if not _is_network_available() or not is_authenticated:
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
	if not _is_network_available():
		print("[LootLockerManager] Offline: Score (%d stars) stored locally; will auto-submit when network returns." % score)
		return {"success": false, "error": "Offline"}

	if not is_authenticated:
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
	if not _is_network_available():
		print("[LootLockerManager] Offline: Cannot retrieve leaderboard without network.")
		return {"success": false, "items": [], "my_rank": 0, "my_score": 0}

	if not is_authenticated:
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
	var gm = get_node_or_null("/root/GameManager")
	if gm and "level_stars" in gm and gm.level_stars:
		if not gm.level_stars.is_empty():
			return gm.level_stars.values().reduce(func(accum, number): return accum + number, 0)
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
