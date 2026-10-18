extends RefCounted
class_name HeroRevealCatalog

# identity_id lets later-stage versions of the same person share encounter history.
# Repeated versions of Astra share the existing story disclosure.
const EMPTY := {}
const CLEAR_UNLOCK := {"clears": 10, "hard_clears": 1}
const STORY_UNLOCK := {"story_only": true}
const DATA := {
	"swift_hunter": {"true_name": "아길리스", "latin_name": "Agilis"},
	"sword_shield_hero": {"true_name": "피르무스", "latin_name": "Firmus"},
	"pistol_hero": {"true_name": "솔리투도", "latin_name": "Sōlitūdō"},
	"madness_hero": {"true_name": "데멘티아", "latin_name": "Dementia"},
	"chemical_hero": {"true_name": "릭소사", "latin_name": "rixosa"},
	"summoner_hero": {"true_name": "데쿠스", "latin_name": "Decus"},
	"purifier_hero": {"true_name": "미티스", "latin_name": "Mitis"},
	"ranged_rookie": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
		"latin_name": "Astra",
		"unlock_rule": STORY_UNLOCK,
	},
	"archmage_hero": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
		"latin_name": "Astra",
		"unlock_rule": STORY_UNLOCK,
	},
	"sage_astra": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
		"latin_name": "Astra",
		"unlock_rule": STORY_UNLOCK,
		"portrait_path": "res://assets/art/heroes/portrait/stage10_hero_portrait.png",
	},
}


static func get_reveal_data(
	hero_id: String,
	hero_display_name: String,
	portrait_path: String
) -> Dictionary:
	var entry: Dictionary = DATA.get(hero_id, {})
	return {
		"hero_id": hero_id,
		"identity_id": String(entry.get("identity_id", hero_id)),
		"title": hero_display_name,
		"true_name": String(entry.get("true_name", "")),
		"true_name_label": true_name_label(hero_id),
		"portrait_path": String(entry.get("portrait_path", portrait_path)),
	}


static func identity_for(hero_id: String) -> String:
	return String(DATA.get(hero_id, EMPTY).get("identity_id", hero_id))


static func true_name_label(hero_id: String) -> String:
	var entry: Dictionary = DATA.get(hero_id, EMPTY)
	var name := String(entry.get("true_name", ""))
	var latin := String(entry.get("latin_name", ""))
	return "%s (%s)" % [name, latin] if not name.is_empty() and not latin.is_empty() else name


static func display_name(hero_id: String, fallback: String, unlocked: Dictionary, include_latin: bool = false) -> String:
	if not bool(unlocked.get(identity_for(hero_id), false)): return fallback
	var entry: Dictionary = DATA.get(hero_id, EMPTY)
	var name := String(entry.get("true_name", ""))
	if name.is_empty(): return fallback
	return true_name_label(hero_id) if include_latin else name
