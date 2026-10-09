extends RefCounted
const ROOT := "res://assets/art/Transcendent_monster/Shuten-doji/frames"
const BASE := {"max_hp":2500,"attack_damage":220,"move_speed":310.0,"attack_range":70.0,"attack_cooldown":2.0,"projectile_speed":0.0,"projectile_range":0.0,"exp_reward":0}
const RULES := {"mode":"all","conditions":[{"metric":"controls_summoned","amount":40},{"metric":"statuses_applied","amount":3}]}
const PROFILE := {"mode":"frames","asset_dir":ROOT,"target_height":110.0,"animations":{
"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"walk","count":6,"fps":8.0,"loop":true},
"attack":{"prefix":"attack","count":6,"fps":10.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":3,"fps":8.0,"loop":false}}}
const FOG_CAPACITY := 64
const FOG_RADIUS := 100.0
const FOG_SPREAD := 200.0 # Centers + radius fill the named diameter600.
const FOG_CAST_SECONDS := 2.0
const FOG_LIFE_MIN := 5.0
const FOG_LIFE_MAX := 10.0
const BLAST_RADIUS := 150.0
const BLAST_THRESHOLD := 10.0
const CHAIN_CAPACITY := 4
const CHAIN_SPEED := 40.0 # Unspecified tuning: deliberately slow homing spirit.
const CHAIN_MAX_SECONDS := 40.0
const CAST_RANGE := 600.0 # Unspecified acquisition range; flight may continue outside it.
const REVIVAL_SECONDS := 3.0
const ARRIVAL_SECONDS := 1.25
const EFFECT_CANVASES := [Vector2(396,413),Vector2(382,323),Vector2(364,350),Vector2(550,379)]
const EFFECT_ANCHORS := [Vector2(198,393),Vector2(191,272),Vector2(182,200),Vector2(275,338)]
const EFFECT_HEIGHTS := [210.0,260.0,140.0,230.0]
const EFFECT_COUNTS := [8,8,8,8]
