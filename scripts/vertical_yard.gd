extends Node3D

const Dog = preload("res://scripts/dog.gd")
const START := Vector3(-5.5, 0.05, 0)
# x, top, width, object. Generated from landing size and difficulty in _ready().
var ROUTE: Array = []
# Authored first three sections; randomize appearance, not their solution geometry.
const OBSTACLE_BASE := [
	[-4.0,0.7,1.8,"jar"], [-2.5,1.6,1.9,"jar"],
	[-0.9,2.7,2.0,"jangdokdae"], [1.6,4.0,3.4,"cushion"],
	[3.8,5.4,1.7,"jar"], [1.0,5.8,1.8,"cushion"],
	[-2.0,7.3,1.8,"jar"], [-4.2,8.7,2.0,"cushion"],
	[-6.1,10.0,1.9,"cushion"], [-4.8,11.3,1.2,"cushion"],
	[-0.5,12.8,1.2,"cushion"], [2.4,14.3,1.7,"cushion"],
	[4.3,16.3,1.3,"cushion"], [1.1,18.5,1.1,"cushion"],
	[-2.1,20.7,1.05,"jar"], [-5.4,23.0,0.95,"cushion"],
	[-2.0,25.3,0.9,"cushion"]
]
const SHORTCUT := [-1.6,11.0,0.75,"cushion"]
const CATCH := [4.1,2.1,2.4,"cushion"]

var dog: CharacterBody3D
var camera: Camera3D
var status: Label
var best := 0.0
var food_route: Array = []
var background: Sprite3D

func prop(kind: String, at: Vector3, variation := 0, horizontal_scale := 1.0, vertical_scale := 1.0) -> void:
	var instance := load("res://scenes/props/%s.tscn" % kind).instantiate() as Node3D
	instance.set("variant", variation)
	instance.scale = Vector3(horizontal_scale,vertical_scale,horizontal_scale)
	instance.position = at
	add_child(instance)

func generate_obstacle_route() -> void:
	ROUTE = OBSTACLE_BASE.duplicate(true)

func _ready() -> void:
	var bindings := {"left":[KEY_A,KEY_LEFT], "right":[KEY_D,KEY_RIGHT], "jump":[KEY_SPACE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action,event)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("cabfc9")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ffe4c2")
	settings.ambient_light_energy = 0.30
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-30,0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	add_child(sun)
	add_child(preload("res://scripts/solid_ground.gd").new())
	generate_obstacle_route()
	# Only reusable gameplay props; no placeholder buildings, beams or scenery blocks.
	for row in ROUTE + [SHORTCUT, CATCH]:
		var x := float(row[0])
		var top := float(row[1])
		var width := float(row[2])
		var kind := str(row[3])
		if kind == "jar":
			var jar_scale := top/1.1 if top < 2.0 else 0.6
			prop("jar",Vector3(x,top-1.1*jar_scale,0),int(top/6.0)%3,width/1.6,jar_scale)
		elif kind == "jangdokdae":
			var stand_scale := 1.0 if top < 3.0 else 0.5
			prop("jangdokdae",Vector3(x,top-2.4*stand_scale,0),int(top/5.0)%3,width/2.0,stand_scale)
		else:
			prop("cushion",Vector3(x,top-0.3,0),int(top/7.0)%3,width/2.0)
	var foods := preload("res://scripts/food_scatter.gd").new()
	foods.name = "FoodScatter"
	add_child(foods)
	var last_obstacle: Array = ROUTE[-1]
	foods.scatter(food_route,Vector2(float(last_obstacle[0]),float(last_obstacle[1])),float(last_obstacle[2]))
	dog = Dog.new()
	add_child(dog)
	dog.teleport(START)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.5
	camera.position = Vector3(-1.0,3.3,20)
	add_child(camera)
	camera.current = true
	background = Sprite3D.new()
	background.name = "Map01Background"
	background.texture = preload("res://assets/environment/map01_vertical_sunset.png")
	background.shaded = false
	background.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	add_child(background)
	update_background()
	var ui := CanvasLayer.new()
	add_child(ui)
	status = Label.new()
	status.position = Vector2(22,18)
	status.add_theme_color_override("font_shadow_color",Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x",2)
	status.add_theme_constant_override("shadow_offset_y",2)
	ui.add_child(status)

func _process(delta: float) -> void:
	best = maxf(best,dog.position.y)
	var target := Vector3(clampf(dog.position.x*0.35,-1.5,1.5),maxf(3.3,dog.position.y+1.7),20)
	camera.position = camera.position.lerp(target,1.0-exp(-5.0*delta))
	update_background()
	var section := "물건 더미 · 작은 발판부터" if dog.position.y < 4.0 else ("낮은 천장 · 오른쪽 끝에서 점프" if dog.position.y < 8.7 else ("갈림길 · 왼쪽 우회 / 오른쪽 좁은 지름길" if dog.position.y < 14.5 else "상단 등반"))
	status.text = section + "\n항아리 · 장독대 · 방석 → 음식 등반  |  최고 %.1fm\nA/D 이동 · SPACE 2단 점프 · ESC 로비" % best
	if dog.position.y > float(food_route[-1][1])-0.4 and dog.is_on_floor():
		status.text += "\n음식 코스 정상에 도착했습니다"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://lobby.tscn")

func update_background() -> void:
	# Orthographic depth alone has no parallax: map camera height to image scroll.
	var viewport_size := get_viewport().get_visible_rect().size
	var view_height := camera.size
	var view_width := view_height * viewport_size.x / maxf(1.0,viewport_size.y)
	var texture_size := background.texture.get_size()
	var world_per_pixel := maxf(view_width/texture_size.x,view_height/texture_size.y)*1.04
	background.pixel_size = world_per_pixel
	var image_height := texture_size.y * world_per_pixel
	var summit_camera := float(food_route[-1][1])+1.7
	var progress := clampf((camera.position.y-3.3)/(summit_camera-3.3),0.0,1.0)
	var scroll_range := maxf(0.0,image_height-view_height)
	background.position = Vector3(camera.position.x,camera.position.y+(0.5-progress)*scroll_range,-12)
