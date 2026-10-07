extends RefCounted

# Event artwork and featured ID. The same rarity roll is used in both pools.
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const FEATURED_WEIGHT := 3.0
const CURRENT_ID := "zeus"
const INACTIVE_ART := "res://assets/art/UI/shop/pickup_inactive.png"
const EVENTS := {
	"zeus": {
		"monster_id": "zeus",
		"name": "제우스",
		"art_path": "res://assets/art/Transcendent_monster/zeus/zeus_pickup_banner.png",
	},
}

static func current() -> Dictionary:
	return Dictionary(EVENTS.get(CURRENT_ID, {})).duplicate(true)

static func can_draw() -> bool:
	var event := current()
	var id := String(event.get("monster_id", ""))
	return MONSTERS.MONSTERS.has(id) and MONSTERS.get_rarity(id) == "transcendent"
