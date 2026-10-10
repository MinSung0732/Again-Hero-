extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node2D:
	var registry = REGISTRY.new()
	var recycled := 0
	func get_battle_entity_handle(node: Node) -> Vector3i:return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node:return registry.resolve(handle)
	func recycle_projectile(node: Node,_key: String):
		recycled += 1
		registry.retire_instance(node.get_instance_id())
		node.deactivate_for_pool()
class Monster extends Node2D:
	var hits: Array = []
	var callback: Callable
	func take_damage(amount):
		hits.append(amount)
		if callback.is_valid():callback.call()
class Hero extends Node2D:
	var monsters: Array = []
	var impacts: Array = []
	var gauge := 0.0
	var callback: Callable
	var on_gauge: Callable
	func _get_monster_nodes_near(_position,_radius) -> Array:return monsters
	func _get_monster_nodes_cached() -> Array:return monsters
	func _get_monster_nodes_in_rect(_r) -> Array:return monsters
	func resolve_archmage_ice_bolt_hit(node: Node2D,position: Vector2,empowered: bool):
		impacts.append([node,position,empowered])
		if callback.is_valid():callback.call()
	func restore_archmage_gauge(amount):
		gauge += amount
		if on_gauge.is_valid():on_gauge.call()
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
	var hero = Hero.new()
	scope.add_child(hero)
	scope.registry.activate(hero)
	for i in range(3):
		var m = Monster.new()
		m.position = Vector2(100+i*100,0)
		m.add_to_group("monsters")
		scope.add_child(m)
		scope.registry.activate(m)
		hero.monsters.append(m)
	var p = script.new()
	for name in ["Sprite","Tail"]:
		var sprite = AnimatedSprite2D.new()
		sprite.name = name
		p.add_child(sprite)
	scope.add_child(p)
	return {"scope":scope,"hero":hero,"p":p,"target":hero.monsters[0]}
func start(w,kind: String,empowered := false):
	w.scope.registry.activate(w.p)
	w.p.setup(kind,Vector2.RIGHT,100,700.0,350.0,{"hit_radius":1000.0},w.hero,empowered)
	w.p.set_physics_process(false)
func recycle(w,node):
	w.scope.registry.retire_instance(node.get_instance_id())
	w.scope.registry.activate(node)
func snap(w) -> Array:
	return [w.p.active,w.p.skill_type,w.p.global_position,w.p.direction,w.p.traveled,w.p.storm_returning,w.p.hit_ids.size(),w.p.storm_return_hit_ids.size(),w.hero.gauge,w.scope.recycled,w.target.hits.duplicate(),w.hero.monsters[1].hits.duplicate(),w.hero.monsters[2].hits.duplicate()]
func run():
	before = load("res://tests/elemental_projectile_before.gd")
	after = load("res://tests/elemental_projectile_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	for kind in ["ice_bolt","storm"]:
		for empowered in [false,true]:
			var old = world(before)
			var fresh = world(after)
			start(old,kind,empowered)
			start(fresh,kind,empowered)
			check(snap(old) == snap(fresh),"normal setup "+kind)
			for frame in range(100):
				if old.p.active:old.p._physics_process(0.01)
				if fresh.p.active:fresh.p._physics_process(0.01)
				check(snap(old) == snap(fresh),"normal trajectory/damage/dedup/gauge/return "+kind)
			old.scope.free()
			fresh.scope.free()
	# Initial target does not reserve straight shots: an interceptor remains valid.
	var w = world(after)
	start(w,"ice_bolt")
	w.p._on_body_entered(w.hero.monsters[1])
	check(w.hero.monsters[1].hits == [100] and w.hero.impacts.size() == 1,"ice interceptor receives damage and impact")
	w.scope.free()
	for kind in ["ice_bolt","storm"]:
		for mode in ["reuse_source","epoch","queued_source"]:
			w = world(after)
			start(w,kind)
			if mode == "reuse_source":recycle(w,w.hero)
			elif mode == "epoch":
				w.scope.registry.begin_session(2)
				w.scope.registry.activate(w.hero)
				w.scope.registry.activate(w.p)
			else:w.hero.queue_free()
			w.p._physics_process(0.01)
			check(w.target.hits.is_empty() and not w.p.active,"invalid source cancels movement/damage "+kind+mode)
			w.scope.free()
	# Baseline accepts a reused source for both collision and storm area damage.
	for kind in ["ice_bolt","storm"]:
		w = world(before)
		start(w,kind)
		recycle(w,w.hero)
		if kind == "ice_bolt":w.p._on_body_entered(w.target)
		else:w.p._damage_storm_area(false)
		check(not w.target.hits.is_empty(),"baseline stale source reproduced "+kind)
		w.scope.free()
	# Ice damage callback reconfigures projectile: do not impact or finish new shot.
	for i in range(200):
		w = world(after)
		start(w,"ice_bolt")
		w.target.callback = func():
			w.scope.registry.retire_instance(w.p.get_instance_id())
			w.p.deactivate_for_pool()
			start(w,"storm")
		w.p._on_body_entered(w.target)
		check(w.p.active and w.p.skill_type == "storm" and w.hero.impacts.is_empty(),"200 old ice callbacks preserve reused shot")
		w.target.callback = Callable()
		w.scope.free()
	# Ice impact callback can also reconfigure the same projectile.
	w = world(after)
	start(w,"ice_bolt")
	w.hero.callback = func():start(w,"storm")
	w.p._on_body_entered(w.target)
	check(w.p.active and w.p.skill_type == "storm", "impact callback new shot is not finished")
	w.hero.callback = Callable()
	w.scope.free()
	# Queued/recycled victims do not receive status; valid source gets lethal-hit gauge.
	for mode in ["recycle","queued"]:
		w = world(after)
		start(w,"storm")
		w.target.callback = func():
			if mode == "recycle":recycle(w,w.target)
			else:w.target.queue_free()
		w.p._damage_storm_area(false)
		check(not w.target.has_meta("archmage_root_until"),"storm cannot root changed victim: "+mode)
		check(w.hero.gauge == 12.0,"outward per-hit gauge preserved on changed/lethal victim")
		w.target.callback = Callable()
		w.scope.free()
	# Ice follow-up keeps hit origin and runs with null target when target no longer lives.
	w = world(after)
	start(w,"ice_bolt")
	w.p.position = Vector2(60,10)
	w.target.callback = func():w.target.queue_free()
	w.p._on_body_entered(w.target)
	check(w.hero.impacts.size() == 1 and w.hero.impacts[0][0] == null and w.hero.impacts[0][1] == Vector2(60,10),"ice lethal follow-up uses captured position/null target")
	w.target.callback = Callable()
	w.scope.free()
	# Storm callbacks must not change the reused shot's return flag/traveled state.
	w = world(after)
	start(w,"storm")
	w.target.callback = func():
		start(w,"ice_bolt")
		w.p.traveled = 88.0
	w.p._physics_process(1.0)
	check(w.p.active and w.p.skill_type == "ice_bolt" and w.p.traveled == 88.0 and not w.p.storm_returning,"storm physics does not overwrite new shot after damage")
	check(w.hero.gauge == 0.0 and w.hero.monsters[1].hits.is_empty(),"old storm stops root/gauge/remaining damage after callback")
	w.target.callback = Callable()
	w.scope.free()
	w = world(after)
	start(w,"storm")
	w.hero.on_gauge = func():start(w,"ice_bolt")
	w.p._damage_storm_area(false)
	check(w.hero.gauge == 4.0 and w.hero.monsters[1].hits.is_empty() and w.p.skill_type == "ice_bolt", "gauge callback reuse stops remaining storm hits")
	w.hero.on_gauge = Callable()
	w.scope.free()
	# Fresh AoE victims remain eligible, and missing identities fail closed.
	w = world(after)
	start(w,"storm")
	recycle(w,w.target)
	w.p._damage_storm_area(false)
	check(w.target.hits == [100] and w.target.has_meta("archmage_root_until"),"fresh AoE target life remains hittable")
	w.scope.free()
	for kind in ["ice_bolt","storm"]:
		w = world(after)
		w.p.setup(kind,Vector2.RIGHT,100,700.0,350.0,{},w.hero)
		check(not w.p.active,"unregistered projectile rejected "+kind)
		w.scope.free()
	# Callback source retirement cancels effects/gauge and stops remaining victims.
	for kind in ["ice_bolt","storm"]:
		w = world(after)
		start(w,kind)
		w.target.callback = func():recycle(w,w.hero)
		if kind == "ice_bolt":w.p._on_body_entered(w.target)
		else:
			w.p._damage_storm_area(false)
			w.p._physics_process(0.01)
		check(w.target.hits == [100] and w.hero.gauge == 0.0 and w.hero.impacts.is_empty() and not w.target.has_meta("archmage_root_until"), "source callback stops old follow-up "+kind)
		check(not w.p.active and w.hero.monsters[1].hits.is_empty(),"source callback old shot cleanup "+kind)
		w.target.callback = Callable()
		w.scope.free()
	# Each leg hits once, return multiplier and empowerment stay exact.
	for empowered in [false,true]:
		w = world(after)
		start(w,"storm",empowered)
		w.p._damage_storm_area(false)
		w.p._damage_storm_area(false)
		w.p._damage_storm_area(true)
		w.p._damage_storm_area(true)
		check(w.target.hits == ([150,75] if empowered else [100,50]),"storm per-leg damage/dedup/empowerment")
		check(w.hero.gauge == 12.0 and w.target.get_meta("archmage_root_until") > Time.get_ticks_msec(), "only outward credits gauge; valid root")
		w.scope.free()
	# A callback on the return leg also cannot finish/rewrite the new shot.
	w = world(after)
	start(w,"storm")
	w.p.position = Vector2(100,0)
	w.p.storm_returning = true
	w.target.callback = func():start(w,"ice_bolt")
	w.p._physics_process(0.01)
	check(w.p.active and w.p.skill_type == "ice_bolt" and w.p.traveled == 0.0 and w.hero.gauge == 0.0,"return leg callback protects new shot")
	w.target.callback = Callable()
	w.scope.free()
	print("Elemental projectile checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
