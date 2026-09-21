extends RefCounted
class_name MutationCatalog

const PROFILES := {
	"mutation_1": {
		"id": "mutation_1",
		"name_prefix": "돌연변이",
		"ui_title": "돌연변이 선택",
		"ui_description": "편성 몬스터 1종을 돌연변이로 투입합니다.",
		"spawn_distance": 460.0,
		"hp_multiplier": 2.2,
		"damage_multiplier": 1.45,
		"speed_multiplier": 1.10,
		"exp_multiplier": 1.5,
		"visual_scale": 1.15,
	},
	"mutation_2": {
		"id": "mutation_2",
		"name_prefix": "돌연변이",
		"ui_title": "돌연변이 선택",
		"ui_description": "편성 몬스터 1종을 돌연변이로 투입합니다.",
		"spawn_distance": 460.0,
		"hp_multiplier": 2.5,
		"damage_multiplier": 1.55,
		"speed_multiplier": 1.05,
		"exp_multiplier": 1.6,
		"visual_scale": 1.18,
	},
	"greater_mutation": {
		"id": "greater_mutation",
		"name_prefix": "대돌연변이",
		"ui_title": "대돌연변이 선택",
		"ui_description": "편성 몬스터 1종을 대돌연변이로 진화시킵니다.",
		"spawn_distance": 460.0,
		"hp_multiplier": 4.0,
		"damage_multiplier": 1.9,
		"speed_multiplier": 1.08,
		"exp_multiplier": 2.2,
		"visual_scale": 1.32,
	},
}

static func get_profile(profile_id: String) -> Dictionary:
	var profile: Dictionary = PROFILES.get(profile_id, {})
	return profile.duplicate(true)

static func resolve_event(event: Dictionary) -> Dictionary:
	var result := event.duplicate(true)
	var profile_id := String(event.get("mutation_profile_id", ""))
	if profile_id.is_empty():
		return result

	var profile := get_profile(profile_id)
	if profile.is_empty():
		return result

	for key in profile.keys():
		if key == "id":
			continue
		if not result.has(key):
			result[key] = profile[key]

	return result
