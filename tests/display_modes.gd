extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings := root.get_node("DisplaySettings")
	# Keep the player's saved preference untouched.
	settings.config_path = "/private/tmp/ddong-puppy-display-mode-test.cfg"
	var lobby = load("res://lobby.tscn").instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.open_settings()
	assert(lobby.settings_dialog.visible)
	for fullscreen in [true,false]:
		lobby.change_screen_mode(1 if fullscreen else 0)
		assert(settings.fullscreen == fullscreen)
		var restored = load("res://scripts/display_settings.gd").new()
		restored.config_path = settings.config_path
		restored.load_settings()
		assert(restored.fullscreen == fullscreen)
		restored.free()
		if DisplayServer.get_name() != "headless":
			await create_timer(1.5).timeout
			assert(root.mode == (Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED))
	if DisplayServer.get_name() != "headless":
		var available := DisplayServer.screen_get_usable_rect(root.current_screen)
		assert(root.size.x <= available.size.x and root.size.y <= available.size.y)
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/private/tmp/ddong-display-settings.png")
	DirAccess.remove_absolute(settings.config_path)
	print("PASS: lobby settings, fullscreen/windowed transitions, persisted preference")
	quit()
