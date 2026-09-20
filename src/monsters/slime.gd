extends CharacterBody2D

signal died

@export var max_hp: int = 60
@export var move_speed: float = 115.0
@export var attack_damage: int = 9
@export var attack_range: float = 72.0
@export var attack_cooldown: float = 1.10
@export var exp_reward: int = 25

var current_hp: int
var hero: Node2D
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0:
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
	if current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	hit_flash_timer = 0.10
	queue_redraw()

	if current_hp <= 0:
		died.emit()
		queue_free()

func _draw() -> void:
	var body_color := Color(0.44, 0.92, 0.5)
	if hit_flash_timer > 0.0:
		body_color = Color(1.0, 1.0, 1.0)

	draw_circle(Vector2(0, 5), 29.0, body_color)
	draw_rect(Rect2(-29, 5, 58, 23), body_color, true)
	draw_circle(Vector2(-10, 0), 4.0, Color(0.08, 0.12, 0.1))
	draw_circle(Vector2(10, 0), 4.0, Color(0.08, 0.12, 0.1))

	var bar_width := 66.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -44.0, bar_width, 7.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(Rect2(-bar_width / 2.0, -44.0, bar_width * hp_ratio, 7.0), Color(0.95, 0.38, 0.32), true)
