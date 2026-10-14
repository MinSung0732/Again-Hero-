extends RefCounted
## Shared castle assets/colors; the battle mode owns the values and callbacks.
const BATTLE_TOP := 470.0
const FRAME_WIDTH := 90.0
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
static var portraits: Dictionary = {}
const FRAMES := preload("res://src/ui/battle_pixel_frame_assembler.gd")
const LOGO := preload("res://assets/art/UI/logo/AgainHeroLogo.png")
static func logo(parent: Control) -> void:
	var image := TextureRect.new()
	image.name = "AgainHeroLogo"; image.texture = LOGO
	image.custom_minimum_size = Vector2(200,70)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
static func bar(parent: Control, title: String, color: Color, height: float) -> ProgressBar:
	var result := ProgressBar.new(); result.name = title+"Bar"
	result.custom_minimum_size.y = height; result.show_percentage = false
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := StyleBoxFlat.new(); background.bg_color = Color(0.018,0.02,0.05,0.98)
	background.border_color = Color(0.38,0.18,0.52,1); background.set_border_width_all(2)
	result.add_theme_stylebox_override("background",background)
	var fill := StyleBoxFlat.new(); fill.bg_color = color
	fill.set_corner_radius_all(4); result.add_theme_stylebox_override("fill",fill)
	parent.add_child(result)
	FRAMES.apply_progress_background(result,"res://assets/art/UI/05_right_bars/part_02.png",18,7)
	var caption := Label.new(); caption.name = "Caption"; caption.text = title
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",24)
	caption.add_theme_color_override("font_color",Color.WHITE)
	caption.add_theme_color_override("font_outline_color",Color("111623")); caption.add_theme_constant_override("outline_size",5)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; result.add_child(caption)
	return result

static func inventory_row(parent: Control, title: String, count: int) -> Array[Button]:
	var row := HBoxContainer.new(); row.name = title+"Inventory"; row.add_theme_constant_override("separation",8); parent.add_child(row)
	var caption := Label.new(); caption.text = title; caption.custom_minimum_size.x = 80; caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",25); caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(caption)
	var buttons: Array[Button] = []
	for index in count:
		var button := Button.new(); button.name = "Slot"+str(index); button.custom_minimum_size = Vector2(0,80)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var style := StyleBoxFlat.new(); style.bg_color = Color("171726"); style.border_color = Color("887048"); style.set_border_width_all(2)
		button.add_theme_stylebox_override("normal",style); button.add_theme_stylebox_override("disabled",style)
		var hover := style.duplicate(); hover.border_color = Color("ffda82")
		button.add_theme_stylebox_override("hover",hover); button.add_theme_stylebox_override("pressed",hover)
		row.add_child(button)
		var icon := TextureRect.new(); icon.name = "Icon"; icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 8; icon.offset_right = -8; icon.offset_top = 4; icon.offset_bottom = -8
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(icon)
		var rank := Label.new(); rank.name = "Rank"; rank.text = "+"; rank.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; rank.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		rank.offset_right = -5; rank.offset_bottom = -2; rank.add_theme_font_size_override("font_size",24)
		rank.add_theme_color_override("font_outline_color",Color("0d0a18")); rank.add_theme_constant_override("outline_size",5)
		rank.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(rank); buttons.append(button)
	return buttons
static func update_slot(button: Button, texture: Texture2D, rank: String, tooltip: String) -> void:
	button.get_node("Icon").texture = texture; button.get_node("Rank").text = rank
	button.get_node("Rank").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if texture == null else HORIZONTAL_ALIGNMENT_RIGHT
	button.get_node("Rank").vertical_alignment = VERTICAL_ALIGNMENT_CENTER if texture == null else VERTICAL_ALIGNMENT_BOTTOM
	button.get_node("Rank").modulate = Color("ffdb7a") if rank == "MAX" else Color.WHITE
	button.tooltip_text = tooltip

static func portrait_path(hero_id: String) -> String:
	return String(STAGES.get_stage(CHARACTERS.stage_for_hero(hero_id)).get("portrait_path",""))
static func portrait_texture(hero_id: String) -> Texture2D:
	var path := portrait_path(hero_id)
	if not portraits.has(path):
		var texture := load(path) as Texture2D if not path.is_empty() else null
		if texture != null:
			var image := texture.get_image()
			var used := image.get_used_rect() if image != null else Rect2i()
			if used.has_area():
				var cropped := AtlasTexture.new(); cropped.atlas = texture; cropped.region = Rect2(used); cropped.filter_clip = true
				texture = cropped
		portraits[path] = texture
	return portraits[path] as Texture2D
static func portrait(parent: Control, hero_id: String) -> TextureRect:
	var result := TextureRect.new(); result.name = "HeroPortrait"; result.texture = portrait_texture(hero_id)
	result.custom_minimum_size = Vector2(96,96); result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(result); return result

static func panel(parent: Control, color: Color, margin: int = 8) -> PanelContainer:
	var result := PanelContainer.new()
	var style := StyleBoxFlat.new(); style.bg_color = color; style.set_content_margin_all(margin)
	style.border_color = Color("484055"); style.set_border_width_all(1)
	result.add_theme_stylebox_override("panel",style); parent.add_child(result); return result
static func counter(parent: Control, title: String, tint: Color) -> Label:
	var plate := panel(parent,Color("242333"),6)
	plate.custom_minimum_size = Vector2(220,52)
	var result := Label.new(); result.name = title; result.text = title+" 0"
	result.add_theme_font_size_override("font_size",28); result.add_theme_color_override("font_color",tint)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE; plate.add_child(result); return result
