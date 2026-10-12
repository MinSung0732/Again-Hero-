extends RefCounted
## First three stages: immediate decisions, a new tool, then a different opponent.
const OPENING_COMMAND := 24.0
const OWNED_REWARD_SHARDS := 10
const PROFILES := {
	"stage_1":{"duration":180.0,"events":[25.0,65.0,105.0,145.0],"reward_monster":"bomb_rat","objective":"거미로 발을 묶고, 여러 방향에서 몰아붙이세요.","preview":"원거리 마법탄 · 둔화와 포위로 접근 기회 만들기","next":"다음 용사는 빠르게 파고듭니다. 폭탄쥐의 폭발을 시험해 보세요."},
	"stage_2":{"duration":240.0,"events":[35.0,90.0,140.0,195.0],"reward_monster":"skeleton_archer","objective":"탱커로 찌르기를 받고, 다른 방향에서 공격하세요.","preview":"근접 연속 찌르기 · 탱커로 붙잡고 화력 분산","next":"다음 용사는 방패를 듭니다. 해골 궁수로 전선을 유지해 보세요."},
	"stage_3":{"duration":300.0,"events":[45.0,110.0,175.0,245.0],"reward_monster":"ghost","objective":"한 번에 쏟기보다 탱커 뒤에 화력을 이어 붙이세요.","preview":"검과 방패 · 탱커와 지속 화력의 조합","next":"다음은 권총 용사입니다. 장전 중에 압박할 군단을 준비하세요."},
}
const ADVANCED_OBJECTIVES := {
	"stage_4":"탄창이 비는 순간에 여러 방향에서 압박하세요.",
	"stage_5":"원소 기술을 확인하고, 큰 공격이 끝난 뒤 공세를 보내세요.",
	"stage_6":"탱커가 먼저 붙잡고 화력 몬스터가 뒤따르게 보내세요.",
	"stage_7":"바닥의 위험 구역을 피해 소환 방향을 바꿔 보세요.",
	"stage_8":"용사의 소환수와 본체를 확인해 공세를 나눠 보세요.",
	"stage_9":"정화 기술을 보고 다음 공세를 이어 보내세요.",
	"stage_10":"큰 기술이 끝난 틈에 탱커와 화력을 함께 밀어 넣으세요.",
}
static func objective(stage_id: String) -> String:
	return String(PROFILES.get(stage_id,{}).get("objective",ADVANCED_OBJECTIVES.get(stage_id,"용사의 선택을 보고 군단 조합을 바꿔 보세요.")))
const COUNTERS := {
	"reload":"용사가 장전하는 동안 여러 방향에서 압박하세요.",
	"area":"광역에 한꺼번에 휩쓸리지 않게 소환 방향을 나누세요.",
	"recovery":"회복할 틈을 주지 말고, 군단을 나눠 계속 이어 보내세요.",
	"mobility":"추격만 하기보다 둔화와 다른 방향의 포위를 섞어 보세요.",
	"evasion":"회피한 직후에 다음 공세를 이어 보내세요.",
	"durability":"탱커만 늘리지 말고 원거리·폭발 화력을 섞어 보세요.",
	"projectile":"탱커를 앞에 보내고 다른 방향에서 접근해 보세요.",
	"attack_speed":"한 방향에 몰기보다 탱커와 화력을 나눠 보내세요.",
	"damage":"탱커가 먼저 접근한 뒤에 화력 몬스터를 보내세요.",
}
const COUNTER_PRIORITY := ["area","reload","recovery","mobility","evasion","durability","projectile","attack_speed","damage"]
static func profile(stage_id: String) -> Dictionary: return PROFILES.get(stage_id,{}).duplicate(true)
static func apply(stage: Dictionary) -> Dictionary:
	var id := String(stage.get("id",""))
	if not PROFILES.has(id): return stage
	var rules: Dictionary = PROFILES[id]
	stage["run_duration_seconds"] = rules.duration
	stage["opening_command"] = OPENING_COMMAND
	stage["auto_spawn_min_distance"] = 320.0
	stage["auto_spawn_max_distance"] = 440.0
	var events: Array = stage.get("event_timeline",[])
	for i in mini(events.size(),rules.events.size()): events[i]["at_seconds"] = rules.events[i]
	return stage
static func counter_hint(tags: Array, fallback: String) -> String:
	for tag in COUNTER_PRIORITY:
		if tag in tags: return COUNTERS[tag]
	return fallback
