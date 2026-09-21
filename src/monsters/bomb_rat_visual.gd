extends AnimatedSprite2D

signal death_animation_finished

const SHEET_COLUMNS := 6
const SHEET_ROWS := 5
const CELL_SIZE := 229

const IDLE_FRAMES := 4
const MOVE_FRAMES := 6
const ATTACK_FRAMES := 6
const HIT_FRAMES := 3
const DEATH_FRAMES := 4

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
	var loaded = load(sheet_path)
	if not loaded is Texture2D:
		push_warning("BombRat visual: sprite sheet load failed: %s" % sheet_path)
		return

	var source_texture := loaded as Texture2D
	var expected_width := SHEET_COLUMNS * CELL_SIZE
	var expected_height := SHEET_ROWS * CELL_SIZE

	if (
		source_texture.get_width() != expected_width
		or source_texture.get_height() != expected_height
	):
		push_warning(
			"BombRat visual: expected %dx%d but got %dx%d"
			% [
				expected_width,
				expected_height,
				source_texture.get_width(),
				source_texture.get_height(),
			]
		)
		return

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	_add_row_animation(
		frames,
		source_texture,
		&"idle",
		0,
		IDLE_FRAMES,
		idle_fps,
		true
	)
	_add_row_animation(
		frames,
		source_texture,
		&"move",
		1,
		MOVE_FRAMES,
		move_fps,
		true
	)
	_add_row_animation(
		frames,
		source_texture,
		&"attack",
		2,
		ATTACK_FRAMES,
		attack_fps,
		false
	)
	_add_row_animation(
		frames,
		source_texture,
		&"hit",
		3,
		HIT_FRAMES,
		hit_fps,
		false
	)
	_add_row_animation(
		frames,
		source_texture,
		&"death",
		4,
		DEATH_FRAMES,
		death_fps,
		false
	)

	sprite_frames = frames
	var uniform_scale := target_height / float(CELL_SIZE)
	scale = Vector2(uniform_scale, uniform_scale)
	_visual_ready = true

	print(
		"BombRat visual ready: %dx%d / cell %d / grid %dx%d"
		% [
			source_texture.get_width(),
			source_texture.get_height(),
			CELL_SIZE,
			SHEET_COLUMNS,
			SHEET_ROWS,
		]
	)

func _add_row_animation(
	frames: SpriteFrames,
	source_texture: Texture2D,
	animation_name: StringName,
	row: int,
	frame_count: int,
	fps: float,
	looping: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)

	for column in range(frame_count):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(
			float(column * CELL_SIZE),
			float(row * CELL_SIZE),
			float(CELL_SIZE),
			float(CELL_SIZE)
		)
		frames.add_frame(animation_name, atlas_texture)
