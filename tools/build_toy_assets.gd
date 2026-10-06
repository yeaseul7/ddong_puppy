extends SceneTree

const ITEMS := [
	"red_food_container", "kimchi_bowl", "tennis_rope_toy", "plush_fish",
	"spiky_bone_toy", "plush_cow", "vegetable_toys", "bumpy_balls",
	"wavy_rope", "chicken_bone_toy", "plush_elephant", "braided_rope", "rope_ball"
]
const PIXEL_SCALE := 0.14

func _initialize() -> void:
	call_deferred("build_all")

func build_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/2d/toys"))
	for item in ITEMS:
		var image_path := "res://assets/2d/toys/%s.png" % item
		var image := Image.load_from_file(image_path)
		assert(image != null and not image.is_empty())
		var used := image.get_used_rect()
		assert(used.size.x > 0 and used.size.y > 0)

		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,0.08)
		var outlines := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),6.0)
		assert(not outlines.is_empty())

		var body := StaticBody2D.new()
		body.name = item
		body.set_meta("route",true)
		body.set_meta("kind",item)

		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load(image_path)
		sprite.scale = Vector2.ONE*PIXEL_SCALE
		var center_x := used.position.x+used.size.x*0.5
		sprite.position = Vector2((image.get_width()*0.5-center_x)*PIXEL_SCALE,(image.get_height()*0.5-used.position.y)*PIXEL_SCALE)
		body.add_child(sprite)
		sprite.owner = body

		var collision_count := 0
		for outline in outlines:
			if outline.size() < 3 or absf(polygon_area(outline)) < 1200.0:
				continue
			var polygon := PackedVector2Array()
			for point in outline:
				polygon.append(Vector2((point.x-center_x)*PIXEL_SCALE,(point.y-used.position.y)*PIXEL_SCALE))
			var collision := CollisionPolygon2D.new()
			collision.name = "Collision%02d" % collision_count
			collision.polygon = polygon
			body.add_child(collision)
			collision.owner = body
			collision_count += 1
		assert(collision_count > 0)

		var packed := PackedScene.new()
		assert(packed.pack(body) == OK)
		assert(ResourceSaver.save(packed,"res://scenes/2d/toys/%s.tscn" % item) == OK)
		body.free()
		print("BUILT ",item," polygons=",collision_count)
	quit()

func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		var a := points[i]
		var b := points[(i+1)%points.size()]
		area += a.x*b.y-b.x*a.y
	return area*0.5
