extends RefCounted
class_name MutationDirector

var active: bool = false
var pending_event: Dictionary = {}
var candidate_ids: Array[String] = []

func reset() -> void:
	active = false
	pending_event.clear()
	candidate_ids.clear()

func begin(event: Dictionary, candidates: Array) -> bool:
	reset()

	for raw_id in candidates:
		var monster_id := String(raw_id)
		if monster_id.is_empty():
			continue
		if monster_id in candidate_ids:
			continue
		candidate_ids.append(monster_id)

	if candidate_ids.is_empty():
		return false

	pending_event = event.duplicate(true)
	active = true
	return true

func is_active() -> bool:
	return active

func get_event() -> Dictionary:
	return pending_event.duplicate(true)

func get_candidates() -> Array[String]:
	return candidate_ids.duplicate()

func commit_selection(monster_id: String) -> Dictionary:
	if not active:
		return {}
	if monster_id.is_empty():
		return {}

	var result := pending_event.duplicate(true)
	result["selected_monster_id"] = monster_id
	reset()
	return result
