extends RefCounted

# Presentation configuration; no paid draw is enabled until the reward pool,
# rates and playable monster are implemented together.
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
