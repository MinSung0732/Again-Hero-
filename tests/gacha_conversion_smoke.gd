extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const HISTORY := preload("res://src/systems/shop_summon_history_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("GACHA_CONVERSION: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = true # Fixture retains free test draws.
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated folder")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	SCOPE.select_guest()
	SCOPE.guest_directory = folder
	# Existing dungeon cfg files store encounter stages as a PackedStringArray.
	var progress := ConfigFile.new()
	progress.set_value("meta", "research_points", 100)
	progress.set_value("hero_identity_stages", "fixture_hero", PackedStringArray(["stage_1", "stage_2"]))
	check(progress.save(folder.path_join("stage_progress.cfg")) == OK, "legacy encounter fixture")
	var state := STORE.load_state()
	for monster_id in state:
		state[monster_id] = {"unlocked": true, "level": 30, "shards": 0}
	check(STORE.save_state(state), "maxed collection")
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._open_monster_boxes(11)
	var history := HISTORY.load_entries()
	check(history.size() == 11, "legacy guest retains all 11 maxed draws")
	var total := 0
	for entry in history:
		total += int(entry.research_points)
	check(total >= 22 and total <= 88 and PROGRESS.get_research_points() == 100 + total, "exact conversion once")
	lobby._rebuild_shop_list()
	check(lobby.shop_rates_text.text.contains("조각 5~8") and lobby.shop_rates_text.text.contains("조각 3~5") and lobby.shop_rates_text.text.contains("조각 1~5"), "rates UI uses updated shard ranges")
	var overlay: Control = lobby.gacha_reveal_overlay
	if history.size() == 11:
		await create_timer(0.3).timeout
		overlay.skip_to_results()
		check(overlay._results.size() == 11 and overlay._result_grid.get_child_count() == 11, "skip keeps all 11 cards")
		for card in overlay._result_grid.get_children():
			var effect: Node2D = card.get_node("ConversionFeedback")
			check(effect.amount_label.text.begins_with("+") and effect.elapsed < 0.0, "maxed monster briefly shows shard reward")
		await create_timer(1.2).timeout
		for card in overlay._result_grid.get_children():
			var effect: Node2D = card.get_node("ConversionFeedback")
			check(effect.amount_label.text == "연구 +%d P" % effect.points, "conversion finishes with points")
			check(effect._stamp.modulate.a == 1.0 and effect._stamp.rotation < 0.0 and not effect.is_processing(), "diagonal stamp finishes without idle work")
		check(PROGRESS.get_research_points() == 100 + total, "animation never duplicates rewards")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://gacha-conversion-preview.png")
		overlay._confirm()
	# Fixed RNG sequence checks every currently configured common monster remains eligible.
	seed(4261)
	var seen := {}
	var shard_amounts := {}
	for index in range(1000):
		var roll: Dictionary = lobby._roll_monster_shard()
		check(not roll.is_empty(), "valid roll")
		if not roll.is_empty():
			seen[roll.monster_id] = true
			var rarity: Dictionary = SHOP.get_rarity(roll.rarity)
			check(roll.shards >= rarity.shard_min and roll.shards <= rarity.shard_max, "draw within rarity range")
			if roll.rarity == "common":
				shard_amounts[int(roll.shards)] = true
	for amount in range(5, 9):
		check(shard_amounts.has(amount), "inclusive shard amount reachable: " + str(amount))
	for monster_id in CATALOG.ORDER:
		if CATALOG.get_rarity(monster_id) == "common":
			check(seen.has(monster_id), "eligible even at max level: " + monster_id)
	# Existing account cfg import and future encounter writes both stay JSON-safe.
	check(SCOPE.select_account(id), "legacy account import")
	check(SCOPE.valid_payload(SCOPE.files), "packed encounter stages normalize for account bundles")
	var before := PROGRESS.get_research_points()
	PROGRESS.record_hero_encounter("stage_3", "fixture_hero")
	check(SCOPE.valid_payload(SCOPE.files), "new encounter record remains serializable")
	var batch := STORE.award_shard_batch([{"monster_id": "slime", "shards": 2}, {"monster_id": "orc", "shards": 3}])
	check(batch.success and batch.awards.size() == 2 and PROGRESS.get_research_points() == before + 5, "account maxed batch after encounter")
	# Failed account transaction rolls back the entire batch, not only converted draws.
	SCOPE.files["unexpected.cfg"] = {}
	var rejected := STORE.award_shard_batch([{"monster_id": "slime", "shards": 1}, {"monster_id": "orc", "shards": 2}])
	check(not rejected.success and rejected.awards.is_empty() and PROGRESS.get_research_points() == before + 5, "whole failed batch rolled back")
	SCOPE.files.erase("unexpected.cfg")
	state = STORE.load_state()
	state.orc = {"unlocked": true, "level": 0, "shards": 0}
	STORE.save_state(state)
	batch = STORE.award_shard_batch([{"monster_id": "slime", "shards": 3}, {"monster_id": "orc", "shards": 2}])
	check(batch.success and batch.awards[0].research_points == 3 and batch.awards[1].research_points == 0 and STORE.get_shards("orc") == 2, "mixed batch retains monster and point entries")
	for batch_index in range(16):
		var points_before := PROGRESS.get_research_points()
		var shards_before := STORE.get_shards("orc")
		lobby._open_monster_boxes(11)
		check(overlay._results.size() == 11, "repeated mixed 10+1 batch keeps count")
		var batch_points := 0
		var batch_shards := 0
		for entry in overlay._results:
			batch_points += int(entry.research_points)
			if entry.monster_id == "orc":
				batch_shards += int(entry.shards)
		check(PROGRESS.get_research_points() == points_before + batch_points and STORE.get_shards("orc") == shards_before + batch_shards, "repeated batch balances exact")
		overlay.skip_to_results()
		check(overlay._result_grid.get_child_count() == 11, "immediate skip has 11 cards")
		overlay._confirm()
		await process_frame
	var saved_points := PROGRESS.get_research_points()
	check(SCOPE.select_account(id) and PROGRESS.get_research_points() == saved_points, "converted rewards survive reload")
	lobby.free()
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://"
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	print("GACHA_CONVERSION_FAILED" if failed else "GACHA_CONVERSION_OK")
	quit(1 if failed else 0)
