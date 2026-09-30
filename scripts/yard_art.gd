extends Node3D

const Dog = preload("res://scripts/dog.gd")
const PIXEL := 0.010416667
var dog: CharacterBody3D
var outlines: Array[MeshInstance3D] = []
var camera: Camera3D
var guide: Label3D
var height_label: Label
var surfaces: Array[Vector3] = []
var highest := 0.0

func point(x: float, y: float) -> Vector3:
	return Vector3((x - 768.0) * PIXEL, (800.0 - y) * PIXEL, 0)

func _ready() -> void:
	for action in {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "retry": [KEY_R], "debug_ground": [KEY_F2]}:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "retry": [KEY_R], "debug_ground": [KEY_F2]}[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var art := Sprite3D.new()
	art.texture = preload("res://assets/environment/grandma_fantasy_v2.png")
	art.pixel_size = PIXEL
	art.position = Vector3(0, (800 - 512) * PIXEL, -0.6)
	art.shaded = false
	add_child(art)
	add_child(preload("res://scripts/solid_ground.gd").new())
	# Image-space endpoints follow the visible resting surfaces.
	for edge in [
		[52,692,141,692], [170,748,252,748],
		[434,701,589,727], [359,666,442,666], [332,626,411,626],
		[308,584,408,584], [10,553,320,553], [306,494,353,494],
		[340,470,377,470], [377,440,720,440], [369,389,505,425],
		[160,253,380,320], [0,172,157,245],
		[626,523,902,581], [890,653,1108,653]
	]:
		surface(point(edge[0], edge[1]), point(edge[2], edge[3]))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_energy = 0.55
	light.light_color = Color("ffd6a0")
	add_child(light)
	dog = Dog.new()
	add_child(dog)
	dog.scale = Vector3.ONE * 0.6
	dog.teleport(point(750, 790))
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 8.5
	camera.position = Vector3(dog.position.x, 1.8, 20)
	add_child(camera)
	camera.current = true
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	label.text = "할머니집 · 구름 너머로\nA/D 이동 · SPACE 2단 점프 · R 마당으로 · 밝은 윗면을 밟으세요 · ESC 로비"
	label.position = Vector2(20, 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(label)
	height_label = Label.new()
	height_label.position = Vector2(20, 72)
	height_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	height_label.add_theme_constant_override("shadow_offset_x", 2)
	height_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(height_label)
	guide = Label3D.new()
	guide.text = "▼ 다음 발판"
	guide.font_size = 32
	guide.pixel_size = 0.003
	guide.modulate = Color("ffe9a3")
	guide.no_depth_test = true
	add_child(guide)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("edb9a1")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ffe4c7")
	settings.ambient_light_energy = 0.30
	environment.environment = settings
	add_child(environment)

func surface(a: Vector3, b: Vector3) -> void:
	surfaces.append((a + b) * 0.5)
	var body := StaticBody3D.new()
	body.position = (a + b) * 0.5 - Vector3(0, 0.045, 0)
	body.rotation.z = atan2(b.y - a.y, b.x - a.x)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(a.distance_to(b), 0.09, 1)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	# Visible geometry uses the same dimensions as its collision surface.
	var ledge := MeshInstance3D.new()
	var ledge_box := BoxMesh.new()
	ledge_box.size = shape.size
	ledge.mesh = ledge_box
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("887454")
	stone.roughness = 0.95
	ledge.material_override = stone
	body.add_child(ledge)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(shape.size.x, 0.025, 0.025)
	mesh.mesh = box
	mesh.position = Vector3(0, 0.045, 0.6)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("f8dea0")
	mesh.material_override = material
	mesh.visible = true
	body.add_child(mesh)
	outlines.append(mesh)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("retry"):
		dog.teleport(point(750, 790))
	if Input.is_action_just_pressed("debug_ground"):
		for mesh in outlines:
			mesh.visible = not mesh.visible
	# Keep both edges over the continuous floor; falling never causes death.
	dog.position.x = clampf(dog.position.x, -7.7, 7.7)
	var target := Vector3(clampf(dog.position.x, -3.7, 3.7), maxf(1.8, dog.position.y + 1.2), 20)
	camera.position = camera.position.lerp(target, 1.0 - exp(-6.0 * delta))
	highest = maxf(highest, dog.position.y)
	height_label.text = "현재 %.1fm · 최고 %.1fm  |  마당 → 돌계단 → 담장 → 지붕" % [maxf(0, dog.position.y), highest]
	if dog.is_on_floor():
		var closest := INF
		guide.visible = false
		for landing in surfaces:
			var rise := landing.y - dog.position.y
			var distance := absf(landing.x - dog.position.x)
			if rise > 0.15 and rise < 2.8 and distance < 3.5:
				var score := distance + rise * 1.4
				if score < closest:
					closest = score
					guide.position = landing + Vector3(0, 0.45, 0.8)
					guide.visible = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://lobby.tscn")
