extends RefCounted
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const AUGMENT_COMPARE := preload("res://src/ui/augment_compare_view.gd")

const COMPACT_CARD_HEIGHT := 330
const COMPACT_ICON_SIZE := 64
const COMPACT_MARGIN := 8
const COMPACT_SPACING := 4
const COMPACT_COMPARE_LIMIT := 2
const CARD_MARGIN := 24
const TITLE_HEIGHT := 64
const DESCRIPTION_HEIGHT := 90
const COMPARE_HEIGHT := 112
const COMPARE_MIN_FONT := 12

static func create(parent: HBoxContainer,candidate: Dictionary,action: Callable,compact: bool = false) -> Button:
	var id := String(candidate.get("id",""))
	var button := Button.new(); button.name = id; button.custom_minimum_size = Vector2(280,COMPACT_CARD_HEIGHT if compact else 500)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new(); style.bg_color = Color("223d50"); style.border_color = Color("c9a45e"); style.set_border_width_all(2); style.set_content_margin_all(10)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,SKIN.skin_style(style))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",Color("efe5c9"))
	parent.add_child(button); button.pressed.connect(action)
	var margin := MarginContainer.new(); margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.name = "MarginContainer"
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,COMPACT_MARGIN if compact else CARD_MARGIN)
	var rows := VBoxContainer.new(); rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.name = "VBoxContainer"
	rows.add_theme_constant_override("separation",COMPACT_SPACING if compact else 8); margin.add_child(rows)
	var icon := TextureRect.new(); icon.name = "AugmentIcon"; icon.texture = ICONS.texture(id)
	icon.custom_minimum_size = Vector2(COMPACT_ICON_SIZE,COMPACT_ICON_SIZE) if compact else Vector2(96,96); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; rows.add_child(icon)
	var name_label := _label(rows,String(candidate.get("name",id)),26)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.max_lines_visible = 1 if compact else 2
	if not compact: name_label.custom_minimum_size.y = TITLE_HEIGHT
	if compact:
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF; name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var description := _label(rows,String(candidate.get("description","")),22)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var comparison: Array = candidate.get("compare",[])
	var comparison_view := AUGMENT_COMPARE.add(rows,comparison.slice(0,COMPACT_COMPARE_LIMIT) if compact else comparison,AUGMENT_COMPARE.SOLO_HERO_FONT,true)
	if not compact:
		comparison_view.fit_content = false
		comparison_view.custom_minimum_size.y = COMPARE_HEIGHT
		comparison_view.autowrap_mode = TextServer.AUTOWRAP_OFF
		comparison_view.resized.connect(_fit_comparison.bind(comparison_view,comparison))
		_fit_comparison.call_deferred(comparison_view,comparison)
	description.max_lines_visible = 1 if compact else 3
	if not compact: description.custom_minimum_size.y = DESCRIPTION_HEIGHT
	if compact:
		description.autowrap_mode = TextServer.AUTOWRAP_OFF; description.clip_text = true
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	AUGMENT_COMPARE.details(rows,candidate)
	return button

static func _label(parent: Node,value: String,size_px: int) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px); label.add_theme_color_override("font_color",Color("e5ead4")); label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label); return label

static func _fit_comparison(label: RichTextLabel, rows: Array) -> void:
	if not is_instance_valid(label) or label.size.x <= 0: return
	var font := label.get_theme_font("normal_font")
	if font == null: return
	var size := AUGMENT_COMPARE.SOLO_HERO_FONT
	for row in AUGMENT_COMPARE.meaningful_rows(rows):
		var line := "%s %s → %s" % [row.get("label",""),row.get("current",""),row.get("next","")]
		while size > COMPARE_MIN_FONT and font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > label.size.x:
			size -= 1
	if label.get_theme_font_size("normal_font_size") != size: label.add_theme_font_size_override("normal_font_size",size)
