extends CharacterBody2D

signal released(gatekeeper: Node2D)

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const PROJECTILE_SCENE := preload("res://src/hero/SummonerGatekeeperProjectile.tscn")
const FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect1"
const ATTACK_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_attack_pixabay.mp3"
const SUMMON_AUDIO_PATH := "res://assets/audio/sfx/summoner_gatekeeper_summon_pixabay.mp3"
const PROJECTILE_POOL_SIZE := 6

static var _frames_cache: SpriteFrames

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
var attack_range: float = 720.0
var attack_cooldown: float = 1.65
var projectile_speed: float = 560.0
var attack_timer: float = 0.0
var dying: bool = false
var consecutive_damage_bonus_per_step: float = 0.0
var consecutive_target_id: int = 0
var consecutive_target_steps: int = 0
var projectile_pool: Array[Node2D] = []


func _ready() -> void:
	_setup_visual()
	_load_optional_audio()
	deactivate(false)
	# Do not add projectile siblings to our parent while this node is still in
	# its own _ready() setup. Build the fixed pool on the deferred idle step.
	call_deferred("_build_projectile_pool")


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	global_position = world_position
	owner_hero = new_owner
	max_hp = maxi(int(config.get("max_hp", 650)), 1)
	current_hp = max_hp
	duration_total = maxf(float(config.get("duration", 60.0)), 0.1)
	duration_remaining = duration_total
	attack_damage = maxi(
		int(round(
			float(config.get("owner_attack_damage", 1))
			* float(config.get("damage_ratio", 0.70))
		)),
		1
	)
	attack_range = maxf(float(config.get("attack_range", 720.0)), 1.0)
	attack_cooldown = maxf(float(config.get("attack_cooldown", 1.65)), 0.05)
	projectile_speed = maxf(float(config.get("projectile_speed", 560.0)), 1.0)
	consecutive_damage_bonus_per_step = maxf(float(config.get("consecutive_damage_bonus_per_step", 0.0)), 0.0)
	consecutive_target_id = 0
	consecutive_target_steps = 0
	attack_timer = 0.55
	dying = false
	active = true
	visible = true
	collision_shape.set_deferred("disabled", false)
	if not is_in_group("hero_summons"):
		add_to_group("hero_summons")
	set_physics_process(true)
	visual.visible = true
	visual.speed_scale = 1.0
	visual.play(&"birth")
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
	if visual.animation == &"birth" and visual.is_playing():
		queue_redraw()
		return
	if (
		visual.animation == &"birth"
		and visual.sprite_frames != null
		and visual.sprite_frames.get_frame_count(&"birth") <= 0
	):
		visual.play(&"idle")
	if dying:
		return

	if attack_timer <= 0.0:
		var target := _find_nearest_target()
		if is_instance_valid(target):
			_fire_at(target)
			var speed_multiplier := 1.0
			if is_instance_valid(owner_hero) and owner_hero.has_method("get_summoner_runtime_speed_multipliers"):
				var multipliers: Dictionary = owner_hero.call("get_summoner_runtime_speed_multipliers")
				speed_multiplier = maxf(float(multipliers.get("attack_speed", 1.0)), 0.1)
			attack_timer = attack_cooldown / speed_multiplier
	queue_redraw()


func _find_nearest_target() -> Node2D:
	var battle := get_parent()
	if not is_instance_valid(battle):
		return null
	var candidates: Array = []
	if battle.has_method("query_monsters_near"):
		var result = battle.call("query_monsters_near", global_position, attack_range)
		if result is Array:
			candidates = result
	else:
		candidates = get_tree().get_nodes_in_group("monsters")

	var nearest: Node2D = null
	var nearest_distance_sq := attack_range * attack_range
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


func _fire_at(target: Node2D) -> void:
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"attack"):
		visual.play(&"attack")
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()

	var projectile := _acquire_projectile()
	if projectile == null:
		return
	var target_id := target.get_instance_id()
	if target_id == consecutive_target_id:
		consecutive_target_steps = mini(consecutive_target_steps + 1, 4)
	else:
		consecutive_target_id = target_id
		consecutive_target_steps = 1
	var bonus_steps := maxi(consecutive_target_steps - 1, 0)
	var shot_damage := maxi(int(round(float(attack_damage) * (1.0 + consecutive_damage_bonus_per_step * float(bonus_steps)))), 1)
	projectile.call(
		"activate",
		global_position + Vector2(0.0, -18.0),
		target,
		shot_damage,
		projectile_speed,
		attack_range + 80.0
	)


func _acquire_projectile() -> Node2D:
	for projectile in projectile_pool:
		if is_instance_valid(projectile) and bool(projectile.call("is_available")):
			return projectile
	return null


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
		if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"hit"):
			visual.play(&"hit")
		queue_redraw()
	return applied > 0


func _begin_release() -> void:
	if not active or dying:
		return
	dying = true
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
	current_hp = 0
	duration_remaining = 0.0
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
	if visual.animation == &"birth" or visual.animation == &"attack" or visual.animation == &"hit":
		visual.play(&"idle")
	elif visual.animation == &"death":
		deactivate()


func _setup_visual() -> void:
	if _frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		_add_sequence(frames, &"birth", "birth", 4, 9.0, false)
		_add_sequence(frames, &"idle", "idle", 5, 6.0, true)
		frames.add_animation(&"attack")
		frames.set_animation_speed(&"attack", 8.0)
		frames.set_animation_loop(&"attack", false)
		for file_name in ["atk_01.png", "atk_02.png", "atk+03.png"]:
			var texture := _load_texture("%s/%s" % [FRAME_DIR, file_name])
			if texture != null:
				frames.add_frame(&"attack", texture)
		_add_sequence(frames, &"hit", "hit", 2, 10.0, false)
		_add_sequence(frames, &"death", "dead", 4, 8.0, false)
		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.46, 0.46)
	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)


func _add_sequence(
	frames: SpriteFrames,
	animation: StringName,
	prefix: String,
	count: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for index in range(1, count + 1):
		var texture := _load_texture("%s/%s_%02d.png" % [FRAME_DIR, prefix, index])
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


func _load_optional_audio() -> void:
	if ResourceLoader.exists(ATTACK_AUDIO_PATH):
		var stream = load(ATTACK_AUDIO_PATH)
		if stream is AudioStream:
			attack_audio.stream = stream
	if ResourceLoader.exists(SUMMON_AUDIO_PATH):
		var stream = load(SUMMON_AUDIO_PATH)
		if stream is AudioStream:
			summon_audio.stream = stream


func _draw() -> void:
	if not active:
		return
	var bar_width := 78.0
	var hp_ratio := clampf(float(current_hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var duration_ratio := clampf(duration_remaining / maxf(duration_total, 0.1), 0.0, 1.0)

	# Duration gauge sits above the HP gauge and is intentionally white.
	draw_rect(Rect2(-bar_width / 2.0, -83.0, bar_width, 6.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(-bar_width / 2.0, -83.0, bar_width * duration_ratio, 6.0), Color(1.0, 1.0, 1.0), true)

	draw_rect(Rect2(-bar_width / 2.0, -72.0, bar_width, 8.0), Color(0.10, 0.10, 0.12), true)
	draw_rect(Rect2(-bar_width / 2.0, -72.0, bar_width * hp_ratio, 8.0), Color(0.45, 0.82, 1.0), true)
