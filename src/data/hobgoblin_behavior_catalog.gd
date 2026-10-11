extends RefCounted

const BASE := {"max_hp":300,"attack_damage":24,"move_speed":75.0,"attack_range":80.0,"attack_cooldown":2.0,"exp_reward":48}
const RADIUS := 175.0
const LORD_RADIUS := 375.0
const STAT_PER_ALLY := 2.0
const ATTACK_SPEED_PER_ALLY := 0.02
const STUN_COUNT := 10
const STUN_CHANCE := 0.03
const STUN_SECONDS := 1.0
const FORTRESS_COUNT := 100
const FORTRESS_HP_MULTIPLIER := 4.0
const GUARD_MULTIPLIER := 0.80
const SHIELD_SECONDS := 2.0
const SHIELD_AMOUNT := 30
const COMMAND_SECONDS := 5.0
const COMMAND_SPACING := 65.0
const REFRESH_SECONDS := 0.25
const REFRESH_BUDGET := 4
const ANIMATIONS := {
	"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":8.0,"loop":true},
	"attack":{"prefix":"attack","count":6,"fps":12.0,"loop":false},
	"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},
	"death":{"prefix":"death","count":4,"fps":10.0,"loop":false},
}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/Hobgoblin_Commander/frames","target_height":145.0,"animations":ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/Hobgoblin_Commander/frames","target_height":165.0,"animations":ANIMATIONS}
