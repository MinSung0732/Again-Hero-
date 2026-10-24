extends RefCounted
const AUDIO_PATH := "res://assets/audio/sfx/level_up_rise07_cc0.mp3"
static func configure(sprite: AnimatedSprite2D, loader: Callable) -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"): frames.remove_animation("default")
	frames.add_animation("level_up")
	frames.set_animation_speed("level_up", 13.5)
	frames.set_animation_loop("level_up", false)
	for frame_index in range(1, 7):
		var texture: Texture2D = loader.call("res://assets/art/effects/levelup/frames/levelup_%02d.png" % frame_index)
		if texture != null: frames.add_frame("level_up", texture)
	sprite.sprite_frames = frames
	sprite.animation = &"level_up"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-192.0, -410.0)
	sprite.scale = Vector2(0.42, 0.42)
	sprite.position = Vector2(0.0, 44.0)
	sprite.z_index = 6
	sprite.visible = false
