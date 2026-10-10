extends SceneTree

# Run in the asset-free project created by build_battle_boundary_fixture.py.
const RULES := preload("res://src/data/battle_session_catalog.gd")
const REQUEST := preload("res://src/systems/battle_command.gd")
var checks := 0
var failures := 0
var ready_count := 0
var applied_count := 0
var displayed_revision := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func on_ready(_candidates: Array, _rerolls: int, _level: int, battle: Node) -> void:
	ready_count += 1
	displayed_revision = battle.get_demon_augment_revision()

func on_applied(_name: String, _summary: String) -> void:
	applied_count += 1

func run() -> void:
	# Fixture scripts are generated outside the game repository. Runtime loading
	# keeps the real project's editor/import from preloading nonexistent fixtures.
	var battle_script := load("res://tests/battle_boundary_fixture.gd") as Script
	if battle_script == null:
		push_error("Build the isolated project with build_battle_boundary_fixture.py first")
		quit(1)
		return
	for routed in [true, false]:
		var battle = battle_script.new()
		root.add_child(battle)
		battle.command_routing_enabled = routed
		battle.demon_augment_ready.connect(on_ready.bind(battle))
		battle.demon_augment_applied.connect(on_applied)
		check(battle.try_summon("slime"), "auto wrapper")
		check(battle.try_summon_at_position("orc", Vector2(12, 34)), "manual wrapper")
		check(battle.last_position == Vector2(12, 34), "position unchanged")
		check(battle.try_summon_transcendent(), "transcendent wrapper")
		check(battle.try_use_demon_ultimate("line_assault", "west"), "skill wrapper")
		check(battle.last_direction == "west", "direction unchanged")
		battle.gameplay_allowed = false
		check(not battle.try_summon("slime"), "gameplay failure propagated")
		battle.gameplay_allowed = true
		check(not battle.choose_demon_augment("fixture_a"), "no offer")
		check(not battle.reroll_demon_augments(), "no reroll without offer")
		battle.start_offer([2, 3])
		var old_revision: int = displayed_revision
		check(old_revision > 0 and battle.flow_pause_manager.paused, "offer revision and pause")
		check(battle.reroll_demon_augments(old_revision), "reroll current")
		var rerolled_revision: int = displayed_revision
		check(rerolled_revision > old_revision, "same candidate ids get new revision")
		check(battle.demon_rerolls_left == 2, "one reroll consumed")
		check(not battle.reroll_demon_augments(old_revision), "stale reroll denied")
		check(not battle.choose_demon_augment("fixture_a", old_revision), "stale choose denied")
		check(battle.demon_rerolls_left == 2 and battle.applied == 0, "stale actions have no effects")
		check(not battle.choose_demon_augment("not_a_candidate", rerolled_revision), "noncandidate denied")
		var before_ready := ready_count
		check(battle.choose_demon_augment("fixture_a", rerolled_revision), "choose current")
		check(battle.applied == 1 and battle.refreshed == 1 and battle.rebuilds == 1, "original apply path once")
		check(ready_count == before_ready + 1 and battle.demon_active_augment_level == 3, "next queued level opens synchronously")
		check(battle.flow_pause_manager.paused and battle.demon_augment_selection_active, "next offer remains paused")
		check(not battle.choose_demon_augment("fixture_a", rerolled_revision), "previous level cannot choose same id")
		check(battle.applied == 1, "no duplicate stack")
		check(battle.choose_demon_augment("fixture_a"), "legacy API chooses current offer")
		check(battle.applied == 2 and battle.demon_build_counts.fixture_a == 2, "two queued levels accounted")
		check(not battle.demon_augment_selection_active and not battle.flow_pause_manager.paused, "selection releases pause")
		check(not battle.choose_demon_augment("fixture_a", displayed_revision), "closed offer denied")
		battle.start_offer([4])
		check(not battle.choose_demon_augment("fixture_a", displayed_revision), "max stack preserved")
		check(battle.choose_demon_augment("fixture_special", displayed_revision), "special original path")
		check(battle.run_metrics.specials == 1 and battle.demon_special_augments.size() == 1, "special recorded once")
		battle.start_offer([5])
		check(not battle.choose_demon_augment("fixture_special", displayed_revision), "special duplicate denied")
		battle.demon_rerolls_left = 0
		check(not battle.reroll_demon_augments(displayed_revision), "reroll cap preserved")
		if routed:
			var epoch: int = battle.battle_command_router.snapshot().session_id
			var packet := REQUEST.new(RULES.PROTOCOL_VERSION, epoch, 1, 100, RULES.Command.DEMON_AUGMENT_REROLL, "", Vector2.ZERO, "", displayed_revision)
			check(not battle.battle_command_router.submit(packet), "cost rejection")
			battle.demon_rerolls_left = 1
			check(not battle.battle_command_router.submit(packet), "failed action cannot replay after refill")
			check(battle.demon_rerolls_left == 1, "replay cannot consume reroll")
		for mode in [RULES.Mode.HERO_SOLO, RULES.Mode.PVP_CASUAL, RULES.Mode.PVP_RANKED]:
			battle.battle_command_router.begin_session(battle._execute_battle_command, mode)
			check(not battle.choose_demon_augment("fixture_a", displayed_revision), "future choose blocked on/off")
			check(not battle.reroll_demon_augments(displayed_revision), "future reroll blocked on/off")
		battle.queue_free()
	print("battle_augment_boundary_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
