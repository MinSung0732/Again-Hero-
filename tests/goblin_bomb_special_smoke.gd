extends "res://tests/goblin_receipt_smoke.gd"
func run():
	var receipt = RESULT.new()
	for kind in ["goblin","bomb_rat"]:
		before = load("res://tests/"+kind+"_before.gd")
		after = load("res://src/monsters/"+kind+".gd")
		for hp in [0,1,60]:
			for support in [0,10,100]:
				for elite in [0,10,100]:
					for amount in [-1,0,1,25,100,2000]:
						for aura in [0.5,1.0,1.5]:
							for special in [false,true]:
								var old = actor(before,hp,support,aura)
								var fresh = actor(after,hp,support,aura)
								for a in [old,fresh]:
									a.set_meta("elite_shield_hp",elite)
									a.stealth_remaining = 1.0 if special else 0.0
									a.self_destructing = special
								old.take_damage(amount)
								check(fresh.take_damage_with_result(amount,receipt),"special receipt complete")
								check(old.current_hp == fresh.current_hp and old.dying == fresh.dying and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp") and old.get_meta("elite_shield_hp") == fresh.get_meta("elite_shield_hp") and old.self_destructing == fresh.self_destructing and old.exp_reward == fresh.exp_reward,"stealth/two shields/death FX/reward preserved")
								check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == support+elite-int(fresh.get_meta("support_shield_hp"))-int(fresh.get_meta("elite_shield_hp")),"exact combined shields/HP")
								check(receipt.death_started == fresh.dying and receipt.accepted == (receipt.hp_damage+receipt.shield_absorbed>0),"special result flags")
								cleanup(old)
								cleanup(fresh)
	# Actual self-destruct function stays separate from killed-by-hero death.
	before = load("res://tests/bomb_rat_before.gd")
	after = load("res://src/monsters/bomb_rat.gd")
	for hp in [1,30,60]:
		var old = actor(before,hp)
		var fresh = actor(after,hp)
		old.self_destructing = true
		fresh.self_destructing = true
		old._complete_self_destruct()
		fresh._complete_self_destruct()
		check(old.events == fresh.events and old.current_hp == fresh.current_hp and old.exp_reward == fresh.exp_reward and old.self_destruct_hp_ratio == fresh.self_destruct_hp_ratio and fresh.get_meta("death_type") == "self_destruct","actual self-destruct order/reward/ratio unchanged")
		check(fresh.events.has("explosion_damage") and fresh.exp_reward == 10,"self-destruct explosion/reward")
		cleanup(old)
		cleanup(fresh)
	var fresh = actor(after)
	fresh.self_destructing = true
	fresh.take_damage_with_result(100,receipt)
	check(receipt.death_started and fresh.get_meta("death_type") == "normal" and fresh.exp_reward == 30 and not fresh.events.has("explosion_damage"),"hero kill during fuse never becomes self-destruct")
	cleanup(fresh)
	fresh = actor(after,60,10)
	fresh.set_meta("elite_shield_hp",20)
	fresh.hit_callback = func():fresh.set_meta("elite_shield_hp",100)
	fresh.take_damage_with_result(25,receipt)
	check(receipt.shield_absorbed == 25 and receipt.hp_damage == 0,"elite absorb recorded before flash callback")
	cleanup(fresh)
	print("Goblin/bomb special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
