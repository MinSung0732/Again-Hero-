extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	func get_battle_entity_handle(node: Node) -> Vector3i:return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node:return registry.resolve(handle)
var scope: Scope
var epoch := 1
var checks := 0
var failures := 0
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script):
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	return a
func recycle(a):
	scope.registry.retire_instance(a.get_instance_id())
	scope.registry.activate(a)
func keys(calls: Array) -> Array:
	var result: Array = []
	for c in calls:result.append(c.slice(0,3))
	return result
func run():
	var before = load("res://tests/multi_before.gd")
	var after = load("res://tests/multi_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(epoch)
	# Fixed-seed normal behavior including filtering and failed-cast accounting.
	for mode in ["normal","chain_active","partial_config","all_fail","zero_stacks"]:
		var old = actor(before)
		var fresh = actor(after)
		for a in [old,fresh]:
			if mode == "chain_active":a.archmage_chain_dagger_active = true
			elif mode == "partial_config":a.archmage_skill_config = {"combustion":{},"ice_bolt":{},"storm":{}}
			elif mode == "all_fail":a.fail_skills = ["ice_bolt","earth_spikes","holy_power","chain_dagger","storm"]
			elif mode == "zero_stacks":a.archmage_multicast_stacks = 0
		seed(719)
		await old._start_archmage_multicast("combustion")
		seed(719)
		var fresh_started = Time.get_ticks_msec()
		await fresh._start_archmage_multicast("combustion")
		check(keys(old.calls) == keys(fresh.calls),"normal RNG/filter/order/false-false flags: "+mode)
		check(not fresh.archmage_multicast_active and fresh.archmage_multicast_candidates.is_empty(),"normal final cleanup: "+mode)
		if not fresh.calls.is_empty():
			check(fresh.calls[0][3] - fresh_started >= 290,"first additional cast waits 0.30 seconds")
		for i in range(1,fresh.calls.size()):
			check(fresh.calls[i][3] - fresh.calls[i-1][3] >= 290,"real 0.30 interval preserved")
		old.free()
		fresh.free()
	# Old start has a timer reservation that survives reset/new start in same life.
	for script in [before,after]:
		var a = actor(script)
		a.archmage_multicast_stacks = 1
		a._start_archmage_multicast("combustion")
		await create_timer(0.15).timeout
		a.reset_profile_slice()
		a.archmage_multicast_stacks = 1
		a._start_archmage_multicast("ice_bolt")
		var reserved = a.archmage_multicast_candidates.duplicate()
		await create_timer(0.20).timeout
		if script == before:
			check(not a.calls.is_empty() and not a.archmage_multicast_active,"baseline steals new reservation and clears state")
			# Keep the remaining baseline timer safe after reproducing corruption.
			a.archmage_multicast_candidates.assign(["storm"])
		else:
			check(a.calls.is_empty() and a.archmage_multicast_active and a.archmage_multicast_candidates == reserved,"old timer cannot pop or clear new reservation")
		await create_timer(0.20).timeout
		if script == after:check(a.calls.size() == 1 and not a.archmage_multicast_active,"new timer completes normally")
		a.free()
	for mode in ["recycle","epoch","dead","reparent","reset"]:
		var a = actor(after)
		a._start_archmage_multicast("combustion")
		if mode == "recycle":recycle(a)
		elif mode == "epoch":
			epoch += 1
			scope.registry.begin_session(epoch)
			scope.registry.activate(a)
		elif mode == "dead":a.current_hp = 0
		elif mode == "reparent":
			scope.remove_child(a)
			root.add_child(a)
		else:a.reset_profile_slice()
		if mode in ["recycle","epoch","reparent"]:
			a.archmage_multicast_candidates.assign(["sentinel"])
			a.archmage_multicast_active = true
		await create_timer(0.40).timeout
		check(a.calls.is_empty(),"no stale additional cast: "+mode)
		if mode in ["dead","reset"]:check(not a.archmage_multicast_active and a.archmage_multicast_candidates.is_empty(),"same life/reset cleanup: "+mode)
		else:check(a.archmage_multicast_active and a.archmage_multicast_candidates == ["sentinel"],"new life state left intact: "+mode)
		a.free()
	# Repeated restart reuses the same Array; only latest timer may consume it.
	var a = actor(after)
	a.archmage_multicast_stacks = 1
	var shared: Array = a.archmage_multicast_candidates
	for i in range(200):
		a._start_archmage_multicast("combustion")
		check(a.archmage_multicast_revision == i+1,"200 monotonic reservation revisions")
	await create_timer(0.40).timeout
	check(a.calls.size() == 1 and shared.is_empty() and not a.archmage_multicast_active,"200 old timers cancel; reused Array cleared by latest")
	a.free()
	# Callback reset/start in the same Node life must not be cleaned by old call.
	a = actor(after)
	a.archmage_multicast_stacks = 2
	a.callback = func():
		a.callback = Callable()
		a.reset_profile_slice()
		a.archmage_multicast_stacks = 1
		a._start_archmage_multicast("ice_bolt")
	a._start_archmage_multicast("combustion")
	await create_timer(0.40).timeout
	check(a.calls.size() == 1 and a.archmage_multicast_active,"callback new reservation retains active/list")
	await create_timer(0.40).timeout
	check(a.calls.size() == 2 and not a.archmage_multicast_active,"callback new reservation completes exactly once")
	a.free()
	# Callback invalidation must not schedule another old interval.
	a = actor(after)
	a.callback = func():recycle(a)
	a._start_archmage_multicast("combustion")
	await create_timer(0.75).timeout
	check(a.calls.size() == 1,"callback generation change stops subsequent cast")
	a.callback = Callable()
	a.free()
	# Empty configuration and unregistered source leave no stuck active state.
	a = actor(after)
	a.archmage_skill_config = {"combustion":{}}
	await a._start_archmage_multicast("combustion")
	check(not a.archmage_multicast_active and a.archmage_multicast_candidates.is_empty(),"empty candidates clean exit")
	scope.registry.retire_instance(a.get_instance_id())
	var revision = a.archmage_multicast_revision
	await a._start_archmage_multicast("combustion")
	check(a.archmage_multicast_revision == revision and a.calls.is_empty(),"invalid source does not touch reservations")
	a.free()
	scope.free()
	print("Multicast lifetime checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
