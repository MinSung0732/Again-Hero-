extends SceneTree
const RULES := preload("res://src/data/ranked_rules.gd")

func _initialize() -> void:
	assert(RULES.weekly_reset_mmr(1370) == 1000)
	assert(RULES.weekly_reset_mmr(1000) == 1000)
	assert(RULES.weekly_reset_mmr(1401) == 1400)
	assert(RULES.weekly_reset_mmr(1400) == 1000)
	assert(RULES.weekly_reset_mmr(1800) == 1400)
	assert(RULES.weekly_reset_mmr(2300) == 1800)
	assert(RULES.weekly_reset_mmr(2788) == 2300)
	assert(RULES.weekly_reset_mmr(2900) == 2300)
	assert(RULES.weekly_reset_mmr(3400, 101) == 2900)
	assert(RULES.weekly_reset_mmr(3400, 1) == 2900)
	assert(RULES.weekly_reward_tier(1200, 1800) == "gold_1")
	assert(RULES.weekly_reward_tier(3500, 3400, 101, 1) == "demon_lord")
	assert(RULES.weekly_reward_tier(3400, 3500, 1, 101) == "demon_lord")
	assert(RULES.weekly_reward_tier(3400, 3400, 101, 1) == "demon_lord")
	var expected := [20, 22, 24, 26, 30, 32, 34, 36, 40, 42, 44, 46, 60, 64, 68, 72, 85]
	var ids := ["bronze_1", "bronze_2", "bronze_3", "bronze_4", "silver_1", "silver_2", "silver_3", "silver_4", "gold_1", "gold_2", "gold_3", "gold_4", "diamond_1", "diamond_2", "diamond_3", "diamond_4", "demon_lord"]
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261030120000_ranked_weekly_settlement.sql")
	var thresholds: Array = RULES.data().mmr_thresholds
	for i in range(ids.size()):
		var reward: Dictionary = RULES.weekly_reward(ids[i])
		assert(reward.demon_token == expected[i] and reward.hero_token == expected[i])
		var mmr := int(thresholds[i].mmr)
		assert(sql.contains("('%s',%d,%d,%d)" % [ids[i], RULES.weekly_reset_mmr(mmr + 1), expected[i], expected[i]]))
	for pair in [[1, 300], [2, 250], [10, 250], [11, 200], [20, 200], [21, 150], [50, 150], [51, 100], [100, 100]]:
		assert(RULES.weekly_reward("hero", pair[0]) == {"demon_token": pair[1], "hero_token": pair[1]})
	for band in RULES.data().weekly_hero_rank_rewards:
		assert(sql.contains("(%d,%d,%d)" % [band.min_rank, band.max_rank, band.amount]))
	var currencies: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://src/data/token_currencies.json"))
	for check in [[currencies.hero_token.exchange[0], "hero_summon", 1], [currencies.demon_token.exchange[0], "gold", 750], [currencies.demon_token.exchange[1], "stamina", 100]]:
		assert(int(check[0].token_amount) == 10 and check[0].target == check[1] and int(check[0].amount) == check[2])
	assert(RULES.weekly_reward("hero", 0).is_empty())
	assert(sql.contains("played.wins+played.losses>=1"))
	assert(sql.contains("where week_start=start_date"))
	print("ranked_weekly_settlement_smoke: data and SQL seed PASS")
	quit()
