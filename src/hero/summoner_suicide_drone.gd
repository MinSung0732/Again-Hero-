extends Node2D

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

signal released(drone: Node2D)

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const SCOUT_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect2"
const GATEKEEPER_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect1"

static var _body_frames: SpriteFrames
static var _spawn_frames: SpriteFrames
static var _explosion_frames: SpriteFrames

@onready var visual: AnimatedSprite2D = $Visual
@onready var spawn_effect: AnimatedSprite2D = $SpawnEffect
@onready var explosion: AnimatedSprite2D = $Explosion

var active: bool = false
var owner_hero: Node2D = null
var target: Node2D = null
var current_hp: int = 100
var max_hp: int = 100
var attack_damage: int = 1
var attack_range: float = 100.0
var move_speed: float = 360.0
var sense_range: float = 1200.0
var lifetime_remaining: float = 12.0
var retarget_timer: float = 0.0
var exploding: bool = false


func _ready() -> void:
	_setup_frames()
	deactivate(false)


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	global_position = world_position
	owner_hero = new_owner
	max_hp = maxi(int(config.get("max_hp", 100)), 1)
	current_hp = max_hp
	var owner_attack_damage := maxi(
		int(config.get("owner_attack_damage", 0)),
		0
	)
	if owner_attack_damage <= 0 and is_instance_valid(new_owner):
		var raw_owner_attack_damage = new_owner.get("attack_damage")
		if raw_owner_attack_damage != null:
			owner_attack_damage = maxi(
				int(raw_owner_attack_damage),
				1
			)
	owner_attack_damage = maxi(owner_attack_damage, 1)
	attack_damage = maxi(
		int(round(
			float(owner_attack_damage)
			* maxf(float(config.get("damage_ratio", 0.30)), 0.0)
		)),
		1
	)
	attack_range = maxf(float(config.get("attack_range", 100.0)), 1.0)
	move_speed = maxf(float(config.get("move_speed", 360.0)), 1.0)
	sense_range = maxf(float(config.get("sense_range", 1200.0)), attack_range)
	lifetime_remaining = maxf(float(config.get("max_lifetime", 12.0)), 0.1)
	visual.scale = Vector2.ONE * maxf(float(config.get("visual_scale", 0.276)), 0.01)
	spawn_effect.scale = Vector2.ONE * maxf(float(config.get("spawn_effect_scale", 0.22)), 0.01)
	explosion.scale = Vector2.ONE * maxf(float(config.get("explosion_scale", 0.34)), 0.01)

	target = null
	retarget_timer = 0.0
	exploding = false
	active = true
	visible = true
	visual.visible = true
	spawn_effect.visible = true
	explosion.visible = false
	visual.play(&"move")
	spawn_effect.stop()
	spawn_effect.play(&"spawn")
	if not is_in_group("hero_summons"):
		add_to_group("hero_summons")
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not active or exploding:
		return

	lifetime_remaining = maxf(lifetime_remaining - delta, 0.0)
	if lifetime_remaining <= 0.0:
		deactivate()
		return

	retarget_timer = maxf(retarget_timer - delta, 0.0)
	if (
		not HERO_TARGET_POLICY.is_detectable(target)
		or retarget_timer <= 0.0
	):
		target = _find_nearest_target()
		retarget_timer = 0.08

	if not is_instance_valid(target):
		return

	var horizontal_delta := target.global_position.x - global_position.x
	if absf(horizontal_delta) > 1.0:
		visual.flip_h = horizontal_delta < 0.0

	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range:
		_explode_on_target()
		return

	global_position += (
		global_position.direction_to(target.global_position)
		* move_speed
		* delta
	)


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


func _explode_on_target() -> void:
	if exploding or not active:
		return
	exploding = true
	set_physics_process(false)

	if HERO_TARGET_POLICY.is_detectable(target):
		if target.has_method("take_damage"):
			target.call("take_damage", attack_damage)

	visual.visible = false
	spawn_effect.visible = false
	explosion.visible = true
	explosion.stop()
	explosion.play(&"explode")


func take_damage(amount: int, _source: Node = null) -> bool:
	if not active or exploding or amount <= 0:
		return false
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied := previous_hp - current_hp
	if applied > 0:
		DAMAGE_NUMBERS.show(self, applied)
	if current_hp <= 0:
		deactivate()
	return applied > 0


func deactivate(emit_signal: bool = true) -> void:
	var was_active := active
	active = false
	exploding = false
	owner_hero = null
	target = null
	current_hp = 0
	visible = false
	set_physics_process(false)
	if is_in_group("hero_summons"):
		remove_from_group("hero_summons")
	if is_instance_valid(visual):
		visual.stop()
	if is_instance_valid(spawn_effect):
		spawn_effect.stop()
	if is_instance_valid(explosion):
		explosion.stop()
	if emit_signal and was_active:
		released.emit(self)


func is_available() -> bool:
	return not active


func _on_explosion_finished() -> void:
	if explosion.animation == &"explode":
		deactivate()


func _on_spawn_effect_finished() -> void:
	if spawn_effect.animation == &"spawn":
		spawn_effect.visible = false


func _setup_frames() -> void:
	if _body_frames == null:
		_body_frames = SpriteFrames.new()
		if _body_frames.has_animation(&"default"):
			_body_frames.remove_animation(&"default")
		_body_frames.add_animation(&"move")
		_body_frames.set_animation_speed(&"move", 14.0)
		_body_frames.set_animation_loop(&"move", true)
		for index in range(1, 7):
			var texture := _load_texture("%s/move_%02d.png" % [SCOUT_FRAME_DIR, index])
			if texture != null:
				_body_frames.add_frame(&"move", texture)

	if _spawn_frames == null:
		_spawn_frames = SpriteFrames.new()
		if _spawn_frames.has_animation(&"default"):
			_spawn_frames.remove_animation(&"default")
		_spawn_frames.add_animation(&"spawn")
		_spawn_frames.set_animation_speed(&"spawn", 12.0)
		_spawn_frames.set_animation_loop(&"spawn", false)
		for index in range(1, 3):
			var texture := _load_texture("%s/summon_%02d.png" % [SCOUT_FRAME_DIR, index])
			if texture != null:
				_spawn_frames.add_frame(&"spawn", texture)

	if _explosion_frames == null:
		_explosion_frames = SpriteFrames.new()
		if _explosion_frames.has_animation(&"default"):
			_explosion_frames.remove_animation(&"default")
		_explosion_frames.add_animation(&"explode")
		_explosion_frames.set_animation_speed(&"explode", 14.0)
		_explosion_frames.set_animation_loop(&"explode", false)
		for path in [
			"%s/dead_03.png" % GATEKEEPER_FRAME_DIR,
			"%s/dead_04.png" % GATEKEEPER_FRAME_DIR,
			"%s/projectile_02.png" % GATEKEEPER_FRAME_DIR,
		]:
			var texture := _load_texture(path)
			if texture != null:
				_explosion_frames.add_frame(&"explode", texture)

	visual.sprite_frames = _body_frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.position = Vector2(0.0, -20.0)

	spawn_effect.sprite_frames = _spawn_frames
	spawn_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spawn_effect.position = Vector2(0.0, -18.0)
	if not spawn_effect.animation_finished.is_connected(_on_spawn_effect_finished):
		spawn_effect.animation_finished.connect(_on_spawn_effect_finished)

	explosion.sprite_frames = _explosion_frames
	explosion.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	explosion.position = Vector2(0.0, -16.0)
	if not explosion.animation_finished.is_connected(_on_explosion_finished):
		explosion.animation_finished.connect(_on_explosion_finished)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	return null
