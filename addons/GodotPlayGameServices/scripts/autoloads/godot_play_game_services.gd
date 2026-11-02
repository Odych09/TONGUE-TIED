extends Node
## Main Autoload of the plugin, which contains a reference to the android plugin itself.
##
## This Autoload contains the entrypoint to the android code, but you don't need
## to use it directly. Some autoloads exposing the plugin functionality, as a wrapper
## for GDScript code, are also loaded with the plugin.[br]
## [br]
## Automatically initialized in _enter_tree().

## Signal emitted after an image is downloaded and saved to the device.[br]
## [br]
## [param file_path]: The path to the stored file.
signal image_stored(file_path: String)

## Signal emitted when authentication state changes or is checked.
signal user_authenticated(is_authenticated: bool)

## Signal emitted when the current player profile is loaded.
signal current_player_loaded(player: PlayGamesPlayer)

enum PlayGamesPluginError {
	OK = 0,
	PLUGIN_NOT_FOUND = 1
}

## Main entry point to the android plugin. With this object, you can call the 
## kotlin methods directly.
var android_plugin: Object

## A helper JSON marshaller to safely access JSON data from the plugin.
var json_marshaller := JsonMarshaller.new()

## Tracks whether the player is currently signed in.
var is_signed_in: bool = false

## Stores the currently loaded player info if available.
var current_player: PlayGamesPlayer = null

func _enter_tree() -> void:
	initialize()

func _ready() -> void:
	if android_plugin:
		# Check authentication on Android startup (v2 best practice)
		check_authentication()

## Call this method manually to initialize the plugin.[br]
## [br]
## You have to call this method before you use any of the clients of the plugin.
## Called automatically in _enter_tree().[br]
## [br]
## Returns [PlayGamesPluginError.OK] if the plugin was initialized properly, or
## [PlayGamesPluginError.PLUGIN_NOT_FOUND] otherwise.
func initialize() -> PlayGamesPluginError:
	var plugin_name := "GodotPlayGameServices"
	
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("GodotPlayGameServices: Plugin initialized successfully.")
			
			android_plugin = Engine.get_singleton(plugin_name)
			android_plugin.initialize()
			
			android_plugin.imageStored.connect(func(file_path: String):
				image_stored.emit(file_path)
			)
			
			android_plugin.userAuthenticated.connect(func(authenticated: bool):
				is_signed_in = authenticated
				print("GodotPlayGameServices: userAuthenticated = ", authenticated)
				user_authenticated.emit(authenticated)
				if authenticated:
					load_current_player()
			)
			
			android_plugin.currentPlayerLoaded.connect(func(player_json: String):
				var safe_dict := json_marshaller.safe_parse_dictionary(player_json)
				current_player = PlayGamesPlayer.new(safe_dict)
				print("GodotPlayGameServices: Current player = ", current_player.display_name if current_player else "unknown")
				current_player_loaded.emit(current_player)
			)
			
			return PlayGamesPluginError.OK
		else:
			if OS.get_name() == "Android":
				printerr("GodotPlayGameServices: Android singleton not found. Ensure Gradle build and plugin are active.")
			else:
				print("GodotPlayGameServices: Running on %s (plugin only active on Android devices)." % OS.get_name())
	
	return PlayGamesPluginError.PLUGIN_NOT_FOUND

## Initiates the Google Play Games sign in flow.
func sign_in() -> void:
	if android_plugin:
		print("GodotPlayGameServices: Triggering sign in...")
		android_plugin.signIn()
	else:
		print("GodotPlayGameServices: sign_in called on non-Android platform.")

## Checks whether the user is currently authenticated without prompting.
func check_authentication() -> void:
	if android_plugin:
		print("GodotPlayGameServices: Checking authentication...")
		android_plugin.isAuthenticated()
	else:
		print("GodotPlayGameServices: check_authentication called on non-Android platform.")

## Displays the standard Google Play Games achievements UI overlay.
func show_achievements() -> void:
	if android_plugin:
		android_plugin.showAchievements()
	else:
		print("GodotPlayGameServices: show_achievements called on non-Android platform.")

## Displays the standard Google Play Games leaderboards UI overlay.
func show_leaderboards() -> void:
	if android_plugin:
		android_plugin.showAllLeaderboards()
	else:
		print("GodotPlayGameServices: show_leaderboards called on non-Android platform.")

## Unlocks the specified achievement for the currently signed-in player.
func unlock_achievement(achievement_id: String) -> void:
	if android_plugin:
		android_plugin.unlockAchievement(achievement_id)

## Submits a score to the specified leaderboard.
func submit_score(leaderboard_id: String, score: int) -> void:
	if android_plugin:
		android_plugin.submitScore(leaderboard_id, score)

## Loads the currently signed-in player's profile data.
func load_current_player(force_reload: bool = false) -> void:
	if android_plugin:
		android_plugin.loadCurrentPlayer(force_reload)

## Displays the given image in the given texture rectangle.[br]
## [br]
## [param texture_rect]: The texture rectangle control to display the image.[br]
## [param file_path]: The file path of the image, for example user://image.png.
func display_image_in_texture_rect(texture_rect: TextureRect, file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var image := Image.load_from_file(file_path)
		texture_rect.texture = ImageTexture.create_from_image(image)
	else:
		print("File %s does not exist." % file_path)
