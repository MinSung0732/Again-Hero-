extends AnimatedSprite2D
class_name CombatStatusEffectVisual

static var _frames_cache: Dictionary = {}

var target: Node
var effect_type: String = ""

func setup(new_target: Node, new_effect_type: String) -> void:
	target = new_target
	effect_type = new_effect_type
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 9
	centered = true

	var cached = _frames_cache.get(effect_type)
	var frames: SpriteFrames
	if cached is SpriteFrames:
		frames = cached
	else:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("fx")
		frames.set_animation_loop("fx", true)

		match effect_type:
			"slow":
				frames.set_animation_speed("fx", 12.0)
				for index in range(1, 7):
					var texture := _load_texture(
						"res://assets/art/effects/debuff/frames/slow_%02d.png" % index
					)
					if texture != null:
						frames.add_frame("fx", texture)
			"orc_rage":
				frames.set_animation_speed("fx", 14.0)
				for index in range(1, 9):
					var texture := _load_texture(
						"res://assets/art/effects/buff/frames/orc_rage/rage_%02d.png" % index
					)
					if texture != null:
						frames.add_frame("fx", texture)

		_frames_cache[effect_type] = frames

	match effect_type:
		"slow":
			scale = Vector2(0.30, 0.30)
			position = Vector2(0.0, 18.0)
		"orc_rage":
			scale = Vector2(0.34, 0.34)
			position = Vector2(0.0, -10.0)

	sprite_frames = frames
	visible = false
	if frames.get_frame_count("fx") > 0:
		play("fx")

func _process(_delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return

	match effect_type:
		"slow":
			visible = _is_slow_active()
		"orc_rage":
			visible = bool(target.get_meta("orc_berserk_visual_active", false))

func _is_slow_active() -> bool:
	var slow_value = target.get("slow_timer")
	if slow_value != null and float(slow_value) > 0.0:
		return true

	var now := Time.get_ticks_msec()
	if int(target.get_meta("gunner_slow_until", 0)) > now:
		return true
	if int(target.get_meta("archmage_root_until", 0)) > now:
		return true
	return false

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null
