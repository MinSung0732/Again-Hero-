extends SceneTree
const SCOPE := preload("res://tests/scope.gd")
class Victim extends Node2D:
	var current_hp := 100000
	var hits: Array = []
	var callback: Callable
	func take_damage(amount):
		hits.append(amount)
		if callback.is_valid(): callback.call()
var scope
var epoch := 1
var checks := 0
var failures := 0
var config := {"charge_duration":0.11,"charge_tick_interval":0.05,"charge_radius":1000.0,"thrust_half_width":1000.0}
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script,victim):
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	a.target = victim
	a.nearest = victim
	a.candidates = [victim]
	return a
func recycle(a):
	scope.registry.retire_instance(a.get_instance_id())
	scope.registry.activate(a)
func run():
	var before = load("res://tests/fire_before.gd")
	var after = load("res://tests/fire_after.gd")
	if before == null or after == null or not before.can_instantiate() or not after.can_instantiate():
		quit(1)
		return
	scope = SCOPE.new()
	root.add_child(scope)
	scope.registry.begin_session(epoch)
	var victim = Victim.new()
	victim.position = Vector2(150,0)
	scope.add_child(victim)
	scope.registry.activate(victim)
	var other = Victim.new()
	other.position = Vector2(170,0)
	scope.add_child(other)
	scope.registry.activate(other)
	for empowered in [false,true]:
		var old = actor(before,victim)
		var fresh = actor(after,victim)
		victim.hits.clear()
		await old._cast_archmage_combustion(config,empowered)
		var hits = victim.hits.duplicate()
		victim.hits.clear()
		await fresh._cast_archmage_combustion(config,empowered)
		check(old.effects == fresh.effects and old.audio == fresh.audio,"normal full FX/audio before-after")
		check(hits == victim.hits and victim.hits.size() == 4,"normal 3 charge ticks plus release")
		check(fresh.archmage_casting_sequence_count == 0,"normal cleanup")
		old.free()
		fresh.free()
	for mode in ["recycle","epoch","dead","reparent"]:
		var a = actor(after,victim)
		victim.hits.clear()
		a._cast_archmage_combustion(config,false)
		var fx = a.charge_fx
		if mode == "recycle": recycle(a)
		elif mode == "epoch":
			epoch += 1
			scope.registry.begin_session(epoch)
			scope.registry.activate(a)
		elif mode == "dead": a.current_hp = 0
		else:
			scope.remove_child(a)
			root.add_child(a)
		if mode != "dead": a.archmage_casting_sequence_count = 7
		await create_timer(0.25).timeout
		check(victim.hits.size() == 1 and a.effects.size() == 1 and a.audio == ["charge"],"no stale ticks/release: "+mode)
		check(a.archmage_casting_sequence_count == (0 if mode == "dead" else 7),"counter belongs to same life: "+mode)
		check(not fx.visible and scope.transient_fx_pools.get("archmage_cast_fx",[]).has(fx),"old FX cleaned through original scope: "+mode)
		a.free()
	# Baseline continues after a reused source despite positive HP/tree.
	var old = actor(before,victim)
	victim.hits.clear()
	old._cast_archmage_combustion(config,false)
	recycle(old)
	await create_timer(0.30).timeout
	check(victim.hits.size() == 4 and old.audio == ["charge","release"],"baseline stale source reproduced")
	old.free()
	# Damage callbacks may invalidate the source during charge or corridor.
	for release in [false,true]:
		var a = actor(after,victim)
		a.candidates = [victim,other]
		victim.hits.clear()
		other.hits.clear()
		victim.callback = func():
			if not release or victim.hits.back() == 160: recycle(a)
		await a._cast_archmage_combustion(config,false)
		check(other.hits.size() == (3 if release else 0),"callback stops later victims in charge/corridor")
		check(a.audio == ["charge"] and a._combat_monster_scratch.is_empty(),"cancel stale release audio and clear scratch")
		victim.callback = Callable()
		a.free()
	# Reused playback must remain active when old charge completes.
	var a = actor(after,victim)
	a._cast_archmage_combustion(config,false)
	var fx = a.charge_fx
	scope.recycle_transient_fx(fx,"archmage_cast_fx")
	var replacement = a._spawn_archmage_fx("test","replacement",1,1,1.0,true,Vector2.ZERO,Vector2.ONE)
	check(replacement == fx,"actual pool reuses same sprite")
	var revision = int(fx.get_meta("archmage_cast_revision"))
	await create_timer(0.30).timeout
	check(fx.visible and int(fx.get_meta("archmage_cast_revision")) == revision,"old charge cleanup preserves replacement playback")
	check(not scope.transient_fx_pools.get("archmage_cast_fx",[]).has(fx),"replacement not returned twice")
	for i in range(200):
		var old_revision = int(fx.get_meta("archmage_cast_revision"))
		scope.recycle_transient_fx(fx,"archmage_cast_fx")
		fx = a._spawn_archmage_fx("test","replacement",1,1,1.0,true,Vector2.ZERO,Vector2.ONE)
		a._recycle_archmage_fx_if_current(fx,old_revision,scope.get_instance_id())
		check(fx.visible and not scope.transient_fx_pools.get("archmage_cast_fx",[]).has(fx),"200 reuse revisions reject previous cleanup")
	a.free()
	# Current AoE candidates are acquired each tick; reservations do not freeze targets.
	a = actor(after,victim)
	a.candidates = []
	a._cast_archmage_combustion(config,false)
	other.hits.clear()
	a.candidates = [other]
	await create_timer(0.30).timeout
	check(other.hits.size() == 3,"new candidates hit by remaining charge ticks and release")
	a.free()
	# Deleted entries are skipped before typed policy calls.
	var doomed = Victim.new()
	doomed.position = Vector2(170,0)
	scope.add_child(doomed)
	var doomed_id = doomed.get_instance_id()
	a = actor(after,victim)
	a.candidates = [victim,doomed]
	victim.callback = func():
		var live = instance_from_id(doomed_id)
		if is_instance_valid(live): live.free()
	await a._cast_archmage_combustion(config,false)
	check(a.archmage_casting_sequence_count == 0,"freed candidates safe in charge and corridor")
	victim.callback = Callable()
	a.free()
	# Deleted FX during the wait must not enter a typed helper with a freed Node.
	a = actor(after,victim)
	a._cast_archmage_combustion(config,false)
	a.charge_fx.queue_free()
	await create_timer(0.30).timeout
	check(a.effects.size() == 2 and a.archmage_casting_sequence_count == 0,"deleted charging FX does not block normal release")
	a.free()
	# Missing textures remain cosmetic: valid source still deals normal damage.
	a = actor(after,victim)
	a.test_texture = null
	victim.hits.clear()
	await a._cast_archmage_combustion(config,false)
	check(victim.hits.size() == 4 and a.charge_fx == null,"missing FX resources preserve combat")
	check(a.archmage_casting_sequence_count == 0,"missing FX cleanup")
	a.free()
	# Per-coroutine scalar source/playback reservations survive simultaneous casts.
	a = actor(after,victim)
	victim.hits.clear()
	a._cast_archmage_combustion(config,false)
	a._cast_archmage_combustion(config,true)
	await create_timer(0.30).timeout
	check(victim.hits.size() == 8 and a.effects.size() == 4,"simultaneous casts preserve independent ticks/releases")
	check(a.archmage_casting_sequence_count == 0,"simultaneous casting counter cleanup")
	a.free()
	# Missing source identity fails before audio/FX/counter changes.
	a = actor(after,victim)
	scope.registry.retire_instance(a.get_instance_id())
	await a._cast_archmage_combustion(config,false)
	check(a.effects.is_empty() and a.audio.is_empty() and a.archmage_casting_sequence_count == 0,"unregistered source fails closed")
	a.free()
	await create_timer(0.40).timeout
	scope.free()
	print("Combustion lifetime checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
