extends SceneTree
const H = preload("res://tests/succubus_receipt_helper.gd")
const W = preload("res://tests/succubus_wave_receipt_helper.gd")
const RESULT = preload("res://src/systems/battle_damage_receipt.gd")
const AFTER = preload("res://src/monsters/succubus.gd")
const BEFORE = preload("res://tests/succubus_before.gd")
const POPUPS = preload("res://tests/popups.gd")
const POLICY = preload("res://src/systems/hero_target_policy.gd")
class Authority extends Node:
	var scaling_calls := 0
	func _apply_demon_level_scaling_to_monster(_actor,_preserve):
		scaling_calls += 1
var checks := 0
var failures := 0
var h
func check(value: bool,message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script,hp,shield,config,waltz):
	var a = h.actor(script,hp,shield)
	a.max_hp = 240
	a.infiltration_used = false
	a.collision_layer = 5
	a.collision_mask = 12
	a.waltz_active = waltz
	a.waltz_config = {"damage_taken_multiplier":0.5}
	a.special_augment_configs = config
	return a
func state(a):
	return [a.current_hp,a.dying,a.events,a.infiltration_used,a.infiltration_timer,
		a.infiltration_finished,a.collision_layer,a.collision_mask,a.waltz_active,
		a.visual.modulate.a,a.get_meta("hero_detection_hidden",false),
		a.get_meta("elite_skill_movement_lock",false),a.get_meta("ignore_monster_separation",false),
		a.get_meta("support_shield_hp"),a.rage_stacks,a.last_charge_triggered]
func run():
	h = H.new()
	h.root = root
	var r = RESULT.new()
	var configs = [{},{"succubus_danger_sense":{"hp_ratio":0.5}},
		{"succubus_shadow_recovery":{"hp_ratio":0.75}},
		{"succubus_danger_sense":{"hp_ratio":0.5},"succubus_shadow_recovery":{"hp_ratio":0.75}}]
	for hp in [1,60,240]:
		for shield in [0,10,300]:
			for amount in [0,1,70,1000]:
				for config in configs:
					for waltz in [false,true]:
						var old = actor(BEFORE,hp,shield,config,waltz)
						var fresh = actor(AFTER,hp,shield,config,waltz)
						old.take_damage(amount)
						check(fresh.take_damage_with_result(amount,r),"special receipt completes")
						check(state(old)==state(fresh),"original HP/recovery/phase/shield/visual sequence")
						var applied_hp := 0
						# Popup spy separates shield/HP by the same exact legacy event sequence.
						var absorbed = shield-int(old.get_meta("support_shield_hp"))
						var remaining = maxi(roundi(amount*0.5),0) if waltz else amount
						remaining -= absorbed
						if remaining > 0:
							applied_hp = hp-maxi(hp-remaining,1 if old.infiltration_used else 0)
						check(r.hp_damage==applied_hp and r.shield_absorbed==absorbed,"damage before infiltration healing")
						check(r.accepted==(applied_hp+absorbed>0) and not r.death_started,"phase is never actual death")
						check(r.requested_damage==amount and r.identity_verified,"original request/identity before reduction")
						if fresh.infiltration_used:
							var events = fresh.events.duplicate(true)
							check(fresh.take_damage_with_result(9999,r) and not r.accepted and not r.death_started,"infiltration immune receipt")
							check(fresh.events==events and state(old)==state(fresh),"infiltration ignores new damage")
							old._tick_infiltration(3.0)
							fresh._tick_infiltration(3.0)
							check(state(old)==state(fresh) and POLICY.is_detectable(fresh),"original phase exit restores detection")
							old.take_damage(9999)
							check(fresh.take_damage_with_result(9999,r) and r.death_started and fresh.dying,"later hit begins actual death")
							check(state(old)==state(fresh),"post-infiltration actual death parity")
						h.cleanup(old)
						h.cleanup(fresh)
	# HP1 lethal is a phase transition with zero HP damage, not accepted damage.
	var a = actor(AFTER,1,0,{},false)
	check(a.take_damage_with_result(100,r) and not r.accepted and r.hp_damage==0 and a.infiltration_used,"HP1 phase without phantom damage")
	h.cleanup(a)
	# Waltz may round to zero; do not introduce a minimum-one hit or phase.
	a = actor(AFTER,1,10,{},true)
	a.waltz_config.damage_taken_multiplier = 0.1
	check(a.take_damage_with_result(1,r) and not r.accepted and not a.infiltration_used,"rounded-zero waltz ignores damage")
	check(a.current_hp==1 and a.get_meta("support_shield_hp")==10 and a.waltz_active,"zero reduction keeps shield/phase/waltz")
	h.cleanup(a)
	# Default enabled shape is restored after the deferred collision writes.
	a = actor(AFTER,60,0,{},true)
	a.take_damage_with_result(1000,r)
	await process_frame
	check(a.collision_shape.disabled and not a.waltz_active and not a.get_meta("succubus_waltz_active"),"phase cancels waltz before hiding")
	a._tick_infiltration(3.0)
	await process_frame
	check(not a.collision_shape.disabled and not a.get_meta("ignore_monster_separation") and a.visual.modulate.a==1.0,"enabled shape and normal appearance restored")
	h.cleanup(a)
	# Phase restoration uses original collision flags, alpha and separation state.
	a = actor(AFTER,60,0,{},false)
	a.collision_shape.disabled = true
	a.set_meta("ignore_monster_separation",true)
	var authority = Authority.new()
	a.get_parent().add_child(authority)
	a.combat_authority = authority
	var policy_revision = POLICY.revision
	a.take_damage_with_result(100,r)
	check(POLICY.revision==policy_revision+1 and not POLICY.is_detectable(a),"detection invalidation at phase entry")
	check(a.infiltration_shape_disabled and a.infiltration_ignore_separation,"original collision/separation remembered")
	await process_frame
	check(a.collision_shape.disabled and a.collision_layer==0 and a.collision_mask==0,"deferred phase collision disable")
	a._tick_infiltration(1.0)
	check(a.infiltration_timer==2.0 and not a.infiltration_finished and authority.scaling_calls==0,"phase timer waits")
	a._tick_infiltration(2.0)
	await process_frame
	check(a.collision_shape.disabled and a.collision_layer==5 and a.collision_mask==12 and a.get_meta("ignore_monster_separation"),"exit restores pre-disabled shape/flags")
	check(POLICY.revision==policy_revision+2 and POLICY.is_detectable(a) and authority.scaling_calls==1 and a.visual.modulate.a==1.0,"exit detection/stat scaling once")
	h.cleanup(a)
	# Same buffer reused by recovery callback: earlier result becomes unavailable.
	a = actor(AFTER,60,0,configs[2],false)
	var nested_ok := [false]
	POPUPS.heal_callback = func(_owner,_amount):
		POPUPS.heal_callback = Callable()
		nested_ok[0] = a.take_damage_with_result(7,r)
	check(not a.take_damage_with_result(100,r),"recovery callback invalidates outer buffer")
	check(nested_ok[0] and r.complete and not r.accepted and r.requested_damage==7 and a.current_hp==180,"new immune receipt preserved; original recovery once")
	h.cleanup(a)
	# Separate result survives recovery callback and preserves pre-heal HP loss.
	a = actor(AFTER,60,0,configs[2],false)
	var inner = RESULT.new()
	POPUPS.heal_callback = func(_owner,_amount):
		POPUPS.heal_callback = Callable()
		a.take_damage_with_result(7,inner)
	check(a.take_damage_with_result(100,r) and r.hp_damage==59 and r.accepted and not r.death_started,"pre-heal finalized damage despite healing")
	check(a.current_hp==180 and not inner.accepted and inner.complete,"inner immune result independent")
	h.cleanup(a)
	# Actual wave follows first-survival/later-death semantics and buffer pool.
	var w = W.new()
	w.root = root
	var shot = load("res://tests/wave_projectile_after.gd")
	var world = w.world(shot,60,0,100)
	world.a.infiltration_used = false
	w.sweep(world)
	check(world.hero.kills==0 and world.a.current_hp==1 and world.a.infiltration_used,"wave first lethal saves actor")
	check(world.hero.hits==2 and world.a.events.count("idle")==1,"wave hit policy retained; no duplicate phase")
	world.a._tick_infiltration(3.0)
	world.p.setup("berserker_wave",Vector2.RIGHT,100,700.0,700.0,{},world.hero)
	world.p.set_physics_process(false)
	w.sweep(world)
	check(world.hero.kills==1 and world.a.dying,"later shot actual death credited exactly once")
	w.cleanup(world)
	world = w.world(shot,60,0,100)
	world.a.infiltration_used = false
	world.a.special_augment_configs = configs[2]
	POPUPS.heal_callback = func(_owner,_amount):
		POPUPS.heal_callback = Callable()
		world.a.take_damage_with_result(7,world.p._wave_damage_receipt)
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.current_hp==45,"wave invalidated receipt not retried or inferred")
	w.cleanup(world)
	POPUPS.callback = Callable()
	POPUPS.heal_callback = Callable()
	print("Succubus special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
