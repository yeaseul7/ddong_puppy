extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var index := 0
	for file in DirAccess.get_files_at("res://scenes/2d/household"):
		if not file.ends_with(".tscn"): continue
		var body = load("res://scenes/2d/household/"+file).instantiate()
		body.position = Vector2(index*1000,0)
		host.add_child(body)
		await physics_frame
		await physics_frame
		var space := host.get_world_2d().direct_space_state
		var ray := PhysicsRayQueryParameters2D.create(body.position+Vector2(0,-100),body.position+Vector2(0,200))
		var hit := space.intersect_ray(ray)
		assert(not hit.is_empty() and hit.collider==body,"No top collision for "+file)
		assert(absf(hit.position.y)<1,"Landing anchor mismatch for "+file)
		assert(body.find_children("*", "Sprite2D", false, false)[0].texture.get_image().detect_alpha()!=Image.ALPHA_NONE)
		for child in body.get_children():
			if child is CollisionPolygon2D:
				assert(not Geometry2D.triangulate_polygon(child.polygon).is_empty())
		index+=1
	assert(index==16)
	print("PASS: 16 transparent assets, landing anchors and valid collision polygons")
	quit()
