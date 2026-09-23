extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

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
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false
var special_augment_configs: Dictionary = {}
var rage_stacks: int = 0
var last_charge_triggered: bool = false
var last_charge_timer: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	last_charge_timer = maxf(last_charge_timer - delta, 0.0)

	var combat_bonuses := _get_combat_bonuses()
	var external_slow := 1.0
	if int(get_meta("gunner_slow_until", 0)) > Time.get_ticks_msec():
		external_slow = clampf(float(get_meta("gunner_slow_multiplier", 1.0)), 0.1, 1.0)
	if int(get_meta("archmage_root_until", 0)) > Time.get_ticks_msec():
		external_slow = 0.0
	var effective_move_speed := move_speed * float(
		combat_bonuses.get("move_speed_multiplier", 1.0)
	) * external_slow
	var effective_attack_cooldown := attack_cooldown / maxf(
		float(combat_bonuses.get("attack_speed_multiplier", 1.0)),
		0.01
	)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_visual_call(&"play_locomotion", [false])
			return

	var direction_to_hero := global_position.direction_to(hero.global_position)
	_visual_call(&"set_facing_direction", [direction_to_hero.x])

	var distance := global_position.distance_to(hero.global_position)
	if distance > attack_range:
		velocity = direction_to_hero * effective_move_speed
		_visual_call(&"play_locomotion", [true])
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_visual_call(&"play_locomotion", [false])
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
	}

func _begin_death() -> void:
	if dying:
		return

	dying = true
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
