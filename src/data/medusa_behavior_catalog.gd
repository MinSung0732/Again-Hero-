extends RefCounted
const BASE := {"max_hp": 110, "move_speed": 140.0, "attack_damage": 6, "attack_range": 72.0, "attack_cooldown": 0.65, "exp_reward": 38}
const PURSUIT := {"growth_per_second": 0.10, "max_multiplier": 2.0}
const STONE := {"initial_stacks": 10, "threshold_growth": 1, "duration": 2.5, "tint": Color(0.72,0.72,0.72,1.0)}
const NORMAL_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/monsters/medusa/frames", "target_height":100.0, "animations":{
	"idle":{"prefix":"idle","count":5,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":5,"fps":11.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":14.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/elitemonster/medusa/frames", "target_height":120.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":11.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":14.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
