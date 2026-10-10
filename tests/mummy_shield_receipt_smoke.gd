extends "res://tests/mummy_receipt_smoke.gd"
const STATUS := preload("res://src/systems/status_action_scope.gd")
class Target extends Node2D:
	var current_hp := 1000
	var shield_hp := 0
	var hits := 0
	var heal_reductions := 0
	var curses := 0
	var callback: Callable
	func take_damage(amount, source):
		hits += 1
		current_hp = maxi(current_hp - amount, 0)
		source.events.append(["counter", amount])
		if callback.is_valid():callback.call()
	func apply_healing_reduction(_duration, _reduction):heal_reductions += 1
	func apply_damage_taken_increase(_duration, _increase):curses += 1

func configure(a, native: int, counter: bool, rescale: bool):
	a.shield_hp = native
	a.shield_basis_hp = 60
	a.max_hp = 120 if rescale else 60
	a.shield_capacity = 30
	a.combat_authority = a.get_parent()
	var target = Target.new()
	a.get_parent().add_child(target)
	a.hero = target
	if counter:
		a.special_augment_configs = {
			"mummy_broken_seal": {},
			"mummy_dry_wound": {"duration":3.0,"reduction":0.5}}
		a.elite_curse = {"duration":4.0,"damage_increase":0.2}
	return target

func run():
	before = load("res://tests/mummy_before.gd")
	after = load("res://src/monsters/mummy.gd")
	var receipt = RESULT.new()
	# Real rescale, support/native shielding and counterattack, including lethal hits.
	for hp in [0,1,60]:
		for support in [0,10]:
			for native in [0,10,30]:
				for damage in [-1,0,1,25,100]:
					for counter in [false,true]:
						for rescale in [false,true]:
							var old = actor(before,hp,support)
							var fresh = actor(after,hp,support)
							var old_target = configure(old,native,counter,rescale)
							var target = configure(fresh,native,counter,rescale)
							old.take_damage(damage)
							check(fresh.take_damage_with_result(damage,receipt),"mummy completes")
							check(old.current_hp == fresh.current_hp and old.shield_hp == fresh.shield_hp and old.shield_capacity == fresh.shield_capacity and old.shield_basis_hp == fresh.shield_basis_hp and old.shield_broken == fresh.shield_broken and old.dying == fresh.dying and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"mummy state/effects exactly before-after")
							check(old_target.current_hp == target.current_hp and old_target.hits == target.hits and old_target.heal_reductions == target.heal_reductions and old_target.curses == target.curses,"real counterattack and statuses preserved")
							var effective_native = native * (2 if rescale else 1) if hp > 0 and damage > 0 else native
							var absorbed = support-int(fresh.get_meta("support_shield_hp"))+effective_native-fresh.shield_hp
							check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == absorbed and receipt.accepted == (absorbed+receipt.hp_damage > 0) and receipt.death_started == fresh.dying,"actual two shield layers and death result")
							check(STATUS.current(target) == null and STATUS.current(old_target) == null,"counterattack action scope restored")
							cleanup(old)
							cleanup(fresh)
	# Native shield-only hit is accepted, plays hit, breaks seal before counterattack.
	var fresh = actor(after)
	var target = configure(fresh,10,true,false)
	var prior_action = STATUS.Token.new()
	STATUS.begin(target,prior_action)
	target.callback = func():
		check(fresh.shield_broken and fresh.current_hp == 60,"seal committed before counter callback")
	fresh.take_damage_with_result(10,receipt)
	check(receipt.hp_damage == 0 and receipt.shield_absorbed == 10 and receipt.accepted and target.hits == 1,"native shield-only counter result")
	check(STATUS.current(target) == prior_action and target.heal_reductions == 1 and target.curses == 1,"real counter statuses and enclosing scope retained")
	target.callback = Callable()
	fresh.take_damage_with_result(1,receipt)
	check(target.hits == 1,"seal counter occurs only once")
	cleanup(fresh)
	# Both records are committed before popup callback mutates actor shielding/HP.
	fresh = actor(after)
	configure(fresh,10,false,false)
	POPUPS.callback = func(owner,_amount):
		POPUPS.callback = Callable()
		owner.shield_hp = 99
		owner.current_hp = 99
	fresh.take_damage_with_result(25,receipt)
	check(receipt.hp_damage == 15 and receipt.shield_absorbed == 10,"native result fixed before popup mutation")
	cleanup(fresh)
	# Same-buffer counter reentry makes outer result unavailable, without extra hit.
	fresh = actor(after)
	target = configure(fresh,10,true,false)
	var nested := [false]
	target.callback = func():
		target.callback = Callable()
		nested[0] = fresh.take_damage_with_result(7,receipt)
	check(not fresh.take_damage_with_result(25,receipt),"same-buffer counter invalidates outer receipt")
	check(nested[0] and receipt.complete and receipt.hp_damage == 7 and receipt.shield_absorbed == 0 and receipt.requested_damage == 7 and fresh.current_hp == 38 and target.hits == 1,"inner result survives and no replay")
	cleanup(fresh)
	# Independent buffers keep both actual HP/shield counts on counter reentry.
	fresh = actor(after)
	target = configure(fresh,10,true,false)
	var inner = RESULT.new()
	target.callback = func():
		target.callback = Callable()
		fresh.take_damage_with_result(7,inner)
	check(fresh.take_damage_with_result(25,receipt) and receipt.hp_damage == 15 and receipt.shield_absorbed == 10 and inner.hp_damage == 7,"independent counter results")
	cleanup(fresh)
	# Break on lethal damage retains hit/counter/death ordering.
	fresh = actor(after,1)
	target = configure(fresh,10,true,false)
	fresh.take_damage_with_result(100,receipt)
	check(fresh.events == [11,"hit",["counter",30],"death"] and receipt.hp_damage == 1 and receipt.shield_absorbed == 10 and receipt.death_started,"lethal counter executes before actual death")
	cleanup(fresh)
	# Ghost death clears phase even when its death guard is already locked.
	var ghost_script = load("res://src/monsters/ghost.gd")
	fresh = actor(ghost_script,1)
	fresh.phase_shift_active = true
	fresh.visual.modulate = Color(0.1,0.2,0.3,0.4)
	fresh.take_damage_with_result(5,receipt)
	check(not fresh.phase_shift_active and fresh.visual.modulate == Color.WHITE and receipt.death_started,"ghost actual phase teardown")
	cleanup(fresh)
	fresh = actor(ghost_script,1)
	fresh.phase_shift_active = true
	POPUPS.callback = func(owner,_amount):
		POPUPS.callback = Callable()
		owner.dying = true
	fresh.take_damage_with_result(5,receipt)
	check(not fresh.phase_shift_active and not receipt.death_started,"ghost teardown precedes guarded death")
	cleanup(fresh)
	# Actual wave treats native absorption as accepted hit, never a kill.
	var helper = load("res://tests/mummy_wave_helper.gd").new()
	helper.root = root
	var world = helper.world(load("res://src/hero/archmage_skill_projectile.gd"),60,0,10)
	world.a.shield_hp = 30
	helper.sweep(world)
	check(world.a.current_hp == 60 and world.a.shield_hp == 20 and world.p._wave_damage_receipt.accepted and world.p._wave_damage_receipt.hp_damage == 0 and world.p._wave_damage_receipt.shield_absorbed == 10 and world.hero.kills == 0,"wave native shield receipt")
	helper.cleanup(world)
	print("Mummy shield/ghost checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
