extends RefCounted

const MISSION_LEDGER := preload("res://src/systems/mission_ledger.gd")

# Select namespace before progression reads; never migrate guest data silently.
static var user_id := ""
const FILES := ["stage_progress.cfg", "monster_collection.cfg", "team_loadout.cfg", "demon_skill_loadout.cfg", "shop_summon_history.cfg"]
static var files: Dictionary = {}
static var revision := 0
static var dirty := false
static var serial := 0
static var saved_callback := Callable()
static var write_allowed := Callable()
static var pending_cloud: Dictionary = {}
const GUEST_TRANSACTION := "user://gameplay_transaction.json"
static var guest_directory := "user://" # Tests use an isolated directory.

static func _guest_path(path: String) -> String:
	return guest_directory.path_join(path.get_file())

static func select_account(id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
	if pattern.search(id) == null:
		return false
	if DirAccess.make_dir_recursive_absolute("user://accounts/" + id.to_lower()) != OK:
		return false
	user_id = id.to_lower()
	files = {}
	revision = 0
	dirty = false
	serial = 0
	pending_cloud = {}
	var cache: Variant = JSON.parse_string(FileAccess.get_file_as_string(resolve("user://save_bundle.json"))) if FileAccess.file_exists(resolve("user://save_bundle.json")) else null
	if FileAccess.file_exists(resolve("user://save_bundle.json")) and (not cache is Dictionary or not valid_payload(cache.get("files"))):
		return false # Never silently replace a corrupt save with older/default data.
	if cache is Dictionary and valid_payload(cache.get("files")):
		files = cache.files
		revision = int(cache.get("revision", 0))
		dirty = bool(cache.get("dirty", false))
		serial = int(cache.get("serial", 0))
		var pending: Variant = cache.get("pending_cloud", {})
		if _valid_pending(pending):
			pending_cloud = pending
			# JSON cache numbers are floats, including bigint RPC arguments.
			pending_cloud["expected_revision"] = int(pending_cloud.expected_revision)
			pending_cloud["serial"] = int(pending_cloud.serial)
			pending_cloud["sent"] = bool(pending.get("sent", true))
			dirty = true
	else:
		# Import only this verified UUID's existing files, never legacy guest data.
		for name in FILES:
			var config := ConfigFile.new()
			if config.load(resolve("user://" + name)) == OK:
				files[name] = _config_data(config)
				dirty = true
	return true

static func select_guest() -> void:
	user_id = ""
	files = {}
	revision = 0
	dirty = false
	serial = 0
	pending_cloud = {}

static func resolve(legacy_path: String) -> String:
	return legacy_path if user_id.is_empty() else "user://accounts/%s/%s" % [user_id, legacy_path.get_file()]

static func load_config(config: ConfigFile, path: String) -> Error:
	if user_id.is_empty():
		var recovery := _recover_guest_transaction()
		if recovery != OK:
			return recovery
		return config.load(_guest_path(path))
	config.clear()
	var name := path.get_file()
	if not files.has(name):
		return ERR_FILE_NOT_FOUND
	for section in files[name]:
		for key in files[name][section]:
			config.set_value(section, key, files[name][section][key])
	return OK

static func save_config(config: ConfigFile, path: String) -> Error:
	if not user_id.is_empty() and write_allowed.is_valid() and not write_allowed.call():
		return ERR_BUSY
	if path.get_file() == "stage_progress.cfg":
		return save_configs({"stage_progress.cfg": config})
	if user_id.is_empty():
		var recovery := _recover_guest_transaction()
		if recovery != OK:
			return recovery
		return config.save(_guest_path(path))
	var name := path.get_file()
	if name not in FILES:
		return ERR_INVALID_PARAMETER
	var previous := files.duplicate(true)
	files[name] = _config_data(config)
	var was_dirty := dirty
	var old_pending := pending_cloud
	dirty = true
	serial += 1
	_stage_cloud_request()
	var error := persist()
	if error != OK:
		files = previous
		dirty = was_dirty
		pending_cloud = old_pending
		serial -= 1
	elif saved_callback.is_valid():
		saved_callback.call()
	return error

# Award conversions change collection and research together. Account bundles
# commit once; guest cfg files use a replayable write-ahead journal.
static func save_configs(configs: Dictionary, write_missions: bool = false) -> Error:
	if not user_id.is_empty() and write_allowed.is_valid() and not write_allowed.call():
		return ERR_BUSY
	var data := {}
	for name in configs:
		if name not in FILES or not configs[name] is ConfigFile:
			return ERR_INVALID_PARAMETER
		data[name] = _config_data(configs[name])
	if not valid_payload(data):
		return ERR_INVALID_DATA
	if data.has("stage_progress.cfg"):
		var previous_data: Dictionary
		if user_id.is_empty():
			var previous_progress := ConfigFile.new()
			var read_error := load_config(previous_progress, "user://stage_progress.cfg")
			if read_error not in [OK, ERR_FILE_NOT_FOUND]:
				return read_error
			previous_data = _config_data(previous_progress)
		else:
			previous_data = files.get("stage_progress.cfg", {})
		# Work on serialized copies. Failed saves must not mutate the caller's
		# ConfigFile or count its acquisition again when it retries.
		MISSION_LEDGER.capture(data["stage_progress.cfg"], previous_data, int(Time.get_unix_time_from_system()), write_missions)
		if not valid_payload(data):
			return ERR_INVALID_DATA
	if user_id.is_empty():
		var recovery := _recover_guest_transaction()
		if recovery != OK:
			return recovery
		var journal := _guest_path(GUEST_TRANSACTION)
		var file := FileAccess.open(journal + ".tmp", FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(JSON.stringify(data))
		file.flush()
		file.close()
		var error := DirAccess.rename_absolute(journal + ".tmp", journal)
		return _recover_guest_transaction() if error == OK else error
	var previous := files.duplicate(true)
	var was_dirty := dirty
	var old_pending := pending_cloud
	files.merge(data, true)
	dirty = true
	serial += 1
	_stage_cloud_request()
	var error := persist()
	if error != OK:
		files = previous
		dirty = was_dirty
		pending_cloud = old_pending
		serial -= 1
	elif saved_callback.is_valid():
		saved_callback.call()
	return error

static func _recover_guest_transaction() -> Error:
	var journal := _guest_path(GUEST_TRANSACTION)
	if not FileAccess.file_exists(journal):
		return OK
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(journal))
	if not valid_payload(data):
		return ERR_INVALID_DATA
	for name in data:
		var config := ConfigFile.new()
		for section in data[name]:
			for key in data[name][section]:
				config.set_value(section, key, data[name][section][key])
		var error := config.save(_guest_path(name))
		if error != OK:
			return error
	return DirAccess.remove_absolute(journal)

static func _config_data(config: ConfigFile) -> Dictionary:
	var data := {}
	for section in config.get_sections():
		data[section] = {}
		for key in config.get_section_keys(section):
			var value = config.get_value(section, key)
			# Legacy encounter cfgs use packed strings; JSON stores plain arrays.
			data[section][key] = Array(value) if value is PackedStringArray else value
	return data

static func valid_payload(value: Variant) -> bool:
	if not value is Dictionary or JSON.stringify(value).to_utf8_buffer().size() > 1000000 or not _json_safe(value):
		return false
	for name in value:
		if name not in FILES or not value[name] is Dictionary:
			return false
		for section in value[name]:
			if not section is String or not value[name][section] is Dictionary:
				return false
	return true

static func _json_safe(value: Variant, depth: int = 0) -> bool:
	if depth > 24:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not _json_safe(item, depth + 1):
					return false
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _json_safe(value[key], depth + 1):
					return false
		_:
			return false
	return true

static func _stage_cloud_request() -> void:
	if not pending_cloud.is_empty():
		if not bool(pending_cloud.get("sent", true)):
			pending_cloud["new_payload"] = files.duplicate(true)
			pending_cloud["serial"] = serial
		return
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var operation := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	pending_cloud = {"operation_id": operation, "expected_revision": revision,
		"new_payload": files.duplicate(true), "serial": serial, "sent": false}

static func _valid_pending(value: Variant) -> bool:
	if not value is Dictionary or not valid_payload(value.get("new_payload")): return false
	if value.get("expected_revision") != revision or not value.get("operation_id") is String: return false
	var number: Variant = value.get("serial")
	if not (number is int or number is float) or not is_finite(float(number)) or float(number) != floor(float(number)) or number < 0 or number > serial: return false
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
	return pattern.search(value.operation_id) != null

static func persist() -> Error:
	if user_id.is_empty():
		return ERR_UNCONFIGURED
	if not valid_payload(files):
		return ERR_INVALID_DATA
	var target := resolve("user://save_bundle.json")
	var temporary := target + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"files": files, "revision": revision, "dirty": dirty, "serial": serial, "pending_cloud": pending_cloud}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(temporary, target)

static func install(remote: Dictionary, version: int) -> bool:
	if not valid_payload(remote):
		return false
	# Preserve the first pre-cloud copy permanently, including unsent progress.
	var target := resolve("user://save_bundle.json")
	if FileAccess.file_exists(target) and not FileAccess.file_exists(target + ".before_cloud.bak") and DirAccess.copy_absolute(target, target + ".before_cloud.bak") != OK:
		return false
	if (dirty or not pending_cloud.is_empty()) and FileAccess.file_exists(target):
		if DirAccess.copy_absolute(target, target + ".unsent_before_cloud.bak") != OK: return false
	var old_files := files
	var old_revision := revision
	var old_dirty := dirty
	var old_pending := pending_cloud
	pending_cloud = {}
	files = remote.duplicate(true)
	revision = version
	dirty = false
	if persist() != OK:
		files = old_files
		revision = old_revision
		dirty = old_dirty
		pending_cloud = old_pending
		return false
	return true

