extends "res://tests/kraken_receipt_smoke.gd"
const TENTACLE = preload("res://tests/tentacle_spy.gd")
class Target extends Node2D:
	var current_hp := 1000
	var shield_hp := 0
	var hits: Array = []
	var callback: Callable
	func take_damage(amount,source):
		hits.append(amount)
		current_hp = maxi(current_hp-amount,0)
		source.events.append("strike")
		if callback.is_valid():callback.call()
class YukiRuntime extends RefCounted:
	var calls := 0
	var callback: Callable
	func record_death(a):
		calls += 1
		a.events.append("yuki_death")
		if callback.is_valid():callback.call()
class Authority extends Node:
	var hero
	var owner_actor
	var yuki_runtime = YukiRuntime.new()
	func note_tentacle(_spot):owner_actor.events.append("tentacle")
	func _apply_demon_level_scaling_to_monster(_a,_b):owner_actor.events.append("unexpected_growth")
func configure(a,offset: Vector2,visual_scale: float):
	var authority = Authority.new()
	a.get_parent().add_child(authority)
	a.combat_authority = authority
	authority.owner_actor = a
	var target = Target.new()
	a.get_parent().add_child(target)
	target.position = offset
	authority.hero = target
	a.hero = target
	a.scale = Vector2.ONE*visual_scale
	a.burst_count = 3
	a.growth_hits = 2
	a.growth_stacks = 4
	return target
func run():
	before = load("res://tests/kraken_before.gd")
	after = load("res://src/monsters/kraken.gd")
	var receipt = RESULT.new()
	for hp in [0,1,60]:
		for support in [0,10]:
			for damage in [0,1,25,100]:
				for offset in [Vector2.ZERO,Vector2(155,0),Vector2(1000,0)]:
					for visual_scale in [1.0,1.5]:
						var old = actor(before,hp,support)
						var fresh = actor(after,hp,support)
						var ot = configure(old,offset,visual_scale)
						var ft = configure(fresh,offset,visual_scale)
						TENTACLE.calls.clear()
						old.take_damage(damage)
						var old_fx = TENTACLE.calls.duplicate(true)
						TENTACLE.calls.clear()
						check(fresh.take_damage_with_result(damage,receipt),"kraken completes")
						check(old.current_hp==fresh.current_hp and old.dying==fresh.dying and old.events==fresh.events and old.burst_count==fresh.burst_count and old.get_meta("support_shield_hp")==fresh.get_meta("support_shield_hp"),"kraken incoming and death order preserved")
						check(ot.hits==ft.hits and ot.current_hp==ft.current_hp and old_fx==TENTACLE.calls and fresh.growth_hits==2 and fresh.growth_stacks==4,"real eight radial strikes, visuals and no death growth preserved")
						check(receipt.hp_damage==hp-fresh.current_hp and receipt.shield_absorbed==support-int(fresh.get_meta("support_shield_hp")) and receipt.death_started==fresh.dying,"kraken records only own damage/death")
						cleanup(old)
						cleanup(fresh)
	# Enemy strike callback closing death guard retains radial effects but no kill.
	var fresh = actor(after,1)
	var target = configure(fresh,Vector2(155,0),1.0)
	target.callback = func():fresh.dying = true
	fresh.take_damage_with_result(100,receipt)
	check(receipt.hp_damage==1 and not receipt.death_started and target.hits.size()>0 and fresh.burst_count==0,"real strike callback before death guard")
	target.callback = Callable()
	cleanup(fresh)
	# Revision overwrite during real death attack is never retried.
	fresh = actor(after,1)
	target = configure(fresh,Vector2(155,0),1.0)
	target.callback = func():
		target.callback = Callable()
		receipt.begin(target,7)
		receipt.record_hp(7,receipt.revision)
		receipt.finish(receipt.revision)
	check(not fresh.take_damage_with_result(100,receipt) and receipt.hp_damage==7 and receipt.requested_damage==7 and receipt.victim_instance_id==target.get_instance_id() and fresh.dying,"death strike buffer overwrite invalidates outer result")
	cleanup(fresh)
	# Yuki notification occurs once and before actual death guard in both APIs.
	before = load("res://tests/yuki_onna_before.gd")
	after = load("res://src/monsters/yuki_onna.gd")
	for hp in [0,1,60]:
		for support in [0,10]:
			for damage in [0,1,25,100]:
				var old = actor(before,hp,support)
				fresh = actor(after,hp,support)
				for a in [old,fresh]:
					var authority = Authority.new()
					a.get_parent().add_child(authority)
					a.combat_authority = authority
				old.take_damage(damage)
				check(fresh.take_damage_with_result(damage,receipt),"yuki completes")
				check(old.events==fresh.events and old.current_hp==fresh.current_hp and old.dying==fresh.dying and old.combat_authority.yuki_runtime.calls==fresh.combat_authority.yuki_runtime.calls,"yuki callback before-after")
				check(receipt.hp_damage==hp-fresh.current_hp and receipt.death_started==fresh.dying,"yuki actual death result")
				cleanup(old)
				cleanup(fresh)
	fresh = actor(after,1)
	var authority = Authority.new()
	fresh.get_parent().add_child(authority)
	fresh.combat_authority = authority
	authority.yuki_runtime.callback = func():fresh.dying=true
	fresh.take_damage_with_result(100,receipt)
	check(authority.yuki_runtime.calls==1 and receipt.hp_damage==1 and not receipt.death_started,"yuki callback can close actual guard")
	authority.yuki_runtime.callback = Callable()
	fresh._begin_death()
	check(authority.yuki_runtime.calls==1,"yuki already dying does not repeat notification")
	cleanup(fresh)
	TENTACLE.calls.clear()
	print("Remaining inherited special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
