extends Node2D
## Fixed-capacity decoration pool, outside the monster registry/target queries.
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
const FX := preload("res://src/ui/bulgasal_combat_effects.gd")
var actor: Node2D
var authority: Node
var bodies: Array[StaticBody2D] = []
var states := PackedInt32Array()
var ages := PackedFloat32Array()
var retiring := false
var retire_remaining := 1.7

func _ready() -> void:
	top_level = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	states.resize(DATA.PILLAR_MAX)
	ages.resize(DATA.PILLAR_MAX)
	for index in range(DATA.PILLAR_MAX):
		var body := StaticBody2D.new()
		body.collision_layer = 0
		body.collision_mask = 0
		body.set_meta("decoration_type", "bulgasal_pillar")
		var collider := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = DATA.PILLAR_RADIUS
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		bodies.append(body)

func regenerate() -> void:
	if not is_instance_valid(actor) or retiring:
		return
	var map_size: Vector2 = authority.current_map_size
	for index in range(DATA.PILLAR_MAX):
		if states[index] != 0:
			continue
		var column := index % 4
		var row := index / 4
		var candidate := Vector2((float(column)+randf_range(0.2,0.8))/4.0, (float(row)+randf_range(0.25,0.75))/2.0) * map_size
		if authority.has_method("_clamp_manual_spawn_position"):
			candidate = authority._clamp_manual_spawn_position(candidate)
		# A bounded terrain/actor check prevents spawning a collider in a wall or actor.
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = bodies[index].get_child(0).shape
		query.transform = Transform2D(0.0, candidate)
		query.collision_mask = 15
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		bodies[index].global_position = candidate
		states[index] = 1
		ages[index] = 0.0
		bodies[index].collision_layer = 3
	queue_redraw()

func nearest(point: Vector2, radius: float) -> int:
	var chosen := -1
	var best := radius*radius
	for index in range(DATA.PILLAR_MAX):
		if states[index] != 1 and states[index] != 2:
			continue
		var distance := bodies[index].global_position.distance_squared_to(point)
		if distance < best:
			chosen = index
			best = distance
	return chosen

func shatter(index: int, damage: bool, eaten: bool = false) -> bool:
	if index < 0 or index >= DATA.PILLAR_MAX or (states[index] != 1 and states[index] != 2):
		return false
	states[index] = 3
	ages[index] = 0.0
	bodies[index].collision_layer = 0
	if is_instance_valid(actor):
		if eaten:
			actor.add_stacking_shield(DATA.EAT_SHIELD)
		elif damage:
			actor.hit_aftershock(bodies[index].global_position)
	queue_redraw()
	return true

func shatter_all(damage: bool) -> void:
	for index in range(DATA.PILLAR_MAX):
		shatter(index, damage)

func shatter_segment(start: Vector2, finish: Vector2) -> void:
	for index in range(DATA.PILLAR_MAX):
		if (states[index] != 1 and states[index] != 2):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(bodies[index].global_position, start, finish)
		if closest.distance_squared_to(bodies[index].global_position) <= DATA.PILLAR_RADIUS*DATA.PILLAR_RADIUS:
			shatter(index, true)

func finish_death() -> void:
	shatter_all(false)
	retiring = true
	# Natural monster animation removal must not truncate the pillar destruction.
	var battle := get_parent().get_parent()
	reparent(battle, true)

func _physics_process(delta: float) -> void:
	if is_instance_valid(authority) and (authority.battle_over or authority.external_pause or authority.demon_augment_selection_active):
		return
	for index in range(DATA.PILLAR_MAX):
		if states[index] == 0:
			continue
		ages[index] += delta
		if states[index] == 1 and ages[index] >= 0.5:
			states[index] = 2
		elif states[index] == 3 and ages[index] >= 1.5:
			states[index] = 0
	if retiring:
		retire_remaining -= delta
		if retire_remaining <= 0.0:
			queue_free()
	queue_redraw()

func _draw() -> void:
	for index in range(DATA.PILLAR_MAX):
		if states[index] == 0:
			continue
		var frame := mini(int(ages[index]*10.0),4) if states[index] == 1 else 5 if states[index] == 2 else 6+mini(int(ages[index]*10.0),14)
		FX.draw_frame(self,"pillar",frame,to_local(bodies[index].global_position))
