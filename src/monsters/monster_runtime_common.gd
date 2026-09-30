extends RefCounted
class_name MonsterRuntimeCommon

const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")

const TARGET_REFRESH_INTERVAL := 0.25
const FAR_NAV_INITIAL_MAX := 0.16
const FAR_NAV_TICK_MIN := 0.10
const FAR_NAV_TICK_MAX := 0.16


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
