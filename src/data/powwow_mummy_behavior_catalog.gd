extends RefCounted
const BASE := {"max_hp":62,"move_speed":44.0,"attack_damage":5,"attack_range":237.5,"attack_range_diameter":475.0,"attack_cooldown":2.0,"projectile_speed":275.0,"projectile_range":285.5,"exp_reward":22}
const BUFF := {"interval":20.0,"duration":10.0,"cast_duration":0.4,"damage_ratio":0.15,"shield_ratio":0.10,"heal_missing_ratio":0.05,"speed_ratio":0.50}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/powwowmummy/frames","target_height":110.0,"death_fade_duration":0.55,"animations":{
	"idle":{"prefix":"idle","count":4,"fps":7.0,"loop":true},
	"move":{"prefix":"walk","count":4,"fps":7.0,"loop":true},
	"attack":{"prefix":"atk","count":4,"fps":10.0,"loop":false},
	"skill":{"files":["skill_01.png","skill_02.png","skill_03.png","skill_03.png"],"count":4,"fps":10.0,"loop":false},
	"hit":{"prefix":"hit","count":2,"fps":12.0,"loop":false}}}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/powwowmummy/frames","target_height":130.0,"death_fade_duration":0.55,"animations":{
	"idle":{"prefix":"idle","count":4,"fps":7.0,"loop":true},
	"move":{"prefix":"walk","count":4,"fps":7.0,"loop":true},
	"attack":{"prefix":"atk","count":3,"fps":10.0,"loop":false},
	"skill":{"prefix":"skill","count":4,"fps":10.0,"loop":false}}}
