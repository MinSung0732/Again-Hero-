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
var _lod_suspended: bool = false

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	_setup_sprite_frames()
	set_process(false)

	if _visual_ready:
		play(&"idle")

func _process(delta: float) -> void:
	if _flash_timer <= 0.0:
		return

	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if _flash_timer <= 0.0:
		self_modulate = Color.WHITE
		set_process(false)

func is_visual_ready() -> bool:
	return _visual_ready

func play_locomotion(moving: bool) -> void:
	_desired_locomotion = &"move" if moving else &"idle"
	if _lod_suspended:
		return
	if not _visual_ready or _one_shot_locked or _death_playing:
		return

	if sprite_frames.has_animation(_desired_locomotion):
		if animation != _desired_locomotion or not is_playing():
			play(_desired_locomotion)

func play_attack() -> void:
	if _death_playing or _lod_suspended:
		return
	_play_one_shot(&"attack")

func play_hit() -> void:
	if _death_playing or _lod_suspended:
		return

	if _visual_ready and sprite_frames.has_animation(&"hit"):
		_play_one_shot(&"hit")
		return

	_flash_timer = 0.12
	self_modulate = Color(1.0, 0.58, 0.58, 1.0)
	set_process(true)

func play_death() -> void:
	if _death_playing:
		return

	set_lod_suspended(false)
	_death_playing = true
	_one_shot_locked = true
	self_modulate = Color.WHITE

	if _visual_ready and sprite_frames.has_animation(&"death"):
		play(&"death")
	else:
		call_deferred("_emit_death_finished")

func set_lod_suspended(suspended: bool) -> void:
	if suspended == _lod_suspended:
		return

	_lod_suspended = suspended
	if suspended:
		# Let a current attack/hit one-shot finish so it cannot remain
		# permanently locked while offscreen.
		if _one_shot_locked:
			return
		if _visual_ready and is_playing():
			pause()
		return

	if not _visual_ready or _death_playing or _one_shot_locked:
		return
	if sprite_frames.has_animation(_desired_locomotion):
		play(_desired_locomotion)


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
		if _lod_suspended:
			return
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


func apply_visual_profile(profile: Dictionary) -> bool:
	if profile.is_empty():
		return false

	var mode := String(profile.get("mode", ""))
	var animations = profile.get("animations", {})
	if typeof(animations) != TYPE_DICTIONARY:
		return false

	var built := SpriteFrames.new()
	if built.has_animation(&"default"):
		built.remove_animation(&"default")

	match mode:
		"frames":
			_build_profile_frames(built, profile, animations)
		"sequence":
			_build_profile_sequence(built, profile, animations)
		"sheet":
			_build_profile_sheet(built, profile, animations)
		_:
			return false

	if not built.has_animation(&"idle"):
		return false
	if built.get_frame_count(&"idle") <= 0:
		return false

	sprite_frames = built
	var first_texture := built.get_frame_texture(&"idle", 0)
	if first_texture == null:
		return false

	var profile_height := float(profile.get("target_height", target_height))
	var source_height := float(first_texture.get_height())
	if source_height > 0.0:
		var uniform_scale := profile_height / source_height
		scale = Vector2(uniform_scale, uniform_scale)

	_visual_ready = true
	_one_shot_locked = false
	_death_playing = false
	_desired_locomotion = &"idle"
	self_modulate = Color.WHITE
	play(&"idle")
	return true

func _build_profile_frames(
	frames: SpriteFrames,
	profile: Dictionary,
	animations: Dictionary
) -> void:
	var dir_path := String(profile.get("asset_dir", ""))
	if dir_path.is_empty():
		return

	for raw_name in animations.keys():
		var animation_name := StringName(String(raw_name))
		var config: Dictionary = animations[raw_name]
		var prefix := String(config.get("prefix", String(raw_name)))
		var count := int(config.get("count", 0))
		if count <= 0:
			continue

		var textures: Array[Texture2D] = []
		for frame_index in range(1, count + 1):
			var texture := _load_texture(
				"%s/%s_%02d.png" % [dir_path, prefix, frame_index]
			)
			if texture != null:
				textures.append(texture)

		_add_profile_animation(
			frames,
			animation_name,
			textures,
			float(config.get("fps", 10.0)),
			bool(config.get("loop", false))
		)

func _build_profile_sequence(
	frames: SpriteFrames,
	profile: Dictionary,
	animations: Dictionary
) -> void:
	var dir_path := String(profile.get("asset_dir", ""))
	if dir_path.is_empty():
		return

	for raw_name in animations.keys():
		var animation_name := StringName(String(raw_name))
		var config: Dictionary = animations[raw_name]
		var start_index := int(config.get("start", 1))
		var count := int(config.get("count", 0))
		if count <= 0:
			continue

		var textures: Array[Texture2D] = []
		for offset in range(count):
			var texture := _load_texture(
				"%s/frame_%02d.png" % [dir_path, start_index + offset]
			)
			if texture != null:
				textures.append(texture)

		_add_profile_animation(
			frames,
			animation_name,
			textures,
			float(config.get("fps", 10.0)),
			bool(config.get("loop", false))
		)

func _build_profile_sheet(
	frames: SpriteFrames,
	profile: Dictionary,
	animations: Dictionary
) -> void:
	var sheet_path := String(profile.get("sheet_path", ""))
	var sheet := _load_texture(sheet_path)
	if sheet == null:
		return

	var columns := maxi(int(profile.get("columns", 1)), 1)
	var rows := maxi(int(profile.get("rows", 1)), 1)
	var cell_size := Vector2(
		float(sheet.get_width()) / float(columns),
		float(sheet.get_height()) / float(rows)
	)

	for raw_name in animations.keys():
		var animation_name := StringName(String(raw_name))
		var config: Dictionary = animations[raw_name]
		var row := int(config.get("row", 0))
		var count := mini(int(config.get("count", 0)), columns)
		if count <= 0:
			continue

		var textures: Array[Texture2D] = []
		for column in range(count):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.filter_clip = true
			atlas.region = Rect2(
				Vector2(float(column), float(row)) * cell_size,
				cell_size
			)
			textures.append(atlas)

		_add_profile_animation(
			frames,
			animation_name,
			textures,
			float(config.get("fps", 10.0)),
			bool(config.get("loop", false))
		)

func _add_profile_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	textures: Array[Texture2D],
	fps: float,
	looping: bool
) -> void:
	if textures.is_empty():
		return

	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)
	for texture in textures:
		frames.add_frame(animation_name, texture)

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
