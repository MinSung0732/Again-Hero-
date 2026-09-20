extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)
signal augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)

const AUGMENT_CATALOG := preload("res://src/data/hero_augment_catalog.gd")
const BUILD_AI := preload("res://src/ai/hero_build_ai.gd")
const PROJECTILE_SCENE := preload("res://src/hero/HeroProjectile.tscn")

const APPROACH_DISTANCE_RATIO := 0.86
const FIELD_WIDTH := 1080.0
const FIELD_HEIGHT := 1280.0
const FIELD_MARGIN := 72.0
const WANDER_REACHED_DISTANCE := 42.0
const WANDER_MIN_TARGET_DISTANCE := 260.0

@export var max_hp: int = 300
@export var move_speed: float = 230.0
@export var attack_damage: int = 34
@export var attack_range: float = 430.0
@export var attack_cooldown: float = 0.62
@export var projectile_speed: float = 680.0
@export var exp_pickup_radius: float = 150.0
@export var ai_sense_radius: float = 420.0
@export var kite_distance: float = 210.0

var hero_id: String = "ranged_rookie"
var hero_display_name: String = "견습 마도사"
var hero_archetype: String = "ranged_kiter"

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
var slow_timer: float = 0.0
var move_multiplier: float = 1.0
var strafe_sign: float = 1.0
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

func configure_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return

	hero_id = String(profile.get("id", hero_id))
	hero_display_name = String(profile.get("display_name", hero_display_name))
	hero_archetype = String(profile.get("archetype", hero_archetype))

	max_hp = int(profile.get("max_hp", max_hp))
	move_speed = float(profile.get("move_speed", move_speed))
	attack_damage = int(profile.get("attack_damage", attack_damage))
	attack_range = float(profile.get("attack_range", attack_range))
	attack_cooldown = float(profile.get("attack_cooldown", attack_cooldown))
	projectile_speed = float(profile.get("projectile_speed", projectile_speed))
	exp_pickup_radius = float(profile.get("exp_pickup_radius", exp_pickup_radius))
	ai_sense_radius = float(profile.get("ai_sense_radius", ai_sense_radius))
	kite_distance = float(profile.get("kite_distance", kite_distance))

func _ready() -> void:
	add_to_group("hero")
	current_hp = max_hp
	exp_to_next_level = _required_exp_for_level(level)
	strafe_sign = -1.0 if randf() < 0.5 else 1.0
	_pick_new_wander_target()
	health_changed.emit(current_hp, max_hp)
	progression_changed.emit(level, current_exp, exp_to_next_level)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if not is_instance_valid(target) or target.is_queued_for_deletion() or retarget_timer <= 0.0:
		target = _find_nearest_monster()
		retarget_timer = 0.12

	if not is_instance_valid(target):
		_move_without_monsters()
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_move_direction(target, distance)
	velocity = move_direction * move_speed * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

	if distance <= attack_range and attack_timer <= 0.0:
		_fire_projectile(target)

func _move_without_monsters() -> void:
	if wander_timer <= 0.0 or position.distance_to(wander_target) <= WANDER_REACHED_DISTANCE:
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	velocity = direction * move_speed * 0.72 * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

func _pick_new_wander_target() -> void:
	var candidate := Vector2(FIELD_WIDTH * 0.5, FIELD_HEIGHT * 0.5)

	for _attempt in range(6):
		candidate = Vector2(
			randf_range(FIELD_MARGIN, FIELD_WIDTH - FIELD_MARGIN),
			randf_range(FIELD_MARGIN, FIELD_HEIGHT - FIELD_MARGIN)
		)
		if position.distance_to(candidate) >= WANDER_MIN_TARGET_DISTANCE:
			break

	wander_target = candidate
	wander_timer = randf_range(2.6, 5.0)

func _choose_move_direction(nearest_target: Node2D, nearest_distance: float) -> Vector2:
	var avoidance := Vector2.ZERO

	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var monster := node as Node2D
		if monster == null:
			continue

		var distance := global_position.distance_to(monster.global_position)
		if distance <= 0.0 or distance > kite_distance:
			continue

		var weight := 1.0 - clampf(distance / kite_distance, 0.0, 1.0)
		avoidance += monster.global_position.direction_to(global_position) * (0.35 + weight)

	if avoidance.length_squared() > 0.01:
		return avoidance.normalized()

	if nearest_distance > attack_range * APPROACH_DISTANCE_RATIO:
		return global_position.direction_to(nearest_target.global_position)

	var to_target := global_position.direction_to(nearest_target.global_position)
	var tangent := Vector2(-to_target.y, to_target.x) * strafe_sign
	return tangent.normalized()

func _clamp_to_battlefield() -> void:
	var clamped_position := position
	var hit_edge := false

	if clamped_position.x < FIELD_MARGIN or clamped_position.x > FIELD_WIDTH - FIELD_MARGIN:
		hit_edge = true
	if clamped_position.y < FIELD_MARGIN or clamped_position.y > FIELD_HEIGHT - FIELD_MARGIN:
		hit_edge = true

	clamped_position.x = clampf(clamped_position.x, FIELD_MARGIN, FIELD_WIDTH - FIELD_MARGIN)
	clamped_position.y = clampf(clamped_position.y, FIELD_MARGIN, FIELD_HEIGHT - FIELD_MARGIN)
	position = clamped_position

	if hit_edge:
		strafe_sign *= -1.0

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

func _fire_projectile(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	attack_timer = attack_cooldown

	var projectile := PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + shot_direction * 46.0
	projectile.call("setup", shot_direction, attack_damage, projectile_speed, attack_range)

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
	var ai_context: Dictionary = _build_ai_context()
	var chosen: Dictionary = BUILD_AI.choose_candidate(candidates, ai_context, build_counts)
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

func _build_ai_context() -> Dictionary:
	var nearby_count: int = 0
	var total_count: int = 0
	var nearest_distance: float = 9999.0
	var type_counts: Dictionary = {
		"slime": 0,
		"spider": 0,
		"orc": 0,
	}
	var role_counts: Dictionary = {
		"swarm": 0,
		"controller": 0,
		"tank": 0,
	}

	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var monster := node as Node2D
		if monster == null:
			continue

		var monster_hp = monster.get("current_hp")
		if monster_hp != null and int(monster_hp) <= 0:
			continue

		total_count += 1
		var distance: float = global_position.distance_to(monster.global_position)
		nearest_distance = minf(nearest_distance, distance)

		if distance <= ai_sense_radius:
			nearby_count += 1

		var type_value = monster.get("monster_type")
		if type_value != null:
			var monster_type: String = String(type_value)
			type_counts[monster_type] = int(type_counts.get(monster_type, 0)) + 1

		var role_value = monster.get("monster_role")
		if role_value != null:
			var monster_role: String = String(role_value)
			role_counts[monster_role] = int(role_counts.get(monster_role, 0)) + 1

	if total_count == 0:
		nearest_distance = 0.0

	return {
		"nearby_count": nearby_count,
		"total_count": total_count,
		"nearest_distance": nearest_distance,
		"hp_ratio": float(current_hp) / float(maxi(max_hp, 1)),
		"level": level,
		"type_counts": type_counts,
		"role_counts": role_counts,
	}

func _apply_augment(augment: Dictionary) -> void:
	var augment_id: String = String(augment.get("id", ""))

	match augment_id:
		"projectile_power":
			attack_damage += 8
		"rapid_strikes":
			attack_cooldown = maxf(attack_cooldown * 0.88, 0.18)
		"iron_body":
			max_hp += 45
			current_hp = mini(current_hp + 45, max_hp)
		"pursuit":
			move_speed += 25.0
		"long_reach":
			attack_range += 35.0
		"battle_recovery":
			current_hp = mini(current_hp + 90, max_hp)

	if not augment_id.is_empty():
		var current_stack: int = int(build_counts.get(augment_id, 0))
		build_counts[augment_id] = current_stack + 1

func apply_slow(multiplier: float, duration: float) -> void:
	if current_hp <= 0:
		return

	move_multiplier = minf(move_multiplier, clampf(multiplier, 0.30, 1.0))
	slow_timer = maxf(slow_timer, duration)
	queue_redraw()

func get_build_summary() -> String:
	if build_counts.is_empty():
		return "아직 선택 없음"

	var parts: PackedStringArray = []
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

	if slow_timer > 0.0:
		draw_circle(Vector2.ZERO, 46.0, Color(0.72, 0.38, 0.92, 0.75), false, 4.0)

	draw_circle(Vector2.ZERO, 34.0, body_color)
	draw_circle(Vector2(0, -4), 21.0, Color(0.82, 0.9, 1.0))

	# Ranged prototype weapon: small staff + glowing focus.
	draw_line(Vector2(22, 13), Vector2(44, -12), Color(0.82, 0.72, 0.48), 7.0)
	draw_circle(Vector2(49, -17), 8.0, Color(0.95, 0.86, 0.32))

	var bar_width := 92.0
	var hp_ratio := float(current_hp) / float(max_hp)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width, 10.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width * hp_ratio, 10.0), Color(0.3, 0.9, 0.45), true)
