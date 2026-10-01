extends Node3D

var placed_count := 0
var placement_seed := 0

func scatter(route: Array, start: Vector2, start_width: float, seed_value := -1) -> void:
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
	var previous_x := start.x
	var previous_top := start.y
	var previous_width := start_width
	var direction := 1.0
	for index in paths.size():
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
		var progress := float(index)/maxf(1.0,float(paths.size()-1))
		var target_width := lerpf(2.3,1.4,pow(progress,0.8))
		# Fit the model inside the available footprint with one uniform scale so the
		# original food proportions are preserved instead of flattening its height.
		var uniform_scale := minf(
			target_width/maxf(bounds.size.x,0.001),
			1.4/maxf(bounds.size.z,0.001)
		)
		var size := Vector3.ONE*uniform_scale
		var landing_width := bounds.size.x*uniform_scale
		# Taller gaps, smaller landing areas and wider clearances are introduced
		# gradually. The actual scaled model width determines the next horizontal gap.
		var clearance := lerpf(0.25,0.60,progress)+rng.randf_range(-0.08,0.08)
		var horizontal_step := 0.5*(previous_width+landing_width)+clearance
		var next_x := previous_x+direction*horizontal_step
		if absf(next_x) > 6.7:
			direction *= -1.0
			next_x = previous_x+direction*horizontal_step
		elif rng.randf() < lerpf(0.08,0.24,progress):
			direction *= -1.0
		var narrowness := 1.0-clampf(landing_width/2.3,0.0,1.0)
		var rise := lerpf(1.28,1.68,progress)+0.12*narrowness+rng.randf_range(-0.08,0.08)
		var row := [next_x,previous_top+rise,landing_width,"food"]
		route.append(row)
		var offset := Vector3(bounds.get_center().x,bounds.end.y,bounds.get_center().z)
		model.scale *= size
		model.position -= offset*size
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(landing_width,0.16,minf(bounds.size.z*uniform_scale,1.4))
		collision.shape = shape
		collision.position.y = -0.08
		holder.add_child(collision)
		holder.position = Vector3(row[0],row[1],0)
		previous_x = float(row[0])
		previous_top = float(row[1])
		previous_width = landing_width
		placed_count += 1
