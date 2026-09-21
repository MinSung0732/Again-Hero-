extends RefCounted
class_name HeroProfiles

const PROFILES = {
	"ranged_rookie": {
		"id": "ranged_rookie",
		"display_name": "견습 마도사",
		"archetype": "ranged_kiter",
		"max_hp": 300,
		"move_speed": 230.0,
		"attack_damage": 34,
		"attack_range": 430.0,
		"attack_cooldown": 0.62,
		"projectile_speed": 680.0,
		"exp_pickup_radius": 150.0,
		"ai_sense_radius": 420.0,
		"kite_distance": 210.0,
		"invulnerability_duration": 0.35,
		"facing_switch_delay": 0.14,
		"facing_min_horizontal_speed": 18.0,
		"ai_settings": {
			"observation_interval": 4.0,
			"stack_inertia": 1.25,
			"new_branch_penalty": 0.70,
		},
		"sprite_sheet_path": "res://assets/art/heroes/stage1_mage/stage1_mage_spritesheet.png",
	},
	"swift_hunter": {
		"id": "swift_hunter",
		"display_name": "기동 사냥꾼",
		"archetype": "ranged_kiter",
		"max_hp": 360,
		"move_speed": 265.0,
		"attack_damage": 30,
		"attack_range": 405.0,
		"attack_cooldown": 0.46,
		"projectile_speed": 760.0,
		"exp_pickup_radius": 160.0,
		"ai_sense_radius": 450.0,
		"kite_distance": 235.0,
		"invulnerability_duration": 0.35,
		"facing_switch_delay": 0.10,
		"facing_min_horizontal_speed": 22.0,
		"ai_settings": {
			"observation_interval": 2.8,
			"stack_inertia": 0.95,
			"new_branch_penalty": 0.40,
		},
	},
}

static func get_profile(hero_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(hero_id, {})
	return profile.duplicate(true)
