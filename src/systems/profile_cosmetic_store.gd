extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const APPEARANCE := preload("res://src/systems/demon_appearance_store.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const PATH := "user://stage_progress.cfg"
const SECTION := "profile_cosmetics"
const KEYS := {"avatar": "avatar_id", "banner": "banner_id"}

static func choices(slot: String) -> Array[String]:
	var result: Array[String] = []
	if not KEYS.has(slot):
		return result
	for id in APPEARANCE.owned_ids():
		var path := CATALOG.path(id, slot)
		if not path.is_empty() and FileAccess.file_exists(path):
			result.append(id)
	var state := COLLECTION.load_state()
	for id in CATALOG.MONSTER_REWARDS:
		var reward: Dictionary = CATALOG.MONSTER_REWARDS[id]
		var monster_id := String(reward.get("monster_id", ""))
		if MONSTERS.get_rarity(monster_id) != "transcendent" or not COLLECTION.is_unlocked(monster_id, state):
			continue
		if COLLECTION.get_upgrade_level(monster_id,state) < int(reward.get("min_upgrade_level",0)):
			continue
		var path := CATALOG.path(String(id), slot)
		if not path.is_empty() and FileAccess.file_exists(path) and String(id) not in result:
			result.append(String(id))
	return result

static func selected_id(slot: String) -> String:
	if not KEYS.has(slot):
		return ""
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var id := String(config.get_value(SECTION, KEYS[slot], ""))
	var available := choices(slot)
	if id in available:
		return id
	# Unset legacy profiles follow their existing equipped appearance.
	var fallback := PROFILE.appearance_id()
	return fallback if fallback in available else (available[0] if not available.is_empty() else "")

static func select(slot: String, id: String) -> bool:
	if not KEYS.has(slot) or id not in choices(slot):
		return false
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
		return false
	config.set_value(SECTION, KEYS[slot], id)
	return SCOPE.save_config(config, PATH) == OK
