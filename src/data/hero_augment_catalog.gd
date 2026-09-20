extends RefCounted
class_name HeroAugmentCatalog

const AUGMENTS = [
	{
		"id": "projectile_power",
		"name": "탄환 강화",
		"description": "투사체 공격력 +8",
		"base_score": 8.0,
		"ai_rules": [
			{"source": "current_type_ratio", "key": "orc", "weight": 4.0},
			{"source": "current_role_ratio", "key": "tank", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "orc", "weight": 2.6},
			{"source": "recent_role_ratio", "key": "tank", "weight": 1.4},
			{"source": "nearby_count_max", "value": 2, "bonus": 1.0},
			{"source": "hp_ratio_min", "value": 0.65, "bonus": 0.6},
		],
	},
	{
		"id": "rapid_strikes",
		"name": "연사 강화",
		"description": "공격속도 +12%",
		"base_score": 7.5,
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.55, "cap": 2.8},
			{"source": "current_type_ratio", "key": "slime", "weight": 3.5},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "slime", "weight": 3.2},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 1.8},
			{"source": "recent_events_linear", "weight": 0.10, "cap": 0.8},
			{"source": "total_count_min", "value": 4, "bonus": 0.6},
		],
	},
	{
		"id": "iron_body",
		"name": "강인한 육체",
		"description": "최대 HP +45, HP +45",
		"base_score": 7.0,
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.0},
			{"source": "current_type_ratio", "key": "orc", "weight": 2.5},
			{"source": "current_role_ratio", "key": "tank", "weight": 1.5},
			{"source": "recent_type_ratio", "key": "orc", "weight": 1.5},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "hp_ratio_max", "value": 0.55, "bonus": 1.0},
		],
	},
	{
		"id": "pursuit",
		"name": "민첩한 발놀림",
		"description": "이동속도 +25",
		"base_score": 6.0,
		"ai_rules": [
			{"source": "distance", "divisor": 220.0, "cap": 2.3},
			{"source": "current_type_ratio", "key": "spider", "weight": 3.5},
			{"source": "current_role_ratio", "key": "controller", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "spider", "weight": 3.0},
			{"source": "recent_role_ratio", "key": "controller", "weight": 1.6},
			{"source": "total_count_max", "value": 2, "bonus": 0.5},
		],
	},
	{
		"id": "long_reach",
		"name": "사거리 확장",
		"description": "공격/투사체 최대 사거리 +35",
		"base_score": 5.5,
		"ai_rules": [
			{"source": "distance", "divisor": 180.0, "cap": 2.7},
			{"source": "current_type_ratio", "key": "spider", "weight": 1.8},
			{"source": "recent_type_ratio", "key": "spider", "weight": 1.4},
			{"source": "recent_role_ratio", "key": "controller", "weight": 0.8},
			{"source": "nearby_count_eq", "value": 0, "bonus": 0.7},
		],
	},
	{
		"id": "battle_recovery",
		"name": "전투 회복",
		"description": "즉시 HP 90 회복",
		"base_score": 5.0,
		"ai_rules": [
			{"source": "hp_missing", "weight": 8.0},
			{"source": "current_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.5},
			{"source": "hp_ratio_min", "value": 0.80, "bonus": -2.5},
			{"source": "hp_ratio_max", "value": 0.45, "bonus": 2.0},
		],
	},
]

static func roll_candidates(count: int = 3) -> Array:
	var pool: Array = AUGMENTS.duplicate(true)
	pool.shuffle()

	var result: Array = []
	var take_count: int = mini(count, pool.size())
	for index in range(take_count):
		result.append(pool[index])

	return result
