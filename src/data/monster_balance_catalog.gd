extends RefCounted
## Versioned authoring standard. No scene/MonsterCatalog dependency; safe before _ready().
## Budgets describe level-zero, unaugmented FINAL stats after rarity multipliers.
const VERSION := "2026-10-11-v1"
const GRADE_EFFICIENCY := {"common":1.0,"uncommon":1.05,"rare":1.12,"legendary":1.20}
const ROLE_BUDGETS := {
	"swarm":{"hp_per_cost":24.0,"damage_per_cost":2.7},
	"tank":{"hp_per_cost":28.0,"damage_per_cost":1.2},
	"ranged":{"hp_per_cost":14.0,"damage_per_cost":2.1},
	"control":{"hp_per_cost":18.0,"damage_per_cost":1.3},
	"burst":{"hp_per_cost":10.0,"damage_per_cost":2.4,"burst_per_cost":16.0},
	"buffer":{"hp_per_cost":18.0,"damage_per_cost":1.2},
}
const ROLE_ALIASES := {"controller":"control","exploder":"burst"}
const RARITY_ALIASES := {"normal":"common","advanced":"uncommon"}
const RARITY_COMBAT_PROFILES := {
	"common":{"hp_multiplier":1.0,"damage_multiplier":1.0,"move_speed_multiplier":1.0,"attack_cooldown_multiplier":1.0},
	"uncommon":{"hp_multiplier":1.0,"damage_multiplier":1.0,"move_speed_multiplier":1.0,"attack_cooldown_multiplier":1.0},
	"rare":{"hp_multiplier":1.10,"damage_multiplier":1.12,"move_speed_multiplier":1.03,"attack_cooldown_multiplier":0.96},
	"legendary":{"hp_multiplier":1.22,"damage_multiplier":1.25,"move_speed_multiplier":1.05,"attack_cooldown_multiplier":0.92},
}
# Shares account for reach, control, poison, shields and healing; not simulated win rates.
# Reviewed profiles override rough authored HP/ATK. New IDs use their inline balance config
# or role defaults; custom mechanics must still be reviewed before declaring balanced.
const REVIEWED_PROFILES := {
	"slime": {"health_share": 1.0, "damage_share": 1.01010101, "cycle_damage_multiplier": 1.0, "note": "기본 물량 기준점"},
	"bat": {"health_share": 0.83333333, "damage_share": 0.99561928, "cycle_damage_multiplier": 1.0, "note": "돌진 진입 보유: 체력·직접 화력 할인"},
	"goblin": {"health_share": 0.74074074, "damage_share": 0.85733882, "cycle_damage_multiplier": 1.0, "note": "빠른 근접 압박"},
	"scorpion": {"health_share": 0.75, "damage_share": 0.75973409, "cycle_damage_multiplier": 1.0, "note": "장기 독 피해를 별도 기여로 계산"},
	"wolf": {"health_share": 0.83333333, "damage_share": 1.08533442, "cycle_damage_multiplier": 1.0, "note": "2타 합계는 공격력 1회분, 하울링 추가 화력 할인"},
	"orc": {"health_share": 0.92857143, "damage_share": 1.03448276, "cycle_damage_multiplier": 1.0, "note": "낮은 접근성의 순수 탱커: 비용 인하·몸체 보강", "move_speed": 100.0},
	"skeleton": {"health_share": 0.71428571, "damage_share": 1.48148148, "cycle_damage_multiplier": 2.0, "note": "2연격 합계 2배, 체력 예산 일부를 직접 화력에 배분"},
	"mummy": {"health_share": 0.68027211, "damage_share": 1.33992991, "cycle_damage_multiplier": 1.0, "note": "등장 50% 쉴드로 실효 체력 보충"},
	"dullahan": {"health_share": 1.05902778, "damage_share": 1.83465848, "cycle_damage_multiplier": 1.0, "note": "부활·흡혈·휴식 회복: 몸체/화력 할인, 접근 속도 보완", "move_speed": 75.0},
	"spider": {"health_share": 0.88888889, "damage_share": 0.68376068, "cycle_damage_multiplier": 1.0, "note": "낮은 직접 화력, 갱신 둔화가 주 기여"},
	"ghost": {"health_share": 0.91074681, "damage_share": 0.31525851, "cycle_damage_multiplier": 1.0, "note": "가스형·제어 효과 때문에 직접 화력 할인", "attack_cooldown": 2.0},
	"banshee": {"health_share": 0.8954009, "damage_share": 0.56353903, "cycle_damage_multiplier": 1.0, "note": "돌진·현재체력 비례 피해는 별도 기여"},
	"medusa": {"health_share": 0.93537415, "damage_share": 1.05663567, "cycle_damage_multiplier": 1.0, "note": "추적 가속·공용 석화는 별도 기여"},
	"yuki_onna": {"health_share": 0.99206349, "damage_share": 0.81949301, "cycle_damage_multiplier": 1.0, "note": "공용 둔화·사망 버프에 화력 예산 배분"},
	"succubus": {"health_share": 0.92043896, "damage_share": 1.78658205, "cycle_damage_multiplier": 1.0, "note": "근접 매혹형: 높은 접근 부담에 직접 화력 허용, 생존 패시브 체력 할인"},
	"goblin_thrower": {"health_share": 0.95238095, "damage_share": 0.80834803, "cycle_damage_multiplier": 1.0, "note": "중거리 투사체형"},
	"skeleton_archer": {"health_share": 0.68571429, "damage_share": 0.5734767, "cycle_damage_multiplier": 1.0, "note": "짧은 사거리 취약성에 화력 보완"},
	"kobolt": {"health_share": 0.78571429, "damage_share": 0.84656085, "cycle_damage_multiplier": 1.0, "note": "고정 장거리 이점으로 직접 화력 할인"},
	"kraken": {"health_share": 0.87142857, "damage_share": 0.64699793, "cycle_damage_multiplier": 1.0, "note": "분할 3타 합계 1회분, 고정 장거리·타격 성장과 긴 주기"},
	"powwow_mummy": {"health_share": 0.87301587, "damage_share": 0.67515432, "cycle_damage_multiplier": 1.0, "note": "지원형 별도 기준: 아군 강화에 화력 예산 배분", "role": "buffer", "move_speed": 70.0},
	"bomb_rat": {"health_share": 0.8, "damage_share": 1.0, "cycle_damage_multiplier": 1.0, "note": "반복 DPS 대신 1회 폭발 피해/비용 기준"},
}

static func rarity_id(data: Dictionary) -> String:
	var value := String(data.get("rarity", data.get("grade", "common")))
	return String(RARITY_ALIASES.get(value,value))

static func profile(data: Dictionary) -> Dictionary:
	var authored = data.get("balance", {})
	if typeof(authored) == TYPE_DICTIONARY and not authored.is_empty():
		return authored
	return REVIEWED_PROFILES.get(String(data.get("id","")), {})

static func role_id(data: Dictionary) -> String:
	var value := String(profile(data).get("role",data.get("role","")))
	return String(ROLE_ALIASES.get(value,value))

static func _number(value: Variant, fallback: float) -> float:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return fallback
	var result := float(value)
	return result if is_finite(result) else fallback

static func resolve_base_stats(data: Dictionary) -> Dictionary:
	var raw = data.get("base_stats",{})
	if typeof(raw) != TYPE_DICTIONARY or raw.is_empty():
		return {}
	var stats: Dictionary = raw.duplicate(true)
	var rarity := rarity_id(data)
	# Transcendents have one summon/unique growth; never apply ordinary cost budgets.
	if rarity == "transcendent":
		return stats
	var role := role_id(data)
	var cost := _number(data.get("base_cost",0.0),0.0)
	if not ROLE_BUDGETS.has(role) or not GRADE_EFFICIENCY.has(rarity) or cost <= 0.0:
		return stats # Unknown content is reported by audit, not converted to another role.
	var weights := profile(data)
	var budget: Dictionary = ROLE_BUDGETS[role]
	var combat: Dictionary = RARITY_COMBAT_PROFILES[rarity]
	var efficiency: float = GRADE_EFFICIENCY[rarity]
	var health_share := clampf(_number(weights.get("health_share",1.0),1.0),0.25,2.0)
	var damage_share := clampf(_number(weights.get("damage_share",1.0),1.0),0.25,2.0)
	stats["max_hp"] = maxi(1,int(round(cost*efficiency*budget.hp_per_cost*health_share/combat.hp_multiplier)))
	if stats.has("move_speed"):
		stats["move_speed"] = clampf(_number(weights.get("move_speed",stats.move_speed),0.0),0.0,1000.0)
	if stats.has("explosion_damage"):
		var burst_share := clampf(_number(weights.get("burst_share",damage_share),damage_share),0.25,2.0)
		stats["explosion_damage"] = maxi(1,int(round(cost*efficiency*float(budget.get("burst_per_cost",16.0))*burst_share/combat.damage_multiplier)))
	if stats.has("attack_damage") and String(data.get("attack_type","")) != "self_destruct":
		var cooldown := clampf(_number(weights.get("attack_cooldown",stats.get("attack_cooldown",1.0)),1.0),0.25,10.0)
		stats["attack_cooldown"] = cooldown
		var default_cycle := maxf(1.0,_number(stats.get("hits_per_attack",1.0),1.0))*maxf(0.01,_number(stats.get("hit_damage_multiplier",1.0),1.0))
		var cycle := clampf(_number(weights.get("cycle_damage_multiplier",default_cycle),default_cycle),0.25,20.0)
		var extra := clampf(_number(weights.get("cycle_extra_seconds",0.0),0.0),0.0,10.0)
		var period := cooldown*float(combat.attack_cooldown_multiplier)+extra
		stats["attack_damage"] = maxi(1,int(round(cost*efficiency*budget.damage_per_cost*damage_share*period/(cycle*float(combat.damage_multiplier)))))
	return stats

static func apply_base_stats(actor: Node, stats: Dictionary) -> void:
	# Only at spawn, before raw stat snapshots, giant/rarity/research/augment scaling.
	# EXP has its separate spawn accounting and is deliberately left alone.
	for key in stats:
		if key != "exp_reward" and actor.get(StringName(key)) != null:
			actor.set(StringName(key),stats[key])

static func audit(data: Dictionary) -> PackedStringArray:
	var issues := PackedStringArray()
	if rarity_id(data) == "transcendent":
		return issues
	if not GRADE_EFFICIENCY.has(rarity_id(data)): issues.append("unknown rarity")
	if not ROLE_BUDGETS.has(role_id(data)): issues.append("unknown role")
	if _number(data.get("base_cost",0.0),0.0) <= 0.0: issues.append("invalid cost")
	var weights := profile(data)
	if weights.is_empty(): issues.append("unreviewed mechanics: role defaults applied")
	elif String(weights.get("note","")).strip_edges().is_empty(): issues.append("mechanics review note required")
	for key in ["health_share","damage_share","burst_share"]:
		var value := _number(weights.get(key,1.0),-1.0)
		if value < 0.25 or value > 2.0: issues.append("invalid " + key)
	return issues
