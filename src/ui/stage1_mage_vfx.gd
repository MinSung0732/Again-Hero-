extends RefCounted
class_name Stage1MageVfx

# Stage 1 mage sheets: four PNG reads at most, with shared AtlasTexture frames.
# Original standalone PNGs remain an automatic fail-soft fallback in callers.
const ROOT := "res://assets/art/heroes/stage1_mage/vfx_v2/"
const CELL := 128
const FRAME_COUNTS := {
	"projectile": 4,
	"effect_01": 6,
	"effect_02": 6,
	"effect_03": 6,
}
const COLUMNS := {
	"projectile": 4,
	"effect_01": 3,
	"effect_02": 3,
	"effect_03": 3,
}

static var _sheets: Dictionary = {}
static var _frames: Dictionary = {}
static var _unavailable: Dictionary = {}

static func frame(kind: String, index: int) -> Texture2D:
	var count := int(FRAME_COUNTS.get(kind, 0))
	if index < 1 or index > count:
		return null
	var key := "%s_%02d" % [kind, index]
	if _frames.has(key):
		return _frames[key] as Texture2D
	if _unavailable.has(kind):
		return null
	var sheet := _get_sheet(kind)
	if sheet == null:
		_unavailable[kind] = true
		return null
	var columns := int(COLUMNS.get(kind, 1))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2i(
		((index - 1) % columns) * CELL,
		floori(float(index - 1) / float(columns)) * CELL,
		CELL,
		CELL
	)
	atlas.filter_clip = true
	_frames[key] = atlas
	return atlas


static func _get_sheet(kind: String) -> Texture2D:
	if _sheets.has(kind):
		return _sheets[kind] as Texture2D
	var path := ROOT + kind + "_spritesheet.png"
	# Source-first prevents stale import caches in Godot Android Editor.
	var texture: Texture2D
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			texture = ImageTexture.create_from_image(image)
	if texture == null and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		return null
	var columns := int(COLUMNS.get(kind, 1))
	var rows := ceili(float(FRAME_COUNTS[kind]) / float(columns))
	if texture.get_width() != CELL * columns or texture.get_height() != CELL * rows:
		push_warning("Stage1MageVfx unexpected sheet dimensions: " + path)
		return null
	_sheets[kind] = texture
	return texture
