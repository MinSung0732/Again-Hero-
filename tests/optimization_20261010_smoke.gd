extends SceneTree

const BUFFER := preload("res://src/systems/timed_event_buffer.gd")
const GRID := preload("res://src/systems/monster_local_grid.gd")
const AI := preload("res://src/ai/hero_build_ai.gd")
const METRICS := preload("res://src/systems/run_metrics.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const WARMUP := preload("res://src/systems/presentation_warmup.gd")
var failed := false

class Actor extends Node2D:
	var current_hp := 100


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("OPTIMIZATION: " + message)


func legacy(name: String) -> GDScript:
	# Immutable production snapshots at 1d5ad4ce, not rewritten expectations.
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/optimization_20261010/" + name + ".gd.txt")
	check(script.reload() == OK, "baseline parses: " + name)
	return script


func test_buffer_and_memory() -> void:
	var buffer := BUFFER.new()
	var reference: Array = []
	for i in range(4096):
		var event := {"time": float(i) * 0.02, "ordinal": i}
		buffer.append(event)
		reference.append(event)
		var cutoff := float(i) * 0.02 - 3.0
		buffer.prune_before(cutoff)
		while not reference.is_empty() and float(reference[0].time) < cutoff:
			reference.pop_front()
		check(buffer.size() == reference.size(), "window live count")
		for index in range(reference.size()):
			check(buffer.get_event(index) == reference[index], "FIFO order/exact cutoff")
		check(buffer._events.size() <= 2 * buffer.size() + BUFFER.COMPACT_MINIMUM, "bounded dead slots")
	buffer.prune_before(INF)
	check(buffer.is_empty() and buffer._events.is_empty(), "empty window releases storage")
	var value: RefCounted = RefCounted.new()
	var observer: WeakRef = weakref(value)
	buffer.append({"time": 0.0, "reference": value})
	buffer.append({"time": 10.0})
	value = null
	buffer.prune_before(1.0)
	check(observer.get_ref() == null, "expired nested reference released before compaction")
	buffer.clear()
	var hero = load("res://src/hero/hero.gd").new()
	for i in range(1200):
		hero.ai_memory_clock = float(i) * 0.025
		hero.record_offensive_event("slime" if i % 2 == 0 else "orc")
		hero.record_status_effect_event("slow" if i % 3 == 0 else "poison")
	var now: float = hero.ai_memory_clock
	var offense: Dictionary = hero._build_recent_offense_memory()
	var status: Dictionary = hero._build_recent_status_memory()
	var count := 0
	var weights: Dictionary = {}
	var total := 0.0
	for i in range(1200):
		var time := float(i) * 0.025
		if time < now - hero.OFFENSE_MEMORY_WINDOW:
			continue
		count += 1
		var kind := "slime" if i % 2 == 0 else "orc"
		var weight := lerpf(hero.OFFENSE_MEMORY_MIN_WEIGHT, 1.0, 1.0 - clampf((now - time) / hero.OFFENSE_MEMORY_WINDOW, 0.0, 1.0))
		weights[kind] = float(weights.get(kind, 0.0)) + weight
		total += weight
	check(offense.event_count == count and offense.type_weights == weights and offense.total_weight == total, "real Hero offense weighting unchanged")
	count = 0
	var status_counts: Dictionary = {}
	var status_weights: Dictionary = {}
	for i in range(1200):
		var time := float(i) * 0.025
		if time < now - hero.STATUS_MEMORY_WINDOW:
			continue
		count += 1
		var kind := "slow" if i % 3 == 0 else "poison"
		status_counts[kind] = int(status_counts.get(kind, 0)) + 1
		var weight := lerpf(hero.STATUS_MEMORY_MIN_WEIGHT, 1.0, 1.0 - clampf((now - time) / hero.STATUS_MEMORY_WINDOW, 0.0, 1.0))
		status_weights[kind] = float(status_weights.get(kind, 0.0)) + weight
	check(status.event_count == count and status.status_counts == status_counts and status.status_weights == status_weights, "real Hero raw status refresh weighting unchanged")
	hero.free()


func test_ai_and_metrics() -> void:
	var old_ai := legacy("hero_build_ai")
	var candidates: Array = [
		{"id": "a", "name": "A", "base_score": 1.0, "randomness": 0.4, "ai_rules": [{"source": "nearby_linear", "weight": 0.15}]},
		{"id": "b", "name": "B", "base_score": 2.0, "randomness": 0.4, "ai_rules": [{"source": "hp_missing", "weight": 2.0}]},
		{"id": "c", "name": "C", "base_score": 3.0, "randomness": 0.4, "nested": {"values": [1, 2]}}
	]
	var pristine := candidates.duplicate(true)
	for trial in range(100):
		var context := {"nearby_count": trial % 20, "hp_ratio": float(trial % 10) / 10.0, "observation_age": 0.5}
		var settings := {"augment_biases": {"a": 0.3}, "new_branch_penalty": 0.4}
		seed(trial)
		var before: Dictionary = old_ai.choose_candidate(candidates, context, {"a": 2}, settings)
		var before_rng := randf()
		seed(trial)
		var after := AI.choose_candidate(candidates, context, {"a": 2}, settings)
		check(before == after and before_rng == randf(), "AI decision/reason/debug/RNG unchanged")
	check(candidates == pristine, "AI input dictionaries stay immutable")
	var chosen := AI.choose_candidate([candidates[2]], {}, {}, {})
	chosen.nested.values.append(3)
	check(candidates == pristine, "winner remains a deep independent copy")
	check(AI.choose_candidate([], {}, {}, {}).is_empty(), "empty AI candidate list")
	var before = legacy("run_metrics").new()
	var after := METRICS.new()
	before.reset(600.0, 1000, 1000)
	after.reset(600.0, 1000, 1000)
	for i in range(3000):
		var delta := 16.0 if i % 83 == 0 else 0.013
		before.tick(delta)
		after.tick(delta)
		var kind := "slime" if (i / 100) % 2 == 0 else "orc"
		var cost := 3.0 if kind == "slime" else 18.0
		before.record_summon(kind, cost)
		after.record_summon(kind, cost)
		check(before.get_snapshot() == after.get_snapshot(), "RunMetrics counters/switch times/results unchanged")
	check(before.get_result_summary() == after.get_result_summary(), "identical player-facing result summary")


func test_grid() -> void:
	var before = legacy("monster_local_grid").new()
	var after := GRID.new()
	var host := Node2D.new()
	root.add_child(host)
	var actors: Dictionary = {}
	for i in range(24):
		var actor := Actor.new()
		host.add_child(actor)
		actor.add_to_group("audit_actor")
		actors[actor.get_instance_id()] = actor
	var expected: Array = []
	var actual: Array = []
	for step in range(128):
		var index := 0
		for id in actors:
			var actor: Node2D = actors[id]
			actor.position = Vector2(step * 128 + (index % 8) * 12 - 1500, (index / 8) * 11 - step * 128)
			index += 1
		before.ensure(actors, step)
		after.ensure(actors, step)
		check(after.buckets.size() == after.used_cells.size() and after.spare_buckets.size() <= 128, "grid memory independent of travel history")
		for id in actors:
			var actor: Node2D = actors[id]
			check(before.separation_bias(actor, 25.0).is_equal_approx(after.separation_bias(actor, 25.0)), "same steering")
			check(before.count_group_near(actor.position, 60, &"audit_actor", actor, 3) == after.count_group_near(actor.position, 60, &"audit_actor", actor, 3), "same group count/early exit")
			var rect := Rect2(actor.position - Vector2.ONE * 24, Vector2.ONE * 48)
			before.fill_rect(rect, expected)
			after.fill_rect(rect, actual)
			check(expected == actual, "same rectangle hit set and order")
	print("OPTIMIZATION grid historical_cells=%d live_cells=%d spare=%d" % [before.buckets.size(), after.buckets.size(), after.spare_buckets.size()])
	after.clear()
	check(after.buckets.is_empty() and after.spare_buckets.is_empty(), "grid reset releases cache")
	for path in ["res://src/systems/wolf_pack_runtime.gd", "res://src/systems/yuki_onna_runtime.gd"]:
		var runtime = load(path).new()
		var corpse := Node2D.new()
		for step in range(256):
			corpse.position = Vector2(step * 250, -step * 250)
			runtime.record_death(corpse)
			runtime.tick(0.016)
			check(runtime.death_cells.is_empty() and runtime.spare_death_buckets.size() == 1, "death event buckets recycle after batch: " + path)
		runtime.reset()
		check(runtime.spare_death_buckets.is_empty(), "death cache reset")
		corpse.free()
	host.free()


func popup_ownership(spawner: GDScript) -> bool:
	var host := Node2D.new()
	root.add_child(host)
	var first := Node2D.new()
	var second := Node2D.new()
	host.add_child(first)
	host.add_child(second)
	spawner.show(first, 10)
	var old = first.get_meta("damage_number_popup")
	old._deactivate_for_pool()
	spawner.show(second, 20) # Reuse first's popup for another live target.
	spawner.show(first, 5)
	var okay: bool = second.get_meta("damage_number_popup").numeric_amount == 20 and first.get_meta("damage_number_popup").numeric_amount == 5
	host.free()
	return okay


func test_popups_and_warmup() -> void:
	check(not popup_ownership(legacy("damage_number_spawner")), "baseline reproduces cross-target popup merge")
	check(popup_ownership(POPUPS), "reused popup only merges its current owner")
	var host := Node2D.new()
	root.add_child(host)
	var dead := Node2D.new()
	host.add_child(dead)
	var pool: Array = [dead]
	host.set_meta(POPUPS.POOL_META, pool)
	dead.free()
	check(POPUPS._get_compacted_pool(host).is_empty(), "stale pool nodes removed")
	pool.append(Node2D.new())
	check(POPUPS._get_compacted_pool(host).size() == 1, "caller and metadata retain the same array")
	pool[0].free()
	for i in range(60):
		POPUPS.show_text_at(host, Vector2.ZERO, "text")
	check(host.get_meta(POPUPS.POOL_META).size() == 48, "original popup capacity retained")
	host.free()
	var paths: Array[String] = ["a", "", "b", "a", "c", "b"]
	check(WARMUP.unique_paths(paths) == ["a", "b", "c"], "stable dedupe/no empty path")


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	test_buffer_and_memory()
	test_ai_and_metrics()
	test_grid()
	test_popups_and_warmup()
	print("OPTIMIZATION_20261010: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
