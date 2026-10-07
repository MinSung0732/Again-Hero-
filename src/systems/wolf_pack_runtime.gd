extends RefCounted

const DATA := preload("res://src/data/wolf_behavior_catalog.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
const CELL_SIZE := 125.0
var battle: Node
var wolves: Dictionary = {}
var death_cells: Dictionary = {}
var used_cells: Array[Vector2i] = []
var stale_ids: Array[int] = []
var spawn_jobs: Array[Dictionary] = []

func setup(authority: Node) -> void:
	battle = authority

func register(wolf: Node2D) -> void:
	var id := wolf.get_instance_id()
	wolves[id] = wolf
	wolf.tree_exited.connect(unregister.bind(id), CONNECT_ONE_SHOT)

func unregister(id: int) -> void:
	wolves.erase(id)

func record_death(wolf: Node2D) -> void:
	unregister(wolf.get_instance_id())
	var cell := Vector2i(floori(wolf.global_position.x / CELL_SIZE), floori(wolf.global_position.y / CELL_SIZE))
	if not death_cells.has(cell):
		death_cells[cell] = []
	var points: Array = death_cells[cell]
	if points.is_empty():
		used_cells.append(cell)
	points.append(wolf.global_position)

func queue_pack(origin: Vector2, facing: float) -> void:
	spawn_jobs.append({"origin":origin, "facing":facing, "index":0})

func tick(_delta: float) -> void:
	# Batch deaths: examine each eligible living wolf once, using nearby cells.
	# Reuse cell buckets and never poll the scene's monster group.
	if not used_cells.is_empty():
		stale_ids.clear()
		for id in wolves:
			var wolf: Node2D = wolves[id]
			if not is_instance_valid(wolf) or wolf.is_queued_for_deletion():
				stale_ids.append(id)
				continue
			if wolf.can_howl() and _has_near_death(wolf.global_position):
				wolf.begin_howl()
		for id in stale_ids:
			wolves.erase(id)
		for cell in used_cells:
			death_cells[cell].clear()
		used_cells.clear()
	var budget := int(DATA.PACK.spawn_budget)
	while budget > 0 and not spawn_jobs.is_empty():
		var job: Dictionary = spawn_jobs[0]
		var index := int(job.index)
		# Three columns behind the caster, four rows; snapshot survives release.
		var position: Vector2 = job.origin + Vector2(-float(job.facing) * (float(DATA.PACK.back_distance) + (index % 3) * float(DATA.PACK.spacing)), (float(index / 3) - 1.5) * float(DATA.PACK.spacing))
		var child = battle._spawn_monster("wolf", position, 0.0, false, {"speed_multiplier":float(DATA.PACK.speed_multiplier)})
		if is_instance_valid(child):
			child.set_meta("spawn_source", "elite_skill")
			child.set_meta("runtime_variant_stats", {"speed":float(DATA.PACK.speed_multiplier)})
			child.set_meta("wolf_pack_speed_multiplier", float(DATA.PACK.speed_multiplier))
			FX.show_on(child, "wolf_pack_agility")
		job.index = index + 1
		budget -= 1
		if int(job.index) >= int(DATA.PACK.count):
			# Fixed job count removal, no shifting an ever-growing spawn array.
			spawn_jobs[0] = spawn_jobs.back()
			spawn_jobs.pop_back()

func _has_near_death(position: Vector2) -> bool:
	var radius := float(DATA.HOWL.radius)
	var low := Vector2i(floori((position.x - radius) / CELL_SIZE), floori((position.y - radius) / CELL_SIZE))
	var high := Vector2i(floori((position.x + radius) / CELL_SIZE), floori((position.y + radius) / CELL_SIZE))
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			if not death_cells.has(cell):
				continue
			for point in death_cells[cell]:
				if position.distance_squared_to(point) <= radius * radius:
					return true
	return false

func reset() -> void:
	wolves.clear()
	death_cells.clear()
	used_cells.clear()
	stale_ids.clear()
	spawn_jobs.clear()
