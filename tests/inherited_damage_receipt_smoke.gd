extends "res://tests/wolf_receipt_smoke.gd"
class Pack extends RefCounted:
	var calls := 0
	var callback: Callable
	func record_death(a):
		calls += 1
		a.events.append("pack")
		if callback.is_valid():callback.call()
class Swamp extends RefCounted:
	var calls := 0
	var callback: Callable
	func spawn(_position, _damage, _config, a):
		calls += 1
		a.events.append("swamp")
		if callback.is_valid():callback.call()
class Authority extends Node:
	var wolf_pack_runtime = Pack.new()
	var scorpion_swamp_runtime = Swamp.new()
func authority(a):
	var node = Authority.new()
	a.get_parent().add_child(node)
	a.combat_authority = node
	return node
func configure_wolf(a,howl,iron,pack,rage):
	a.howl_timer = howl
	a.pack_cast_timer = pack
	a.rage_stacks = rage
	a.followup_target = weakref(a.get_parent().hero)
	a.hit_counts[1] = 2
	a.special_augment_configs = {"orc_rage_stacks":{"max_stacks":3},"orc_last_charge":{"hp_ratio":0.3,"duration":0.75}}
	if iron:a.special_augment_configs["wolf_iron_howl"] = {}
	return authority(a)
func run():
	before = load("res://tests/wolf_before.gd")
	after = load("res://src/monsters/wolf.gd")
	var receipt = RESULT.new()
	for hp in [0,1,18,60]:
		for support in [0,10]:
			for damage in [-1,0,1,3,25,100]:
				for howl in [0.0,1.0]:
					for iron in [false,true]:
						for pack in [0.0,1.0]:
							for rage in [0,3]:
								var old = actor(before,hp,support)
								var fresh = actor(after,hp,support)
								var oa = configure_wolf(old,howl,iron,pack,rage)
								var fa = configure_wolf(fresh,howl,iron,pack,rage)
								old.take_damage(damage)
								check(fresh.take_damage_with_result(damage,receipt),"wolf result completes")
								check(old.current_hp == fresh.current_hp and old.events == fresh.events and old.dying == fresh.dying and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"real inherited HP/shield/visual/death preserved")
								check(old.rage_stacks == fresh.rage_stacks and old.last_charge_triggered == fresh.last_charge_triggered and old.last_charge_timer == fresh.last_charge_timer,"parent rage and last charge preserved")
								check(old.howl_timer == fresh.howl_timer and old.pack_cast_timer == fresh.pack_cast_timer and old.hit_counts == fresh.hit_counts and (old.followup_target == null) == (fresh.followup_target == null) and oa.wolf_pack_runtime.calls == fa.wolf_pack_runtime.calls,"wolf suppression and pack cleanup preserved")
								check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == support-int(fresh.get_meta("support_shield_hp")) and receipt.requested_damage == damage and receipt.death_started == fresh.dying,"original amount and actual reduced damage recorded")
								cleanup(old)
								cleanup(fresh)
	# Reduction occurs once and before support shield; original request stays intact.
	var fresh = actor(after,60,1)
	configure_wolf(fresh,1.0,true,0.0,0)
	fresh.take_damage_with_result(3,receipt)
	check(receipt.requested_damage == 3 and receipt.shield_absorbed == 1 and receipt.hp_damage == 1 and fresh.current_hp == 59,"odd amount rounded once before shield")
	cleanup(fresh)
	# Pack callback can close death guard: no confirmed death despite HP0.
	fresh = actor(after,1)
	var fa = configure_wolf(fresh,1.0,true,1.0,0)
	fa.wolf_pack_runtime.callback = func():fresh.dying = true
	fresh.take_damage_with_result(10,receipt)
	check(receipt.hp_damage == 1 and not receipt.death_started and fa.wolf_pack_runtime.calls == 1 and fresh.followup_target == null and fresh.hit_counts.is_empty(),"pack cleanup before actual death guard")
	fa.wolf_pack_runtime.callback = Callable()
	cleanup(fresh)
	# Same buffer nested popup hit uses the actual wolf reduced damage path.
	fresh = actor(after)
	configure_wolf(fresh,1.0,true,0.0,0)
	POPUPS.callback = func(_owner,_amount):
		POPUPS.callback = Callable()
		fresh.take_damage_with_result(7,receipt)
	check(not fresh.take_damage_with_result(20,receipt) and receipt.complete and receipt.requested_damage == 7 and receipt.hp_damage == 4 and fresh.current_hp == 46,"wolf reentry reduction and revision")
	cleanup(fresh)
	# Actual Scorpion inheritance: normal death, swamp and consumption semantics.
	before = load("res://tests/scorpion_before.gd")
	after = load("res://src/monsters/scorpion.gd")
	for hp in [0,1,60]:
		for support in [0,10]:
			for damage in [-1,0,1,25,100]:
				for swamp in [false,true]:
					var old = actor(before,hp,support)
					fresh = actor(after,hp,support)
					var oa = authority(old)
					fa = authority(fresh)
					for a in [old,fresh]:
						a.followup_target = weakref(a.get_parent().hero)
						if swamp:a.special_augment_configs["scorpion_death_swamp"] = {"duration":2.0}
					old.take_damage(damage)
					check(fresh.take_damage_with_result(damage,receipt),"scorpion inherited result complete")
					check(old.current_hp == fresh.current_hp and old.events == fresh.events and old.dying == fresh.dying and (old.followup_target == null) == (fresh.followup_target == null) and oa.scorpion_swamp_runtime.calls == fa.scorpion_swamp_runtime.calls,"scorpion swamp and cleanup before-after")
					check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == support-int(fresh.get_meta("support_shield_hp")) and receipt.death_started == fresh.dying,"scorpion damage/death result")
					cleanup(old)
					cleanup(fresh)
	fresh = actor(after)
	fa = authority(fresh)
	fresh.special_augment_configs["scorpion_death_swamp"] = {"duration":2.0}
	fresh.consume_without_rewards()
	check(fresh.current_hp == 0 and fresh.dying and fresh.get_meta("death_type") == "consumed" and fa.scorpion_swamp_runtime.calls == 1,"consumption still uses original non-hit death path")
	fresh._begin_death()
	check(fa.scorpion_swamp_runtime.calls == 1,"already dying does not respawn swamp")
	cleanup(fresh)
	# Legacy zero-argument overrides must receive zero arguments on both APIs.
	for parent in ["orc","goblin_thrower"]:
		var script = load("res://tests/"+parent+"_legacy_death.gd")
		fresh = actor(script,1)
		fresh.take_damage(10)
		check(fresh.dying and fresh.death_calls == 1 and fresh.current_hp == 0,"legacy derived void lethal dispatch: "+parent)
		cleanup(fresh)
		fresh = actor(script,1)
		check(not fresh.take_damage_with_result(10,receipt) and fresh.dying and fresh.death_calls == 1 and not receipt.complete,"unsupported derived receipt falls back once: "+parent)
		cleanup(fresh)
	# Actual wave uses reduced wolf HP and invokes subclass death once.
	var helper = load("res://tests/wolf_wave_helper.gd").new()
	helper.root = root
	var world = helper.world(load("res://src/hero/archmage_skill_projectile.gd"),60,0,100)
	configure_wolf(world.a,1.0,true,0.0,0)
	helper.sweep(world)
	check(world.a.current_hp == 10 and world.hero.kills == 0 and world.p._wave_damage_receipt.hp_damage == 50,"wave wolf reduction does not create false kill")
	helper.cleanup(world)
	print("Inherited special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
