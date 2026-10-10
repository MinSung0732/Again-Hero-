extends "res://tests/skeleton_archer_receipt_smoke.gd"
class ReverseVisual extends Node2D:
	signal revival_animation_finished
	signal death_animation_finished
	var pose_ready := false
	var duration := 0.0
	func is_revival_death_pose_ready():return pose_ready
	func play_revival_reverse(seconds):duration = seconds
	func play_death():pass
func configure(a,can_revive,used,waiting):
	if can_revive:a.special_augment_configs["skeleton_archer_revive"] = {"revive_delay":0.2,"revive_hp_ratio":0.5}
	a.revive_used = used
	a.reviving = waiting
	a.attack_windup_timer = 1
	a.burst_shot_timer = 1
	a.burst_shots_remaining = 3
	a.burst_total_shots = 3
func run():
	before = load("res://tests/skeleton_archer_before.gd")
	after = load("res://src/monsters/skeleton_archer.gd")
	var receipt = RESULT.new()
	for hp in [0,1,60]:
		for shield in [0,10,100]:
			for amount in [0,1,25,100]:
				for can_revive in [false,true]:
					for used in [false,true]:
						for waiting in [false,true]:
							var old = actor(before,hp,shield)
							var fresh = actor(after,hp,shield)
							configure(old,can_revive,used,waiting)
							configure(fresh,can_revive,used,waiting)
							old.take_damage(amount)
							check(fresh.take_damage_with_result(amount,receipt),"archer receipt complete")
							check(old.current_hp == fresh.current_hp and old.dying == fresh.dying and old.events == fresh.events and old.reviving == fresh.reviving and old.revive_used == fresh.revive_used and old.revive_timer == fresh.revive_timer and old.get_meta("support_shield_hp") == fresh.get_meta("support_shield_hp"),"archer HP/shield/revival/death before-after")
							check(old.attack_windup_timer == fresh.attack_windup_timer and old.burst_shot_timer == fresh.burst_shot_timer and old.burst_shots_remaining == fresh.burst_shots_remaining and old.burst_total_shots == fresh.burst_total_shots,"attack cancellation preserved")
							check(receipt.hp_damage == hp-fresh.current_hp and receipt.death_started == fresh.dying,"revival is not death")
							cleanup(old)
							cleanup(fresh)
	var fresh = actor(after)
	configure(fresh,true,false,false)
	fresh.take_damage_with_result(100,receipt)
	check(fresh.reviving and receipt.accepted and not receipt.death_started,"archer first lethal revives")
	check(fresh.attack_windup_timer == -1 and fresh.burst_shot_timer == -1 and fresh.burst_shots_remaining == 0 and fresh.burst_total_shots == 0,"revival cancels volley")
	fresh.take_damage_with_result(100,receipt)
	check(not receipt.accepted,"reviving actor rejects damage")
	fresh._tick_revival(0.2)
	check(not fresh.reviving and fresh.current_hp == 30 and fresh.attack_timer == 1.5,"fallback restores HP and resets attack cooldown")
	fresh.take_damage_with_result(100,receipt)
	check(receipt.death_started and fresh.dying and not fresh.get_meta("elite_skill_reviving"),"second lethal confirms real death")
	cleanup(fresh)
	fresh = actor(after)
	configure(fresh,true,false,false)
	fresh.visual.free()
	var visual = ReverseVisual.new()
	fresh.add_child(visual)
	fresh.visual = visual
	fresh.take_damage_with_result(100,receipt)
	fresh._tick_revival(1)
	check(not fresh.revive_reverse_started,"reverse waits for pose")
	visual.pose_ready = true
	fresh._tick_revival(0.1)
	check(fresh.revive_reverse_started and is_equal_approx(visual.duration,0.05),"reverse connected")
	visual.revival_animation_finished.emit()
	check(fresh.current_hp == 30 and not fresh.reviving and fresh.attack_timer == 1.5,"reverse completion resets HP/cooldown")
	cleanup(fresh)
	var wave = load("res://tests/skeleton_archer_wave_helper.gd").new()
	wave.root = root
	var w = wave.world(load("res://tests/wave_projectile_after.gd"))
	w.hero.monsters = [w.a]
	configure(w.a,true,false,false)
	wave.sweep(w)
	check(w.a.reviving and w.hero.kills == 0 and w.hero.hits == 1,"actual wave no revival kill")
	w.a._tick_revival(0.2)
	w.p.deactivate_for_pool()
	w.scope.registry.activate(w.p)
	w.p.setup("berserker_wave",Vector2.RIGHT,100,700.0,700.0,{"hit_radius":64.0},w.hero)
	wave.sweep(w)
	check(w.a.dying and w.hero.kills == 1,"actual wave counts second death")
	wave.cleanup(w)
	wave = null
	print("Ranged revival checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
