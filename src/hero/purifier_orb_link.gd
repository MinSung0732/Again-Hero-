extends Node2D

static var _frames_cache: SpriteFrames = null

@onready var visual: AnimatedSprite2D = $Visual


func setup(
	from_position: Vector2,
	to_position: Vector2,
	effect_dir: String,
	vertical_scale: float = 0.58
) -> void:
	var segment := to_position - from_position
	var distance := segment.length()
	if distance <= 1.0:
		visible = false
		return

	global_position = from_position.lerp(to_position, 0.5)
	rotation = segment.angle()
	z_index = 5

	visual.sprite_frames = _get_or_build_frames(effect_dir)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(
		maxf(distance / 320.0, 0.20),
		maxf(vertical_scale, 0.05)
	)
	visual.visible = true
	visual.frame = 0
	visual.frame_progress = 0.0
	if (
		visual.sprite_frames != null
		and visual.sprite_frames.has_animation(&"link")
	):
		visual.play(&"link")


static func _get_or_build_frames(effect_dir: String) -> SpriteFrames:
	if _frames_cache != null:
		return _frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"link")
	frames.set_animation_loop(&"link", true)
	frames.set_animation_speed(&"link", 24.0)

	for frame_index in range(1, 42):
		var path := "%s/chain_%02d.png" % [effect_dir, frame_index]
		if not ResourceLoader.exists(path):
			continue
		var loaded = load(path)
		if loaded is Texture2D:
			frames.add_frame(&"link", loaded)

	_frames_cache = frames
	return frames
