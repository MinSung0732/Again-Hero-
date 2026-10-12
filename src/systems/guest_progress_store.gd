extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PATH := "user://stage_progress.cfg"
const CLAIM_FILE := "guest_claim.cfg"
static var _id_directory := ""
static var _cached_guest_id := ""

static func is_guest() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var mode := tree.root.get_node_or_null("LocalTestMode") if tree != null else null
	return mode != null and SCOPE.user_id.is_empty() and not mode.active and not mode.tutorial_preview and SCOPE.guest_directory != mode.test_directory

static func guest_id() -> String:
	if not is_guest(): return ""
	if _id_directory == SCOPE.guest_directory and not _cached_guest_id.is_empty(): return _cached_guest_id
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]: return ""
	var id := String(config.get_value("guest_identity", "id", ""))
	if id.is_empty():
		var hex := Crypto.new().generate_random_bytes(16).hex_encode()
		id = "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
		config.set_value("guest_identity", "id", id)
		if SCOPE.save_config(config, PATH) != OK: return ""
	_id_directory = SCOPE.guest_directory
	_cached_guest_id = id
	return id

static func capture() -> Dictionary:
	var id := guest_id()
	if id.is_empty(): return {}
	var claim := ConfigFile.new()
	if claim.load(SCOPE.guest_directory.path_join(CLAIM_FILE)) == OK and claim.get_value("claim", "guest_id", "") == id:
		return {} # A successful transfer consumes this guest identity.
	var payload := {}
	for name in SCOPE.FILES:
		var config := ConfigFile.new()
		var error := SCOPE.load_config(config, "user://" + name)
		if error == ERR_FILE_NOT_FOUND: continue
		if error != OK: return {}
		payload[name] = SCOPE._config_data(config)
	return {"guest_id": id, "directory": SCOPE.guest_directory, "payload": payload} if SCOPE.valid_payload(payload) else {}

static func mark_consumed(directory: String, id: String, owner: String) -> bool:
	var config := ConfigFile.new()
	config.set_value("claim", "guest_id", id)
	config.set_value("claim", "account_id", owner)
	return config.save(directory.path_join(CLAIM_FILE)) == OK

static func reset() -> bool:
	if not is_guest(): return false
	var configs := {}
	for name in SCOPE.FILES: configs[name] = ConfigFile.new()
	var progress: ConfigFile = configs["stage_progress.cfg"]
	progress.set_value("progress", "current_stage_id", "stage_1")
	progress.set_value("progress", "highest_unlocked_stage", 1)
	progress.set_value("meta", "gold", 0)
	progress.set_value("meta", "research_points", 0)
	if SCOPE.save_configs(configs) != OK: return false
	_id_directory = ""
	_cached_guest_id = ""
	return not guest_id().is_empty()

static func ensure_available() -> bool:
	if not is_guest(): return true
	var id := guest_id()
	if id.is_empty(): return false
	var claim := ConfigFile.new()
	return reset() if claim.load(SCOPE.guest_directory.path_join(CLAIM_FILE)) == OK and claim.get_value("claim", "guest_id", "") == id else true

static func tutorial_operation(action: String) -> Dictionary:
	if not is_guest() or action not in ["read", "start", "skip", "complete"]: return {}
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PATH) != OK: return {}
	var profile: Dictionary = config.get_value("player_profile", "value", {})
	if not bool(profile.get("completed", false)): return {"ok": false, "error": "profile_required"}
	var status := String(config.get_value("guest_tutorial", "status", "pending"))
	var claimed := bool(config.get_value("guest_tutorial", "claimed", false))
	if action == "read": return {"ok": true, "status": status, "reward_claimed": claimed}
	if action == "start" and status == "pending": status = "active"
	if action in ["skip", "complete"] and not claimed:
		if action == "complete" and status != "active": return {}
		status = "skipped" if action == "skip" else "completed"
		claimed = true
		config.set_value("meta", "gold", int(config.get_value("meta", "gold", 0)) + preload("res://src/data/tutorial_catalog.gd").REWARD)
	config.set_value("guest_tutorial", "status", status)
	config.set_value("guest_tutorial", "claimed", claimed)
	if SCOPE.save_config(config, PATH) != OK: return {}
	return {"ok": true, "status": status, "reward_claimed": claimed}
