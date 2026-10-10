extends SceneTree
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
const SLIME := preload("res://src/monsters/slime.gd")
class Scope extends Node2D:
	var registry = REGISTRY.new()
	var hero
	var aura := 1.0
	func get_battle_entity_handle(n):return registry.get_handle(n)
	func resolve_battle_entity(h):return registry.resolve(h)
	func get_last_battle_entity_handle(n):return registry.get_last_handle(n)
	func get_transcendent_aura_modifier(_n,kind):return aura if kind == "incoming" else 1.0
	func recycle_projectile(p,_key):
		registry.retire_instance(p.get_instance_id())
		p.deactivate_for_pool()
class Visual extends Node:
	signal death_animation_finished
	var owner_actor
	func play_death():owner_actor.events.append("death")
class Legacy extends Node2D:
	var current_hp := 1000
	var hits: Array = []
	func take_damage(amount):
		hits.append(amount)
		current_hp -= amount
class Hero extends Node2D:
	var monsters: Array = []
	var hits := 0
	var kills := 0
	var on_hit: Callable
	func _get_monster_nodes_near(_pos,_radius):return monsters
	func notify_berserker_blood_art_hit():
		hits += 1
		if on_hit.is_valid():on_hit.call()
	func notify_berserker_skill_kill():kills += 1
var checks := 0
var failures := 0
var before
var after
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func world(script,hp := 60,shield := 0,damage := 100,aura := 1.0):
	var scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	scope.aura = aura
	var hero = Hero.new()
	scope.hero = hero
	scope.add_child(hero)
	scope.registry.activate(hero)
	var a = SLIME.new()
	scope.add_child(a)
	a.position = Vector2(100,0)
	a.current_hp = hp
	a.set_meta("support_shield_hp",shield)
	scope.registry.activate(a)
	var visual = Visual.new()
	visual.owner_actor = a
	a.add_child(visual)
	a.visual = visual
	a.died.connect(func():scope.registry.retire_instance(a.get_instance_id()))
	var legacy = Legacy.new()
	scope.add_child(legacy)
	legacy.position = Vector2(200,0)
	scope.registry.activate(legacy)
	hero.monsters = [a,legacy]
	var p = script.new()
	for name in ["Sprite","Tail"]:
		var v = AnimatedSprite2D.new()
		v.name = name
		p.add_child(v)
	scope.add_child(p)
	scope.registry.activate(p)
	p.setup("berserker_wave",Vector2.RIGHT,damage,700.0,700.0,{"hit_radius":64.0},hero)
	p.set_physics_process(false)
	return {"scope":scope,"hero":hero,"a":a,"legacy":legacy,"p":p}
func sweep(w):w.p._damage_berserker_wave_sweep(Vector2.ZERO,Vector2(400,0))
func cleanup(w):
	w.a.hit_callback = Callable()
	w.hero.on_hit = Callable()
	w.scope.free()
func run():
	before = load("res://tests/wave_projectile_before.gd")
	after = load("res://tests/wave_projectile_after.gd")
	for hp in [0,1,60,1000]:
		for shield in [0,10,100]:
			for damage in [1,25,100,2000]:
				for aura in [0.5,1.0,1.5]:
					var old = world(before,hp,shield,damage,aura)
					var fresh = world(after,hp,shield,damage,aura)
					var buffer_id = fresh.p._wave_damage_receipt.get_instance_id()
					sweep(old)
					sweep(fresh)
					check(old.a.current_hp == fresh.a.current_hp and old.a.events == fresh.a.events and old.a.get_meta("support_shield_hp") == fresh.a.get_meta("support_shield_hp"),"real slime normal damage/FX/shield")
					check(old.hero.hits == fresh.hero.hits and old.hero.kills == fresh.hero.kills and old.legacy.hits == fresh.legacy.hits,"normal hit/kill and legacy coexistence")
					sweep(fresh)
					check(fresh.hero.hits == 2 and fresh.p._wave_damage_receipt.get_instance_id() == buffer_id,"shot dedup/buffer reused")
					cleanup(old)
					cleanup(fresh)
	# Death callback resets target life before damage returns: original receipt still counts.
	var w = world(after)
	w.a.died.connect(func():
		w.scope.registry.activate(w.a)
		w.a.current_hp = 60
		w.a.dying = false
	)
	sweep(w)
	check(w.hero.kills == 1 and w.a.current_hp == 60,"actual original death credited despite target reuse")
	cleanup(w)
	# HP0 caused inside hit visual but death guard refuses: legacy inference falsely credits.
	w = world(after)
	w.a.hit_callback = func():w.a.dying = true
	sweep(w)
	check(w.hero.kills == 0 and w.a.current_hp == 0,"no kill without actual death start")
	cleanup(w)
	# The shared result is overwritten by nested damage: do not infer or repeat old damage.
	w = world(after)
	var other = SLIME.new()
	w.scope.add_child(other)
	other.current_hp = 100
	w.scope.registry.activate(other)
	other.visual = w.a.visual
	w.a.hit_callback = func():
		w.a.hit_callback = Callable()
		other.take_damage_with_result(5,w.p._wave_damage_receipt)
	sweep(w)
	check(w.hero.kills == 0 and w.hero.hits == 2 and other.current_hp == 95 and w.a.current_hp == 0,"unavailable old result not credited/retried")
	cleanup(w)
	# Copy killed before hit-heal callback overwrites buffer.
	w = world(after)
	w.hero.on_hit = func():w.p._wave_damage_receipt.begin(w.legacy,0)
	sweep(w)
	check(w.hero.kills == 1,"receipt result copied before notification callback")
	cleanup(w)
	for mode in ["source_reuse","new_shot"]:
		w = world(after)
		w.a.died.connect(func():
			if mode == "source_reuse":
				w.scope.registry.retire_instance(w.hero.get_instance_id())
				w.scope.registry.activate(w.hero)
			else:
				w.scope.registry.retire_instance(w.p.get_instance_id())
				w.scope.registry.activate(w.p)
				w.p.setup("ice_bolt",Vector2.RIGHT,1,10.0,100.0,{},w.hero)
				w.p.set_physics_process(false)
		)
		sweep(w)
		check(w.hero.hits == 0 and w.hero.kills == 0 and w.legacy.hits.is_empty(),"source/shot receipt callback cancels old work "+mode)
		cleanup(w)
	# A new pooled wave keeps the same buffer object, but begins a fresh receipt per hit.
	w = world(after,1000,0,1)
	var id = w.p._wave_damage_receipt.get_instance_id()
	for i in range(200):
		w.p.deactivate_for_pool()
		w.scope.registry.retire_instance(w.p.get_instance_id())
		w.scope.registry.activate(w.p)
		w.p.setup("berserker_wave",Vector2.RIGHT,1,700.0,700.0,{},w.hero)
		w.p.set_physics_process(false)
		sweep(w)
		check(w.p._wave_damage_receipt.get_instance_id() == id and w.p._wave_damage_receipt.requested_damage == 1,"200 pooled waves reuse result buffer")
	cleanup(w)
	print("Wave receipt checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
