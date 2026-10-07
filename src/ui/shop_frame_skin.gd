extends RefCounted

# Shop-only native artwork: cached textures, unbroken borders, clear label area.
const DIR := "res://assets/art/UI/shop_frames_v1/"
static var _textures: Dictionary = {}

static func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := DIR + name + ".png"
		var image := Image.new()
		_textures[name] = ImageTexture.create_from_image(image) if FileAccess.file_exists(path) and image.load(path) == OK else load(path) as Texture2D
	return _textures[name] as Texture2D

static func style(name: String = "shop_panel_frame", padding: float = 18.0, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture(name)
	box.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 24.0)
		box.set_content_margin(side, padding)
	return box

static func plain_content_style(padding: float = 14.0) -> StyleBoxEmpty:
	var box := StyleBoxEmpty.new()
	box.set_content_margin_all(padding)
	return box

static func apply_button(button: Button, primary: bool = false) -> void:
	button.set_meta("preserve_authored_skin", true)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var name := "shop_primary_button" if primary else "shop_button_frame"
	for state in ["normal", "hover", "pressed", "disabled"]:
		var tint := Color.WHITE
		if state == "hover":
			tint = Color(1.12, 1.09, 1.15)
		elif state == "pressed":
			tint = Color("c6a5d6")
		elif state == "disabled":
			tint = Color("706576")
		button.add_theme_stylebox_override(state, style(name, 12.0, tint))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
