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

@onready var visual: MonsterVisual = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false

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

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			visual.play_locomotion(false)
			return

	var direction_to_hero := global_position.direction_to(hero.global_position)
	visual.set_facing_direction(direction_to_hero.x)

	var distance := global_position.distance_to(hero.global_position)
	if distance > attack_range:
		velocity = direction_to_hero * move_speed
		visual.play_locomotion(true)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		visual.play_locomotion(false)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			visual.play_attack()
			if hero.has_method("take_damage"):
				hero.call("take_damage", attack_damage)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.12
	visual.play_hit()
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

	if is_instance_valid(visual):
		visual.death_animation_finished.connect(
			_on_death_animation_finished,
			CONNECT_ONE_SHOT
		)
		visual.play_death()
	else:
		queue_free()

func _on_death_animation_finished() -> void:
	queue_free()

func _draw() -> void:
	var visual_ready := (
		is_instance_valid(visual)
		and visual.is_visual_ready()
	)

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
		Color(0.95, 0.38, 0.32),
		true
	)
