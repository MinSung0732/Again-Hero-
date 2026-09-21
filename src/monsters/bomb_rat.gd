extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const BOMBRAT_SHEET_PATH := "res://assets/art/monsters/bombrat/bombrat_spritesheet.png"
const BOMBRAT_FRAME_SIZE := Vector2(229, 229)
const BOMBRAT_TARGET_HEIGHT := 78.0
const BOMBRAT_EFFECT_FRAME_DIR := "res://assets/art/monsters/bombrat/frames"
const BOMBRAT_EFFECT_FRAME_COUNT := 8
const BOMBRAT_EFFECT_TARGET_DIAMETER := 300.0

signal died

@export var monster_type: String = "bomb_rat"
@export var monster_role: String = "burst"
@export var max_hp: int = 36
@export var move_speed: float = 175.0
@export var self_destruct_range: float = 78.0
@export var self_destruct_fuse: float = 0.30
@export var exp_reward: int = 30
@export var self_destruct_exp_reward: int = 10
@export var hero_kill_exp_reward: int = 30
@export var explosion_radius: float = 150.0
@export var explosion_damage: int = 28

@onready var visual: AnimatedSprite2D = $Visual
@onready var explosion_effect: AnimatedSprite2D = $ExplosionEffect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var hit_flash_timer: float = 0.0
var dying: bool = false
var self_destructing: bool = false
var self_destruct_timer: float = 0.0
var desired_locomotion: StringName = &"idle"

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	exp_reward = hero_kill_exp_reward
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	_apply_bomb_rat_visual()
	_apply_bomb_rat_explosion_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if self_destructing:
		velocity = Vector2.ZERO
		self_destruct_timer = maxf(self_destruct_timer - delta, 0.0)
		if self_destruct_timer <= 0.0:
			_complete_self_destruct()
		return

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_play_locomotion(false)
			return

	var direction_to_hero := global_position.direction_to(hero.global_position)
	if visual.visible and absf(direction_to_hero.x) > 0.01:
		visual.flip_h = direction_to_hero.x < 0.0

	var distance := global_position.distance_to(hero.global_position)
	if distance > self_destruct_range:
		velocity = direction_to_hero * move_speed
		_play_locomotion(true)
		move_and_slide()
	else:
		_begin_self_destruct()

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10

	if current_hp <= 0:
		_die_from_hero()
		return

	if not self_destructing:
		_restart_visual_animation(&"hit")
	queue_redraw()

func _begin_self_destruct() -> void:
	if self_destructing or dying:
		return

	self_destructing = true
	self_destruct_timer = maxf(self_destruct_fuse, 0.0)
	velocity = Vector2.ZERO
	_restart_visual_animation(&"attack")

	if self_destruct_timer <= 0.0:
		_complete_self_destruct()

func _complete_self_destruct() -> void:
	if dying:
		return

	dying = true
	self_destructing = false
	velocity = Vector2.ZERO
	current_hp = 0
	exp_reward = self_destruct_exp_reward
	collision_shape.set_deferred("disabled", true)

	_play_explosion_effect()
	_trigger_death_explosion()
	died.emit()
	_play_death_or_free()

func _die_from_hero() -> void:
	if dying:
		return

	dying = true
	self_destructing = false
	velocity = Vector2.ZERO
	current_hp = 0
	exp_reward = hero_kill_exp_reward
	collision_shape.set_deferred("disabled", true)

	died.emit()
	_play_death_or_free()

func _play_death_or_free() -> void:
	if visual.visible and visual.sprite_frames != null:
		_restart_visual_animation(&"death")
	else:
		queue_free()

func _trigger_death_explosion() -> void:
	if not is_instance_valid(hero):
		return
	if global_position.distance_to(hero.global_position) > explosion_radius:
		return
	if hero.has_method("take_damage"):
		hero.call("take_damage", explosion_damage)

func apply_visual_profile(profile: Dictionary) -> bool:
	if profile.is_empty():
		return false

	var mode := String(profile.get("mode", ""))
	if mode == "sequence":
		return _apply_bomb_rat_sequence_visual(profile)
	if mode != "sheet":
		return false

	var sheet_path := String(profile.get("sheet_path", ""))
	if sheet_path.is_empty():
		return false

	return _apply_bomb_rat_visual(
		sheet_path,
		float(profile.get("target_height", BOMBRAT_TARGET_HEIGHT))
	)

func _apply_bomb_rat_sequence_visual(profile: Dictionary) -> bool:
	var dir_path := String(profile.get("asset_dir", ""))
	var animations = profile.get("animations", {})
	if dir_path.is_empty() or typeof(animations) != TYPE_DICTIONARY:
		return false

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	for raw_name in animations.keys():
		var animation_name := StringName(String(raw_name))
		var config: Dictionary = animations[raw_name]
		var start_index := int(config.get("start", 1))
		var count := int(config.get("count", 0))
		if count <= 0:
			continue

		var textures: Array[Texture2D] = []
		for offset in range(count):
			var texture := _load_bomb_rat_texture(
				"%s/frame_%02d.png" % [
					dir_path,
					start_index + offset,
				]
			)
			if texture != null:
				textures.append(texture)

		if textures.is_empty():
			continue

		frames.add_animation(animation_name)
		frames.set_animation_speed(
			animation_name,
			float(config.get("fps", 10.0))
		)
		frames.set_animation_loop(
			animation_name,
			bool(config.get("loop", false))
		)
		for texture in textures:
			frames.add_frame(animation_name, texture)

	if not frames.has_animation(&"idle"):
		return false
	if frames.get_frame_count(&"idle") <= 0:
		return false

	var first_texture := frames.get_frame_texture(&"idle", 0)
	if first_texture == null:
		return false

	visual.visible = false
	visual.sprite_frames = frames
	visual.modulate = Color.WHITE
	visual.rotation = 0.0
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var target_height := float(
		profile.get("target_height", BOMBRAT_TARGET_HEIGHT)
	)
	var source_height := maxf(float(first_texture.get_height()), 1.0)
	var uniform_scale := target_height / source_height
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.visible = true
	visual.speed_scale = 1.0

	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)

	visual.play(&"idle")
	return true

func _apply_bomb_rat_visual(
	sheet_path: String = BOMBRAT_SHEET_PATH,
	profile_height: float = BOMBRAT_TARGET_HEIGHT
) -> bool:
	visual.visible = false
	visual.sprite_frames = null
	visual.modulate = Color.WHITE
	visual.rotation = 0.0
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var sheet := _load_bomb_rat_texture(sheet_path)
	if sheet == null:
		push_warning("Bomb Rat spritesheet load failed: %s" % sheet_path)
		return false

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	_add_sheet_animation(frames, &"idle", sheet, 0, 4, 6.0, true)
	_add_sheet_animation(frames, &"move", sheet, 1, 6, 11.0, true)
	_add_sheet_animation(frames, &"attack", sheet, 2, 6, 14.0, false)
	_add_sheet_animation(frames, &"hit", sheet, 3, 3, 14.0, false)
	_add_sheet_animation(frames, &"death", sheet, 4, 4, 10.0, false)

	visual.sprite_frames = frames
	var uniform_scale := profile_height / BOMBRAT_FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.visible = true
	visual.speed_scale = 1.0

	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)

	visual.play(&"idle")
	return true

func _apply_bomb_rat_explosion_visual() -> void:
	explosion_effect.visible = false
	explosion_effect.sprite_frames = null
	explosion_effect.modulate = Color.WHITE
	explosion_effect.rotation = 0.0
	explosion_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"explode")
	frames.set_animation_speed(&"explode", 14.0)
	frames.set_animation_loop(&"explode", false)

	var first_texture: Texture2D = null
	for frame_index in range(1, BOMBRAT_EFFECT_FRAME_COUNT + 1):
		var path := "%s/frame_%02d.png" % [
			BOMBRAT_EFFECT_FRAME_DIR,
			frame_index,
		]
		var texture := _load_bomb_rat_texture(path)
		if texture == null:
			continue
		if first_texture == null:
			first_texture = texture
		frames.add_frame(&"explode", texture)

	if first_texture == null:
		push_warning(
			"Bomb Rat explosion frames not found: %s"
			% BOMBRAT_EFFECT_FRAME_DIR
		)
		return

	explosion_effect.sprite_frames = frames
	var source_width := maxf(float(first_texture.get_width()), 1.0)
	var uniform_scale := BOMBRAT_EFFECT_TARGET_DIAMETER / source_width
	explosion_effect.scale = Vector2(uniform_scale, uniform_scale)
	explosion_effect.speed_scale = 1.0

	if not explosion_effect.animation_finished.is_connected(
		_on_explosion_effect_finished
	):
		explosion_effect.animation_finished.connect(
			_on_explosion_effect_finished
		)

func _play_explosion_effect() -> void:
	if explosion_effect.sprite_frames == null:
		return
	if not explosion_effect.sprite_frames.has_animation(&"explode"):
		return

	explosion_effect.visible = true
	explosion_effect.stop()
	explosion_effect.animation = &"explode"
	explosion_effect.frame = 0
	explosion_effect.frame_progress = 0.0
	explosion_effect.play(&"explode")

func _on_explosion_effect_finished() -> void:
	if explosion_effect.animation == &"explode":
		explosion_effect.visible = false

func _load_bomb_rat_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null

	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture

	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(path)
		if error == OK:
			return ImageTexture.create_from_image(image)

	return null

func _add_sheet_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	sheet: Texture2D,
	row: int,
	frame_count: int,
	fps: float,
	loop_animation: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)

	for column in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.filter_clip = true
		atlas.region = Rect2(
			Vector2(column, row) * BOMBRAT_FRAME_SIZE,
			BOMBRAT_FRAME_SIZE
		)
		frames.add_frame(animation_name, atlas)

func _play_locomotion(moving: bool) -> void:
	desired_locomotion = &"move" if moving else &"idle"

	if not visual.visible or visual.sprite_frames == null or dying or self_destructing:
		return

	if visual.animation == &"attack" or visual.animation == &"hit":
		return

	if visual.animation != desired_locomotion or not visual.is_playing():
		visual.play(desired_locomotion)

func _restart_visual_animation(animation_name: StringName) -> void:
	if not visual.visible or visual.sprite_frames == null:
		return
	if not visual.sprite_frames.has_animation(animation_name):
		return

	visual.stop()
	visual.animation = animation_name
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.speed_scale = 1.0
	visual.play(animation_name)

func _on_visual_animation_finished() -> void:
	if not visual.visible:
		return

	if visual.animation == &"death":
		queue_free()
		return

	if visual.animation == &"hit" and not dying and not self_destructing:
		if visual.sprite_frames.has_animation(desired_locomotion):
			visual.play(desired_locomotion)

func _draw() -> void:
	if not visual.visible:
		var body_color := Color(0.54, 0.43, 0.34)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE

		draw_circle(Vector2(-3, 3), 22.0, body_color)
		draw_circle(Vector2(17, -2), 14.0, body_color)
		draw_circle(Vector2(22, -6), 3.0, Color(0.9, 0.35, 0.25))
		draw_line(Vector2(-24, 6), Vector2(-40, 16), body_color, 5.0)

		draw_circle(Vector2(-7, -18), 12.0, Color(0.16, 0.16, 0.18))
		draw_line(
			Vector2(-7, -30),
			Vector2(3, -42),
			Color(0.92, 0.62, 0.22),
			4.0
		)
		draw_circle(Vector2(5, -44), 4.0, Color(1.0, 0.4, 0.16))

	if dying:
		return

	var bar_width := 58.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -48.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -48.0, bar_width * hp_ratio, 7.0),
		Color(0.95, 0.38, 0.32),
		true
	)
