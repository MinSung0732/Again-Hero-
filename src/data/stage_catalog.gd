extends RefCounted
class_name StageCatalog

const STAGES = {
	"stage_1": {
		"id": "stage_1",
		"number": 1,
		"display_name": "첫 번째 침입자",
		"hero_id": "ranged_rookie",
		"hero_level_start": 1,
		"map_width": 3200,
		"map_height": 3200,
		"first_clear_reward": 100,
		"next_stage_id": "stage_2",
	},
	"stage_2": {
		"id": "stage_2",
		"number": 2,
		"display_name": "빠른 사냥꾼",
		"hero_id": "swift_hunter",
		"hero_level_start": 1,
		"map_width": 3600,
		"map_height": 3600,
		"first_clear_reward": 150,
		"next_stage_id": "",
	},
}

static func get_stage(stage_id: String) -> Dictionary:
	var stage: Dictionary = STAGES.get(stage_id, {})
	return stage.duplicate(true)
