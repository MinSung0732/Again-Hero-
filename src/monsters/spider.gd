extends CharacterBody2D

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const SPIDER_PROJECTILE_SCENE := preload("res://src/monsters/SpiderProjectile.tscn")

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
@export var exp_reward: int = 30
@export var slow_multiplier: float = 0.72
@export var slow_duration: float = 1.5

@onready var visual = get_node_or_null("Visual")
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
			_visual_call(&"play_locomotion", [false])
			return

	var direction_to_hero := global_position.direction_to(hero.global_position)
	_visual_call(&"set_facing_direction", [direction_to_hero.x])

	var distance := global_position.distance_to(hero.global_position)
	if distance > attack_range:
		velocity = direction_to_hero * move_speed
		_visual_call(&"play_locomotion", [true])
		move_and_slide()
		return

	velocity = Vector2.ZERO
	_visual_call(&"play_locomotion", [false])
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		_visual_call(&"play_attack")
		_fire_projectile(direction_to_hero)

func _fire_projectile(direction_to_hero: Vector2) -> void:
	if SPIDER_PROJECTILE_SCENE == null:
		return

	var projectile = SPIDER_PROJECTILE_SCENE.instantiate() as Area2D
	if projectile == null:
		return

	var projectile_parent := get_parent()
	if projectile_parent == null:
		return

	projectile_parent.add_child(projectile)
	projectile.global_position = global_position

	var is_elite := String(get_meta("visual_variant", "")) == "elite"
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			direction_to_hero,
			attack_damage,
			projectile_speed,
			projectile_range,
			slow_multiplier,
			slow_duration,
			is_elite
		)

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
