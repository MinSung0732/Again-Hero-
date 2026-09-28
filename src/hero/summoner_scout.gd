extends CharacterBody2D

signal released(scout: Node2D)

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const DEFAULT_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect2"
const DEFAULT_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_attack_pixabay.mp3"
const DEFAULT_SUMMON_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_summon_pixabay.mp3"

static var _frames_cache_by_dir: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_audio: AudioStreamPlayer = $AttackAudio
@onready var summon_audio: AudioStreamPlayer = $SummonAudio

var active: bool = false
var owner_hero: Node2D = null
var current_hp: int = 1
var max_hp: int = 1
var duration_total: float = 60.0
var duration_remaining: float = 0.0
var attack_damage: int = 1
var attack_range: float = 150.0
var attack_cooldown: float = 0.62
var move_speed: float = 220.0
var sense_range: float = 760.0
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var target: Node2D = null
var dying: bool = false
var frame_dir: String = DEFAULT_FRAME_DIR


func _ready() -> void:
	_setup_visual(DEFAULT_FRAME_DIR)
	_load_audio(DEFAULT_ATTACK_AUDIO_PATH, DEFAULT_SUMMON_AUDIO_PATH)
	deactivate(false)


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	global_position = world_position
	owner_hero = new_owner
	max_hp = maxi(int(config.get("max_hp", 1050)), 1)
	current_hp = max_hp
	duration_total = maxf(float(config.get("duration", 60.0)), 0.1)
	duration_remaining = duration_total
	attack_damage = maxi(
		int(round(
			float(config.get("owner_attack_damage", 1))
			* maxf(float(config.get("damage_ratio", 0.50)), 0.0)
		)),
		1
	)
	attack_range = maxf(float(config.get("attack_range", 150.0)), 1.0)
	attack_cooldown = maxf(float(config.get("attack_cooldown", 0.62)), 0.05)
	move_speed = maxf(float(config.get("move_speed", 220.0)), 1.0)
	sense_range = maxf(float(config.get("sense_range", 760.0)), attack_range)
	frame_dir = String(config.get("frame_dir", DEFAULT_FRAME_DIR))
	_setup_visual(frame_dir)
	_load_audio(
		String(config.get("attack_audio_path", DEFAULT_ATTACK_AUDIO_PATH)),
		String(config.get("summon_audio_path", DEFAULT_SUMMON_AUDIO_PATH))
	)

	attack_timer = 0.45
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
	if summon_audio.stream != null:
		summon_audio.stop()
		summon_audio.play()
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

	if visual.animation == &"summon" and visual.is_playing():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if dying:
		velocity = Vector2.ZERO
		return

	if (
		not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or retarget_timer <= 0.0
	):
		target = _find_nearest_target()
		retarget_timer = 0.12

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
		if is_instance_valid(owner_hero):
			if owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
				var support: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
				move_multiplier *= maxf(float(support.get("move_speed", 1.0)), 0.1)
			if owner_hero.has_method("get_summoner_scout_swarm_multipliers"):
				var swarm: Dictionary = owner_hero.call("get_summoner_scout_swarm_multipliers")
				move_multiplier *= maxf(float(swarm.get("move_speed", 1.0)), 0.1)
		velocity = global_position.direction_to(target.global_position) * move_speed * move_multiplier
		move_and_slide()
		if visual.animation != &"move":
			visual.play(&"move")
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			_attack_target(target)
		elif visual.animation != &"attack":
			visual.play(&"idle")
	queue_redraw()


func _find_nearest_target() -> Node2D:
	var battle := get_parent()
	if not is_instance_valid(battle):
		return null

	var candidates: Array = []
	if battle.has_method("query_monsters_near"):
		var result = battle.call("query_monsters_near", global_position, sense_range)
		if result is Array:
			candidates = result
	else:
		# Compatibility fallback only. Normal battle runtime uses the spatial query.
		candidates = get_tree().get_nodes_in_group("monsters")

	var nearest: Node2D = null
	var nearest_distance_sq := sense_range * sense_range
	for raw_node in candidates:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if monster == null:
			continue
		var distance_sq := global_position.distance_squared_to(monster.global_position)
		if distance_sq > nearest_distance_sq:
			continue
		nearest_distance_sq = distance_sq
		nearest = monster
	return nearest


func _attack_target(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	var attack_speed_multiplier := 1.0
	var damage_multiplier := 1.0
	if is_instance_valid(owner_hero):
		if owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
			var support: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
			attack_speed_multiplier *= maxf(float(support.get("attack_speed", 1.0)), 0.1)
		if owner_hero.has_method("get_summoner_scout_swarm_multipliers"):
			var swarm: Dictionary = owner_hero.call("get_summoner_scout_swarm_multipliers")
			attack_speed_multiplier *= maxf(float(swarm.get("attack_speed", 1.0)), 0.1)
			damage_multiplier *= maxf(float(swarm.get("damage", 1.0)), 0.1)
	attack_timer = attack_cooldown / attack_speed_multiplier
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"attack"):
		visual.play(&"attack")
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()
	if current_target.has_method("take_damage"):
		current_target.call("take_damage", maxi(int(round(float(attack_damage) * damage_multiplier)), 1))


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
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
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
	if visual.animation == &"summon" or visual.animation == &"attack":
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
		_add_sequence(frames, &"summon", resolved_dir, "summon", 4, 10.0, false)
		_add_sequence(frames, &"idle", resolved_dir, "idle", 4, 6.0, true)
		_add_sequence(frames, &"move", resolved_dir, "move", 6, 10.0, true)
		_add_sequence(frames, &"attack", resolved_dir, "attack", 4, 14.0, false)
		_add_sequence(frames, &"death", resolved_dir, "death", 4, 8.0, false)
		_frames_cache_by_dir[resolved_dir] = frames

	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.46, 0.46)
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
		var texture := _load_texture(
			"%s/%s_%02d.png" % [base_dir, prefix, index]
		)
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
	var bar_width := 64.0
	var hp_ratio := clampf(float(current_hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var duration_ratio := clampf(duration_remaining / maxf(duration_total, 0.1), 0.0, 1.0)

	draw_rect(Rect2(-bar_width / 2.0, -70.0, bar_width, 5.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(-bar_width / 2.0, -70.0, bar_width * duration_ratio, 5.0), Color(1.0, 1.0, 1.0), true)
	draw_rect(Rect2(-bar_width / 2.0, -60.0, bar_width, 7.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(-bar_width / 2.0, -60.0, bar_width * hp_ratio, 7.0), Color(0.45, 0.82, 1.0), true)
