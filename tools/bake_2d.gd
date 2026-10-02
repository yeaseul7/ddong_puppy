extends SceneTree
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var catalog: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func capture(node: Node3D, path: String, fixed := false) -> void:
	stage.add_child(node)
	node.set_physics_process(false)
	await process_frame
	var bounds := AABB()
	var first := true
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	var center := bounds.get_center()
	camera.size = maxf(bounds.size.x,bounds.size.y)*1.16
	camera.position = Vector3(center.x,center.y,center.z+20)
	if fixed:
		camera.size = 2.5
		camera.position = Vector3(0,0.8,20)
	for i in 2: await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if not fixed: image = image.get_region(image.get_used_rect())
	assert(image.save_png(path)==OK)
	catalog[path.get_file().get_basename()] = {"path":path,"width":image.get_width(),"height":image.get_height()}
	stage.remove_child(node)
	node.queue_free()
func run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(512,512)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30,-25,0)
	sun.light_energy = 0.8
	stage.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera)
	camera.current = true
	var paths: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/imported/food_pack_manifest.json"))
	for file in DirAccess.get_files_at("res://assets/imported/snack_pack"):
		if file.ends_with(".glb"): paths.append("res://assets/imported/snack_pack/"+file)
	for path in paths:
		await capture(load(path).instantiate(),"res://assets/2d/food/"+str(path).get_file().get_basename()+".png")
	for kind in ["jar","jangdokdae","cushion"]:
		for variation in 3:
			var prop = load("res://scenes/props/"+kind+".tscn").instantiate()
			prop.variant = variation
			await capture(prop,"res://assets/2d/props/%s_%d.png" % [kind,variation])
	for clip in ["idle","run","jump","double_jump","fall","land"]:
		for frame in 6:
			var visual = load("res://scripts/jindo_visual.gd").new()
			stage.add_child(visual)
			visual.pose(clip,float(frame)/6.0)
			stage.remove_child(visual)
			await capture(visual,"res://assets/2d/dog/%s_%d.png" % [clip,frame],true)
	FileAccess.open("res://assets/2d/catalog.json",FileAccess.WRITE).store_string(JSON.stringify(catalog,"\t"))
	print("BAKED ",catalog.size()," transparent 2D assets")
	quit()
