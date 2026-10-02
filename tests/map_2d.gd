extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func tick(count := 1) -> void:
	for i in count: await physics_frame
func run() -> void:
	var scene = load("res://map_2d.tscn").instantiate()
	root.add_child(scene)
	await tick(3)
	scene.set_process(false)
	assert(scene.find_children("*","Node3D",true,false).is_empty())
	var dog = scene.dog
	var previous := Vector2(-550,-5)
	var platforms: Array = scene.get_node("Platforms").get_children().filter(func(n): return n.get_meta("route"))
	var count := 0
	for platform in platforms:
		dog.teleport(previous)
		await tick(20)
		if not dog.is_on_floor():
			push_error("Unstable start before "+platform.name)
			quit(1)
			return
		if count == 4:
			Input.action_press("right")
			for i in 80:
				await tick()
				if dog.position.x >= 250: break
			Input.action_release("right")
			previous = dog.position
		Input.action_press("jump")
		await tick(2)
		Input.action_release("jump")
		var doubled := false
		var hold := 0
		var landed := false
		for frame in 160:
			Input.action_release("left")
			Input.action_release("right")
			if absf(dog.position.x-platform.position.x)>9:
				Input.action_press("right" if dog.position.x<platform.position.x else "left")
			if not doubled and dog.velocity.y > -450 and (previous.y-platform.position.y>155 or absf(previous.x-platform.position.x)>260 or platform.get_meta("kind")=="food"):
				Input.action_press("jump")
				doubled = true
				hold = 2
			elif hold>0: hold-=1
			else: Input.action_release("jump")
			await tick()
			if dog.is_on_floor() and absf(dog.position.y-platform.position.y)<16:
				landed = true
				break
		for action in ["left","right","jump"]: Input.action_release(action)
		if not landed:
			push_error("Cannot reach %s at %s: ended %s" % [platform.name,platform.position,dog.position])
			quit(1)
			return
		previous = dog.position+Vector2(0,-5)
		count+=1
	for side in [-1,1]:
		dog.teleport(Vector2(side*780,-15000))
		Input.action_press("left" if side<0 else "right")
		await tick(400)
		Input.action_release("left")
		Input.action_release("right")
		assert(dog.is_on_floor() and absf(dog.position.y)<2)
	print("PASS: pure 2D scene, ",count," jumps, both edge falls")
	quit()
