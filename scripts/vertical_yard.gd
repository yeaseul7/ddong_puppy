extends Node3D

const Dog = preload("res://scripts/dog.gd")
const START := Vector3(-5.5, 0.05, 0)
# x, top, width, object. Generated from landing size and difficulty in _ready().
var ROUTE: Array = []
const OBSTACLE_BASE := [
	[-3.5,1.1,1.8,"jar"], [-1.3,2.4,2.0,"jangdokdae"],
	[1.0,3.8,2.2,"cushion"], [3.2,5.2,2.1,"cushion"],
	[-0.3,6.9,1.7,"jar"], [-1.9,8.6,1.6,"cushion"],
	[-4.5,10.4,1.5,"cushion"], [-1.7,12.3,1.5,"jangdokdae"],
	[1.3,14.3,1.3,"jar"], [4.3,16.3,1.3,"cushion"],
	[1.1,18.5,1.1,"cushion"], [-2.1,20.7,1.05,"jar"],
	[-5.4,23.0,0.95,"cushion"], [-2.0,25.3,0.9,"cushion"]
]

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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var previous_top := 0.0
	for i in OBSTACLE_BASE.size():
		var base: Array = OBSTACLE_BASE[i]
		var progress := float(i)/maxf(1.0,float(OBSTACLE_BASE.size()-1))
		var previous_base_top := 0.0 if i == 0 else float(OBSTACLE_BASE[i-1][1])
		var rise := float(base[1])-previous_base_top+rng.randf_range(-0.03,0.03)*lerpf(0.4,1.0,progress)
		previous_top += rise
		var x_jitter := rng.randf_range(-0.06,0.06)*lerpf(0.35,1.0,progress)
		var width := float(base[2])*rng.randf_range(0.98,1.02)
		ROUTE.append([float(base[0])+x_jitter,previous_top,width,base[3]])

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
	for row in ROUTE:
		var x := float(row[0])
		var top := float(row[1])
		var width := float(row[2])
		var kind := str(row[3])
		if kind == "jar":
			var jar_scale := 1.0 if top < 2.0 else 0.6
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
	status.text = "항아리 · 장독대 · 방석 → 음식 등반  |  최고 %.1fm\nA/D 이동 · SPACE 2단 점프 · ESC 로비" % best
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
