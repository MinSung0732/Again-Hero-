extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)
signal augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)

const AUGMENT_CATALOG := preload("res://src/data/hero_augment_catalog.gd")
const BUILD_AI := preload("res://src/ai/hero_build_ai.gd")

@export var max_hp: int = 300
@export var move_speed: float = 230.0
@export var attack_damage: int = 34
@export var attack_range: float = 78.0
@export var attack_cooldown: float = 0.48

var current_hp: int
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 50
var build_counts: Dictionary = {}

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
	level_flash_timer = 0.45

	var candidates: Array = AUGMENT_CATALOG.roll_candidates(3)
	var chosen: Dictionary = BUILD_AI.choose_candidate_v0(candidates)
	_apply_augment(chosen)

	health_changed.emit(current_hp, max_hp)
	leveled_up.emit(level)
	augment_selected.emit(
		level,
		candidates,
		String(chosen.get("name", "알 수 없는 증강")),
		String(chosen.get("decision_reason", "기본 판단")),
		get_build_summary()
	)
	queue_redraw()

func _apply_augment(augment: Dictionary) -> void:
	var augment_id: String = String(augment.get("id", ""))

	match augment_id:
		"sword_mastery":
			attack_damage += 8
		"rapid_strikes":
			attack_cooldown = maxf(attack_cooldown * 0.88, 0.18)
		"iron_body":
			max_hp += 45
			current_hp = mini(current_hp + 45, max_hp)
		"pursuit":
			move_speed += 25.0
		"long_reach":
			attack_range += 20.0
		"battle_recovery":
			current_hp = mini(current_hp + 90, max_hp)

	if not augment_id.is_empty():
		var current_stack: int = int(build_counts.get(augment_id, 0))
		build_counts[augment_id] = current_stack + 1

func get_build_summary() -> String:
	if build_counts.is_empty():
		return "아직 선택 없음"

	var parts: Array[String] = []
	for augment in AUGMENT_CATALOG.AUGMENTS:
		var augment_id: String = String(augment.get("id", ""))
		var stacks: int = int(build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue

		var label: String = String(augment.get("name", augment_id))
		if stacks > 1:
			label += " x%d" % stacks
		parts.append(label)

	return " · ".join(parts)

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
