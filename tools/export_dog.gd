extends SceneTree

func _initialize() -> void:
	call_deferred("export_model")

func export_model() -> void:
	var model = load("res://scripts/dog_visual.gd").new()
	root.add_child(model)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model.add_child(player)
	var library := AnimationLibrary.new()
	for clip in model.CLIPS:
		var animation := Animation.new()
		animation.length = float(model.CLIPS[clip])
		animation.loop_mode = Animation.LOOP_LINEAR if clip in ["idle","run","fall"] else Animation.LOOP_NONE
		for node in model.joints:
			for type in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:
				var track := animation.add_track(type)
				animation.track_set_path(track,model.get_path_to(node))
		var frames := int(ceil(animation.length*30))
		for frame in frames+1:
			var time := animation.length*float(frame)/frames
			model.pose(clip,time)
			var track := 0
			for node in model.joints:
				animation.position_track_insert_key(track,time,node.position)
				animation.rotation_track_insert_key(track+1,time,node.quaternion)
				animation.scale_track_insert_key(track+2,time,node.scale)
				track += 3
		library.add_animation(clip,animation)
	player.add_animation_library("",library)
	model.pose("idle",0)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_scene(model,state)
	if error == OK:
		error = document.write_to_filesystem(state,"res://assets/characters/dog/white_puppy_v2.glb")
	if error != OK:
		push_error("GLB export failed: %s"%error)
		quit(1)
		return
	print("PASS: exported white_puppy_v2.glb with six transform-animation clips")
	quit()
