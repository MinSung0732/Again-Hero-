extends RefCounted
const BASE := {"max_hp":320,"attack_damage":22,"move_speed":78.0,"attack_range":80.0,"attack_cooldown":2.0,"exp_reward":40}
const RANGED_REDUCTION := 0.40
const EXTRA_REDUCTION := 0.20
const LOW_HP_START := 0.50
const LOW_HP_MAX := 0.15
const GUARD_RADIUS := 200.0
const GUARD_SHARE := 0.30
const STORAGE_RATIO := 0.30
const STORAGE_HEAL_RATIO := 0.50
const RANGED_SHIELD_RATIO := 0.70
const PETRIFY_TINT := Color(0.72,0.72,0.72,1.0)
const PETRIFY_SECONDS := 3.0
const PETRIFY_HEAL_RATIO := 0.30

# Existing normal/elite art shares the same five motions; keep original PNG pixels.
const ANIMATIONS := {
	"idle": {"prefix":"idle", "count":4, "fps":6.0, "loop":true},
	"move": {"prefix":"walk", "count":6, "fps":8.0, "loop":true},
	"attack": {"prefix":"attack", "count":6, "fps":12.0, "loop":false},
	"hit": {"prefix":"hit", "count":3, "fps":12.0, "loop":false},
	"death": {"prefix":"death", "count":4, "fps":10.0, "loop":false},
}
const NORMAL_VISUAL := {
	"mode":"frames", "asset_dir":"res://assets/art/monsters/Gargoyle/frames",
	"target_height":140.0, "animations":ANIMATIONS,
}
const ELITE_VISUAL := {
	"mode":"frames", "asset_dir":"res://assets/art/elitemonster/gargoyle/frames",
	"target_height":160.0, "animations":ANIMATIONS,
}
