extends SceneTree
const RESULT := preload("res://src/systems/battle_damage_receipt.gd")
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
const POPUPS := preload("res://tests/popups.gd")
class Scope extends Node:
	var registry = REGISTRY.new()
	var hero = Node.new()
	var aura := 1.0
	func get_battle_entity_handle(n):return registry.get_handle(n)
	func resolve_battle_entity(handle):return registry.resolve(handle)
	func get_transcendent_aura_modifier(_n,kind):return aura if kind == "incoming" else 1.0
class Visual extends Node:
	signal death_animation_finished
	var owner_actor
	func play_death():owner_actor.events.append("death")
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
func actor(script,hp := 60,shield := 0,aura := 1.0):
	var scope = Scope.new()
	root.add_child(scope)
	scope.add_child(scope.hero)
	scope.aura = aura
	scope.registry.begin_session(1)
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	a.current_hp = hp
	a.set_meta("support_shield_hp",shield)
	var visual = Visual.new()
	visual.owner_actor = a
	a.add_child(visual)
	a.visual = visual
	return a
func cleanup(a):
	a.hit_callback = Callable()
	a.get_parent().free()
func run():
	before = load("res://tests/slime_before.gd")
	after = load("res://src/monsters/slime.gd")
	var receipt = RESULT.new()
	# Real shield/death bodies; normal effects/state match both legacy and opt-in API.
	for hp in [0,1,60,1000]:
		for shield in [0,10,100]:
			for amount in [-1,0,1,25,100,2000]:
				for aura in [0.5,1.0,1.5]:
					var old = actor(before,hp,shield,aura)
					var fresh = actor(after,hp,shield,aura)
					old.take_damage(amount)
					check(fresh.take_damage_with_result(amount,receipt),"opt-in completed")
					check(old.current_hp == fresh.current_hp and old.dying == fresh.dying and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"before/after HP/shield/FX/death sequence")
					check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == shield-int(fresh.get_meta("support_shield_hp")),"exact finalized HP/shield counts")
					check(receipt.accepted == (receipt.hp_damage+receipt.shield_absorbed > 0) and receipt.death_started == fresh.dying,"accepted/death flags")
					check(receipt.victim_life == fresh.get_parent().registry.get_handle(fresh) and receipt.victim_instance_id == fresh.get_instance_id() and receipt.requested_damage == amount,"receipt original identity/request")
					cleanup(old)
					cleanup(fresh)
	# Legacy void API remains exactly equivalent when result is omitted.
	var old = actor(before)
	var fresh = actor(after)
	old.take_damage(30)
	fresh.take_damage(30)
	check(old.events == fresh.events and old.current_hp == fresh.current_hp,"legacy void wrapper")
	cleanup(old)
	cleanup(fresh)
	# Callback reuses same buffer: old writer cannot clobber newer completed receipt.
	fresh = actor(after)
	var nested_ok := [false]
	fresh.hit_callback = func():
		fresh.hit_callback = Callable()
		nested_ok[0] = fresh.take_damage_with_result(7,receipt)
	check(not fresh.take_damage_with_result(20,receipt),"reentrant same-buffer outer result unavailable")
	check(nested_ok[0] and receipt.complete and receipt.hp_damage == 7 and receipt.requested_damage == 7 and fresh.current_hp == 33,"newer receipt survives old finish")
	cleanup(fresh)
	# Separate caller-owned buffers preserve both results during nested hits.
	fresh = actor(after)
	var inner = RESULT.new()
	fresh.hit_callback = func():
		fresh.hit_callback = Callable()
		fresh.take_damage_with_result(7,inner)
	check(fresh.take_damage_with_result(20,receipt) and receipt.hp_damage == 20 and inner.hp_damage == 7,"independent nested buffers")
	cleanup(fresh)
	# Snapshot shielding before its popup callback can change shield state.
	fresh = actor(after,60,10)
	POPUPS.callback = func(owner,_amount):
		POPUPS.callback = Callable()
		owner.set_meta("support_shield_hp",100)
	check(fresh.take_damage_with_result(25,receipt) and receipt.hp_damage == 15 and receipt.shield_absorbed == 10,"shield result fixed before popup callback")
	cleanup(fresh)
	# Damage result survives death callback actor reuse, tagged with original life.
	fresh = actor(after)
	var original_life = fresh.get_parent().registry.get_handle(fresh)
	fresh.died.connect(func():
		var reg = fresh.get_parent().registry
		reg.retire_instance(fresh.get_instance_id())
		reg.activate(fresh)
		fresh.current_hp = 60
		fresh.dying = false
	)
	check(fresh.take_damage_with_result(100,receipt),"original lethal receipt completes after actor reuse")
	check(receipt.hp_damage == 60 and receipt.death_started and receipt.victim_life == original_life and fresh.get_parent().registry.get_handle(fresh) != original_life,"receipt uses original damage/life despite reset")
	cleanup(fresh)
	# Actual death guard must prevent reporting a death that never started.
	fresh = actor(after)
	fresh.hit_callback = func():fresh.dying = true
	fresh.take_damage_with_result(100,receipt)
	check(not receipt.death_started and receipt.hp_damage == 60,"death guard reflected in receipt")
	cleanup(fresh)
	# Inherited opt-in cannot bypass another script's overridden damage implementation.
	var derived = actor(load("res://tests/derived.gd"))
	check(not derived.take_damage_with_result(100,receipt) and derived.current_hp == 59 and not receipt.complete,"unsupported override uses legacy once and no confirmed receipt")
	cleanup(derived)
	fresh = actor(after)
	check(not fresh.take_damage_with_result(20,null) and fresh.current_hp == 40,"null result still applies legacy damage once")
	cleanup(fresh)
	# Int64 counts are not truncated to a Vector3i packet.
	fresh = actor(after,5000000000,3000000000)
	fresh.take_damage_with_result(7000000000,receipt)
	check(receipt.shield_absorbed == 3000000000 and receipt.hp_damage == 4000000000 and fresh.current_hp == 1000000000,"64-bit finalized counts")
	cleanup(fresh)
	# All other monsters still call the int-returning shield wrapper.
	var old_common = load("res://tests/common_before.gd")
	var new_common = load("res://tests/common_after.gd")
	for shield in [0,10,100]:
		for amount in [-1,0,1,25,100,2000]:
			for aura in [0.5,1.0,1.5]:
				old = actor(before,60,shield,aura)
				fresh = actor(after,60,shield,aura)
				var old_remaining = old_common.consume_support_shield(old,amount)
				var new_remaining = new_common.consume_support_shield(fresh,amount)
				check(old_remaining == new_remaining and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"legacy shared shield wrapper unchanged")
				cleanup(old)
				cleanup(fresh)
	fresh = actor(after)
	fresh.died.connect(func():fresh.queue_free())
	check(fresh.take_damage_with_result(100,receipt) and receipt.death_started and receipt.hp_damage == 60,"queued death callback retains original receipt")
	cleanup(fresh)
	fresh = actor(after)
	check(fresh.take_damage_with_result(1,receipt) and receipt.identity_verified,"registered identity confidence")
	fresh.get_parent().registry.retire_instance(fresh.get_instance_id())
	check(fresh.take_damage_with_result(1,receipt) and not receipt.identity_verified and receipt.victim_life == Vector3i.ZERO,"unregistered receipt not authoritative identity")
	cleanup(fresh)
	POPUPS.callback = Callable()
	print("Slime receipt checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
