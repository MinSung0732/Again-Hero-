extends RefCounted

# Presentation only; no skill, damage, summoning or reward authority.
const ENTRIES := {
	"zeus": {"view": "res://src/ui/zeus_battle_summon_view.gd", "duration": 5.0, "zoom": 1.3,
		"slow_motion": {"minimum": 0.18, "approach_end": 0.95, "recover_start": 2.65, "recover_end": 3.3},
		"world_effect": "res://src/ui/zeus_summon_radial_lightning.gd"},
}

# World-space presentation only, separate from Zeus combat skills/damage.
const ZEUS_RADIAL := {
	"rays": 8, "radius": 240.0, "bursts": [1.9, 2.08, 2.26], "burst_duration": 0.48,
}
