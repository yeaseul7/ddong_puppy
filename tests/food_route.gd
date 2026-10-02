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
	var course: Array = scene.ROUTE + scene.food_route
	if "--shortcut" in OS.get_cmdline_user_args():
		course = scene.ROUTE.slice(0,8) + [scene.SHORTCUT] + scene.ROUTE.slice(10) + scene.food_route
	for row in course:
		dog.teleport(previous)
		await tick(20)
		if not dog.is_on_floor():
			push_error("Unstable start %s before %s" % [previous,row])
			quit(1)
			return
		# The low ceiling requires walking to the exposed right edge before jumping.
		if row == scene.ROUTE[4]:
			Input.action_press("right")
			for frame in 80:
				await tick()
				if dog.position.x >= 2.5: break
			Input.action_release("right")
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
	print("PASS: all authored sections and food route jumps")
	# A failed right-side jump is caught below instead of respawning.
	dog.teleport(Vector3(4.1,3.7,0))
	await tick(90)
	assert(dog.is_on_floor() and absf(dog.position.y-2.1)<0.12)
	# Jumping straight up under the overhead cushion hits its underside.
	dog.teleport(Vector3(1.0,4.05,0))
	await tick(20)
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	var peak: float = dog.position.y
	for i in 60:
		await tick()
		peak = maxf(peak,dog.position.y)
	assert(peak < 4.9)
	print("PASS: recovery cushion and low ceiling collision")
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
