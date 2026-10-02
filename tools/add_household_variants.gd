extends "res://tools/replace_household.gd"
const EXTRA := ["onggi_tall","onggi_wide","onggi_knob","brass_kettle","ceramic_pot","red_basket"]
func poly(coords: Array) -> Array:
	var result := []
	for p in coords: result.append(Vector2(p[0],p[1]))
	return result
func run() -> void:
	anchors.merge({"onggi_tall":Vector2(625,85),"onggi_wide":Vector2(625,215),"onggi_knob":Vector2(625,150),"brass_kettle":Vector2(700,55),"ceramic_pot":Vector2(625,130),"red_basket":Vector2(630,230)},true)
	polygons["onggi_tall"] = [poly([[460,85],[800,85],[925,150],[1030,330],[1120,610],[1120,860],[1000,1090],[880,1190],[440,1190],[260,1060],[130,830],[120,610],[220,370],[320,155]])]
	polygons["onggi_wide"] = [poly([[450,215],[800,215],[950,275],[1080,485],[1190,650],[1190,850],[1050,1060],[900,1130],[330,1130],[150,1010],[60,810],[65,670],[175,450],[290,275]])]
	polygons["onggi_knob"] = [poly([[550,150],[700,150],[745,190],[735,220],[900,265],[1030,410],[1050,495],[1110,670],[1100,865],[1020,1060],[880,1150],[410,1150],[255,1040],[135,815],[130,650],[200,475],[205,400],[325,275],[500,220],[505,180]])]
	polygons["ceramic_pot"] = [poly([[570,130],[685,130],[740,175],[735,215],[710,240],[900,285],[1080,365],[1190,420],[1190,485],[1120,530],[1120,600],[1180,735],[1140,950],[990,1090],[800,1155],[430,1155],[250,1090],[110,935],[75,740],[135,580],[130,520],[55,480],[50,420],[200,340],[520,240],[500,200],[510,165]])]
	polygons["red_basket"] = [poly([[430,230],[830,230],[1060,275],[1165,350],[1220,460],[1130,720],[1080,920],[970,1040],[810,1100],[410,1100],[230,1000],[130,850],[80,570],[25,465],[30,390],[160,300]])]
	# Separate the handle from the kettle body to preserve its visible opening.
	polygons["brass_kettle"] = [poly([[590,55],[810,55],[980,110],[965,205],[800,165],[600,160],[470,205],[460,125]]),poly([[460,125],[470,205],[395,285],[385,400],[440,510],[385,565],[350,440],[350,280],[390,190]]),poly([[980,155],[1050,240],[1100,350],[1090,490],[1040,550],[1030,460],[1045,350],[1000,250],[950,205]]),poly([[700,305],[785,305],[820,330],[815,425],[940,455],[1040,525],[1100,620],[1190,740],[1200,940],[1110,1090],[985,1180],[530,1200],[360,1110],[300,970],[310,780],[355,630],[445,540],[495,475],[660,425],[655,335]]),poly([[75,535],[165,520],[220,590],[305,740],[370,770],[365,980],[250,960],[180,880],[150,710],[110,605]])]
	for kind in EXTRA:
		var prop := make_prop(kind,220)
		var packed := PackedScene.new()
		assert(packed.pack(prop)==OK)
		assert(ResourceSaver.save(packed,"res://scenes/2d/household/"+kind+".tscn")==OK)
		prop.free()
	var scene = load("res://map_2d.tscn").instantiate()
	var platforms = scene.get_node("Platforms")
	# Mix six new types into 18 existing slots, preserving route positions/order.
	for i in 18:
		var slot := 19+i*3
		var old = platforms.get_child(slot)
		var kind: String = EXTRA[i%6]
		var replacement := make_prop(kind,180,145)
		replacement.name = "%02d_%s" % [slot,kind]
		replacement.position = old.position
		for key in old.get_meta_list(): replacement.set_meta(key,old.get_meta(key))
		platforms.remove_child(old)
		old.free()
		add_owned(platforms,replacement,scene)
		platforms.move_child(replacement,slot)
		for child in replacement.get_children(): child.owner = scene
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://map_2d.tscn")==OK)
	scene.free()
	print("Added 6 collidable variants in 18 route slots")
	quit()
