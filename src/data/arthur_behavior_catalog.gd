extends RefCounted
const ROOT := "res://assets/art/Transcendent_monster/King_Arthur/frames"
const BASE := {"max_hp":2000,"attack_damage":170,"move_speed":300.0,"attack_range":80.0,"attack_cooldown":1.75,"exp_reward":0}
const GROWTH := {"attack_damage":1.5,"max_hp":15.0}
const RULES := {"mode":"all","conditions":[{"metric":"tanks_summoned","amount":40},{"metric":"allies_died","amount":50}]}
const BODY_HEIGHT := 108.0 # Previous 120px combat body at 90%; feet anchor unchanged.
const COMBAT_EFFECT_Z := 5
const PROFILE := {"mode":"frames","asset_dir":ROOT,"target_height":BODY_HEIGHT,"animations":{
"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"walk","count":6,"fps":8.0,"loop":true},
"attack":{"prefix":"attack","count":3,"fps":9.0,"loop":false},"skill":{"prefix":"skill","count":1,"fps":1.0,"loop":true},
"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":8.0,"loop":false}}}
const COSTS := [50.0,100.0,40.0]
const COOLDOWNS := [50.0,100.0,50.0]
const GAUGE_MAX := 150.0
const DASH_DISTANCE := 1000.0
const DASH_SPEED := 900.0
const DASH_WIDTH := 40.0
const DASH_DURATION := 10.0
const GATE_RADIUS := 600.0
const BLESSING_RADIUS := 250.0
const EFFECT_CANVASES := [Vector2(664,270),Vector2(356,385),Vector2(412,410),Vector2(488,461)]
const EFFECT_ANCHORS := [Vector2(332,157),Vector2(178,364),Vector2(206,256),Vector2(244,285)]
const EFFECT_HEIGHTS := [150.0,260.0,210.0,210.0]
const EFFECT_COUNTS := [8,8,8,8]

const ARRIVAL_SHIELD := 0.20
const DASH_SHIELD := 0.15
const DASH_DAMAGE := 2.50
const DASH_FOLLOWUP_DAMAGE := 0.80
const DASH_HASTE := 1.80
const DASH_FOLLOWUP_SPEED := 1.50
const DASH_CHANNEL := 0.50
const DASH_HEAL := 0.15
const DASH_LANDING_PROBES := 48
const DASH_LANDING_STEP := 32.0
const DASH_ESCAPE_RINGS := 4
const DASH_ESCAPE_DIRECTIONS := 8
const DASH_STATIC_MASK := (1 << 2) | (1 << 3) # Castle decor and hard boundaries.
const GATE_CHANNEL := 1.0
const GATE_DURATION := 30.0
const GATE_UPGRADED_DURATION := 40.0
const GATE_COST_REDUCTION := 20.0
const GATE_HASTE := 1.50
const GATE_SPEED := 1.25
const GATE_ATTACK := 1.50
const GATE_CYCLE := 5.0
const GATE_RECOVERY := 0.05
const GATE_CASTER_ATTACK_PER_ALLY := 0.0045
const BLESSING_RATIO := 1.0
const BLESSING_UPGRADED_RATIO := 1.70
const BLESSING_DURATION := 3.0
const BLESSING_UPGRADED_DURATION := 5.0
const BLESSING_REFLECT := 0.50
const BLOCK_BASE := 0.15
const BLOCK_FIRST := 0.15
const BLOCK_SECOND := 0.20
