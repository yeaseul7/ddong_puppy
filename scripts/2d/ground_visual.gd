extends Node2D

var left := -885.0
var right := 885.0
const DEPTH := 1000.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Broad warm soil layers. The collision surface remains exactly at y = 0.
	draw_rect(Rect2(left,0,right-left,DEPTH),Color("704a2e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left,34),Vector2(right,34),Vector2(right,180),
		Vector2(right*0.75,168),Vector2(right*0.49,190),Vector2(right*0.22,162),
		Vector2(left*0.06,186),Vector2(left*0.36,160),Vector2(left*0.66,184),Vector2(left,165)
	]),Color("8f6038"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left,180),Vector2(left*0.73,194),Vector2(left*0.45,178),Vector2(left*0.17,205),
		Vector2(right*0.11,181),Vector2(right*0.4,210),Vector2(right*0.7,182),Vector2(right,200),
		Vector2(right,430),Vector2(right*0.68,414),Vector2(right*0.38,442),Vector2(right*0.1,417),
		Vector2(left*0.21,446),Vector2(left*0.52,420),Vector2(left*0.77,448),Vector2(left,430)
	]),Color("7d5232"))

	# Soft turf cap and irregular grassy silhouette.
	draw_rect(Rect2(left,-10,right-left,48),Color("537044"))
	draw_rect(Rect2(left,16,right-left,25),Color("65804d"))
	var turf := PackedVector2Array([Vector2(left,4)])
	for x in range(int(left),int(right)+1,24):
		var wave := sin(float(x)*0.031)*3.0+sin(float(x)*0.087)*1.8
		turf.append(Vector2(x,-8.0+wave))
	turf.append(Vector2(right,20))
	turf.append(Vector2(left,20))
	draw_colored_polygon(turf,Color("769257"))
	draw_line(Vector2(left,-7),Vector2(right,-7),Color("a9b96d"),3.0,true)

	# Deterministic details keep the ground lively without changing between runs.
	var rng := RandomNumberGenerator.new()
	rng.seed = 260930
	for i in 34:
		var x := rng.randf_range(left+30,right-30)
		var y := rng.randf_range(70,430)
		var radius := rng.randf_range(4,11)
		var stone_color := Color("b18a62") if i%3 else Color("5f4735")
		draw_stone(Vector2(x,y),Vector2(radius*1.5,radius),stone_color)
		if i%2 == 0:
			draw_arc(Vector2(x-1,y-1),radius*0.65,3.45,5.65,7,Color(1,0.88,0.68,0.28),1.4,true)
	for i in 15:
		var x := rng.randf_range(left+60,right-60)
		var y := rng.randf_range(105,390)
		var length := rng.randf_range(28,65)
		var root_color := Color(0.25,0.16,0.10,0.34)
		draw_polyline(PackedVector2Array([
			Vector2(x,y),Vector2(x+length*0.35,y+9),
			Vector2(x+length*0.65,y+5),Vector2(x+length,y+18)
		]),root_color,2.0,true)

	# Grass clumps break up the perfectly straight playable edge.
	for x in range(int(left)+45,int(right),95):
		var sway := sin(float(x)*0.043)*4.0
		var base := Vector2(x+sway,-8)
		var grass := Color("5d7e46")
		draw_line(base,base+Vector2(-8,-rng.randf_range(13,25)),grass,3.0,true)
		draw_line(base,base+Vector2(1,-rng.randf_range(17,30)),Color("7f9b59"),3.0,true)
		draw_line(base,base+Vector2(9,-rng.randf_range(11,23)),grass,3.0,true)

func draw_stone(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU*float(i)/16.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)

func set_horizontal_bounds(new_left: float, new_right: float) -> void:
	if is_equal_approx(left,new_left) and is_equal_approx(right,new_right):
		return
	left = new_left
	right = new_right
	queue_redraw()
