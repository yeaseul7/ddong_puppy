extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func tick(frames := 1) -> void:
	for i in frames:
		await physics_frame

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await tick(3)
	# Keep tests from overwriting the player's save.
	scene.set_process(false)
	var dog = scene.dog
	var previous := Vector3(-4,0.05,0)
	for row in scene.ROUTE:
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
			if not doubled and dog.velocity.y < 4.5 and (target.y-previous.y>1.55 or absf(target.x-previous.x)>2.6):
				Input.action_press("jump")
				doubled = true
				jump_hold = 2
			elif jump_hold > 0:
				jump_hold -= 1
			else:
				Input.action_release("jump")
			await tick()
			if dog.is_on_floor() and absf(dog.position.y-target.y)<0.1:
				landed = true
				break
		Input.action_release("left")
		Input.action_release("right")
		Input.action_release("jump")
		if not landed:
			push_error("Unreachable route step: %s; ended at %s" % [target,dog.position])
			quit(1)
			return
		previous = target+Vector3(0,0.05,0)
	print("PASS: all 20 route jumps and solid landings")
	for direction in [-1, 1]:
		dog.teleport(Vector3(direction * 7.8, 35, 0))
		Input.action_press("left" if direction < 0 else "right")
		await tick(240)
		Input.action_release("left")
		Input.action_release("right")
		assert(dog.is_on_floor() and absf(dog.position.y) < 0.1)
		assert(absf(dog.position.x) <= dog.WORLD_HALF_WIDTH)
	print("PASS: both world edges land on base floor without respawn")
	# Neutral input must jump straight up, including after moving.
	dog.teleport(Vector3(6.5,0.05,0))
	await tick(20)
	Input.action_press("right")
	await tick(5)
	Input.action_release("right")
	var launch_x: float = dog.position.x
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	assert(dog.velocity.y > 0 and dog.animation_state == "jump")
	await tick(10)
	assert(absf(dog.position.x-launch_x)<0.001, "Neutral jump must not drift forward")
	assert(dog.model.get_chest_pitch() > 0.25, "Jump pose must lift chest upward")
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	assert(dog.jumps == 2 and dog.animation_state == "double_jump")
	await tick(3)
	var before_third: float = dog.velocity.y
	Input.action_press("jump")
	await tick(2)
	Input.action_release("jump")
	assert(dog.velocity.y < before_third, "Third jump must not add upward impulse")
	await tick(120)
	assert(dog.is_on_floor() and absf(dog.position.x-launch_x)<0.001)
	assert(dog.animation_state == "idle")
	print("PASS: vertical jump, upward pose, double jump, third-jump rejection, landing")
	# Save round-trip, preserve any existing user save.
	var path: String = scene.SAVE_PATH
	var existed := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if existed else ""
	scene.checkpoint_active = true
	dog.teleport(scene.CHECKPOINT)
	scene.save_game()
	dog.teleport(scene.START)
	scene.checkpoint_active = false
	scene.load_game()
	assert(scene.checkpoint_active and dog.position.distance_to(scene.CHECKPOINT)<0.01)
	if existed:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(backup)
		file.close()
	else:
		DirAccess.remove_absolute(path)
	print("PASS: checkpoint and position save round-trip")
	quit(0)
