extends RefCounted
const BASE := {"max_hp":150,"attack_damage":22,"move_speed":180.0,"attack_range":80.0,"attack_cooldown":0.8,"exp_reward":36}
const FAMILY := "lizardman"
const TAIL_TRIGGER_RATIO := 0.30
const ESCAPE_DISTANCE := 400.0
const ESCAPE_SECONDS := 0.35
const TAIL_LIFETIME := 3.0
const TAIL_BLINK_START := 2.0
const TAIL_BLINK_SECONDS := 0.12
const RECOVERY_RATIO := 0.35
const FOOD_STAT_STEP := 0.02
const NORMAL_ANIMATIONS := {
 "idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},
 "move":{"prefix":"walk","count":6,"fps":10.0,"loop":true},
 "attack":{"prefix":"attack","count":6,"fps":14.0,"loop":false},
 "hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},
 "death":{"prefix":"death","count":4,"fps":10.0,"loop":false},
}
const ELITE_ANIMATIONS := {
 "idle":{"prefix":"idle","count":3,"fps":6.0,"loop":true},
 "move":{"prefix":"walk","count":6,"fps":10.0,"loop":true},
 "attack":{"prefix":"attack","count":6,"fps":14.0,"loop":false},
 "hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},
 "death":{"prefix":"death","count":4,"fps":10.0,"loop":false},
}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/lizardmanfighter/frames","target_height":130.0,"animations":NORMAL_ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/lizardmanfighter/frames","target_height":150.0,"animations":ELITE_ANIMATIONS}
const TAIL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/lizardmanfighter/frames/effect1","target_height":36.0,"animations":{"idle":{"prefix":"tail","count":8,"fps":12.0,"loop":false}}}
