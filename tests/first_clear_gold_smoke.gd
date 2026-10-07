extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const CATALOG := preload("res://src/data/stage_catalog.gd")
const COPY := preload("res://src/ui/battle_result_copy.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FIRST_GOLD: " + message)

func clear_stage(id: String) -> Dictionary:
	var stage := CATALOG.get_stage(id)
	var next := CATALOG.get_stage(String(stage.next_stage_id))
	return PROGRESS.complete_stage(id, int(stage.number), String(stage.next_stage_id), int(next.get("number", 0)), int(stage.first_clear_reward))

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://first_clear_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	# Legacy clears/research claims must not consume the new gold entitlement.
	var config := ConfigFile.new()
	config.set_value("cleared", "stage_10", true)
	config.set_value("reward_claimed", "stage_10", true)
	config.set_value("meta", "gold", 37)
	config.set_value("meta", "research_points", 73)
	SCOPE.save_config(config, PROGRESS.SAVE_PATH)
	var legacy := clear_stage("stage_10")
	check(legacy.success and legacy.gold_reward == 1000 and legacy.reward == 0 and legacy.easy_all_clear_gold == 0, "legacy clear earns gold once; stage10 alone is not all-clear")
	check(PROGRESS.get_research_points() == 73 and PROGRESS.get_gold() == 1037, "existing currency preserved")
	var expected_research := 73
	for id in CATALOG.ORDER:
		if id in ["stage_1", "stage_10"]:
			continue
		var reward := clear_stage(id)
		expected_research += int(CATALOG.get_stage(id).first_clear_reward)
		check(reward.gold_reward == 1000 and reward.easy_all_clear_gold == 0, "stage first gold " + id)
		var repeat := clear_stage(id)
		check(repeat.gold_reward == 0 and repeat.reward == 0 and repeat.easy_all_clear_gold == 0, "no repeated rewards " + id)
	check(PROGRESS.get_gold() == 9037 and PROGRESS.get_research_points() == expected_research, "nine cleared stages and unchanged research awards")
	SCOPE.select_guest()
	check(PROGRESS.is_gold_reward_claimed("stage_10") and PROGRESS.get_gold() == 9037, "claims persist across scope reload")
	PROGRESS.set_current_stage("stage_1")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(main)
	current_scene = main
	var deadline := Time.get_ticks_msec() + 20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	main.stage_intro_cutscene._finish(true)
	await process_frame
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	main.battle.set_external_pause(true)
	main.battle._on_hero_died()
	var run_gold := PROGRESS.get_gold() - 9037 - 4000
	check(main.battle.battle_over and run_gold >= 0, "real victory path grants stage and all-clear gold plus run reward")
	check(main.result_reward.text.contains("최초 클리어 골드 +1000") and main.result_reward.text.contains("쉬움 전체 클리어 골드 +3000"), "both gold awards shown in victory reward panel")
	check(not COPY.format_message("최초 클리어 골드 +1000\n쉬움 전체 클리어 골드 +3000").headline.contains("골드"), "awards stay in reward section")
	var paid := PROGRESS.get_gold()
	main.battle._on_hero_died()
	check(PROGRESS.get_gold() == paid, "duplicate victory signal grants nothing")
	for id in CATALOG.ORDER:
		var repeat := clear_stage(id)
		check(repeat.gold_reward == 0 and repeat.easy_all_clear_gold == 0 and PROGRESS.get_gold() == paid, "all claims persist " + id)
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		var args := OS.get_cmdline_user_args()
		root.get_texture().get_image().save_png(args[args.find("--capture") + 1])
	main.free()
	# Failure must report no paid reward and must not consume the entitlement.
	SCOPE.guest_directory = folder.path_join("missing")
	SCOPE.select_guest()
	var save_failed := clear_stage("stage_1")
	check(not save_failed.success and save_failed.gold_reward == 0 and save_failed.reward == 0, "save failure grants nothing")
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(clear_stage("stage_1").gold_reward == 1000, "failed save leaves reward available")
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	await create_timer(0.2).timeout
	print("FIRST_GOLD: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
