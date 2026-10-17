extends RefCounted
## Player weapons only. Level-one values stay unchanged; existing AI summons
## retain their authored profiles. Watchers have no health and expire by time.
const BASE_DURATION := 14.0
const DURATION_PER_LEVEL := 2.0
const MAX_DURATION := 40.0
const BASE_HP_RATIO := 0.35
const AREA_LEVELS := [3,6,9,10,11]
# Radius / secondary damage ratio / additional targets. The primary is never hit twice.
const AREA_PROFILES := {
	"hound":{"mode":"cleave","label":"전방 휩쓸기","steps":[[65,.45,3],[90,.60,4],[115,.75,5],[145,.90,6],[190,1.0,8]]},
	"scout":{"mode":"whirl","label":"회전 베기","steps":[[90,.50,3],[120,.65,4],[150,.80,6],[180,.95,7],[220,1.10,10]]},
	"watcher":{"mode":"burst","label":"차원 탄착파","steps":[[70,.30,2],[95,.40,3],[125,.50,4],[155,.65,6],[200,.85,8]]},
	"gatekeeper":{"mode":"burst","label":"균열 폭발","steps":[[85,.50,3],[115,.65,4],[145,.80,5],[180,1.0,7],[230,1.20,10]]},
}
const PROFILES := {
	"summoner_hero_gate_hound":{"kind":"hound","hp_per_level":0.10,"max_hp_ratio":1.70,"invulnerable":false},
	"summoner_hero_scout":{"kind":"scout","hp_per_level":0.12,"max_hp_ratio":2.0,"invulnerable":false},
	"summoner_hero_gatekeeper":{"kind":"gatekeeper","hp_per_level":0.08,"max_hp_ratio":1.50,"invulnerable":false},
	"summoner_hero_watcher":{"kind":"watcher","hp_per_level":0.0,"max_hp_ratio":0.0,"invulnerable":true},
}

static func apply(data: Dictionary, rank: int, awakened: bool) -> void:
	var id := String(data.get("weapon_id",""))
	if String(data.get("pattern","")) != "summon" or not PROFILES.has(id): return
	var profile: Dictionary = PROFILES[id]
	var area: Dictionary = AREA_PROFILES[profile.kind]
	data["summon_area_mode"] = area.mode
	data["summon_area_label"] = area.label
	data["summon_area_radius"] = 0.0
	data["summon_area_ratio"] = 0.0
	data["summon_area_targets"] = 0
	for index in AREA_LEVELS.size():
		if (11 if awakened else rank) < int(AREA_LEVELS[index]): break
		var step: Array = area.steps[index]
		data.summon_area_radius = float(step[0])
		data.summon_area_ratio = float(step[1])
		data.summon_area_targets = int(step[2])
	data["summon_duration"] = MAX_DURATION if awakened else BASE_DURATION+DURATION_PER_LEVEL*(clampi(rank,1,10)-1)
	data["summon_invulnerable"] = bool(profile.invulnerable)
	if profile.invulnerable:
		data.erase("summon_hp_ratio")
	else:
		data["summon_hp_ratio"] = float(profile.max_hp_ratio) if awakened else BASE_HP_RATIO+float(profile.hp_per_level)*(clampi(rank,1,10)-1)

static func description(id: String, rank: int, awakened: bool = false) -> String:
	if not PROFILES.has(id): return ""
	var data := {"pattern":"summon","weapon_id":id}
	apply(data,rank,awakened)
	var text := "소환 유지 %.0f초" % float(data.summon_duration)
	if data.summon_invulnerable: return text+" · 감시자는 무적, 시간 만료 시 귀환"
	return text+" · 소환수 HP 용사 최대 HP의 %.0f%%" % (float(data.summon_hp_ratio)*100.0)
