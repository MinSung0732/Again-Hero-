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
	},
}

static func get_profile(hero_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(hero_id, {})
	return profile.duplicate(true)
