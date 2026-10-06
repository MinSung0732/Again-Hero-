extends RefCounted

const DIR := "res://assets/art/UI/commerce_v2/"
static var _textures: Dictionary = {}

static func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := DIR + name + ".png"
		var image := Image.new()
		if FileAccess.file_exists(path) and image.load(path) == OK:
			_textures[name] = ImageTexture.create_from_image(image)
		else:
			_textures[name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[name] as Texture2D

static func style(name: String = "shop_panel_frame", padding: float = 18.0, tint: Color = Color.WHITE) -> StyleBox:
	var box := StyleBoxTexture.new()
	box.texture = texture(name)
	box.modulate_color = tint
	var patch := 24.0
	if name == "header_frame":
		patch = 20.0
	elif name == "shop_button_frame":
		patch = 18.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, patch)
		box.set_content_margin(side, padding)
	return preload("res://src/ui/pixel_panel_skin.gd").button_style(box) if name == "shop_button_frame" else box
