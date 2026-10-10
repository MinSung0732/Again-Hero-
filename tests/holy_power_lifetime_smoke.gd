extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
class Victim extends Node2D:
	var current_hp := 100000
	var undead := false
	var hits: Array = []
	var callback: Callable
	func take_damage(damage):
		hits.append(damage)
		if callback.is_valid(): callback.call()
var scope: Scope
var epoch := 1
var checks := 0
var failures := 0
var config := {"burst_count":3, "burst_delay":0.02, "burst_spawn_radius":20.0, "burst_hit_radius":100.0}
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize(): call_deferred("run")
func actor(script, victim):
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	a.cluster = victim
	a.candidates = [victim]
	return a
func recycle(node):
	scope.registry.retire_instance(node.get_instance_id())
	scope.registry.activate(node)
func clear_status(victim):
	for key in ["gunner_slow_multiplier", "gunner_slow_until"]:
		if victim.has_meta(key): victim.remove_meta(key)
func run():
	var before = load("res://tests/holy_before.gd")
	var after = load("res://tests/holy_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(epoch)
	var victim = Victim.new()
	scope.add_child(victim)
	scope.registry.activate(victim)
	var other = Victim.new()
	scope.add_child(other)
	scope.registry.activate(other)
	# Fixed RNG normal casts: full effect parameters, damage and slow semantics.
	for empowered in [false,true]:
		for undead in [false,true]:
			victim.undead = undead
			var old = actor(before,victim)
			var fresh = actor(after,victim)
			victim.hits.clear()
			seed(418)
			await old._cast_archmage_holy_power(config,empowered)
			var hits = victim.hits.duplicate()
			victim.hits.clear()
			clear_status(victim)
			seed(418)
			await fresh._cast_archmage_holy_power(config,empowered)
			check(old.effects == fresh.effects and old.audio == fresh.audio, "normal full FX/RNG/audio comparison")
			check(hits == victim.hits, "normal undead/empowered damage comparison")
			check(victim.get_meta("gunner_slow_multiplier") == 0.6, "slow multiplier preserved")
			var remaining = victim.get_meta("gunner_slow_until") - Time.get_ticks_msec()
			check(remaining > 1800 and remaining <= 2000, "slow duration uses damage time")
			check(fresh.archmage_casting_sequence_count == 0, "normal cleanup")
			old.free()
			fresh.free()
	for mode in ["recycle","epoch","dead","reparent"]:
		var a = actor(after,victim)
		a._cast_archmage_holy_power(config,false)
		if mode == "recycle": recycle(a)
		elif mode == "epoch":
			epoch += 1
			scope.registry.begin_session(epoch)
			scope.registry.activate(a)
			scope.registry.activate(victim)
			scope.registry.activate(other)
		elif mode == "dead": a.current_hp = 0
		else:
			scope.remove_child(a)
			root.add_child(a)
		if mode != "dead": a.archmage_casting_sequence_count = 9
		await create_timer(0.11).timeout
		check(a.effects.size() == 1, "cancel await pulses: "+mode)
		check(a.archmage_casting_sequence_count == (0 if mode == "dead" else 9), "life-aware casting cleanup: "+mode)
		a.free()
	# A damage callback must not attach slow to the new target generation.
	for i in range(200):
		var a = actor(after,victim)
		clear_status(victim)
		victim.callback = func(): recycle(victim)
		await a._cast_archmage_holy_power({"burst_count":1,"burst_hit_radius":1000.0,"burst_delay":0.02},false)
		check(not victim.has_meta("gunner_slow_multiplier") and not victim.has_meta("gunner_slow_until"), "200 recycled victims reject old slow")
		check(a.archmage_casting_sequence_count == 0, "recycled victim leaves source cleanup intact")
		victim.callback = Callable()
		a.free()
	# Baseline reproduces the status leak onto a reused target.
	var old = actor(before,victim)
	clear_status(victim)
	victim.callback = func(): recycle(victim)
	await old._cast_archmage_holy_power({"burst_count":1,"burst_hit_radius":1000.0,"burst_delay":0.02},false)
	check(victim.has_meta("gunner_slow_multiplier"), "baseline reused-target slow reproduced")
	victim.callback = Callable()
	old.free()
	# Source invalidation inside take_damage stops slow and remaining victims.
	var a = actor(after,victim)
	a.candidates = [victim,other]
	clear_status(victim)
	other.hits.clear()
	victim.callback = func(): recycle(a)
	await a._cast_archmage_holy_power(config,false)
	check(not victim.has_meta("gunner_slow_multiplier") and other.hits.is_empty(), "source callback cancels slow/next victim")
	check(a.effects.size() == 1 and a.archmage_query_candidates.is_empty(), "cancel remaining FX and clear query scratch")
	victim.callback = Callable()
	a.free()
	# Queued victim: no metadata writes after lethal callback.
	var queued = Victim.new()
	scope.add_child(queued)
	scope.registry.activate(queued)
	a = actor(after,queued)
	queued.callback = func(): queued.queue_free()
	a._cast_archmage_holy_power(config,false)
	check(not queued.has_meta("gunner_slow_multiplier"), "queued deletion prevents slow")
	await create_timer(0.11).timeout
	check(a.effects.size() == 3, "source remains valid after victim deletion")
	a.free()
	# A callback may free another entry before the query loop reaches it.
	var doomed = Victim.new()
	scope.add_child(doomed)
	scope.registry.activate(doomed)
	a = actor(after,victim)
	a.candidates = [victim,doomed]
	var doomed_id = doomed.get_instance_id()
	victim.callback = func():
		var live = instance_from_id(doomed_id)
		if is_instance_valid(live): live.free()
	await a._cast_archmage_holy_power(config,false)
	check(a.effects.size() == 3 and a.archmage_casting_sequence_count == 0, "freed next candidate safely skipped")
	victim.callback = Callable()
	a.free()
	# Scope queued during damage stops the cast immediately.
	var holder = Scope.new()
	root.add_child(holder)
	holder.registry.begin_session(1)
	a = after.new()
	holder.add_child(a)
	holder.registry.activate(a)
	a.cluster = victim
	a.candidates = [victim,other]
	other.hits.clear()
	clear_status(victim)
	victim.callback = func(): holder.queue_free()
	a._cast_archmage_holy_power(config,false)
	check(not victim.has_meta("gunner_slow_multiplier") and other.hits.is_empty(), "queued scope blocks post-damage status and victims")
	victim.callback = Callable()
	await process_frame
	# Catalog clamp semantics are unchanged at zero duration/extreme multipliers.
	for multiplier in [-1.0,2.0]:
		a = actor(after,victim)
		await a._cast_archmage_holy_power({"burst_count":1,"burst_hit_radius":1000.0,"burst_delay":0.02,"slow_duration":-1.0,"slow_multiplier":multiplier},false)
		check(victim.get_meta("gunner_slow_multiplier") == clampf(multiplier,0.0,1.0), "slow clamp preserved")
		check(victim.get_meta("gunner_slow_until") <= Time.get_ticks_msec(), "negative duration clamps to zero")
		a.free()
	# Concurrent casts use independent leases and fresh AoE, not initial target life.
	a = actor(after,victim)
	a.candidates = []
	a._cast_archmage_holy_power(config,false)
	a._cast_archmage_holy_power(config,true)
	other.hits.clear()
	a.candidates = [other]
	await create_timer(0.15).timeout
	check(a.effects.size() == 6 and other.hits.size() == 4, "concurrent fresh AoE pulses")
	check(a.archmage_casting_sequence_count == 0 and not a.archmage_casting_sequence, "concurrent counter cleanup")
	a.free()
	# Baseline stale source resumes; WeakRef-only independent scenes stay compatible.
	old = actor(before,victim)
	old._cast_archmage_holy_power(config,false)
	recycle(old)
	await create_timer(0.15).timeout
	check(old.effects.size() == 3, "baseline stale source pulses reproduced")
	old.free()
	var legacy = Node.new()
	root.add_child(legacy)
	a = after.new()
	legacy.add_child(a)
	a.cluster = victim
	a.candidates = [victim]
	clear_status(victim)
	await a._cast_archmage_holy_power(config,false)
	check(a.effects.size() == 3 and victim.has_meta("gunner_slow_multiplier"), "untracked standalone scene preserves normal cast")
	legacy.free()
	# No cluster and unregistered source must leave no stuck casting state.
	a = actor(after,null)
	await a._cast_archmage_holy_power(config,false)
	check(a.effects.is_empty() and a.archmage_casting_sequence_count == 0, "no cluster clean exit")
	scope.registry.retire_instance(a.get_instance_id())
	a.cluster = victim
	await a._cast_archmage_holy_power(config,false)
	check(a.effects.is_empty() and a.archmage_casting_sequence_count == 0, "unregistered source fails closed")
	a.free()
	scope.free()
	print("Holy power lifetime checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
