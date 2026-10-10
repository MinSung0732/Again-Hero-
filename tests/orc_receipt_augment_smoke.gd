extends "res://tests/orc_receipt_smoke.gd"

func run():
	before = load("res://tests/orc_before.gd")
	after = load("res://src/monsters/orc.gd")
	var receipt = RESULT.new()
	# Include shield-only, lethal, threshold, already-triggered and capped rage.
	for hp in [0,1,18,19,60]:
		for shield in [0,10,100]:
			for amount in [-1,0,1,25,100]:
				for initial_rage in [0,3]:
					for triggered in [false,true]:
						var old = actor(before,hp,shield)
						var fresh = actor(after,hp,shield)
						for a in [old,fresh]:
							a.max_hp = 60
							a.rage_stacks = initial_rage
							a.last_charge_triggered = triggered
							a.special_augment_configs = {
								"orc_rage_stacks":{"max_stacks":3},
								"orc_last_charge":{"hp_ratio":0.30,"duration":0.75}}
						old.take_damage(amount)
						check(fresh.take_damage_with_result(amount,receipt),"orc receipt complete")
						check(old.current_hp == fresh.current_hp and old.dying == fresh.dying and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"orc damage/effect sequence preserved")
						check(old.rage_stacks == fresh.rage_stacks and old.last_charge_triggered == fresh.last_charge_triggered and old.last_charge_timer == fresh.last_charge_timer,"orc rage/charge exact before-after")
						check(receipt.hp_damage == hp-fresh.current_hp and receipt.death_started == fresh.dying,"orc receipt matches effects")
						cleanup(old)
						cleanup(fresh)
	# Effects must already be visible to the hit callback, not deferred by receipt.
	var fresh = actor(after)
	fresh.special_augment_configs = {"orc_rage_stacks":{"max_stacks":3},"orc_last_charge":{"hp_ratio":0.30,"duration":0.75}}
	fresh.hit_callback = func():
		check(fresh.rage_stacks == 1 and fresh.last_charge_triggered and fresh.last_charge_timer == 0.75,"rage/charge happen before visual callback")
	fresh.take_damage_with_result(42,receipt)
	check(receipt.hp_damage == 42 and fresh.current_hp == 18,"exact threshold triggers without changing damage")
	cleanup(fresh)
	print("Orc augment checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
