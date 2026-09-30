extends Control

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://assets/ui/lobby.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-375, -170)
	panel.size = Vector2(330, 340)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.09, 0.82)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "똥강아지"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("ffe3ad"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "마당에서 구름 너머까지"
	column.add_child(subtitle)
	for item in [["산책 시작", "res://vertical_yard.tscn"], ["조작 연습 · 기존 코스", "res://main.tscn"]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 48
		var destination: String = item[1]
		button.pressed.connect(func(): get_tree().change_scene_to_file(destination))
		column.add_child(button)
		if item[0] == "산책 시작": button.grab_focus()
	var quit := Button.new()
	quit.text = "종료"
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)
