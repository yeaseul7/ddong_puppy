extends Node2D
@export var summit_height := 11000.0
@onready var dog: CharacterBody2D = $Dog
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var status: Label = $HUD/Status
var best := 0.0
func _ready() -> void:
	var keys := {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in keys[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action,event)
	camera.position = Vector2(dog.position.x*0.35,-330)
	update_background()
func _process(delta: float) -> void:
	best = maxf(best,-dog.position.y/100)
	camera.position = camera.position.lerp(Vector2(clampf(dog.position.x*0.35,-150,150),minf(-330,dog.position.y-170)),1-exp(-5*delta))
	update_background()
	status.text = "똥강아지 · 2D  |  최고 %.1fm\nA/D 이동 · SPACE 2단 점프 · ESC 로비" % best
func update_background() -> void:
	var view := get_viewport_rect().size / camera.zoom
	var tex := background.texture.get_size()
	var factor := maxf(view.x/tex.x,view.y/tex.y)*1.04
	background.scale = Vector2.ONE*factor
	var progress := clampf((-camera.position.y-330)/(summit_height+170-330),0,1)
	background.position = camera.position+Vector2(0,(progress-0.5)*maxf(0,tex.y*factor-view.y))
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://lobby.tscn")
