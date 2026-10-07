extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const COPY := preload("res://src/ui/battle_result_copy.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("GOLD_TEST: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://gold_reward_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(main)
	current_scene = main
	var deadline := Time.get_ticks_msec()+20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	main.battle.set_external_pause(true)
	var message: String = main.battle._grant_run_research_reward(true)
	var pattern := RegEx.new()
	pattern.compile("Run 연구 \\+(\\d+)")
	var match_result := pattern.search(message)
	check(match_result != null, "clear research message present")
	if match_result != null:
		var expected := int(floor(float(match_result.get_string(1).to_int())*0.60))
		check(PROGRESS.get_gold() == expected, "60 percent of granted run research")
		check(COPY.format_message(message).reward.contains("전투 골드 +%d" % expected), "gold result label")
	var gold := PROGRESS.get_gold()
	PROGRESS.complete_stage("stage_1",1,"stage_2",2,450)
	check(PROGRESS.get_gold() == gold + 1000, "first clear gold added separately")
	gold = PROGRESS.get_gold()
	main.battle.current_stage_data["run_reward_multiplier"] = 3.0
	var defeat_research_before := PROGRESS.get_research_points()
	main.battle._on_run_time_up()
	var defeat_research := PROGRESS.get_research_points() - defeat_research_before
	var defeat_gold := int(floor(float(defeat_research) * 0.60))
	check(defeat_research > 0 and PROGRESS.get_gold() == gold + defeat_gold, "defeat grants 60 percent of its research reward")
	check(main.result_reward.text.contains("전투 골드 +%d" % defeat_gold), "defeat result displays granted gold")
	check(not main.result_reward.text.contains("최초 클리어"), "defeat has no first-clear reward")
	check(not main.result_analysis.text.contains("Stage 3.00"), "defeat ignores victory stage multiplier")
	main.battle._on_run_time_up()
	check(PROGRESS.get_gold() == gold + defeat_gold, "repeated finish signal cannot grant gold twice")
	main.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	SCOPE.select_guest()
	print("CLEAR_GOLD_REWARD_FAILED" if failed else "CLEAR_GOLD_REWARD_OK")
	quit(1 if failed else 0)
