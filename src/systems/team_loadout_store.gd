extends RefCounted
class_name TeamLoadoutStore

const SAVE_PATH := "user://team_loadout.cfg"
const MAX_SLOTS := 3

static func load_ids(valid_ids: Array, fallback_ids: Array) -> Array[String]:
	var raw_ids: Array = []
	var config := ConfigFile.new()

	if config.load(SAVE_PATH) == OK:
		var encoded := String(
			config.get_value("team", "monster_ids", "")
		)
		if not encoded.is_empty():
			for raw_id in encoded.split(",", false):
				raw_ids.append(String(raw_id))

	var normalized := _normalize_ids(raw_ids, valid_ids)
	if normalized.is_empty():
		normalized = _normalize_ids(fallback_ids, valid_ids)

	return normalized

static func save_ids(monster_ids: Array, valid_ids: Array) -> bool:
	var normalized := _normalize_ids(monster_ids, valid_ids)
	if normalized.is_empty():
		return false

	var encoded := ""
	for monster_id in normalized:
		if not encoded.is_empty():
			encoded += ","
		encoded += monster_id

	var config := ConfigFile.new()
	config.set_value("team", "monster_ids", encoded)
	return config.save(SAVE_PATH) == OK

static func _normalize_ids(raw_ids: Array, valid_ids: Array) -> Array[String]:
	var result: Array[String] = []

	for raw_id in raw_ids:
		var monster_id := String(raw_id)
		if monster_id.is_empty():
			continue
		if monster_id not in valid_ids:
			continue
		if monster_id in result:
			continue

		result.append(monster_id)
		if result.size() >= MAX_SLOTS:
			break

	return result
