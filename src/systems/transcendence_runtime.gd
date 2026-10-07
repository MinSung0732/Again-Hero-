extends RefCounted
var monster_id := ""
var conditions: Array = []
var condition_mode := "any"
var monsters_summoned := 0
var mana_spent := 0.0
var ready := false
var used := false

func configure(id: String, rules: Dictionary) -> void:
	monster_id = id
	conditions = rules.get("conditions", []).duplicate(true)
	condition_mode = String(rules.get("mode", "any"))
	monsters_summoned = 0
	mana_spent = 0.0
	ready = false
	used = false

func record_summon() -> bool:
	if monster_id.is_empty() or used:
		return false
	monsters_summoned += 1
	return _evaluate()

func record_mana(amount: float) -> bool:
	if monster_id.is_empty() or used:
		return false
	mana_spent += maxf(amount,0.0)
	return _evaluate()

func _evaluate() -> bool:
	if ready or conditions.is_empty() or (condition_mode != "any" and condition_mode != "all"):
		return false
	var matched := 0
	for condition in conditions:
		var metric := String(condition.get("metric",""))
		var required := float(condition.get("amount",0))
		if (metric != "monsters_summoned" and metric != "mana_spent") or required <= 0:
			return false
		var actual := float(monsters_summoned) if metric == "monsters_summoned" else mana_spent
		if actual + 0.0001 >= required:
			matched += 1
	ready = matched == conditions.size() if condition_mode == "all" else matched > 0
	return ready

func consume() -> void:
	used = true
	ready = false
