extends RefCounted
class_name DemonAugmentCatalog

const TYPE_NORMAL := "normal"
const TYPE_SPECIAL := "special"

const NORMAL_MAX_LEVEL := 10
const SPECIAL_MAX_LEVEL := 1

const MONSTER_NAMES := {
	"banshee": "밴시",
	"slime": "슬라임",
	"spider": "거미",
	"orc": "오크",
	"bomb_rat": "폭탄쥐",
	"skeleton": "해골 전사",
	"skeleton_archer": "해골 궁병",
	"kobolt": "코볼트",
	"bat": "박쥐",
	"goblin": "고블린",
	"goblin_thrower": "고블린투척병",
	"ghost": "유령",
}

const MONSTER_NORMAL_EXCLUDED_KEYS := {
	"kobolt": ["speed"],
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
	{"id": "banshee_bleeding", "monster_id": "banshee", "name": "찢어진 상처", "description": "공격 적중 시 20% 확률로 3초 출혈 (중첩·갱신 불가)", "augment_type": TYPE_SPECIAL, "max_stack": SPECIAL_MAX_LEVEL, "icon": "", "effect_type": "banshee_bleeding", "effect_values": {"chance": 0.20, "duration": 3.0}},
	{"id": "banshee_charge_stealth", "monster_id": "banshee", "name": "핏빛 은신", "description": "돌진 중 은신 및 받는 피해 50% 감소", "augment_type": TYPE_SPECIAL, "max_stack": SPECIAL_MAX_LEVEL, "icon": "", "effect_type": "banshee_charge_stealth", "effect_values": {"damage_taken_multiplier": 0.50}},
	{"id": "banshee_death_possession", "monster_id": "banshee", "name": "서른 번째 원혼", "description": "밴시 30마리 사망마다 증강이 적용되지 않은 엘리트 밴시 소환", "augment_type": TYPE_SPECIAL, "max_stack": SPECIAL_MAX_LEVEL, "icon": "", "effect_type": "banshee_death_possession", "effect_values": {"deaths_required": 30}},
	{
		"id": "bat_lifesteal",
		"monster_id": "bat",
		"name": "흡혈",
		"description": "준 피해의 70% 회복",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bat_lifesteal",
		"effect_values": {"heal_ratio": 0.70},
	},
	{
		"id": "bat_permanent_charge",
		"monster_id": "bat",
		"name": "피의 추적",
		"description": "배회 없이 항상 용사에게 돌진",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bat_permanent_charge",
		"effect_values": {"always_charge": true},
	},
	{
		"id": "bat_echo_summon",
		"monster_id": "bat",
		"name": "메아리 군집",
		"description": "소환 시 15% 확률로 1~3마리 추가",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "bat_echo_summon",
		"effect_values": {
			"chance": 0.15,
			"min_extra_count": 1,
			"max_extra_count": 3,
		},
	},
	{
		"id": "goblin_spawn_stealth",
		"monster_id": "goblin",
		"name": "겁쟁이 은신",
		"description": "소환 후 1초 은신 · 받는 피해 -50%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_spawn_stealth",
		"effect_values": {
			"duration": 1.0,
			"damage_taken_multiplier": 0.50,
			"opacity": 0.42,
		},
	},
	{
		"id": "goblin_survivor_growth",
		"monster_id": "goblin",
		"name": "생존 진화",
		"description": "8초 생존 시 대형 고블린으로 진화",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_survivor_growth",
		"effect_values": {"survival_time": 8.0},
	},
	{
		"id": "goblin_pack_mastery",
		"monster_id": "goblin",
		"name": "대무리 결속",
		"description": "10마리 이상: 무리 보너스 +10% → +30%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_pack_mastery",
		"effect_values": {"large_pack_multiplier": 1.30},
	},
	{
		"id": "goblin_thrower_heavy_rock",
		"monster_id": "goblin_thrower",
		"name": "대형 투석",
		"description": "기본공격 시 15% 확률 · 공격력 150% 큰 돌",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_thrower_heavy_rock",
		"effect_values": {
			"chance": 0.15,
			"damage_multiplier": 1.50,
			"size_multiplier": 1.65,
		},
	},
	{
		"id": "goblin_thrower_retreat_heal",
		"monster_id": "goblin_thrower",
		"name": "겁쟁이 후퇴",
		"description": "HP 35% 이하 후퇴 · 최대 HP 6%/초 회복 · 60%에 복귀",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_thrower_retreat_heal",
		"effect_values": {
			"trigger_hp_ratio": 0.35,
			"resume_hp_ratio": 0.60,
			"heal_max_hp_per_second": 0.06,
			"retreat_speed_multiplier": 1.25,
		},
	},
	{
		"id": "goblin_thrower_rapid_fire",
		"monster_id": "goblin_thrower",
		"name": "난사",
		"description": "공격속도 +100% · 공격 간격 절반",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "goblin_thrower_rapid_fire",
		"effect_values": {"attack_speed_multiplier": 2.0},
	},
	{
		"id": "ghost_phase_shift",
		"monster_id": "ghost",
		"name": "위상도약",
		"description": "공격 후 1초 위상화 · 용사 주변으로 순간이동",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "ghost_phase_shift",
		"effect_values": {"duration": 1.0, "fade_alpha": 0.22, "min_distance": 150.0, "max_distance": 260.0},
	},
	{
		"id": "ghost_stack_slow",
		"monster_id": "ghost",
		"name": "얼어붙은 공포",
		"description": "공유 10중첩 소모 시 2초간 30% 둔화",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "ghost_stack_slow",
		"effect_values": {"slow_multiplier": 0.70, "duration": 2.0},
	},
	{
		"id": "ghost_death_empower",
		"monster_id": "ghost",
		"name": "망자의 유산",
		"description": "사망 시 무작위 아군 1기 모든 전투 능력 +10% · 누적",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "ghost_death_empower",
		"effect_values": {"stat_multiplier": 1.10},
	},
	{
		"id": "kobolt_projectile_speed",
		"monster_id": "kobolt",
		"name": "고속 투창",
		"description": "창 투사체 속도 +20%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "kobolt_projectile_speed",
		"effect_values": {"speed_multiplier": 1.20},
	},
	{
		"id": "kobolt_unlimited_range",
		"monster_id": "kobolt",
		"name": "무제한 조준",
		"description": "사거리 제한 제거 · 기본 사거리 밖 피해 거리 비례 감소(최대 -50%)",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "kobolt_unlimited_range",
		"effect_values": {
			"unlimited_range": true,
			"damage_falloff_distance": 1050.0,
			"min_damage_multiplier": 0.50,
		},
	},
	{
		"id": "kobolt_giant_fusion",
		"monster_id": "kobolt",
		"name": "거대 융합",
		"description": "근처 일반 코볼트 4기 → 대형 1기 · 대형/엘리트는 집계 제외",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "kobolt_giant_fusion",
		"effect_values": {"radius": 180.0, "required_count": 4},
	},
	{
		"id": "skeleton_archer_power_shot",
		"monster_id": "skeleton_archer",
		"name": "강령 사격",
		"description": "조준 0.25초 · 기본공격 피해 +60%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_archer_power_shot",
		"effect_values": {"windup_delay": 0.25, "damage_multiplier": 1.60},
	},
	{
		"id": "skeleton_archer_revive",
		"monster_id": "skeleton_archer",
		"name": "불사의 사수",
		"description": "첫 사망 시 2초 후 HP 100%로 1회 부활",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_archer_revive",
		"effect_values": {"revive_delay": 2.0, "revive_hp_ratio": 1.0},
	},
	{
		"id": "skeleton_archer_triple_shot",
		"monster_id": "skeleton_archer",
		"name": "삼연사",
		"description": "기본공격이 0.4초 간격 3연사로 변경",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_archer_triple_shot",
		"effect_values": {"shot_count": 3, "shot_interval": 0.40},
	},
	{
		"id": "skeleton_return_of_dead",
		"monster_id": "skeleton",
		"name": "망자의 귀환",
		"description": "첫 사망 시 2초 후 HP 100%로 1회 부활",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_return_of_dead",
		"effect_values": {"revive_delay": 2.0, "revive_hp_ratio": 1.0},
	},
	{
		"id": "skeleton_bone_bond",
		"monster_id": "skeleton",
		"name": "뼈의 결속",
		"description": "주변 3기 이상: 공격력·이속·공속 +10%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_bone_bond",
		"effect_values": {
			"radius": 75.0,
			"required_count": 3,
			"damage_multiplier": 1.10,
			"move_speed_multiplier": 1.10,
			"attack_speed_multiplier": 1.10,
			"refresh_interval": 0.12,
		},
	},
	{
		"id": "skeleton_necrotic_guard",
		"monster_id": "skeleton",
		"name": "사령의 가호",
		"description": "엘리트 해골 전사 생존 중 모든 해골 전사 받는 피해 -25%",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "skeleton_necrotic_guard",
		"effect_values": {"damage_taken_multiplier": 0.75},
	},
	{
		"id": "slime_cell_division",
		"monster_id": "slime",
		"name": "세포 분열",
		"description": "슬라임 소환 시 1기 추가",
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
		"description": "사망 시 HP·공격력 50% 소형 슬라임 1기 생성",
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
		"description": "주변 2기 이상: 이속 +18% · 공속 +20%",
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
		"description": "HP 50% 이하: 이속·공속 +25%",
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
		"description": "피격마다 공속 +4% · 최대 10중첩",
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
		"description": "HP 30% 이하: 속도 220%로 0.75초 1회 돌진",
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
		"description": "비자폭 사망 시 HP 50% 폭탄쥐 2기 생성",
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
		"description": "2초마다 자폭 반경 +12 · 최대 +72",
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
		"description": "잃은 HP에 비례해 자폭 피해 증가 · 최대 +75%",
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
		"description": "기본공격이 부채꼴 3발로 변경",
		"augment_type": TYPE_SPECIAL,
		"max_stack": SPECIAL_MAX_LEVEL,
		"icon": "",
		"effect_type": "spider_triple_web",
		"effect_values": {
			"shot_count": 3,
			"damage_multiplier": 1.0,
			"spread_degrees": 18.0,
		},
	},
	{
		"id": "spider_sticky_web",
		"monster_id": "spider",
		"name": "끈끈한 거미줄",
		"description": "둔화 28% → 44% · 지속 1.5초 → 2.2초",
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
		"description": "4회 적중: 1.1초간 62% 둔화 · 쿨 4초",
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

	for monster_id in [
		"slime",
		"spider",
		"orc",
		"bomb_rat",
		"skeleton",
		"skeleton_archer",
		"kobolt",
		"bat",
		"goblin",
		"goblin_thrower",
		"ghost",
	]:
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
		var excluded_keys: Array = MONSTER_NORMAL_EXCLUDED_KEYS.get(
			monster_id,
			[]
		)
		if key in excluded_keys:
			continue
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
		for raw_augment in get_monster_normal_augments(
			monster_id,
			monster_name
		):
			var augment: Dictionary = raw_augment
			_append_normal_candidate(
				pool,
				augment,
				build_counts,
				exclude_ids
			)

	var result: Array = []
	var selected_monster_counts: Dictionary = {}
	while not pool.is_empty() and result.size() < count:
		var eligible_indices: Array[int] = []
		for index in range(pool.size()):
			var candidate: Dictionary = pool[index]
			var target_monster_id := String(
				candidate.get("target_monster_id", "")
			)
			if target_monster_id.is_empty():
				eligible_indices.append(index)
				continue

			var selected_count := int(
				selected_monster_counts.get(
					target_monster_id,
					0
				)
			)
			if selected_count < 2:
				eligible_indices.append(index)

		# If the only remaining candidates belong to a monster already
		# selected twice, allow them rather than returning fewer cards.
		if eligible_indices.is_empty():
			for index in range(pool.size()):
				eligible_indices.append(index)

		var selected_index := _weighted_candidate_index(
			pool,
			eligible_indices,
			build_counts
		)
		if selected_index < 0:
			break

		var selected: Dictionary = pool[selected_index]
		result.append(selected)
		var selected_monster_id := String(
			selected.get("target_monster_id", "")
		)
		if not selected_monster_id.is_empty():
			selected_monster_counts[selected_monster_id] = (
				int(
					selected_monster_counts.get(
						selected_monster_id,
						0
					)
				)
				+ 1
			)
		pool.remove_at(selected_index)

	return result

static func _weighted_candidate_index(
	pool: Array,
	eligible_indices: Array[int],
	build_counts: Dictionary
) -> int:
	if eligible_indices.is_empty():
		return -1

	var total_weight := 0.0
	var weights: Array[float] = []
	for pool_index in eligible_indices:
		var candidate: Dictionary = pool[pool_index]
		var weight := _normal_candidate_weight(
			candidate,
			build_counts
		)
		weights.append(weight)
		total_weight += weight

	if total_weight <= 0.0:
		return int(eligible_indices.pick_random())

	var roll := randf() * total_weight
	var cursor := 0.0
	for weight_index in range(weights.size()):
		cursor += weights[weight_index]
		if roll <= cursor:
			return int(eligible_indices[weight_index])

	return int(eligible_indices.back())

static func _normal_candidate_weight(
	candidate: Dictionary,
	build_counts: Dictionary
) -> float:
	var augment_id := String(candidate.get("id", ""))
	var current_stack := int(build_counts.get(augment_id, 0))
	var weight := 1.0

	if current_stack >= 8:
		weight *= 1.30
	elif current_stack >= 4:
		weight *= 1.20
	elif current_stack >= 1:
		weight *= 1.10

	var monster_id := String(
		candidate.get("target_monster_id", "")
	)
	if not monster_id.is_empty():
		var monster_investment := 0
		var prefix := "%s_" % monster_id
		for raw_id in build_counts.keys():
			var build_id := String(raw_id)
			if not build_id.begins_with(prefix):
				continue
			monster_investment += int(
				build_counts.get(build_id, 0)
			)
		if monster_investment > 0:
			weight *= 1.10

	return weight

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
