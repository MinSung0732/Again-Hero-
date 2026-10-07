extends RefCounted
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const DATA := preload("res://src/data/transcendence_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SAVE_PATH := "user://team_loadout.cfg"
const LEGACY_PATH := "user://transcendence_loadout.cfg"
const SECTION := "transcendence"

static func load_id() -> String:
	var config := ConfigFile.new()
	var result := SCOPE.load_config(config,SAVE_PATH)
	var id := ""
	if result == OK and config.has_section_key(SECTION,"monster_id"):
		id = String(config.get_value(SECTION,"monster_id",""))
	elif result == OK or result == ERR_FILE_NOT_FOUND:
		var legacy := ConfigFile.new()
		if SCOPE.load_config(legacy,LEGACY_PATH) == OK:
			id = String(legacy.get_value("loadout","monster_id",""))
	return id if DATA.is_transcendent(id) and COLLECTION.is_unlocked(id) and DATA.MONSTERS.get_scene(id) != null else ""

static func save_id(id: String) -> bool:
	if not id.is_empty() and (not DATA.is_transcendent(id) or not COLLECTION.is_unlocked(id) or DATA.MONSTERS.get_scene(id) == null):
		return false
	var config := ConfigFile.new()
	var result := SCOPE.load_config(config,SAVE_PATH)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		return false
	config.set_value(SECTION,"monster_id",id)
	return SCOPE.save_config(config,SAVE_PATH) == OK
