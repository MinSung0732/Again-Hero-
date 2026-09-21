extends AnimatedSprite2D

signal death_animation_finished

@export var sheet_path: String = "res://assets/art/monsters/bombrat/bombrat_spritesheet.png"
@export var target_height: float = 78.0
@export var idle_fps: float = 6.0
@export var move_fps: float = 10.0
@export var attack_fps: float = 14.0
@export var hit_fps: float = 14.0
@export var death_fps: float = 10.0

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
	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		return

	var loaded = load(sheet_path)
	if not loaded is Texture2D:
		return

	var source_texture := loaded as Texture2D
	var image := source_texture.get_image()
	if image == null or image.is_empty():
		return

	var layout := _detect_layout(image.get_width(), image.get_height())
	if layout.is_empty():
		return

	var columns := int(layout.get("columns", 0))
	var rows := int(layout.get("rows", 0))
	var cell_size := int(layout.get("cell_size", 0))
	if columns <= 0 or rows <= 0 or cell_size <= 0:
		return

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	_add_row_animation(frames, source_texture, image, &"idle", 0, columns, cell_size, idle_fps, true)

	if rows >= 2:
		_add_row_animation(frames, source_texture, image, &"move", 1, columns, cell_size, move_fps, true)
	if rows >= 3:
		_add_row_animation(frames, source_texture, image, &"attack", 2, columns, cell_size, attack_fps, false)

	if rows >= 5:
		_add_row_animation(frames, source_texture, image, &"hit", 3, columns, cell_size, hit_fps, false)
		_add_row_animation(frames, source_texture, image, &"death", 4, columns, cell_size, death_fps, false)
	elif rows >= 4:
		_add_row_animation(frames, source_texture, image, &"death", 3, columns, cell_size, death_fps, false)

	if not frames.has_animation(&"idle") or frames.get_frame_count(&"idle") <= 0:
		return

	sprite_frames = frames
	var uniform_scale := target_height / float(cell_size)
	scale = Vector2(uniform_scale, uniform_scale)
	_visual_ready = true

func _detect_layout(width: int, height: int) -> Dictionary:
	for rows in [5, 4, 6, 3]:
		if rows <= 0 or height % rows != 0:
			continue

		var cell_size := height / rows
		if cell_size <= 0 or width % cell_size != 0:
			continue

		var columns := width / cell_size
		if columns < 2 or columns > 12:
			continue

		return {
			"columns": columns,
			"rows": rows,
			"cell_size": cell_size,
		}

	return {}

func _add_row_animation(
	frames: SpriteFrames,
	source_texture: Texture2D,
	image: Image,
	animation_name: StringName,
	row: int,
	columns: int,
	cell_size: int,
	fps: float,
	looping: bool
) -> void:
	var textures: Array[Texture2D] = []

	for column in range(columns):
		var cell_region := Rect2i(
			column * cell_size,
			row * cell_size,
			cell_size,
			cell_size
		)
		if not _cell_has_visible_pixel(image, cell_region):
			continue

		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(
			cell_region.position,
			cell_region.size
		)
		textures.append(atlas_texture)

	if textures.is_empty():
		return

	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)

	for texture in textures:
		frames.add_frame(animation_name, texture)

func _cell_has_visible_pixel(image: Image, region: Rect2i) -> bool:
	var sample_step := maxi(region.size.x / 32, 1)
	var x_end := region.position.x + region.size.x
	var y_end := region.position.y + region.size.y

	for y in range(region.position.y, y_end, sample_step):
		for x in range(region.position.x, x_end, sample_step):
			if image.get_pixel(x, y).a > 0.02:
				return true

	return false
