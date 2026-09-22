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
		"event_timeline": [
			{
				"id": "elite_01",
				"at_seconds": 90.0,
				"type": "elite",
				"name": "1차 돌연변이",
				"selection_mode": "team",
				"mutation_profile_id": "mutation_1",
			},			{
				"id": "elite_02",
				"at_seconds": 180.0,
				"type": "elite",
				"name": "2차 돌연변이",
				"selection_mode": "team",
				"mutation_profile_id": "mutation_2",
			},			{
				"id": "miniboss_01",
				"at_seconds": 240.0,
				"type": "miniboss",
				"name": "대돌연변이",
				"selection_mode": "team",
				"mutation_profile_id": "greater_mutation",
			},			{
				"id": "boss_01",
				"at_seconds": 300.0,
				"type": "boss",
				"name": "침공 대장",
				"monster_id": "orc",
				"hp_multiplier": 7.0,
				"damage_multiplier": 2.4,
				"speed_multiplier": 1.12,
				"exp_multiplier": 3.0,
				"visual_scale": 1.50,
			},
		],
		"first_clear_reward": 500,
		"next_stage_id": "stage_2",
	},
	"stage_2": {
		"id": "stage_2",
		"number": 2,
		"display_name": "그림자 도적",
		"hero_id": "swift_hunter",
		"hero_ai_profile_id": "stage_2_aggressive",
		"portrait_path": "res://assets/art/heroes/stage2_rogue/stage2_hero_portrait.png",
		"lobby_description": "빠르게 파고들어 3단 찌르기를 연계하고, 난도질과 급습-암살로 전장을 휘젓는 근접 도적.",
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
