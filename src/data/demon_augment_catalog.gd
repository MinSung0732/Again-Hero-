extends RefCounted
class_name DemonAugmentCatalog

const AUGMENTS = [
	{
		"id": "dark_current",
		"name": "어둠의 순환",
		"description": "지휘력 회복 +0.8 /초",
	},
	{
		"id": "war_economy",
		"name": "전쟁 경제",
		"description": "모든 몬스터 소환 비용 -15%",
	},
	{
		"id": "legion_drill",
		"name": "군단 훈련",
		"description": "새로 소환되는 몬스터 이동속도 +15%",
	},
	{
		"id": "blood_recycling",
		"name": "시체 재활용",
		"description": "몬스터 사망 시 실제 소환 비용의 25% 지휘력 환급",
	},
	{
		"id": "slime_mitosis",
		"name": "분열 실험",
		"description": "슬라임 사망 시 30% 확률로 무료 슬라임 1체 생성",
	},
	{
		"id": "venom_nest",
		"name": "독거미 둥지",
		"description": "새 거미의 둔화 지속시간 +40%",
	},
	{
		"id": "orc_fortify",
		"name": "오크 중장갑",
		"description": "새 오크 최대 HP +30%",
	},
	{
		"id": "cruel_command",
		"name": "잔혹한 명령",
		"description": "새로 소환되는 몬스터 공격력 +12%",
	},
	{
		"id": "dark_reservoir",
		"name": "마력 비축",
		"description": "최대 지휘력 +25, 즉시 지휘력 +25",
	},
]

static func get_augment(augment_id: String) -> Dictionary:
	for augment in AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)
	return {}

static func roll_candidates(exclude_ids: Array, count: int = 3) -> Array:
	var pool: Array = []

	for augment in AUGMENTS:
		var augment_id: String = String(augment.get("id", ""))
		if augment_id in exclude_ids:
			continue
		pool.append(augment.duplicate(true))

	if pool.size() < count:
		var existing_ids: Array[String] = []
		for item in pool:
			existing_ids.append(String(item.get("id", "")))

		for augment in AUGMENTS:
			var augment_id: String = String(augment.get("id", ""))
			if augment_id in existing_ids:
				continue
			pool.append(augment.duplicate(true))
			existing_ids.append(augment_id)

	pool.shuffle()

	var result: Array = []
	for index in range(mini(count, pool.size())):
		result.append(pool[index])
	return result
