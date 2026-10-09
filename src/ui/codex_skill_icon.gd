extends PanelContainer
const ART := preload("res://src/data/skill_icon_catalog.gd")
var image: TextureRect
var placeholder: Label
func _init() -> void:
	custom_minimum_size = Vector2(76,76)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20142f")
	style.border_color = Color("9a7541")
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel",style)
	image = TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	placeholder = Label.new()
	placeholder.text = "기술"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size",18)
	placeholder.add_theme_color_override("font_color",Color("aa91bb"))
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.add_child(placeholder)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func configure(domain: String, owner_id: String, skill_id: String) -> void:
	set_meta("icon_key",ART.key(domain,owner_id,skill_id))
	image.texture = ART.texture(domain,owner_id,skill_id)
	placeholder.visible = image.texture == null
	tooltip_text = "기술 아이콘" if image.texture != null else "스킬 아이콘 자리"
