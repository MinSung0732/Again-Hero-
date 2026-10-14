extends RefCounted
static func create(texture: Texture2D, level: int, maximum: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0,184)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rows := VBoxContainer.new()
	rows.name = "CardContent"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rows)
	rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.offset_left = 12; rows.offset_right = -12
	rows.offset_top = 12; rows.offset_bottom = -12
	rows.add_theme_constant_override("separation",6)
	var icon := TextureRect.new()
	icon.name = "ResearchIcon"
	icon.texture = texture
	icon.custom_minimum_size.y = 110
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(icon)
	var rank := Label.new()
	rank.name = "ResearchLevel"
	rank.text = "Lv.%d / %d" % [level,maximum]
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size",26)
	rank.add_theme_color_override("font_color",Color("ffe399") if level >= maximum else Color("f1e8f5"))
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(rank)
	return button
