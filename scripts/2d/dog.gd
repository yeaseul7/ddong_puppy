extends CharacterBody2D
const SPEED := 560.0
const AIR_SPEED := 280.0
const GROUND_ACCELERATION := 4200.0
const AIR_ACCELERATION := 1700.0
const JUMP := 520.0
const DOUBLE_JUMP_RATIO := 0.75
const GRAVITY := 2100.0
const FALL_GRAVITY := 1550.0
var horizontal_min := -840.0
var horizontal_max := 840.0
var jumps := 0
var coyote := 0.0
var buffered := 0.0
var enabled := true
var landing := 0.0
var sprite: AnimatedSprite2D
func _ready() -> void:
	sprite = $Visual
	sprite.sprite_frames = preload("res://assets/2d/jindo_cartoon/animations.tres")
	sprite.position = Vector2(0,-44.4)
	sprite.scale = Vector2(0.3,0.3)
	sprite.play("idle")
func _physics_process(delta: float) -> void:
	if not enabled: return
	var grounded := is_on_floor()
	var axis := Input.get_axis("left","right")
	landing = maxf(0,landing-delta)
	if grounded:
		jumps = 0
		coyote = 0.11
	else:
		var gravity := FALL_GRAVITY if velocity.y > 0.0 else GRAVITY
		velocity.y += gravity*delta
		coyote = maxf(0,coyote-delta)
		if coyote == 0 and jumps == 0: jumps = 1
	buffered = maxf(0,buffered-delta)
	if Input.is_action_just_pressed("jump"): buffered = 0.13
	if buffered > 0:
		if grounded or coyote > 0:
			velocity.y = -JUMP
			jumps = 1
			coyote = 0
			buffered = 0
		elif jumps < 2:
			velocity.y = -JUMP*DOUBLE_JUMP_RATIO
			jumps = 2
			buffered = 0
	var move_speed := SPEED if grounded else AIR_SPEED
	var acceleration := GROUND_ACCELERATION if grounded else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x,axis*move_speed,acceleration*delta) if axis else 0.0
	move_and_slide()
	position.x = clampf(position.x,horizontal_min,horizontal_max)
	if axis: sprite.flip_h = axis < 0
	if is_on_floor() and not grounded: landing = 0.24
	var clip := "idle"
	if not is_on_floor(): clip = ("double_jump" if jumps == 2 else "jump") if velocity.y < -20 else "fall"
	elif absf(velocity.x)>15: clip = "run"
	elif landing>0: clip = "land"
	sprite.play(clip)
func teleport(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	jumps = 0
	buffered = 0
	coyote = 0

func set_horizontal_bounds(left: float, right: float) -> void:
	horizontal_min = left
	horizontal_max = right
