extends Node3D

var placed_count := 0
var placement_seed := 0

func scatter(route: Array, seed_value := -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	placement_seed = rng.seed
	var paths: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/imported/food_pack_manifest.json"))
	# Fisher-Yates: every imported model appears once, with a new order per visit.
	for i in range(paths.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var saved = paths[i]
		paths[i] = paths[j]
		paths[j] = saved
	for index in paths.size():
		var row: Array = route[index]
		var holder := StaticBody3D.new()
		holder.name = "Food_%02d" % index
		add_child(holder)
		var model := (load(paths[index]) as PackedScene).instantiate() as Node3D
		holder.add_child(model)
		var vertices := PackedVector3Array()
		var meshes := model.find_children("*","MeshInstance3D",true,false)
		for node in meshes:
			var transform: Transform3D = holder.global_transform.affine_inverse()*node.global_transform
			for surface in node.mesh.get_surface_count():
				var arrays: Array = node.mesh.surface_get_arrays(surface)
				for vertex in arrays[Mesh.ARRAY_VERTEX]:
					vertices.append(transform*vertex)
		assert(not vertices.is_empty())
		var bounds := AABB(vertices[0],Vector3.ZERO)
		for vertex in vertices: bounds = bounds.expand(vertex)
		# Normalize footprint, retaining the food silhouette with a shallow climbable profile.
		var size := Vector3(float(row[2])/maxf(bounds.size.x,0.001),0.35/maxf(bounds.size.y,0.001),1.4/maxf(bounds.size.z,0.001))
		var offset := Vector3(bounds.get_center().x,bounds.end.y,bounds.get_center().z)
		model.scale *= size
		model.position -= offset*size
		var collision := CollisionShape3D.new()
		var shape := ConvexPolygonShape3D.new()
		var points := PackedVector3Array()
		for vertex in vertices: points.append((vertex-offset)*size)
		shape.points = points
		collision.shape = shape
		holder.add_child(collision)
		holder.position = Vector3(row[0],row[1],0)
		placed_count += 1
