extends "res://tests/skeleton_receipt_smoke.gd"
class ReverseVisual extends Node2D:
	signal revival_animation_finished
	signal death_animation_finished
	var pose_ready := false
	var duration := 0.0
	func is_revival_death_pose_ready():return pose_ready
	func play_revival_reverse(seconds):duration = seconds
	func play_death():pass
func configure(a,ambush,guard,revival,used,waiting):
	a.set_meta("visual_variant","elite")
	a.set_meta("elite_skeleton_ambush_active",ambush)
	a.combat_authority.elite_living = guard
	a.revive_used = used
	a.reviving = waiting
	if guard:a.special_augment_configs["skeleton_necrotic_guard"] = {"damage_taken_multiplier":0.75}
	if revival:a.special_augment_configs["skeleton_return_of_dead"] = {"revive_delay":0.2,"revive_hp_ratio":0.5}
func run():
	before = load("res://tests/skeleton_before.gd")
	after = load("res://src/monsters/skeleton.gd")
	var receipt = RESULT.new()
	for hp in [0,1,60]:
		for shield in [0,10,100]:
			for damage in [0,1,25,100]:
				for ambush in [false,true]:
					for guard in [false,true]:
						for revival in [false,true]:
							for used in [false,true]:
								for waiting in [false,true]:
									var old = actor(before,hp,shield)
									var fresh = actor(after,hp,shield)
									configure(old,ambush,guard,revival,used,waiting)
									configure(fresh,ambush,guard,revival,used,waiting)
									old.take_damage(damage)
									check(fresh.take_damage_with_result(damage,receipt),"skeleton complete")
									check(old.current_hp == fresh.current_hp and old.dying == fresh.dying and old.events == fresh.events and old.reviving == fresh.reviving and old.revive_used == fresh.revive_used and old.revive_timer == fresh.revive_timer and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp") and old.get_meta("elite_skeleton_ambush_active") == fresh.get_meta("elite_skeleton_ambush_active"),"actual ambush/guard/revival/death before-after")
									check(receipt.hp_damage == hp-fresh.current_hp and receipt.shield_absorbed == shield-int(fresh.get_meta("support_shield_hp")) and receipt.death_started == fresh.dying,"HP0 revival never confirms death")
									cleanup(old)
									cleanup(fresh)
	var fresh = actor(after)
	configure(fresh,true,false,true,false,false)
	fresh.pending_second_hit_timer = 1
	fresh.pending_second_hit_target = fresh.combat_authority.hero
	fresh.take_damage_with_result(200,receipt)
	check(fresh.reviving and receipt.accepted and receipt.hp_damage == 60 and not receipt.death_started,"lethal accepted but revival not kill")
	check(fresh.pending_second_hit_target == null and fresh.pending_second_hit_timer == -1 and not fresh.get_meta("elite_skeleton_ambush_active"),"revival clears second hit and ambush")
	check(fresh.heal_direct(100) == 0,"revival blocks direct healing")
	fresh.take_damage_with_result(100,receipt)
	check(not receipt.accepted and not receipt.death_started,"revival blocks incoming damage")
	fresh._tick_revival(0.1)
	check(fresh.reviving,"fallback timer waits")
	fresh._tick_revival(0.1)
	check(not fresh.reviving and fresh.current_hp == 30 and not fresh.get_meta("elite_skill_reviving"),"fallback restores configured HP")
	check(fresh.heal_direct(10) == 10 and fresh.current_hp == 40,"heal restored after revival")
	fresh.take_damage_with_result(200,receipt)
	check(receipt.death_started and fresh.dying and not fresh.reviving,"second lethal actually dies")
	cleanup(fresh)
	fresh = actor(after)
	configure(fresh,false,false,true,false,false)
	fresh.visual.free()
	var visual = ReverseVisual.new()
	fresh.add_child(visual)
	fresh.visual = visual
	fresh.take_damage_with_result(100,receipt)
	fresh._tick_revival(1.0)
	check(fresh.reviving and not fresh.revive_reverse_started,"reverse path waits for death pose readiness")
	visual.pose_ready = true
	fresh._tick_revival(0.1)
	check(fresh.revive_reverse_started and is_equal_approx(visual.duration,0.05),"actual reverse signal connected with minimum duration")
	visual.revival_animation_finished.emit()
	check(not fresh.reviving and fresh.current_hp == 30,"reverse finished restores HP")
	cleanup(fresh)
	# Use the actual projectile caller; only receipt source path/world construction differ.
	var wave = load("res://tests/skeleton_wave_helper.gd").new()
	wave.root = root
	var w = wave.world(load("res://tests/wave_projectile_after.gd"))
	w.hero.monsters = [w.a]
	w.a.special_augment_configs["skeleton_return_of_dead"] = {"revive_delay":0.2,"revive_hp_ratio":0.5}
	wave.sweep(w)
	check(w.a.reviving and w.hero.hits == 1 and w.hero.kills == 0,"real wave hit heals without revival kill credit")
	w.a._tick_revival(0.2)
	w.p.deactivate_for_pool()
	w.scope.registry.activate(w.p)
	w.p.setup("berserker_wave",Vector2.RIGHT,100,700.0,700.0,{"hit_radius":64.0},w.hero)
	wave.sweep(w)
	check(w.a.dying and w.hero.kills == 1,"new wave credits actual second death once")
	wave.cleanup(w)
	wave = null
	print("Skeleton revival checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
