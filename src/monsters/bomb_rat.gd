extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

signal died

@export var monster_type: String = "bomb_rat"
@export var monster_role: String = "burst"
@export var max_hp: int = 36
@export var move_speed: float = 145.0
@export var attack_damage: int = 6
@export var attack_range: float = 64.0
@export var attack_cooldown: float = 0.95
@export var exp_reward: int = 32
@export var explosion_radius: float = 150.0
@export var explosion_damage: int = 28

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
			return

	var distance := global_position.distance_to(hero.global_position)
	if distance > attack_range:
		velocity = global_position.direction_to(hero.global_position) * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if hero.has_method("take_damage"):
				hero.call("take_damage", attack_damage)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10
	queue_redraw()

	if current_hp <= 0:
		_begin_death()

func _begin_death() -> void:
	if dying:
		return

	dying = true
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)

	_trigger_death_explosion()
	died.emit()
	queue_free()

func _trigger_death_explosion() -> void:
	if not is_instance_valid(hero):
		return
	if global_position.distance_to(hero.global_position) > explosion_radius:
		return
	if hero.has_method("take_damage"):
		hero.call("take_damage", explosion_damage)

func _draw() -> void:
	var body_color := Color(0.54, 0.43, 0.34)
	if hit_flash_timer > 0.0:
		body_color = Color.WHITE

	draw_circle(Vector2(-3, 3), 22.0, body_color)
	draw_circle(Vector2(17, -2), 14.0, body_color)
	draw_circle(Vector2(22, -6), 3.0, Color(0.9, 0.35, 0.25))
	draw_line(Vector2(-24, 6), Vector2(-40, 16), body_color, 5.0)

	draw_circle(Vector2(-7, -18), 12.0, Color(0.16, 0.16, 0.18))
	draw_line(
		Vector2(-7, -30),
		Vector2(3, -42),
		Color(0.92, 0.62, 0.22),
		4.0
	)
	draw_circle(Vector2(5, -44), 4.0, Color(1.0, 0.4, 0.16))

	if dying:
		return

	var bar_width := 58.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -48.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -48.0, bar_width * hp_ratio, 7.0),
		Color(0.95, 0.38, 0.32),
		true
	)
