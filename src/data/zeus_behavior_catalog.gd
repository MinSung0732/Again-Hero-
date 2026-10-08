extends RefCounted
const BASE := {"max_hp":1200,"attack_damage":150,"move_speed":290.0,"attack_range":237.5,"attack_cooldown":1.3,"projectile_speed":0.0,"projectile_range":0.0,"exp_reward":0}
const HP_PER_SUMMON := 2.5
const DAMAGE_PER_SUMMON := 0.6
const COMBAT_STYLE := "ranged_harasser"
const RETREAT_START_DISTANCE := 170.0
const HOLD_DISTANCE := 210.0
const GAUGE_MAX := 100.0
const REGEN_RATIO := 1.0
const REGEN_CAP := 15.0
const COSTS := [30.0,30.0,50.0]
const COOLDOWNS := [20.0,45.0,15.0]
const CAST_PRIORITY := [1,0,2]
const CHARGE_SECONDS := 2.0
const CROWN_SECONDS := 15.0
const CROWN_HEAL_INTERVAL := 5.0
const CROWN_HEAL_RATIO := 0.03
const CROWN_PARALYSIS_MULTIPLIER := 1.5
const CROWN_SKILL_DELAY := 10.0
const STATUS_SECONDS := 2.0
const BASIC_CHANCE := 0.5
const BASIC_PARALYSIS := 0.75
const IMMUNE_DAMAGE_RATIO := 0.5
const IMMUNE_CHANCE := 0.25
const IMMUNE_PARALYSIS := 0.30
const THUNDER_DAMAGE := 2.0
const THUNDER_UPGRADED_DAMAGE := 2.35
const THUNDER_SLOW := 0.30
const THUNDER_PARALYSIS := 0.30
const SLASH_DAMAGE := 1.5
const SLASH_UPGRADED_DAMAGE := 1.75
const SLASH_PARALYSIS := 0.20
const SLASH_RANGE := 1500.0
const SLASH_SPEED := 650.0
const SLASH_HIT_RADIUS := 32.0
const DEATH_RADIUS := 275.0
const ORB_GAUGE := GAUGE_MAX * 0.0001
const ORB_HEAL_MISSING_RATIO := 0.0007
const ORB_SECONDS := 0.9
const MAX_ORBS := 64
const RULES := {"mode":"all","conditions":[{"metric":"command_spent","amount":500},{"metric":"mana_spent","amount":250}]}
const EFFECT_ROOT := "res://assets/art/Transcendent_monster/zeus/frames/"
const EFFECTS := {
	"charge":{"folder":"effect1","prefix":"discharge","first":1,"last":7,"size":92.0},
	"crown":{"folder":"effect2","prefix":"magic_circle","first":1,"last":8,"size":96.0},
	"orb":{"folder":"effect3","prefix":"orb","first":1,"last":7,"size":24.0},
	"judgment":{"folder":"effect5","prefix":"pillar","first":1,"last":3,"size":160.0,"feet":true},
	"thunder":{"folder":"effect5","prefix":"pillar","first":4,"last":8,"size":220.0,"feet":true},
	"slash":{"folder":"effect6","prefix":"slash","first":1,"last":7,"size":130.0*1.75},
}
