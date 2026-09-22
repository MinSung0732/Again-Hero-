extends RefCounted
class_name HeroAIProfiles

const PROFILES = {
	"stage_1_cautious": {
		"id": "stage_1_cautious",
		"display_name": "신중한 견습생",
		"observation_interval": 4.0,
		"stack_inertia": 1.25,
		"new_branch_penalty": 0.70,
		"heal_item_desire": 0.95,
		"heal_risk_tolerance": 0.35,
		"heal_detour_weight": 1.15,
		"augment_biases": {},
	},
	"stage_2_aggressive": {
		"id": "stage_2_aggressive",
		"display_name": "공격적인 추격자",
		"observation_interval": 2.8,
		"stack_inertia": 0.95,
		"new_branch_penalty": 0.40,
		"heal_item_desire": 1.10,
		"heal_risk_tolerance": 0.60,
		"heal_detour_weight": 1.20,
		"augment_biases": {
			"rogue_edge": 0.75,
			"rogue_tempo": 0.65,
			"rogue_guard": 0.35,
			"rogue_hunt": 0.50,
			"rogue_execution": 0.30,
			"pursuit": 0.45,
			"slow_resistance": 0.20,
			"rogue_bloodthirst": 0.55,
		},
	},
	"stage_3_guardian": {
		"id": "stage_3_guardian",
		"display_name": "전선을 지키는 수호자",
		"observation_interval": 3.2,
		"stack_inertia": 1.05,
		"new_branch_penalty": 0.45,
		"heal_item_desire": 1.18,
		"heal_risk_tolerance": 0.76,
		"heal_detour_weight": 0.90,
		"augment_biases": {
			"fighter_guard_wall": 0.45,
			"fighter_revenge": 0.35,
			"fighter_thorns": 0.20,
			"fighter_guard_mastery": 0.45,
			"fighter_slash_mastery": 0.35,
			"fighter_charge": 0.30,
			"fighter_sword_mastery": 0.35,
			"fighter_slash_width": 0.25,
			"fighter_thrust_training": 0.20,
			"fighter_charge_recovery": 0.25,
			"iron_body": 0.35,
		},
	},
}

static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(profile_id, {})
	return profile.duplicate(true)
