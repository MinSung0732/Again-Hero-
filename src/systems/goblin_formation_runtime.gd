extends RefCounted
const DATA := preload("res://src/data/hobgoblin_behavior_catalog.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var battle: Node
var clock := 0.0
var goblin_ids: Dictionary = {}
var leaders: Array[WeakRef] = []
var leader_ids: Array[int] = []
var guard_sources := 0
var states: Dictionary = {}
var cursor := 0
var scan_scratch: Array = []
var guard_grid: Dictionary = {}
var guard_grid_frame := -1
const GUARD_CELL_SIZE := 256.0

func setup(authority: Node, catalog: Dictionary) -> void:
	battle = authority
	for id in catalog:
		if "고블린" in String(catalog[id].get("name","")): goblin_ids[id] = true

func reset() -> void:
	clock = 0.0
	leaders.clear()
	leader_ids.clear()
	guard_sources = 0
	states.clear()
	scan_scratch.clear()
	guard_grid.clear()
	guard_grid_frame = -1
	cursor = 0

func register(leader: Node2D) -> void:
	var id := leader.get_instance_id()
	if states.has(id): return
	leaders.append(weakref(leader))
	leader_ids.append(id)
	states[id] = {"refresh":clock,"shield":clock+DATA.SHIELD_SECONDS,"command":clock,"guard":false,"shielding":false}
	invalidate(leader)

func invalidate(leader: Node2D) -> void:
	var state: Dictionary = states.get(leader.get_instance_id(),{})
	if not state.is_empty():
		var guarded: bool = leader.special_augment_configs.has("hobgoblin_iron_bond")
		if guarded != bool(state.guard):
			guard_sources += 1 if guarded else -1
			state.guard = guarded
		guard_grid_frame = -1
		var shielding: bool = leader.special_augment_configs.has("hobgoblin_shield_march")
		if shielding and not bool(state.shielding): state.shield = clock+DATA.SHIELD_SECONDS
		state.shielding = shielding
		state.refresh = clock
		state.command = clock

func is_goblin(actor: Node) -> bool:
	return is_instance_valid(actor) and goblin_ids.has(String(actor.get("monster_type")))

func _alive(actor: Node) -> bool:
	return is_instance_valid(actor) and not actor.is_queued_for_deletion() and int(actor.get("current_hp")) > 0 and not bool(actor.get("dying"))

func tick(delta: float) -> void:
	clock += delta
	if leaders.is_empty() or not is_instance_valid(battle): return
	var budget := DATA.REFRESH_BUDGET
	var visited := 0
	var size := leaders.size()
	while visited < size and budget > 0 and not leaders.is_empty():
		cursor %= leaders.size()
		var leader = leaders[cursor].get_ref()
		visited += 1
		if not _alive(leader):
			# Weak registrations cannot retain dead actors or their aura.
			var stale_id: int = leader_ids[cursor]
			guard_sources -= 1 if bool(states[stale_id].guard) else 0
			states.erase(stale_id)
			leaders.remove_at(cursor)
			leader_ids.remove_at(cursor)
			continue
		cursor += 1
		var state: Dictionary = states[leader.get_instance_id()]
		if float(state.refresh) > clock: continue
		budget -= 1
		state.refresh = clock+DATA.REFRESH_SECONDS
		_refresh(leader,state)

func _refresh(leader: Node2D, state: Dictionary) -> void:
	var radius: float = leader.formation_radius()
	scan_scratch.clear()
	battle.fill_monsters_near(leader.global_position,radius,scan_scratch)
	var count := 0
	var shield_due := float(state.shield) <= clock
	var command_due := bool(leader.command_active) and float(state.command) <= clock
	for ally in scan_scratch:
		if not _alive(ally) or not is_goblin(ally) or leader.global_position.distance_squared_to(ally.global_position) > radius*radius: continue
		count += 1
		if shield_due and leader.special_augment_configs.has("hobgoblin_shield_march"):
			COMMON.grant_typed_shield(ally,"melee",DATA.SHIELD_AMOUNT,true)
		if command_due and ally != leader and ally.get("command_active") != true:
			_assign_command(ally,leader,count)
	scan_scratch.clear()
	leader.update_formation_count(count)
	if shield_due: state.shield = clock+DATA.SHIELD_SECONDS
	if command_due: state.command = clock+DATA.COMMAND_SECONDS

func _assign_command(ally: Node2D, leader: Node2D, slot: int) -> void:
	var previous: WeakRef = ally.get_meta("goblin_command_leader") if ally.has_meta("goblin_command_leader") else null
	var other = previous.get_ref() if previous != null else null
	if _alive(other) and other != leader and float(ally.get_meta("goblin_command_until",0.0)) > clock:
		var other_distance := ally.global_position.distance_squared_to(other.global_position)
		var distance := ally.global_position.distance_squared_to(leader.global_position)
		if other_distance < distance or (is_equal_approx(other_distance,distance) and other.get_instance_id() < leader.get_instance_id()): return
	ally.set_meta("goblin_command_leader",weakref(leader))
	ally.set_meta("goblin_command_until",clock+DATA.COMMAND_SECONDS+DATA.REFRESH_SECONDS)
	ally.set_meta("goblin_command_offset",Vector2.RIGHT.rotated(slot*2.39996323)*DATA.COMMAND_SPACING)

func _guard_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x/GUARD_CELL_SIZE),floori(point.y/GUARD_CELL_SIZE))

func _refresh_guard_grid() -> void:
	var frame := Engine.get_physics_frames()
	if guard_grid_frame == frame: return
	guard_grid_frame = frame
	# Reuse buckets; allocation occurs only on first visit to a new map cell.
	for cell in guard_grid: guard_grid[cell].clear()
	for reference in leaders:
		var provider = reference.get_ref()
		if not _alive(provider) or not provider.special_augment_configs.has("hobgoblin_iron_bond"): continue
		var cell := _guard_cell(provider.global_position)
		if not guard_grid.has(cell): guard_grid[cell] = []
		guard_grid[cell].append(reference)

func incoming_multiplier(target: Node2D) -> float:
	if guard_sources <= 0 or not is_goblin(target): return 1.0
	_refresh_guard_grid()
	# Search the provider index, not every soldier in the army's local cells.
	var extent := Vector2.ONE*DATA.LORD_RADIUS
	var first := _guard_cell(target.global_position-extent)-Vector2i.ONE
	var last := _guard_cell(target.global_position+extent)+Vector2i.ONE
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			var cell := Vector2i(x,y)
			if not guard_grid.has(cell): continue
			for reference in guard_grid[cell]:
				var provider = reference.get_ref()
				if not _alive(provider) or not provider.special_augment_configs.has("hobgoblin_iron_bond"): continue
				var radius: float = provider.formation_radius()
				if target.global_position.distance_squared_to(provider.global_position) <= radius*radius:
					return DATA.GUARD_MULTIPLIER # Multiple copies of the same aura never multiply.
	return 1.0
