extends StaticBody3D
## Solid soil reaches below any normal camera view, with the exact top at Y=0.
func _ready() -> void:
	name = "SolidGround"
	var size := Vector3(80,40,8)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position.y = -size.y/2
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float depth=max(0.0,-world.y);
 float grain=noise(world.xy*13.0);
 float strata=noise(vec2(world.x*0.7,world.y*2.0));
 vec3 soil=mix(vec3(0.25,0.17,0.115),vec3(0.46,0.32,0.205),strata*0.7+grain*0.3);
 float edge=0.13+noise(vec2(world.x*3.0,0.0))*0.08;
 vec3 top=mix(vec3(0.44,0.40,0.24),vec3(0.57,0.51,0.31),grain);
 ALBEDO=mix(top,soil,smoothstep(edge,edge+0.12,depth));
 ROUGHNESS=1.0;
}
"""
	mat.shader = shader
	mesh.material_override = mat
	add_child(mesh)
	var collision := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = size
	collision.shape = bounds
	collision.position = mesh.position
	add_child(collision)
