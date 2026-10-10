extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	func get_battle_entity_handle(node: Node) -> Vector3i:return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node:return registry.resolve(handle)
class Victim extends Node2D:
	var current_hp := 100000
	var hits: Array = []
	var callback: Callable
	func take_damage(amount):
		hits.append(amount)
		if callback.is_valid():callback.call()
var checks := 0
var failures := 0
var before
var after
func check(value: bool,msg: String):
	checks += 1
	if not value:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func world(script) -> Dictionary:
	var scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	var victims: Array = []
	for point in [Vector2.ZERO,Vector2(20,0),Vector2(500,0)]:
		var v = Victim.new()
		v.position = point
		scope.add_child(v)
		scope.registry.activate(v)
		victims.append(v)
	a.candidates = victims
	return {"scope":scope,"a":a,"v":victims}
func cleanup(w):
	for v in w.v:
		if is_instance_valid(v):v.callback = Callable()
	w.scope.free()
func reuse(w,node):
	w.scope.registry.retire_instance(node.get_instance_id())
	w.scope.registry.activate(node)
func run():
	before = load("res://tests/actor_before.gd")
	after = load("res://tests/actor_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	# Actual impact damage + full real-timer pillar sequence, fixed RNG comparison.
	for empowered in [false,true]:
		for hp in [100,0]:
			var old = world(before)
			var fresh = world(after)
			old.a.current_hp = hp
			fresh.a.current_hp = hp
			seed(739)
			old.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,empowered)
			await create_timer(0.20).timeout
			seed(739)
			fresh.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,empowered)
			await create_timer(0.20).timeout
			check(old.a.effects == fresh.a.effects and old.a.audio == fresh.a.audio,"normal FX/RNG/audio including source HP0")
			for i in range(3):check(old.v[i].hits == fresh.v[i].hits,"normal impact/pillar damage positions/order")
			check(fresh.v[2].hits.is_empty(),"outside radius ignored")
			check(fresh.v[0].hits[0] == (225 if empowered else 150),"exact impact empowerment damage")
			check(fresh.a.effects.size() == (0 if hp == 0 else 4),"HP0 retains impact but no new pillars")
			cleanup(old)
			cleanup(fresh)
	# Callback can reuse source mid-impact: no remaining old AoE/new-life pillars.
	for i in range(200):
		var w = world(after)
		w.v[0].callback = func():reuse(w,w.a)
		w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
		check(w.v[0].hits == [150] and w.v[1].hits.is_empty() and w.a.effects.is_empty(),"200 callback reuse stops old damage/pillars")
		cleanup(w)
	# Last affected victim's callback used to recapture a new life for pillars.
	var w = world(before)
	w.v[1].callback = func():reuse(w,w.a)
	w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
	check(not w.a.effects.is_empty(),"baseline stale-source pillar bug reproduced")
	await create_timer(0.20).timeout
	cleanup(w)
	w = world(after)
	w.v[1].callback = func():reuse(w,w.a)
	w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
	check(w.v[0].hits == [150] and w.v[1].hits == [150] and w.a.effects.is_empty(),"last victim source reuse cannot start pillars")
	cleanup(w)
	for mode in ["epoch","queued","retired"]:
		w = world(after)
		w.v[0].callback = func():
			if mode == "epoch":
				w.scope.registry.begin_session(2)
				w.scope.registry.activate(w.a)
			elif mode == "queued":w.a.queue_free()
			else:w.scope.registry.retire_instance(w.a.get_instance_id())
		w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
		check(w.v[0].hits == [150] and w.v[1].hits.is_empty() and w.a.effects.is_empty(),"source invalidation stops old impact "+mode)
		cleanup(w)
	# Entry rejects no identity/queued source before audio and damage.
	for mode in ["unregistered","queued"]:
		w = world(after)
		if mode == "unregistered":w.scope.registry.retire_instance(w.a.get_instance_id())
		else:w.a.queue_free()
		w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
		check(w.a.audio == 0 and w.v[0].hits.is_empty() and w.a.effects.is_empty(),"invalid impact entry "+mode)
		cleanup(w)
	# HP0 during damage retains already emitted AoE; original pillars gate still applies.
	w = world(after)
	w.v[0].callback = func():w.a.current_hp = 0
	w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
	check(w.v[0].hits == [150] and w.v[1].hits == [150] and w.a.effects.is_empty(),"HP0 callback preserves emitted impact policy")
	check(w.a._capture_delayed_skill_source().x < 0 and w.a._capture_delayed_skill_source(false).x > 0,"existing default alive gate preserved")
	w.a._damage_monsters_in_radius(Vector2.ZERO,125.0,99,w.scope.registry.get_handle(w.a),w.scope.get_instance_id())
	check(w.v[0].hits == [150],"existing default AoE alive gate preserved")
	cleanup(w)
	# Target removal/reuse remains current area-query behavior; no reserved target requirement.
	w = world(after)
	w.a.archmage_skill_config.ice_bolt.pillar_count = 1
	w.v[0].callback = func():w.v[1].queue_free()
	w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
	await create_timer(0.08).timeout
	check(w.v[0].hits.size() == 2 and w.a.effects.size() == 2,"queued next target safe; valid source keeps pillars")
	cleanup(w)
	w = world(after)
	w.a.archmage_skill_config.ice_bolt.pillar_count = 1
	reuse(w,w.v[0])
	w.a.resolve_archmage_ice_bolt_hit(null,Vector2.ZERO,false)
	await create_timer(0.08).timeout
	check(w.v[0].hits == [150,85],"fresh target life in current AoE still damaged")
	cleanup(w)
	print("Ice impact checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
