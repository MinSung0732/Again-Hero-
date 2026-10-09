extends RefCounted

# Presentation only: no probabilities, currency, inventory or reward mutations.
const ROOT := "res://assets/art/Transcendent_monster/zeus/frames/"
const ENTRIES := {
	"izanami": {"name":"이자나미","duration":5.0,"presentation_view":"res://src/ui/izanami_gacha_view.gd", "impact_sound_path":"res://assets/audio/sfx/izanami/spirit_release.wav", "impact_sound_at":2.4,"impact_volume_db":-12.0, "charge_sound_path":"res://assets/audio/sfx/izanami/prayer_charge.wav","charge_sound_at":0.7,"charge_volume_db":-18.0},
	"bulgasal": {"name":"불가살","duration":5.0,"presentation_view":"res://src/ui/bulgasal_gacha_view.gd"},
	"zeus": {
		"name": "제우스", "duration": 5.0,
		"presentation_view": "res://src/ui/zeus_rig_cutscene_view.gd",
		"impact_sound_path": "res://assets/audio/sfx/zeus/thunder.wav",
		"impact_sound_at": 1.9, "impact_volume_db": -8.0,
		"background_path": "res://assets/art/effects/gatcha/zeus/celestial_temple.png",
		"halo_path": "", # Optional transparent full halo PNG; geometric fallback.
		"stage_size": Vector2(1080, 1920),
		"character_dir": "res://assets/art/effects/gatcha/zeus/portrait/",
		"character_prefix": "idle", "character_count": 1,
		"character_fps": 6.0, "character_region": Rect2(0, 0, 768, 1280),
		"feet_y": [1200.0],
		"character_scale": 1.25, "anchor": Vector2(540, 1570),
		"name_rect": Rect2(240, 1740, 600, 72), "name_font_size": 48,
		"halo_center": Vector2(540, 860), "halo_radius": 350.0,
		"halo_rect": Rect2(170, 490, 740, 740),
		"circle_rect": Rect2(180, 1400, 720, 350),
		"pillar_rect": Rect2(390, 350, 300, 1250),
		"electric_left_rect": Rect2(20, 920, 320, 380),
		"electric_right_rect": Rect2(740, 960, 320, 380),
		"particle_center": Vector2(540, 1570), "particle_height": 1050.0,
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
