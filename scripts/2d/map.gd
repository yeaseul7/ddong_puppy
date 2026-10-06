extends Node2D
@export var summit_height := 11000.0
@export_file("*.tscn") var next_scene := ""
@export var map_title := "첫 번째 마당"
@export_file("*.tscn") var continuation_scene := ""
@export var continuation_start_height := 0.0
@export var continuation_title := "두 번째 밤하늘"
@onready var dog: CharacterBody2D = $Dog
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var status: Label = $HUD/Status
@onready var ground_collision: CollisionShape2D = $Ground/CollisionShape2D
@onready var ground_visual: Node2D = $Ground/GroundVisual
@onready var map_music: AudioStreamPlayer = get_node_or_null("MapMusic")
@onready var night_background: Sprite2D = get_node_or_null("NightBackground")
var best := 0.0
var changing_map := false
var route_summit_height := 0.0
const CAMERA_FOLLOW_SPEED := 2.4
const CAMERA_X_DEAD_ZONE := 42.0
const CAMERA_UP_DEAD_ZONE := 70.0
const CAMERA_DOWN_DEAD_ZONE := 100.0
const CAMERA_X_LIMIT := 0.0
func _ready() -> void:
	merge_continuation()
	route_summit_height = summit_height
	for platform in $Platforms.get_children():
		if platform.get_meta("route",false):
			route_summit_height = maxf(route_summit_height,-platform.position.y)
	var keys := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in keys[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action,event)
	camera.position = Vector2(dog.position.x*0.35,-330)
	update_background()

func merge_continuation() -> void:
	if continuation_scene.is_empty() or continuation_start_height <= 0.0:
		return
	var packed := load(continuation_scene) as PackedScene
	assert(packed != null)
	var continuation := packed.instantiate()
	var source_platforms: Node = continuation.get_node("Platforms")
	for platform in source_platforms.get_children():
		source_platforms.remove_child(platform)
		clear_scene_owner(platform)
		platform.name = "Night_"+platform.name
		platform.position.y -= continuation_start_height
		$Platforms.add_child(platform)
	continuation.free()

func clear_scene_owner(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		clear_scene_owner(child)
func _process(delta: float) -> void:
	best = maxf(best,-dog.position.y/100)
	update_camera(delta)
	update_background()
	var current_title := continuation_title if continuation_start_height > 0.0 and -dog.position.y >= continuation_start_height else map_title
	status.text = "%s  |  최고 %.1fm\nA/D 이동 · SPACE 2단 점프 · ESC 로비" % [current_title,best]
	if map_music != null:
		if continuation_start_height > 0.0 and -dog.position.y >= continuation_start_height:
			map_music.stop()
		elif not map_music.playing:
			map_music.play()
	if not changing_map and -dog.position.y >= route_summit_height-20.0 and dog.is_on_floor():
		if next_scene.is_empty():
			status.text += "\n정상에 도착했습니다!"
		else:
			changing_map = true
			get_tree().change_scene_to_file(next_scene)
func update_camera(delta: float) -> void:
	var target := camera.position
	var desired_x := clampf(dog.position.x,-CAMERA_X_LIMIT,CAMERA_X_LIMIT)
	var x_error := desired_x-camera.position.x
	if absf(x_error)>CAMERA_X_DEAD_ZONE:
		target.x = desired_x-signf(x_error)*CAMERA_X_DEAD_ZONE
	var desired_y := dog.position.y-170.0
	var y_error := desired_y-camera.position.y
	if y_error < -CAMERA_UP_DEAD_ZONE:
		target.y = desired_y+CAMERA_UP_DEAD_ZONE
	elif y_error > CAMERA_DOWN_DEAD_ZONE:
		target.y = desired_y-CAMERA_DOWN_DEAD_ZONE
	target.y = minf(-330.0,target.y)
	camera.position = camera.position.lerp(target,1.0-exp(-CAMERA_FOLLOW_SPEED*delta))
func update_background() -> void:
	var view := get_viewport_rect().size / camera.zoom
	var tex := background.texture.get_size()
	var factor := maxf(view.x/tex.x,view.y/tex.y)*1.04
	background.scale = Vector2.ONE*factor
	var camera_climb := -camera.position.y-330.0
	var progress := clampf(camera_climb/maxf(1.0,route_summit_height-160.0),0,1)
	if night_background != null and continuation_start_height > 0.0:
		var first_span := maxf(1.0,continuation_start_height-160.0)
		var second_span := maxf(1.0,route_summit_height-continuation_start_height)
		progress = clampf(camera_climb/first_span,0,1)
		var night_progress := clampf((camera_climb-first_span)/second_span,0,1)
		var night_tex := night_background.texture.get_size()
		var night_factor := maxf(view.x/night_tex.x,view.y/night_tex.y)*1.04
		night_background.scale = Vector2.ONE*night_factor
		night_background.position = camera.position+Vector2(0,(night_progress-0.5)*maxf(0,night_tex.y*night_factor-view.y))
		var night_mix := smoothstep(first_span-180.0,first_span+80.0,camera_climb)
		background.modulate.a = 1.0-night_mix
		night_background.modulate.a = night_mix
	else:
		background.modulate.a = 1.0
	background.position = camera.position+Vector2(0,(progress-0.5)*maxf(0,tex.y*factor-view.y))
	var half_width := tex.x*factor*0.5
	var left := background.position.x-half_width
	var right := background.position.x+half_width
	dog.set_horizontal_bounds(left+26.0,right-26.0)
	var ground_shape := ground_collision.shape as RectangleShape2D
	ground_shape.size.x = right-left
	ground_collision.position.x = (left+right)*0.5-$Ground.position.x
	ground_visual.set_horizontal_bounds(left-$Ground.position.x,right-$Ground.position.x)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://lobby.tscn")
