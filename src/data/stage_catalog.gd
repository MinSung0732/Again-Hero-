extends RefCounted
class_name StageCatalog

const ORDER := ["stage_1", "stage_2"]

const STAGES = {
	"stage_1": {
		"id": "stage_1",
		"number": 1,
		"display_name": "첫 번째 침입자",
		"hero_id": "ranged_rookie",
		"hero_ai_profile_id": "stage_1_cautious",
		"portrait_path": "res://assets/art/heroes/stage1_mage/stage1_hero_portrait.png",
		"lobby_description": "첫 번째 침입자. 원거리에서 거리를 벌리며 마법탄을 쏘는 견습 마도사.",
		"hero_level_start": 1,
		"map_width": 3200,
		"map_height": 3200,
		"run_duration_seconds": 360.0,
		"first_clear_reward": 500,
		"next_stage_id": "stage_2",
	},
	"stage_2": {
		"id": "stage_2",
		"number": 2,
		"display_name": "빠른 사냥꾼",
		"hero_id": "swift_hunter",
		"hero_ai_profile_id": "stage_2_aggressive",
		"portrait_path": "",
		"lobby_description": "더 빠른 관측과 연사 성향을 가진 기동형 원거리 침입자.",
		"hero_level_start": 1,
		"map_width": 3600,
		"map_height": 3600,
		"run_duration_seconds": 420.0,
		"first_clear_reward": 750,
		"next_stage_id": "",
	},
}

static func get_stage(stage_id: String) -> Dictionary:
	var stage: Dictionary = STAGES.get(stage_id, {})
	return stage.duplicate(true)

static func get_ordered_stage_ids() -> Array[String]:
	var result: Array[String] = []
	for stage_id in ORDER:
		if STAGES.has(stage_id):
			result.append(String(stage_id))
	return result
