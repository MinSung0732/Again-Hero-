extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CATALOG := preload("res://src/data/demon_appearance_catalog.gd")
const PATH := "user://stage_progress.cfg"
const SECTION := "demon_appearance"

static func owned_ids() -> Array[String]:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var result: Array[String] = []
	var local_owned: Variant = config.get_value(SECTION, "local_owned", [])
	for id in CATALOG.ORDER:
		var entry := CATALOG.get_entry(id)
		# Local unlocks are preview-only. Paid/social entitlements need a server
		# ledger before a real cosmetic gacha is connected; snapshot data is not proof.
		if bool(entry.get("default_owned", false)) or (SCOPE.user_id.is_empty() and local_owned is Array and id in local_owned):
			result.append(id)
	return result

static func equipped_id(gender: String) -> String:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PATH)
	var id := String(config.get_value(SECTION, "equipped_id", ""))
	return id if id in owned_ids() else CATALOG.default_id(gender)

static func equip(id: String) -> bool:
	if id not in owned_ids() or CATALOG.path(id, "avatar").is_empty() or CATALOG.path(id).is_empty():
		return false
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
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
	var raw: Variant = config.get_value(SECTION, "local_owned", [])
	var owned: Array = raw.duplicate() if raw is Array else []
	if id not in owned:
		owned.append(id)
	config.set_value(SECTION, "local_owned", owned)
	return SCOPE.save_config(config, PATH) == OK
