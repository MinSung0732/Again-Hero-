extends Node2D

static var _frames_cache: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual


func setup(
	world_position: Vector2,
	effect_dir: String,
	visual_scale: float = 1.0,
	fps: float = 12.0
) -> void:
	global_position = world_position
	visual.sprite_frames = _get_or_build_frames(effect_dir, fps)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * maxf(visual_scale, 0.05)
	visual.visible = true
	visual.animation_finished.connect(_on_animation_finished)
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"cleanse"):
		visual.play(&"cleanse")
	else:
		queue_free()


func _on_animation_finished() -> void:
	queue_free()


static func _get_or_build_frames(effect_dir: String, fps: float) -> SpriteFrames:
	var cache_key := "%s|%.2f" % [effect_dir, fps]
	var cached = _frames_cache.get(cache_key)
	if cached is SpriteFrames:
		return cached

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"cleanse")
	frames.set_animation_loop(&"cleanse", false)
	frames.set_animation_speed(&"cleanse", maxf(fps, 1.0))
	for frame_index in [29, 30, 31]:
		var path := "%s/effect_%02d.png" % [effect_dir, frame_index]
		if not ResourceLoader.exists(path):
			continue
		var loaded = load(path)
		if loaded is Texture2D:
			frames.add_frame(&"cleanse", loaded)
	_frames_cache[cache_key] = frames
	return frames
