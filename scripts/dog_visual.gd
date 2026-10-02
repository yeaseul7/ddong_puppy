extends Node3D
## Rigid-jointed, procedural 3D dog. Local +X is forward; +Y is up.
## Collision and translation belong to the CharacterBody, never to animations.

const CLIPS := {"idle": 2.0, "run": 0.6, "jump": 0.5, "double_jump": 0.4, "fall": 0.8, "land": 0.24}
var torso: Node3D
var head: Node3D
var tail: Node3D
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var ears: Array[Node3D] = []
var joints: Array[Node3D] = []
var materials: Dictionary = {}
var animation_state := "idle"
var clock := 0.0

func _ready() -> void:
	name = "WhiteDogV3"
	materials = {
		"fur": material("eae9e3"), "cream": material("deddd5"),
		"pink": material("d3aaa6"), "dark": material("242629"),
		"eye": material("47352b"), "glint": material("ffffff")}
	materials.dark.roughness = 0.32
	materials.eye.roughness = 0.25
	build()
	pose("idle", 0.0)

func material(hex: String, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.metallic = metallic
	mat.roughness = 0.75 if metallic == 0 else 0.35
	return mat

func joint(parent: Node3D, id: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = id
	node.position = at
	parent.add_child(node)
	joints.append(node)
	return node

func shape(parent: Node3D, id: String, mesh: Mesh, at: Vector3, tint: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = id
	node.mesh = mesh
	node.position = at
	node.material_override = materials[tint]
	parent.add_child(node)
	return node

func oval(parent: Node3D, id: String, at: Vector3, size: Vector3, tint: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 24
	mesh.rings = 16
	var node := shape(parent, id, mesh, at, tint)
	node.scale = size
	return node

func block(parent: Node3D, id: String, at: Vector3, size: Vector3, tint: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(parent, id, mesh, at, tint)

func cylinder(parent: Node3D, id: String, at: Vector3, radius: float, height: float, tint: String) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	return shape(parent, id, mesh, at, tint)

func ear_mesh() -> ArrayMesh:
	# A tapered triangular ear, broad across Z and thin across X.
	var pts := [Vector3(-0.045,0,-0.10),Vector3(-0.045,0,0.10),Vector3(0.005,0.26,0),Vector3(0.045,0,-0.10),Vector3(0.045,0,0.10),Vector3(0.035,0.26,0)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,2,1,3,4,5,0,3,5,0,5,2,1,2,5,1,5,4,0,1,4,0,4,3]:
		surface.add_vertex(pts[index])
	surface.generate_normals()
	return surface.commit()

func tail_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	for ring in 33:
		var t := float(ring)/32
		var angle := -PI/2-t*4.1
		var center := Vector3(0.03+cos(angle)*0.20,0.24+sin(angle)*0.23,0)
		var outward := Vector3(cos(angle),sin(angle),0).normalized()
		var radius := 0.063*(1.0-pow(t,4)*0.8)
		for segment in 12:
			var theta := TAU*segment/12
			var normal := outward*cos(theta)+Vector3.FORWARD*sin(theta)
			vertices.append(center+normal*radius)
			normals.append(normal)
	for ring in 32:
		for segment in 12:
			var a := ring*12+segment
			var b := ring*12+(segment+1)%12
			var c := a+12
			var d := b+12
			for index in [a,b,c,b,d,c]:
				surface.set_normal(normals[index])
				surface.add_vertex(vertices[index])
	return surface.commit()

func loft(profile: Array) -> ArrayMesh:
	# Smooth continuous cross-sections instead of separate body/head balls.
	var vertices: Array[Vector3] = []
	var smooth_profile: Array[Vector4] = []
	for step in profile.size()-1:
		var controls: Array[Vector4] = []
		for offset in [-1,0,1,2]:
			var row: Array = profile[clampi(step+offset,0,profile.size()-1)]
			controls.append(Vector4(row[0],row[1],row[2],row[3]))
		for segment in 4:
			var t := float(segment)/4
			var p := 0.5*((2*controls[1])+(-controls[0]+controls[2])*t+(2*controls[0]-5*controls[1]+4*controls[2]-controls[3])*t*t+(-controls[0]+3*controls[1]-3*controls[2]+controls[3])*t*t*t)
			p.z = maxf(p.z,0.001)
			p.w = maxf(p.w,0.001)
			smooth_profile.append(p)
	var last: Array = profile[-1]
	smooth_profile.append(Vector4(last[0],last[1],last[2],last[3]))
	for row in smooth_profile:
		for i in 33:
			var angle := TAU*float(i)/32
			vertices.append(Vector3(row[0],row[1]+cos(angle)*row[2],sin(angle)*row[3]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in smooth_profile.size()-1:
		for i in 32:
			var a := row*33+i
			for index in [a,a+33,a+1,a+1,a+33,a+34]:
				surface.add_vertex(vertices[index])
	surface.index()
	surface.generate_normals()
	return surface.commit()

func build() -> void:
	torso = joint(self,"Torso",Vector3(0,0.76,0))
	shape(torso,"Body",loft([
		[-0.65,0.03,0.001,0.001],[-0.61,0.035,0.12,0.10],
		[-0.52,0.025,0.23,0.18],[-0.37,0.025,0.24,0.195],
		[-0.18,0.055,0.20,0.18],[0.03,0.055,0.205,0.18],
		[0.23,0.03,0.27,0.215],[0.37,0.10,0.31,0.21],
		[0.47,0.19,0.25,0.17],[0.55,0.24,0.001,0.001]
	]),Vector3.ZERO,"fur")
	# Taller sloping neck, relatively small head and a tapered adult-dog muzzle.
	var neck := oval(torso,"Neck",Vector3(0.40,0.27,0),Vector3(0.32,0.57,0.31),"fur")
	neck.rotation.z = -0.34
	head = joint(torso,"Head",Vector3(0.50,0.49,0))
	shape(head,"Face",loft([
		[-0.20,0.035,0.001,0.001],[-0.16,0.035,0.11,0.10],
		[-0.09,0.03,0.165,0.14],[0.015,0.025,0.17,0.15],
		[0.105,0.005,0.13,0.125],[0.17,-0.023,0.077,0.092],
		[0.25,-0.03,0.059,0.071],[0.34,-0.025,0.044,0.053],
		[0.375,-0.025,0.001,0.001]
	]),Vector3.ZERO,"fur")
	oval(head,"Nose",Vector3(0.354,-0.008,0),Vector3(0.069,0.057,0.086),"dark")
	oval(head,"NoseHighlight",Vector3(0.374,0.009,0.012),Vector3(0.010,0.007,0.022),"cream")
	for side in [-1.0,1.0]:
		var suffix := "Near" if side > 0 else "Far"
		var eye := oval(head,"Eye"+suffix,Vector3(0.074,0.069,side*0.129),Vector3(0.066,0.042,0.024),"dark")
		eye.rotation.y = side*0.32
		oval(head,"Iris"+suffix,Vector3(0.083,0.069,side*0.140),Vector3(0.031,0.030,0.011),"eye")
		oval(head,"Glint"+suffix,Vector3(0.087,0.078,side*0.148),Vector3(0.011,0.012,0.006),"glint")
		oval(head,"GlintSmall"+suffix,Vector3(0.073,0.062,side*0.146),Vector3(0.006,0.006,0.004),"glint")
		# A tiny lip at the corner, no dark line across the entire muzzle.
		var lip := oval(head,"Smile"+suffix,Vector3(0.27,-0.054,side*0.059),Vector3(0.115,0.006,0.009),"dark")
		lip.rotation.z = 0.10
		var ear := joint(head,"Ear"+suffix,Vector3(-0.055,0.155,side*0.10))
		var outer := shape(ear,"Outer",ear_mesh(),Vector3.ZERO,"fur")
		outer.scale = Vector3(1.5,0.90,0.94)
		var inset := shape(ear,"Inner",ear_mesh(),Vector3(0.032,0.022,0),"pink")
		inset.material_override = materials.pink
		inset.scale = Vector3(1.06,0.63,0.59)
		ear.rotation.x = side*0.15
		ears.append(ear)
		for front in [true,false]:
			var id := ("Front" if front else "Back")+suffix
			var hip := joint(torso,id,Vector3(0.34 if front else -0.48,-0.065,side*0.145))
			# Tapered anatomical limbs replace the stacked ball-like joints.
			var upper := shape(hip,"Upper",loft([
				[-0.11,0,0.001,0.001],[-0.06,0,0.075 if front else 0.12,0.08],
				[0.03,0,0.085 if front else 0.135,0.085],
				[0.15,0.0 if front else 0.055,0.061 if front else 0.085,0.065],
				[0.29,0.0 if front else 0.055,0.041,0.046],[0.36,0.0 if front else 0.055,0.001,0.001]
			]),Vector3.ZERO,"fur")
			upper.rotation.z = -PI/2
			var knee := joint(hip,"Knee",Vector3(0 if front else 0.055,-0.30,0))
			var shin := shape(knee,"Shin",loft([
				[-0.06,0,0.001,0.001],[-0.025,0,0.045,0.049],
				[0.08,0 if front else -0.03,0.043,0.045],
				[0.22,0 if front else -0.095,0.033,0.036],
				[0.30,0 if front else -0.09,0.035,0.037],[0.35,0 if front else -0.08,0.001,0.001]
			]),Vector3.ZERO,"fur")
			shin.rotation.z = -PI/2
			oval(knee,"Paw",Vector3(0.032 if front else -0.055,-0.35,0),Vector3(0.16,0.085,0.10),"fur")
			hips.append(hip)
			knees.append(knee)
	tail = joint(torso,"Tail",Vector3(-0.57,0.17,0))
	shape(tail,"CurledTail",tail_mesh(),Vector3.ZERO,"fur")

func animate(delta: float, state: String) -> void:
	if state != animation_state:
		animation_state = state
		clock = 0.0
	else:
		clock += delta
	pose(state,clock)

func pose(state: String, seconds: float) -> void:
	var phase := seconds/float(CLIPS.get(state,1.0))*TAU
	torso.position = Vector3(0,0.76,0)
	torso.rotation = Vector3.ZERO
	torso.scale = Vector3.ONE
	head.rotation = Vector3.ZERO
	tail.rotation = Vector3(0.10*sin(phase),0,0)
	for i in ears.size():
		ears[i].rotation = Vector3((-1.0 if i == 0 else 1.0)*0.15,0,0)
	for i in hips.size():
		hips[i].rotation = Vector3.ZERO
		knees[i].rotation = Vector3.ZERO
	match state:
		"idle":
			torso.scale.y = 1.0+sin(phase)*0.012
			head.rotation.z = sin(phase)*0.025
			tail.rotation.x = sin(phase*2)*0.16
		"run":
			torso.position.y += absf(sin(phase))*0.025
			head.rotation.z = 0.04
			for i in hips.size():
				var stride := phase + (PI if i in [1,2] else 0.0)
				hips[i].rotation.z = sin(stride)*0.60
				knees[i].rotation.z = -maxf(0,sin(stride))*0.75
		"jump", "double_jump":
			# Head and chest rise UP, paws fold under the belly. No forward lunge.
			var kick := exp(-seconds*12.0)
			torso.rotation.z = 0.38+kick*0.13
			torso.position.y += 0.08
			head.rotation.z = 0.16
			for i in hips.size():
				var front := i%2 == 0
				hips[i].rotation.z = -0.75 if front else 0.62-kick*0.65
				knees[i].rotation.z = 1.1 if front else -1.10+kick*0.50
			tail.rotation.z = -0.16
		"fall":
			torso.rotation.z = 0.10
			head.rotation.z = -0.18
			for i in hips.size():
				hips[i].rotation.z = -0.16 if i%2 == 0 else 0.16
				knees[i].rotation.z = 0.20 if i%2 == 0 else -0.20
		"land":
			var squash := maxf(0,1.0-seconds/float(CLIPS.land))
			torso.position.y -= 0.08*squash
			torso.scale.y = 1.0-0.08*squash
			for i in hips.size():
				hips[i].rotation.z = -0.5*squash
				knees[i].rotation.z = 0.9*squash
