extends Node2D

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

signal released(watcher: Node2D)

const PROJECTILE_SCENE := preload("res://src/hero/SummonerGatekeeperProjectile.tscn")
const DEFAULT_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect4"
const DEFAULT_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_attack_pixabay.mp3"
const DEFAULT_SUMMON_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_summon_pixabay.mp3"
const PROJECTILE_POOL_SIZE := 8

static var _frames_cache_by_dir: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual
@onready var attack_audio: AudioStreamPlayer = $AttackAudio
@onready var summon_audio: AudioStreamPlayer = $SummonAudio

var active: bool = false
var owner_hero: Node2D = null
var duration_total: float = 20.0
var duration_remaining: float = 0.0
var attack_damage: int = 1
var attack_range: float = 700.0
var attack_cooldown: float = 0.34
var projectile_speed: float = 800.0
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var target: Node2D = null
var dying: bool = false
var follow_slot: int = -1
var follow_offset: Vector2 = Vector2.ZERO
var frame_dir: String = DEFAULT_FRAME_DIR
var visual_scale: float = 0.50
var visual_offset: Vector2 = Vector2(24.0, -8.0)
var focus_attack_speed_bonus: float = 0.0
var focus_damage_bonus: float = 0.0
var projectile_pool: Array[Node2D] = []


func _ready() -> void:
	_setup_visual(DEFAULT_FRAME_DIR)
	_load_audio(DEFAULT_ATTACK_AUDIO_PATH, DEFAULT_SUMMON_AUDIO_PATH)
	deactivate(false)
	call_deferred("_build_projectile_pool")


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	owner_hero = new_owner
	follow_slot = maxi(int(config.get("follow_slot", 0)), 0)
	duration_total = maxf(float(config.get("duration", 20.0)), 0.1)
	duration_remaining = duration_total
	attack_damage = maxi(
		int(round(
			float(config.get("owner_attack_damage", 1))
			* maxf(float(config.get("damage_ratio", 0.10)), 0.0)
		)),
		1
	)
	attack_range = maxf(float(config.get("attack_range", 700.0)), 1.0)
	attack_cooldown = maxf(float(config.get("attack_cooldown", 0.34)), 0.05)
	projectile_speed = maxf(float(config.get("projectile_speed", 800.0)), 1.0)
	focus_attack_speed_bonus = maxf(float(config.get("focus_attack_speed_bonus", 0.0)), 0.0)
	focus_damage_bonus = maxf(float(config.get("focus_damage_bonus", 0.0)), 0.0)
	frame_dir = String(config.get("frame_dir", DEFAULT_FRAME_DIR))
	visual_scale = maxf(float(config.get("visual_scale", 0.50)), 0.01)
	visual_offset = Vector2(
		float(config.get("visual_offset_x", 24.0)),
		float(config.get("visual_offset_y", -8.0))
	)
	follow_offset = _resolve_follow_offset(config, follow_slot)
	_setup_visual(frame_dir)
	_load_audio(
		String(config.get("attack_audio_path", DEFAULT_ATTACK_AUDIO_PATH)),
		String(config.get("summon_audio_path", DEFAULT_SUMMON_AUDIO_PATH))
	)

	global_position = world_position
	_update_follow_position()
	attack_timer = 0.20
	retarget_timer = 0.0
	target = null
	dying = false
	active = true
	visible = true
	if not is_in_group("hero_summons"):
		add_to_group("hero_summons")
	set_physics_process(true)
	visual.visible = true
	visual.play(&"idle")
	if summon_audio.stream != null:
		summon_audio.stop()
		summon_audio.play()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(owner_hero) or owner_hero.is_queued_for_deletion():
		deactivate()
		return

	_update_follow_position()
	duration_remaining = maxf(duration_remaining - delta, 0.0)
	if duration_remaining <= 0.0:
		_begin_release()
		return
	if dying:
		queue_redraw()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)

	var priority_target := _get_owner_priority_target()
	if is_instance_valid(priority_target):
		target = priority_target
		retarget_timer = 0.10
	elif (
		not HERO_TARGET_POLICY.is_detectable(target)
		or retarget_timer <= 0.0
	):
		target = _find_nearest_target()
		retarget_timer = 0.10

	if is_instance_valid(target):
		var horizontal_delta := target.global_position.x - global_position.x
		if absf(horizontal_delta) > 2.0:
			visual.flip_h = horizontal_delta < 0.0
		if attack_timer <= 0.0:
			_fire_at_target(target)
	elif visual.animation != &"idle":
		visual.play(&"idle")

	queue_redraw()


func _get_owner_priority_target() -> Node2D:
	if not is_instance_valid(owner_hero):
		return null
	var raw_target = owner_hero.get("target")
	if not raw_target is Node2D:
		return null
	var priority_target := raw_target as Node2D
	if (
		not is_instance_valid(priority_target)
		or priority_target.is_queued_for_deletion()
		or global_position.distance_squared_to(priority_target.global_position)
		> attack_range * attack_range
	):
		return null
	return priority_target


func _find_nearest_target() -> Node2D:
	var battle := get_parent()
	if not is_instance_valid(battle):
		return null

	if battle.has_method("get_nearest_monster_target"):
		var target = battle.call(
			"get_nearest_monster_target",
			global_position,
			attack_range
		)
		return target as Node2D if target is Node2D else null

	# Standalone/debug fallback only. Normal Battle runtime uses the spatial
	# nearest-target query above and allocates no candidate Array.
	var nearest: Node2D = null
	var nearest_distance_sq := attack_range * attack_range
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


func _fire_at_target(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	var projectile := _acquire_projectile()
	if projectile == null:
		return

	var focus_active := false
	if is_instance_valid(owner_hero):
		var owner_target = owner_hero.get("target")
		focus_active = owner_target == current_target
	var attack_speed_multiplier := 1.0 + (focus_attack_speed_bonus if focus_active else 0.0)
	if is_instance_valid(owner_hero):
		if owner_hero.has_method("get_summoner_runtime_attack_speed_multiplier"):
			attack_speed_multiplier *= maxf(
				float(owner_hero.call("get_summoner_runtime_attack_speed_multiplier")),
				0.1
			)
		elif owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
			var support: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
			attack_speed_multiplier *= maxf(float(support.get("attack_speed", 1.0)), 0.1)
	attack_timer = attack_cooldown / maxf(attack_speed_multiplier, 0.1)
	var shot_damage := maxi(int(round(float(attack_damage) * (1.0 + (focus_damage_bonus if focus_active else 0.0)))), 1)
	projectile.call(
		"activate",
		global_position,
		current_target,
		shot_damage,
		projectile_speed,
		attack_range
	)
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"attack"):
		visual.stop()
		visual.play(&"attack")


func _acquire_projectile() -> Node2D:
	for projectile in projectile_pool:
		if is_instance_valid(projectile) and bool(projectile.call("is_available")):
			return projectile
	return null


func take_damage(_amount: int, _source: Node = null) -> bool:
	# Watchers are intentionally invulnerable and only expire by duration.
	return false


func _begin_release() -> void:
	if not active or dying:
		return
	dying = true
	target = null
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"death"):
		visual.play(&"death")
	else:
		deactivate()


func deactivate(emit_signal: bool = true) -> void:
	var was_active := active
	active = false
	dying = false
	owner_hero = null
	target = null
	duration_remaining = 0.0
	follow_slot = -1
	visible = false
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
	if visual.animation == &"death":
		deactivate()
	elif visual.animation == &"attack":
		visual.play(&"idle")


func _update_follow_position() -> void:
	if is_instance_valid(owner_hero):
		global_position = owner_hero.global_position + follow_offset


func _resolve_follow_offset(config: Dictionary, slot_index: int) -> Vector2:
	var key := "follow_left_offset" if slot_index == 0 else "follow_right_offset"
	var raw_offset = config.get(
		key,
		[-95.0, -110.0] if slot_index == 0 else [95.0, -110.0]
	)
	if raw_offset is Array and raw_offset.size() >= 2:
		return Vector2(float(raw_offset[0]), float(raw_offset[1]))
	return Vector2(-95.0, -110.0) if slot_index == 0 else Vector2(95.0, -110.0)


func _setup_visual(requested_frame_dir: String) -> void:
	var resolved_dir := requested_frame_dir
	if resolved_dir.is_empty():
		resolved_dir = DEFAULT_FRAME_DIR

	var frames: SpriteFrames = _frames_cache_by_dir.get(resolved_dir)
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		_add_sequence(frames, &"idle", resolved_dir, "idle", 4, 8.0, true)
		_add_sequence(frames, &"attack", resolved_dir, "attack", 8, 24.0, false)
		_add_sequence(frames, &"death", resolved_dir, "death", 3, 10.0, false)
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


func _build_projectile_pool() -> void:
	if not projectile_pool.is_empty():
		return
	var world := get_parent()
	if not is_instance_valid(world):
		return
	for _index in range(PROJECTILE_POOL_SIZE):
		var projectile := PROJECTILE_SCENE.instantiate() as Node2D
		if projectile == null:
			continue
		world.add_child(projectile)
		projectile_pool.append(projectile)


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
	var bar_width := 54.0
	var duration_ratio := clampf(duration_remaining / maxf(duration_total, 0.1), 0.0, 1.0)
	draw_rect(Rect2(-bar_width / 2.0, -54.0, bar_width, 5.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(-bar_width / 2.0, -54.0, bar_width * duration_ratio, 5.0), Color(1.0, 1.0, 1.0), true)
