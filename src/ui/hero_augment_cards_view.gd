extends RefCounted
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const AUGMENT_COMPARE := preload("res://src/ui/augment_compare_view.gd")

static func create(parent: HBoxContainer,candidate: Dictionary,action: Callable) -> Button:
	var id := String(candidate.get("id",""))
	var button := Button.new(); button.name = id; button.custom_minimum_size = Vector2(280,500)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new(); style.bg_color = Color("223d50"); style.border_color = Color("c9a45e"); style.set_border_width_all(2); style.set_content_margin_all(10)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,SKIN.skin_style(style))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",Color("efe5c9"))
	parent.add_child(button); button.pressed.connect(action)
	var margin := MarginContainer.new(); margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	button.add_child(margin)
	var rows := VBoxContainer.new(); rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.name = "VBoxContainer"
	rows.add_theme_constant_override("separation",8); margin.add_child(rows)
	var icon := TextureRect.new(); icon.name = "AugmentIcon"; icon.texture = ICONS.texture(id)
	icon.custom_minimum_size = Vector2(96,96); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; rows.add_child(icon)
	var name_label := _label(rows,String(candidate.get("name",id)),26)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var description := _label(rows,String(candidate.get("description","")),22)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var comparison: Array = candidate.get("compare",[])
	var comparison_view := AUGMENT_COMPARE.add(rows,comparison,AUGMENT_COMPARE.SOLO_HERO_FONT,true)
	comparison_view.fit_content = false
	comparison_view.custom_minimum_size.y = 112
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	AUGMENT_COMPARE.details(rows,candidate)
	return button

static func _label(parent: Node,value: String,size_px: int) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px); label.add_theme_color_override("font_color",Color("e5ead4")); label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label); return label
