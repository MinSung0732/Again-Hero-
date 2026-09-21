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
			"projectile_power": 0.20,
			"rapid_strikes": 0.85,
			"pursuit": 0.65,
			"slow_resistance": 0.10,
			"long_reach": 0.35,
			"arcane_burst": 0.25,
		},
	},
}

static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(profile_id, {})
	return profile.duplicate(true)
