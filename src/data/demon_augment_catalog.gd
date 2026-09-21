extends RefCounted
class_name DemonAugmentCatalog

const AUGMENTS = [
	{
		"id": "dark_current",
		"name": "어둠의 순환",
		"description": "지휘력 회복 +0.45 /초",
		"max_stack": 4,
		"effects": [
			{"op": "add_runtime", "target": "command_regen_per_second", "value": 0.45},
		],
	},
	{
		"id": "war_economy",
		"name": "전쟁 경제",
		"description": "모든 몬스터 소환 비용 -10%",
		"max_stack": 3,
		"effects": [
			{"op": "multiply_runtime", "target": "summon_cost_multiplier", "value": 0.90},
		],
	},
	{
		"id": "legion_drill",
		"name": "군단 훈련",
		"description": "새로 소환되는 몬스터 이동속도 +7%",
		"max_stack": 2,
		"effects": [
			{"op": "multiply_runtime", "target": "monster_speed_multiplier", "value": 1.07},
		],
	},
	{
		"id": "blood_recycling",
		"name": "시체 재활용",
		"description": "몬스터 사망 시 실제 소환 비용의 12% 지휘력 환급 추가",
		"max_stack": 3,
		"effects": [
			{"op": "add_runtime", "target": "death_refund_ratio", "value": 0.12, "max": 0.36},
		],
	},
	{
		"id": "slime_mitosis",
		"name": "분열 실험",
		"description": "슬라임 사망 시 무료 슬라임 생성 확률 +15%",
		"max_stack": 3,
		"effects": [
			{"op": "add_runtime", "target": "slime_split_chance", "value": 0.15, "max": 0.45},
		],
	},
	{
		"id": "venom_nest",
		"name": "독거미 둥지",
		"description": "새 거미의 둔화 지속시간 +20%",
		"max_stack": 2,
		"effects": [
			{"op": "multiply_runtime", "target": "spider_slow_duration_multiplier", "value": 1.20},
		],
	},
	{
		"id": "orc_fortify",
		"name": "오크 중장갑",
		"description": "새 오크 최대 HP +12%",
		"max_stack": 3,
		"effects": [
			{"op": "multiply_runtime", "target": "orc_hp_multiplier", "value": 1.12},
		],
	},
	{
		"id": "cruel_command",
		"name": "잔혹한 명령",
		"description": "새로 소환되는 몬스터 공격력 +6%",
		"max_stack": 2,
		"effects": [
			{"op": "multiply_runtime", "target": "monster_damage_multiplier", "value": 1.06},
		],
	},
	{
		"id": "dark_reservoir",
		"name": "마력 비축",
		"description": "최대 지휘력 +15, 즉시 지휘력 +15",
		"max_stack": 4,
		"effects": [
			{"op": "add_command_capacity", "value": 15.0},
		],
	},
]

static func get_augment(augment_id: String) -> Dictionary:
	for augment in AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)
	return {}

static func roll_candidates(
	exclude_ids: Array,
	count: int = 3,
	build_counts: Dictionary = {}
) -> Array:
	var pool: Array = []

	for raw_augment in AUGMENTS:
		var augment: Dictionary = raw_augment
		var augment_id: String = String(augment.get("id", ""))
		if augment_id in exclude_ids:
			continue

		var current_stack := int(build_counts.get(augment_id, 0))
		var max_stack := int(augment.get("max_stack", 0))
		if max_stack > 0 and current_stack >= max_stack:
			continue

		var candidate := augment.duplicate(true)
		candidate["current_stack"] = current_stack
		pool.append(candidate)

	pool.shuffle()

	var result: Array = []
	for index in range(mini(count, pool.size())):
		result.append(pool[index])
	return result
