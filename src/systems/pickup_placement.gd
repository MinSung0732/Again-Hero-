extends RefCounted
# Item coordinates are local to Battle, just like the hero movement rectangle.
# Keep the castle wall/hero clearance in one authority; no item-specific Y value.
static func clamp_local(battle: Node, point: Vector2) -> Vector2:
	if not is_instance_valid(battle) or battle.get("hero_player_mode") != true:
		return point
	var hero := battle.get("hero") as Node2D
	if not is_instance_valid(hero) or not hero.has_method("_get_battlefield_movement_bounds"):
		return point
	var bounds: Rect2 = hero.call("_get_battlefield_movement_bounds")
	return point.clamp(bounds.position, bounds.end)


static func ensure_reachable(item: Node2D) -> void:
	item.position = clamp_local(item.get_parent(), item.position)
