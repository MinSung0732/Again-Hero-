extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
const REFERENCE := preload("res://src/systems/battle_target_reference.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
class Target extends Node2D:
	var current_hp := 10000
	var hits: Array[int] = []
	func take_damage(amount: int):
		hits.append(amount)
		current_hp -= amount
class PartialScope extends Node:
	func get_battle_entity_handle(_n): return Vector3i.ONE
var checks := 0
var failures := 0
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize(): call_deferred("run")
func run():
	var script = load("res://tests/charge_actor.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	var actor = script.new()
	scope.add_child(actor)
	var target = Target.new()
	target.position = Vector2(200, 0)
	scope.add_child(target)
	scope.registry.activate(target)
	var ref = actor.fighter_charge_reference
	actor._begin_fighter_charge_dash(target)
	check(actor.fighter_charge_active, "registered target starts charge")
	actor.candidates = [target]
	actor._update_fighter_charge(1.0)
	check(target.hits == [120, 170], "direct plus fresh area damage unchanged")
	check(actor.impacts == 1 and not actor.fighter_charge_active, "normal completion")
	check(ref.resolve(scope) == null and actor.fighter_charge_reference == ref, "clear and reference reused")
	for i in range(200):
		target.hits.clear()
		actor._begin_fighter_charge_dash(target)
		var old = scope.registry.get_handle(target)
		scope.registry.retire(old)
		scope.registry.activate(target)
		if i % 2 == 0: actor._update_fighter_charge(1.0)
		else: actor._complete_fighter_charge_dash()
		check(target.hits.is_empty(), "reused Node rejects old hit")
		check(not actor.fighter_charge_active and ref.resolve(scope) == null, "cancel old charge")
	actor._begin_fighter_charge_dash(target)
	scope.registry.begin_session(2)
	scope.registry.activate(target)
	actor._update_fighter_charge(1.0)
	check(target.hits.is_empty(), "new session rejects old charge")
	actor._begin_fighter_charge_dash(target)
	actor.on_clamp = func():
		scope.registry.retire_instance(target.get_instance_id())
		scope.registry.activate(target)
	actor._update_fighter_charge(1.0)
	check(target.hits.is_empty(), "completion rechecks callback invalidation")
	actor.on_clamp = Callable()
	# Area effects query current lives, so newly activated bystanders remain hittable.
	var bystander = Target.new()
	bystander.position = Vector2(154,0)
	scope.add_child(bystander)
	scope.registry.activate(bystander)
	actor.candidates = [bystander]
	actor._begin_fighter_charge_dash(target)
	actor._update_fighter_charge(1.0)
	check(target.hits == [120] and bystander.hits == [170], "fresh AoE stays independent of reservation")
	actor.next_target = bystander
	actor.fighter_charge_config.max_chains = 2
	actor.fighter_charge_chain_count = 0
	actor._begin_fighter_charge_dash(target)
	actor._complete_fighter_charge_dash()
	check(actor.fighter_charge_active and ref.resolve(scope) == bystander, "chain captures next life")
	scope.registry.retire_instance(bystander.get_instance_id())
	scope.registry.activate(bystander)
	var hit_count = bystander.hits.size()
	actor._update_fighter_charge(1.0)
	check(bystander.hits.size() == hit_count and not actor.fighter_charge_active, "next chain lifetime guarded")
	var unregistered = Target.new()
	scope.add_child(unregistered)
	actor._begin_fighter_charge_dash(unregistered)
	check(not actor.fighter_charge_active, "tracked missing handle fails closed")
	var partial = PartialScope.new()
	check(not ref.capture(target, partial), "partial interface fails closed")
	partial.free()
	var legacy = Node.new()
	root.add_child(legacy)
	check(ref.capture(target, legacy) and ref.resolve(legacy) == target, "legacy non-registry fallback")
	check(ref.resolve(scope) == null, "scope cannot change")
	ref.clear()
	check(ref.resolve(legacy) == null, "explicit clear")
	var weak_target = Target.new()
	check(ref.capture(weak_target, legacy), "weak capture")
	weak_target.free()
	check(ref.resolve(legacy) == null, "freed target cannot resolve")
	var queued = Target.new()
	legacy.add_child(queued)
	check(ref.capture(queued, legacy), "queue setup")
	queued.queue_free()
	check(ref.resolve(legacy) == null, "queued target cannot resolve")
	check(ref.capture(target, scope), "live registered capture")
	scope.queue_free()
	check(ref.resolve(scope) == null, "queued scope invalidates")
	legacy.queue_free()
	await process_frame
	print("charge_lifetime_smoke: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
