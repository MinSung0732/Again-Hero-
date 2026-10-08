extends RefCounted
const ZEUS_AUDIO := preload("res://src/data/zeus_audio_catalog.gd")

# Presentation only; no skill, damage, summoning or reward authority.
const ENTRIES := {
	"bulgasal": {"view":"res://src/ui/bulgasal_battle_summon_view.gd","duration":5.0,"zoom":1.3,
		"slow_motion":{"minimum":0.18,"approach_end":0.95,"recover_start":2.65,"recover_end":3.3}},
	"zeus": {"view": "res://src/ui/zeus_battle_summon_view.gd", "duration": 5.0, "zoom": 1.3,
		"slow_motion": {"minimum": 0.18, "approach_end": 0.95, "recover_start": 2.65, "recover_end": 3.3},
		"world_effect": "res://src/ui/zeus_summon_radial_lightning.gd",
		"audio_cues": ZEUS_AUDIO.CUES, "audio_timeline": ZEUS_AUDIO.SUMMON_TIMELINE,
		"death_audio_timeline": ZEUS_AUDIO.DEATH_TIMELINE},
}

# World-space presentation only, separate from Zeus combat skills/damage.
const ZEUS_RADIAL := {
	"rays": 8, "radius": 240.0, "bursts": [1.9, 2.08, 2.26], "burst_duration": 0.48,
}

# Applied to every transcendent death; an entry may override this with a "death" profile.
const DEATH_DEFAULT := {
	"duration": 2.8, "zoom": 1.65, "return_start": 2.0,
	"slow_motion": {"initial": 0.45, "minimum": 0.12, "approach_end": 0.35,
		"recover_start": 1.6, "recover_end": 2.15},
}
