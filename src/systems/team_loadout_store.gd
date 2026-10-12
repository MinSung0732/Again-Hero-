extends RefCounted
class_name TeamLoadoutStore
const ACCOUNT_SCOPE := preload("res://src/systems/account_save_scope.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")

const SAVE_PATH := "user://team_loadout.cfg"
const MAX_SLOTS := 3

static func load_ids(valid_ids: Array, fallback_ids: Array) -> Array:
	var raw_ids: Array = []
	var config := ConfigFile.new()

	var has_saved_selection := false
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) == OK:
		has_saved_selection = config.has_section_key("team", "monster_ids")
		var encoded := String(
			config.get_value("team", "monster_ids", "")
		)
		if not encoded.is_empty():
			for raw_id in encoded.split(",", false):
				raw_ids.append(String(raw_id))

	var normalized := _normalize_ids(raw_ids, valid_ids)
	if normalized.is_empty() and not has_saved_selection:
		normalized = _normalize_ids(fallback_ids, valid_ids)

	return normalized

static func save_ids(monster_ids: Array, valid_ids: Array) -> bool:
	var normalized := _normalize_ids(monster_ids, valid_ids)

	var encoded := ""
	for monster_id in normalized:
		if not encoded.is_empty():
			encoded += ","
		encoded += String(monster_id)

	var config := ConfigFile.new()
	var result := ACCOUNT_SCOPE.load_config(config,SAVE_PATH)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		return false
	config.set_value("team", "monster_ids", encoded)
	return ACCOUNT_SCOPE.save_config(config, SAVE_PATH) == OK

static func _normalize_ids(raw_ids: Array, valid_ids: Array) -> Array:
	var result: Array = []

	for raw_id in raw_ids:
		var monster_id := String(raw_id)
		if monster_id.is_empty():
			continue
		if monster_id not in valid_ids:
			continue
		if MONSTERS.get_rarity(monster_id) == "transcendent":
			continue
		if monster_id in result:
			continue

		result.append(monster_id)
		if result.size() >= MAX_SLOTS:
			break

	return result

static func default_ids(valid_ids: Array) -> Array:
	var defaults: Array = []
	for raw_id in MONSTERS.ORDER:
		var id := String(raw_id)
		if id in valid_ids and MONSTERS.is_default_unlocked(id) and MONSTERS.get_rarity(id) != "transcendent":
			defaults.append(id)
			if defaults.size() >= MAX_SLOTS: break
	return defaults if not defaults.is_empty() else _normalize_ids(valid_ids,valid_ids)
