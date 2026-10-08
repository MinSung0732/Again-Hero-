extends RefCounted

const BASE := {"max_hp":48, "move_speed":145.0, "attack_damage":4, "attack_range":58.0, "attack_cooldown":0.65, "exp_reward":18}
const POISON_DURATION := 10.0
const FOLLOWUP_DELAY := 0.12
const CONSUME := {"radius":250.0, "initial_cooldown":3.0, "cooldown":7.0}
const NORMAL_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/monsters/Scorpion/frames", "target_height":90.0, "animations":{
	"idle":{"prefix":"idle","count":5,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":12.0,"loop":true},
	"attack":{"prefix":"atk","count":5,"fps":16.0,"loop":false},
	"hit":{"prefix":"hit","count":4,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":3,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/elitemonster/Scorpion/frames", "target_height":110.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":7,"fps":12.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":16.0,"loop":false},
	"hit":{"prefix":"hit","count":3,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":3,"fps":10.0,"loop":false}}}

# Source manifest: common406x366 cells, ground anchor(203,341).
# Largest visible union width386; one scale across all eight frames.
const SWAMP_VISUAL := {
	"directory":"res://assets/art/monsters/Scorpion/frames/effect1",
	"frame_count":8, "anchor":Vector2(203,341), "reference_width":386.0,
	"frame_seconds":0.12, "intro_count":3, "loop_first":3, "loop_count":2,
	"outro_first":5, "outro_count":3,
}
