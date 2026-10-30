extends RefCounted
const DATA := preload("res://src/data/online_presentation_catalog.gd")
var previous := {}
var current := {}
var elapsed := 0.0
var idle_seconds := 0.0
var active := false
func clear() -> void:
	previous.clear(); current.clear(); active = false; elapsed = 0.0; idle_seconds = 0.0
func begin() -> void:
	var swap := previous
	previous = current; current = swap; current.clear()
	active = false
func put(id: int, target: Vector2) -> void:
	if id <= 0: return
	var start := target
	if previous.has(id) and idle_seconds < DATA.MOTION_RESET_SECONDS:
		var old: Array = previous[id]
		start = old[0].lerp(old[1],minf(1.0,elapsed / DATA.MOTION_SECONDS))
		if start.distance_squared_to(target) > DATA.FX_SNAP_DISTANCE * DATA.FX_SNAP_DISTANCE: start = target
	current[id] = [start,target]
	active = active or start != target
func finish() -> void:
	elapsed = 0.0; idle_seconds = 0.0
func advance(delta: float) -> bool:
	idle_seconds += maxf(0.0,delta)
	if not active: return false
	elapsed = minf(DATA.MOTION_SECONDS,elapsed + maxf(0.0,delta))
	active = elapsed < DATA.MOTION_SECONDS
	return true
func position(id: int, fallback: Vector2) -> Vector2:
	if not current.has(id): return fallback
	var pair: Array = current[id]
	return pair[0].lerp(pair[1],minf(1.0,elapsed / DATA.MOTION_SECONDS))
