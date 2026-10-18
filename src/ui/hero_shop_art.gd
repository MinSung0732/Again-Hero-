extends RefCounted
## New hero-shop-only art. Normalize once, preserve original generated PNGs.
const FRAME := preload("res://assets/art/UI/hero_shop_v2/guild_frame.png")
const SINGLE := preload("res://assets/art/UI/hero_shop_v2/summon_single.png")
const MULTI := preload("res://assets/art/UI/hero_shop_v2/summon_multi.png")
static var frame_texture: Texture2D
static func panel_style(disabled: bool = false) -> StyleBoxTexture:
	if frame_texture == null:
		var image := FRAME.get_image()
		if image.is_compressed(): image.decompress()
		image = image.get_region(image.get_used_rect())
		image.resize(256,256,Image.INTERPOLATE_NEAREST)
		frame_texture = ImageTexture.create_from_image(image)
	var box := StyleBoxTexture.new(); box.texture = frame_texture
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,42)
		box.set_content_margin(side,26 if not disabled else 18)
	if disabled: box.modulate_color = Color(0.68,0.76,0.83,1)
	return box
static func illustration(parent: Node,multi: bool) -> TextureRect:
	var art := TextureRect.new(); art.name = "MultiSummonArt" if multi else "SingleSummonArt"
	art.texture = MULTI if multi else SINGLE
	art.custom_minimum_size.y = 240; art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art); return art
