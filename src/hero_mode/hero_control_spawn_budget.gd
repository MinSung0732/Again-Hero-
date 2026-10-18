extends RefCounted
# Incremental counts: no actor/group scan, timers use the paused run clock.
const DATA := preload("res://src/data/hero_control_spawn_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var members: Dictionary = {}
var species: Dictionary = {}
var next_spawn := 0.0
var fallback_cursor := 0
func reset() -> void:
	members.clear(); species.clear(); next_spawn = 0.0; fallback_cursor = 0
func controls(id: String,elite: bool) -> bool:
	return DATA.is_control(MONSTERS.MONSTERS.get(id,{}),elite)
func allows(id: String,elite: bool,stage: int,elapsed: float,population: int) -> bool:
	if not controls(id,elite): return true
	var rule := DATA.stage_rule(stage)
	if elapsed < float(rule.first) or elapsed < next_spawn: return false
	var late := elapsed >= DATA.LATE_TIME
	var limit := int(rule.limit)+(DATA.LATE_LIMIT_BONUS if late else 0)
	var ratio_limit := maxi(1,floori(float(population+1)*float(rule.ratio)))
	if members.size() >= mini(limit,ratio_limit): return false
	return int(species.get(id,0)) < int(rule.species)+(DATA.LATE_SPECIES_BONUS if late else 0)
func register(instance_id: int,id: String,elite: bool,stage: int,elapsed: float) -> void:
	if members.has(instance_id) or not controls(id,elite): return
	members[instance_id] = id
	species[id] = int(species.get(id,0))+1
	next_spawn = maxf(next_spawn,elapsed+float(DATA.stage_rule(stage).interval))
func retire(instance_id: int) -> void:
	if not members.has(instance_id): return
	var id: String = members[instance_id]
	species[id] = maxi(0,int(species.get(id,0))-1)
	members.erase(instance_id)
func choose(id: String,roster: Array,elite: bool,stage: int,elapsed: float,population: int) -> String:
	if allows(id,elite,stage,elapsed,population): return id
	# Preserve kill/XP opportunities with a bounded alternate selection.
	for offset in roster.size():
		var index := (fallback_cursor+offset)%roster.size()
		var candidate := String(roster[index])
		if controls(candidate,elite): continue
		if elite and not bool(MONSTERS.MONSTERS.get(candidate,{}).get("can_be_elite",true)): continue
		fallback_cursor = index+1
		return candidate
	return ""
