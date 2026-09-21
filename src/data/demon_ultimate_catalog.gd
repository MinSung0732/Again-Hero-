extends RefCounted
class_name DemonUltimateCatalog

const CHARGE_MAX := 100.0
const PASSIVE_CHARGE_PER_SECOND := 1.0
const SUMMON_COST_CHARGE_MULTIPLIER := 1.2
const HERO_DAMAGE_CHARGE_MULTIPLIER := 0.25

const SKILLS = {
	"encirclement": {
		"id": "encirclement",
		"name": "원형 포위",
		"description": "용사 외곽 원주에 편성 몬스터를 둘러 소환",
		"implemented": true,
		"spawn_count": 12,
		"spawn_radius": 700.0,
		"spawn_batch_size": 2,
		"spawn_interval": 0.04,
		"cooldown": 18.0,
	},
	"line_assault": {
		"id": "line_assault",
		"name": "일직선 공세",
		"description": "동/서/남/북 한 면에서 일직선 소환",
		"implemented": true,
		"spawn_count": 10,
		"spawn_distance": 700.0,
		"line_span": 720.0,
		"spawn_batch_size": 2,
		"spawn_interval": 0.04,
		"cooldown": 16.0,
	},
	"square_siege": {
		"id": "square_siege",
		"name": "사각 포위",
		"description": "용사 외곽을 사각형으로 둘러 소환",
		"implemented": false,
		"cooldown": 20.0,
	},
}

const ORDER := [
	"encirclement",
	"line_assault",
	"square_siege",
]

static func get_skill(skill_id: String) -> Dictionary:
	var data: Dictionary = SKILLS.get(skill_id, {})
	return data.duplicate(true)

static func get_ordered_ids() -> Array[String]:
	var result: Array[String] = []
	for skill_id in ORDER:
		result.append(String(skill_id))
	return result
