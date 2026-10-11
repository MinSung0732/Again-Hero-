extends RefCounted
const BASE := {"max_hp":420,"attack_damage":18,"move_speed":65.0,"attack_range":85.0,"attack_cooldown":2.6,"exp_reward":50}
const THIRD_HIT_MULTIPLIER := 0.70
const HIT_INTERVAL := 3
const MEDIUM_SCALE := 1.15
const MEDIUM_STATS := {"hp_multiplier":1.5,"damage_multiplier":1.5,"speed_multiplier":1.1,"attack_speed_multiplier":1.1}
const MEDIUM_INCOMING := 0.80
const FURY_STATS := {"hp_multiplier":0.5,"damage_multiplier":3.5,"speed_multiplier":2.0,"attack_speed_multiplier":2.5}
const FURY_ROLE := "exploder"
const NULLIFY_CHANCE := 0.05
const REFLECT_CHANCE := 0.05
const REFLECT_RATIO := 0.80
const ANIMATIONS := {
 "idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},
 "move":{"prefix":"walk","count":6,"fps":8.0,"loop":true},
 "attack":{"prefix":"attack","count":4,"fps":10.0,"loop":false},
 "hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},
 "death":{"prefix":"death","count":4,"fps":10.0,"loop":false},
}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/ogre/frames","target_height":155.0,"animations":ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/ogre/frames","target_height":175.0,"animations":ANIMATIONS}
