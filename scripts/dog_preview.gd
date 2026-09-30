extends Node3D

var dogs: Array[Node3D] = []
var elapsed := 0.0
const STATES := ["idle","run","jump","land"]

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("d9d4ca")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ffffff")
	settings.ambient_light_energy = 0.25
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-25,0)
	light.light_energy = 0.45
	light.shadow_enabled = true
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30,30)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("88847e")
	floor_mesh.material_override = material
	floor_mesh.position.y = -0.02
	add_child(floor_mesh)
	for i in 4:
		var model = load("res://scripts/dog_visual.gd").new()
		add_child(model)
		model.position.x = (i-1.5)*1.9
		if i==0: model.rotation.y = -0.50
		dogs.append(model)
		var label := Label3D.new()
		label.text = ["대기","이동","수직 도약","착지"][i]
		label.position = Vector3(model.position.x,-0.20,0.4)
		label.font_size = 38
		label.pixel_size = 0.007
		label.modulate = Color("423b32")
		label.outline_size = 0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.3
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.position = Vector3(0.6,2.8,12)
	add_child(camera)
	camera.look_at(Vector3(0,0.65,0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "똥강아지 · 3D 동작 시안\n하얀 강아지 · 이동 / 수직 점프 / 착지"
	title.position = Vector2(36,28)
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("423b32"))
	canvas.add_child(title)

func _process(delta: float) -> void:
	elapsed += delta
	for i in dogs.size():
		dogs[i].pose(STATES[i],fmod(elapsed,float(dogs[i].CLIPS[STATES[i]])))
	# Third model has a purely vertical arc, no horizontal root motion.
	var t := fmod(elapsed,1.5)
	if t < 0.8:
		dogs[2].position.y = maxf(0,3.0*t-3.75*t*t)
		dogs[2].pose("jump" if t < 0.4 else "fall",t if t<0.4 else t-0.4)
	elif t < 1.04:
		dogs[2].position.y = 0
		dogs[2].pose("land",t-0.8)
	else:
		dogs[2].position.y = 0
		dogs[2].pose("idle",t)
