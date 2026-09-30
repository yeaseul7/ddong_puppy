extends CharacterBody3D

const WORLD_HALF_WIDTH := 8.0
const SPEED := 4.5
const JUMP := 8.4
const GRAVITY := 21.0
var jumps := 0
var coyote := 0.0
var buffered := 0.0
var facing := 1.0
const Visual = preload("res://scripts/dog_visual.gd")
var visual: Node3D
var model: Node3D
var landing_time := 0.0
var animation_state := "idle"
var enabled := true

func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = 0.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.4
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	model = Visual.new()
	model.scale = Vector3.ONE * 0.78
	visual.add_child(model)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var was_grounded := is_on_floor()
	landing_time = maxf(0.0, landing_time - delta)
	var axis := Input.get_axis("left", "right")
	if is_on_floor():
		jumps = 0
		coyote = 0.11
	else:
		coyote = maxf(0.0, coyote - delta)
		velocity.y -= GRAVITY * delta
		if coyote <= 0.0 and jumps == 0:
			jumps = 1
	buffered = maxf(0.0, buffered - delta)
	if Input.is_action_just_pressed("jump"):
		buffered = 0.13
	if buffered > 0.0:
		if is_on_floor() or coyote > 0.0:
			velocity.y = JUMP
			jumps = 1
			coyote = 0.0
			buffered = 0.0
		elif jumps < 2:
			velocity.y = JUMP * 0.92
			jumps = 2
			buffered = 0.0
	# No automatic forward impulse: a jump with no direction stays vertical.
	velocity.x = move_toward(velocity.x, axis * SPEED, 32.0 * delta)
	if is_zero_approx(axis):
		velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
	position.z = 0.0
	position.x = clampf(position.x, -WORLD_HALF_WIDTH, WORLD_HALF_WIDTH)
	if absf(position.x) >= WORLD_HALF_WIDTH:
		velocity.x = 0.0
	if absf(axis) > 0.1:
		facing = signf(axis)
	visual.rotation.y = 0.0 if facing > 0 else PI
	if is_on_floor() and not was_grounded:
		landing_time = 0.24
	if not is_on_floor():
		animation_state = ("double_jump" if jumps == 2 else "jump") if velocity.y > 0.2 else "fall"
	elif absf(velocity.x) > 0.15:
		animation_state = "run"
	elif landing_time > 0:
		animation_state = "land"
	else:
		animation_state = "idle"
	model.animate(delta, animation_state)

func teleport(at: Vector3) -> void:
	position = Vector3(clampf(at.x, -WORLD_HALF_WIDTH, WORLD_HALF_WIDTH), maxf(0.05, at.y), 0.0)
	velocity = Vector3.ZERO
	jumps = 0
	buffered = 0.0
	coyote = 0.0
	landing_time = 0.0
	animation_state = "idle"
	if is_instance_valid(model):
		model.animation_state = "idle"
		model.clock = 0.0
		model.pose("idle", 0.0)
