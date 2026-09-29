extends RefCounted
class_name HeroFighterRuntime


static func get_charge_trigger(config: Dictionary) -> Vector2:
	return Vector2(
		maxf(float(config.get("trigger_radius", 245.0)), 1.0),
		float(maxi(int(config.get("trigger_enemy_count", 4)), 1))
	)


static func get_charge_max_target_distance(config: Dictionary) -> float:
	return maxf(
		float(config.get("max_target_distance", 560.0)),
		1.0
	)


static func get_slash_trigger(
	config: Dictionary,
	half_width_bonus: float
) -> Vector2:
	return Vector2(
		maxf(
			float(config.get("slash_reach", 135.0))
			+ half_width_bonus,
			1.0
		),
		float(maxi(int(config.get("slash_enemy_trigger", 2)), 1))
	)


static func get_guard_trigger(config: Dictionary) -> Vector2:
	return Vector2(
		maxf(
			float(config.get("activation_enemy_radius", 320.0)),
			1.0
		),
		float(maxi(int(config.get("activation_enemy_count", 1)), 1))
	)


static func find_farthest_charge_target(
	candidates: Array,
	origin: Vector2,
	max_distance: float,
	exclude: Node = null
) -> Node2D:
	var max_distance_sq := max_distance * max_distance
	var farthest: Node2D = null
	var farthest_distance_sq := -1.0
	for node in candidates:
		if (
			not is_instance_valid(node)
			or node.is_queued_for_deletion()
			or node == exclude
		):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := origin.distance_squared_to(
			monster.global_position
		)
		if (
			distance_sq <= max_distance_sq
			and distance_sq > farthest_distance_sq
		):
			farthest = monster
			farthest_distance_sq = distance_sq
	return farthest
