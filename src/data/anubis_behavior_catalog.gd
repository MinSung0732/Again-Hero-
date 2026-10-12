extends RefCounted
const BASE := {"max_hp":30,"attack_damage":25,"move_speed":35.0,"attack_range":80.0,"attack_cooldown":4.0,"exp_reward":65}
const COST := 12.0
const MUMMY_STAT_STEP := 0.05
const MUMMY_SIZE_STEP := 0.003
const MAX_VISUAL_MULTIPLIER := 3.0
const MELEE_SHIELD := 15
const RANGED_SHIELD := 20
const SHIELD_STAT_BONUS := 0.25
const ELITE_STACK_STEP := 7
const ELITE_MUMMY_SPEED_STEP := 0.03
const MODES := {"anubis_ranged": {"kind":"ranged","threshold":300,"production":35.0},"anubis_melee":{"kind":"melee","threshold":300,"production":35.0},"anubis_universal":{"kind":"shield","threshold":200,"production":17.5}}
const NORMAL_ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":8.0,"loop":true},"attack":{"prefix":"attack","count":5,"fps":10.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":10.0,"loop":false}}
const ELITE_ANIMATIONS := {"idle":{"prefix":"idle","count":4,"fps":6.0,"loop":true},"move":{"prefix":"move","count":6,"fps":8.0,"loop":true},"attack":{"prefix":"attack","count":6,"fps":10.0,"loop":false},"hit":{"prefix":"hit","count":3,"fps":12.0,"loop":false},"death":{"prefix":"death","count":4,"fps":10.0,"loop":false}}
const NORMAL_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/monsters/anubis/frames","target_height":140.0,"animations":NORMAL_ANIMATIONS}
const ELITE_VISUAL := {"mode":"frames","asset_dir":"res://assets/art/elitemonster/anubis/frames","target_height":160.0,"animations":ELITE_ANIMATIONS}
static func crowd_multiplier(count: int) -> float:
	if count >= 30: return 0.50
	if count >= 20: return 0.80
	if count >= 10: return 0.90
	return 1.0
