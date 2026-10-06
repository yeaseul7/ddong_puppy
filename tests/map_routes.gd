extends SceneTree

func _initialize() -> void:
	var scene: Node = load("res://map_2d.tscn").instantiate()
	root.add_child(scene)
	var platforms: Array[Node] = scene.get_node("Platforms").get_children()
	var easy: Array = platforms.filter(func(node): return node.get_meta("branch", "") == "easy")
	var shortcut: Array = platforms.filter(func(node): return node.get_meta("branch", "") == "shortcut")
	var merge: Array = platforms.filter(func(node): return node.get_meta("branch", "") == "merge")
	assert(easy.size() >= 6)
	assert(shortcut.size() >= 4)
	assert(merge.size() == 1)
	assert(shortcut.size() < easy.size())
	for platform in platforms:
		var polygons: Array[Node] = platform.find_children("*", "CollisionPolygon2D", true, false)
		var shapes: Array[Node] = platform.find_children("*", "CollisionShape2D", true, false)
		assert(polygons.size() == 1, "%s must use exactly one polygon" % platform.name)
		assert(shapes.is_empty(), "%s must not use rectangle/primitive collision" % platform.name)
		assert(polygons[0].polygon.size() >= 6, "%s polygon is too coarse" % platform.name)
	print("PASS: early climb + %d-step easy detour + %d-step shortcut; one polygon per object" % [easy.size(),shortcut.size()])
	quit()
