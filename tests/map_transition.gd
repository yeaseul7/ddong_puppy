extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func tick(count := 1) -> void:
	for i in count:
		await process_frame
		await physics_frame

func run() -> void:
	change_scene_to_file("res://map_2d.tscn")
	await tick(3)
	var continuous_map := current_scene
	assert(continuous_map.next_scene.is_empty())
	assert(continuous_map.continuation_scene == "res://map_2d_2.tscn")
	var night_platforms: Array = continuous_map.get_node("Platforms").get_children().filter(func(node): return node.name.begins_with("Night_"))
	assert(night_platforms.size() >= 25)
	assert(continuous_map.route_summit_height >= 6680.0)
	var original_scene := current_scene
	continuous_map.camera.position.y = -3500.0
	continuous_map.update_background()
	assert(continuous_map.night_background.modulate.a > 0.99)
	await tick(3)
	assert(current_scene == original_scene)
	print("PASS: second course continues upward in one scene with night background")
	continuous_map.queue_free()
	await tick(2)
	quit()
