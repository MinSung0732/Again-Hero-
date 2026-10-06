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
	return String(BANNERS.get(id, "")) if slot == "banner" else APPEARANCES.path(id, "avatar")
