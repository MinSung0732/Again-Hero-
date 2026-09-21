extends AnimatedSprite2D
class_name MonsterVisual

signal death_animation_finished

@export var asset_dir: String = ""
@export var target_height: float = 88.0
@export var idle_count: int = 0
@export var move_count: int = 0
@export var attack_count: int = 0
@export var hit_count: int = 0
@export var death_count: int = 0

@export var idle_fps: float = 6.0
@export var move_fps: float = 10.0
@export var attack_fps: float = 14.0
@export var hit_fps: float = 14.0
@export var death_fps: float = 10.0

static var _frames_cache: Dictionary = {}

var _visual_ready: bool = false
var _one_shot_locked: bool = false
var _death_playing: bool = false
var _desired_locomotion: StringName = &"idle"
var _flash_timer: float = 0.0

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	_setup_sprite_frames()

	if _visual_ready:
		play(&"idle")

func _process(delta: float) -> void:
	if _flash_timer <= 0.0:
		return

	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if _flash_timer <= 0.0:
		self_modulate = Color.WHITE

func is_visual_ready() -> bool:
	return _visual_ready

func play_locomotion(moving: bool) -> void:
	_desired_locomotion = &"move" if moving else &"idle"
	if not _visual_ready or _one_shot_locked or _death_playing:
		return

	if sprite_frames.has_animation(_desired_locomotion):
		if animation != _desired_locomotion or not is_playing():
			play(_desired_locomotion)

func play_attack() -> void:
	if _death_playing:
		return
	_play_one_shot(&"attack")

func play_hit() -> void:
	if _death_playing:
		return

	if _visual_ready and sprite_frames.has_animation(&"hit"):
		_play_one_shot(&"hit")
		return

	_flash_timer = 0.12
	self_modulate = Color(1.0, 0.58, 0.58, 1.0)

func play_death() -> void:
	if _death_playing:
		return

	_death_playing = true
	_one_shot_locked = true
	self_modulate = Color.WHITE

	if _visual_ready and sprite_frames.has_animation(&"death"):
		play(&"death")
	else:
		call_deferred("_emit_death_finished")

func set_facing_direction(horizontal_direction: float) -> void:
	if absf(horizontal_direction) < 0.01:
		return
	flip_h = horizontal_direction < 0.0

func _play_one_shot(animation_name: StringName) -> void:
	if not _visual_ready:
		return
	if not sprite_frames.has_animation(animation_name):
		return

	_one_shot_locked = true
	play(animation_name)

func _on_animation_finished() -> void:
	if animation == &"death":
		_emit_death_finished()
		return

	if animation == &"attack" or animation == &"hit":
		_one_shot_locked = false
		if sprite_frames.has_animation(_desired_locomotion):
			play(_desired_locomotion)

func _emit_death_finished() -> void:
	death_animation_finished.emit()

func _setup_sprite_frames() -> void:
	if asset_dir.is_empty():
		return

	var cache_key := "%s|%d|%d|%d|%d|%d" % [
		asset_dir,
		idle_count,
		move_count,
		attack_count,
		hit_count,
		death_count,
	]

	var cached = _frames_cache.get(cache_key)
	if cached is SpriteFrames:
		sprite_frames = cached
	else:
		var built := SpriteFrames.new()
		if built.has_animation(&"default"):
			built.remove_animation(&"default")

		_add_animation(built, &"idle", idle_count, idle_fps, true)
		_add_animation(built, &"move", move_count, move_fps, true)
		_add_animation(built, &"attack", attack_count, attack_fps, false)
		_add_animation(built, &"hit", hit_count, hit_fps, false)
		_add_animation(built, &"death", death_count, death_fps, false)

		sprite_frames = built
		_frames_cache[cache_key] = built

	if not sprite_frames.has_animation(&"idle"):
		return
	if sprite_frames.get_frame_count(&"idle") <= 0:
		return

	var first_texture := sprite_frames.get_frame_texture(&"idle", 0)
	if first_texture == null:
		return

	var source_height := float(first_texture.get_height())
	if source_height > 0.0:
		var uniform_scale := target_height / source_height
		scale = Vector2(uniform_scale, uniform_scale)

	_visual_ready = true

func _add_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	frame_count: int,
	fps: float,
	looping: bool
) -> void:
	if frame_count <= 0:
		return

	var textures: Array[Texture2D] = []
	for frame_index in range(1, frame_count + 1):
		var file_name := "%s_%02d.png" % [
			String(animation_name),
			frame_index,
		]
		var texture := _load_texture("%s/%s" % [asset_dir, file_name])
		if texture != null:
			textures.append(texture)

	if textures.is_empty():
		return

	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)

	for texture in textures:
		frames.add_frame(animation_name, texture)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource

	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)

	return null
