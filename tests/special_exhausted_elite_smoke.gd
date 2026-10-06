extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
var failed := false
var main
var battle
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SPECIAL_EXHAUSTED: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://special_exhausted_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(main)
	current_scene = main
	var deadline := Time.get_ticks_msec() + 20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	check(main._presentation_ready, "presentation ready")
	main.stage_intro_cutscene._finish(true)
	await process_frame
	await process_frame
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	battle = main.battle
	battle.set_external_pause(true)
	battle.allowed_monster_ids.assign(["slime","dullahan","kraken"])
	battle.demon_special_augments.clear()
	for id in battle.allowed_monster_ids:
		for augment in AUGMENTS.get_special_augments_for_monster(id):
			battle.demon_special_augments.append(augment.id)
	var final_id: String = battle.demon_special_augments.pop_back()
	battle.demon_pending_augments = 4
	battle.demon_pending_augment_levels.assign([10,20,30,31])
	battle._open_next_demon_augment_if_needed()
	check(battle.demon_augment_selection_active and battle.demon_augment_candidates.size() == 1 and not battle.mutation_director.is_active(), "last available special stays a special choice")
	check(battle.reroll_demon_augments() and battle.demon_augment_candidates.size() == 1 and not battle.mutation_director.is_active(), "reroll exclusion is not exhaustion")
	var rerolls: int = battle.demon_rerolls_left
	main.demon_augment_panel.hide()
	check(battle.choose_demon_augment(final_id), "final special applies")
	check(battle.mutation_director.is_active() and main.mutation_panel.visible and main.mutation_title.text == "엘리트 소환", "next exhausted special opens actual elite UI")
	check(battle.demon_pending_augments == 2 and battle.demon_pending_augment_levels == [30,31], "one opportunity consumed, remaining queue retained")
	check(battle.demon_rerolls_left == rerolls and not battle.demon_augment_selection_active, "elite spends no reroll and no empty special modal")
	check(battle.mutation_director.get_candidates() == ["slime","dullahan"] and "kraken" not in main.current_mutation_candidates, "elite eligibility and equipped candidates")
	check(battle.flow_pause_manager.get_snapshot().has(battle.PAUSE_REASON_MUTATION_CHOICE) and not battle.flow_pause_manager.get_snapshot().has(battle.PAUSE_REASON_DEMON_AUGMENT), "pause belongs to elite modal")
	var population: int = battle.monsters_alive
	battle.spawn_selected_mutation("kraken")
	check(battle.mutation_director.is_active() and battle.monsters_alive == population, "invalid choice preserves modal")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
	main._on_mutation_choice_pressed(0)
	check(battle.monsters_alive == population + 1, "selected elite spawned exactly once")
	await process_frame
	check(main.mutation_panel.visible and battle.mutation_director.is_active() and battle.demon_pending_augments == 1, "consecutive exhausted rewards serialized")
	main._on_mutation_choice_pressed(1)
	await process_frame
	check(not main.mutation_panel.visible and main.demon_augment_panel.visible and battle.demon_augment_selection_active and battle.demon_active_augment_level == 31, "normal reward resumes after elite choices")
	check(battle.monsters_alive == population + 2, "two opportunities give two elites")
	main.demon_augment_panel.hide()
	check(battle.choose_demon_augment(battle.demon_augment_candidates[0].id), "ordinary augment remains selectable")
	check(battle.demon_pending_augments == 0 and not battle.flow_pause_manager.get_snapshot().has(battle.PAUSE_REASON_MUTATION_CHOICE), "queue drained and elite pause released")
	battle._open_mutation_choice({"type":"elite","mutation_profile_id":"mutation_1"})
	battle.demon_pending_augments = 1
	battle.demon_pending_augment_levels.assign([40])
	battle._open_next_demon_augment_if_needed()
	check(battle.demon_pending_augments == 1, "existing stage choice does not discard level reward")
	main._on_mutation_choice_pressed(0)
	await process_frame
	check(battle.mutation_director.is_active() and main.mutation_title.text == "엘리트 소환", "queued replacement resumes after stage choice")
	main._on_mutation_choice_pressed(0)
	await process_frame
	check(battle.demon_pending_augments == 0 and not battle.mutation_director.is_active(), "final choice completed")
	main.free()
	await process_frame
	print("SPECIAL_EXHAUSTED: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
