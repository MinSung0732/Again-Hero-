extends RefCounted
class_name DemonAugmentCatalog

const TYPE_NORMAL := "normal"
const TYPE_SPECIAL := "special"

const NORMAL_MAX_LEVEL := 10
const SPECIAL_MAX_LEVEL := 1

const MONSTER_NAMES := {
	"slime": "슬라임",
	"spider": "거미",
	"orc": "오크",
	"bomb_rat": "폭탄쥐",
}

const NORMAL_AUGMENTS := [
	{
		"id": "command_capacity",
		"name": "최대 지휘력 증가",
		"description": "최대 지휘력 +10",
		"category": "command",
		"target_type": "demon",
		"target_monster_id": "",
		"max_stack": NORMAL_MAX_LEVEL,
		"augment_type": TYPE_NORMAL,
		"icon": "",
		"effects": [{"op": "add_command_capacity", "value": 10.0}],
	},
	{
		"id": "command_regen",
		"name": "초당 지휘력 증가",
		"description": "지휘력 자동 회복 +0.25 /초",
		"category": "command",
		"target_type": "demon",
		"target_monster_id": "",
		"max_stack": NORMAL_MAX_LEVEL,
		"augment_type": TYPE_NORMAL,
		"icon": "",
		"effects": [{"op": "add_runtime", "target": "command_regen_per_second", "value": 0.25}],
	},
	{
		"id": "death_refund",
		"name": "사망 지휘력 환급",
		"description": "사망 시 실제 생산비용 환급률 +3%",
		"category": "command",
		"target_type": "demon",
		"target_monster_id": "",
		"max_stack": NORMAL_MAX_LEVEL,
		"augment_type": TYPE_NORMAL,
		"icon": "",
		"effects": [{"op": "add_runtime", "target": "death_refund_ratio", "value": 0.03, "max": 0.30}],
	},
	{
		"id": "global_cost_down",
		"name": "전체 생산비용 감소",
		"description": "모든 몬스터 생산비용 -3%",
		"category": "command",
		"target_type": "all_monsters",
		"target_monster_id": "",
		"max_stack": NORMAL_MAX_LEVEL,
		"augment_type": TYPE_NORMAL,
		"icon": "",
		"effects": [{"op": "multiply_runtime", "target": "summon_cost_multiplier", "value": 0.97, "min": 0.60}],
	},
	{
		"id": "demon_exp_gain",
		"name": "침략 학습",
		"description": "몬스터 소환으로 얻는 마왕 EXP +5%",
		"category": "growth",
		"target_type": "demon",
		"target_monster_id": "",
		"max_stack": 20,
		"augment_type": TYPE_NORMAL,
		"icon": "",
		"effects": [
			{
				"op": "add_runtime",
				"target": "demon_exp_gain_multiplier",
				"value": 0.05,
			},
		],
	},
]

const MONSTER_NORMAL_TEMPLATES := [
	{
		"key": "damage",
		"name_suffix": "공격력 증가",
		"description": "공격력 +6%",
		"effect": {"op": "monster_multiplier", "stat": "damage", "value": 1.06},
	},
	{
		"key": "hp",
		"name_suffix": "최대 체력 증가",
		"description": "최대 체력 +8%",
		"effect": {"op": "monster_multiplier", "stat": "hp", "value": 1.08},
	},
	{
		"key": "speed",
		"name_suffix": "이동속도 증가",
		"description": "이동속도 +4%",
		"effect": {"op": "monster_multiplier", "stat": "speed", "value": 1.04},
	},
	{
		"key": "attack_speed",
		"name_suffix": "공격속도 증가",
		"description": "공격 간격 -4%",
		"effect": {"op": "monster_multiplier", "stat": "attack_cooldown", "value": 0.96},
	},
	{
		"key": "cost",
		"name_suffix": "생산비용 감소",
		"description": "생산비용 -4%",
		"effect": {"op": "monster_multiplier", "stat": "cost", "value": 0.96, "min": 0.60},
	},
]

const SPECIAL_AUGMENTS := [
	{
		"id": "slime_cell_division",
		"monster_id": "slime",
		"name": "세포 분열",
		"description": "슬라임을 정상 생산할 때 비용 없이 슬라임 1마리를 추가 생성합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "slime_cell_division",
		"effect_values": {"extra_count": 1},
	},
	{
		"id": "slime_residual_mucus",
		"monster_id": "slime",
		"name": "잔여 점액",
		"description": "정상 슬라임이 사망하면 체력/공격력 50%의 작은 슬라임 1마리를 생성합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "slime_residual_mucus",
		"effect_values": {"count": 1, "hp_multiplier": 0.50, "damage_multiplier": 0.50},
	},
	{
		"id": "slime_pack_instinct",
		"monster_id": "slime",
		"name": "군집 본능",
		"description": "가까운 다른 슬라임이 2마리 이상이면 이동속도와 공격속도가 증가합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "slime_pack_instinct",
		"effect_values": {
			"radius": 180.0,
			"required_nearby": 2,
			"move_speed_multiplier": 1.18,
			"attack_speed_multiplier": 1.20,
		},
	},
	{
		"id": "orc_berserk",
		"monster_id": "orc",
		"name": "광폭화",
		"description": "체력이 50% 이하이면 이동속도와 공격속도가 증가합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "orc_berserk",
		"effect_values": {
			"hp_ratio": 0.50,
			"move_speed_multiplier": 1.25,
			"attack_speed_multiplier": 1.25,
			"dynamic": true,
		},
	},
	{
		"id": "orc_rage_stacks",
		"monster_id": "orc",
		"name": "분노 누적",
		"description": "용사에게 피격될 때마다 분노가 쌓여 공격속도가 증가합니다. 최대 10중첩.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "orc_rage_stacks",
		"effect_values": {"max_stacks": 10, "attack_speed_per_stack": 0.04},
	},
	{
		"id": "orc_last_charge",
		"monster_id": "orc",
		"name": "최후의 돌진",
		"description": "체력이 30% 이하로 처음 내려가면 용사를 향해 1회 빠르게 돌진합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "orc_last_charge",
		"effect_values": {"hp_ratio": 0.30, "duration": 0.75, "speed_multiplier": 2.20},
	},
	{
		"id": "bomb_rat_litter",
		"monster_id": "bomb_rat",
		"name": "새끼 폭탄쥐",
		"description": "자폭이 아닌 사망 시 체력 50%의 폭탄쥐 2마리로 분열합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bomb_rat_litter",
		"effect_values": {"count": 2, "hp_multiplier": 0.50},
	},
	{
		"id": "bomb_rat_powder_overload",
		"monster_id": "bomb_rat",
		"name": "화약 과적재",
		"description": "생존 시간이 길어질수록 자폭 범위가 증가합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bomb_rat_powder_overload",
		"effect_values": {"interval": 2.0, "radius_per_interval": 12.0, "max_bonus_radius": 72.0},
	},
	{
		"id": "bomb_rat_unstable_powder",
		"monster_id": "bomb_rat",
		"name": "불안정 화약",
		"description": "현재 체력이 낮을수록 자폭 피해가 증가합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bomb_rat_unstable_powder",
		"effect_values": {"max_damage_bonus": 0.75},
	},
	{
		"id": "spider_triple_web",
		"monster_id": "spider",
		"name": "삼중 거미줄",
		"description": "기본 공격 시 같은 용사를 향해 거미줄을 3회 연속 발사합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "spider_triple_web",
		"effect_values": {"shot_count": 3, "damage_multiplier": 0.55, "shot_interval": 0.12},
	},
	{
		"id": "spider_sticky_web",
		"monster_id": "spider",
		"name": "끈끈한 거미줄",
		"description": "기본 거미줄의 둔화율과 둔화 지속시간을 강화합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "spider_sticky_web",
		"effect_values": {"slow_multiplier_factor": 0.78, "duration_multiplier": 1.45},
	},
	{
		"id": "spider_binding",
		"monster_id": "spider",
		"name": "속박",
		"description": "거미줄이 누적 적중하면 짧은 시간 매우 강한 둔화를 적용합니다.",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "spider_binding",
		"effect_values": {
			"required_hits": 4,
			"slow_multiplier": 0.38,
			"duration": 1.10,
			"cooldown": 4.0,
		},
	},
]

static func is_special_level(level: int) -> bool:
	return level >= 10 and level % 5 == 0

static func get_augment(augment_id: String) -> Dictionary:
	for augment in NORMAL_AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)

	for monster_id in ["slime", "spider", "orc", "bomb_rat"]:
		for augment in get_monster_normal_augments(monster_id, ""):
			if String(augment.get("id", "")) == augment_id:
				return augment.duplicate(true)

	for augment in SPECIAL_AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)

	return {}

static func get_monster_normal_augments(
	monster_id: String,
	monster_name: String
) -> Array:
	if monster_id.is_empty():
		return []

	var display_name := (
		monster_name
		if not monster_name.is_empty()
		else String(MONSTER_NAMES.get(monster_id, monster_id))
	)
	var result: Array = []
	for raw_template in MONSTER_NORMAL_TEMPLATES:
		var template: Dictionary = raw_template
		var key := String(template.get("key", ""))
		var effect: Dictionary = template.get("effect", {}).duplicate(true)
		effect["monster_id"] = monster_id
		result.append({
			"id": "%s_%s" % [monster_id, key],
			"name": "%s %s" % [display_name, String(template.get("name_suffix", ""))],
			"description": String(template.get("description", "")),
			"category": "monster",
			"target_type": "monster",
			"target_monster_id": monster_id,
			"max_stack": NORMAL_MAX_LEVEL,
			"augment_type": TYPE_NORMAL,
			"icon": "",
			"effects": [effect],
		})
	return result

static func roll_normal_candidates(
	loadout_ids: Array,
	monster_names: Dictionary,
	build_counts: Dictionary,
	exclude_ids: Array = [],
	count: int = 3
) -> Array:
	var pool: Array = []
	for raw_augment in NORMAL_AUGMENTS:
		var augment: Dictionary = raw_augment
		_append_normal_candidate(pool, augment, build_counts, exclude_ids)

	for raw_monster_id in loadout_ids:
		var monster_id := String(raw_monster_id)
		if monster_id.is_empty():
			continue
		var monster_name := String(monster_names.get(monster_id, monster_id))
		for raw_augment in get_monster_normal_augments(monster_id, monster_name):
			var augment: Dictionary = raw_augment
			_append_normal_candidate(pool, augment, build_counts, exclude_ids)

	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

static func roll_special_candidates(
	loadout_ids: Array,
	acquired_special_ids: Array,
	exclude_ids: Array = [],
	count: int = 3
) -> Array:
	var per_monster: Dictionary = {}
	for raw_monster_id in loadout_ids:
		var monster_id := String(raw_monster_id)
		if monster_id.is_empty():
			continue
		var options: Array = []
		for raw_augment in SPECIAL_AUGMENTS:
			var augment: Dictionary = raw_augment
			var augment_id := String(augment.get("id", ""))
			if String(augment.get("monster_id", "")) != monster_id:
				continue
			if augment_id in acquired_special_ids or augment_id in exclude_ids:
				continue
			options.append(augment.duplicate(true))
		if not options.is_empty():
			options.shuffle()
			per_monster[monster_id] = options[0]

	var monster_pool: Array = per_monster.keys()
	monster_pool.shuffle()
	var result: Array = []
	for raw_monster_id in monster_pool:
		var monster_id := String(raw_monster_id)
		result.append(per_monster[monster_id])
		if result.size() >= count:
			break
	return result

static func get_special_augments_for_monster(monster_id: String) -> Array:
	var result: Array = []
	for raw_augment in SPECIAL_AUGMENTS:
		var augment: Dictionary = raw_augment
		if String(augment.get("monster_id", "")) == monster_id:
			result.append(augment.duplicate(true))
	return result

static func _append_normal_candidate(
	pool: Array,
	augment: Dictionary,
	build_counts: Dictionary,
	exclude_ids: Array
) -> void:
	var augment_id := String(augment.get("id", ""))
	if augment_id.is_empty() or augment_id in exclude_ids:
		return

	var current_stack := int(build_counts.get(augment_id, 0))
	var max_stack := int(augment.get("max_stack", NORMAL_MAX_LEVEL))
	if current_stack >= max_stack:
		return

	var candidate := augment.duplicate(true)
	candidate["current_stack"] = current_stack
	pool.append(candidate)
