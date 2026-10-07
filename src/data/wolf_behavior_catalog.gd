extends RefCounted

const BASE := {"max_hp":100, "move_speed":160.0, "attack_damage":12, "attack_range":68.0, "attack_cooldown":0.65, "exp_reward":27}
const HOWL := {"radius":250.0, "cast_time":1.0, "duration":10.0, "refresh_threshold":2.0, "damage_multiplier":1.15}
const FOLLOWUP_DELAY := 0.16
const PACK := {"count":12, "cast_time":1.0, "speed_multiplier":1.30, "spawn_budget":2, "spacing":42.0, "back_distance":65.0}
const NORMAL_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/monsters/wolf/frames", "target_height":100.0, "animations":{
	"idle":{"prefix":"idle","count":4,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":6,"fps":14.0,"loop":true},
	"attack":{"prefix":"atk","count":6,"fps":16.0,"loop":false},
	"hit":{"prefix":"hit","count":3,"fps":14.0,"loop":false},
	"skill":{"prefix":"skill","count":3,"fps":3.0,"loop":false},
	"death":{"prefix":"dead","count":5,"fps":10.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames", "asset_dir":"res://assets/art/elitemonster/wolf/frames", "target_height":115.0, "animations":{
	"idle":{"prefix":"idle","count":8,"fps":8.0,"loop":true},
	"move":{"prefix":"walk","count":5,"fps":14.0,"loop":true},
	"attack":{"prefix":"atk","count":7,"fps":16.0,"loop":false},
	"hit":{"prefix":"hit","count":3,"fps":14.0,"loop":false},
	"skill":{"prefix":"hit","count":3,"fps":3.0,"loop":false},
	"death":{"prefix":"dead","count":9,"fps":12.0,"loop":false}}}
