extends RefCounted
class_name ResearchCatalog

const COST_ROUNDING := 5.0

const RESEARCH = {
	"monster_power": {
		"id": "monster_power",
		"name": "군단 화력 연구",
		"description": "모든 몬스터 공격력 +1% / Lv",
		"max_level": 70,
		"base_cost": 15,
		"cost_growth": 1.15,
	},
	"monster_vitality": {
		"id": "monster_vitality",
		"name": "군단 생체 강화",
		"description": "모든 몬스터 최대 HP +1% / Lv",
		"max_level": 70,
		"base_cost": 15,
		"cost_growth": 1.15,
	},
	"monster_mobility": {
		"id": "monster_mobility",
		"name": "군단 기동 연구",
		"description": "모든 몬스터 이동속도 +0.35% / Lv",
		"max_level": 70,
		"base_cost": 10,
		"cost_growth": 1.16,
	},
	"monster_attack_speed": {
		"id": "monster_attack_speed",
		"name": "군단 공격 훈련",
		"description": "모든 몬스터 공격속도 +0.5% / Lv",
		"max_level": 70,
		"base_cost": 15,
		"cost_growth": 1.15,
	},
	"summon_efficiency": {
		"id": "summon_efficiency",
		"name": "소환 효율화",
		"description": "모든 몬스터 소환 비용 -1% / Lv",
		"max_level": 20,
		"base_cost": 70,
		"cost_growth": 1.14,
	},
	"mana_cycle": {
		"id": "mana_cycle",
		"name": "마력 순환",
		"description": "지휘력 회복 +0.15 /초 / Lv",
		"max_level": 30,
		"base_cost": 80,
		"cost_growth": 1.115,
	},
	"mana_reservoir": {
		"id": "mana_reservoir",
		"name": "마력 저장고",
		"description": "최대 지휘력 +5 / Lv",
		"max_level": 30,
		"base_cost": 70,
		"cost_growth": 1.115,
	},
	"rapid_experiment": {
		"id": "rapid_experiment",
		"name": "고속 실험법",
		"description": "몬스터 소환 시 마왕 EXP 획득 +3% / Lv",
		"max_level": 20,
		"base_cost": 90,
		"cost_growth": 1.14,
	},
	"tactical_notebook": {
		"id": "tactical_notebook",
		"name": "전술 기록 노트",
		"description": "Run당 마왕 증강 새로고침 +1회",
		"max_level": 3,
		"costs": [1000, 3000, 5000],
	},
}

const ORDER := [
	"monster_power",
	"monster_vitality",
	"monster_mobility",
	"monster_attack_speed",
	"summon_efficiency",
	"mana_cycle",
	"mana_reservoir",
	"rapid_experiment",
	"tactical_notebook",
]

static func get_research(research_id: String) -> Dictionary:
	var data: Dictionary = RESEARCH.get(research_id, {})
	return data.duplicate(true)

static func get_ordered_ids() -> Array[String]:
	var result: Array[String] = []
	for research_id in ORDER:
		result.append(String(research_id))
	return result

static func get_cost(research_id: String, current_level: int) -> int:
	var data: Dictionary = RESEARCH.get(research_id, {})
	if data.is_empty():
		return -1

	var max_level: int = int(data.get("max_level", 0))
	if current_level < 0 or current_level >= max_level:
		return -1

	var fixed_costs: Array = data.get("costs", [])
	if not fixed_costs.is_empty():
		if current_level >= fixed_costs.size():
			return -1
		return int(fixed_costs[current_level])

	var base_cost: float = float(data.get("base_cost", 0))
	var growth: float = float(data.get("cost_growth", 1.0))
	if base_cost <= 0.0:
		return -1
	if growth < 1.0:
		growth = 1.0

	var raw_cost: float = base_cost
	for _step in range(current_level):
		raw_cost *= growth

	var rounded_steps: int = int(
		(raw_cost + COST_ROUNDING - 0.001) / COST_ROUNDING
	)
	return maxi(rounded_steps * int(COST_ROUNDING), 1)
