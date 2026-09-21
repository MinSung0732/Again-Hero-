extends RefCounted
class_name ResearchCatalog

const RESEARCH = {
	"mana_reservoir": {
		"id": "mana_reservoir",
		"name": "마력 저장고",
		"description": "Run 시작 최대 지휘력 +20",
		"max_level": 3,
		"costs": [150, 250, 400],
	},
	"mana_cycle": {
		"id": "mana_cycle",
		"name": "마력 순환",
		"description": "지휘력 회복 +0.5 /초",
		"max_level": 3,
		"costs": [180, 300, 450],
	},
	"slime_logistics": {
		"id": "slime_logistics",
		"name": "슬라임 배양 최적화",
		"description": "슬라임 소환 비용 -8%",
		"max_level": 3,
		"costs": [150, 250, 400],
	},
	"tactical_notebook": {
		"id": "tactical_notebook",
		"name": "전술 기록 노트",
		"description": "Run당 마왕 증강 새로고침 +1회",
		"max_level": 3,
		"costs": [220, 350, 500],
	},
	"rapid_experiment": {
		"id": "rapid_experiment",
		"name": "고속 실험법",
		"description": "몬스터 소환 시 마왕 EXP 획득 +10%",
		"max_level": 3,
		"costs": [200, 320, 480],
	},
}

const ORDER := [
	"mana_reservoir",
	"mana_cycle",
	"slime_logistics",
	"tactical_notebook",
	"rapid_experiment",
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
	var data := get_research(research_id)
	if data.is_empty():
		return -1

	var max_level: int = int(data.get("max_level", 0))
	if current_level < 0 or current_level >= max_level:
		return -1

	var costs: Array = data.get("costs", [])
	if current_level >= costs.size():
		return -1

	return int(costs[current_level])
