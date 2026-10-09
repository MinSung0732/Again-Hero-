extends CharacterBody2D
const RECEIVED_STATUS := preload("res://src/data/status_effect_catalog.gd")

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

const SUMMONER_SFX := preload("res://src/audio/summoner_audio.gd")

signal released(hound: Node2D)

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const DEFAULT_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect3"
const DEFAULT_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/summoner_clean/follower_attack.wav"
const DEFAULT_SUMMON_AUDIO_PATH := "res://assets/audio/sfx/summoner_clean/portal.wav"

static var _frames_cache_by_dir: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_audio: AudioStreamPlayer = $AttackAudio
@onready var summon_audio: AudioStreamPlayer = $SummonAudio

var active: bool = false
var owner_hero: Node2D = null
var current_hp: int = 1
var max_hp: int = 1
var duration_total: float = 40.0
var duration_remaining: float = 0.0
var attack_damage: int = 1
var attack_range: float = 150.0
var attack_cooldown: float = 0.72
var move_speed: float = 300.0
var sense_range: float = 820.0
var hits_per_attack: int = 2
var hit_interval: float = 0.14
var attack_timer: float = 0.0
var pending_hits: int = 0
var hit_timer: float = 0.0
var attack_target: Node2D = null
var retarget_timer: float = 0.0
var target: Node2D = null
var dying: bool = false
var frame_dir: String = DEFAULT_FRAME_DIR
var visual_scale: float = 0.46
var visual_offset: Vector2 = Vector2(9.2, -55.2)
var owner_attack_damage: int = 1
var second_hit_bonus_ratio: float = 0.0
var high_hp_damage_bonus: float = 0.0
var elite_move_speed_bonus: float = 0.0


func _ready() -> void:
	_setup_visual(DEFAULT_FRAME_DIR)
	_load_audio(DEFAULT_ATTACK_AUDIO_PATH, DEFAULT_SUMMON_AUDIO_PATH)
	deactivate(false)


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	preload("res://src/systems/yuki_onna_runtime.gd").start_target_life(self)
	global_position = world_position
	owner_hero = new_owner
	owner_attack_damage = maxi(int(config.get("owner_attack_damage", 1)), 1)
	max_hp = maxi(int(config.get("max_hp", 2000)), 1)
	current_hp = max_hp
	duration_total = maxf(float(config.get("duration", 40.0)), 0.1)
	duration_remaining = duration_total
	attack_damage = maxi(
		int(round(
			float(config.get("owner_attack_damage", 1))
			* maxf(float(config.get("damage_ratio", 0.35)), 0.0)
		)),
		1
	)
	hits_per_attack = maxi(int(config.get("hits_per_attack", 2)), 1)
	hit_interval = maxf(float(config.get("hit_interval", 0.14)), 0.01)
	attack_range = maxf(float(config.get("attack_range", 150.0)), 1.0)
	attack_cooldown = maxf(float(config.get("attack_cooldown", 0.72)), 0.05)
	move_speed = maxf(float(config.get("move_speed", 300.0)), 1.0)
	sense_range = maxf(float(config.get("sense_range", 820.0)), attack_range)
	second_hit_bonus_ratio = maxf(float(config.get("second_hit_bonus_ratio", 0.0)), 0.0)
	high_hp_damage_bonus = maxf(float(config.get("high_hp_damage_bonus", 0.0)), 0.0)
	elite_move_speed_bonus = maxf(float(config.get("elite_move_speed_bonus", 0.0)), 0.0)
	frame_dir = String(config.get("frame_dir", DEFAULT_FRAME_DIR))
	visual_scale = maxf(float(config.get("visual_scale", 0.46)), 0.01)
	visual_offset = Vector2(
		float(config.get("visual_offset_x", 9.2)),
		float(config.get("visual_offset_y", -55.2))
	)
	_setup_visual(frame_dir)
	_load_audio(
		String(config.get("attack_audio_path", DEFAULT_ATTACK_AUDIO_PATH)),
		String(config.get("summon_audio_path", DEFAULT_SUMMON_AUDIO_PATH))
	)

	attack_timer = 0.45
	pending_hits = 0
	hit_timer = 0.0
	attack_target = null
	retarget_timer = 0.0
	target = null
	dying = false
	active = true
	visible = true
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", false)
	if not is_in_group("hero_summons"):
		add_to_group("hero_summons")
	set_physics_process(true)
	visual.visible = true
	visual.speed_scale = 1.0
	visual.play(&"summon")
	SUMMONER_SFX.play_portal(owner_hero, summon_audio)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return

	duration_remaining = maxf(duration_remaining - delta, 0.0)
	if duration_remaining <= 0.0:
		_begin_release()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	_update_pending_hits(delta)

	if visual.animation == &"summon" and visual.is_playing():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if dying:
		velocity = Vector2.ZERO
		return
	if pending_hits > 0:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if (
		not HERO_TARGET_POLICY.is_detectable(target)
		or retarget_timer <= 0.0
	):
		target = _find_nearest_target()
		retarget_timer = 0.10

	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		if visual.animation != &"idle":
			visual.play(&"idle")
		queue_redraw()
		return

	var distance := global_position.distance_to(target.global_position)
	var horizontal_delta := target.global_position.x - global_position.x
	if absf(horizontal_delta) > 2.0:
		visual.flip_h = horizontal_delta < 0.0

	if distance > attack_range * 0.88:
		var move_multiplier := 1.0
		if bool(target.get_meta("elite", false)) or bool(target.get_meta("boss", false)) or bool(target.get_meta("is_boss", false)):
			move_multiplier += elite_move_speed_bonus
		if is_instance_valid(owner_hero):
			if owner_hero.has_method("get_summoner_runtime_move_speed_multiplier"):
				move_multiplier *= maxf(
					float(owner_hero.call("get_summoner_runtime_move_speed_multiplier")),
					0.1
				)
			elif owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
				var support: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
				move_multiplier *= maxf(float(support.get("move_speed", 1.0)), 0.1)
		velocity = global_position.direction_to(target.global_position) * move_speed * move_multiplier * float(get_meta("yuki_slow_multiplier",1.0))*RECEIVED_STATUS.movement_multiplier(self)
		move_and_slide()
		if visual.animation != &"move":
			visual.play(&"move")
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			_start_attack(target)
		elif visual.animation != &"attack":
			visual.play(&"idle")
	queue_redraw()


func _update_pending_hits(delta: float) -> void:
	if pending_hits <= 0:
		return
	hit_timer = maxf(hit_timer - delta, 0.0)
	if hit_timer > 0.0:
		return

	if HERO_TARGET_POLICY.is_detectable(attack_target):
		if attack_target.has_method("take_damage"):
			var dealt_damage := float(attack_damage)
			var raw_hp = attack_target.get("current_hp")
			var raw_max_hp = attack_target.get("max_hp")
			if raw_hp != null and raw_max_hp != null and float(raw_max_hp) > 0.0 and float(raw_hp) / float(raw_max_hp) >= 0.50:
				dealt_damage *= 1.0 + high_hp_damage_bonus
			var hit_index := hits_per_attack - pending_hits + 1
			if hit_index == 2 and second_hit_bonus_ratio > 0.0:
				dealt_damage += float(owner_attack_damage) * second_hit_bonus_ratio
			attack_target.call("take_damage", maxi(int(round(dealt_damage*RECEIVED_STATUS.outgoing_multiplier(self))), 1))
		if attack_audio.stream != null:
			attack_audio.stop()
			attack_audio.play()

	pending_hits -= 1
	if pending_hits > 0:
		hit_timer = hit_interval
	else:
		attack_target = null


func _find_nearest_target() -> Node2D:
	var battle := get_parent()
	if not is_instance_valid(battle):
		return null

	if battle.has_method("get_nearest_monster_target"):
		var target = battle.call(
			"get_nearest_monster_target",
			global_position,
			sense_range
		)
		return target as Node2D if target is Node2D else null

	# Standalone/debug fallback only. Normal Battle runtime uses the spatial
	# nearest-target query above and allocates no candidate Array.
	var nearest: Node2D = null
	var nearest_distance_sq := sense_range * sense_range
	for raw_node in get_tree().get_nodes_in_group("monsters"):
		if not HERO_TARGET_POLICY.is_detectable(raw_node):
			continue
		var monster := raw_node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > nearest_distance_sq:
			continue
		nearest_distance_sq = distance_sq
		nearest = monster
	return nearest


func _start_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	var attack_speed_multiplier := 1.0
	if is_instance_valid(owner_hero):
		if owner_hero.has_method("get_summoner_runtime_attack_speed_multiplier"):
			attack_speed_multiplier = maxf(
				float(owner_hero.call("get_summoner_runtime_attack_speed_multiplier")),
				0.1
			)
		elif owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
			var support: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
			attack_speed_multiplier = maxf(float(support.get("attack_speed", 1.0)), 0.1)
	attack_timer = attack_cooldown / attack_speed_multiplier
	attack_target = current_target
	pending_hits = hits_per_attack
	hit_timer = 0.0
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"attack"):
		visual.play(&"attack")


func take_damage(amount: int, _source: Node = null) -> bool:
	if not active or dying or amount <= 0:
		return false
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied := previous_hp - current_hp
	if applied > 0:
		DAMAGE_NUMBERS.show(self, applied)
	if current_hp <= 0:
		_begin_release()
	else:
		queue_redraw()
	return applied > 0


func _begin_release() -> void:
	if not active or dying:
		return
	dying = true
	pending_hits = 0
	attack_target = null
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"death"):
		visual.play(&"death")
	else:
		deactivate()


func deactivate(emit_signal: bool = true) -> void:
	preload("res://src/systems/received_afflictions.gd").reset_on(self)
	var was_active := active
	active = false
	dying = false
	owner_hero = null
	target = null
	attack_target = null
	pending_hits = 0
	current_hp = 0
	duration_remaining = 0.0
	velocity = Vector2.ZERO
	visible = false
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	if is_in_group("hero_summons"):
		remove_from_group("hero_summons")
	if is_instance_valid(visual):
		visual.stop()
	if emit_signal and was_active:
		released.emit(self)


func _on_visual_animation_finished() -> void:
	if not active:
		return
	if visual.animation == &"summon":
		visual.play(&"idle")
	elif visual.animation == &"attack":
		if pending_hits <= 0:
			visual.play(&"idle")
	elif visual.animation == &"death":
		deactivate()


func _setup_visual(requested_frame_dir: String) -> void:
	var resolved_dir := requested_frame_dir
	if resolved_dir.is_empty():
		resolved_dir = DEFAULT_FRAME_DIR

	var frames: SpriteFrames = _frames_cache_by_dir.get(resolved_dir)
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		_add_sequence(frames, &"summon", resolved_dir, "summon", 3, 10.0, false)
		_add_sequence(frames, &"idle", resolved_dir, "idle", 4, 6.0, true)
		_add_sequence(frames, &"move", resolved_dir, "move", 4, 12.0, true)
		_add_sequence(frames, &"attack", resolved_dir, "attack", 6, 16.0, false)
		_add_sequence(frames, &"death", resolved_dir, "death", 4, 9.0, false)
		_frames_cache_by_dir[resolved_dir] = frames

	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(visual_scale, visual_scale)
	visual.position = visual_offset
	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)


func _add_sequence(
	frames: SpriteFrames,
	animation: StringName,
	base_dir: String,
	prefix: String,
	count: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for index in range(1, count + 1):
		var texture := _load_texture("%s/%s_%02d.png" % [base_dir, prefix, index])
		if texture != null:
			frames.add_frame(animation, texture)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	return null


func _load_audio(attack_path: String, summon_path: String) -> void:
	if not attack_path.is_empty() and ResourceLoader.exists(attack_path):
		var stream = load(attack_path)
		if stream is AudioStream:
			attack_audio.stream = stream
	if not summon_path.is_empty() and ResourceLoader.exists(summon_path):
		var stream = load(summon_path)
		if stream is AudioStream:
			summon_audio.stream = stream


func _draw() -> void:
	if not active:
		return
	var bar_width := 72.0
	var bar_center_x := 0.0
	var duration_bar_y := -102.0
	var hp_bar_y := -92.0
	var hp_ratio := clampf(float(current_hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var duration_ratio := clampf(duration_remaining / maxf(duration_total, 0.1), 0.0, 1.0)

	# Keep status gauges centered on the summon body origin. The sprite keeps
	# its own visual offset, while the bars stay stable across facing changes.
	draw_rect(Rect2(bar_center_x - bar_width / 2.0, duration_bar_y, bar_width, 5.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(bar_center_x - bar_width / 2.0, duration_bar_y, bar_width * duration_ratio, 5.0), Color(1.0, 1.0, 1.0), true)
	draw_rect(Rect2(bar_center_x - bar_width / 2.0, hp_bar_y, bar_width, 8.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(bar_center_x - bar_width / 2.0, hp_bar_y, bar_width * hp_ratio, 8.0), Color(0.45, 0.82, 1.0), true)
