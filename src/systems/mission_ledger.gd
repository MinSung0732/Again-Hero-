extends RefCounted

const RULES := preload("res://src/data/mission_catalog.gd")
const DAY := 86400
const KST := 32400

# Unix day 0 is Thursday. Fixed KST arithmetic avoids device timezone/DST.
static func period(tab: String, now: int) -> int:
	var day := int((maxi(now, 0) + KST) / DAY)
	return int(day / 7) if tab == "weekly" else day

static func normalize(state: Dictionary, now: int) -> Dictionary:
	for tab in RULES.TABS:
		var id: String = tab.id
		var current := period(id, now)
		var bucket: Variant = state.get(id, {})
		if not bucket is Dictionary or int(bucket.get("period", -1)) != current:
			state[id] = {"period": current, "counts": {}, "claimed": {}}
		else:
			if not bucket.has("counts") or not bucket.counts is Dictionary:
				bucket.counts = {}
			if not bucket.has("claimed") or not bucket.claimed is Dictionary:
				bucket.claimed = {}
			for index in RULES.EVENTS.size():
				var event: String = RULES.EVENTS[index]
				var value: Variant = bucket.counts.get(event, 0)
				bucket.counts[event] = minf(maxf(float(value), 0), float(tab.targets[index])) if (value is int or value is float) and is_finite(float(value)) else 0.0
				bucket.claimed[event] = bucket.claimed.get(event, false) == true
	return state

static func record(state: Dictionary, event: String, amount: float, now: int) -> void:
	var index := RULES.EVENTS.find(event)
	if index < 0 or not is_finite(amount) or amount <= 0:
		return
	# Called per successful action, never per frame. Counts cap at each target.
	normalize(state, now)
	for tab in RULES.TABS:
		var counts: Dictionary = state[tab.id].counts
		counts[event] = minf(maxf(float(counts.get(event, 0)), 0) + amount, float(tab.targets[index]))

static func merge(state: Dictionary, pending: Dictionary, now: int) -> void:
	normalize(state, now)
	for tab in RULES.TABS:
		var bucket: Dictionary = pending.get(tab.id, {})
		if int(bucket.get("period", -1)) != period(tab.id, now):
			continue # Expired actions never spill into a new day/week.
		for index in RULES.EVENTS.size():
			var event: String = RULES.EVENTS[index]
			var counts: Dictionary = state[tab.id].counts
			counts[event] = minf(float(tab.targets[index]), maxf(float(counts.get(event, 0)), 0) + float(bucket.get("counts", {}).get(event, 0)))

# Capture wallet/acquisition changes in the SAME transaction as their source.
# Never capture cloud import/old saves: these are only invoked on local writes.
static func capture(data: Dictionary, previous: Dictionary, now: int, write_missions: bool = false) -> void:
	# Unrelated callers may reuse a ConfigFile or build one without mission keys.
	# Only MissionStore explicitly writes markers/counts; wallet writes always
	# start from the latest committed ledger, preventing stale-state erasure.
	var section: Dictionary = (data.get("missions", {}) if write_missions else previous.get("missions", {})).duplicate(true)
	var saved: Variant = section.get("state", {})
	var state: Dictionary = saved.duplicate(true) if saved is Dictionary else {}
	var research := float(data.get("meta", {}).get("research_points", 0)) - float(previous.get("meta", {}).get("research_points", 0))
	var draws := int(data.get("monster_gacha", {}).get("total_draws", 0)) - int(previous.get("monster_gacha", {}).get("total_draws", 0))
	record(state, "research", research, now)
	record(state, "gacha", draws, now)
	var stamina: Dictionary = data.get("stamina", {})
	var old: Dictionary = previous.get("stamina", {})
	if bool(stamina.get("active_claimed", false)) and (not bool(old.get("active_claimed", false)) or int(stamina.get("active_entry", 0)) != int(old.get("active_entry", 0))):
		record(state, "stamina", float(stamina.get("active_charged", 0)), now)
	section["state"] = state
	data["missions"] = section
