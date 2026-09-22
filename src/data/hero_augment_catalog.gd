extends RefCounted
class_name HeroAugmentCatalog

const TAG_LABELS := {
	"damage": "화력",
	"projectile": "투사체",
	"attack_speed": "공격속도",
	"durability": "내구",
	"survival": "생존",
	"mobility": "기동",
	"kite": "카이팅",
	"range": "사거리",
	"recovery": "회복",
	"area": "광역",
	"resistance": "저항",
	"growth": "성장",
}

const AUGMENTS = [
	{
		"id": "projectile_power",
		"name": "탄환 강화",
		"description": "투사체 공격력 +8",
		"base_score": 8.0,
		"max_stack": 5,
		"tags": ["damage", "projectile"],
		"effects": [
			{"op": "add_stat", "target": "attack_damage", "value": 8},
		],
		"ai_rules": [
			{"source": "current_type_ratio", "key": "orc", "weight": 4.0},
			{"source": "current_role_ratio", "key": "tank", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "orc", "weight": 2.6},
			{"source": "recent_role_ratio", "key": "tank", "weight": 1.4},
			{"source": "nearby_count_max", "value": 2, "bonus": 1.0},
			{"source": "hp_ratio_min", "value": 0.65, "bonus": 0.6},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.90, "cap": 2.70},
			{"source": "build_tag_stacks", "key": "range", "weight": 0.45, "cap": 1.35},
		],
	},
	{
		"id": "rapid_strikes",
		"name": "연사 강화",
		"description": "공격속도 +12%",
		"base_score": 7.5,
		"max_stack": 5,
		"tags": ["attack_speed", "projectile"],
		"effects": [
			{"op": "multiply_stat", "target": "attack_cooldown", "value": 0.88, "min": 0.18},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.55, "cap": 2.8},
			{"source": "current_type_ratio", "key": "slime", "weight": 3.5},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "slime", "weight": 3.2},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 1.8},
			{"source": "recent_events_linear", "weight": 0.10, "cap": 0.8},
			{"source": "total_count_min", "value": 4, "bonus": 0.6},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.90, "cap": 2.70},
			{"source": "build_tag_stacks", "key": "range", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "iron_body",
		"name": "강인한 육체",
		"description": "최대 HP +20, HP +20",
		"base_score": 7.0,
		"max_stack": 10,
		"tags": ["durability", "survival"],
		"effects": [
			{"op": "add_stat", "target": "max_hp", "value": 20},
			{"op": "heal", "value": 20},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.0},
			{"source": "current_type_ratio", "key": "orc", "weight": 2.5},
			{"source": "current_role_ratio", "key": "tank", "weight": 1.5},
			{"source": "recent_type_ratio", "key": "orc", "weight": 1.5},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "hp_ratio_max", "value": 0.55, "bonus": 1.0},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "recovery", "weight": 1.00, "cap": 2.00},
		],
	},
	{
		"id": "pursuit",
		"name": "민첩한 발놀림",
		"description": "이동속도 +8",
		"base_score": 6.0,
		"max_stack": 10,
		"tags": ["mobility", "kite"],
		"effects": [
			{"op": "add_stat", "target": "move_speed", "value": 8.0},
		],
		"ai_rules": [
			{"source": "distance", "divisor": 220.0, "cap": 2.3},
			{"source": "current_type_ratio", "key": "spider", "weight": 3.5},
			{"source": "current_role_ratio", "key": "controller", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "spider", "weight": 3.0},
			{"source": "recent_role_ratio", "key": "controller", "weight": 1.6},
			{"source": "recent_status_weight", "key": "slow", "weight": 0.45, "cap": 2.7},
			{"source": "total_count_max", "value": 2, "bonus": 0.5},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "range", "weight": 0.70, "cap": 2.10},
		],
	},
	{
		"id": "slow_resistance",
		"name": "둔화 적응",
		"description": "둔화 저항 +5%",
		"base_score": 4.8,
		"max_stack": 10,
		"tags": ["resistance", "mobility", "survival"],
		"effects": [
			{"op": "add_status_resistance", "status": "slow", "value": 0.05, "max": 0.50},
		],
		"ai_rules": [
			{"source": "recent_status_weight", "key": "slow", "weight": 1.10, "cap": 6.6},
			{"source": "recent_type_ratio", "key": "spider", "weight": 1.8},
			{"source": "recent_role_ratio", "key": "controller", "weight": 1.4},
			{"source": "current_type_ratio", "key": "spider", "weight": 1.2},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.45, "cap": 1.35},
			{"source": "build_tag_stacks", "key": "kite", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "long_reach",
		"name": "사거리 확장",
		"description": "공격/투사체 최대 사거리 +35",
		"base_score": 5.5,
		"max_stack": 3,
		"tags": ["range", "kite"],
		"effects": [
			{"op": "add_stat", "target": "attack_range", "value": 35.0},
		],
		"ai_rules": [
			{"source": "distance", "divisor": 180.0, "cap": 2.7},
			{"source": "current_type_ratio", "key": "spider", "weight": 1.8},
			{"source": "recent_type_ratio", "key": "spider", "weight": 1.4},
			{"source": "recent_role_ratio", "key": "controller", "weight": 0.8},
			{"source": "nearby_count_eq", "value": 0, "bonus": 0.7},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.70, "cap": 2.10},
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.30, "cap": 0.90},
		],
	},
	{
		"id": "arcane_burst",
		"name": "폭발 탄환",
		"description": "투사체 적중 시 주변 적에게 광역 피해",
		"base_score": 5.8,
		"max_stack": 4,
		"tags": ["area", "projectile"],
		"effects": [
			{"op": "add_stat", "target": "projectile_splash_radius", "value": 70.0, "max": 180.0},
			{"op": "add_stat", "target": "projectile_splash_damage_ratio", "value": 0.28, "max": 0.70},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.70, "cap": 3.5},
			{"source": "current_type_ratio", "key": "slime", "weight": 4.5},
			{"source": "current_role_ratio", "key": "swarm", "weight": 3.0},
			{"source": "recent_type_ratio", "key": "slime", "weight": 4.0},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 2.5},
			{"source": "recent_events_linear", "weight": 0.14, "cap": 1.4},
			{"source": "total_count_min", "value": 5, "bonus": 1.2},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.55, "cap": 1.65},
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "battle_recovery",
		"name": "전투 회복",
		"description": "즉시 HP 90 회복",
		"base_score": 5.0,
		"max_stack": 3,
		"tags": ["recovery", "survival"],
		"effects": [
			{"op": "heal", "value": 90},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 8.0},
			{"source": "current_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.5},
			{"source": "hp_ratio_min", "value": 0.80, "bonus": -2.5},
			{"source": "hp_ratio_max", "value": 0.45, "bonus": 2.0},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "durability", "weight": 0.80, "cap": 2.40},
		],
	},
	{
		"id": "exp_training",
		"name": "경험 축적",
		"description": "경험치 획득량 +4%",
		"base_score": 6.4,
		"max_stack": 10,
		"tags": ["growth"],
		"effects": [
			{"op": "add_stat", "target": "exp_gain_multiplier", "value": 0.04, "max": 1.40},
		],
	},
	{
		"id": "exp_magnet",
		"name": "경험 흡수",
		"description": "경험치 획득 범위 +15",
		"base_score": 5.8,
		"max_stack": 10,
		"tags": ["growth", "range"],
		"effects": [
			{"op": "add_stat", "target": "exp_pickup_radius", "value": 15.0},
		],
	},
	{
		"id": "rogue_edge",
		"name": "예리한 연격",
		"description": "연격 피해 +10% (최대 +50%)",
		"base_score": 7.8,
		"max_stack": 5,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_combo_damage_multiplier", "value": 0.10, "max": 1.50},
		],
	},
	{
		"id": "rogue_tempo",
		"name": "연격 가속",
		"description": "연격 마무리 후딜 -3%",
		"base_score": 7.2,
		"max_stack": 4,
		"tags": ["attack_speed", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_combo_recovery_multiplier", "value": -0.03, "min": 0.88},
		],
	},
	{
		"id": "rogue_guard",
		"name": "난도질 방어",
		"description": "난도질 쉴드량 +2% 최대 HP",
		"base_score": 6.8,
		"max_stack": 4,
		"tags": ["durability", "survival", "area"],
		"effects": [
			{"op": "add_stat", "target": "rogue_slash_shield_ratio_bonus", "value": 0.02, "max": 0.08},
		],
	},
	{
		"id": "rogue_hunt",
		"name": "끈질긴 급습",
		"description": "급습-암살 공격 횟수 +1",
		"base_score": 6.6,
		"max_stack": 4,
		"tags": ["damage", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_assassination_hit_bonus", "value": 1, "max": 4},
		],
	},
	{
		"id": "rogue_execution",
		"name": "처형 감각",
		"description": "일반 몬스터 처형 기준 +2%",
		"base_score": 6.2,
		"max_stack": 3,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_execute_threshold_bonus", "value": 0.02, "max": 0.06},
		],
	},
	{
		"id": "rogue_bloodthirst",
		"name": "피의 갈증",
		"description": "직접 피해 흡혈 +2% (최대 20%)",
		"base_score": 6.9,
		"max_stack": 10,
		"tags": ["recovery", "survival", "damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_lifesteal_ratio", "value": 0.02, "max": 0.20},
		],
	},
	{
		"id": "rogue_ruthless_strike",
		"name": "무자비한 일격",
		"description": "기본 연격 돌진 횟수 +1 (3타 → 4타)",
		"base_score": 8.1,
		"max_stack": 1,
		"tags": ["damage", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_bonus_combo_hits", "value": 1, "max": 1},
		],
	}

]

static func roll_candidates(
	count: int = 3,
	build_counts: Dictionary = {},
	allowed_ids: Array = []
) -> Array:
	var pool: Array = []

	for raw_augment in AUGMENTS:
		var augment: Dictionary = raw_augment
		var augment_id := String(augment.get("id", ""))
		var max_stack := int(augment.get("max_stack", 0))
		var current_stack := int(build_counts.get(augment_id, 0))

		if not allowed_ids.is_empty() and augment_id not in allowed_ids:
			continue

		if max_stack > 0 and current_stack >= max_stack:
			continue

		pool.append(augment.duplicate(true))

	pool.shuffle()

	var result: Array = []
	var take_count: int = mini(count, pool.size())
	for index in range(take_count):
		result.append(pool[index])

	return result

static func get_augment(augment_id: String) -> Dictionary:
	for augment in AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)
	return {}

static func get_tag_label(tag_id: String) -> String:
	return String(TAG_LABELS.get(tag_id, tag_id))

static func get_build_tag_counts(build_counts: Dictionary) -> Dictionary:
	var tag_counts := {}

	for raw_augment_id in build_counts.keys():
		var augment_id := String(raw_augment_id)
		var stacks := int(build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue

		var augment := get_augment(augment_id)
		for raw_tag in augment.get("tags", []):
			var tag := String(raw_tag)
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + stacks

	return tag_counts
