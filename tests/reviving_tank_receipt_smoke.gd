extends "res://tests/dullahan_receipt_smoke.gd"
class RevivalVisual extends Node2D:
	signal animation_finished
	signal death_animation_finished
	signal revival_animation_finished
	var ready_pose := false
	var reverse_calls := 0
	func is_revival_death_pose_ready():return ready_pose
	func play_revival_reverse():reverse_calls += 1
func configure(a,shield,used,waiting,slam,rescale):
	a.shield_hp = shield
	a.wall_max_hp = 60
	a.max_hp = 120 if rescale else 60
	a.revive_used = used
	a.reviving = waiting
	a.slam_state = slam
	a.slam_target = a
	a.march_remaining = 3
	a.danger_state = 2
	a.visual.animation_finished.connect(a._finish_slam)
func run():
	before = load("res://tests/dullahan_before.gd")
	after = load("res://src/monsters/dullahan.gd")
	var receipt = RESULT.new()
	for hp in [0,1,60]:
		for support in [0,10]:
			for shield in [0,10]:
				for damage in [0,1,25,100]:
					for used in [false,true]:
						for waiting in [false,true]:
							for slam in [0,2]:
								for rescale in [false,true]:
									var old = actor(before,hp,support)
									var fresh = actor(after,hp,support)
									configure(old,shield,used,waiting,slam,rescale)
									configure(fresh,shield,used,waiting,slam,rescale)
									old.take_damage(damage)
									check(fresh.take_damage_with_result(damage,receipt),"dullahan completes")
									check(old.current_hp == fresh.current_hp and old.shield_hp == fresh.shield_hp and old.wall_max_hp == fresh.wall_max_hp and old.dying == fresh.dying and old.events == fresh.events and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"actual shield/HP/FX preserved")
									check(old.revive_used == fresh.revive_used and old.reviving == fresh.reviving and old.slam_state == fresh.slam_state and old.march_remaining == fresh.march_remaining and old.danger_state == fresh.danger_state and old.visual.animation_finished.is_connected(old._finish_slam) == fresh.visual.animation_finished.is_connected(fresh._finish_slam),"revival and actual slam disconnect preserved")
									check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == support-int(fresh.get_meta("support_shield_hp"))+shield*(2 if rescale else 1)-fresh.shield_hp and receipt.death_started == fresh.dying,"two shields and real death distinct from revival")
									cleanup(old)
									cleanup(fresh)
	var fresh = actor(after,1)
	configure(fresh,0,false,false,2,false)
	fresh.take_damage_with_result(100,receipt)
	check(receipt.accepted and not receipt.death_started and fresh.reviving and fresh.revive_used and fresh.get_meta("elite_skill_reviving"),"first lethal enters revival without kill")
	fresh.visual.animation_finished.emit()
	check(fresh.unexpected_slam_hits == 0 and fresh.slam_target == null and fresh.march_remaining == 0 and fresh.danger_state == 0,"lethal cancels pending slam and other states")
	fresh.take_damage_with_result(10,receipt)
	check(not receipt.accepted and not receipt.death_started,"revival rejects extra damage")
	fresh._tick_revival()
	check(fresh.current_hp == 9 and not fresh.reviving and not fresh.get_meta("elite_skill_reviving"),"actual fallback restores passive HP ratio")
	fresh.take_damage_with_result(100,receipt)
	check(receipt.hp_damage == 9 and receipt.death_started and fresh.dying,"second lethal is actual death")
	cleanup(fresh)
	# Real ONE_SHOT reverse signal and idempotent tick/complete.
	fresh = actor(after,1)
	fresh.revive_used = false
	fresh.visual.free()
	var visual = RevivalVisual.new()
	fresh.add_child(visual)
	fresh.visual = visual
	fresh.special_augment_configs["dullahan_immortal_thirst"] = {"revive_hp_ratio":0.5}
	fresh.take_damage_with_result(100,receipt)
	fresh._tick_revival()
	check(fresh.reviving and not fresh.revive_reverse_started and visual.reverse_calls == 0,"wait for actual ready pose")
	visual.ready_pose = true
	fresh._tick_revival()
	fresh._tick_revival()
	check(fresh.revive_reverse_started and visual.reverse_calls == 1,"reverse starts once")
	visual.revival_animation_finished.emit()
	check(fresh.current_hp == 30 and not fresh.reviving and not visual.revival_animation_finished.is_connected(fresh._complete_revival),"ONE_SHOT reverse completion config HP")
	cleanup(fresh)
	# Actual Banshee reduced hits, minimum zero and original amount identity.
	before = load("res://tests/banshee_before.gd")
	after = load("res://src/monsters/banshee.gd")
	for active in [false,true]:
		for multiplier in [0.0,0.5,1.0]:
			for hp in [0,1,60]:
				for support in [0,10]:
					for damage in [-1,0,1,3,25,100]:
						var old = actor(before,hp,support)
						fresh = actor(after,hp,support)
						for a in [old,fresh]:
							a.set_meta("banshee_charge_stealth_active",active)
							a.special_augment_configs["banshee_charge_stealth"] = {"damage_taken_multiplier":multiplier}
						old.take_damage(damage)
						check(fresh.take_damage_with_result(damage,receipt),"banshee completes")
						check(old.current_hp == fresh.current_hp and old.events == fresh.events and old.dying == fresh.dying and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"banshee stealth before-after")
						check(receipt.requested_damage == damage and receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == support-int(fresh.get_meta("support_shield_hp")) and receipt.death_started == fresh.dying,"banshee original request and reduced counts")
						cleanup(old)
						cleanup(fresh)
	# A real wave first lethal is accepted hit, but not kill; a later wave can kill.
	var helper = load("res://tests/dullahan_wave_helper.gd").new()
	helper.root = root
	var world = helper.world(load("res://src/hero/archmage_skill_projectile.gd"),1,0,100)
	world.a.revive_used = false
	helper.sweep(world)
	check(world.a.reviving and world.hero.kills == 0 and world.p._wave_damage_receipt.accepted and not world.p._wave_damage_receipt.death_started,"wave first lethal never counts revival as kill")
	helper.cleanup(world)
	print("Reviving tank/stealth checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
