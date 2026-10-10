extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
class Victim extends Node2D:
	var current_hp := 100000
	var hits: Array = []
	var callback: Callable
	func take_damage(amount):
		hits.append(amount)
		if callback.is_valid(): callback.call()
var checks := 0
var failures := 0
var epoch := 0
var scope: Scope
var config := {"spike_count": 3, "spike_spacing": 20.0, "spike_radius": 100.0, "spike_delay": 0.02, "branch_distance_ratio": 0.5}
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize(): call_deferred("run")
func actor(script):
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	return a
func recycle(a):
	scope.registry.retire_instance(a.get_instance_id())
	scope.registry.activate(a)
func run():
	var before = load("res://tests/actor_before.gd")
	var after = load("res://tests/actor_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	epoch = 1
	var victim = Victim.new()
	scope.add_child(victim)
	var other = Victim.new()
	scope.add_child(other)
	# Real timers, fixed RNG and full FX/position/damage comparison.
	for empowered in [false, true]:
		for ice in [true, false]:
			var old = actor(before)
			var fresh = actor(after)
			old.candidates = [victim]
			fresh.candidates = [victim]
			victim.hits.clear()
			seed(413)
			if ice: await old._resolve_archmage_ice_pillars(Vector2.ZERO, empowered)
			else: await old._cast_archmage_earth_spikes(config, empowered)
			var hits = victim.hits.duplicate()
			victim.hits.clear()
			seed(413)
			if ice: await fresh._resolve_archmage_ice_pillars(Vector2.ZERO, empowered)
			else: await fresh._cast_archmage_earth_spikes(config, empowered)
			check(old.effects == fresh.effects, "normal FX sequence/positions/scale preserved")
			check(hits == victim.hits and old.audio == fresh.audio, "normal damage/dedup/audio preserved")
			check(fresh.archmage_casting_sequence_count == 0, "normal casting cleanup")
			old.free()
			fresh.free()
	# Invalidation during await must stop next pulse and protect new life counter.
	for mode in ["recycle", "epoch", "dead", "reparent"]:
		for ice in [true, false]:
			var a = actor(after)
			a.candidates = [victim]
			victim.hits.clear()
			if ice: a._resolve_archmage_ice_pillars(Vector2.ZERO, false)
			else: a._cast_archmage_earth_spikes(config, false)
			var fx_count = a.effects.size()
			if mode == "recycle": recycle(a)
			elif mode == "epoch":
				epoch += 1
				scope.registry.begin_session(epoch)
				scope.registry.activate(a)
			elif mode == "dead": a.current_hp = 0
			else:
				scope.remove_child(a)
				root.add_child(a)
			if mode != "dead": a.archmage_casting_sequence_count = 5
			await create_timer(0.09).timeout
			check(a.effects.size() == fx_count, "old delayed task stops: " + mode)
			check(a.archmage_casting_sequence_count == (0 if mode == "dead" else 5), "cleanup cannot affect new life: " + mode)
			a.free()
	# Reproducer: old ice implementation continues after registry retirement.
	var old = actor(before)
	old._resolve_archmage_ice_pillars(Vector2.ZERO, false)
	recycle(old)
	await create_timer(0.19).timeout
	check(old.effects.size() == 4, "baseline reproduces stale ice pulses")
	old.free()
	# Damage callback invalidation stops subsequent victims even in same pulse.
	for ice in [true, false]:
		var a = actor(after)
		a.candidates = [victim, other]
		victim.hits.clear()
		other.hits.clear()
		victim.callback = func(): recycle(a)
		if ice: await a._resolve_archmage_ice_pillars(Vector2.ZERO, false)
		else: await a._cast_archmage_earth_spikes(config, false)
		check(victim.hits.size() == 1 and other.hits.is_empty(), "callback retires source before next victim")
		check(a._combat_monster_scratch.is_empty(), "scratch cleared on cancellation")
		victim.callback = Callable()
		a.free()
	# Concurrent casts each keep their own source lease; current AoE remains fresh.
	var a = actor(after)
	a._resolve_archmage_ice_pillars(Vector2.ZERO, false)
	a._resolve_archmage_ice_pillars(Vector2.ZERO, true)
	a.candidates = [other]
	other.hits.clear()
	await create_timer(0.21).timeout
	check(a.effects.size() == 8 and other.hits.size() == 4, "independent concurrent casts hit newly available AoE victims")
	var first = a._capture_delayed_skill_source()
	var second = a._capture_delayed_skill_source()
	check(first != second and a._is_delayed_skill_source_current(first), "per-cast reservations independent")
	for i in range(200):
		var life = a._capture_delayed_skill_source()
		recycle(a)
		check(not a._is_delayed_skill_source_current(life), "200 reuse generations reject previous cast")
	a.free()
	# Queued scope, queued source and detached source invalidate immediately.
	for mode in ["scope", "source", "detach"]:
		var holder = Scope.new()
		root.add_child(holder)
		holder.registry.begin_session(1)
		var queued = after.new()
		holder.add_child(queued)
		holder.registry.activate(queued)
		var life = queued._capture_delayed_skill_source()
		if mode == "scope": holder.queue_free()
		elif mode == "source": queued.queue_free()
		else: holder.remove_child(queued)
		check(not queued._is_delayed_skill_source_current(life), "queued/detached life rejected: " + mode)
		if mode == "detach": queued.free()
		if mode != "scope": holder.queue_free()
	await process_frame
	# Invalid entry never increments casting count or spawns FX.
	a = actor(after)
	scope.registry.retire_instance(a.get_instance_id())
	a._cast_archmage_earth_spikes(config, false)
	a._resolve_archmage_ice_pillars(Vector2.ZERO, false)
	check(a.effects.is_empty() and a.archmage_casting_sequence_count == 0, "unregistered source fails closed")
	a.free()
	scope.free()
	print("Delayed Hero skill checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
