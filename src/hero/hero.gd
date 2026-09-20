extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)

@export var max_hp: int = 300
@export var move_speed: float = 230.0
@export var attack_damage: int = 34
@export var attack_range: float = 78.0
@export var attack_cooldown: float = 0.48

var current_hp: int
var target: Node2D
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var hit_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("hero")
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
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

	# Hero body
	draw_circle(Vector2.ZERO, 34.0, body_color)
	draw_circle(Vector2(0, -4), 21.0, Color(0.82, 0.9, 1.0))
	# Sword
	draw_line(Vector2(22, 14), Vector2(52, -18), Color(0.95, 0.95, 1.0), 9.0)
	draw_line(Vector2(17, 10), Vector2(31, 24), Color(0.95, 0.75, 0.25), 7.0)

	# Local HP bar
	var bar_width := 92.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width, 10.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width * hp_ratio, 10.0), Color(0.3, 0.9, 0.45), true)
