extends RefCounted
class_name HeroRevealCatalog

# identity_id lets later-stage versions of the same person share encounter history.
# Stage 1 and Stage 5 are already described by the stage data as the same returning
# magic hero, so they intentionally share one identity.
const DATA := {
	"ranged_rookie": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
	},
	"archmage_hero": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
	},
	"sage_astra": {
		"identity_id": "returning_magic_hero",
		"true_name": "아스트라",
		"portrait_path": "res://assets/art/heroes/stage10_sage/cutscene/stage10_hero_cutscene.png",
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
		"portrait_path": String(entry.get("portrait_path", portrait_path)),
	}
