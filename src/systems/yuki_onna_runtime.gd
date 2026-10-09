extends RefCounted
const BUCKET_POOL := preload("res://src/systems/spatial_bucket_pool.gd")
const DATA := preload("res://src/data/yuki_onna_behavior_catalog.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
const CELL_SIZE := 125.0
var actors: Dictionary = {}
var elites: Dictionary = {}
var targets: Dictionary = {}
var death_cells: Dictionary = {}
var used_cells: Array[Vector2i] = []
var spare_death_buckets: Array = []
var stale_ids: Array[int] = []

static func start_target_life(target: Node) -> void:
	target.set_meta("yuki_status_generation",int(target.get_meta("yuki_status_generation",0)) + 1)
	target.set_meta("yuki_slow_multiplier",1.0)
	target.set_meta("yuki_slow_active",false)
	var effect = target.get_node_or_null("StatusFX_yuki_slow")
	if effect != null:
		effect.visible = false
		effect.stop()
		effect._last_active = false
		effect.set_process(false)

func register(actor: Node2D) -> void:
	var id := actor.get_instance_id()
	actors[id] = actor
	actor.tree_exited.connect(unregister.bind(id),CONNECT_ONE_SHOT)

func unregister(id: int) -> void:
	actors.erase(id)
	elites.erase(id)

func register_elite(actor: Node2D) -> void:
	elites[actor.get_instance_id()] = actor

func record_death(actor: Node2D) -> void:
	unregister(actor.get_instance_id())
	var cell := Vector2i(floori(actor.global_position.x / CELL_SIZE),floori(actor.global_position.y / CELL_SIZE))
	if not death_cells.has(cell):
		death_cells[cell] = BUCKET_POOL.acquire(spare_death_buckets)
	var points: Array = death_cells[cell]
	if points.is_empty():
		used_cells.append(cell)
	points.append(actor.global_position)

func apply_hit(target: Node2D, slow_ratio: float, cap: int, source: Node) -> void:
	if not _alive(target):
		return
	var id := target.get_instance_id()
	var generation := int(target.get_meta("yuki_status_generation",0))
	if not targets.has(id) or int(targets[id].generation) != generation:
		targets[id] = {"target":weakref(target),"generation":generation,"count":0,"cap":cap,"stack_move":1.0,"timer":0.0,"burst_timer":0.0,"burst_move":1.0}
	var entry: Dictionary = targets[id]
	var resistance := float(target.call("get_status_resistance","slow")) if target.has_method("get_status_resistance") else 0.0
	entry.cap = maxi(int(entry.cap),cap)
	if int(entry.count) < int(entry.cap):
		entry.count = int(entry.count) + 1
		entry.stack_move = float(entry.stack_move) * (1.0 - clampf(slow_ratio,0.0,0.99) * (1.0 - resistance))
	entry.timer = maxf(float(DATA.SLOW.duration) * (1.0 - resistance),0.05)
	if target.has_method("record_status_effect_event"):
		target.call("record_status_effect_event","slow")
	_try_snowflake(target,entry,source,resistance)
	_sync_target(target,entry)
	if not target.is_in_group("hero"):
		FX.show_on(target,"yuki_slow")

func _try_snowflake(target: Node2D, entry: Dictionary, source: Node = null, resistance: float = -1.0) -> void:
	if elites.is_empty() or int(entry.cap) <= 0 or int(entry.count) < int(entry.cap):
		return
	var elite := _find_elite(target,source)
	if elite == null:
		return
	if resistance < 0.0:
		resistance = float(target.call("get_status_resistance","slow")) if target.has_method("get_status_resistance") else 0.0
	entry.count = 0
	entry.stack_move = 1.0
	entry.timer = 0.0
	entry.burst_timer = maxf(float(DATA.SNOWFLAKE.duration) * (1.0 - resistance),0.05)
	entry.burst_move = lerpf(float(DATA.SNOWFLAKE.move_multiplier),1.0,resistance)
	elite.visual.play_skill()
	var damage := maxi(int(round(float(elite.attack_damage) * float(DATA.SNOWFLAKE.damage_multiplier))),1)
	if target.has_method("take_followup_damage"):
		target.call("take_followup_damage",damage,elite)
	else:
		target.call("take_damage",damage)

func _find_elite(target: Node2D, source: Node) -> Node2D:
	if _alive(source) and bool(source.get("elite_snowflake")):
		return source as Node2D
	var closest: Node2D
	var distance := INF
	for id in elites:
		var actor: Node2D = elites[id]
		if not _alive(actor) or not actor.elite_snowflake:
			continue
		var candidate_distance := actor.global_position.distance_squared_to(target.global_position)
		if candidate_distance < distance:
			closest = actor
			distance = candidate_distance
	return closest

func _sync_target(target: Node, entry: Dictionary) -> void:
	var multiplier := float(entry.stack_move)
	if float(entry.burst_timer) > 0.0:
		multiplier = minf(multiplier,float(entry.burst_move))
	target.set_meta("yuki_slow_multiplier",multiplier)
	target.set_meta("yuki_slow_active",int(entry.count) > 0 or float(entry.burst_timer) > 0.0)

func tick(delta: float) -> void:
	if not used_cells.is_empty():
		for id in actors:
			var actor: Node2D = actors[id]
			if not _alive(actor):
				continue
			var free_stacks := maxi(actor.max_chill_stacks - actor.chill_stacks,0)
			if free_stacks > 0:
				actor.apply_chill(_near_death_count(actor.global_position,free_stacks))
		for cell in used_cells:
			death_cells[cell].clear()
		BUCKET_POOL.retire_empty(death_cells, used_cells, spare_death_buckets)
	stale_ids.clear()
	for id in targets:
		var entry: Dictionary = targets[id]
		var target: Node = entry.target.get_ref()
		if is_instance_valid(target) and int(target.get_meta("yuki_status_generation",0)) != int(entry.generation):
			stale_ids.append(id)
			continue
		if not _alive(target):
			if is_instance_valid(target):
				target.set_meta("yuki_slow_multiplier",1.0)
				target.set_meta("yuki_slow_active",false)
			stale_ids.append(id)
			continue
		entry.timer = maxf(float(entry.timer) - delta,0.0)
		entry.burst_timer = maxf(float(entry.burst_timer) - delta,0.0)
		if float(entry.timer) <= 0.0:
			entry.count = 0
			entry.cap = 0
			entry.stack_move = 1.0
		_try_snowflake(target as Node2D,entry)
		_sync_target(target,entry)
		if int(entry.count) <= 0 and float(entry.burst_timer) <= 0.0:
			stale_ids.append(id)
	for id in stale_ids:
		targets.erase(id)

func _near_death_count(position: Vector2, limit: int) -> int:
	var radius := float(DATA.CHILL.radius)
	var low := Vector2i(floori((position.x-radius)/CELL_SIZE),floori((position.y-radius)/CELL_SIZE))
	var high := Vector2i(floori((position.x+radius)/CELL_SIZE),floori((position.y+radius)/CELL_SIZE))
	var count := 0
	for y in range(low.y,high.y+1):
		for x in range(low.x,high.x+1):
			var cell := Vector2i(x,y)
			if not death_cells.has(cell):
				continue
			for point in death_cells[cell]:
				if position.distance_squared_to(point) <= radius*radius:
					count += 1
					if count >= limit:
						return count
	return count

func _alive(actor: Node) -> bool:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion():
		return false
	var hp = actor.get("current_hp")
	return hp != null and int(hp) > 0 and actor.get("dying") != true and actor.get("is_dying") != true and actor.get("active") != false

func reset() -> void:
	for id in targets:
		var target: Node = targets[id].target.get_ref()
		if is_instance_valid(target):
			target.set_meta("yuki_slow_multiplier",1.0)
			target.set_meta("yuki_slow_active",false)
	actors.clear()
	elites.clear()
	targets.clear()
	death_cells.clear()
	spare_death_buckets.clear()
	used_cells.clear()
	stale_ids.clear()
