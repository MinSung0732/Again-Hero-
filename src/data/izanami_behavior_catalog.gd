extends RefCounted
const BASE := {"max_hp":1080,"attack_damage":55,"move_speed":250.0,"attack_range":275.0,"attack_cooldown":1.5,"projectile_speed":0.0,"projectile_range":0.0,"exp_reward":0}
const RULES := {"mode":"all","conditions":[{"metric":"controls_summoned","amount":50},{"metric":"statuses_applied","amount":3}]}
const ROOT := "res://assets/art/Transcendent_monster/Izanami/frames"
const PROFILE := {"mode":"frames","asset_dir":ROOT,"target_height":110.0,"animations":{
"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"walk","count":6,"fps":8.0,"loop":true},
"attack":{"prefix":"atk","count":4,"fps":10.0,"loop":false},"hit":{"prefix":"hit","count":2,"fps":12.0,"loop":false},"death":{"prefix":"death","count":3,"fps":8.0,"loop":false}}}
const RETREAT_START_DISTANCE := 220.0
const HOLD_DISTANCE := 240.0
const GAUGE_MAX := 100.0
const COSTS := [20.0,10.0,30.0]
const COOLDOWNS := [30.0,8.0,20.0]
# Unspecified values are centralized provisional tuning, not hidden balance rules.
const SPIRIT_DETECTION_RADIUS := 180.0
const SPIRIT_DASH_SPEED := 900.0
const SPIRIT_THROW_SPEED := 500.0
const TORII_CAPACITY := 4
const TORII_SHIELD_RATIO := 0.04
const TORII_WORLD_Z := -1 # Above the floor (-20), behind all actor bodies (0+).
const EFFECT_HEIGHTS := [150.0,180.0,135.0,460.0]
# Visible bounds of original attachment/roaming frames, measured once from PNGs.
# The authored torii anchor is the bottom edge, not the ground rune center.
const TORII_GROUND_CENTER := Vector2(150,370)
const GHOST_VISIBLE_CENTER := Vector2(140.5,190.0)
const SPIRIT_VISIBLE_TOP := 81.0
const SPIRIT_BAR_GAP := 7.0
const TARGET_BODY_CENTER_FALLBACK := Vector2(0,-24)
# Exact uploaded manifest coordinates; export-safe without runtime JSON dependency.
const EFFECT_CANVASES := [Vector2(278,349),Vector2(414,368),Vector2(336,425),Vector2(308,405)]
const EFFECT_ANCHORS := [Vector2(139,332),Vector2(207,356),Vector2(168,241),Vector2(154,390)]
const EFFECT_COUNTS := [8,7,8,8]
