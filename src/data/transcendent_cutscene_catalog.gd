extends RefCounted

# Presentation only: no probabilities, currency, inventory or reward mutations.
const ROOT := "res://assets/art/Transcendent_monster/zeus/frames/"
const ENTRIES := {
	"zeus": {
		"name": "제우스", "duration": 5.0,
		"background_path": "res://assets/art/effects/gatcha/zeus/celestial_temple.png",
		"halo_path": "", # Optional transparent full halo PNG; geometric fallback.
		"character_dir": ROOT, "character_prefix": "idle", "character_count": 4,
		"character_fps": 6.0, "character_region": Rect2(110, 160, 250, 210),
		"feet_y": [366.0, 366.0, 365.0, 366.0],
		"character_scale": 2.2, "anchor": Vector2(640, 574),
		"circle_dir": ROOT + "effect2/", "circle_prefix": "magic_circle", "circle_count": 8,
		"electric_dir": ROOT + "effect1/", "electric_prefix": "discharge", "electric_count": 7,
		"pillar_dir": ROOT + "effect5/", "pillar_prefix": "pillar", "pillar_count": 8,
		"effect_fps": 12.0,
	},
}

static func has_cutscene(entry: Dictionary) -> bool:
	return String(entry.get("rarity", "")) == "transcendent" and ENTRIES.has(String(entry.get("monster_id", "")))

static func get_entry(monster_id: String) -> Dictionary:
	return ENTRIES.get(monster_id, {})
