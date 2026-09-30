extends Node3D

const Dog = preload("res://scripts/dog.gd")
const SAVE_PATH := "user://yard_save.json"
const START := Vector3(-4, 0.1, 0)
const CHECKPOINT := Vector3(1.0, 12.1, 0)
var dog: CharacterBody3D
var camera: Camera3D
var checkpoint_active := false
var completed := false
var best := 0.0
var falls := 0
var elapsed := 0.0
var autosave := 0.0
var notice_time := 0.0
var status: Label
var notice: Label
var marker: Node3D
# x, top height, width, prop type. All tops share the playable z plane.
const ROUTE := [
	[-2.5, 1, 2.1, "bench"],
	[0.1, 2.2, 1.5, "box"],
	[2.6, 3.4, 1.3, "chair"],
	[0, 5.7, 1.8, "quilt"],
	[-2.7, 6.9, 1.1, "jar"],
	[-4.7, 8.1, 1.3, "box"],
	[-2, 10.3, 1, "chair"],
	[1, 12, 2.4, "bench"],
	[3.5, 13.3, 1.3, "box"],
	[5.5, 14.7, 0.95, "jar"],
	[2.8, 17, 1.6, "quilt"],
	[0, 18.3, 1, "chair"],
	[-2.7, 19.6, 0.95, "jar"],
	[-5, 22, 1.5, "box"],
	[-2.3, 23.4, 1.1, "chair"],
	[0.4, 24.8, 0.95, "jar"],
	[3, 27.1, 1.6, "quilt"],
	[5, 28.5, 1.1, "box"],
	[2.5, 30, 1.1, "chair"],
	[-0.5, 32.2, 2.4, "roof"]
]

func _ready() -> void:
	get_tree().auto_accept_quit = false
	bind_key("left", [KEY_A, KEY_LEFT])
	bind_key("right", [KEY_D, KEY_RIGHT])
	bind_key("jump", [KEY_SPACE])
	bind_key("look", [KEY_W, KEY_UP])
	bind_key("checkpoint", [KEY_E])
	bind_key("retry", [KEY_R])
	bind_key("fresh", [KEY_N])
	bind_key("pause", [KEY_ESCAPE])
	build_world()
	build_ui()
	dog = Dog.new()
	add_child(dog)
	dog.teleport(START)
	load_game()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	camera.far = 200
	add_child(camera)
	camera.current = true
	update_camera(1.0)
	notify("마당에서 지붕까지 · 발판의 윗면을 보고 올라가세요", 6.0)

func bind_key(action: String, keys: Array) -> void:
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid := false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	node.add_child(mesh)
	if solid:
		var col := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		col.shape = bounds
		node.add_child(col)
	return node

func build_world() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("b6d6dc")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("fff0d4")
	settings.ambient_light_energy = 0.30
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	add_child(sun)
	add_child(preload("res://scripts/solid_ground.gd").new())
	box(self, Vector3(-5,1.5,-3.5), Vector3(5,3,2), Color("e6d6b9"))
	box(self, Vector3(-5,3.15,-3.5), Vector3(5.6,0.4,2.8), Color("5e777a"))
	box(self, Vector3(-5,1.05,-2.45), Vector3(1,2.1,0.1), Color("806a53"))
	box(self, Vector3(-3.7,1.7,-2.4), Vector3(0.8,0.85,0.12), Color("f0bd75"))
	for row in ROUTE:
		make_prop(float(row[0]), float(row[1]), float(row[2]), str(row[3]))
	marker = Node3D.new()
	add_child(marker)
	marker.position = Vector3(CHECKPOINT.x,12.02,0.5)
	box(marker, Vector3(0,0,0), Vector3(1.1,0.05,0.8), Color("d3ba74"))
	for i in 9:
		box(self, Vector3(sin(i * 2.0) * 8, i * 4.0 + 3,-7), Vector3(3.8,0.25,1), Color("e8ede3"))
	label_3d("할머니 집", Vector3(-5,3.8,-2), 28)
	label_3d("배변 장소 · E", Vector3(1.0,12.7,-0.6), 24)
	label_3d("지붕 · 이번 산책의 끝", Vector3(-0.5,33.5,-0.6), 28)

func make_prop(x: float, top: float, width: float, kind: String) -> void:
	var color := Color("ad8961")
	if kind == "jar": color = Color("795448")
	if kind == "quilt": color = Color("ba8790")
	if kind == "roof": color = Color("637f81")
	var depth := 1.25
	var thickness := 0.25
	if kind == "box": thickness = 0.8
	if kind == "jar": thickness = 0.85
	box(self, Vector3(x,top-thickness/2,0), Vector3(width,thickness,depth), color,true)
	if kind == "bench" or kind == "chair":
		for side in [-1,1]:
			box(self, Vector3(x+side*(width/2-0.12),top-0.55,0), Vector3(0.15,0.85,1.0),Color("80634b"))
	if kind == "chair":
		box(self, Vector3(x,top+0.35,-0.7),Vector3(width,0.9,0.12),color)
	if kind == "jar":
		box(self,Vector3(x,top-0.05,0),Vector3(width+0.1,0.1,depth+0.1),Color("a58163"))
	if kind == "quilt":
		for stripe in [-1,0,1]:
			box(self,Vector3(x+stripe*width/3,top+0.008,0),Vector3(0.1,0.012,depth),Color("edd4b8"))

func label_3d(text: String, at: Vector3, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.12,0.18,0.19,0.85)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 102
	layer.add_child(panel)
	status = Label.new()
	status.position = Vector2(26,15)
	status.add_theme_font_size_override("font_size",22)
	layer.add_child(status)
	var help := Label.new()
	help.text = "A / D  이동    SPACE  점프 · 2단 점프    W  위 보기    E  체크포인트    R  복귀    ESC  일시정지\n새로 시작: N 길게 누르기 (2초) · 종료 시 현재 위치 자동 저장"
	help.position = Vector2(26,49)
	help.add_theme_font_size_override("font_size",16)
	layer.add_child(help)
	notice = Label.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	notice.offset_top = -85
	notice.offset_bottom = -25
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size",22)
	notice.add_theme_color_override("font_shadow_color",Color("243c42"))
	notice.add_theme_constant_override("shadow_offset_x",2)
	notice.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(notice)

var reset_hold := 0.0
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		dog.enabled = not dog.enabled
		notify("일시정지 · ESC로 계속" if not dog.enabled else "다시 올라가요", 3600 if not dog.enabled else 2)
	if not dog.enabled: return
	elapsed += delta
	best = maxf(best,dog.position.y)
	reset_hold = reset_hold + delta if Input.is_action_pressed("fresh") else 0.0
	if reset_hold >= 2.0:
		checkpoint_active = false
		completed = false
		best = 0
		falls = 0
		elapsed = 0
		reset_hold = -100
		dog.teleport(START)
		clear_poop()
		save_game()
		notify("새 산책을 시작합니다")
	if Input.is_action_just_pressed("retry"):
		falls += 1
		dog.teleport(CHECKPOINT if checkpoint_active else START)
		notify("저장한 배변 장소에서 다시 시작" if checkpoint_active else "마당에서 다시 시작")
	if Input.is_action_just_pressed("checkpoint") and dog.is_on_floor() and dog.position.distance_to(CHECKPOINT) < 1.7:
		checkpoint_active = true
		show_poop()
		save_game()
		notify("응가 완료! 체크포인트가 저장됐습니다")
	if not completed and dog.is_on_floor() and dog.position.y > 32.0:
		completed = true
		save_game()
		notify("지붕에 도착했습니다. 구름 위의 산책은 다음에 계속됩니다.",15)
	autosave += delta
	if autosave > 2 and dog.is_on_floor():
		autosave = 0
		save_game()
	notice_time -= delta
	notice.visible = notice_time > 0
	status.text = "똥강아지  /  마당 → 지붕     높이 %.1fm  ·  최고 %.1fm  ·  복귀 %d회  ·  %02d:%02d" % [maxf(0,dog.position.y),best,falls,int(elapsed)/60,int(elapsed)%60]
	update_camera(delta)

func update_camera(delta: float) -> void:
	var look := 3.5 if Input.is_action_pressed("look") else 0.0
	var target := Vector3(clampf(dog.position.x*0.25,-1.5,1.5),maxf(3.5,dog.position.y+2.0)+look,0)
	var destination := target+Vector3(1.5,2.0,18)
	camera.position = camera.position.lerp(destination,1.0-exp(-5.0*delta))
	camera.look_at(camera.position-Vector3(1.5,2.0,18),Vector3.UP)

func notify(message: String, duration := 4.0) -> void:
	notice.text = message
	notice_time = duration
	notice.visible = true

func clear_poop() -> void:
	for child in marker.get_children():
		if child.name.begins_with("Poop"):
			marker.remove_child(child)
			child.queue_free()

func show_poop() -> void:
	clear_poop()
	for i in 3:
		var size := 0.32-i*0.075
		var node := box(marker,Vector3(0,0.12+i*0.13,0),Vector3(size,0.15,size),Color("75503b"))
		node.name = "Poop%d" % i

func save_game() -> void:
	var data := {"version":1,"position":[dog.position.x,dog.position.y,0],"checkpoint":checkpoint_active,"best":best,"falls":falls,"elapsed":elapsed,"completed":completed}
	var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1: return
	var pos = data.get("position",[])
	if not pos is Array or pos.size() != 3: return
	for value in pos:
		if not (value is float or value is int): return
	var at := Vector3(float(pos[0]),float(pos[1]),0)
	if not at.is_finite() or absf(at.x)>20 or at.y < -3 or at.y>40: return
	checkpoint_active = bool(data.get("checkpoint",false))
	completed = bool(data.get("completed",false))
	best = float(data.get("best",0))
	falls = int(data.get("falls",0))
	elapsed = float(data.get("elapsed",0))
	dog.teleport(at)
	if checkpoint_active: show_poop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(dog): save_game()
		get_tree().quit()
