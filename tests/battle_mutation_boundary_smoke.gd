extends SceneTree

const RULES := preload("res://src/data/battle_session_catalog.gd")
const REQUEST := preload("res://src/systems/battle_command.gd")
var checks := 0
var failures := 0
var displayed_revision := 0
var results: Array[bool] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func on_ready(_event: Dictionary, _candidates: Array, battle: Node) -> void:
	displayed_revision = battle.get_mutation_choice_revision()

func on_result(ok: bool, _message: String) -> void:
	results.append(ok)

func run() -> void:
	var script := load("res://tests/battle_boundary_fixture.gd") as Script
	if script == null:
		push_error("Build isolated fixture first")
		quit(1)
		return
	for routed in [true, false]:
		var battle = script.new()
		root.add_child(battle)
		battle.command_routing_enabled = routed
		battle.mutation_choice_ready.connect(on_ready.bind(battle))
		battle.mutation_spawn_result.connect(on_result)
		check(not battle.try_choose_mutation("slime"), "no active offer")
		battle._open_mutation_choice({"spawn_distance": 500.0, "name_prefix": "elite", "type": "elite"})
		var first: int = displayed_revision
		check(first > 0 and battle.flow_pause_manager.paused, "version published before ready")
		check(not battle.try_choose_mutation("ghost", first), "noncandidate")
		check(battle.mutation_director.is_active() and battle.mutation_spawns == 0, "invalid input preserves offer")
		check(battle.try_choose_mutation("slime", first), "valid selection")
		check(battle.mutation_spawns == 1 and results.back(), "spawn once / success signal")
		check(battle.last_mutation_event.spawn_distance == 260.0, "existing distance clamp")
		check(battle.announcements == 1 and battle.reinforcement_requests == 1, "existing announcement/reinforcement")
		check(not battle.mutation_director.is_active() and not battle.flow_pause_manager.paused, "choice consumed and pause released")
		check(not battle.try_choose_mutation("slime", first), "duplicate choice")
		battle._open_mutation_choice({"name_prefix": "next"})
		var second: int = displayed_revision
		check(second > first, "same ids different event version")
		check(not battle.try_choose_mutation("slime", first), "old event cannot select new offer")
		check(battle.mutation_spawns == 1 and battle.mutation_director.is_active(), "stale offer no effect")
		battle.demon_pending_augment_levels.assign([2])
		battle.demon_pending_augments = 1
		check(battle.try_choose_mutation("orc", second), "current offer")
		await process_frame
		check(battle.demon_augment_selection_active and battle.flow_pause_manager.paused, "deferred next augment opens")
		check(battle.choose_demon_augment("fixture_a"), "queued augment usable")
		battle._open_mutation_choice({})
		battle.mutation_spawn_allowed = false
		check(not battle.try_choose_mutation("slime", displayed_revision), "spawn failure return")
		check(not results.back() and not battle.mutation_director.is_active(), "failure signal and consumption preserved")
		check(not battle.flow_pause_manager.paused, "failure still releases pause")
		check(battle.last_mutation_event.hp_multiplier == 2.8, "existing fallback elite values")
		battle.mutation_spawn_allowed = true
		battle._open_mutation_choice({})
		battle.spawn_selected_mutation("orc")
		check(results.back() and not battle.mutation_director.is_active(), "legacy void API works")
		battle._open_mutation_choice({})
		for mode in [RULES.Mode.HERO_SOLO, RULES.Mode.PVP_CASUAL, RULES.Mode.PVP_RANKED]:
			battle.battle_command_router.begin_session(battle._execute_battle_command, mode)
			var count: int = battle.mutation_spawns
			check(not battle.try_choose_mutation("slime", displayed_revision), "future mode on/off blocked")
			check(battle.mutation_spawns == count, "future mode cannot consume offer")
		battle.battle_command_router.begin_session(battle._execute_battle_command)
		if routed:
			var epoch: int = battle.battle_command_router.snapshot().session_id
			var command := REQUEST.new(RULES.PROTOCOL_VERSION, epoch, 1, 1, RULES.Command.MUTATION_CHOOSE, "slime")
			check(not battle.battle_command_router.submit(command), "requires revision")
			command.choice_revision = displayed_revision
			command.position = Vector2.ONE
			check(not battle.battle_command_router.submit(command), "rejects position")
			command.position = Vector2.ZERO
			check(battle.battle_command_router.submit(command), "typed selection")
			check(not battle.battle_command_router.submit(command), "sequence duplicate")
		battle.queue_free()
	await process_frame
	print("battle_mutation_boundary_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
