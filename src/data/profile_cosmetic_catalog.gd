extends RefCounted

const APPEARANCES := preload("res://src/data/demon_appearance_catalog.gd")
const BANNERS := {
	"original_male": "res://assets/art/UI/profile_v1/banner_male.png",
	"original_female": "res://assets/art/UI/profile_v1/banner_female.png",
}
const ACTIONS := [
	["avatar", "초상화 변경", "portrait"],
	["banner", "배너 변경", "banner"],
	["representative", "대표 캐릭터 변경", "character"],
	["title", "칭호 변경", "crown"],
]

static func path(id: String, slot: String) -> String:
	if MONSTER_REWARDS.has(id):
		return String(MONSTER_REWARDS[id].get(slot, "")) if slot in ["avatar", "banner"] else ""
	return String(BANNERS.get(id, "")) if slot == "banner" else APPEARANCES.path(id, "avatar")

# These are profile rewards only, never representative demon appearances.
# Ownership follows the monster collection, so old saves and cloud restores
# receive the cosmetics without a second grant transaction or duplicate flags.
const MONSTER_REWARDS := {
	"zeus": {
		"monster_id": "zeus", "name": "초월 · 제우스",
		"avatar": "res://assets/art/Transcendent_monster/zeus/zeus_icon.png",
		"banner": "res://assets/art/Transcendent_monster/zeus/zeus_banner.png",
	},
}

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in APPEARANCES.ORDER:
		result.append(String(id))
	for id in MONSTER_REWARDS:
		if String(id) not in result:
			result.append(String(id))
	return result

static func display_name(id: String) -> String:
	return String(MONSTER_REWARDS[id].get("name", id)) if MONSTER_REWARDS.has(id) else String(APPEARANCES.get_entry(id).get("name", id))
