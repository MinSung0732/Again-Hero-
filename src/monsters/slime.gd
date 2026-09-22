extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

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
var special_augment_configs: Dictionary = {}

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
	var pack_bonuses := _get_pack_bonuses()
	var external_slow := 1.0
	if int(get_meta("gunner_slow_until", 0)) > Time.get_ticks_msec():
		external_slow = clampf(float(get_meta("gunner_slow_multiplier", 1.0)), 0.1, 1.0)
	var effective_move_speed := move_speed * float(
		pack_bonuses.get("move_speed_multiplier", 1.0)
	) * external_slow
	var effective_attack_cooldown := attack_cooldown / maxf(
		float(pack_bonuses.get("attack_speed_multiplier", 1.0)),
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
	for node in get_tree().get_nodes_in_group("monsters"):
		if node == self or not is_instance_valid(node):
			continue
		if String(node.get("monster_type")) != "slime":
			continue
		var other := node as Node2D
		if other == null:
			continue
		if global_position.distance_to(other.global_position) <= radius:
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
