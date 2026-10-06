extends RefCounted

const BASE := {"max_hp":125, "move_speed":92.0, "attack_damage":13, "attack_range":76.0, "attack_cooldown":1.1, "exp_reward":32}
const SHIELD_RATIO := 0.50
const NORMAL_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/monsters/mummy/frames", "target_height":110.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":7.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":9.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":12.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":12.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/elitemonster/mummy/frames", "target_height":130.0, "animations":NORMAL_VISUAL.animations}
