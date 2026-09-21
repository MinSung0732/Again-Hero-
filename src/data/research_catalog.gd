extends RefCounted
class_name ResearchCatalog

const RESEARCH = {
	"monster_power": {
		"id": "monster_power",
		"name": "군단 화력 연구",
		"description": "모든 몬스터 공격력 +10%",
		"max_level": 5,
		"costs": [150, 220, 300, 400, 520],
	},
	"monster_vitality": {
		"id": "monster_vitality",
		"name": "군단 생체 강화",
		"description": "모든 몬스터 최대 HP +12%",
		"max_level": 5,
		"costs": [150, 220, 300, 400, 520],
	},
	"monster_mobility": {
		"id": "monster_mobility",
		"name": "군단 기동 연구",
		"description": "모든 몬스터 이동속도 +8%",
		"max_level": 5,
		"costs": [140, 210, 290, 380, 500],
	},
	"monster_attack_speed": {
		"id": "monster_attack_speed",
		"name": "군단 공격 훈련",
		"description": "공격 주기 -7% · 자폭 준비시간도 감소",
		"max_level": 5,
		"costs": [160, 230, 320, 420, 550],
	},
	"summon_efficiency": {
		"id": "summon_efficiency",
		"name": "소환 효율화",
		"description": "모든 몬스터 소환 비용 -5%",
		"max_level": 5,
		"costs": [170, 250, 340, 450, 580],
	},
	"mana_cycle": {
		"id": "mana_cycle",
		"name": "마력 순환",
		"description": "지휘력 회복 +0.5 /초",
		"max_level": 5,
		"costs": [180, 260, 350, 460, 600],
	},
	"mana_reservoir": {
		"id": "mana_reservoir",
		"name": "마력 저장고",
		"description": "최대 지휘력 +20",
		"max_level": 5,
		"costs": [150, 230, 320, 420, 550],
	},
	"rapid_experiment": {
		"id": "rapid_experiment",
		"name": "고속 실험법",
		"description": "몬스터 소환 시 마왕 EXP 획득 +10%",
		"max_level": 5,
		"costs": [200, 280, 370, 480, 620],
	},
	"tactical_notebook": {
		"id": "tactical_notebook",
		"name": "전술 기록 노트",
		"description": "Run당 마왕 증강 새로고침 +1회",
		"max_level": 3,
		"costs": [220, 350, 500],
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
