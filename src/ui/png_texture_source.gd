extends RefCounted
## Preserve source identity for decoded PNGs without replacing ResourceLoader cache.
const SOURCE_META := &"source_png_path"
static func annotate(texture: Texture2D,path: String) -> Texture2D:
	texture.set_meta(SOURCE_META,path)
	return texture
static func path(texture: Texture2D) -> String:
	return String(texture.get_meta(SOURCE_META,texture.resource_path))
