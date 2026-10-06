extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if not args.is_empty() else "res://map_2d_2.tscn"
	var map: Node = load(scene_path).instantiate()
	root.add_child(map)
	await process_frame
	var total := 0
	var polygon_ready := 0
	var legacy_shapes := 0
	var missing_alpha := 0
	for platform in map.get_node("Platforms").get_children():
		if not platform.get_meta("route",false):
			continue
		total += 1
		var sprites := platform.find_children("*","Sprite2D",true,false)
		var polygons := platform.find_children("*","CollisionPolygon2D",true,false)
		var shapes := platform.find_children("*","CollisionShape2D",true,false)
		if not polygons.is_empty(): polygon_ready += 1
		if not shapes.is_empty(): legacy_shapes += 1
		if not sprites.is_empty():
			var image: Image = (sprites[0] as Sprite2D).texture.get_image()
			if image.detect_alpha() == Image.ALPHA_NONE: missing_alpha += 1
		print(platform.name," sprites=",sprites.size()," polygons=",polygons.size()," shapes=",shapes.size())
	print("SUMMARY total=",total," polygon_ready=",polygon_ready," legacy_shapes=",legacy_shapes," missing_alpha=",missing_alpha)
	map.queue_free()
	await process_frame
	quit()
