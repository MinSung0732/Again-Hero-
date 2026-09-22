extends RefCounted
class_name ResearchCatalog

const COST_ROUNDING := 5.0

const RESEARCH = {
	"monster_power": {
		"id": "monster_power",
		"name": "군단 화력 연구",
		"description": "공격력 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 70,
		"base_cost": 25,
		"cost_growth": 1.155,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 25, "multiplier": 0.70},
			{"up_to": 45, "multiplier": 0.45},
			{"up_to": 70, "multiplier": 0.25},
		],
	},
	"monster_vitality": {
		"id": "monster_vitality",
		"name": "군단 생체 강화",
		"description": "최대 HP 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 70,
		"base_cost": 25,
		"cost_growth": 1.155,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 25, "multiplier": 0.70},
			{"up_to": 45, "multiplier": 0.45},
			{"up_to": 70, "multiplier": 0.25},
		],
	},
	"monster_mobility": {
		"id": "monster_mobility",
		"name": "군단 기동 연구",
		"description": "이동속도 연구. 고레벨 구간에서 효율이 크게 감소합니다.",
		"max_level": 70,
		"base_cost": 20,
		"cost_growth": 1.165,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 25, "multiplier": 0.60},
			{"up_to": 45, "multiplier": 0.35},
			{"up_to": 70, "multiplier": 0.20},
		],
	},
	"monster_attack_speed": {
		"id": "monster_attack_speed",
		"name": "군단 공격 훈련",
		"description": "공격속도 연구. 고레벨 구간에서 효율이 크게 감소합니다.",
		"max_level": 70,
		"base_cost": 25,
		"cost_growth": 1.155,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 25, "multiplier": 0.60},
			{"up_to": 45, "multiplier": 0.35},
			{"up_to": 70, "multiplier": 0.20},
		],
	},
	"summon_efficiency": {
		"id": "summon_efficiency",
		"name": "소환 효율화",
		"description": "소환 비용 감소 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 20,
		"base_cost": 100,
		"cost_growth": 1.15,
		"effect_segments": [
			{"up_to": 5, "multiplier": 1.00},
			{"up_to": 10, "multiplier": 0.75},
			{"up_to": 15, "multiplier": 0.55},
			{"up_to": 20, "multiplier": 0.35},
		],
	},
	"mana_cycle": {
		"id": "mana_cycle",
		"name": "마력 순환",
		"description": "지휘력 회복 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 30,
		"base_cost": 110,
		"cost_growth": 1.125,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 20, "multiplier": 0.65},
			{"up_to": 30, "multiplier": 0.40},
		],
	},
	"mana_reservoir": {
		"id": "mana_reservoir",
		"name": "마력 저장고",
		"description": "최대 지휘력 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 30,
		"base_cost": 100,
		"cost_growth": 1.125,
		"effect_segments": [
			{"up_to": 10, "multiplier": 1.00},
			{"up_to": 20, "multiplier": 0.65},
			{"up_to": 30, "multiplier": 0.40},
		],
	},
	"rapid_experiment": {
		"id": "rapid_experiment",
		"name": "고속 실험법",
		"description": "마왕 EXP 획득 연구. 고레벨 구간일수록 효율이 감소합니다.",
		"max_level": 20,
		"base_cost": 130,
		"cost_growth": 1.15,
		"effect_segments": [
			{"up_to": 5, "multiplier": 1.00},
			{"up_to": 10, "multiplier": 0.70},
			{"up_to": 15, "multiplier": 0.45},
			{"up_to": 20, "multiplier": 0.30},
		],
	},
	"tactical_notebook": {
		"id": "tactical_notebook",
		"name": "전술 기록 노트",
		"description": "Run당 마왕 증강 새로고침 +1회",
		"max_level": 3,
		"costs": [1500, 4500, 8000],
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

static func get_effective_level_points(research_id: String, level: int) -> float:
	var data: Dictionary = RESEARCH.get(research_id, {})
	if data.is_empty() or level <= 0:
		return 0.0

	var max_level := maxi(int(data.get("max_level", 0)), 0)
	var clamped_level := mini(level, max_level)
	var segments: Array = data.get("effect_segments", [])
	if segments.is_empty():
		return float(clamped_level)

	var total := 0.0
	var previous_limit := 0
	for raw_segment in segments:
		var segment: Dictionary = raw_segment
		var limit := maxi(int(segment.get("up_to", previous_limit)), previous_limit)
		var covered := mini(clamped_level, limit) - previous_limit
		if covered > 0:
			total += float(covered) * maxf(
				float(segment.get("multiplier", 1.0)),
				0.0
			)
		previous_limit = limit
		if clamped_level <= limit:
			break

	return total

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
