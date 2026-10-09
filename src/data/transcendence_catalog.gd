extends RefCounted
const MONSTERS := preload("res://src/data/monster_catalog.gd")
# Chest-like default: 15 stones, 20 EXP each. Kept separate from ordinary kill EXP.
const DEATH_DROP_DEFAULT := {
	"pieces": 15, "total_exp": 300, "speed_min": 220.0, "speed_max": 420.0,
	"pickup_delay": 0.30,
}

static func get_death_drop(id: String) -> Dictionary:
	if not is_transcendent(id):
		return {}
	return MONSTERS.MONSTERS[id].get("death_drop", DEATH_DROP_DEFAULT)

static func is_transcendent(id: String) -> bool:
	return MONSTERS.MONSTERS.has(id) and MONSTERS.get_rarity(id) == "transcendent"

static func get_ids() -> Array:
	var result: Array = []
	for id in MONSTERS.ORDER:
		if is_transcendent(String(id)):
			result.append(String(id))
	return result

static func get_rules(id: String) -> Dictionary:
	if not is_transcendent(id):
		return {}
	return MONSTERS.MONSTERS[id].get("transcendence", {
		"mode":"any", "conditions":[
			{"metric":"monsters_summoned", "amount":200},
			{"metric":"mana_spent", "amount":500},
		],
	}).duplicate(true)

static func describe(id: String) -> String:
	var rules := get_rules(id)
	var parts := PackedStringArray()
	for condition in rules.get("conditions", []):
		var metric := String(condition.get("metric", ""))
		var amount := float(condition.get("amount", 0))
		if metric == "damage_dealt":
			parts.append("누적 피해 %d" % int(amount))
		elif metric == "monsters_summoned":
			parts.append("몬스터 %d마리 소환" % int(amount))
		elif metric == "controls_summoned":
			parts.append("제어형 실제 %d회 소환" % int(amount))
		elif metric == "statuses_applied":
			parts.append("상태이상 %d회 적중" % int(amount))
		elif metric == "tanks_summoned":
			parts.append("탱커 실제 %d마리 소환" % int(amount))
		elif metric == "allies_died":
			parts.append("아군 몬스터 %d마리 사망" % int(amount))
		elif metric == "command_spent":
			parts.append("지휘력 %s 사용" % String.num(amount,1))
		elif metric == "mana_spent":
			parts.append("마력 %s 사용" % String.num(amount,1))
	return (" 및 " if rules.get("mode", "any") == "all" else " 또는 ").join(parts)
