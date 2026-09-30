extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://vertical_yard.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for height in [3.3,25.0,55.0,94.5,55.0,3.3]:
		scene.camera.position.y = height
		scene.update_background()
		var image_height: float = scene.background.texture.get_height()*scene.background.pixel_size
		var bottom: float = scene.background.position.y-image_height/2
		var top: float = scene.background.position.y+image_height/2
		assert(bottom <= height-scene.camera.size/2+0.001)
		assert(top >= height+scene.camera.size/2-0.001)
		var sample: float = (top-height)/image_height
		if height == 3.3: assert(sample > 0.7)
		if height == 94.5: assert(sample < 0.3)
	print("PASS: background covers viewport and scrolls from village to sky and back")
	quit()
