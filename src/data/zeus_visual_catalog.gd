extends RefCounted
const BATTLE_VISIBLE_HEIGHT := 108.0

# Original uploaded filenames and common 512x384 canvas are preserved.
const PROFILE := {
	"mode": "frames", "asset_dir": "res://assets/art/Transcendent_monster/zeus/frames",
	"target_height": 88.0,
	"animations": {
		"idle": {"count": 4, "fps": 6.0, "loop": true},
		"move": {"prefix": "walk", "count": 6, "fps": 10.0, "loop": true},
		"attack": {"count": 2, "fps": 12.0, "loop": false},
		"hit": {"count": 3, "fps": 12.0, "loop": false},
		"death": {"count": 3, "fps": 10.0, "loop": false},
		"skill": {"count": 3, "fps": 10.0, "loop": false,
			"files": ["skill_01.png", "skill_01-02.png", "skill01-03.png"]},
	},
}
