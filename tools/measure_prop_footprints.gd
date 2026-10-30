extends SceneTree

const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const PROP_KEYS := ["pillar_a", "pillar_b", "pillar_broken", "debris_a", "debris_b", "debris_c", "ruins", "throne", "altar", "brazier", "crystal", "flag_a", "flag_b", "statue"]

const CONTACT_ALPHA := 0.5
const CONTACT_HEIGHT_RATIO := 0.10
const CONTACT_MIN_HEIGHT := 8
const CONTACT_MAX_HEIGHT := 24

static func measure(image: Image) -> Dictionary:
	var used: Rect2i = image.get_used_rect()
	if used.size == Vector2i.ZERO: return {}
	var top: int = used.position.y + int(floor(used.size.y * 0.8))
	var left: int = used.end.x
	var right: int = used.position.x - 1
	for y in range(top, used.end.y):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > 0.0:
				left = mini(left, x)
				right = maxi(right, x)
	var opaque_bottom := -1
	for y in range(used.end.y - 1, used.position.y - 1, -1):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > CONTACT_ALPHA:
				opaque_bottom = y
				break
		if opaque_bottom >= 0: break
	var result := {"used": Rect2(used), "base": Rect2(left, top, right - left + 1, used.end.y - top)}
	if opaque_bottom < 0: return result
	var height := mini(used.size.y, clampi(int(ceil(used.size.y * CONTACT_HEIGHT_RATIO)), CONTACT_MIN_HEIGHT, CONTACT_MAX_HEIGHT))
	var contact_top := maxi(used.position.y, opaque_bottom - height + 1)
	left = used.end.x
	right = used.position.x - 1
	for y in range(contact_top, opaque_bottom + 1):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a > CONTACT_ALPHA:
				left = mini(left, x)
				right = maxi(right, x)
	result["contact"] = Rect2(left, contact_top, right - left + 1, opaque_bottom - contact_top + 1)
	return result

func _initialize() -> void:
	var paths := {}
	for id in THEMES.ids():
		var theme: Dictionary = THEMES.get_theme(id)
		for key in PROP_KEYS:
			paths[theme.overrides.get(key, FIELD.TEXTURE_PATHS[key])] = true
		for path in theme.extra_textures.values(): paths[path] = true
	var sorted: Array = paths.keys()
	sorted.sort()
	print("const FOOTPRINTS := {")
	for path in sorted:
		var image := Image.load_from_file(path)
		var data := measure(image)
		if data.is_empty(): push_error("Empty footprint: " + path); quit(1); return
		var used: Rect2 = data.used
		var base: Rect2 = data.base
		var contact: Rect2 = data.contact
		print('\t"%s": {"used": Rect2(%d, %d, %d, %d), "base": Rect2(%d, %d, %d, %d), "contact": Rect2(%d, %d, %d, %d)},' % [path, used.position.x, used.position.y, used.size.x, used.size.y, base.position.x, base.position.y, base.size.x, base.size.y, contact.position.x, contact.position.y, contact.size.x, contact.size.y])
	print("}")
	quit()
