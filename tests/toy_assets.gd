extends SceneTree

const ITEMS := [
	"red_food_container", "kimchi_bowl", "tennis_rope_toy", "plush_fish",
	"spiky_bone_toy", "plush_cow", "vegetable_toys", "bumpy_balls",
	"wavy_rope", "chicken_bone_toy", "plush_elephant", "braided_rope", "rope_ball"
]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for item in ITEMS:
		var texture: Texture2D = load("res://assets/2d/toys/%s.png" % item)
		assert(texture != null)
		var image := texture.get_image()
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		var scene: PackedScene = load("res://scenes/2d/toys/%s.tscn" % item)
		assert(scene != null)
		var body := scene.instantiate()
		var collisions := body.find_children("*","CollisionPolygon2D",true,false)
		assert(not collisions.is_empty())
		for collision in collisions:
			assert(collision.polygon.size() >= 3)
		body.free()

	var map: Node = load("res://map_2d_2.tscn").instantiate()
	root.add_child(map)
	await process_frame
	var placed: Array = map.get_node("Platforms").get_children().filter(func(node): return node.get_meta("kind","") in ITEMS)
	assert(placed.size() == ITEMS.size())
	assert(map.summit_height == 5160.0)
	assert(map.route_summit_height == 5160.0)
	map.camera.position.y = -(map.route_summit_height+170.0)
	map.update_background()
	var view: Vector2 = map.get_viewport_rect().size/map.camera.zoom
	var image_height: float = map.background.texture.get_height()*map.background.scale.y
	var image_top: float = map.background.position.y-image_height*0.5
	var view_top: float = map.camera.position.y-view.y*0.5
	assert(image_top <= view_top+1.0)
	print("PASS: 13 transparent assets, silhouette polygons and map placements")
	quit()
