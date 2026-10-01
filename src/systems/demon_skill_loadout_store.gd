extends RefCounted
class_name DemonSkillLoadoutStore

const SAVE_PATH := "user://demon_skill_loadout.cfg"
const MAX_SLOTS := 3


static func load_ids(valid_ids: Array, fallback_ids: Array) -> Array:
	var raw_ids: Array = []
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		var encoded := String(
			config.get_value("skills", "skill_ids", "")
		)
		if not encoded.is_empty():
			for raw_id in encoded.split(",", false):
				raw_ids.append(String(raw_id))

	var normalized := _normalize_ids(raw_ids, valid_ids)
	if normalized.is_empty():
		normalized = _normalize_ids(fallback_ids, valid_ids)
	return normalized


static func save_ids(skill_ids: Array, valid_ids: Array) -> bool:
	var normalized := _normalize_ids(skill_ids, valid_ids)
	if normalized.is_empty():
		return false

	var encoded := ""
	for skill_id in normalized:
		if not encoded.is_empty():
			encoded += ","
		encoded += String(skill_id)

	var config := ConfigFile.new()
	config.set_value("skills", "skill_ids", encoded)
	return config.save(SAVE_PATH) == OK


static func _normalize_ids(raw_ids: Array, valid_ids: Array) -> Array:
	var result: Array = []
	for raw_id in raw_ids:
		var skill_id := String(raw_id)
		if skill_id.is_empty() or skill_id not in valid_ids:
			continue
		if skill_id in result:
			continue
		result.append(skill_id)
		if result.size() >= MAX_SLOTS:
			break
	return result
