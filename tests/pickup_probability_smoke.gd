extends SceneTree

const SHOP := preload("res://src/data/shop_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")

func _initialize() -> void:
	assert(is_equal_approx(SHOP.get_effective_probability("transcendent"), 0.5))
	assert(SHOP.roll_rarity(0.994999) == "legendary")
	assert(SHOP.roll_rarity(0.995001) == "transcendent")
	assert(SHOP.roll_rarity(1.0) == "transcendent")
	for pickup in ["", "zeus"]:
		assert(is_equal_approx(SHOP.get_monster_probability("zeus", pickup), 0.5))
		var total := 0.0
		for rarity in SHOP.RARITY_ORDER:
			for id in SHOP.get_monster_pool(rarity):
				total += SHOP.get_monster_probability(id, pickup)
		assert(is_equal_approx(total, 100.0))
		assert(SHOP.roll_monster("transcendent", 0.0, pickup) == "zeus")
		assert(SHOP.roll_monster("transcendent", 1.0, pickup) == "zeus")
	# Synthetic IDs exercise future pool distribution without shipping content.
	assert(SHOP.weighted_id(["zeus", "future_a"], 0.499999) == "zeus")
	assert(SHOP.weighted_id(["zeus", "future_a"], 0.5) == "future_a")
	assert(SHOP.weighted_id(["zeus", "future_a"], 0.749999, "zeus") == "zeus")
	assert(SHOP.weighted_id(["zeus", "future_a"], 0.75, "zeus") == "future_a")
	assert(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.599999, "zeus") == "zeus")
	assert(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.600001, "zeus") == "future_a")
	assert(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.800001, "zeus") == "future_b")
	assert(SHOP.weighted_id([], 0.5, "zeus") == "")
	for source in ["summon", "pickup"]:
		var entry := {"unlocked": false, "shards": 0, "level": 0}
		var roll := {"monster_id": "zeus", "source": source, "shards": 1}
		var first := COLLECTION._apply_draw_reward(entry, roll, SHOP.get_rarity("transcendent"), 1, false)
		assert(entry.unlocked and entry.shards == 0 and first.first_draw_unlock)
		var second := COLLECTION._apply_draw_reward(entry, roll, SHOP.get_rarity("transcendent"), 1, false)
		assert(entry.shards == 1 and not bool(second.get("first_draw_unlock", false)))
	print("pickup probability / first-unlock PASS")
	quit()
