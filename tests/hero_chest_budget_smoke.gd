extends SceneTree
const DATA := preload("res://src/data/hero_mode_catalog.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	var host = load("res://tests/hero_chest_budget_harness.gd").new(); root.add_child(host)
	check(host._chest_kill_requirement() == 200,"hero ordinary chest cadence quartered")
	host.hero_kills_toward_chest = 200; host._try_spawn_chest_from_kills(); await process_frame
	check(host.hero_chests_spawned == 0,"first opening chest reserved for elite")
	host.run_metrics.elapsed_seconds = 35; host.hero_elite_kills_toward_chest = 1
	host._spawn_chest_for_session(1,"elite")
	check(host.hero_chests_spawned == 1 and host.active_treasure_chests.size() == 1,"first elite still gives physical chest")
	check(host.hero_kills_toward_chest == 200,"elite reward preserves ordinary kill progress")
	host._spawn_chest_for_session(1)
	check(host.hero_chests_spawned == 2,"earned next reward has no three-minute restriction")
	host.hero_kills_toward_chest = 200
	host._spawn_chest_for_session(1)
	check(host.hero_chests_spawned == 2 and host.hero_kills_toward_chest == 200,"active chest saturation preserves pending progress")
	host.active_treasure_chests.clear(); host._spawn_chest_for_session(2)
	check(host.hero_chests_spawned == 2,"stale session cannot consume progress")
	host.battle_over = true; host._spawn_chest_for_session(1)
	check(host.hero_chests_spawned == 2,"ended run cannot generate reward")
	host.battle_over = false; host._spawn_chest_for_session(1)
	check(host.hero_chests_spawned == 3,"third physical reward succeeds")
	host.active_treasure_chests.clear()
	host.hero_elite_kills_toward_chest = 3
	check(not host._hero_chest_eligible("elite"),"three elite deaths insufficient after opening")
	host.hero_elite_kills_toward_chest = 4
	check(host._hero_chest_eligible("elite"),"four elite deaths eligible without time gate")
	host.hero_kills_toward_chest = 199; host._spawn_chest_for_session(1,"elite")
	check(host.hero_chests_spawned == 4 and host.hero_kills_toward_chest == 199,"fourth reward allowed; elite cannot erase normal progress")
	for index in 5:
		host.active_treasure_chests.clear(); host.hero_kills_toward_chest = 200; host.hero_elite_kills_toward_chest = 2
		host._spawn_chest_for_session(1)
		check(host.hero_chests_spawned == 5+index and host.hero_elite_kills_toward_chest == 2,"no per-run cap; normal reward preserves elite progress")
	host.active_treasure_chests.clear(); host.hero_player_mode = false; host.hero_kills_toward_chest = 50
	check(host._chest_kill_requirement() == 50,"demon mode keeps fifty-kill cadence")
	host._try_spawn_chest_from_kills(); await process_frame
	check(host.active_treasure_chests.size() == 1,"demon spawn unaffected")
	var model = load("res://tests/hero_chest_budget_harness.gd").new(); root.add_child(model)
	for second in range(901):
		model.run_metrics.elapsed_seconds = second
		model.hero_kills_toward_chest = mini(200,model.hero_kills_toward_chest+7)
		if second >= 35 and (second-35)%90 == 0:
			model.hero_elite_kills_toward_chest += 1; model._spawn_chest_for_session(1,"elite")
		model._spawn_chest_for_session(1)
		model.active_treasure_chests.clear() # Immediate collection supply model.
	check(model.hero_chests_spawned > 3,"dense-kill model has no three-reward ceiling")

	host.queue_free(); model.queue_free(); await process_frame
	print("HERO_CHEST_BUDGET checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
