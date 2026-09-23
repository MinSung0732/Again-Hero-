extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "slime"
@export var monster_role: String = "swarm"
@export var max_hp: int = 60
@export var move_speed: float = 115.0
@export var attack_damage: int = 9
@export var attack_range: float = 72.0
@export var attack_cooldown: float = 1.10
@export var exp_reward: int = 25

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false
var visual_moving_state: int = -1
var visual_facing_sign: int = 0
var far_ai_tick_timer: float = 0.0
var cached_direction_to_hero: Vector2 = Vector2.ZERO
var visual_lod_suspended: bool = false
var special_augment_configs: Dictionary = {}
var pack_bonus_cache: Dictionary = {}
var pack_bonus_refresh_timer: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	add_to_group("slimes")
	pack_bonus_refresh_timer = randf_range(0.0, 0.25)
	far_ai_tick_timer = randf_range(0.0, 0.16)
	current_hp = max_hp
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	_attach_status_effect_visual("slow")
	queue_redraw()

func _attach_status_effect_visual(effect_type: String) -> void:
	var effect := COMBAT_STATUS_EFFECT_VISUAL.new()
	add_child(effect)
	effect.setup(self, effect_type)


func _physics_process(delta: float) -> void:
	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	pack_bonus_refresh_timer = maxf(pack_bonus_refresh_timer - delta, 0.0)
	if pack_bonus_refresh_timer <= 0.0:
		pack_bonus_refresh_timer = 0.25
		pack_bonus_cache = _get_pack_bonuses()
	var pack_bonuses := pack_bonus_cache
	var external_slow := 1.0
	if int(get_meta("gunner_slow_until", 0)) > Time.get_ticks_msec():
		external_slow = clampf(float(get_meta("gunner_slow_multiplier", 1.0)), 0.1, 1.0)
	if int(get_meta("archmage_root_until", 0)) > Time.get_ticks_msec():
		external_slow = 0.0
	var effective_move_speed := move_speed * float(
		pack_bonuses.get("move_speed_multiplier", 1.0)
	) * external_slow
	var effective_attack_cooldown := attack_cooldown / maxf(
		float(pack_bonuses.get("attack_speed_multiplier", 1.0)),
		0.01
	)

	if hit_flash_timer > 0.0:
		var previous_hit_flash := hit_flash_timer
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
			queue_redraw()

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
	var attack_range_sq := attack_range * attack_range
	far_ai_tick_timer = maxf(far_ai_tick_timer - delta, 0.0)

	if distance_sq > attack_range_sq:
		var direction_to_hero := cached_direction_to_hero
		if distance_sq <= far_nav_sq or far_ai_tick_timer <= 0.0:
			direction_to_hero = offset_to_hero.normalized()
			cached_direction_to_hero = direction_to_hero
			far_ai_tick_timer = randf_range(0.10, 0.16)

		velocity = direction_to_hero * effective_move_speed
		_update_visual_motion(direction_to_hero.x, true)
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
		velocity = Vector2.ZERO
		_update_visual_motion(direction_to_hero.x, false)
		if attack_timer <= 0.0:
			attack_timer = effective_attack_cooldown
			_visual_call(&"play_attack")
			if hero.has_method("take_damage"):
				hero.call("take_damage", attack_damage, self)

func _update_visual_lod(distance_sq: float) -> void:
	var should_suspend := (
		distance_sq > VISUAL_LOD_DISTANCE * VISUAL_LOD_DISTANCE
	)
	if should_suspend == visual_lod_suspended:
		return

	visual_lod_suspended = should_suspend
	set_meta("visual_lod_suspended", should_suspend)
	if is_instance_valid(visual) and visual.has_method("set_lod_suspended"):
		visual.call("set_lod_suspended", should_suspend)


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

func _get_pack_bonuses() -> Dictionary:
	var config: Dictionary = special_augment_configs.get(
		"slime_pack_instinct",
		{}
	)
	if config.is_empty():
		return {}

	var radius := maxf(float(config.get("radius", 0.0)), 0.0)
	var required_nearby := maxi(int(config.get("required_nearby", 0)), 0)
	if radius <= 0.0 or required_nearby <= 0:
		return {}

	var nearby := 0
	var candidates: Array = []
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("query_monsters_near")
	):
		var queried = battle.call(
			"query_monsters_near",
			global_position,
			radius
		)
		if queried is Array:
			candidates = queried
	if candidates.is_empty():
		candidates = get_tree().get_nodes_in_group("slimes")

	var radius_sq := radius * radius
	for node in candidates:
		if node == self or not is_instance_valid(node):
			continue
		if not node.is_in_group("slimes"):
			continue
		var other := node as Node2D
		if other == null:
			continue
		if global_position.distance_squared_to(other.global_position) <= radius_sq:
			nearby += 1
			if nearby >= required_nearby:
				return {
					"move_speed_multiplier": float(
						config.get("move_speed_multiplier", 1.0)
					),
					"attack_speed_multiplier": float(
						config.get("attack_speed_multiplier", 1.0)
					),
				}
	return {}

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
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

func _begin_death() -> void:
	if dying:
		return

	dying = true
	visual_lod_suspended = false
	set_meta("visual_lod_suspended", false)
	if is_instance_valid(visual) and visual.has_method("set_lod_suspended"):
		visual.call("set_lod_suspended", false)
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)

	died.emit()

	if (
		is_instance_valid(visual)
		and visual.has_signal("death_animation_finished")
		and visual.has_method("play_death")
	):
		visual.connect(
			"death_animation_finished",
			Callable(self, "_on_death_animation_finished"),
			Object.CONNECT_ONE_SHOT
		)
		visual.call("play_death")
	else:
		queue_free()

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

		if hit_flash_timer > 0.0:
			body_color = Color(1.0, 1.0, 1.0)

		draw_circle(Vector2(0, 5), 29.0, body_color)
		draw_rect(Rect2(-29, 5, 58, 23), body_color, true)
		draw_circle(Vector2(-10, 0), 4.0, Color(0.08, 0.12, 0.1))
		draw_circle(Vector2(10, 0), 4.0, Color(0.08, 0.12, 0.1))

	if dying:
		return

	var bar_width := 66.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(
		Rect2(-bar_width / 2.0, -44.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(
			-bar_width / 2.0,
			-44.0,
			bar_width * hp_ratio,
			7.0
		),
		Color(0.3, 0.9, 0.45),
		true
	)
