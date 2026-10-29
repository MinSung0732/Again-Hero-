extends RefCounted
const RULES := preload("res://src/online/match_rules.gd")
## Identity comes from authentication, never from a client's declared user ID.
var waiting := {"hero":[],"demon":[]}
var members := {}
func enqueue(peer: int,uid: String,role: String,tier_index: int = -1,now: float = -1.0) -> bool:
	if role not in waiting or members.has(peer) or uid.is_empty(): return false
	for entry in members.values():
		if entry.uid == uid: return false
	if now < 0.0: now = Time.get_ticks_msec() / 1000.0
	members[peer] = {"uid":uid,"role":role,"tier":tier_index,"since":now}; waiting[role].append(peer); return true
func remove(peer: int) -> void:
	if not members.has(peer): return
	waiting[members[peer].role].erase(peer); members.erase(peer)
func pair(now: float = -1.0) -> Array:
	if now < 0.0: now = Time.get_ticks_msec() / 1000.0
	var best_hero := -1; var best_demon := -1; var best_distance := 2147483647
	var best_since := INF; var best_other := INF
	for hero in waiting.hero:
		var h: Dictionary = members[hero]
		for demon in waiting.demon:
			var d: Dictionary = members[demon]
			if (h.tier < 0) != (d.tier < 0): continue
			var distance: int = 0 if h.tier < 0 else absi(h.tier - d.tier)
			if distance > RULES.MATCH_TIER_EXPAND_RANGE: continue
			if distance > 0 and now - minf(h.since,d.since) < RULES.MATCH_TIER_EXPAND_SECONDS: continue
			var oldest: float = float(h.since) if distance == 0 else minf(h.since,d.since)
			var other: float = float(d.since) if distance == 0 else maxf(h.since,d.since)
			if distance < best_distance or (distance == best_distance and (oldest < best_since or (oldest == best_since and other < best_other))):
				best_hero = hero; best_demon = demon; best_distance = distance; best_since = oldest; best_other = other
	if best_hero < 0: return []
	remove(best_hero); remove(best_demon); return [best_hero,best_demon]
