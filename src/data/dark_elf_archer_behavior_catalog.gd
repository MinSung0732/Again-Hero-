extends RefCounted
const COST := 12.0
const BASE := {"max_hp":97,"attack_damage":30,"move_speed":180.0,"attack_range":375.0,"attack_range_diameter":750.0,"attack_cooldown":1.4,"projectile_speed":280.0,"projectile_range":375.0,"exp_reward":35}
const STEALTH_DELAY := 3.0
const STEALTH_DAMAGE_RATIO := 0.5
const AMBUSH_MULTIPLIER := 1.5
const STEALTH_ALPHA := 0.40
const REPOSITION_DISTANCE := 85.0
const REPOSITION_SPEED_MULTIPLIER := 2.0
const BURST_INTERVAL := 0.18
const BURST_DAMAGE := 1.25
const BURST_SHOTS := 4
const NORMAL_ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":10.0,"loop":true},"attack":{"prefix":"attack","count":7,"fps":14.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":5,"fps":10.0,"loop":false}}
const ELITE_ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":10.0,"loop":true},"attack":{"prefix":"attack","count":6,"fps":14.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":10.0,"loop":false}}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/dark_elf_archer/frames","target_height":165.2,"animations":NORMAL_ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/dark_elf_archer/frames","target_height":188.8,"animations":ELITE_ANIMATIONS}
const ARROW_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/dark_elf_archer/frames/effect1","target_height":39.24,"animations":{"idle":{"prefix":"projectile","count":6,"fps":12.0,"loop":true},"impact":{"prefix":"impact","count":6,"fps":15.0,"loop":false}}}
