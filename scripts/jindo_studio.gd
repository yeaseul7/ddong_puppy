extends Node3D
var models: Array[Node3D] = []
var elapsed := 0.0
var animated := false
func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("d2d5d8")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.23
	env.environment = settings
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-40,0)
	light.light_energy = 0.43
	light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,140,0)
	fill.light_energy = 0.14
	fill.light_color = Color("ccddee")
	add_child(fill)
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(200,200)
	plane.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("767c84")
	mat.roughness = 1
	plane.material_override = mat
	plane.position.y = -0.002
	add_child(plane)
	for i in 3:
		var dog = preload("res://scripts/jindo_visual.gd").new()
		add_child(dog)
		dog.position.x = (i-1)*2.8
		dog.rotation.y = [0.0,-0.70,-PI/2][i]
		dog.pose("idle",0)
		models.append(dog)
		var label := Label3D.new()
		label.text = ["측면","사선","정면"][i]
		label.font_size = 32
		label.pixel_size = .006
		label.outline_size = 0
		label.modulate = Color("30343b")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(dog.position.x,-.23,.5)
		add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 9.0
	camera.position = Vector3(0,2.3,12)
	add_child(camera)
	camera.look_at(Vector3(0,.84,0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "백구 · 연속 표면과 뼈대가 있는 3D 모델\nSPACE: 이동 동작 전환   ·   J: 수직 점프 동작"
	title.position = Vector2(35,28)
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("30343b"))
	canvas.add_child(title)

func _process(delta: float) -> void:
	elapsed += delta
	for dog in models:
		dog.animate(delta,"run" if animated else "idle")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE: animated = not animated
		if event.keycode == KEY_J:
			set_process(false)
			for dog in models: dog.pose("jump",.15)
		if event.keycode == KEY_SPACE: set_process(true)
