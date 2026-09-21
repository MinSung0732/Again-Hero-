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

@onready var visual: AnimatedSprite2D = $Visual
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
	if is_instance_valid(visual):
		visual.animation_finished.connect(_on_visual_animation_finished)
		visual.play(&"idle")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if is_instance_valid(visual) and hit_flash_timer <= 0.0:
			visual.self_modulate = Color.WHITE
		queue_redraw()

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_play_locomotion(false)
			return

	var direction_to_hero := global_position.direction_to(hero.global_position)
	if is_instance_valid(visual) and absf(direction_to_hero.x) > 0.01:
		visual.flip_h = direction_to_hero.x < 0.0

	var distance := global_position.distance_to(hero.global_position)
	if distance > attack_range:
		velocity = direction_to_hero * move_speed
		_play_locomotion(true)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play_locomotion(false)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			if is_instance_valid(visual):
				visual.play(&"attack")
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

	if is_instance_valid(visual):
		visual.play(&"hit")

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

	if is_instance_valid(visual):
		visual.play(&"death")
	else:
		queue_free()

func _on_visual_animation_finished() -> void:
	if not is_instance_valid(visual):
		return

	if visual.animation == &"death":
		queue_free()
		return

	if visual.animation == &"attack" or visual.animation == &"hit":
		_play_locomotion(velocity.length_squared() > 1.0)

func _play_locomotion(moving: bool) -> void:
	if not is_instance_valid(visual):
		return
	if dying:
		return
	if visual.animation == &"attack" or visual.animation == &"hit":
		return

	var target: StringName = &"move" if moving else &"idle"
	if visual.animation != target or not visual.is_playing():
		visual.play(target)

func _trigger_death_explosion() -> void:
	if not is_instance_valid(hero):
		return
	if global_position.distance_to(hero.global_position) > explosion_radius:
		return
	if hero.has_method("take_damage"):
		hero.call("take_damage", explosion_damage)

func _draw() -> void:
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
