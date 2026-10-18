extends RefCounted
# Solo hero pressure policy. Monster combat skills remain unchanged.
const STAGES := [
	{"first":30.0,"interval":12.0,"limit":2,"species":1,"ratio":0.10},
	{"first":25.0,"interval":10.0,"limit":3,"species":1,"ratio":0.12},
	{"first":20.0,"interval":9.0,"limit":4,"species":2,"ratio":0.14},
	{"first":15.0,"interval":8.0,"limit":5,"species":2,"ratio":0.16},
	{"first":12.0,"interval":7.0,"limit":6,"species":2,"ratio":0.18},
	{"first":10.0,"interval":6.0,"limit":7,"species":3,"ratio":0.20},
	{"first":8.0,"interval":5.0,"limit":8,"species":3,"ratio":0.22},
	{"first":6.0,"interval":4.5,"limit":9,"species":3,"ratio":0.24},
	{"first":5.0,"interval":4.0,"limit":10,"species":4,"ratio":0.26},
	{"first":5.0,"interval":3.5,"limit":12,"species":4,"ratio":0.28},
]
const LATE_TIME := 300.0
const LATE_LIMIT_BONUS := 2
const LATE_SPECIES_BONUS := 1
# These non-controller roles have innate slow/stun/charm behavior outside
# base_stats. New controller roles and authored elite status fields auto-match.
const INNATE_CONTROL := {"mud_golem":true,"hobgoblin":true,"gumiho":true,"yuki_onna":true}
const CONTROL_WORDS := ["fear","stun","root","petrify","charm"]
static var classification: Dictionary = {}
static func stage_rule(stage: int) -> Dictionary:
	return STAGES[clampi(stage,1,10)-1]
static func is_control(data: Dictionary, elite: bool) -> bool:
	var id := String(data.get("id",""))
	var key := id+("/elite" if elite else "/normal")
	if classification.has(key): return bool(classification[key])
	var result := String(data.get("role","")) == "controller" or bool(data.get("hero_control_source",INNATE_CONTROL.has(id)))
	if not result: result = _status_fields(data.get("base_stats",{}))
	if not result and elite:
		for skill in data.get("elite_skills",[]):
			if _status_fields(skill): result = true; break
			for word in CONTROL_WORDS:
				if String(skill.get("id","")).contains(word): result = true; break
	classification[key] = result
	return result
static func _status_fields(data: Dictionary) -> bool:
	for key in ["slow_multiplier","hero_slow_multiplier"]:
		if float(data.get(key,1.0)) < 1.0: return true
	for key in ["stun_duration","root_duration","fear_duration","petrify_duration","charm_duration"]:
		if float(data.get(key,0.0)) > 0.0: return true
	return false
