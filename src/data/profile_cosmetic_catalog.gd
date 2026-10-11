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
	"arthur":{"monster_id":"arthur","name":"초월 · 아서왕","avatar":"res://assets/art/Transcendent_monster/King_Arthur/King_Arthur_icon.png","banner":"res://assets/art/Transcendent_monster/King_Arthur/King_Arthur_banner.png"},
	"arthur_plus_banner":{"monster_id":"arthur","name":"5초월 · 아서왕","min_upgrade_level":5,"banner":"res://assets/art/Transcendent_monster/King_Arthur/king_arthur_plus_banner.png"},
	"bulgasal_plus_banner":{"monster_id":"bulgasal","name":"5초월 · 불가살","min_upgrade_level":5,"banner":"res://assets/art/Transcendent_monster/Bulgasal/bulgasal_plus_banner.png"},
	"izanami_plus_banner":{"monster_id":"izanami","name":"5초월 · 이자나미","min_upgrade_level":5,"banner":"res://assets/art/Transcendent_monster/Izanami/izanami_plus_banner.png"},
	"shuten_doji_plus_banner":{"monster_id":"shuten_doji","name":"5초월 · 슈텐-도지","min_upgrade_level":5,"banner":"res://assets/art/Transcendent_monster/Shuten-doji/Shuten-doji_plus_banner.png"},
	"shuten_doji":{"monster_id":"shuten_doji","name":"초월 · 슈텐-도지","avatar":"res://assets/art/Transcendent_monster/Shuten-doji/shuten-doji_icon.png","banner":"res://assets/art/Transcendent_monster/Shuten-doji/shutendoji_banner.png"},
	"manticore":{"monster_id":"manticore","name":"초월 · 만티코어","avatar":"res://assets/art/Transcendent_monster/manticore/manticore_icon.png","banner":"res://assets/art/Transcendent_monster/manticore/manticore_banner.png"},
	"manticore_plus_banner":{"monster_id":"manticore","name":"5초월 · 만티코어","min_upgrade_level":5,"banner":"res://assets/art/Transcendent_monster/manticore/manticore_plus_banner.png"},
	"zeus_plus_banner": {
		"monster_id":"zeus", "name":"5초월 · 제우스", "min_upgrade_level":5,
		"banner":"res://assets/art/Transcendent_monster/zeus/zeus_plus_banner.png",
	},
	"izanami":{"monster_id":"izanami","name":"초월 · 이자나미","avatar":"res://assets/art/Transcendent_monster/Izanami/izanami_icon.png","banner":"res://assets/art/Transcendent_monster/Izanami/izanami_banner.png"},
	"bulgasal": {"monster_id":"bulgasal","name":"초월 · 불가살",
		"avatar":"res://assets/art/Transcendent_monster/Bulgasal/bulgasal_icon.png",
		"banner":"res://assets/art/Transcendent_monster/Bulgasal/bulgasal_banner.png"},
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

static func icon_info(id: String) -> Dictionary:
	if MONSTER_REWARDS.has(id):
		var label := display_name(id)
		var upgraded := int(MONSTER_REWARDS[id].get("min_upgrade_level", 0)) > 0
		return {"type": "5초월" if upgraded else "초월", "name": label.get_slice("·", 1).strip_edges() if label.contains("·") else label, "source": "몬스터 해금 · 5초월 달성" if upgraded else "초월 몬스터 해금"}
	var entry := APPEARANCES.get_entry(id)
	if entry.is_empty(): return {}
	return {"type": "기본", "name": String(entry.get("name", id)), "source": "초기 성별 선택"}
