extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
class Scope extends Node2D:
	var registry = REGISTRY.new()
	var recycled := 0
	func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
	func recycle_projectile(node: Node, _key: String):
		recycled += 1
		registry.retire_instance(node.get_instance_id())
		node.deactivate_for_pool()
class Monster extends Node2D:
	var current_hp := 100000
	var hits: Array[int] = []
	var on_hit: Callable
	func take_damage(amount: int):
		hits.append(amount)
		current_hp -= amount
		if on_hit.is_valid(): on_hit.call()
class Hero extends Node2D:
	var monsters: Array = []
	var finished := 0
	var audio := 0
	var gauge := 0.0
	var blood_hits := 0
	var kills := 0
	var on_finished: Callable
	var on_audio: Callable
	func _get_monster_nodes_cached() -> Array: return monsters
	func _get_monster_nodes_near(_o, _r) -> Array: return monsters
	func _get_monster_nodes_in_rect(_r) -> Array: return monsters
	func notify_archmage_chain_dagger_finished():
		finished += 1
		if on_finished.is_valid(): on_finished.call()
	func play_archmage_chain_hit_audio():
		audio += 1
		if on_audio.is_valid(): on_audio.call()
	func restore_archmage_gauge(amount): gauge += amount
	func notify_berserker_blood_art_hit(): blood_hits += 1
	func notify_berserker_skill_kill(): kills += 1
	func resolve_archmage_ice_bolt_hit(_m, _p, _e): pass
var before_script
var after_script
var checks := 0
var failures := 0
func check(ok: bool, msg: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(msg)
func make_world(script) -> Dictionary:
	var scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	var hero = Hero.new()
	scope.add_child(hero)
	scope.registry.activate(hero)
	for i in range(3):
		var m = Monster.new()
		m.position = Vector2(100 + i * 100, 0)
		m.add_to_group("monsters")
		scope.add_child(m)
		scope.registry.activate(m)
		hero.monsters.append(m)
	var projectile = script.new()
	for n in ["Sprite", "Tail"]:
		var sprite = AnimatedSprite2D.new()
		sprite.name = n
		projectile.add_child(sprite)
	scope.add_child(projectile)
	return {"scope": scope, "hero":hero,"p":projectile,"target":hero.monsters[0]}
func start(w: Dictionary, kind := "chain_dagger", cfg: Dictionary = {}, empowered := false):
	w.scope.registry.activate(w.p)
	w.p.setup(kind,Vector2.RIGHT,100,700.0,900.0,cfg,w.hero,empowered,w.target if kind == "chain_dagger" else null)
	w.p.set_physics_process(false) # Manual physics steps; timers stay real.
func snapshot(w: Dictionary) -> Array:
	var p = w.p
	return [p.active,p.skill_type,p.global_position,p.direction,p.traveled,p.bounce_count,
		p.hit_ids.size(),p.storm_return_hit_ids.size(),p.storm_returning,
		w.hero.finished,w.hero.audio,w.hero.gauge,w.hero.blood_hits,w.hero.kills,
		w.hero.monsters[0].hits.duplicate(),w.hero.monsters[1].hits.duplicate(),w.hero.monsters[2].hits.duplicate(),
		w.scope.recycled]
func _initialize(): call_deferred("run")
func run():
	before_script = load("res://tests/chain_projectile_before.gd")
	after_script = load("res://tests/chain_projectile_after.gd")
	if before_script == null or after_script == null or not before_script.can_instantiate() or not after_script.can_instantiate():
		quit(1)
		return
	# Real setup/physics/collision/finish for unaffected types and normal chains.
	for kind in ["ice_bolt","storm","berserker_wave","chain_dagger"]:
		for empowered in [false,true]:
			var old = make_world(before_script)
			var new = make_world(after_script)
			var cfg = {"chain_tick_count":1,"max_bounces":2}
			start(old,kind,cfg,empowered)
			start(new,kind,cfg,empowered)
			check(snapshot(old) == snapshot(new),"normal setup "+kind)
			for frame in range(40):
				if old.p.active: old.p._physics_process(0.01)
				if new.p.active: new.p._physics_process(0.01)
				check(snapshot(old) == snapshot(new),"normal motion/damage "+kind)
			if kind in ["ice_bolt","chain_dagger"]:
				old.p._on_body_entered(old.target)
				new.p._on_body_entered(new.target)
				check(snapshot(old) == snapshot(new),"normal impact "+kind)
				if kind == "chain_dagger":
					old.p._on_body_entered(old.hero.monsters[1])
					new.p._on_body_entered(new.hero.monsters[1])
					check(snapshot(old) == snapshot(new),"normal bounce + link first tick")
			old.scope.queue_free();new.scope.queue_free()
	# Target reused while homing, including collision arriving before physics.
	var w = make_world(after_script)
	var target_ref = w.p._chain_target_reference
	for i in range(200):
		start(w)
		w.scope.registry.retire_instance(w.target.get_instance_id())
		w.scope.registry.activate(w.target)
		if i % 2 == 0: w.p._physics_process(0.01)
		else: w.p._on_body_entered(w.target)
		check(w.target.hits.is_empty() and not w.p.active,"retired/reused homing life blocked")
		check(w.p._chain_target_reference == target_ref,"target reference object reused")
	check(w.hero.finished == 200 and w.scope.recycled == 200,"one notify/recycle per rejected shot")
	# A fresh interceptor remains hittable; homing is not an exclusive collision filter.
	start(w)
	w.p._on_body_entered(w.hero.monsters[1])
	check(w.hero.monsters[1].hits == [100],"fresh interceptor keeps original collision rules")
	check(w.p.current_target == w.target,"bounce picks nearest unhit")
	w.scope.registry.retire_instance(w.target.get_instance_id())
	w.scope.registry.activate(w.target)
	w.p._on_body_entered(w.target)
	check(w.target.hits.is_empty(),"bounce reserves new target life")
	# Existing concealment drops homing and continues straight.
	start(w)
	w.target.set_meta("detectable",false)
	w.p._physics_process(0.01)
	check(w.p.active and w.p.current_target == null,"concealment keeps direction-only flight")
	w.target.set_meta("detectable",true)
	w.p._finish()
	# Old await must not hit through a new pooled projectile/source/config.
	for kind in ["chain_dagger","ice_bolt"]:
		start(w,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
		w.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
		w.p._finish_after_chain_ticks()
		var count: int = w.target.hits.size()
		var finished: int = w.hero.finished
		w.scope.recycle_projectile(w.p,"archmage_chain_dagger_projectile")
		start(w,kind,{"chain_tick_count":4,"chain_tick_interval":0.01})
		await create_timer(0.15).timeout
		check(w.target.hits.size() == count,"old timer damage blocked after reuse "+kind)
		check(w.p.active and w.hero.finished == finished,"old finish timer cannot close new shot "+kind)
		check(w.p.monitoring,"old deferred monitoring cannot disable new shot "+kind)
		w.p._finish()
	# Valid segment ticks continue querying fresh lives each tick.
	var old = make_world(before_script)
	var new = make_world(after_script)
	start(old,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
	start(new,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
	old.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	new.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	new.scope.registry.retire_instance(new.target.get_instance_id())
	new.scope.registry.activate(new.target)
	await create_timer(0.15).timeout
	check(old.target.hits == [11,11,11,11] and old.target.hits == new.target.hits,"fresh segment damage + count unchanged")
	old.scope.queue_free();new.scope.queue_free()
	# Real finish timers retain timing/count for a normal life.
	old = make_world(before_script)
	new = make_world(after_script)
	var normal_cfg = {"chain_tick_count":4,"chain_tick_interval":0.01,"chain_duration_bonus":0.02}
	start(old,"chain_dagger",normal_cfg,true)
	start(new,"chain_dagger",normal_cfg,true)
	old.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	new.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	old.p._finish_after_chain_ticks()
	new.p._finish_after_chain_ticks()
	await create_timer(0.2).timeout
	check(snapshot(old) == snapshot(new) and new.hero.finished == 1,"valid async finish and bonus ticks preserved")
	check(new.target.hits == [17,17,17,17,17,17],"empowered tick damage/count")
	old.scope.queue_free();new.scope.queue_free()
	# Confirm the old implementation actually exhibited the pool timer regression.
	old = make_world(before_script)
	start(old,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
	old.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	old.p._finish_after_chain_ticks()
	var before_count: int = old.target.hits.size()
	old.scope.recycle_projectile(old.p,"archmage_chain_dagger_projectile")
	start(old,"ice_bolt")
	await create_timer(0.15).timeout
	check(old.target.hits.size() > before_count and not old.p.active,"baseline reproduces old timer damaging/closing reused shot")
	old.scope.queue_free()
	# A source life invalidation ends delayed damage and never notifies a new source.
	start(w,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
	w.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	w.p._finish_after_chain_ticks()
	var count: int = w.target.hits.size()
	var finished: int = w.hero.finished
	w.scope.registry.retire_instance(w.hero.get_instance_id())
	w.scope.registry.activate(w.hero)
	await create_timer(0.15).timeout
	check(w.target.hits.size() == count,"source lifetime blocks delayed ticks")
	check(w.hero.finished == finished and not w.p.active,"source invalid cleanup without new-life notification")
	var gone_source = make_world(after_script)
	start(gone_source,"chain_dagger",{"chain_tick_count":4,"chain_tick_interval":0.01})
	gone_source.p._apply_chain_current_ticks(Vector2.ZERO,Vector2(400,0))
	gone_source.p._finish_after_chain_ticks()
	var gone_count: int = gone_source.target.hits.size()
	gone_source.hero.queue_free()
	await create_timer(0.15).timeout
	check(gone_source.target.hits.size() == gone_count and not gone_source.p.active,"deleted source stops ticks and cleans up")
	gone_source.scope.queue_free()
	# Damage callback reuses projectile; old handler must stop before bounce mutation.
	start(w)
	w.target.on_hit = func():
		w.scope.recycle_projectile(w.p,"archmage_chain_dagger_projectile")
		start(w,"ice_bolt")
	w.p._on_body_entered(w.target)
	check(w.p.active and w.p.skill_type == "ice_bolt" and w.p.bounce_count == 0,"reentrant hit cannot mutate reused projectile")
	w.target.on_hit = Callable()
	w.p._finish()
	var freed = make_world(after_script)
	start(freed)
	freed.hero.on_audio = func():
		freed.scope.registry.retire_instance(freed.target.get_instance_id())
		freed.hero.monsters.erase(freed.target)
		freed.target.free()
	freed.p._on_body_entered(freed.target)
	check(freed.p.active and freed.p.bounce_count == 1 and freed.p.current_target == freed.hero.monsters[0],"freed victim does not break bounce origin")
	freed.scope.queue_free()
	# Missing projectile identity still settles a valid source's active count.
	var missing = make_world(after_script)
	missing.p.setup("chain_dagger",Vector2.RIGHT,100,700.0,900.0,{},missing.hero,false,missing.target)
	check(not missing.p.active and missing.hero.finished == 1,"unregistered projectile fails closed and notifies live source")
	missing.scope.queue_free()
	var missing_target = make_world(after_script)
	missing_target.scope.registry.retire_instance(missing_target.target.get_instance_id())
	start(missing_target)
	check(not missing_target.p.active and missing_target.hero.finished == 1 and missing_target.target.hits.is_empty(),"unregistered target cancels and settles valid source")
	missing_target.scope.queue_free()
	# Finish callback cannot duplicate notification or recycle a newly setup shot.
	start(w)
	finished = w.hero.finished
	var recycled: int = w.scope.recycled
	w.hero.on_finished = func():
		w.p._finish()
		w.scope.registry.retire_instance(w.p.get_instance_id())
		start(w,"ice_bolt")
	w.p._finish()
	check(w.hero.finished == finished+1,"nested finish notifies once")
	check(w.p.active and w.p.skill_type == "ice_bolt" and w.scope.recycled == recycled,"finish callback new shot preserved")
	w.hero.on_finished = Callable()
	# New battle epoch: no old source feedback or homing hit.
	start(w)
	finished = w.hero.finished
	count = w.target.hits.size()
	w.scope.registry.begin_session(2)
	for node in [w.hero,w.p,w.target]: w.scope.registry.activate(node)
	w.p._on_body_entered(w.target)
	check(w.target.hits.size() == count and w.hero.finished == finished and not w.p.active,"session boundary blocks damage and notification")
	w.scope.queue_free()
	await process_frame
	print("chain_projectile_lifetime_smoke: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
