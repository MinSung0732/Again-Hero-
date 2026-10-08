extends AnimatedSprite2D
class_name MonsterVisual

signal death_animation_finished
signal revival_animation_finished

@export var asset_dir: String = ""
@export var target_height: float = 88.0
@export var idle_count: int = 0
@export var move_count: int = 0
@export var attack_count: int = 0
@export var hit_count: int = 0
@export var death_count: int = 0

@export var idle_fps: float = 6.0
@export var move_fps: float = 10.0
@export var locomotion_max_fps: float = 8.0
@export var locomotion_transition_seconds: float = 0.12
@export var attack_fps: float = 14.0
@export var hit_fps: float = 14.0
@export var death_fps: float = 10.0

static var _frames_cache: Dictionary = {}
static var _hit_flash_shader: Shader

var _visual_ready: bool = false
var _one_shot_locked: bool = false
var _death_playing: bool = false
var _revival_death_pose_playing: bool = false
var _revival_death_pose_ready: bool = false
var _revival_reverse_playing: bool = false
var _desired_locomotion: StringName = &"idle"
var _pending_locomotion: StringName = &"idle"
var _locomotion_request_seconds := 0.0
var _saved_move_frame := 0
var _saved_move_progress := 0.0
var _flash_timer: float = 0.0
var _hit_flash_material: ShaderMaterial
var _lod_suspended: bool = false
var _death_fade_duration := 0.0

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	_setup_sprite_frames()
	_ensure_hit_flash_material()
	set_process(false)
	set_physics_process(false)

	if _visual_ready:
		play(&"idle")

func _process(delta: float) -> void:
	if _flash_timer <= 0.0:
		return

	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if _hit_flash_material != null:
		_hit_flash_material.set_shader_parameter(
			"flash_strength",
			1.0 if _flash_timer > 0.0 else 0.0
		)
	if _flash_timer <= 0.0:
		set_process(false)

func _ensure_hit_flash_material() -> void:
	if _hit_flash_material != null:
		return
	if _hit_flash_shader == null:
		_hit_flash_shader = Shader.new()
		_hit_flash_shader.code = """
shader_type canvas_item;
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	base.rgb = mix(base.rgb, flash_color.rgb, flash_strength);
	COLOR = base;
}
"""
	_hit_flash_material = ShaderMaterial.new()
	_hit_flash_material.shader = _hit_flash_shader
	_hit_flash_material.set_shader_parameter("flash_strength", 0.0)
	material = _hit_flash_material


func is_visual_ready() -> bool:
	return _visual_ready

func play_locomotion(moving: bool) -> void:
	var requested: StringName = &"move" if moving else &"idle"
	if requested != _pending_locomotion:
		_pending_locomotion = requested
		_locomotion_request_seconds = 0.0
	if requested == _desired_locomotion:
		set_physics_process(false)
		_apply_locomotion()
	else:
		# Also supports callers that submit only state changes, not every tick.
		set_physics_process(true)


func _physics_process(delta: float) -> void:
	_locomotion_request_seconds += delta
	if _locomotion_request_seconds < locomotion_transition_seconds:
		return
	_remember_move_phase()
	_desired_locomotion = _pending_locomotion
	set_physics_process(false)
	_apply_locomotion()


func _apply_locomotion() -> void:
	if _lod_suspended or not _visual_ready or _one_shot_locked or _death_playing:
		return
	if sprite_frames.has_animation(_desired_locomotion):
		if animation != _desired_locomotion or not is_playing():
			_resume_locomotion()


func play_attack() -> void:
	if _death_playing or _lod_suspended or _revival_reverse_playing or _revival_death_pose_playing:
		return
	_play_one_shot(&"attack")

func play_skill() -> void:
	if not _death_playing and not _lod_suspended:
		_play_one_shot(&"skill")

func play_hit() -> void:
	if _death_playing or _lod_suspended or _revival_reverse_playing or _revival_death_pose_playing:
		return

	_start_damage_flash(Color.WHITE, 0.12)

	if _visual_ready and sprite_frames.has_animation(&"hit"):
		_play_one_shot(&"hit")


func play_poison_hit() -> void:
	if _death_playing or _lod_suspended or _revival_reverse_playing or _revival_death_pose_playing:
		return
	_start_damage_flash(Color(0.72, 0.30, 0.92), 0.10)


func _start_damage_flash(flash_color: Color, duration: float) -> void:
	_flash_timer = maxf(duration, 0.01)
	_ensure_hit_flash_material()
	if _hit_flash_material != null:
		_hit_flash_material.set_shader_parameter(
			"flash_color",
			flash_color
		)
		_hit_flash_material.set_shader_parameter("flash_strength", 1.0)
	set_process(true)

func play_death() -> void:
	if _death_playing:
		return

	set_lod_suspended(false)
	_death_playing = true
	_revival_death_pose_playing = false
	_revival_death_pose_ready = false
	_revival_reverse_playing = false
	_one_shot_locked = true
	_flash_timer = 0.0
	if _hit_flash_material != null:
		_hit_flash_material.set_shader_parameter("flash_strength", 0.0)
	self_modulate = Color.WHITE

	if _death_fade_duration > 0.0 and _visual_ready:
		play(&"idle")
		stop()
		frame = 0
		var fade := create_tween()
		fade.tween_property(self,"self_modulate:a",0.0,_death_fade_duration)
		fade.tween_callback(_emit_death_finished)
		return

	if _visual_ready and sprite_frames.has_animation(&"death"):
		speed_scale = 1.0
		play(&"death")
	else:
		call_deferred("_emit_death_finished")


func play_revival_death_pose() -> void:
	set_lod_suspended(false)
	_death_playing = false
	_revival_death_pose_playing = true
	_revival_death_pose_ready = false
	_revival_reverse_playing = false
	_one_shot_locked = true
	_flash_timer = 0.0
	if _hit_flash_material != null:
		_hit_flash_material.set_shader_parameter("flash_strength", 0.0)
	self_modulate = Color.WHITE

	if _visual_ready and sprite_frames.has_animation(&"death"):
		speed_scale = 1.0
		play(&"death")
	else:
		call_deferred("_hold_revival_death_pose")


func is_revival_death_pose_ready() -> bool:
	return _revival_death_pose_ready


func play_revival_reverse(duration: float = 0.0) -> void:
	if _revival_reverse_playing:
		return

	set_lod_suspended(false)
	_death_playing = false
	_revival_death_pose_playing = false
	_revival_death_pose_ready = false
	_revival_reverse_playing = true
	_one_shot_locked = true
	self_modulate = Color.WHITE

	if _visual_ready and sprite_frames.has_animation(&"death"):
		var reverse_speed := 1.0
		if duration > 0.0:
			var frame_count := sprite_frames.get_frame_count(&"death")
			var fps := sprite_frames.get_animation_speed(&"death")
			if frame_count > 0 and fps > 0.0:
				var base_duration := float(frame_count) / fps
				reverse_speed = maxf(base_duration / duration, 0.01)
		speed_scale = 1.0
		play(&"death", -reverse_speed, true)
	else:
		call_deferred("_finish_revival_reverse")


func _hold_revival_death_pose() -> void:
	if not _revival_death_pose_playing:
		return
	stop()
	if _visual_ready and sprite_frames.has_animation(&"death"):
		var frame_count := sprite_frames.get_frame_count(&"death")
		if frame_count > 0:
			animation = &"death"
			frame = frame_count - 1
			frame_progress = 1.0
	_revival_death_pose_ready = true


func _finish_revival_reverse() -> void:
	_revival_reverse_playing = false
	_revival_death_pose_playing = false
	_revival_death_pose_ready = false
	_death_playing = false
	_one_shot_locked = false
	self_modulate = Color.WHITE
	_desired_locomotion = &"idle"
	stop()
	if _visual_ready and sprite_frames.has_animation(&"death"):
		animation = &"death"
		frame = 0
		frame_progress = 0.0
	revival_animation_finished.emit()

func set_lod_suspended(suspended: bool) -> void:
	if suspended == _lod_suspended:
		return

	_lod_suspended = suspended
	if suspended:
		_remember_move_phase()
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
		_resume_locomotion()


func set_facing_direction(horizontal_direction: float) -> void:
	if absf(horizontal_direction) < 0.01:
		return
	flip_h = horizontal_direction < 0.0

func _remember_move_phase() -> void:
	if animation == &"move":
		_saved_move_frame = frame
		_saved_move_progress = frame_progress


func _resume_locomotion() -> void:
	var fps := sprite_frames.get_animation_speed(_desired_locomotion)
	speed_scale = minf(locomotion_max_fps / maxf(fps, 0.01), 1.0) if _desired_locomotion == &"move" else 1.0
	play(_desired_locomotion)
	if _desired_locomotion == &"move":
		set_frame_and_progress(mini(_saved_move_frame, sprite_frames.get_frame_count(&"move") - 1), _saved_move_progress)


func _play_one_shot(animation_name: StringName) -> void:
	if not _visual_ready:
		return
	if not sprite_frames.has_animation(animation_name):
		return

	_remember_move_phase()
	speed_scale = 1.0
	_one_shot_locked = true
	play(animation_name)

func _on_animation_finished() -> void:
	if animation == &"death":
		if _revival_reverse_playing:
			_finish_revival_reverse()
			return
		if _revival_death_pose_playing:
			_hold_revival_death_pose()
			return
		_emit_death_finished()
		return

	if animation == &"attack" or animation == &"hit" or animation == &"skill":
		_one_shot_locked = false
		if _lod_suspended:
			return
		if sprite_frames.has_animation(_desired_locomotion):
			_resume_locomotion()

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
	_death_fade_duration = maxf(float(profile.get("death_fade_duration",0.0)),0.0)
	locomotion_max_fps = maxf(float(profile.get("locomotion_max_fps",8.0)),1.0)
	locomotion_transition_seconds = maxf(float(profile.get("locomotion_transition_seconds",0.12)),0.0)
	_saved_move_frame = 0
	_saved_move_progress = 0.0
	_pending_locomotion = &"idle"
	_locomotion_request_seconds = 0.0
	set_physics_process(false)
	speed_scale = 1.0

	var mode := String(profile.get("mode", ""))
	var animations = profile.get("animations", {})
	if typeof(animations) != TYPE_DICTIONARY:
		return false

	var cache_key := _get_profile_cache_key(mode, profile, animations)
	var cached = _frames_cache.get(cache_key)
	var built: SpriteFrames
	if cached is SpriteFrames:
		built = cached
	else:
		built = SpriteFrames.new()
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
		_frames_cache[cache_key] = built

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
	_revival_death_pose_playing = false
	_revival_death_pose_ready = false
	_revival_reverse_playing = false
	_desired_locomotion = &"idle"
	self_modulate = Color.WHITE
	play(&"idle")
	return true


func _get_profile_cache_key(
	mode: String,
	profile: Dictionary,
	animations: Dictionary
) -> String:
	return "profile|%s|%s|%s|%d|%d|%s" % [
		mode,
		String(profile.get("asset_dir", "")),
		String(profile.get("sheet_path", "")),
		int(profile.get("columns", 0)),
		int(profile.get("rows", 0)),
		var_to_str(animations),
	]


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
		var files: Array = config.get("files", [])
		for frame_index in range(1, count + 1):
			var filename := String(files[frame_index - 1]) if files.size() >= frame_index else "%s_%02d.png" % [prefix, frame_index]
			var texture := _load_texture(
				"%s/%s" % [dir_path, filename]
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
