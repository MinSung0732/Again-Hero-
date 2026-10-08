extends RefCounted
var monster_id := ""
var conditions: Array = []
var condition_mode := "any"
var monsters_summoned := 0
var tanks_summoned := 0
var allies_died := 0
var mana_spent := 0.0
var command_spent := 0.0
var ready := false
var used := false
var test_unlock_confirmed := false

func configure(id: String, rules: Dictionary) -> void:
	monster_id = id
	conditions = rules.get("conditions", []).duplicate(true)
	condition_mode = String(rules.get("mode", "any"))
	monsters_summoned = 0
	tanks_summoned = 0
	allies_died = 0
	mana_spent = 0.0
	command_spent = 0.0
	ready = false
	used = false
	test_unlock_confirmed = false

func record_summon(role: String = "") -> bool:
	if monster_id.is_empty() or used:
		return false
	monsters_summoned += 1
	if role == "tank":
		tanks_summoned += 1
	return _evaluate()

func record_ally_death() -> bool:
	if monster_id.is_empty() or used:
		return false
	allies_died += 1
	return _evaluate()

func record_mana(amount: float) -> bool:
	if monster_id.is_empty() or used:
		return false
	mana_spent += maxf(amount,0.0)
	return _evaluate()

func record_command(amount: float) -> bool:
	if monster_id.is_empty() or used:
		return false
	command_spent += maxf(amount,0.0)
	return _evaluate()

func _evaluate() -> bool:
	if monster_id.is_empty() or ready or conditions.is_empty() or (condition_mode != "any" and condition_mode != "all"):
		return false
	var matched := 0
	for condition in conditions:
		var metric := String(condition.get("metric",""))
		var required := float(condition.get("amount",0))
		if (metric not in ["monsters_summoned", "mana_spent", "command_spent", "tanks_summoned", "allies_died"]) or required <= 0:
			return false
		var actual := 0.0
		match metric:
			"monsters_summoned": actual = monsters_summoned
			"mana_spent": actual = mana_spent
			"command_spent": actual = command_spent
			"tanks_summoned": actual = tanks_summoned
			"allies_died": actual = allies_died
		if actual + 0.0001 >= required:
			matched += 1
	ready = matched == conditions.size() if condition_mode == "all" else matched > 0
	return ready

func consume() -> void:
	used = true
	ready = false

# Caller must enforce local-test authorization. Only condition counters change.
func satisfy_conditions_for_test() -> bool:
	if monster_id.is_empty() or used or test_unlock_confirmed:
		return false
	if ready:
		test_unlock_confirmed = true
		return true
	for condition in conditions:
		var amount := float(condition.get("amount", 0))
		match String(condition.get("metric", "")):
			"tanks_summoned":
				tanks_summoned = maxi(tanks_summoned, int(ceil(amount)))
			"allies_died":
				allies_died = maxi(allies_died, int(ceil(amount)))
			"monsters_summoned":
				monsters_summoned = maxi(monsters_summoned, int(ceil(amount)))
			"command_spent":
				command_spent = maxf(command_spent, amount)
			"mana_spent":
				mana_spent = maxf(mana_spent, amount)
	var unlocked := _evaluate()
	test_unlock_confirmed = unlocked
	return unlocked
