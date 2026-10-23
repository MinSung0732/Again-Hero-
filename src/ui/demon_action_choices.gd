extends RefCounted

static func line_directions(select: Callable, cancel: Callable) -> Array:
	return [
		{"id":"east","text":"동쪽 ▶","action":select.bind("east")},
		{"id":"west","text":"◀ 서쪽","action":select.bind("west")},
		{"id":"north","text":"▲ 북쪽","action":select.bind("north")},
		{"id":"south","text":"▼ 남쪽","action":select.bind("south")},
		{"id":"cancel","text":"취소","action":cancel},
	]

static func ensure_buttons(grid: GridContainer, buttons: Array, template: Button, pressed: Callable, count: int) -> void:
	while buttons.size() < count:
		var index := buttons.size()
		var button := Button.new()
		button.name = "Choice%d" % (index + 1)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_color_override("font_color",Color(0.96,0.91,1.0,1.0))
		button.add_theme_color_override("font_pressed_color",Color(1.0,0.88,0.4,1.0))
		button.add_theme_color_override("font_disabled_color",Color(0.48,0.45,0.54,0.9))
		for style_name in ["normal","hover","pressed","disabled"]:
			var style_box := template.get_theme_stylebox(style_name)
			if style_box != null: button.add_theme_stylebox_override(style_name,style_box)
		button.pressed.connect(pressed.bind(index))
		grid.add_child(button)
		button.hide()
		buttons.append(button)

static func show_choices(grid: GridContainer, buttons: Array, ultimate_buttons: Control, ultimate_bar: Control, title_label: Label, title: String, choices: Array) -> void:
	var count := choices.size()
	var columns := count if count <= 5 else ceili(float(count)/2.0)
	grid.columns = maxi(columns,1)
	var rows := ceili(float(count)/float(grid.columns))
	var font_size := 17 if rows > 1 else 20 if count >= 5 else 22
	for index in count:
		var choice: Dictionary = choices[index]
		var button: Button = buttons[index]
		button.text = String(choice.get("text",choice.get("id","")))
		button.disabled = bool(choice.get("disabled",false))
		button.add_theme_font_size_override("font_size",int(choice.get("font_size",font_size)))
		button.show()
	for index in range(count,buttons.size()): buttons[index].hide()
	ultimate_buttons.hide()
	ultimate_bar.hide()
	grid.show()
	title_label.text = title
	title_label.add_theme_color_override("font_color",Color(1.0,0.78,0.28,1.0))

static func hide_choices(grid: GridContainer, buttons: Array) -> void:
	grid.hide()
	for button in buttons: button.hide()
