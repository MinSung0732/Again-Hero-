extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const HISTORY := preload("res://src/systems/shop_summon_history_store.gd")
var failed := false
var test_gold := 0

func read_test_gold() -> int:
	return test_gold

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("UPGRADE_TEST: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = true # Fixture retains free test draws.
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var expected := {"common": [0.02,30], "advanced": [0.035,30], "uncommon": [0.035,30], "rare": [0.05,30], "legendary": [0.07,25], "transcendent": [0.10,15]}
	for rarity in expected:
		var profile: Dictionary = CATALOG.RARITY_UPGRADE_PROFILES[rarity]
		check(is_equal_approx(profile.hp_per_level, expected[rarity][0]) and is_equal_approx(profile.damage_per_level, expected[rarity][0]), rarity + " growth")
		check(profile.shards_required == expected[rarity][1] and profile.configured, rarity + " cost/enabled")
	for monster_id in CATALOG.ORDER:
		check(CATALOG.get_shards_required(monster_id) == 30, "common cost " + monster_id)
	check(SHOP.RARITIES.common.shard_min == 1 and SHOP.RARITIES.common.shard_max == 3, "common roll range")
	var state := STORE.load_state()
	state.slime = {"unlocked": true, "level": 29, "shards": 35}
	check(STORE.save_state(state), "seed level29")
	var serial := SCOPE.serial
	var result := STORE.try_upgrade("slime")
	check(result.success and result.level == 30 and result.shards == 0 and result.research_points == 5, "last upgrade consumes30 and converts remaining5")
	check(SCOPE.serial == serial + 1 and PROGRESS.get_research_points() == 5, "one atomic collection/research commit")
	check(STORE.try_upgrade("slime").get("reason") == "max_level", "level31 blocked")
	result = STORE.award_shards("slime", 3)
	check(result.success and result.research_points == 3 and PROGRESS.get_research_points() == 8 and STORE.get_shards("slime") == 0, "maxed draw conversion")
	check(not STORE.award_shards("slime", -1).success, "negative award rejected")
	state = STORE.load_state()
	state.orc = {"unlocked": true, "level": 0, "shards": 29}
	STORE.save_state(state)
	check(STORE.try_upgrade("orc").get("reason") == "not_enough_shards", "fixed cost requires30")
	STORE.award_shards("orc", 1)
	check(STORE.try_upgrade("orc").level == 1, "30-shard upgrade")
	var old := ConfigFile.new()
	SCOPE.load_config(old, STORE.SAVE_PATH)
	old.set_value("monsters", "slime_level", 99)
	old.set_value("monsters", "slime_shards", 7)
	SCOPE.save_config(old, STORE.SAVE_PATH)
	check(STORE.normalize_maxed().success and STORE.get_upgrade_level("slime") == 30 and PROGRESS.get_research_points() == 15, "legacy cap and leftover conversion")
	STORE.normalize_maxed()
	check(PROGRESS.get_research_points() == 15, "migration not duplicated")
	check(SCOPE.select_account(id) and STORE.get_upgrade_level("slime") == 30 and PROGRESS.get_research_points() == 15, "restart recovery")
	state = STORE.load_state()
	state.orc = {"unlocked": true, "level": 29, "shards": 31}
	STORE.save_state(state)
	SCOPE.files["unexpected.cfg"] = {}
	check(STORE.try_upgrade("orc").get("reason") == "save_failed", "failed atomic commit reported")
	SCOPE.files.erase("unexpected.cfg")
	check(STORE.get_upgrade_level("orc") == 29 and STORE.get_shards("orc") == 31 and PROGRESS.get_research_points() == 15, "failed conversion rolls back both balances")
	state = STORE.load_state()
	for monster_id in state:
		state[monster_id] = {"unlocked": true, "level": 30, "shards": 0}
	STORE.save_state(state)
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	var found_max := false
	for button in lobby.team_monster_grid.find_children("*", "Button", true, false):
		if button.text == "최대강화":
			found_max = true
			check(button.disabled, "max button disabled")
	check(found_max, "max label shown")
	var before := PROGRESS.get_research_points()
	lobby._open_monster_boxes(11)
	var history := HISTORY.load_entries()
	var converted := 0
	check(history.size() == 11, "11 individual results retained")
	for entry in history:
		check(entry.shards >= 1 and entry.shards <= 3 and entry.research_points == entry.shards, "draw range and converted history")
		converted += int(entry.research_points)
	check(PROGRESS.get_research_points() - before == converted, "batch research award exact")
	var overlay: Control = lobby.gacha_reveal_overlay
	overlay._show_final_results()
	check(overlay._result_summary.text.contains("총 0조각") and overlay._result_summary.text.contains("연구 +%d" % converted), "converted final summary")
	var card: Control = overlay._create_result_card({"monster_id": "slime", "name": "슬라임", "rarity": "common", "shards": 3, "research_points": 3})
	var point_label := false
	for label in card.find_children("*", "Label", true, false):
		point_label = point_label or label.text == "+3 조각"
	check(point_label and card.has_node("ConversionFeedback"), "converted card starts with shards before stamp")
	card.free()
	overlay._results = [{"monster_id": "slime", "name": "슬라임", "rarity": "common", "shards": 1}, {"monster_id": "orc", "name": "오크", "rarity": "common", "shards": 2, "research_points": 2}]
	overlay._show_final_results()
	check(overlay._result_summary.text.contains("총 1조각") and overlay._result_summary.text.contains("연구 +2"), "mixed batch shows both reward types")
	# Retry preserves the requested draw count, including mixed/fewer displayed results.
	check(overlay._confirm_button.get_parent() == overlay._retry_button.get_parent(), "result actions share one row")
	check(overlay._confirm_button.get_index() < overlay._retry_button.get_index(), "retry is right of confirm")
	overlay.configure_retry(11, SHOP.MULTI_DRAW_COST, read_test_gold)
	check(overlay._retry_button.disabled, "insufficient gold disables retry")
	overlay._retry()
	check(overlay._phase == "result" and HISTORY.load_entries().size() == 11, "disabled retry grants nothing")
	test_gold = SHOP.MULTI_DRAW_COST
	overlay._refresh_retry_button()
	check(not overlay._retry_button.disabled, "exact cost enables retry")
	test_gold -= 1
	overlay._retry()
	check(overlay._phase == "result" and overlay._retry_button.disabled, "click rechecks stale balance")
	test_gold = SHOP.MULTI_DRAW_COST
	overlay._retry()
	check(overlay._phase == "door" and overlay._results.size() == 11 and HISTORY.load_entries().size() == 22, "retry starts full opening and same batch")
	overlay._retry()
	check(HISTORY.load_entries().size() == 22, "double retry blocked during animation")
	overlay.skip_to_results()
	overlay._confirm()
	lobby._open_monster_boxes(1)
	overlay.skip_to_results()
	check(overlay._retry_draw_count == 1 and overlay._retry_cost == SHOP.SINGLE_DRAW_COST, "single retry configured")
	overlay._retry()
	check(overlay._phase == "door" and overlay._results.size() == 1 and HISTORY.load_entries().size() == 24, "single retry retains full animation")
	lobby.queue_free()
	await process_frame
	# Never touch the player's guest cfg files: reuse this random fixture folder.
	SCOPE.select_guest()
	SCOPE.guest_directory = folder
	state = STORE.load_state()
	state.slime = {"unlocked": true, "level": 29, "shards": 32}
	STORE.save_state(state)
	var progress := ConfigFile.new()
	progress.set_value("meta", "research_points", 10)
	SCOPE.save_config(progress, "user://stage_progress.cfg")
	check(STORE.try_upgrade("slime").success and PROGRESS.get_research_points() == 12, "guest conversion committed")
	var collection := ConfigFile.new()
	SCOPE.load_config(collection, STORE.SAVE_PATH)
	progress.set_value("meta", "research_points", 17)
	var journal := folder.path_join("gameplay_transaction.json")
	var file := FileAccess.open(journal, FileAccess.WRITE)
	file.store_string(JSON.stringify({"monster_collection.cfg": SCOPE._config_data(collection), "stage_progress.cfg": SCOPE._config_data(progress)}))
	file.close()
	check(PROGRESS.get_research_points() == 17 and not FileAccess.file_exists(journal), "interrupted guest transaction replayed")
	check(PROGRESS.get_research_points() == 17, "guest replay not duplicated")
	SCOPE.guest_directory = "user://"
	for name in ["monster_collection.cfg", "stage_progress.cfg", "gameplay_transaction.json", "gameplay_transaction.json.tmp"]:
		if FileAccess.file_exists(folder.path_join(name)):
			DirAccess.remove_absolute(folder.path_join(name))
	for name in ["save_bundle.json", "save_bundle.json.tmp", "save_bundle.json.before_cloud.bak"]:
		if FileAccess.file_exists(folder.path_join(name)):
			DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	SCOPE.select_guest()
	print("MONSTER_UPGRADE_BALANCE_SMOKE_OK" if not failed else "MONSTER_UPGRADE_BALANCE_SMOKE_FAILED")
	quit(1 if failed else 0)
