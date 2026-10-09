extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
const MONSTER_RUNTIME_COMMON := preload("res://src/monsters/monster_runtime_common.gd")

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const SPIDER_PROJECTILE_SCENE := preload("res://src/monsters/SpiderProjectile.tscn")
const SPIDER_PROJECTILE_POOL_KEY := "spider_projectile"

const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "spider"
@export var monster_role: String = "controller"
@export var max_hp: int = 45
@export var move_speed: float = 150.0
@export var attack_damage: int = 5
@export var attack_range: float = 300.0
@export var attack_cooldown: float = 1.35
@export var projectile_speed: float = 320.0
@export var projectile_range: float = 360.0
@export var projectile_size_multiplier: float = 1.0
@export var exp_reward: int = 30
@export var slow_multiplier: float = 0.72
@export var slow_duration: float = 1.5

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var combat_authority: Node
var hero_target_refresh_timer: float = 0.0
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false
var visual_moving_state: int = -1
var visual_facing_sign: int = 0
var far_ai_tick_timer: float = 0.0
var cached_direction_to_hero: Vector2 = Vector2.ZERO
var soft_separation_timer: float = 0.0
var soft_separation_bias: Vector2 = Vector2.ZERO
var visual_lod_suspended: bool = false
var special_augment_configs: Dictionary = {}

func _ready() -> void:
	add_to_group("monsters")
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = (
		MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	)
	current_hp = max_hp
	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	hero_target_refresh_timer = 0.0
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(
		self,
		COMBAT_STATUS_EFFECT_VISUAL,
		"slow"
	)
	queue_redraw()


func configure_combat_context(
	primary_hero: Node2D,
	authority: Node
) -> void:
	hero = primary_hero
	combat_authority = authority


func _refresh_combat_target() -> void:
	hero_target_refresh_timer = (
		MONSTER_RUNTIME_COMMON.TARGET_REFRESH_INTERVAL
	)
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	hero = MONSTER_RUNTIME_COMMON.resolve_combat_target(
		self,
		hero,
		combat_authority
	)





func _physics_process(delta: float) -> void:
	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		hero_target_refresh_timer,
		delta
	)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(
		hero_target_refresh_timer,
		hero
	):
		_refresh_combat_target()

	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		_update_visual_motion(0.0, false)
		return

	soft_separation_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		soft_separation_timer,
		delta
	)
	if soft_separation_timer <= 0.0:
		soft_separation_bias = (
			MONSTER_RUNTIME_COMMON.compute_soft_separation_bias(
				self,
				combat_authority
			)
		)
		soft_separation_timer = (
			MONSTER_RUNTIME_COMMON.next_soft_separation_delay()
		)

	attack_timer = maxf(attack_timer - delta, 0.0)

	if hit_flash_timer > 0.0:
		var previous_hit_flash := hit_flash_timer
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
			queue_redraw()

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
	var attack_range_sq := attack_range * attack_range
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		far_ai_tick_timer,
		delta
	)

	if distance_sq > attack_range_sq:
		var direction_to_hero := cached_direction_to_hero
		if MONSTER_RUNTIME_COMMON.should_refresh_far_navigation(
			distance_sq,
			far_nav_sq,
			far_ai_tick_timer
		):
			direction_to_hero = offset_to_hero.normalized()
			cached_direction_to_hero = direction_to_hero
			far_ai_tick_timer = MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
		var external_slow := (
			MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		)
		var move_direction := (
			MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
				direction_to_hero,
				soft_separation_bias
			)
		)
		velocity = move_direction * move_speed * external_slow
		_update_visual_motion(move_direction.x, true)
		if distance_sq > far_nav_sq:
			global_position += velocity * delta
		else:
			move_and_slide()
		return

	var direction_to_hero := (
		offset_to_hero.normalized()
		if distance_sq > 0.001
		else cached_direction_to_hero
	)
	cached_direction_to_hero = direction_to_hero
	var idle_external_slow := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	velocity = (
		MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
			soft_separation_bias,
			move_speed * idle_external_slow
		)
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		_visual_call(&"play_attack")
		_begin_projectile_attack(direction_to_hero)

func _update_visual_lod(distance_sq: float) -> void:
	visual_lod_suspended = (
		MONSTER_RUNTIME_COMMON.apply_standard_visual_lod(
			self,
			visual,
			visual_lod_suspended,
			distance_sq,
			VISUAL_LOD_DISTANCE
		)
	)


func _update_visual_motion(direction_x: float, moving: bool) -> void:
	var facing_sign := 0
	if direction_x > 0.01:
		facing_sign = 1
	elif direction_x < -0.01:
		facing_sign = -1

	if facing_sign != 0 and facing_sign != visual_facing_sign:
		visual_facing_sign = facing_sign
		_visual_call(&"set_facing_direction", [direction_x])

	var moving_state := 1 if moving else 0
	if moving_state != visual_moving_state:
		visual_moving_state = moving_state
		_visual_call(&"play_locomotion", [moving])


func configure_special_augments(configs: Dictionary) -> void:
	special_augment_configs = configs.duplicate(true)

func _begin_projectile_attack(direction_to_hero: Vector2) -> void:
	var triple: Dictionary = special_augment_configs.get(
		"spider_triple_web",
		{}
	)
	if triple.is_empty():
		_fire_projectile(direction_to_hero, 1.0)
		return

	var shot_count := maxi(int(triple.get("shot_count", 3)), 1)
	var damage_multiplier := maxf(
		float(triple.get("damage_multiplier", 1.0)),
		0.0
	)
	var spread_degrees := maxf(
		float(triple.get("spread_degrees", 18.0)),
		0.0
	)
	var spread_radians := deg_to_rad(spread_degrees)

	for shot_index in range(shot_count):
		var t := (
			0.5
			if shot_count <= 1
			else float(shot_index) / float(shot_count - 1)
		)
		var angle_offset := lerpf(
			-spread_radians,
			spread_radians,
			t
		)
		_fire_projectile(
			direction_to_hero.rotated(angle_offset),
			damage_multiplier
		)

func _acquire_spider_projectile() -> Area2D:
	var projectile_parent := get_parent()
	if not is_instance_valid(projectile_parent):
		return null

	if projectile_parent.has_method("acquire_projectile"):
		var pooled = projectile_parent.call(
			"acquire_projectile",
			SPIDER_PROJECTILE_SCENE,
			SPIDER_PROJECTILE_POOL_KEY
		)
		if pooled is Area2D:
			return pooled as Area2D

	# Fallback keeps the monster usable outside Battle test scenes.
	var projectile := SPIDER_PROJECTILE_SCENE.instantiate() as Area2D
	if projectile != null:
		projectile_parent.add_child(projectile)
	return projectile


func _fire_projectile(
	direction_to_hero: Vector2,
	damage_multiplier: float = 1.0
) -> void:
	if SPIDER_PROJECTILE_SCENE == null:
		return

	var projectile := _acquire_spider_projectile()
	if projectile == null:
		return

	projectile.set_meta("combat_source",weakref(self))
	projectile.global_position = global_position

	var sticky: Dictionary = special_augment_configs.get(
		"spider_sticky_web",
		{}
	)
	var projectile_slow_multiplier := slow_multiplier
	var projectile_slow_duration := slow_duration
	if not sticky.is_empty():
		projectile_slow_multiplier = clampf(
			projectile_slow_multiplier
			* float(sticky.get("slow_multiplier_factor", 1.0)),
			0.0,
			1.0
		)
		projectile_slow_duration *= float(
			sticky.get("duration_multiplier", 1.0)
		)

	var binding: Dictionary = special_augment_configs.get(
		"spider_binding",
		{}
	)
	var is_elite := String(get_meta("visual_variant", "")) == "elite"
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			direction_to_hero,
			maxi(int(round(float(attack_damage) * damage_multiplier)), 1),
			projectile_speed,
			projectile_range,
			projectile_slow_multiplier,
			projectile_slow_duration,
			is_elite,
			binding,
			projectile_size_multiplier
		)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	amount = MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)
	if amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10
	_visual_call(&"play_hit")
	queue_redraw()

	if current_hp <= 0:
		_begin_death()

func heal_direct(amount: int) -> int:
	var recovered := MONSTER_RUNTIME_COMMON.apply_direct_heal(
		self,
		amount,
		current_hp,
		max_hp,
		dying
	)
	current_hp += recovered
	return recovered

func _begin_death() -> void:
	MONSTER_RUNTIME_COMMON.begin_standard_death(
		self,
		visual,
		collision_shape
	)

func _on_death_animation_finished() -> void:
	queue_free()

func _visual_call(method_name: StringName, args: Array = []) -> void:
	if not is_instance_valid(visual):
		return
	if not visual.has_method(method_name):
		return
	visual.callv(method_name, args)

func _draw() -> void:
	var visual_ready := false
	if is_instance_valid(visual) and visual.has_method("is_visual_ready"):
		visual_ready = bool(visual.call("is_visual_ready"))

	if not visual_ready:
		var body_color := Color(0.72, 0.38, 0.92)
		if hit_flash_timer > 0.0:
			body_color = Color(1.0, 1.0, 1.0)

		for y_offset in [-10.0, 4.0, 18.0]:
			draw_line(Vector2(-18, y_offset), Vector2(-42, y_offset - 10), body_color, 5.0)
			draw_line(Vector2(18, y_offset), Vector2(42, y_offset - 10), body_color, 5.0)

		draw_circle(Vector2.ZERO, 23.0, body_color)
		draw_circle(Vector2(0, 18), 17.0, body_color)
		draw_circle(Vector2(-8, -5), 3.5, Color(0.95, 0.9, 1.0))
		draw_circle(Vector2(8, -5), 3.5, Color(0.95, 0.9, 1.0))

	if dying:
		return

	var bar_width := 62.0
	MONSTER_RUNTIME_COMMON.draw_support_shield_bar(self, bar_width, -43.0)
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(
		Rect2(-bar_width / 2.0, -43.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(
			-bar_width / 2.0,
			-43.0,
			bar_width * hp_ratio,
			7.0
		),
		Color(0.3, 0.9, 0.45),
		true
	)
