extends SceneTree

const SHOP := preload("res://src/data/shop_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")

var failures := 0

# Report every drifted condition instead of halting on the first assert.
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("PICKUP_PROBABILITY: " + label)

func _initialize() -> void:
	check(is_equal_approx(SHOP.get_effective_probability("transcendent"), 0.5), "is_equal_approx(SHOP.get_effective_probability(\"transcendent\"), 0.5)")
	check(SHOP.roll_rarity(0.994999) == "legendary", "SHOP.roll_rarity(0.994999) == \"legendary\"")
	check(SHOP.roll_rarity(0.995001) == "transcendent", "SHOP.roll_rarity(0.995001) == \"transcendent\"")
	check(SHOP.roll_rarity(1.0) == "transcendent", "SHOP.roll_rarity(1.0) == \"transcendent\"")
	# The 0.5% transcendent chance is split across the whole (growing) pool;
	# a pickup weights only the featured monster within that share.
	var pool: Array = SHOP.get_monster_pool("transcendent")
	var weight: float = SHOP.PICKUP.FEATURED_WEIGHT
	check(pool.size() >= 2 and pool[0] == "zeus" and "bulgasal" in pool, "transcendent pool contains zeus first and bulgasal")
	for pickup in ["", "zeus"]:
		var shares := (weight + pool.size() - 1.0) if pickup == "zeus" else float(pool.size())
		check(is_equal_approx(SHOP.get_monster_probability("zeus", pickup), 0.5 * (weight if pickup == "zeus" else 1.0) / shares), "is_equal_approx(SHOP.get_monster_probability(\"zeus\", pickup), 0.5 * (weight if pickup == \"zeus\" else 1.0) / shares)")
		check(is_equal_approx(SHOP.get_monster_probability("bulgasal", pickup), 0.5 / shares), "is_equal_approx(SHOP.get_monster_probability(\"bulgasal\", pickup), 0.5 / shares)")
		var total := 0.0
		for rarity in SHOP.RARITY_ORDER:
			for id in SHOP.get_monster_pool(rarity):
				total += SHOP.get_monster_probability(id, pickup)
		check(is_equal_approx(total, 100.0), "is_equal_approx(total, 100.0)")
		check(SHOP.roll_monster("transcendent", 0.0, pickup) == "zeus", "SHOP.roll_monster(\"transcendent\", 0.0, pickup) == \"zeus\"")
		check(SHOP.roll_monster("transcendent", 1.0, pickup) == String(pool[-1]), "SHOP.roll_monster(\"transcendent\", 1.0, pickup) == String(pool[-1])")
	# Synthetic IDs exercise future pool distribution without shipping content.
	check(SHOP.weighted_id(["zeus", "future_a"], 0.499999) == "zeus", "SHOP.weighted_id([\"zeus\", \"future_a\"], 0.499999) == \"zeus\"")
	check(SHOP.weighted_id(["zeus", "future_a"], 0.5) == "future_a", "SHOP.weighted_id([\"zeus\", \"future_a\"], 0.5) == \"future_a\"")
	check(SHOP.weighted_id(["zeus", "future_a"], 0.749999, "zeus") == "zeus", "SHOP.weighted_id([\"zeus\", \"future_a\"], 0.749999, \"zeus\") == \"zeus\"")
	check(SHOP.weighted_id(["zeus", "future_a"], 0.75, "zeus") == "future_a", "SHOP.weighted_id([\"zeus\", \"future_a\"], 0.75, \"zeus\") == \"future_a\"")
	check(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.599999, "zeus") == "zeus", "SHOP.weighted_id([\"zeus\", \"future_a\", \"future_b\"], 0.599999, \"zeus\") == \"zeus\"")
	check(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.600001, "zeus") == "future_a", "SHOP.weighted_id([\"zeus\", \"future_a\", \"future_b\"], 0.600001, \"zeus\") == \"future_a\"")
	check(SHOP.weighted_id(["zeus", "future_a", "future_b"], 0.800001, "zeus") == "future_b", "SHOP.weighted_id([\"zeus\", \"future_a\", \"future_b\"], 0.800001, \"zeus\") == \"future_b\"")
	check(SHOP.weighted_id([], 0.5, "zeus") == "", "SHOP.weighted_id([], 0.5, \"zeus\") == \"\"")
	for source in ["summon", "pickup"]:
		var entry := {"unlocked": false, "shards": 0, "level": 0}
		var roll := {"monster_id": "zeus", "source": source, "shards": 1}
		var first := COLLECTION._apply_draw_reward(entry, roll, SHOP.get_rarity("transcendent"), 1, false)
		check(entry.unlocked and entry.shards == 0 and first.first_draw_unlock, "entry.unlocked and entry.shards == 0 and first.first_draw_unlock")
		var second := COLLECTION._apply_draw_reward(entry, roll, SHOP.get_rarity("transcendent"), 1, false)
		check(entry.shards == 1 and not bool(second.get("first_draw_unlock", false)), "entry.shards == 1 and not bool(second.get(\"first_draw_unlock\", false))")
	print("pickup probability / first-unlock %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
