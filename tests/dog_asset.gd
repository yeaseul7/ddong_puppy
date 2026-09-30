extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_file("res://assets/characters/dog/white_puppy_v2.glb",state) == OK)
	var model := document.generate_scene(state)
	assert(model != null)
	root.add_child(model)
	var players := model.find_children("*","AnimationPlayer",true,false)
	assert(players.size()==1)
	var player: AnimationPlayer = players[0]
	for clip in ["idle","run","jump","double_jump","fall","land"]:
		assert(player.has_animation(clip),"Missing animation: "+clip)
		player.play(clip)
		player.advance(0.1)
		assert(player.get_animation(clip).get_track_count() > 0)
	print("PASS: GLB round-trip and six playable animation clips")
	quit()
