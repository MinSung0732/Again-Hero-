extends RefCounted
class_name MonsterCollectionStore

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const SAVE_PATH := "user://monster_collection.json"
const FORMAT_VERSION := 1

static func load_state() -> Dictionary:
	var result := _make_default_state()

	if not FileAccess.file_exists(SAVE_PATH):
		return result

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return result

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return result

	var root: Dictionary = parsed
	var saved_monsters: Variant = root.get("monsters", {})
	if not (saved_monsters is Dictionary):
		return result

	var saved_dict: Dictionary = saved_monsters
	for monster_id in MONSTER_CATALOG.get_ids():
		if not saved_dict.has(monster_id):
			continue

		var raw_entry: Variant = saved_dict.get(monster_id)
		if not (raw_entry is Dictionary):
			continue

		var entry: Dictionary = raw_entry
		var current: Dictionary = result.get(monster_id, {})
		var shards := maxi(int(entry.get("shards", current.get("shards", 0))), 0)
		var unlocked := bool(entry.get("unlocked", current.get("unlocked", false)))
		var required := MONSTER_CATALOG.get_shards_required(monster_id)

		if shards >= required:
			unlocked = true

		result[monster_id] = {
			"unlocked": unlocked,
			"shards": shards,
		}

	return result

static func save_state(state: Dictionary) -> bool:
	var sanitized: Dictionary = {}
	for monster_id in MONSTER_CATALOG.get_ids():
		var raw_entry: Variant = state.get(monster_id, {})
		var entry: Dictionary = raw_entry if raw_entry is Dictionary else {}
		sanitized[monster_id] = {
			"unlocked": bool(entry.get("unlocked", MONSTER_CATALOG.is_default_unlocked(monster_id))),
			"shards": maxi(int(entry.get("shards", 0)), 0),
		}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify({
		"version": FORMAT_VERSION,
		"monsters": sanitized,
	}))
	return true

static func get_unlocked_ids(state: Dictionary = {}) -> Array[String]:
	var source := state
	if source.is_empty():
		source = load_state()

	var result: Array[String] = []
	for monster_id in MONSTER_CATALOG.get_ids():
		var raw_entry: Variant = source.get(monster_id, {})
		if raw_entry is Dictionary and bool(raw_entry.get("unlocked", false)):
			result.append(monster_id)
	return result

static func is_unlocked(monster_id: String, state: Dictionary = {}) -> bool:
	var source := state
	if source.is_empty():
		source = load_state()
	var raw_entry: Variant = source.get(monster_id, {})
	return raw_entry is Dictionary and bool(raw_entry.get("unlocked", false))

static func get_shards(monster_id: String, state: Dictionary = {}) -> int:
	var source := state
	if source.is_empty():
		source = load_state()
	var raw_entry: Variant = source.get(monster_id, {})
	if raw_entry is Dictionary:
		return maxi(int(raw_entry.get("shards", 0)), 0)
	return 0

static func add_shards(monster_id: String, amount: int) -> Dictionary:
	var state := load_state()
	if not state.has(monster_id):
		return state

	var entry: Dictionary = state[monster_id]
	entry["shards"] = maxi(int(entry.get("shards", 0)) + maxi(amount, 0), 0)
	if int(entry["shards"]) >= MONSTER_CATALOG.get_shards_required(monster_id):
		entry["unlocked"] = true
	state[monster_id] = entry
	save_state(state)
	return state

static func _make_default_state() -> Dictionary:
	var result: Dictionary = {}
	for monster_id in MONSTER_CATALOG.get_ids():
		result[monster_id] = {
			"unlocked": MONSTER_CATALOG.is_default_unlocked(monster_id),
			"shards": 0,
		}
	return result
