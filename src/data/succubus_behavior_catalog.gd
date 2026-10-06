extends RefCounted

const BASE := {"max_hp":240, "move_speed":155.0, "attack_damage":28, "attack_range":76.0, "attack_cooldown":0.65, "exp_reward":70}
const CHARM := {"stacks":15, "duration":2.0, "immunity":7.0, "slow_multiplier":0.6, "damage_multiplier":1.15}
const INFILTRATION := {"duration":3.0, "alpha":0.4}
const TELEPORT := {"distance":64.0, "directions":16}
const NORMAL_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/monsters/Succubus/frames", "target_height":125.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":12.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":16.0,"loop":false},
	"hit":{"prefix":"hit","count":3,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":4,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/elitemonster/Succubus/frames", "target_height":150.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":12.0,"loop":true},
	"attack":{"prefix":"atk","count":5,"fps":16.0,"loop":false},
	"skill":{"prefix":"skill","count":1,"fps":8.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
