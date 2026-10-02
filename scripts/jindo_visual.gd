extends Node3D
## One continuous skinned coat; actual Skeleton3D + six imported clips.
const CLIPS := {"idle":2.4,"run":0.65,"jump":0.5,"double_jump":0.4,"fall":0.8,"land":0.24}
const ASSET := "res://assets/characters/jindo_v4/jindo_v4.glb"
static var cached_scene: PackedScene
var player: AnimationPlayer
var skeleton: Skeleton3D
var animation_state := "idle"
var clock := 0.0
var clip_names: Dictionary = {}

func _ready() -> void:
	if cached_scene == null:
		cached_scene = load(ASSET) as PackedScene
		assert(cached_scene != null, "Cannot load imported Jindo GLB")
	var imported := cached_scene.instantiate()
	add_child(imported)
	for mesh in imported.find_children("*","MeshInstance3D",true,false):
		if "ShortCoatTufts" in mesh.name:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player = imported.find_children("*","AnimationPlayer",true,false)[0]
	skeleton = imported.find_children("*","Skeleton3D",true,false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in player.get_animation_list():
		var short_name := str(clip).get_file()
		clip_names[short_name] = clip
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if short_name in ["idle","run","fall"] else Animation.LOOP_NONE
	pose("idle",0)

func animate(delta: float, state: String) -> void:
	if state != animation_state:
		animation_state = state
		clock = 0
		player.play(clip_names[state],0.07)
	else:
		clock += delta
	player.advance(delta)

func pose(state: String, seconds: float) -> void:
	animation_state = state
	clock = seconds
	player.play(clip_names[state])
	player.seek(seconds,true)
	skeleton.force_update_all_bone_transforms()

func get_chest_pitch() -> float:
	return skeleton.get_bone_pose_rotation(skeleton.find_bone("Torso")).get_euler().z
