extends RefCounted
## Shared castle assets/colors; the battle mode owns the values and callbacks.
const FRAMES := preload("res://src/ui/battle_pixel_frame_assembler.gd")
const LOGO := preload("res://assets/art/UI/logo/AgainHeroLogo.png")
static func logo(parent: Control) -> void:
	var image := TextureRect.new()
	image.name = "AgainHeroLogo"; image.texture = LOGO
	image.custom_minimum_size = Vector2(280,70)
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
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_color",Color.WHITE)
	caption.add_theme_color_override("font_outline_color",Color("111623")); caption.add_theme_constant_override("outline_size",5)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; result.add_child(caption)
	return result
