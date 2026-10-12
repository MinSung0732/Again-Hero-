extends RefCounted
const COST := 10.0
const BASE := {"max_hp":158,"attack_damage":9,"explosion_damage":126,"move_speed":180.0,"attack_range":80.0,"attack_cooldown":1.4,"hits_per_attack":2,"hit_damage_multiplier":1.0,"exp_reward":32}
const FOLLOWUP_DELAY := 0.14
const EXPLOSION_RADIUS := 87.5
const DEATH_DELAY := 1.5
const RITUAL_COUNT := 10
const RITUAL_DURATION := 1.5
const ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":10.0,"loop":true},"attack":{"prefix":"attack","count":6,"fps":14.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":10.0,"loop":false}}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/fanatic/frames","target_height":140.0,"animations":ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/fanatic/frames","target_height":160.0,"animations":ANIMATIONS}
const EXPLOSION_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/bombrat/frames/effect","target_height":175.0,"animations":{"idle":{"prefix":"frame","count":8,"fps":14.0,"loop":false}}}
const ORB_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/ghost/frames/effect1","target_height":48.0,"animations":{"idle":{"prefix":"Projectile","count":1,"fps":1.0,"loop":true}}}
