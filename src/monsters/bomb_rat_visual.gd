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
	if sheet_path.is_empty():
		return

	var loaded = load(sheet_path)
	if not loaded is Texture2D:
		push_warning("BombRat visual: sprite sheet load failed: %s" % sheet_path)
		return

	var source_texture := loaded as Texture2D
	var width := source_texture.get_width()
	var height := source_texture.get_height()
	var layout := _detect_layout(width, height)

	if layout.is_empty():
		push_warning(
			"BombRat visual: unsupported sheet size %dx%d" % [width, height]
		)
		return

	var columns := int(layout.get("columns", 0))
	var rows := int(layout.get("rows", 0))
	var cell_size := int(layout.get("cell_size", 0))

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	_add_row_animation(
		frames,
		source_texture,
		&"idle",
		0,
		columns,
		cell_size,
		idle_fps,
		true
	)

	if rows >= 2:
		_add_row_animation(
			frames,
			source_texture,
			&"move",
			1,
			columns,
			cell_size,
			move_fps,
			true
		)

	if rows >= 3:
		_add_row_animation(
			frames,
			source_texture,
			&"attack",
			2,
			columns,
			cell_size,
			attack_fps,
			false
		)

	if rows >= 5:
		_add_row_animation(
			frames,
			source_texture,
			&"hit",
			3,
			columns,
			cell_size,
			hit_fps,
			false
		)
		_add_row_animation(
			frames,
			source_texture,
			&"death",
			4,
			columns,
			cell_size,
			death_fps,
			false
		)
	elif rows >= 4:
		_add_row_animation(
			frames,
			source_texture,
			&"death",
			3,
			columns,
			cell_size,
			death_fps,
			false
		)

	if not frames.has_animation(&"idle"):
		return
	if frames.get_frame_count(&"idle") <= 0:
		return

	sprite_frames = frames
	var uniform_scale := target_height / float(cell_size)
	scale = Vector2(uniform_scale, uniform_scale)
	_visual_ready = true

	print(
		"BombRat visual ready: sheet=%dx%d grid=%dx%d cell=%d"
		% [width, height, columns, rows, cell_size]
	)

func _detect_layout(width: int, height: int) -> Dictionary:
	if width <= 0 or height <= 0:
		return {}

	var best: Dictionary = {}
	var best_score := -999999

	for cell_size in [32, 48, 64, 80, 96, 128, 160, 192, 256, 320, 384, 512]:
		if width % cell_size != 0 or height % cell_size != 0:
			continue

		var columns := int(width / cell_size)
		var rows := int(height / cell_size)

		if columns < 2 or columns > 12:
			continue
		if rows < 3 or rows > 6:
			continue

		var score := 0

		if rows == 4:
			score += 100
		elif rows == 5:
			score += 90
		elif rows == 6:
			score += 45
		else:
			score += 25

		if columns >= 4 and columns <= 8:
			score += 40
		elif columns >= 3 and columns <= 10:
			score += 20

		if columns == 6:
			score += 12
		elif columns == 4:
			score += 10
		elif columns == 8:
			score += 8

		if score > best_score:
			best_score = score
			best = {
				"columns": columns,
				"rows": rows,
				"cell_size": cell_size,
			}

	return best

func _add_row_animation(
	frames: SpriteFrames,
	source_texture: Texture2D,
	animation_name: StringName,
	row: int,
	columns: int,
	cell_size: int,
	fps: float,
	looping: bool
) -> void:
	if row < 0 or columns <= 0 or cell_size <= 0:
		return

	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)

	for column in range(columns):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(
			float(column * cell_size),
			float(row * cell_size),
			float(cell_size),
			float(cell_size)
		)
		frames.add_frame(animation_name, atlas_texture)
