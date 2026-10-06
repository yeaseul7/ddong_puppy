extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var first_map: Node = load("res://map_2d.tscn").instantiate()
	root.add_child(first_map)
	await process_frame
	var music := first_map.get_node_or_null("MapMusic") as AudioStreamPlayer
	assert(music != null)
	assert(music.autoplay)
	assert(music.stream is AudioStreamMP3)
	assert((music.stream as AudioStreamMP3).loop)
	first_map.dog.position.y = -1600.0
	first_map._process(0.0)
	assert(not music.playing)
	first_map.queue_free()
	await process_frame

	var second_map: Node = load("res://map_2d_2.tscn").instantiate()
	root.add_child(second_map)
	assert(second_map.get_node_or_null("MapMusic") == null)
	print("PASS: looping music is scoped to the first map")
	quit()
