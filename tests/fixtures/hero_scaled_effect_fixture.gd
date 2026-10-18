extends Node2D

const HERO_PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
# Only the invalid-size boundary uses a Texture2D adapter. Valid frames are
# actual ImageTextures with independent per-path dimensions.
class EmptyTexture extends Texture2D:
	func _get_width() -> int:
		return 0
	func _get_height() -> int:
		return 0

var hero_id: String = "other"
var hero_archetype: String = "unknown"
var rogue_attack_effect: AnimatedSprite2D
var channel_effect: AnimatedSprite2D
var shield_effect: AnimatedSprite2D
var paths: Array = []
var load_states: Array = []
var signals_seen: Array = []
var textures: Dictionary = {}
var missing: Array = []
var missing_all := false
var texture_size := Vector2i(64, 96)
var size_overrides: Dictionary = {}

func _init():
	rogue_attack_effect = AnimatedSprite2D.new()
	channel_effect = AnimatedSprite2D.new()
	shield_effect = AnimatedSprite2D.new()
	var index := 0
	for sprite in [rogue_attack_effect, channel_effect, shield_effect]:
		add_child(sprite)
		var frames := SpriteFrames.new()
		frames.add_animation("old")
		for i in range(3):
			var texture := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
			texture.set_meta("fixture_path", "old_%d" % i)
			frames.add_frame("old", texture)
		sprite.sprite_frames = frames
		sprite.play("old")
		sprite.frame = 2
		sprite.frame_progress = 0.25
		sprite.visible = true
		sprite.position = Vector2(13, 17)
		sprite.offset = Vector2(3, 7)
		sprite.scale = Vector2(2, 3)
		sprite.modulate = Color(0.2, 0.3, 0.4, 0.5)
		sprite.rotation = 0.4
		sprite.z_index = 7
		sprite.speed_scale = 1.25
		sprite.animation_changed.connect(record_signal.bind(index, "animation"))
		sprite.sprite_frames_changed.connect(record_signal.bind(index, "frames"))
		sprite.frame_changed.connect(record_signal.bind(index, "frame"))
		index += 1

func record_signal(index, kind):
	signals_seen.append([index, kind, states()])

func sprite_state(sprite):
	var animations: Array = []
	if sprite.sprite_frames != null:
		for animation in sprite.sprite_frames.get_animation_names():
			var frame_paths: Array = []
			for i in range(sprite.sprite_frames.get_frame_count(animation)):
				frame_paths.append(sprite.sprite_frames.get_frame_texture(animation, i).get_meta("fixture_path"))
			animations.append([animation, sprite.sprite_frames.get_animation_speed(animation), sprite.sprite_frames.get_animation_loop(animation), frame_paths])
	return [animations, sprite.visible, sprite.position, sprite.offset, sprite.scale, sprite.modulate, sprite.rotation, sprite.z_index, sprite.texture_filter, sprite.animation, sprite.frame, sprite.frame_progress, sprite.speed_scale, sprite.is_playing()]

func states():
	return [sprite_state(rogue_attack_effect), sprite_state(channel_effect), sprite_state(shield_effect)]

func snapshot():
	return [paths, load_states, signals_seen, states()]

func _load_stage1_texture(path: String) -> Texture2D:
	paths.append(path)
	load_states.append(states())
	if missing_all or path in missing:
		return null
	if not textures.has(path):
		var dimensions: Vector2i = size_overrides.get(path, texture_size)
		var texture: Texture2D
		if dimensions == Vector2i.ZERO:
			texture = EmptyTexture.new()
		else:
			texture = ImageTexture.create_from_image(Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8))
		texture.set_meta("fixture_path", path)
		textures[path] = texture
	return textures[path]
