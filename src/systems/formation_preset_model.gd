extends RefCounted

# Reserved stable keys; storage and switching UI are intentionally not enabled.
const SCHEMA_VERSION := 1
const PRESET_IDS := ["preset_1", "preset_2", "preset_3"]

static func snapshot(monsters: Array, skills: Array) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"monster_ids": monsters.duplicate(),
		"skill_ids": skills.duplicate(),
	}

static func normalize(raw: Dictionary, valid_monsters: Array, valid_skills: Array, max_slots: int = 3) -> Dictionary:
	return snapshot(
		_ids(raw.get("monster_ids", []), valid_monsters, max_slots),
		_ids(raw.get("skill_ids", []), valid_skills, max_slots)
	)

static func _ids(raw: Variant, valid: Array, limit: int) -> Array:
	var result: Array = []
	if typeof(raw) != TYPE_ARRAY or limit <= 0:
		return result
	for value in raw:
		if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
			continue
		var id := String(value)
		if id in valid and id not in result:
			result.append(id)
		if result.size() >= limit:
			break
	return result
