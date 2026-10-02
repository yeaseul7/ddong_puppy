extends Control

var settings_dialog: AcceptDialog
var screen_mode: OptionButton
var settings_status: Label
var settings_button: Button

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://assets/ui/lobby.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -375
	panel.offset_right = -45
	panel.offset_top = -210
	panel.offset_bottom = 210
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
	for item in [["산책 시작 · 2D", "res://map_2d.tscn"]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 48
		var destination: String = item[1]
		button.pressed.connect(func(): get_tree().change_scene_to_file(destination))
		column.add_child(button)
		if item[0] == "산책 시작 · 2D": button.grab_focus()
	settings_button = Button.new()
	settings_button.text = "설정"
	settings_button.custom_minimum_size.y = 48
	settings_button.pressed.connect(open_settings)
	column.add_child(settings_button)
	build_settings()
	var quit := Button.new()
	quit.text = "종료"
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)

func build_settings() -> void:
	settings_dialog = AcceptDialog.new()
	settings_dialog.title = "설정"
	settings_dialog.exclusive = true
	settings_dialog.dialog_autowrap = true
	settings_dialog.get_ok_button().text = "닫기"
	settings_dialog.confirmed.connect(func(): settings_button.grab_focus())
	settings_dialog.canceled.connect(func(): settings_button.grab_focus())
	add_child(settings_dialog)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,20)
	settings_dialog.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "화면 모드"
	heading.add_theme_font_size_override("font_size",24)
	column.add_child(heading)
	screen_mode = OptionButton.new()
	screen_mode.add_item("창모드",0)
	screen_mode.add_item("전체화면",1)
	screen_mode.custom_minimum_size = Vector2(360,48)
	screen_mode.item_selected.connect(change_screen_mode)
	column.add_child(screen_mode)
	settings_status = Label.new()
	settings_status.text = "선택하면 즉시 적용되며 다음 실행에도 유지됩니다."
	settings_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_status.custom_minimum_size = Vector2(360,52)
	column.add_child(settings_status)

func open_settings() -> void:
	var display_settings := get_node("/root/DisplaySettings")
	screen_mode.select(1 if display_settings.fullscreen else 0)
	settings_status.text = "선택하면 즉시 적용되며 다음 실행에도 유지됩니다."
	settings_dialog.popup_centered(Vector2i(440,250))
	screen_mode.grab_focus()

func change_screen_mode(index: int) -> void:
	var error: Error = get_node("/root/DisplaySettings").set_fullscreen(index == 1)
	settings_status.text = "화면 모드를 저장했습니다." if error == OK else "화면은 변경했지만 설정 저장에 실패했습니다."
	# Root resizing also re-centers the embedded settings window.
	call_deferred("recenter_settings")

func recenter_settings() -> void:
	if settings_dialog.visible:
		settings_dialog.position = Vector2i((get_viewport_rect().size-Vector2(settings_dialog.size))/2)
