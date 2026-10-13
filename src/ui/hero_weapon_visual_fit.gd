extends RefCounted
## Startup-only alpha bounds, shared across the retained native actors.
static var bounds_cache: Dictionary = {}
static var texture_cache: Dictionary = {}
static func warm(paths: PackedStringArray) -> Rect2:
	var key := "|".join(paths)
	if bounds_cache.has(key): return bounds_cache[key]
	var bounds := Rect2()
	for path in paths:
		var texture := texture_cache.get(path) as Texture2D
		if texture == null: texture = load(path) as Texture2D
		if texture == null: continue
		texture_cache[path] = texture
		var image := texture.get_image()
		if image == null or image.is_empty(): continue
		var used := Rect2(image.get_used_rect())
		used.position -= texture.get_size()*0.5
		bounds = used if not bounds.has_area() else bounds.merge(used)
	bounds_cache[key] = bounds
	return bounds
static func circle(sprite: Sprite2D, bounds: Rect2, radius: float) -> void:
	if not bounds.has_area(): return
	# The full opaque rectangle fits inside the circle; the exact ground outline
	# remains visible through every animation phase.
	var scale := radius/maxf(bounds.size.length()*0.5,1)
	sprite.scale = Vector2.ONE*scale; sprite.offset = -bounds.get_center()
static func projectile(sprite: AnimatedSprite2D, bounds: Rect2, size: Vector2) -> void:
	if not bounds.has_area(): return
	sprite.scale = Vector2.ONE*minf(size.x/bounds.size.x,size.y/bounds.size.y)
	sprite.offset = -bounds.get_center()
static func animated_circle(sprite: AnimatedSprite2D, bounds: Rect2, radius: float) -> void:
	if not bounds.has_area(): return
	sprite.scale = Vector2.ONE*radius/maxf(bounds.size.length()*0.5,1)
	sprite.offset = -bounds.get_center()
