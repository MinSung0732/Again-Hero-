extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

signal died

@export var monster_type: String = "spider"
@export var monster_role: String = "controller"
@export var max_hp: int = 45
@export var move_speed: float = 150.0
@export var attack_damage: int = 5
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 1.15
@export var exp_reward: int = 30
@export var slow_multiplier: float = 0.72
@export var slow_duration: float = 1.5

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
			var damage_applied := false
			if hero.has_method("take_damage"):
				damage_applied = bool(hero.call("take_damage", attack_damage))
			if damage_applied and hero.has_method("apply_slow"):
				hero.call("apply_slow", slow_multiplier, slow_duration)

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10
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
		body_color = Color(0.72, 0.38, 0.92)
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
		Color(0.95, 0.38, 0.32),
		true
	)
