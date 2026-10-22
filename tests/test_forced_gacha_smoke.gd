extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")

class ShopHost extends Control:
	const SHOP_STOREFRONT_ART := {"CONTENT": "Content/"}
	func _apply_lobby_button_skin(_button: Button, _selected: bool, _font_size: int) -> void:
		pass

var failures := 0

# Report every drifted condition instead of halting on the first assert.
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FORCED_GACHA: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var mode := root.get_node("LocalTestMode")
	var old_active: bool = mode.active
	var old_preview: bool = mode.tutorial_preview
	var old_user: String = SCOPE.user_id
	var old_directory: String = SCOPE.guest_directory
	var old_test_directory: String = mode.test_directory
	var directory := "user://forced_gacha_smoke_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	mode.active = true
	mode.tutorial_preview = false
	mode.test_directory = directory
	SCOPE.guest_directory = directory
	SCOPE.user_id = ""
	check(mode.forced_gacha_monster("zeus") == "zeus", "mode.forced_gacha_monster(\"zeus\") == \"zeus\"")
	check(mode.forced_gacha_monster("slime").is_empty(), "mode.forced_gacha_monster(\"slime\").is_empty()")
	check(mode.forced_gacha_monster("unknown").is_empty(), "mode.forced_gacha_monster(\"unknown\").is_empty()")
	check(mode.reset_progress(true), "mode.reset_progress(true)")
	var lobby = load("res://src/lobby/lobby.gd").new()
	var host := ShopHost.new()
	var content := VBoxContainer.new()
	content.name = "Content"
	host.add_child(content)
	var monster_section := Control.new()
	monster_section.name = "MonsterSection"
	content.add_child(monster_section)
	root.add_child(host)
	lobby._shop_test_draw_view.install(host)
	check(lobby._shop_test_draw_view.section.visible, "lobby._shop_test_draw_view.section.visible")
	# Every transcendent in the shop pool is selectable, after "keep normal odds".
	var transcendent_pool: Array = SHOP.get_monster_pool("transcendent")
	var expected_ids: Array[String] = [""]
	for raw_id in transcendent_pool:
		expected_ids.append(String(raw_id))
	check("zeus" in transcendent_pool and lobby._shop_test_draw_view.monster_ids == expected_ids, "selector lists every transcendent")
	lobby._shop_test_draw_view.selector.item_selected.emit(1)
	check(lobby._shop_test_draw_view.selected_id == "zeus", "lobby._shop_test_draw_view.selected_id == \"zeus\"")
	for pickup in ["", "zeus"]:
		var rolls: Array = []
		for index in SHOP.MULTI_DRAW_COUNT:
			var roll: Dictionary = lobby._roll_monster_shard(pickup)
			check(roll.monster_id == "zeus" and roll.rarity == "transcendent", "roll.monster_id == \"zeus\" and roll.rarity == \"transcendent\"")
			check(roll.source == ("summon" if pickup.is_empty() else "pickup"), "roll.source == (\"summon\" if pickup.is_empty() else \"pickup\")")
			check(roll.shards >= 1 and roll.shards <= 2, "roll.shards >= 1 and roll.shards <= 2")
			rolls.append(roll)
		var gold_before := preload("res://src/systems/stage_progress.gd").get_gold()
		var batch := COLLECTION.award_shard_batch(rolls, 0, false)
		check(batch.success and batch.awards.size() == 11, "batch.success and batch.awards.size() == 11")
		check(preload("res://src/systems/stage_progress.gd").get_gold() == gold_before, "preload(\"res://src/systems/stage_progress.gd\").get_gold() == gold_before")
	mode.active = false
	var normal_seen := false
	for index in 100:
		if lobby._roll_monster_shard().rarity != "transcendent":
			normal_seen = true
	check(normal_seen, "normal_seen")
	lobby._shop_test_draw_view.refresh()
	check(not lobby._shop_test_draw_view.section.visible, "not lobby._shop_test_draw_view.section.visible")
	check(lobby._shop_test_draw_view.selected_id.is_empty(), "lobby._shop_test_draw_view.selected_id.is_empty()")
	check(lobby._shop_test_draw_view.selector.selected == 0, "lobby._shop_test_draw_view.selector.selected == 0")
	check(mode.forced_gacha_monster("zeus").is_empty(), "mode.forced_gacha_monster(\"zeus\").is_empty()")
	mode.active = true
	mode.tutorial_preview = true
	check(mode.forced_gacha_monster("zeus").is_empty(), "mode.forced_gacha_monster(\"zeus\").is_empty()")
	mode.tutorial_preview = false
	SCOPE.user_id = "real_account"
	check(mode.forced_gacha_monster("zeus").is_empty(), "mode.forced_gacha_monster(\"zeus\").is_empty()")
	SCOPE.user_id = ""
	SCOPE.guest_directory = "user://"
	check(mode.forced_gacha_monster("zeus").is_empty(), "mode.forced_gacha_monster(\"zeus\").is_empty()")
	# The 0.5% transcendent rarity chance is shared evenly by the whole pool.
	check(is_equal_approx(SHOP.get_effective_probability("transcendent"), 0.5), "transcendent rarity odds")
	check(is_equal_approx(SHOP.get_monster_probability("zeus"), 0.5 / float(transcendent_pool.size())), "zeus share of transcendent odds")
	host.free()
	lobby.free()
	mode.active = old_active
	mode.tutorial_preview = old_preview
	mode.test_directory = old_test_directory
	SCOPE.guest_directory = old_directory
	SCOPE.user_id = old_user
	print("forced gacha: sandbox/real/tutorial guards, normal/pickup 11 awards, gold, odds %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
