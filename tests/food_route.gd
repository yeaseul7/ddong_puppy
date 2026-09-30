extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func tick(frames := 1) -> void:
	for i in frames:
		await physics_frame

func run() -> void:
	var scene = load("res://vertical_yard.tscn").instantiate()
	root.add_child(scene)
	await tick(3)
	assert(scene.get_node("FoodScatter").placed_count == 36, "All imported food assets must be placed")
	# Keep tests from overwriting the player's save.
	scene.set_process(false)
	var dog = scene.dog
	var previous: Vector3 = scene.START
	for row in scene.ROUTE + scene.food_route:
		dog.teleport(previous)
		await tick(20)
		assert(dog.is_on_floor(), "Start surface must be solid")
		Input.action_press("jump")
		await tick(2)
		Input.action_release("jump")
		var target := Vector3(float(row[0]),float(row[1]),0)
		var landed := false
		var doubled := false
		var jump_hold := 0
		for frame in 150:
			Input.action_release("left")
			Input.action_release("right")
			if absf(dog.position.x-target.x)>0.09:
				Input.action_press("right" if dog.position.x<target.x else "left")
			if not doubled and dog.velocity.y < 4.5 and (row[3] == "food" or target.y-previous.y>1.55 or absf(target.x-previous.x)>2.6):
				Input.action_press("jump")
				doubled = true
				jump_hold = 2
			elif jump_hold > 0:
				jump_hold -= 1
			else:
				Input.action_release("jump")
			await tick()
			if dog.is_on_floor() and absf(dog.position.y-target.y)<0.4:
				landed = true
				break
		Input.action_release("left")
		Input.action_release("right")
		Input.action_release("jump")
		if not landed:
			push_error("Unreachable route step: %s; ended at %s" % [target,dog.position])
			quit(1)
			return
		previous = dog.position+Vector3(0,0.05,0)
	print("PASS: all 50 route jumps and solid landings")
	for direction in [-1, 1]:
		dog.teleport(Vector3(direction * 7.8, 35, 0))
		Input.action_press("left" if direction < 0 else "right")
		await tick(240)
		Input.action_release("left")
		Input.action_release("right")
		assert(dog.is_on_floor() and absf(dog.position.y) < 0.1)
		assert(absf(dog.position.x) <= dog.WORLD_HALF_WIDTH)
	print("PASS: both world edges land on base floor without respawn")
	quit(0)
