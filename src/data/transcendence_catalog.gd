extends RefCounted
const MONSTERS := preload("res://src/data/monster_catalog.gd")

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
		if metric == "monsters_summoned":
			parts.append("몬스터 %d마리 소환" % int(amount))
		elif metric == "mana_spent":
			parts.append("마력 %s 사용" % String.num(amount,1))
	return (" 및 " if rules.get("mode", "any") == "all" else " 또는 ").join(parts)
