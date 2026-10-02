extends Node
## Shared across lobby/game scene changes. Stored independently of game progress.
const CONFIG_PATH := "user://display_settings.cfg"
var config_path := CONFIG_PATH
var fullscreen := false

func _ready() -> void:
	load_settings()
	if DisplayServer.get_name() != "headless":
		apply_mode()

func load_settings() -> void:
	var config := ConfigFile.new()
	fullscreen = false
	if config.load(config_path) == OK:
		var value = config.get_value("display","fullscreen",false)
		if value is bool:
			fullscreen = value

func set_fullscreen(value: bool) -> Error:
	fullscreen = value
	if DisplayServer.get_name() != "headless":
		apply_mode()
	var config := ConfigFile.new()
	config.set_value("display","fullscreen",fullscreen)
	return config.save(config_path)

func apply_mode() -> void:
	var window := get_tree().root
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		# Defer sizing until the OS has processed the fullscreen transition.
		call_deferred("size_window")

func size_window() -> void:
	if fullscreen:
		return
	var window := get_tree().root
	var area := DisplayServer.screen_get_usable_rect(window.current_screen)
	if area.size.x <= 0 or area.size.y <= 0:
		return
	# Fill most of the usable monitor while preserving the game's 16:10 ratio.
	var available := Vector2(area.size) * 0.90
	var width := minf(available.x,available.y*1.6)
	window.size = Vector2i(int(width),int(width/1.6))
	window.position = area.position+(area.size-window.size)/2
