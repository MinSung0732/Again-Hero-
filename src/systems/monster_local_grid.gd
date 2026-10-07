extends RefCounted

const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const CELL_SIZE := 32.0
var buckets: Dictionary = {}
var used_cells: Array[Vector2i] = []
var revision := -1
var motion_padding := 1


func clear() -> void:
	buckets.clear()
	used_cells.clear()
	revision = -1


func cell_for(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))


func ensure(actors: Dictionary, snapshot_revision: int) -> void:
	if revision == snapshot_revision:
		return
	for cell in used_cells:
		buckets[cell].clear()
	used_cells.clear()
	motion_padding = 1
	for id in actors:
		var actor = actors[id]
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or int(actor.get("current_hp")) <= 0:
			continue
		var cell := cell_for(actor.global_position)
		if actor is CharacterBody2D:
			motion_padding = maxi(motion_padding, ceili(actor.velocity.length() / Engine.physics_ticks_per_second / CELL_SIZE))
		if not buckets.has(cell):
			buckets[cell] = []
		var bucket: Array = buckets[cell]
		if bucket.is_empty():
			used_cells.append(cell)
		bucket.append(actor)
	revision = snapshot_revision


func separation_bias(owner: Node2D, radius: float) -> Vector2:
	# One local cell covers ordinary motion between queries in this physics
	# frame. Forced movement invalidates the battle snapshot immediately.
	var padding := Vector2i.ONE * motion_padding
	var origin := owner.global_position
	var owner_id := owner.get_instance_id()
	var low := cell_for(origin - Vector2.ONE * radius) - padding
	var high := cell_for(origin + Vector2.ONE * radius) + padding
	var radius_sq := radius * radius
	var bias := Vector2.ZERO
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var bucket = buckets.get(Vector2i(x, y))
			if bucket == null:
				continue
			for other in bucket:
				if other == owner or not is_instance_valid(other) or other.is_queued_for_deletion() or bool(other.get_meta("ignore_monster_separation", false)):
					continue
				var offset: Vector2 = origin - other.global_position
				var distance_sq := offset.length_squared()
				if distance_sq >= radius_sq:
					continue
				var distance := 0.0
				var away: Vector2
				if distance_sq <= 0.01:
					away = COMMON._deterministic_overlap_direction(owner_id, other.get_instance_id())
				else:
					distance = sqrt(distance_sq)
					away = offset / distance
				bias += away * (1.0 - clampf(distance / radius, 0.0, 1.0))
	return bias.normalized() if bias.length_squared() > 0.0001 else Vector2.ZERO


func count_group_near(origin: Vector2, radius: float, group: StringName, excluded: Node, stop_after: int) -> int:
	var padding := Vector2i.ONE * motion_padding
	var low := cell_for(origin - Vector2.ONE * radius) - padding
	var high := cell_for(origin + Vector2.ONE * radius) + padding
	var radius_sq := radius * radius
	var count := 0
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var bucket = buckets.get(Vector2i(x, y))
			if bucket == null:
				continue
			for actor in bucket:
				if actor == excluded or not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_in_group(group):
					continue
				if origin.distance_squared_to(actor.global_position) <= radius_sq:
					count += 1
					if stop_after > 0 and count >= stop_after:
						return count
	return count


func fill_rect(rect: Rect2, result: Array) -> void:
	result.clear()
	var padding := Vector2i.ONE * motion_padding
	var low := cell_for(rect.position) - padding
	var high := cell_for(rect.end) + padding
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var bucket = buckets.get(Vector2i(x, y))
			if bucket == null:
				continue
			for actor in bucket:
				if not is_instance_valid(actor) or actor.is_queued_for_deletion():
					continue
				var point: Vector2 = actor.global_position
				# Include both ends, matching the legacy capsule's <= radius.
				if point.x >= rect.position.x and point.y >= rect.position.y and point.x <= rect.end.x and point.y <= rect.end.y:
					result.append(actor)
