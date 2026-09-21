extends RefCounted
class_name TeamLoadout

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")

const SAVE_PATH := "user://team_loadout.cfg"
const MAX_SLOTS := 3

static func load_ids() -> Array[String]:
	var config := ConfigFile.new()
	var raw_value: Variant = _default_ids()
	if config.load(SAVE_PATH) == OK:
		raw_value = config.get_value("team", "monster_ids", raw_value)

	var normalized := _normalize_ids(raw_value)
	if normalized.is_empty():
		normalized = _default_ids()
	return normalized

static func save_ids(monster_ids: Array[String]) -> Array[String]:
	var normalized := _normalize_ids(monster_ids)
	if normalized.is_empty():
		var defaults := _default_ids()
		if not defaults.is_empty():
			normalized.append(defaults[0])

	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("team", "monster_ids", normalized)
	config.save(SAVE_PATH)
	return normalized

static func is_equipped(monster_id: String) -> bool:
	return monster_id in load_ids()

static func _default_ids() -> Array[String]:
	var result: Array[String] = []
	for monster_id in MONSTER_CATALOG.get_ids():
		if result.size() >= MAX_SLOTS:
			break
		result.append(monster_id)
	return result

static func _normalize_ids(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (raw_value is Array or raw_value is PackedStringArray):
		return result

	for raw_id in raw_value:
		var monster_id := String(raw_id)
		if monster_id.is_empty():
			continue
		if MONSTER_CATALOG.get_monster(monster_id).is_empty():
			continue
		if monster_id in result:
			continue

		result.append(monster_id)
		if result.size() >= MAX_SLOTS:
			break

	return result
