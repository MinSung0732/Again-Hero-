extends Control

var proceed: Callable
var start_button: Button

func install(lobby: Control) -> void:
	name = "TranscendenceEntryConfirm"
	lobby.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 760
	panel.add_theme_stylebox_override("panel", lobby.panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	margin.add_child(box)
	var message := Label.new()
	message.text = "초월편성이 완료되지 않았습니다.\n시작하시겠습니까?"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 30)
	box.add_child(message)
	var note := Label.new()
	note.text = "초월 몬스터 없이 전투를 시작합니다."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 24)
	note.add_theme_color_override("font_color", Color("d8c7de"))
	box.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	for text in ["취소", "시작"]:
		var action := Button.new()
		action.text = text
		action.custom_minimum_size.y = 82
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(action)
		lobby._apply_lobby_button_skin(action, text == "시작", 28)
		if text == "취소":
			action.pressed.connect(hide)
		else:
			start_button = action
			action.pressed.connect(_confirm)
	preload("res://src/ui/pixel_panel_skin.gd").apply(panel)
	hide()

func open(action: Callable) -> void:
	if visible:
		return
	proceed = action
	show()
	start_button.grab_focus()

func _confirm() -> void:
	if not visible:
		return
	hide()
	if proceed.is_valid():
		proceed.call()
