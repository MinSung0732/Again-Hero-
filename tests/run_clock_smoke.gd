extends SceneTree

# Run in the project created by build_run_clock_fixture.py.
const CLOCK := preload("res://src/systems/battle_run_clock.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var before_script := load("res://tests/run_metrics_before.gd") as Script
	var after_script := load("res://tests/run_metrics_after.gd") as Script
	if before_script == null or after_script == null:
		push_error("Build the isolated project with build_run_clock_fixture.py first")
		quit(1)
		return
	var old = before_script.new()
	var current = after_script.new()
	old.reset(100.0, 1000, 1000)
	current.reset(100.0, 1000, 1000)
	var rewards := {"base_reward": 5, "victory_reward": 10, "damage_step_ratio": 0.1,
		"damage_step_reward": 2, "damage_max": 100, "demon_level_step_reward": 2,
		"demon_level_max": 50, "hero_level_step_reward": 1, "hero_level_max": 50,
		"summon_spend_step": 20.0, "summon_spend_step_reward": 3, "summon_spend_max": 100,
		"remaining_time_step_seconds": 30.0, "remaining_time_step_reward": 1, "remaining_time_max": 100,
		"hero_augment_reward": 1, "hero_augment_max": 100,
		"strategy_switch_reward": 2, "strategy_switch_max": 100, "total_max": 1000}
	for index in range(360):
		var delta := [0.016, 0.1, 1.5, 0.0, -0.5][index % 5] as float
		old.tick(delta)
		current.tick(delta)
		check(current.elapsed_seconds == old.elapsed_seconds, "elapsed baseline %d" % index)
		check(current.is_time_up() == old.is_time_up(), "deadline baseline %d" % index)
		check(current.get_remaining_seconds() == old.get_remaining_seconds(), "remaining baseline %d" % index)
		if index % 3 == 0:
			var id := "slime" if index % 30 < 15 else "orc"
			for metrics in [old, current]:
				metrics.record_summon(id, 8.0)
				metrics.record_summon_demon_exp(id, 4.0)
				metrics.record_monster_death(id)
				metrics.record_hero_damage(10)
				metrics.record_hero_hp(1000 - index, 1000 + index)
		if index % 30 == 0:
			old.record_hero_augment(index + 1, "fixture", "observation")
			current.record_hero_augment(index + 1, "fixture", "observation")
		if index == 60:
			old.record_special_augment_acquired()
			current.record_special_augment_acquired()
		if index % 10 == 0:
			check(current.get_snapshot() == old.get_snapshot(), "all metrics baseline %d" % index)
			check(current.get_result_summary() == old.get_result_summary(), "summary baseline %d" % index)
			for victory in [true, false]:
				check(current.get_research_reward_breakdown(victory, 12, 20, rewards) == old.get_research_reward_breakdown(victory, 12, 20, rewards), "reward baseline %d" % index)
	check(current.run_clock.advance_count == 216, "only positive advances counted, not fixed ticks")
	check(current.is_time_up(), "deadline reached")
	var stopped: float = current.elapsed_seconds
	for _frame in range(3):
		await process_frame
	check(current.elapsed_seconds == stopped, "no wall-clock/autonomous advance")
	current.tick(NAN)
	current.tick(INF)
	current.tick(-INF)
	check(current.elapsed_seconds == stopped, "invalid delta cannot poison run clock")
	check(current.run_clock.advance_count == 216, "invalid delta does not advance")
	current.elapsed_seconds = 42.0
	check(current.run_clock.elapsed_seconds == 42.0, "legacy elapsed property write")
	current.reset(100, 1000, 1000)
	check(current.elapsed_seconds == 0.0 and current.run_clock.advance_count == 0, "restart resets clock")
	check(current.summon_counts.is_empty() and current.strategy_switches.is_empty(), "restart clears metrics")
	current.record_summon("slime", 20)
	current.tick(15.0)
	check(current.recent_summons.size() == 1, "exact strategy boundary retained")
	current.tick(0.001)
	check(current.recent_summons.is_empty(), "expired strategy entry released")
	var clock = CLOCK.new()
	clock.advance(0.25)
	clock.advance(0.75)
	check(clock.snapshot() == {"elapsed_seconds": 1.0, "advance_count": 2}, "explicit clock diagnostics")
	clock.reset()
	check(clock.elapsed_seconds == 0.0 and clock.advance_count == 0, "independent clock reset")
	print("run_clock_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
