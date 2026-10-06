extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func tick(count := 1) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if not args.is_empty() else "res://map_2d_2.tscn"
	var scene: Node = load(scene_path).instantiate()
	root.add_child(scene)
	await tick(3)
	scene.set_process(false)
	var dog: CharacterBody2D = scene.dog
	var platforms: Array = scene.get_node("Platforms").get_children().filter(func(node): return node.get_meta("route",false))
	for platform in platforms:
		dog.teleport(platform.position+Vector2(0,-100))
		var landed := false
		for frame in 120:
			await tick()
			if dog.is_on_floor() and absf(dog.position.y-platform.position.y)<110:
				landed = true
				break
		if not landed:
			push_error("Cannot land on %s: ended %s" % [platform.name,dog.position])
			quit(1)
			return
	print("PASS: all ",platforms.size()," second-map silhouette polygons accept landing")
	quit()
