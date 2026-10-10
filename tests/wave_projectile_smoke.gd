extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node2D:
	var registry = REGISTRY.new()
	var recycled := 0
	func get_battle_entity_handle(node: Node) -> Vector3i:return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node:return registry.resolve(handle)
	func get_last_battle_entity_handle(node: Node) -> Vector3i:return registry.get_last_handle(node)
	func recycle_projectile(node: Node,_key: String):
		recycled += 1
		registry.retire_instance(node.get_instance_id())
		node.deactivate_for_pool()
class Monster extends Node2D:
	var current_hp := 200
	var hits: Array = []
	var callback: Callable
	func take_damage(amount):
		hits.append(amount)
		current_hp -= amount
		if callback.is_valid():callback.call()
class Hero extends Node2D:
	var monsters: Array = []
	var hit_count := 0
	var kills := 0
	var on_hit: Callable
	var on_kill: Callable
	func _get_monster_nodes_near(_position,_radius) -> Array:return monsters
	func notify_berserker_blood_art_hit():
		hit_count += 1
		if on_hit.is_valid():on_hit.call()
	func notify_berserker_skill_kill():
		kills += 1
		if on_kill.is_valid():on_kill.call()
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
	for point in [Vector2(100,0),Vector2(200,50),Vector2(300,200),Vector2(0,0),Vector2(750,0)]:
		var m = Monster.new()
		m.position = point
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
func start(w,damage := 100):
	w.scope.registry.activate(w.p)
	w.p.setup("berserker_wave",Vector2.RIGHT,damage,700.0,700.0,{"hit_radius":64.0},w.hero)
	w.p.set_physics_process(false)
func reuse(w,node):
	w.scope.registry.retire_instance(node.get_instance_id())
	w.scope.registry.activate(node)
func snap(w) -> Array:
	var state = [w.p.active,w.p.skill_type,w.p.global_position,w.p.traveled,w.p.hit_ids.size(),w.hero.hit_count,w.hero.kills,w.scope.recycled]
	for m in w.hero.monsters:state.append([m.current_hp,m.hits.duplicate()])
	return state
func cleanup(w):
	for m in w.hero.monsters:
		if is_instance_valid(m):m.callback = Callable()
	w.hero.on_hit = Callable()
	w.hero.on_kill = Callable()
	w.scope.free()
func sweep(w):w.p._damage_berserker_wave_sweep(Vector2.ZERO,Vector2(400,0))
func run():
	before = load("res://tests/wave_projectile_before.gd")
	after = load("res://tests/wave_projectile_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	# Normal movement, swept collisions, per-shot dedup and notifications stay identical.
	for damage in [1,100,250]:
		var old = world(before)
		var fresh = world(after)
		start(old,damage)
		start(fresh,damage)
		check(snap(old) == snap(fresh),"normal setup")
		for frame in range(100):
			if old.p.active:old.p._physics_process(0.01)
			if fresh.p.active:fresh.p._physics_process(0.01)
			check(snap(old) == snap(fresh),"normal damage/trajectory/hit/kill/dedup")
		cleanup(old)
		cleanup(fresh)
	var w = world(after)
	start(w)
	sweep(w)
	sweep(w)
	check(w.hero.hit_count == 3 and w.hero.kills == 0,"capsule includes endpoints/inside only and hits once")
	check(w.hero.monsters[2].hits.is_empty() and w.hero.monsters[4].hits.is_empty(),"off-axis/beyond segment not hit")
	cleanup(w)
	for mode in ["source_reuse","epoch","queued","projectile_reuse"]:
		w = world(after)
		start(w)
		if mode == "source_reuse":reuse(w,w.hero)
		elif mode == "epoch":
			w.scope.registry.begin_session(2)
			w.scope.registry.activate(w.hero)
			w.scope.registry.activate(w.p)
		elif mode == "projectile_reuse":reuse(w,w.p)
		else:w.hero.queue_free()
		w.p._physics_process(0.1)
		check(not w.p.active and w.target.hits.is_empty() and w.hero.hit_count == 0,"stale life cancels "+mode)
		cleanup(w)
	w = world(before)
	start(w)
	reuse(w,w.hero)
	sweep(w)
	check(w.target.hits == [100] and w.hero.hit_count > 0,"baseline source reuse bug reproduced")
	cleanup(w)
	for callback in ["damage","hit","kill"]:
		for i in range(100):
			w = world(after)
			start(w,250)
			var change = func():
				reuse(w,w.p)
				w.p.setup("ice_bolt",Vector2.LEFT,70,20.0,1.0,{},w.hero)
				w.p.set_physics_process(false)
				w.p.traveled = 77.0
			if callback == "damage":w.target.callback = change
			elif callback == "hit":w.hero.on_hit = change
			else:w.hero.on_kill = change
			w.p._physics_process(0.5)
			check(w.p.active and w.p.skill_type == "ice_bolt" and w.p.traveled == 77.0 and w.hero.monsters[1].hits.is_empty(),"old callback protects new shot "+callback)
			check(w.hero.hit_count == (0 if callback == "damage" else 1) and w.hero.kills == (1 if callback == "kill" else 0),"callback ordering old work stops "+callback)
			cleanup(w)
	# Normal death retires identity but still credits the original kill.
	w = world(after)
	start(w,250)
	w.target.callback = func():w.scope.registry.retire_instance(w.target.get_instance_id())
	sweep(w)
	check(w.hero.kills == 3 and w.hero.hit_count == 3,"retired lethal victim still credits kill")
	cleanup(w)
	# Damage callback reuses the victim at HP0: do not credit another life's death.
	w = world(after)
	start(w,250)
	w.target.callback = func():reuse(w,w.target)
	sweep(w)
	check(w.hero.kills == 2 and w.hero.hit_count == 3,"new victim generation cannot credit old kill")
	cleanup(w)
	# Hit callback reuse after real damage cannot change already observed kill result.
	w = world(after)
	start(w,250)
	w.hero.on_hit = func():
		reuse(w,w.target)
		w.target.current_hp = 500
	sweep(w)
	check(w.hero.kills == 3,"snapshot keeps real kill despite hit-heal target reuse")
	cleanup(w)
	w = world(after)
	start(w)
	w.hero.on_hit = func():w.target.current_hp = 0
	sweep(w)
	check(w.hero.kills == 0,"hit callback cannot invent kill from nonlethal damage")
	cleanup(w)
	# Source reuse inside callbacks must stop kill/heal and remaining victims.
	for callback in ["damage","hit","kill"]:
		w = world(after)
		start(w,250)
		var change = func():reuse(w,w.hero)
		if callback == "damage":w.target.callback = change
		elif callback == "hit":w.hero.on_hit = change
		else:w.hero.on_kill = change
		w.p._physics_process(0.5)
		check(not w.p.active and w.hero.monsters[1].hits.is_empty(),"source callback cancels old wave "+callback)
		check(w.hero.hit_count == (0 if callback == "damage" else 1) and w.hero.kills == (1 if callback == "kill" else 0),"source callback stops old credit "+callback)
		cleanup(w)
	# Fresh AoE victims and pre-dead targets follow existing hit/kill rules.
	w = world(after)
	start(w)
	reuse(w,w.target)
	w.hero.monsters[1].current_hp = 0
	sweep(w)
	check(w.target.hits == [100] and w.hero.hit_count == 3 and w.hero.kills == 0,"fresh target/current dead no spurious kill")
	cleanup(w)
	w = world(after)
	w.p.setup("berserker_wave",Vector2.RIGHT,100,700.0,700.0,{},w.hero)
	check(not w.p.active,"unregistered projectile fail closed")
	cleanup(w)
	# Queued lethal victims remain safe to inspect and still credit kills.
	for mode in ["queued"]:
		w = world(after)
		start(w,250)
		var victim = w.target
		victim.callback = func():
			victim.queue_free()
		sweep(w)
		check(w.hero.kills == 3 and w.hero.hit_count == 3,"deleted lethal target credits old hit "+mode)
		cleanup(w)
	# Missing source identity and foreign parent are rejected before damage.
	w = world(after)
	w.scope.registry.retire_instance(w.hero.get_instance_id())
	start(w)
	check(not w.p.active and w.target.hits.is_empty(),"unregistered source fail closed")
	cleanup(w)
	w = world(after)
	start(w)
	var foreign = Scope.new()
	root.add_child(foreign)
	foreign.registry.begin_session(3)
	w.p.reparent(foreign)
	foreign.registry.activate(w.p)
	foreign.registry.activate(w.hero)
	w.p._physics_process(0.1)
	check(not w.p.active and w.target.hits.is_empty(),"changed scope cancels wave")
	foreign.free()
	cleanup(w)
	# Exact edge and zero-length sweep retain original capsule behavior.
	w = world(after)
	start(w)
	w.target.position = Vector2(0,64)
	w.p._damage_berserker_wave_sweep(Vector2.ZERO,Vector2.ZERO)
	check(w.target.hits == [100] and w.hero.hit_count == 2,"zero length capsule includes radius edge")
	cleanup(w)
	# Reused then retired victim at HP0 must never count as the old kill.
	w = world(after)
	start(w,250)
	w.target.callback = func():
		reuse(w,w.target)
		w.scope.registry.retire_instance(w.target.get_instance_id())
	sweep(w)
	check(w.hero.kills == 2 and w.hero.hit_count == 3,"reuse then retire is a different victim even at HP0")
	cleanup(w)
	# Unrelated slot reuse must not discard an actual original kill.
	w = world(after)
	start(w,250)
	var replacement = Monster.new()
	w.scope.add_child(replacement)
	w.target.callback = func():
		w.scope.registry.retire_instance(w.target.get_instance_id())
		w.scope.registry.activate(replacement)
	sweep(w)
	check(w.hero.kills == 3,"last life is per-node despite another node reusing its slot")
	cleanup(w)
	print("Wave projectile checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
