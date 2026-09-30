@tool
extends Node3D

@export_enum("jar", "jangdokdae", "cushion") var kind := "jar"
@export_range(0, 2) var variant := 0

func material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

# Ring profiles produce rounded silhouettes rather than cylinder placeholders.
func rings(parent: Node3D, profile: Array, color: Color, square := false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for ring in profile:
		for i in 49:
			var angle := TAU * float(i) / 48.0
			var x := cos(angle)
			var z := sin(angle)
			if square:
				x = signf(x) * pow(absf(x), 0.35)
				z = signf(z) * pow(absf(z), 0.35)
			points.append(Vector3(x * float(ring[1]),float(ring[0]),z * float(ring[1]) * (0.72 if square else 1.0)))
	for row in profile.size()-1:
		for i in 48:
			var a := row*49+i
			for index in [a,a+1,a+49,a+1,a+50,a+49]:
				st.add_vertex(points[index])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var mat := material(color,0.94 if square else 0.32)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = at
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = material(color,0.95)
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func make_jar(at: Vector3, height: float, radius: float) -> void:
	var body := StaticBody3D.new()
	body.position = at
	add_child(body)
	var profile: Array = []
	var profiles := [
		[[0,0],[0,0.62],[0.06,0.74],[0.24,0.93],[0.52,1.0],[0.72,0.93],[0.85,0.72],[0.9,0.68],[0.92,0.76]],
		[[0,0],[0,0.50],[0.08,0.65],[0.30,0.84],[0.65,0.88],[0.79,0.75],[0.85,0.55],[0.9,0.55],[0.92,0.76]],
		[[0,0],[0,0.72],[0.08,0.9],[0.25,1.08],[0.5,1.1],[0.72,1.02],[0.85,0.83],[0.9,0.72],[0.92,0.76]]]
	for pair in profiles[variant]:
		profile.append([pair[0]*height,pair[1]*radius])
	var mesh := rings(body,profile,[Color("69412d"),Color("393c32"),Color("ad7954")][variant])
	var col := CollisionShape3D.new()
	col.shape = mesh.mesh.create_convex_shape()
	body.add_child(col)
	# Broad, flat ceramic lid provides a visible and accurate landing surface.
	var lid := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius*0.84
	cylinder.bottom_radius = radius*0.9
	cylinder.height = height*0.08
	lid.mesh = cylinder
	lid.position.y = height*0.96
	lid.material_override = material([Color("926342"),Color("666955"),Color("c59a6b")][variant],0.28)
	body.add_child(lid)
	var lid_col := CollisionShape3D.new()
	var lid_shape := CylinderShape3D.new()
	lid_shape.radius = radius*0.84
	lid_shape.height = height*0.08
	lid_col.shape = lid_shape
	lid_col.position.y = height*0.96
	body.add_child(lid_col)
	for y in [0.25,0.52]:
		rings(body,[[height*(y-0.008),radius*(0.94 if y<0.3 else 1.005)],[height*(y+0.008),radius*(0.94 if y<0.3 else 1.005)]],Color("9a7150"))

func _ready() -> void:
	if kind == "jar":
		make_jar(Vector3.ZERO,1.1,0.8)
	elif kind == "jangdokdae":
		# A masonry plinth with staggered pots, built as one reusable prop.
		box(self,Vector3(0,0.55,0),Vector3(2.0,1.1,1.6),[Color("7d7a67"),Color("986d52"),Color("8e9691")][variant])
		for i in 5:
			box(self,Vector3(-0.8+i*0.4,1.04,0),Vector3(0.38,0.12,1.68),Color("b2aa91"))
		make_jar(Vector3(0,1.1,0),1.3,0.75)
		for i in (variant+2):
			var x := -0.72 + float(i) * 1.44 / float(variant+1)
			make_jar(Vector3(x,1.1,-0.72),0.55+0.12*i,0.26+0.03*(i%2))
		for row in 3:
			for column in 4:
				box(self,Vector3(-0.75+column*0.5,0.18+row*0.3,0.81),Vector3(0.47,0.27,0.08),[Color("95907b"),Color("b08263"),Color("b1b6ae")][variant])
	else:
		var body := StaticBody3D.new()
		add_child(body)
		var mesh := rings(body,[[0,0],[0.025,0.78],[0.10,0.98],[0.16,1.0],[0.24,0.88],[0.29,0.72],[0.30,0],[0.30,0]],[Color("985d62"),Color("527b6e"),Color("b28b43")][variant],variant != 1)
		var collision := CollisionShape3D.new()
		collision.shape = mesh.mesh.create_convex_shape()
		body.add_child(collision)
		rings(body,[[0.145,1.005],[0.16,1.005]],Color("e1bf86"),variant != 1)

		if variant == 2:
			for x in [-0.48,0.0,0.48]:
				var stitch := rings(body,[[0.275,0],[0.285,0.045],[0.295,0]],Color("efd7b0"))
				stitch.position.x = x
