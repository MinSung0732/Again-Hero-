extends RefCounted

const CLOCK := preload("res://src/systems/server_clock.gd")

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const RULES := preload("res://src/data/exploration_reward_catalog.gd")
const SAVE_PATH := "user://stage_progress.cfg"
const SECTION := "exploration_rewards"

static func _load(config: ConfigFile) -> Error:
	var error := SCOPE.load_config(config, SAVE_PATH)
	return OK if error == ERR_FILE_NOT_FOUND else error

static func _now(value: int) -> int:
	return maxi(value if value >= 0 else CLOCK.now(), 0)

static func _seconds(config: ConfigFile) -> int:
	return clampi(int(config.get_value(SECTION, "seconds", 0)), 0, RULES.MAX_SECONDS)

static func preview(seconds: int) -> Dictionary:
	seconds = clampi(seconds, 0, RULES.MAX_SECONDS)
	var percent := int(seconds / RULES.SECONDS_PER_PERCENT)
	return {"success": true, "seconds": seconds, "percent": percent,
		"gold": percent * RULES.GOLD_PER_PERCENT,
		"research": percent * RULES.RESEARCH_PER_PERCENT,
		"can_claim": percent > RULES.MIN_PERCENT_EXCLUSIVE,
		"full": percent >= RULES.MAX_PERCENT}

static func snapshot() -> Dictionary:
	var config := ConfigFile.new()
	var error := _load(config)
	return preview(_seconds(config)) if error == OK else {"success": false, "error": error}

# accrue=true only on app launch/resume. Foreground checkpoints never add time.
# Preserve all wallet/progress/stamina sections by updating one loaded config.
static func checkpoint(accrue: bool, now: int = -1) -> Error:
	if now < 0 and not CLOCK.allowed(): return ERR_BUSY
	var config := ConfigFile.new()
	var error := _load(config)
	if error != OK:
		return error
	var explicit_time := now >= 0
	now = _now(now)
	var anchor := maxi(int(config.get_value(SECTION, "anchor", now)), 0)
	if not explicit_time: anchor = mini(anchor, now)
	var seconds := _seconds(config)
	if accrue:
		seconds = mini(seconds + maxi(now - anchor, 0), RULES.MAX_SECONDS)
	config.set_value(SECTION, "seconds", seconds)
	# A backwards clock must not create another earnable interval.
	config.set_value(SECTION, "anchor", maxi(anchor, now) if explicit_time else now)
	return SCOPE.save_config(config, SAVE_PATH)

static func claim(now: int = -1) -> Dictionary:
	if now < 0 and not CLOCK.allowed(): return {"success": false, "reason": "clock_pending"}
	var config := ConfigFile.new()
	var error := _load(config)
	if error != OK:
		return {"success": false, "reason": "save_failed", "error": error}
	var reward := preview(_seconds(config))
	if not reward.can_claim:
		return {"success": false, "reason": "below_threshold"}
	var gold := maxi(int(config.get_value("meta", "gold", 0)), 0)
	var research := maxi(int(config.get_value("meta", "research_points", 0)), 0)
	config.set_value("meta", "gold", gold + int(reward.gold))
	config.set_value("meta", "research_points", research + int(reward.research))
	config.set_value(SECTION, "seconds", 0)
	config.set_value(SECTION, "anchor", _now(now))
	# Currency and consumed time commit together. No separate grant/reset writes.
	error = SCOPE.save_config(config, SAVE_PATH)
	return {"success": true, "gold": reward.gold, "research": reward.research} if error == OK else {"success": false, "reason": "save_failed", "error": error}
