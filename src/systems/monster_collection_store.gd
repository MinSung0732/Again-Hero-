extends RefCounted
class_name MonsterCollectionStore

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const SAVE_PATH := "user://monster_collection.cfg"

static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var has_saved_data := config.load(SAVE_PATH) == OK
	var result: Dictionary = {}

	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if not MONSTER_CATALOG.MONSTERS.has(monster_id):
			continue

		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		if typeof(data) != TYPE_DICTIONARY:
			continue

		var unlocked := bool(data.get("default_unlocked", false))
		var shards := 0
		var required := maxi(int(data.get("shards_required", 1)), 1)

		if has_saved_data:
			unlocked = bool(
				config.get_value(
					"monsters",
					"%s_unlocked" % monster_id,
					unlocked
				)
			)
			shards = maxi(
				int(
					config.get_value(
						"monsters",
						"%s_shards" % monster_id,
						0
					)
				),
				0
			)

		if shards >= required:
			unlocked = true

		result[monster_id] = {
			"unlocked": unlocked,
			"shards": shards,
		}

	return result

static func save_state(state: Dictionary) -> bool:
	var config := ConfigFile.new()

	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if not MONSTER_CATALOG.MONSTERS.has(monster_id):
			continue

		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		if typeof(data) != TYPE_DICTIONARY:
			continue

		var unlocked := bool(data.get("default_unlocked", false))
		var shards := 0
		var required := maxi(int(data.get("shards_required", 1)), 1)
		var entry = state.get(monster_id, {})

		if typeof(entry) == TYPE_DICTIONARY:
			unlocked = bool(entry.get("unlocked", unlocked))
			shards = maxi(int(entry.get("shards", 0)), 0)

		if shards >= required:
			unlocked = true

		config.set_value(
			"monsters",
			"%s_unlocked" % monster_id,
			unlocked
		)
		config.set_value(
			"monsters",
			"%s_shards" % monster_id,
			shards
		)

	return config.save(SAVE_PATH) == OK

static func get_unlocked_ids(state: Dictionary = {}) -> Array:
	var source := state
	if source.is_empty():
		source = load_state()

	var result: Array = []
	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		var entry = source.get(monster_id, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if bool(entry.get("unlocked", false)):
			result.append(monster_id)

	return result

static func is_unlocked(monster_id: String, state: Dictionary = {}) -> bool:
	var source := state
	if source.is_empty():
		source = load_state()

	var entry = source.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	return bool(entry.get("unlocked", false))

static func get_shards(monster_id: String, state: Dictionary = {}) -> int:
	var source := state
	if source.is_empty():
		source = load_state()

	var entry = source.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return 0
	return maxi(int(entry.get("shards", 0)), 0)

static func add_shards(monster_id: String, amount: int) -> Dictionary:
	var state := load_state()
	if not state.has(monster_id):
		return state

	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return state

	var entry = state.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {
			"unlocked": bool(data.get("default_unlocked", false)),
			"shards": 0,
		}

	var shards := maxi(
		int(entry.get("shards", 0)) + maxi(amount, 0),
		0
	)
	entry["shards"] = shards

	var required := maxi(int(data.get("shards_required", 1)), 1)
	if shards >= required:
		entry["unlocked"] = true

	state[monster_id] = entry
	save_state(state)
	return state
