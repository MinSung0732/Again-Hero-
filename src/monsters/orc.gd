extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
const MONSTER_RUNTIME_COMMON := preload("res://src/monsters/monster_runtime_common.gd")

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "orc"
@export var monster_role: String = "tank"
@export var max_hp: int = 140
@export var move_speed: float = 78.0
@export var attack_damage: int = 18
@export var attack_range: float = 82.0
@export var attack_cooldown: float = 1.45
@export var exp_reward: int = 40

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
var combat_bonus_refresh_timer: float = 0.0
var combat_bonus_cache: Dictionary = {}
var cached_berserk_visual_active: bool = false
var special_augment_configs: Dictionary = {}
var rage_stacks: int = 0
var last_charge_triggered: bool = false
var last_charge_timer: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = (
		MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	)
	combat_bonus_refresh_timer = randf_range(0.0, 0.10)
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
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(
		self,
		COMBAT_STATUS_EFFECT_VISUAL,
		"orc_rage"
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
	last_charge_timer = maxf(last_charge_timer - delta, 0.0)

	combat_bonus_refresh_timer = maxf(combat_bonus_refresh_timer - delta, 0.0)
	if combat_bonus_refresh_timer <= 0.0 or combat_bonus_cache.is_empty():
		combat_bonus_refresh_timer = 0.10
		combat_bonus_cache = _get_combat_bonuses()
		var berserk_active := bool(
			combat_bonus_cache.get("berserk_active", false)
		)
		if berserk_active != cached_berserk_visual_active:
			cached_berserk_visual_active = berserk_active
			set_meta("orc_berserk_visual_active", berserk_active)
	var combat_bonuses := combat_bonus_cache
	var external_slow := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	var effective_move_speed := move_speed * float(
		combat_bonuses.get("move_speed_multiplier", 1.0)
	) * external_slow
	var effective_attack_cooldown := attack_cooldown / maxf(
		float(combat_bonuses.get("attack_speed_multiplier", 1.0)),
		0.01
	)

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
		var move_direction := (
			MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
				direction_to_hero,
				soft_separation_bias
			)
		)
		velocity = move_direction * effective_move_speed
		_update_visual_motion(move_direction.x, true)
		if distance_sq > far_nav_sq:
			global_position += velocity * delta
		else:
			move_and_slide()
	else:
		var direction_to_hero := (
			offset_to_hero.normalized()
			if distance_sq > 0.001
			else cached_direction_to_hero
		)
		cached_direction_to_hero = direction_to_hero
		velocity = (
			MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
				soft_separation_bias,
				effective_move_speed
			)
		)
		if velocity.length_squared() > 0.01:
			move_and_slide()
		_update_visual_motion(direction_to_hero.x, false)
		if attack_timer <= 0.0:
			attack_timer = effective_attack_cooldown
			_visual_call(&"play_attack")
			if hero.has_method("take_damage"):
				hero.call("take_damage", attack_damage, self)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	_add_rage_stack()
	_try_trigger_last_charge()
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.12
	_visual_call(&"play_hit")
	queue_redraw()

	if current_hp <= 0:
		_begin_death()

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

func _add_rage_stack() -> void:
	var config: Dictionary = special_augment_configs.get(
		"orc_rage_stacks",
		{}
	)
	if config.is_empty():
		return
	rage_stacks = mini(
		rage_stacks + 1,
		maxi(int(config.get("max_stacks", 0)), 0)
	)

func _try_trigger_last_charge() -> void:
	if last_charge_triggered or current_hp <= 0:
		return
	var config: Dictionary = special_augment_configs.get(
		"orc_last_charge",
		{}
	)
	if config.is_empty():
		return
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	if hp_ratio > float(config.get("hp_ratio", 0.30)):
		return
	last_charge_triggered = true
	last_charge_timer = maxf(float(config.get("duration", 0.75)), 0.0)

func _get_combat_bonuses() -> Dictionary:
	var move_multiplier := 1.0
	var attack_speed_multiplier := 1.0

	var berserk: Dictionary = special_augment_configs.get(
		"orc_berserk",
		{}
	)
	if not berserk.is_empty():
		var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
		if hp_ratio <= float(berserk.get("hp_ratio", 0.50)):
			move_multiplier *= float(
				berserk.get("move_speed_multiplier", 1.0)
			)
			attack_speed_multiplier *= float(
				berserk.get("attack_speed_multiplier", 1.0)
			)

	var rage: Dictionary = special_augment_configs.get(
		"orc_rage_stacks",
		{}
	)
	if not rage.is_empty() and rage_stacks > 0:
		attack_speed_multiplier *= (
			1.0
			+ float(rage.get("attack_speed_per_stack", 0.0))
			* float(rage_stacks)
		)

	var charge: Dictionary = special_augment_configs.get(
		"orc_last_charge",
		{}
	)
	if last_charge_timer > 0.0 and not charge.is_empty():
		move_multiplier *= float(
			charge.get("speed_multiplier", 1.0)
		)

	return {
		"move_speed_multiplier": move_multiplier,
		"attack_speed_multiplier": attack_speed_multiplier,
		"berserk_active": (
			not berserk.is_empty()
			and float(current_hp) / float(maxi(max_hp, 1))
			<= float(berserk.get("hp_ratio", 0.50))
		),
	}

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
		var body_color := Color(0.44, 0.92, 0.5)
		body_color = Color(0.68, 0.48, 0.22)
		if hit_flash_timer > 0.0:
			body_color = Color(1.0, 1.0, 1.0)

		draw_circle(Vector2.ZERO, 39.0, body_color)
		draw_rect(Rect2(-34, 5, 68, 38), body_color, true)
		draw_circle(Vector2(-13, -7), 5.0, Color(0.95, 0.85, 0.42))
		draw_circle(Vector2(13, -7), 5.0, Color(0.95, 0.85, 0.42))
		draw_line(Vector2(-22, -28), Vector2(-35, -45), Color(0.92, 0.9, 0.75), 6.0)
		draw_line(Vector2(22, -28), Vector2(35, -45), Color(0.92, 0.9, 0.75), 6.0)

	if dying:
		return

	var bar_width := 86.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(
		Rect2(-bar_width / 2.0, -59.0, bar_width, 8.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(
			-bar_width / 2.0,
			-59.0,
			bar_width * hp_ratio,
			8.0
		),
		Color(0.3, 0.9, 0.45),
		true
	)
