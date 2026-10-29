extends SceneTree

const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const PROP_KEYS := ["pillar_a", "pillar_b", "pillar_broken", "debris_a", "debris_b", "debris_c", "ruins", "throne", "altar", "brazier", "crystal", "flag_a", "flag_b", "statue"]

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
	return {"used": Rect2(used), "base": Rect2(left, top, right - left + 1, used.end.y - top)}

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
		print('\t"%s": {"used": Rect2(%d, %d, %d, %d), "base": Rect2(%d, %d, %d, %d)},' % [path, used.position.x, used.position.y, used.size.x, used.size.y, base.position.x, base.position.y, base.size.x, base.size.y])
	print("}")
	quit()
