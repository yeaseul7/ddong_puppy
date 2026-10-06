extends SceneTree

const SOURCE := "res://map_2d_2.tscn"
const OUTPUT := "res://map_2d_2_rebuilt.tmp.tscn"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var map: Node = load(SOURCE).instantiate()
	root.add_child(map)
	await process_frame
	map.set_process(false)
	var rebuilt := 0
	for platform in map.get_node("Platforms").get_children():
		if not platform.get_meta("route",false):
			continue
		var legacy := platform.find_children("*","CollisionShape2D",true,false)
		if legacy.is_empty():
			continue
		var sprites := platform.find_children("*","Sprite2D",true,false)
		assert(sprites.size() == 1)
		for shape in legacy:
			shape.get_parent().remove_child(shape)
			shape.free()
		var sprite := sprites[0] as Sprite2D
		var image := sprite.texture.get_image()
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,0.08)
		var outlines := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),16.0)
		var created := 0
		for outline in outlines:
			if outline.size() < 3 or absf(polygon_area(outline)) < 1200.0:
				continue
			var polygon := PackedVector2Array()
			for point in outline:
				var sprite_local := point-Vector2(image.get_size())*0.5
				polygon.append(platform.to_local(sprite.to_global(sprite_local)))
			var convex_parts: Array[PackedVector2Array] = []
			if platform.get_meta("kind","") == "tall_planter":
				convex_parts = [Geometry2D.convex_hull(polygon)]
			else:
				convex_parts = Geometry2D.decompose_polygon_in_convex(polygon)
			if convex_parts.is_empty():
				convex_parts = [Geometry2D.convex_hull(polygon)]
			for part in convex_parts:
				var collision := CollisionPolygon2D.new()
				collision.name = "AlphaCollision%02d" % created
				collision.polygon = part
				platform.add_child(collision)
				collision.owner = map
				created += 1
		assert(created > 0)
		rebuilt += 1
		print("REBUILT ",platform.name," polygons=",created)
	root.remove_child(map)
	var packed := PackedScene.new()
	assert(packed.pack(map) == OK)
	assert(ResourceSaver.save(packed,OUTPUT) == OK)
	map.free()
	print("PASS: rebuilt ",rebuilt," legacy colliders into alpha polygons")
	quit()

func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		var a := points[i]
		var b := points[(i+1)%points.size()]
		area += a.x*b.y-b.x*a.y
	return area*0.5
