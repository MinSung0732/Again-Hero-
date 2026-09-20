extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)

@export var max_hp: int = 300
@export var move_speed: float = 230.0
@export var attack_damage: int = 34
@export var attack_range: float = 78.0
@export var attack_cooldown: float = 0.48

var current_hp: int
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 50

var target: Node2D
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var hit_flash_timer: float = 0.0
var level_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("hero")
	current_hp = max_hp
	exp_to_next_level = _required_exp_for_level(level)
	health_changed.emit(current_hp, max_hp)
	progression_changed.emit(level, current_exp, exp_to_next_level)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if not is_instance_valid(target) or target.is_queued_for_deletion() or retarget_timer <= 0.0:
		target = _find_nearest_monster()
		retarget_timer = 0.15

	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range:
		velocity = global_position.direction_to(target.global_position) * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			_attack_target()

func _find_nearest_monster() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := global_position.distance_squared_to(monster.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = monster

	return nearest

func _attack_target() -> void:
	if not is_instance_valid(target):
		return

	attack_timer = attack_cooldown
	if target.has_method("take_damage"):
		target.call("take_damage", attack_damage)

func gain_exp(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return

	current_exp += amount

	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		_level_up()

	progression_changed.emit(level, current_exp, exp_to_next_level)

func _level_up() -> void:
	level += 1
	exp_to_next_level = _required_exp_for_level(level)

	# Prototype-only growth. Later this will be replaced/expanded by AI augment choices.
	attack_damage += 3
	max_hp += 10
	current_hp = mini(current_hp + 10, max_hp)
	level_flash_timer = 0.45

	health_changed.emit(current_hp, max_hp)
	leveled_up.emit(level)
	queue_redraw()

func _required_exp_for_level(target_level: int) -> int:
	return 50 + maxi(target_level - 1, 0) * 25

func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	hit_flash_timer = 0.12
	health_changed.emit(current_hp, max_hp)
	queue_redraw()

	if current_hp <= 0:
		died.emit()
		queue_free()

func _draw() -> void:
	var body_color := Color(0.35, 0.68, 1.0)
	if hit_flash_timer > 0.0:
		body_color = Color(1.0, 1.0, 1.0)

	if level_flash_timer > 0.0:
		draw_circle(Vector2.ZERO, 54.0, Color(1.0, 0.86, 0.25, 0.35), false, 7.0)

	draw_circle(Vector2.ZERO, 34.0, body_color)
	draw_circle(Vector2(0, -4), 21.0, Color(0.82, 0.9, 1.0))
	draw_line(Vector2(22, 14), Vector2(52, -18), Color(0.95, 0.95, 1.0), 9.0)
	draw_line(Vector2(17, 10), Vector2(31, 24), Color(0.95, 0.75, 0.25), 7.0)

	var bar_width := 92.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width, 10.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width * hp_ratio, 10.0), Color(0.3, 0.9, 0.45), true)
