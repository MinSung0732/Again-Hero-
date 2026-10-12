extends RefCounted
const BASE := {"max_hp":150,"attack_damage":28,"move_speed":180.0,"attack_range":130.0,"attack_cooldown":1.2,"exp_reward":36}
const RANGED_STATS := {"hp_multiplier":0.6,"damage_multiplier":1.35,"attack_speed_multiplier":1.6}
const RANGED_RANGE := 185.0
const PROJECTILE_SPEED := 280.0
const REPOSITION_SECONDS := 0.30
const REPOSITION_ANGLE := 0.65
const KNOCKBACK_DISTANCE := 35.0
const CLOSE_HIT_RANGE := 130.0
const CHARGE_INITIAL := 1.0
const CHARGE_COOLDOWN := 15.0
const CHARGE_SPEED := 750.0
const CHARGE_LIMIT := 2.0
const CHARGE_MULTIPLIER := 2.5
const READY_STEP := 0.02
const READY_MAX_STACKS := 20
const ANIMATIONS := {
 "idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},
 "move":{"prefix":"walk","count":6,"fps":10.0,"loop":true},
 "attack":{"prefix":"attack","count":5,"fps":12.0,"loop":false},
 "hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},
 "death":{"prefix":"death","count":4,"fps":10.0,"loop":false},
}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/lizardmanspearman/frames","target_height":117.6,"animations":ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/lizardmanspearman/frames","target_height":134.4,"animations":ANIMATIONS}
const PROJECTILE_NORMAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/lizardmanspearman/frames/effect1","target_height":100.0,"animations":{"idle":{"prefix":"projectitle","count":1,"fps":1.0,"loop":true}}}
const PROJECTILE_ELITE := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/lizardmanspearman/frames/effect1","target_height":100.0,"animations":{"idle":{"prefix":"projectitle","count":1,"fps":1.0,"loop":true}}}
