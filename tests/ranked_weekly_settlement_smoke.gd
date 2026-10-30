extends SceneTree
const RULES := preload("res://src/data/ranked_rules.gd")

func _initialize() -> void:
	assert(RULES.weekly_reset_mmr(1370) == 1000)
	assert(RULES.weekly_reset_mmr(2788) == 2300)
	assert(RULES.weekly_reset_mmr(3400, 101) == 2900)
	assert(RULES.weekly_reset_mmr(3400, 1) == 2900)
	assert(RULES.weekly_reward_tier(1200, 1800) == "gold_1")
	assert(RULES.weekly_reward_tier(3500, 3400, 101, 1) == "demon_lord")
	assert(RULES.weekly_reward_tier(3400, 3500, 1, 101) == "demon_lord")
	assert(RULES.weekly_reward_tier(3400, 3400, 101, 1) == "demon_lord")
	assert(RULES.weekly_reward("gold_1").get("demon_token", 0) > RULES.weekly_reward("bronze_1").get("demon_token", 0))
	print("ranked_weekly_settlement_smoke: reset and reward data PASS; mailbox and popup not implemented")
	quit()
