extends SceneTree
const NAMES := ["onggi","rattan_chair","brick_well","parasol_table","stereo","cabinet","quilt","blue_chair","planters","sliding_door"]
var polygons := {
"onggi":[[Vector2(340,130),Vector2(880,130),Vector2(1060,390),Vector2(1120,680),Vector2(1040,1040),Vector2(880,1170),Vector2(390,1170),Vector2(220,1000),Vector2(130,680),Vector2(200,390)]],
"quilt":[[Vector2(510,280),Vector2(790,280),Vector2(1110,340),Vector2(1230,450),Vector2(1200,850),Vector2(1040,1050),Vector2(190,930),Vector2(25,800),Vector2(40,620)]],
"sliding_door":[[Vector2(335,40),Vector2(910,40),Vector2(910,1220),Vector2(335,1210)]],
"cabinet":[[Vector2(350,70),Vector2(865,70),Vector2(865,200),Vector2(970,200),Vector2(970,365),Vector2(1030,365),Vector2(1030,1160),Vector2(220,1160),Vector2(220,780),Vector2(255,780),Vector2(255,365),Vector2(300,365),Vector2(300,170),Vector2(350,170)]],
"stereo":[[Vector2(65,350),Vector2(400,350),Vector2(400,875),Vector2(30,850)],[Vector2(850,350),Vector2(1200,350),Vector2(1200,890),Vector2(850,900)],[Vector2(400,490),Vector2(850,490),Vector2(850,880),Vector2(400,875)]],
"brick_well":[[Vector2(470,300),Vector2(780,300),Vector2(1020,410),Vector2(1070,600),Vector2(1040,840),Vector2(860,930),Vector2(350,930),Vector2(200,730),Vector2(210,450)]],
"planters":[[Vector2(20,740),Vector2(1180,820),Vector2(1220,950),Vector2(1090,995),Vector2(20,900)],[Vector2(115,650),Vector2(290,650),Vector2(300,750),Vector2(115,735)],[Vector2(320,680),Vector2(550,700),Vector2(560,780),Vector2(320,760)],[Vector2(560,700),Vector2(800,720),Vector2(800,800),Vector2(560,780)],[Vector2(820,720),Vector2(1000,750),Vector2(1000,820),Vector2(820,800)],[Vector2(1030,740),Vector2(1180,750),Vector2(1180,830),Vector2(1030,830)]],
"blue_chair":[[Vector2(410,90),Vector2(620,90),Vector2(720,170),Vector2(710,610),Vector2(470,650),Vector2(210,370),Vector2(205,230)],[Vector2(470,620),Vector2(1000,650),Vector2(1040,760),Vector2(475,800)],[Vector2(480,760),Vector2(560,760),Vector2(530,1180),Vector2(445,1180)],[Vector2(965,700),Vector2(1040,700),Vector2(1080,1110),Vector2(1000,1110)]],
"rattan_chair":[[Vector2(700,55),Vector2(960,55),Vector2(1110,190),Vector2(1040,660),Vector2(520,680),Vector2(530,330),Vector2(565,160)],[Vector2(250,710),Vector2(650,660),Vector2(960,760),Vector2(770,930),Vector2(240,850)],[Vector2(240,850),Vector2(320,850),Vector2(350,1060),Vector2(270,1070)],[Vector2(800,870),Vector2(890,870),Vector2(860,1150),Vector2(780,1150)]],
"parasol_table":[[Vector2(480,85),Vector2(770,85),Vector2(1010,190),Vector2(1210,370),Vector2(1200,430),Vector2(60,430),Vector2(40,370),Vector2(260,180)],[Vector2(610,430),Vector2(650,430),Vector2(650,860),Vector2(610,860)],[Vector2(410,780),Vector2(810,780),Vector2(950,850),Vector2(920,940),Vector2(320,940),Vector2(300,850)],[Vector2(440,940),Vector2(790,940),Vector2(790,1170),Vector2(440,1170)]]}
# Anchor at a real horizontal rim/top, not at the transparent image border.
var anchors := {"onggi":Vector2(610,130),"quilt":Vector2(650,280),"sliding_door":Vector2(620,40),"cabinet":Vector2(605,70),"stereo":Vector2(230,350),"brick_well":Vector2(625,300),"planters":Vector2(200,650),"blue_chair":Vector2(515,90),"rattan_chair":Vector2(830,55),"parasol_table":Vector2(625,85)}
func add_owned(parent: Node, child: Node, owner_node: Node) -> void:
	parent.add_child(child)
	child.owner = owner_node
func make_prop(kind: String, width: float, height_limit := 155.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = kind
	var texture := load("res://assets/2d/household/"+kind+".png") as Texture2D
	var bounds := texture.get_image().get_used_rect()
	var factor := width/maxf(bounds.size.x,1)
	# Tall furniture keeps its proportions but cannot extend into the previous tier.
	factor = minf(factor,height_limit/maxf(bounds.size.y,1))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = -anchors[kind]*factor
	sprite.scale = Vector2.ONE*factor
	add_owned(body,sprite,body)
	for points in polygons[kind]:
		var collision := CollisionPolygon2D.new()
		var scaled := PackedVector2Array()
		for point in points: scaled.append((point-anchors[kind])*factor)
		collision.polygon = scaled
		add_owned(body,collision,body)
	return body
func run() -> void:
	for kind in NAMES:
		var prop := make_prop(kind,220)
		var packed := PackedScene.new()
		assert(packed.pack(prop)==OK)
		assert(ResourceSaver.save(packed,"res://scenes/2d/household/"+kind+".tscn")==OK)
		prop.free()
	var packed_map := load("res://map_2d.tscn") as PackedScene
	var scene := packed_map.instantiate()
	var platforms := scene.get_node("Platforms")
	var index := 0
	for old in platforms.get_children():
		var width: float = old.get_node("CollisionShape2D").shape.size.x/0.84
		var kind: String = NAMES[index%10]
		# Preserve the large low-ceiling floor and the thin overhead/recovery pads.
		if index in [3,5,7,9,10,11,17,18]: kind = "quilt"
		var replacement := make_prop(kind,width,45.0 if index in [5,9] else 155.0)
		replacement.name = "%02d_%s" % [index,kind]
		replacement.position = old.position
		replacement.set_meta("route",old.get_meta("route"))
		replacement.set_meta("kind", "food" if index>=19 else kind)
		platforms.remove_child(old)
		old.free()
		add_owned(platforms,replacement,scene)
		for child in replacement.get_children(): child.owner = scene
		index+=1
	var result := PackedScene.new()
	assert(result.pack(scene)==OK)
	assert(ResourceSaver.save(result,"res://map_2d.tscn")==OK)
	print("REPLACED ",index," platforms with 10 illustrated collidable props")
	scene.free()
	quit()
func _initialize() -> void: call_deferred("run")
