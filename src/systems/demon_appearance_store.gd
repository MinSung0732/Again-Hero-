extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CATALOG := preload("res://src/data/demon_appearance_catalog.gd")
const PROFILE_DATA := preload("res://src/data/player_profile_catalog.gd")
const PATH := PROFILE_DATA.PATH
const SECTION := "demon_appearance"

static func owned_ids() -> Array[String]:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	return _owned_from_config(config)

static func _initial_id(config: ConfigFile) -> String:
	# Read the registration gender directly to avoid PROFILE -> APPEARANCE cycles.
	var profile: Variant = config.get_value(PROFILE_DATA.SECTION, PROFILE_DATA.VALUE_KEY, {})
	return CATALOG.default_id(PROFILE_DATA.gender_id(profile) if profile is Dictionary else PROFILE_DATA.GENDERS.DEFAULT_ID)

static func _owned_from_config(config: ConfigFile) -> Array[String]:
	var result: Array[String] = []
	var initial_id := _initial_id(config)
	var local_owned: Variant = config.get_value(SECTION, "local_owned", [])
	for id in CATALOG.ORDER:
		var entry := CATALOG.get_entry(id)
		# Local unlocks are preview-only. Paid/social entitlements need a server
		# ledger before a real cosmetic gacha is connected; snapshot data is not proof.
		var initial_gender := String(entry.get("initial_gender", ""))
		if id == initial_id or (initial_gender.is_empty() and (bool(entry.get("default_owned", false)) or (SCOPE.user_id.is_empty() and local_owned is Array and id in local_owned))):
			result.append(id)
	return result

static func equipped_id(_gender: String = "") -> String:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var id := String(config.get_value(SECTION, "equipped_id", ""))
	# Old saves may have equipped the other formerly-free default. Fall back
	# without changing the server-confirmed profile gender or writing on every read.
	return id if id in _owned_from_config(config) else _initial_id(config)

static func equip(id: String) -> bool:
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
		return false
	if id not in _owned_from_config(config) or CATALOG.path(id, "avatar").is_empty() or CATALOG.path(id).is_empty():
		return false
	if config.get_value(SECTION, "equipped_id", "") == id:
		return true
	config.set_value(SECTION, "equipped_id", id)
	return SCOPE.save_config(config, PATH) == OK

static func grant_local_preview(id: String) -> bool:
	# Future gacha development hook, never awards a social account entitlement.
	if not SCOPE.user_id.is_empty() or CATALOG.get_entry(id).is_empty():
		return false
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
		return false
	if not String(CATALOG.get_entry(id).get("initial_gender", "")).is_empty() and id != _initial_id(config):
		return false # The other initial gender is not a preview entitlement.
	var raw: Variant = config.get_value(SECTION, "local_owned", [])
	var owned: Array = raw.duplicate() if raw is Array else []
	if id not in owned:
		owned.append(id)
	config.set_value(SECTION, "local_owned", owned)
	return SCOPE.save_config(config, PATH) == OK
