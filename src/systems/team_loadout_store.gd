extends RefCounted
class_name TeamLoadoutStore

const SAVE_PATH := "user://team_loadout.json"
const MAX_SLOTS := 3

static func load_ids(
	valid_ids: Array[String],
	fallback_ids: Array[String]
) -> Array[String]:
	var saved_value: Variant = null

	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			saved_value = JSON.parse_string(file.get_as_text())

	var normalized := _normalize_ids(saved_value, valid_ids)
	if normalized.is_empty():
		normalized = _normalize_ids(fallback_ids, valid_ids)

	return normalized

static func save_ids(
	monster_ids: Array[String],
	valid_ids: Array[String]
) -> bool:
	var normalized := _normalize_ids(monster_ids, valid_ids)
	if normalized.is_empty():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(normalized))
	return true

static func _normalize_ids(
	raw_value: Variant,
	valid_ids: Array[String]
) -> Array[String]:
	var result: Array[String] = []
	if not (raw_value is Array):
		return result

	for raw_id in raw_value:
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
