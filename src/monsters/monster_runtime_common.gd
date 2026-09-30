extends RefCounted
class_name MonsterRuntimeCommon

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

const TARGET_REFRESH_INTERVAL := 0.25
const FAR_NAV_INITIAL_MAX := 0.16
const FAR_NAV_TICK_MIN := 0.10
const FAR_NAV_TICK_MAX := 0.16
const SOFT_SEPARATION_TICK_MIN := 0.10
const SOFT_SEPARATION_TICK_MAX := 0.14
const SOFT_SEPARATION_RADIUS_SCALE := 0.78
const SOFT_SEPARATION_RADIUS_MIN := 18.0
const SOFT_SEPARATION_RADIUS_MAX := 25.0
const SOFT_SEPARATION_STEER_WEIGHT := 0.26
const SOFT_SEPARATION_IDLE_SPEED_RATIO := 0.18
const SOFT_SEPARATION_IDLE_SPEED_MAX := 26.0

static var _soft_separation_scratch: Array = []


static func tick_countdown(timer: float, delta: float) -> float:
	return maxf(timer - delta, 0.0)


static func should_refresh_target(
	timer: float,
	current_target: Node2D
) -> bool:
	return timer <= 0.0 or not is_instance_valid(current_target)


static func resolve_combat_target(
	owner: Node2D,
	current_target: Node2D,
	combat_authority: Node
) -> Node2D:
	if (
		is_instance_valid(combat_authority)
		and combat_authority.has_method("get_nearest_hero_combat_target")
	):
		var candidate = combat_authority.call(
			"get_nearest_hero_combat_target",
			owner.global_position
		)
		if candidate is Node2D:
			return candidate as Node2D

	if is_instance_valid(current_target):
		return current_target

	var tree := owner.get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("hero") as Node2D


static func initial_far_navigation_delay() -> float:
	return randf_range(0.0, FAR_NAV_INITIAL_MAX)


static func next_far_navigation_delay() -> float:
	return randf_range(FAR_NAV_TICK_MIN, FAR_NAV_TICK_MAX)


static func should_refresh_far_navigation(
	distance_sq: float,
	far_nav_sq: float,
	timer: float
) -> bool:
	return distance_sq <= far_nav_sq or timer <= 0.0


static func initial_soft_separation_delay() -> float:
	return randf_range(0.0, SOFT_SEPARATION_TICK_MAX)


static func next_soft_separation_delay() -> float:
	return randf_range(
		SOFT_SEPARATION_TICK_MIN,
		SOFT_SEPARATION_TICK_MAX
	)


static func compute_soft_separation_bias(
	owner: CharacterBody2D,
	combat_authority: Node
) -> Vector2:
	if owner == null or not is_instance_valid(owner):
		return Vector2.ZERO
	if (
		not is_instance_valid(combat_authority)
		or not combat_authority.has_method("fill_monsters_near")
	):
		return Vector2.ZERO

	var separation_radius := SOFT_SEPARATION_RADIUS_MIN
	var collision := owner.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if is_instance_valid(collision):
		var shape := collision.shape
		if shape is CircleShape2D:
			separation_radius = clampf(
				(shape as CircleShape2D).radius
				* SOFT_SEPARATION_RADIUS_SCALE,
				SOFT_SEPARATION_RADIUS_MIN,
				SOFT_SEPARATION_RADIUS_MAX
			)
		elif shape is CapsuleShape2D:
			separation_radius = clampf(
				(shape as CapsuleShape2D).radius
				* SOFT_SEPARATION_RADIUS_SCALE,
				SOFT_SEPARATION_RADIUS_MIN,
				SOFT_SEPARATION_RADIUS_MAX
			)

	_soft_separation_scratch.clear()
	combat_authority.call(
		"fill_monsters_near",
		owner.global_position,
		separation_radius,
		_soft_separation_scratch
	)

	var bias := Vector2.ZERO
	var owner_id := owner.get_instance_id()
	var separation_radius_sq := separation_radius * separation_radius
	for raw_node in _soft_separation_scratch:
		if (
			not is_instance_valid(raw_node)
			or raw_node == owner
			or raw_node.is_queued_for_deletion()
		):
			continue
		var other := raw_node as Node2D
		if other == null:
			continue

		var offset := owner.global_position - other.global_position
		var distance_sq := offset.length_squared()
		if distance_sq >= separation_radius_sq:
			continue

		var away := Vector2.ZERO
		var distance := 0.0
		if distance_sq <= 0.01:
			away = _deterministic_overlap_direction(
				owner_id,
				other.get_instance_id()
			)
		else:
			distance = sqrt(distance_sq)
			away = offset / distance

		var pressure := 1.0 - clampf(
			distance / separation_radius,
			0.0,
			1.0
		)
		bias += away * pressure

	_soft_separation_scratch.clear()
	if bias.length_squared() <= 0.0001:
		return Vector2.ZERO
	return bias.normalized()


static func blend_soft_separation_direction(
	base_direction: Vector2,
	separation_bias: Vector2
) -> Vector2:
	if separation_bias.length_squared() <= 0.0001:
		return base_direction.normalized()

	var base := (
		base_direction.normalized()
		if base_direction.length_squared() > 0.0001
		else Vector2.ZERO
	)
	if base.length_squared() <= 0.0001:
		return separation_bias.normalized()

	var blended := (
		base
		+ separation_bias.normalized()
		* SOFT_SEPARATION_STEER_WEIGHT
	)
	if blended.length_squared() <= 0.0001:
		return base
	return blended.normalized()


static func get_soft_separation_idle_velocity(
	separation_bias: Vector2,
	move_speed: float
) -> Vector2:
	if separation_bias.length_squared() <= 0.0001:
		return Vector2.ZERO
	var idle_speed := minf(
		maxf(move_speed, 0.0)
		* SOFT_SEPARATION_IDLE_SPEED_RATIO,
		SOFT_SEPARATION_IDLE_SPEED_MAX
	)
	if idle_speed <= 0.01:
		return Vector2.ZERO
	return separation_bias.normalized() * idle_speed


static func _deterministic_overlap_direction(
	owner_id: int,
	other_id: int
) -> Vector2:
	var low_id := mini(owner_id, other_id)
	var high_id := maxi(owner_id, other_id)
	var mixed := (
		(low_id * 1103515245)
		^ (high_id * 12345)
	)
	var angle := (
		float(abs(mixed) % 6283)
		/ 1000.0
	)
	var direction := Vector2.from_angle(angle)
	return direction if owner_id <= other_id else -direction


static func apply_standard_visual_lod(
	owner: Node2D,
	visual: Node,
	currently_suspended: bool,
	distance_sq: float,
	lod_distance: float
) -> bool:
	var should_suspend := distance_sq > lod_distance * lod_distance
	if should_suspend == currently_suspended:
		return currently_suspended

	owner.set_meta("visual_lod_suspended", should_suspend)
	if (
		is_instance_valid(visual)
		and visual.has_method("set_lod_suspended")
	):
		visual.call("set_lod_suspended", should_suspend)
	return should_suspend


static func get_external_movement_multiplier(owner: Node) -> float:
	var now_msec := Time.get_ticks_msec()
	if int(owner.get_meta("archmage_root_until", 0)) > now_msec:
		return 0.0
	if int(owner.get_meta("sage_ice_root_until", 0)) > now_msec:
		return 0.0
	if is_forced_movement_locked(owner):
		return 0.0

	var multiplier := 1.0
	if int(owner.get_meta("gunner_slow_until", 0)) > now_msec:
		multiplier = minf(
			multiplier,
			clampf(
				float(owner.get_meta("gunner_slow_multiplier", 1.0)),
				0.1,
				1.0
			)
		)
	if int(owner.get_meta("movement_slow_until", 0)) > now_msec:
		multiplier = minf(
			multiplier,
			clampf(
				float(owner.get_meta("movement_slow_multiplier", 1.0)),
				0.1,
				1.0
			)
		)
	if int(owner.get_meta("sage_ice_slow_until", 0)) > now_msec:
		multiplier = minf(
			multiplier,
			clampf(
				float(owner.get_meta("sage_ice_slow_multiplier", 0.80)),
				0.1,
				1.0
			)
		)
	if int(owner.get_meta("sage_radiance_slow_until", 0)) > now_msec:
		multiplier = minf(
			multiplier,
			clampf(
				float(owner.get_meta("sage_radiance_slow_multiplier", 0.85)),
				0.1,
				1.0
			)
		)
	return multiplier


static func is_forced_movement_locked(owner: Node) -> bool:
	if owner == null or not is_instance_valid(owner):
		return false
	return int(owner.get_meta("forced_movement_lock_until", 0)) > Time.get_ticks_msec()


static func can_be_forced_moved(owner: Node) -> bool:
	if owner == null or not is_instance_valid(owner):
		return false
	if owner.has_method("is_forced_movement_immune"):
		if bool(owner.call("is_forced_movement_immune")):
			return false
	if bool(owner.get_meta("forced_movement_immune", false)):
		return false
	if bool(owner.get_meta("movement_effect_immune", false)):
		return false
	return true


static func can_receive_movement_slow(owner: Node) -> bool:
	if owner == null or not is_instance_valid(owner):
		return false
	if owner.has_method("is_movement_effect_immune"):
		if bool(owner.call("is_movement_effect_immune")):
			return false
	if bool(owner.get_meta("movement_effect_immune", false)):
		return false
	if bool(owner.get_meta("slow_immune", false)):
		return false
	return true


static func attach_status_effect_visual(
	owner: Node,
	effect_script: Script,
	effect_type: String
) -> void:
	if effect_script == null:
		return
	var effect := effect_script.new() as Node
	if effect == null:
		return
	owner.add_child(effect)
	if effect.has_method("setup"):
		effect.call("setup", owner, effect_type)



static func begin_standard_death(
	owner: CharacterBody2D,
	visual: Node,
	collision_shape: CollisionShape2D,
	finished_method: StringName = &"_on_death_animation_finished"
) -> bool:
	if owner == null or not is_instance_valid(owner):
		return false
	if bool(owner.get("dying")):
		return false

	owner.set("dying", true)
	owner.set("visual_lod_suspended", false)
	owner.set_meta("visual_lod_suspended", false)
	owner.velocity = Vector2.ZERO
	owner.set_physics_process(false)

	if (
		is_instance_valid(visual)
		and visual.has_method("set_lod_suspended")
	):
		visual.call("set_lod_suspended", false)

	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	owner.emit_signal("died")

	if (
		is_instance_valid(visual)
		and visual.has_signal("death_animation_finished")
		and visual.has_method("play_death")
	):
		var finished_callable := Callable(owner, finished_method)
		if not visual.is_connected(
			"death_animation_finished",
			finished_callable
		):
			visual.connect(
				"death_animation_finished",
				finished_callable,
				Object.CONNECT_ONE_SHOT
			)
		visual.call("play_death")
	else:
		owner.queue_free()

	return true



static func apply_direct_heal(
	owner: Node2D,
	amount: int,
	current_hp: int,
	max_hp: int,
	dying: bool
) -> int:
	if (
		amount <= 0
		or current_hp <= 0
		or dying
	):
		return 0

	var recovered := mini(
		amount,
		maxi(max_hp - current_hp, 0)
	)
	if recovered <= 0:
		return 0

	DAMAGE_NUMBERS.show_heal(owner, recovered)
	owner.queue_redraw()
	return recovered
