extends RefCounted
## Bounded display retargeting. Never writes server state or extrapolates.
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const CAPACITY := DATA.MAX_ACTORS + 1
var slots := {}
var free_slots := PackedInt32Array()
var free_count := 0
var ids := PackedInt64Array()
var seen := PackedInt64Array()
var starts := PackedVector2Array()
var targets := PackedVector2Array()
var offsets := PackedVector2Array()
var moving := PackedByteArray()
var tracked := PackedInt32Array()
var tracked_count := 0
var revision := 0
var elapsed := 0.0
var idle_seconds := 0.0
var active := false
func _init() -> void:
	ids.resize(CAPACITY); seen.resize(CAPACITY); starts.resize(CAPACITY)
	targets.resize(CAPACITY); offsets.resize(CAPACITY); moving.resize(CAPACITY)
	free_slots.resize(CAPACITY); tracked.resize(CAPACITY)
	clear()
func clear() -> void:
	slots.clear(); free_count = CAPACITY; tracked_count = 0; moving.fill(0); offsets.fill(Vector2.ZERO)
	for index in CAPACITY: free_slots[index] = CAPACITY-index-1
	active = false; elapsed = 0.0; idle_seconds = 0.0
func replace(hero: Array,actors: Array) -> void:
	revision += 1
	# Release absent IDs before acquisition, including a full-capacity roster swap.
	for actor in actors:
		var slot: int = slots.get(int(actor[0]),-1)
		if slot >= 0: seen[slot] = revision
	var hero_slot: int = slots.get(0,-1)
	if hero_slot >= 0: seen[hero_slot] = revision
	for slot in CAPACITY:
		if seen[slot] == revision or not slots.has(ids[slot]) or slots[ids[slot]] != slot: continue
		slots.erase(ids[slot]); moving[slot] = 0; offsets[slot] = Vector2.ZERO
		free_slots[free_count] = slot; free_count += 1
	var reset := idle_seconds >= DATA.MOTION_RESET_SECONDS
	active = false; tracked_count = 0
	_put(0,Vector2(hero[0],hero[1]),reset)
	for actor in actors: _put(int(actor[0]),Vector2(actor[2],actor[3]),reset)
	elapsed = 0.0; idle_seconds = 0.0
func _put(id: int,point: Vector2,reset: bool) -> void:
	var slot: int = slots.get(id,-1)
	var known := slot >= 0
	if not known:
		if free_count == 0: return
		free_count -= 1; slot = free_slots[free_count]
		slots[id] = slot; ids[slot] = id
	var start := targets[slot]+offsets[slot] if known else point
	if reset or start.distance_squared_to(point) > DATA.MOTION_SNAP_DISTANCE*DATA.MOTION_SNAP_DISTANCE: start = point
	starts[slot] = start; targets[slot] = point; offsets[slot] = start-point
	seen[slot] = revision; moving[slot] = int(start != point)
	tracked[tracked_count] = slot; tracked_count += 1
	active = active or moving[slot] != 0
func advance(delta: float) -> bool:
	idle_seconds += maxf(0.0,delta)
	if not active: return false
	elapsed = minf(DATA.MOTION_SECONDS,elapsed+maxf(0.0,delta))
	var weight := elapsed/DATA.MOTION_SECONDS
	for index in tracked_count:
		var slot := tracked[index]
		if moving[slot] == 0: continue
		offsets[slot] = (starts[slot]-targets[slot])*(1.0-weight)
		if weight >= 1.0: moving[slot] = 0
	active = weight < 1.0
	return true
func position(id: int,fallback: Vector2) -> Vector2:
	var slot: int = slots.get(id,-1)
	return targets[slot]+offsets[slot] if slot >= 0 else fallback
