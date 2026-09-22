extends RefCounted
class_name HeroAIProfiles

const PROFILES = {
	"stage_1_cautious": {
		"id": "stage_1_cautious",
		"display_name": "신중한 견습생",
		"observation_interval": 4.0,
		"stack_inertia": 1.25,
		"new_branch_penalty": 0.70,
		"augment_biases": {},
	},
	"stage_2_aggressive": {
		"id": "stage_2_aggressive",
		"display_name": "공격적인 추격자",
		"observation_interval": 2.8,
		"stack_inertia": 0.95,
		"new_branch_penalty": 0.40,
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
}

static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(profile_id, {})
	return profile.duplicate(true)
