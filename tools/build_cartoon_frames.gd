extends SceneTree
func _initialize() -> void:
	var image := Image.load_from_file("res://assets/2d/jindo_cartoon/sheet.png")
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	var sheet := load("res://assets/2d/jindo_cartoon/sheet.png") as Texture2D
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var clips := {"idle":[0,1,2,3],"run":[4,5,6,7],"jump":[8],"double_jump":[9],"fall":[10],"land":[11]}
	for clip in clips:
		frames.add_animation(clip)
		frames.set_animation_speed(clip,10 if clip == "run" else 3)
		frames.set_animation_loop(clip,clip in ["idle","run"])
		for index in clips[clip]:
			# Sheet rows have unequal one-pixel rounding; keep sampling exact boundaries.
			var y := int(index/4)*image.get_height()/3
			var next_y := (int(index/4)+1)*image.get_height()/3
			var cell := Rect2i((index%4)*384,y,384,next_y-y)
			var bounds := image.get_region(cell).get_used_rect()
			assert(bounds.size.x>100 and bounds.size.y>100)
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(cell.position+bounds.position,bounds.size)
			atlas.margin = Rect2(Vector2((384-bounds.size.x)/2.0,340-bounds.size.y),Vector2(384,384)-Vector2(bounds.size))
			frames.add_frame(clip,atlas)
			if index == 0: ResourceSaver.save(atlas,"res://assets/2d/jindo_cartoon/preview.tres")
	assert(ResourceSaver.save(frames,"res://assets/2d/jindo_cartoon/animations.tres")==OK)
	print("PASS: alpha, 12 atlas frames, six animations, aligned feet")
	quit()
