extends RefCounted
## Survival weapon identity. Fixed 64 generation-safe reaction records, no actor scans.
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const RECORD_LIMIT := 64
var host
var clock := 0.0
var previous := Vector2.ZERO
var movement := 0.0
var casts := 0
var records: Dictionary = {}
var order: Array[Vector3i] = []
var cursor := 0
var summons_cursor := 0
func install(runtime) -> void:
	host = weakref(runtime)
	previous = runtime.hero.global_position
func tick(delta: float) -> void:
	clock += delta
	var runtime = host.get_ref()
	if runtime == null: return
	var current: Vector2 = runtime.hero.global_position
	# Teleports/displacements do not instantly bank a full ambush.
	movement = minf(180.0,movement+minf(previous.distance_to(current),maxf(0.0,delta)*380.0))
	previous = current
func cast_factor(data: Dictionary) -> float:
	if String(data.owner) == "swift_hunter" and String(data.pattern) in ["combo","slash"] and movement >= 180.0:
		movement = 0.0
		return 1.8 if bool(data.get("growth_evolved",false)) else 1.45
	return 1.0
func origin(data: Dictionary,fallback: Vector2) -> Vector2:
	var runtime = host.get_ref()
	if String(data.owner) != "summoner_hero" or String(data.pattern) == "summon" or not is_instance_valid(runtime.authority): return fallback
	var registry = runtime.authority.get("active_hero_summons")
	if not registry is Dictionary: return fallback
	var count := 0
	var result := fallback
	for key in registry:
		var actor = registry[key]
		if not is_instance_valid(actor) or actor.get("owner_hero") != runtime.hero: continue
		if count == summons_cursor%3: result = actor.global_position
		count += 1
		if count >= 3: break
	if count > 0: summons_cursor = (summons_cursor+1)%count
	return result
func _key(actor: Node2D) -> Vector3i:
	var runtime = host.get_ref()
	if not is_instance_valid(runtime.authority) or not runtime.authority.has_method("get_battle_entity_handle"): return Vector3i.ZERO
	return runtime.authority.get_battle_entity_handle(actor)
func factor(actor: Node2D,data: Dictionary) -> float:
	if bool(data.get("evolution_secondary",false)): return 1.0
	var owner := String(data.get("owner",""))
	if owner not in ["archmage_hero","chemical_hero"]: return 1.0
	var key := _key(actor)
	if key == Vector3i.ZERO or not records.has(key): return 1.0
	var record: Dictionary = records[key]
	if String(record.owner) != owner or float(record.left) < clock or float(record.ready) > clock: return 1.0
	var element := String(data.get("kit_element",""))
	if String(record.element) == element: return 1.0
	return 1.65 if bool(data.get("growth_evolved",false)) else 1.3
func landed(actor: Node2D,data: Dictionary,reacted: bool) -> void:
	if bool(data.get("evolution_secondary",false)) or not TARGETS.is_detectable(actor): return
	var owner := String(data.get("owner",""))
	if owner not in ["archmage_hero","chemical_hero"]: return
	var key := _key(actor)
	if key == Vector3i.ZERO: return
	var ready := float(records.get(key,{}).get("ready",0.0))
	if not records.has(key):
		if order.size() < RECORD_LIMIT: order.append(key)
		else:
			records.erase(order[cursor]); order[cursor] = key; cursor = (cursor+1)%RECORD_LIMIT
	if reacted: ready = clock+0.8
	records[key] = {"owner":owner,"element":String(data.get("kit_element","")),"left":clock+3.0,"ready":ready}
func after_cast(data: Dictionary,origin_point: Vector2,direction: Vector2,target: Node2D,damage: int,reach: float) -> void:
	if String(data.owner) != "ranged_rookie" or not TARGETS.is_detectable(target) or String(data.pattern) in ["guard","heal"]: return
	casts += 1
	if casts%3 != 0: return
	var runtime = host.get_ref()
	var secondary: Dictionary = data.get("evolution_secondary_data",data).duplicate()
	secondary["evolution_secondary"] = true
	var center: Vector2 = target.global_position if bool(data.get("growth_evolved",false)) else origin_point+direction*minf(reach,220.0)
	runtime._splash(center,maxi(1,roundi(damage*.4)),90.0 if bool(data.get("growth_evolved",false)) else 65.0,null,secondary)
