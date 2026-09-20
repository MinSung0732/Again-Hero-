extends RefCounted
class_name HeroAugmentCatalog

const AUGMENTS = [
	{
		"id": "projectile_power",
		"name": "탄환 강화",
		"description": "투사체 공격력 +8",
		"base_score": 8.0,
	},
	{
		"id": "rapid_strikes",
		"name": "연사 강화",
		"description": "공격속도 +12%",
		"base_score": 7.5,
	},
	{
		"id": "iron_body",
		"name": "강인한 육체",
		"description": "최대 HP +45, HP +45",
		"base_score": 7.0,
	},
	{
		"id": "pursuit",
		"name": "민첩한 발놀림",
		"description": "이동속도 +25",
		"base_score": 6.0,
	},
	{
		"id": "long_reach",
		"name": "사거리 확장",
		"description": "공격/투사체 최대 사거리 +35",
		"base_score": 5.5,
	},
	{
		"id": "battle_recovery",
		"name": "전투 회복",
		"description": "즉시 HP 90 회복",
		"base_score": 5.0,
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
