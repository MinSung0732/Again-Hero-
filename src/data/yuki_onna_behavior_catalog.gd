extends RefCounted

const BASE := {"max_hp":100,"move_speed":100.0,"attack_damage":12,"attack_range":200.0,"attack_cooldown":1.6,"projectile_speed":250.0,"projectile_range":248.0,"exp_reward":30}
const SLOW := {"ratio":0.10,"duration":5.0,"max_stacks":10}
const CHILL := {"radius":250.0,"duration":5.0,"max_stacks":5,"attack_speed":1.10,"projectile_speed":1.05,"slow_strength":1.02}
const SNOWFLAKE := {"damage_multiplier":2.0,"duration":2.0,"move_multiplier":0.01}
const FAN_ANGLE := 0.2617993878 # 15 degrees on each side.
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/Yuki-onna/frames","target_height":115.0,"animations":{
	"idle":{"prefix":"idle","count":5,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":4,"fps":10.0,"loop":true},
	"attack":{"prefix":"atk","count":7,"fps":10.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":14.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/Yuki-onna/frames","target_height":125.0,"animations":{
	"idle":{"prefix":"idle","count":5,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":4,"fps":10.0,"loop":true},
	"attack":{"prefix":"atk","count":4,"fps":10.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":14.0,"loop":false},
	"skill":{"prefix":"skill","count":3,"fps":10.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
