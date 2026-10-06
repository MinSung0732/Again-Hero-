extends RefCounted

const RULES := preload("res://src/data/stamina_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SAVE_PATH := "user://stage_progress.cfg"
const SECTION := "stamina"
static var _cache_owner := ""
static var _cache_serial := -1
static var _cache_revision := -1
static var _cache_valid := false
static var _amount := RULES.INITIAL_AMOUNT
static var _anchor := 0

static func _owner() -> String:
	return SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:" + SCOPE.guest_directory

static func _now(value: int) -> int:
	return maxi(value if value >= 0 else int(Time.get_unix_time_from_system()), 0)

static func invalidate() -> void:
	_cache_valid = false

# Pure arithmetic: one calculation even after months offline; never loop per hour.
static func resolve(amount: int, anchor: int, now: int) -> Dictionary:
	amount = maxi(amount, 0)
	anchor = maxi(anchor, 0)
	if amount >= RULES.MAX_NATURAL:
		return {"amount": amount, "recovery_at": now, "next_seconds": 0, "full_seconds": 0}
	var ticks := maxi(now - anchor, 0) / RULES.RECOVERY_SECONDS
	amount = mini(amount + ticks, RULES.MAX_NATURAL)
	if amount >= RULES.MAX_NATURAL:
		return {"amount": amount, "recovery_at": now, "next_seconds": 0, "full_seconds": 0}
	anchor += ticks * RULES.RECOVERY_SECONDS
	var next := maxi(anchor + RULES.RECOVERY_SECONDS - now, 1)
	return {"amount": amount, "recovery_at": anchor, "next_seconds": next,
		"full_seconds": next + (RULES.MAX_NATURAL - amount - 1) * RULES.RECOVERY_SECONDS}

static func _load(config: ConfigFile) -> Error:
	var error := SCOPE.load_config(config, SAVE_PATH)
	return OK if error == ERR_FILE_NOT_FOUND else error

static func _from_config(config: ConfigFile, now: int) -> Dictionary:
	return resolve(int(config.get_value(SECTION, "amount", RULES.INITIAL_AMOUNT)),
		int(config.get_value(SECTION, "recovery_at", now)), now)

static func read_state(at: int = -1) -> Dictionary:
	var now := _now(at)
	var owner := _owner()
	if not _cache_valid or owner != _cache_owner or _cache_serial != SCOPE.serial or _cache_revision != SCOPE.revision:
		var config := ConfigFile.new()
		if _load(config) != OK:
			return {"success": false, "amount": 0, "next_seconds": 0, "full_seconds": 0}
		_amount = maxi(int(config.get_value(SECTION, "amount", RULES.INITIAL_AMOUNT)), 0)
		_anchor = int(config.get_value(SECTION, "recovery_at", now))
		_cache_owner = owner
		_cache_serial = SCOPE.serial
		_cache_revision = SCOPE.revision
		_cache_valid = true
	var state := resolve(_amount, _anchor, now)
	state["success"] = true
	return state

static func _commit(config: ConfigFile, state: Dictionary) -> bool:
	config.set_value(SECTION, "version", 1)
	config.set_value(SECTION, "amount", int(state.amount))
	config.set_value(SECTION, "recovery_at", int(state.recovery_at))
	# Existing account bundle / guest write-ahead journal commits all keys together.
	var success := SCOPE.save_configs({"stage_progress.cfg": config}) == OK
	invalidate()
	return success

# All ordinary lobby/retry/next-stage entries use the same atomic debit + stage write.
static func try_enter(stage_id: String, exempt: bool = false, at: int = -1) -> Dictionary:
	if stage_id.is_empty():
		return {"success": false, "reason": "invalid"}
	var config := ConfigFile.new()
	if _load(config) != OK:
		return {"success": false, "reason": "save_failed"}
	var now := _now(at)
	var state := _from_config(config, now)
	var cost: int = 0 if exempt else RULES.ENTRY_COST
	if int(state.amount) < cost:
		return {"success": false, "reason": "insufficient", "amount": state.amount}
	var old_stage := String(config.get_value("progress", "current_stage_id", "stage_1"))
	state.amount -= cost
	var entry_id := int(config.get_value(SECTION, "entry_serial", 0)) + 1
	config.set_value(SECTION, "entry_serial", entry_id)
	config.set_value(SECTION, "active_entry", entry_id)
	config.set_value(SECTION, "active_charged", cost)
	config.set_value(SECTION, "active_stage", stage_id)
	config.set_value(SECTION, "active_claimed", false)
	config.set_value("progress", "current_stage_id", stage_id)
	if not _commit(config, state):
		return {"success": false, "reason": "save_failed"}
	return {"success": true, "amount": state.amount, "charged": cost, "owner": _owner(),
		"entry_id": entry_id, "stage_id": stage_id, "previous_stage": old_stage}

# Call only after a verified gift/reward/purchase. Stable source ID prevents retries
# from crediting twice. This is a wallet hook, not a payment/entitlement verifier.
static func grant(amount: int, grant_id: String, at: int = -1) -> Dictionary:
	if amount <= 0 or grant_id.is_empty() or grant_id.length() > 160:
		return {"success": false, "reason": "invalid"}
	var config := ConfigFile.new()
	if _load(config) != OK:
		return {"success": false, "reason": "save_failed"}
	if config.has_section_key("stamina_grants", grant_id):
		return {"success": true, "reason": "already_granted", "granted": 0}
	var now := _now(at)
	var state := _from_config(config, now)
	state.amount += amount
	if int(state.amount) >= RULES.MAX_NATURAL:
		state.recovery_at = now
	config.set_value("stamina_grants", grant_id, amount)
	if not _commit(config, state):
		return {"success": false, "reason": "save_failed"}
	return {"success": true, "reason": "granted", "granted": amount, "amount": state.amount}

static func refund_failed_entry(entry: Dictionary, at: int = -1) -> bool:
	if not bool(entry.get("success", false)) or String(entry.get("owner", "")) != _owner():
		return false
	var cost := int(entry.get("charged", 0))
	if cost == 0:
		return true
	var config := ConfigFile.new()
	if _load(config) != OK:
		return false
	var key := "entry_refund:" + str(entry.get("entry_id", -1))
	if config.has_section_key("stamina_grants", key):
		return true
	var now := _now(at)
	var state := _from_config(config, now)
	state.amount += cost
	if int(state.amount) >= RULES.MAX_NATURAL:
		state.recovery_at = now
	if String(config.get_value("progress", "current_stage_id", "")) == String(entry.get("stage_id", "")):
		config.set_value("progress", "current_stage_id", String(entry.get("previous_stage", "stage_1")))
	config.set_value("stamina_grants", key, cost)
	return _commit(config, state)

# Consume the accepted entry ticket only once when the destination Main is ready.
# Direct F6/reloads cannot attach themselves to an already used entry.
static func claim_battle_entry(stage_id: String) -> Dictionary:
	var config := ConfigFile.new()
	if _load(config) != OK or bool(config.get_value(SECTION, "active_claimed", true)):
		return {}
	var id := int(config.get_value(SECTION, "active_entry", 0))
	if id <= 0 or String(config.get_value(SECTION, "active_stage", "")) != stage_id or config.has_section_key("stamina_grants", "entry_refund:" + str(id)):
		return {}
	var cost := int(config.get_value(SECTION, "active_charged", 0))
	config.set_value(SECTION, "active_claimed", true)
	if SCOPE.save_configs({"stage_progress.cfg": config}) != OK:
		return {}
	return {"entry_id": id, "charged": cost, "owner": _owner()}

static func refund_early_exit(entry: Dictionary, elapsed_ms: int, at: int = -1) -> Dictionary:
	if entry.is_empty() or String(entry.get("owner", "")) != _owner() or int(entry.get("charged", 0)) != RULES.ENTRY_COST or elapsed_ms < 0 or elapsed_ms > RULES.EARLY_EXIT_WINDOW_MS:
		return {"success": true, "refunded": 0}
	var config := ConfigFile.new()
	if _load(config) != OK:
		return {"success": false, "refunded": 0}
	var id := int(entry.get("entry_id", 0))
	if id <= 0 or int(config.get_value(SECTION, "active_entry", 0)) != id or not bool(config.get_value(SECTION, "active_claimed", false)):
		return {"success": true, "refunded": 0}
	var key := "entry_refund:" + str(id) # Full load-failure and early refunds share a receipt.
	if config.has_section_key("stamina_grants", key):
		return {"success": true, "refunded": 0}
	var now := _now(at)
	var state := _from_config(config, now)
	state.amount += RULES.EARLY_EXIT_REFUND
	if int(state.amount) >= RULES.MAX_NATURAL:
		state.recovery_at = now
	config.set_value("stamina_grants", key, RULES.EARLY_EXIT_REFUND)
	if not _commit(config, state):
		return {"success": false, "refunded": 0}
	return {"success": true, "refunded": RULES.EARLY_EXIT_REFUND}
