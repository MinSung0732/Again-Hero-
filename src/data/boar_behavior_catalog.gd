extends RefCounted
const COST := 8.0
const BASE := {"max_hp":120,"attack_damage":74,"move_speed":175.0,"attack_range":275.0,"attack_range_diameter":550.0,"attack_cooldown":1.4,"exp_reward":30}
const WINDUP := 0.3
const DASH_DISTANCE := 900.0
const MIN_SPEED := 50.0
const MAX_SPEED := 425.0
const ACCELERATION := 375.0
const THIRD_SPEED := 200.0
const CONTACT_RADIUS := 45.0
const ELITE_DURATION := 10.0
const ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":10.0,"loop":true},"attack":{"prefix":"attack","count":6,"fps":12.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":10.0,"loop":false}}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/boar/frames","target_height":157.3,"animations":ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/boar/frames","target_height":181.5,"animations":ANIMATIONS}
