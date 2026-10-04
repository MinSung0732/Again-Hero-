extends RefCounted
class_name MonsterCollectionStore
const ACCOUNT_SCOPE := preload("res://src/systems/account_save_scope.gd")

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const SAVE_PATH := "user://monster_collection.cfg"
const PROGRESS_PATH := "user://stage_progress.cfg"

static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var has_saved_data := ACCOUNT_SCOPE.load_config(config, SAVE_PATH) == OK
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
		var level := 0
		var required := MONSTER_CATALOG.get_shards_required(monster_id)

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
			level = maxi(
				int(
					config.get_value(
						"monsters",
						"%s_level" % monster_id,
						0
					)
				),
				0
			)

		if shards >= required:
			unlocked = true
		level = clampi(level, 0, MONSTER_CATALOG.MAX_UPGRADE_LEVEL)

		result[monster_id] = {
			"unlocked": unlocked,
			"shards": shards,
			"level": level,
		}

	return result

static func _state_config(state: Dictionary) -> ConfigFile:
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
		var level := 0
		var required := MONSTER_CATALOG.get_shards_required(monster_id)
		var entry = state.get(monster_id, {})

		if typeof(entry) == TYPE_DICTIONARY:
			unlocked = bool(entry.get("unlocked", unlocked))
			shards = maxi(int(entry.get("shards", 0)), 0)
			level = clampi(int(entry.get("level", 0)), 0, MONSTER_CATALOG.MAX_UPGRADE_LEVEL)

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
		config.set_value(
			"monsters",
			"%s_level" % monster_id,
			level
		)

	return config

static func save_state(state: Dictionary) -> bool:
	return ACCOUNT_SCOPE.save_config(_state_config(state), SAVE_PATH) == OK

static func _save_with_research(state: Dictionary, points: int) -> bool:
	if points <= 0:
		return save_state(state)
	var progress := ConfigFile.new()
	var error := ACCOUNT_SCOPE.load_config(progress, PROGRESS_PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
		return false
	progress.set_value("meta", "research_points", maxi(int(progress.get_value("meta", "research_points", 0)), 0) + points)
	return ACCOUNT_SCOPE.save_configs({SAVE_PATH.get_file(): _state_config(state), PROGRESS_PATH.get_file(): progress}) == OK

static func normalize_maxed() -> Dictionary:
	var state := load_state()
	var points := 0
	var raw := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(raw, SAVE_PATH)
	var changed := false
	for id in state:
		changed = changed or int(raw.get_value("monsters", "%s_level" % id, 0)) > MONSTER_CATALOG.MAX_UPGRADE_LEVEL
		if is_maxed(id, state):
			points += int(state[id].shards) * MONSTER_CATALOG.SHARD_RESEARCH_POINTS
			state[id].shards = 0
	return {"success": (points == 0 and not changed) or _save_with_research(state, points), "research_points": points}

static func is_maxed(monster_id: String, state: Dictionary = {}) -> bool:
	return get_upgrade_level(monster_id, state) >= MONSTER_CATALOG.MAX_UPGRADE_LEVEL

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


static func get_upgrade_level(monster_id: String, state: Dictionary = {}) -> int:
	var source := state
	if source.is_empty():
		source = load_state()

	var entry = source.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return 0
	return clampi(int(entry.get("level", 0)), 0, MONSTER_CATALOG.MAX_UPGRADE_LEVEL)


static func try_upgrade(monster_id: String) -> Dictionary:
	var state := load_state()
	var entry = state.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return {"success": false, "state": state, "reason": "unknown_monster"}
	if not bool(entry.get("unlocked", false)):
		return {"success": false, "state": state, "reason": "locked"}
	if is_maxed(monster_id, state):
		return {"success": false, "state": state, "reason": "max_level"}

	var profile := MONSTER_CATALOG.get_rarity_upgrade_profile(monster_id)
	if not bool(profile.get("configured", false)):
		return {"success": false, "state": state, "reason": "not_configured"}

	var required := MONSTER_CATALOG.get_shards_required(monster_id)
	var shards := maxi(int(entry.get("shards", 0)), 0)
	if shards < required:
		return {"success": false, "state": state, "reason": "not_enough_shards"}

	entry["shards"] = shards - required
	entry["level"] = maxi(int(entry.get("level", 0)), 0) + 1
	state[monster_id] = entry
	var points := 0
	if is_maxed(monster_id, state):
		points = int(entry.shards) * MONSTER_CATALOG.SHARD_RESEARCH_POINTS
		entry.shards = 0
	if not _save_with_research(state, points):
		return {"success": false, "state": load_state(), "reason": "save_failed"}
	return {
		"success": true,
		"state": state,
		"level": int(entry["level"]),
		"shards": int(entry["shards"]),
		"research_points": points,
	}

static func add_shards(monster_id: String, amount: int) -> Dictionary:
	return award_shards(monster_id, amount).state

static func award_shards(monster_id: String, amount: int) -> Dictionary:
	var state := load_state()
	if not state.has(monster_id) or amount <= 0:
		return {"success": false, "state": state, "research_points": 0}
	if is_maxed(monster_id, state):
		var points := amount * MONSTER_CATALOG.SHARD_RESEARCH_POINTS
		var success := _save_with_research(state, points)
		return {"success": success, "state": state, "research_points": points if success else 0}

	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {"success": false, "state": state, "research_points": 0}

	var entry = state.get(monster_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {
			"unlocked": bool(data.get("default_unlocked", false)),
			"shards": 0,
			"level": 0,
		}

	var shards := maxi(
		int(entry.get("shards", 0)) + maxi(amount, 0),
		0
	)
	entry["shards"] = shards

	var required := MONSTER_CATALOG.get_shards_required(monster_id)
	if shards >= required:
		entry["unlocked"] = true

	state[monster_id] = entry
	var success := save_state(state)
	return {"success": success, "state": state if success else load_state(), "research_points": 0}
