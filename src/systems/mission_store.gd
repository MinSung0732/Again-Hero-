extends RefCounted

const RULES := preload("res://src/data/mission_catalog.gd")
const LEDGER := preload("res://src/systems/mission_ledger.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
static var pending: Dictionary = {}
static var pending_owner := ""

static func owner() -> String:
	return SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:" + SCOPE.guest_directory

static func now() -> int:
	return int(Time.get_unix_time_from_system())

static func _check_owner() -> void:
	if pending_owner != owner():
		pending.clear()
		pending_owner = owner()

static func record(event: String, amount: float, at: int = -1) -> void:
	_check_owner()
	LEDGER.record(pending, event, amount, now() if at < 0 else at)

static func _load(config: ConfigFile) -> bool:
	return SCOPE.load_config(config, RULES.SAVE_PATH) in [OK, ERR_FILE_NOT_FOUND]

static func _state(config: ConfigFile, at: int) -> Dictionary:
	var value: Variant = config.get_value("missions", "state", {})
	return LEDGER.normalize(value.duplicate(true) if value is Dictionary else {}, at)

static func flush(at: int = -1) -> bool:
	_check_owner()
	if pending.is_empty():
		return true
	var config := ConfigFile.new()
	if not _load(config):
		return false
	var timestamp := now() if at < 0 else at
	var state := _state(config, timestamp)
	LEDGER.merge(state, pending, timestamp)
	config.set_value("missions", "state", state)
	if SCOPE.save_configs({"stage_progress.cfg": config}, true) != OK:
		return false # Retain pending counts for a later retry.
	pending.clear()
	return true

static func snapshot(at: int = -1) -> Dictionary:
	_check_owner()
	var config := ConfigFile.new()
	if not _load(config):
		return {"success": false, "tabs": {}, "claimable": 0}
	var timestamp := now() if at < 0 else at
	var state := _state(config, timestamp)
	LEDGER.merge(state, pending, timestamp)
	var tabs := {}
	var claimable := 0
	for tab in RULES.TABS:
		var rows: Array = []
		for index in RULES.EVENTS.size():
			var id: String = RULES.EVENTS[index]
			var count := minf(float(state[tab.id].counts.get(id, 0)), float(tab.targets[index]))
			var claimed := bool(state[tab.id].claimed.get(id, false))
			var complete := count >= float(tab.targets[index])
			var rank := 2 if claimed else (0 if complete else 1)
			if rank == 0:
				claimable += 1
			rows.append({"id": id, "index": index, "count": count, "target": tab.targets[index], "claimed": claimed, "complete": complete, "rank": rank, "gold": tab.gold[index], "research": tab.research[index], "title": RULES.TITLES[index] % tab.targets[index]})
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.rank < b.rank or (a.rank == b.rank and a.index < b.index))
		tabs[tab.id] = rows
	return {"success": true, "tabs": tabs, "claimable": claimable}

static func claim(tab_id: String, mission_id: String = "", at: int = -1) -> Dictionary:
	var tab := RULES.tab(tab_id)
	if tab.is_empty() or (not mission_id.is_empty() and mission_id not in RULES.EVENTS):
		return {"success": false, "reason": "invalid"}
	var timestamp := now() if at < 0 else at
	if not flush(timestamp):
		return {"success": false, "reason": "save_failed"}
	var config := ConfigFile.new()
	if not _load(config):
		return {"success": false, "reason": "save_failed"}
	var state := _state(config, timestamp)
	var gold := 0
	var research := 0
	var count := 0
	for index in RULES.EVENTS.size():
		var id: String = RULES.EVENTS[index]
		if (not mission_id.is_empty() and id != mission_id) or bool(state[tab_id].claimed.get(id, false)) or float(state[tab_id].counts.get(id, 0)) < float(tab.targets[index]):
			continue
		state[tab_id].claimed[id] = true
		gold += int(tab.gold[index])
		research += int(tab.research[index])
		count += 1
	if count == 0:
		return {"success": false, "reason": "not_ready"}
	config.set_value("missions", "state", state)
	config.set_value("meta", "gold", maxi(int(config.get_value("meta", "gold", 0)), 0) + gold)
	config.set_value("meta", "research_points", maxi(int(config.get_value("meta", "research_points", 0)), 0) + research)
	# Claim markers and currencies commit once. Reward research also counts as
	# acquisition, but claim-all only processes the eligible rows of this snapshot.
	if SCOPE.save_configs({"stage_progress.cfg": config}, true) != OK:
		return {"success": false, "reason": "save_failed"}
	return {"success": true, "gold": gold, "research": research, "count": count}
