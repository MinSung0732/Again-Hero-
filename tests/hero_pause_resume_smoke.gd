extends SceneTree
const H := preload("res://tests/hero_summon_growth_smoke.gd")
const DELAY := preload("res://src/systems/combat_delay.gd")
const ENCOUNTERS := preload("res://src/hero_mode/hero_encounter_runtime.gd")
const PAUSES := preload("res://src/systems/flow_pause_manager.gd")
var checks := 0
var failures := 0
var delay_done := false
var selection_pause_states: Array[bool] = []
class Ticker extends Node:
	var elapsed := 0.0
	func _process(delta: float) -> void: elapsed += delta
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func later(owner: Node) -> void:
	await DELAY.wait(owner,.20)
	delay_done = true
func active(hero,kind: String):
	for actor in hero.get("summoner_"+kind+"_pool"):
		if actor.active: return actor
	return null
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var b = load("res://src/battle/Battle.tscn").instantiate()
	b.hero_player_mode = true; b.hero_player_stage = "stage_8"; b.hero_player_hero_id = "summoner_hero"
	b._monster_spawn_resources_warmed = true; root.add_child(b); b.set_external_pause(true)
	await process_frame
	var hero = b.hero; var r = hero.player_weapons
	hero.augment_selected.connect(func(_level,_candidates,_name,_reason,_build): selection_pause_states.append(b.is_combat_simulation_paused()))
	var ui = load("res://tests/hero_pause_ui_host.gd").new(); root.add_child(ui); ui.battle = b
	var victim = b._spawn_monster("orc",hero.position+Vector2(300,0))
	victim.set_physics_process(false); victim.max_hp = 1000000; victim.current_hp = victim.max_hp
	# Fill the old cap with one kind, then learn gatekeeper: no starvation.
	for index in 3: r._cast("summoner_hero_gate_hound")
	check(hero._get_active_summon_count() == 3,"single learned species retains three slots")
	check(r.add("summoner_hero_gatekeeper"),"learn gatekeeper")
	r._cast("summoner_hero_gatekeeper")
	check(is_instance_valid(active(hero,"gatekeeper")),"new gatekeeper casts despite occupied old slots")
	check(hero._get_active_summon_count() == 3,"new species replaces duplicate within cap")
	check(r.add("summoner_hero_scout") and r.add("summoner_hero_watcher"),"learn four species")
	r._cast("summoner_hero_scout"); r._cast("summoner_hero_watcher")
	check(hero._get_active_summon_count() == 4,"four learned species have four bounded slots")
	for kind in ["hound","scout","watcher","gatekeeper"]:
		check(is_instance_valid(active(hero,kind)),kind+" represented")
	# Kill all copies; repeated cast order cannot steal missing species slots.
	for row in H.CASES.values():
		for actor in hero.get("summoner_"+String(row[0])+"_pool"):
			if actor.active: actor.deactivate()
	for index in 4: r._cast("summoner_hero_gate_hound")
	check(hero._get_active_summon_count() == 1,"duplicates reserve room for missing species")
	for id in ["summoner_hero_scout","summoner_hero_watcher","summoner_hero_gatekeeper"]: r._cast(id)
	check(hero._get_active_summon_count() == 4,"all four return after pool reuse")
	# A real in-flight chain projectile has async hits even with physics disabled.
	var chain = hero._acquire_projectile(load("res://src/hero/ArchmageSkillProjectile.tscn"),"archmage_chain_dagger_projectile")
	chain.setup("chain_dagger",Vector2.RIGHT,40,100,1000,{"chain_tick_count":4,"chain_tick_interval":.18,"chain_tick_damage_ratio":.5},hero,false,victim)
	chain._apply_chain_current_ticks(victim.position-Vector2(30,0),victim.position+Vector2(30,0))
	chain._finish_after_chain_ticks()
	check(chain.active and not chain.is_physics_processing(),"chain waits for async tail with physics intentionally disabled")
	var ticker := Ticker.new(); b.add_child(ticker)
	var sibling := Ticker.new(); root.add_child(sibling)
	var tween_probe := Node2D.new(); b.add_child(tween_probe)
	tween_probe.create_tween().tween_property(tween_probe,"position",Vector2(100,0),1.0)
	var inactive := Ticker.new(); b.add_child(inactive); inactive.set_process(false)
	var local_timer := Timer.new(); local_timer.one_shot = true; b.add_child(local_timer); local_timer.start(.4)
	later(hero)
	var clock: float = b.run_metrics.elapsed_seconds; var hp: int = hero.current_hp
	var target_hp: int = victim.current_hp
	var left: float = local_timer.time_left
	var status_time := DELAY.now_msec(victim)
	victim.set_meta("movement_slow_until",status_time+200)
	victim.set_meta("movement_slow_multiplier",.5)
	var snapshots := {}
	for kind in ["hound","scout","watcher","gatekeeper"]:
		var a = active(hero,kind)
		snapshots[kind] = [a.duration_remaining,a.position,a.visual.frame,a.visual.frame_progress]
	await create_timer(.4).timeout
	check(b.run_metrics.elapsed_seconds == clock,"run timer frozen")
	check(hero.current_hp == hp and victim.current_hp == target_hp and not b.battle_over,"no paused damage or defeat")
	check(ticker.elapsed == 0 and sibling.elapsed > .1,"owned process frozen; sibling scene continues")
	check(is_equal_approx(left,local_timer.time_left),"owned Timer frozen")
	check(tween_probe.position == Vector2.ZERO,"owned Tween frozen")
	check(not delay_done,"delayed combat action frozen")
	check(chain.active and not chain.is_physics_processing(),"paused chain tail is not recycled")
	check(DELAY.now_msec(victim) == status_time,"absolute status clock frozen")
	check(is_equal_approx(preload("res://src/monsters/monster_runtime_common.gd").get_external_movement_multiplier(victim),.5),"slow deadline remains active through pause")
	for kind in snapshots:
		var a = active(hero,kind); var old: Array = snapshots[kind]
		check(a.duration_remaining == old[0] and a.position == old[1],kind+" lifetime and movement frozen")
		check(a.visual.frame == old[2] and is_equal_approx(a.visual.frame_progress,old[3]),kind+" animation frozen with physics")
	# Repeated real selection handler must resume all four without changing pool flags.
	hero.player_augment_requested.connect(ui._show_choices)
	for index in 3:
		hero.player_augment_candidates = [r._card("summoner_hero_gate_hound",int(r.levels.summoner_hero_gate_hound)+1)]
		ui._show_choices(hero.player_augment_candidates)
		await create_timer(.28).timeout
		var button = ui.overlay_rows.get_node("HorizontalAugmentCards/summoner_hero_gate_hound")
		check(not button.disabled,"choice input guard expires during combat pause")
		ui._choose("summoner_hero_gate_hound",ui.choice_generation)
		check(selection_pause_states.back(),"upgrade applies while simulation remains paused")
		check(not b.is_combat_simulation_paused() and not ui.choosing,"selection releases final modal")
		var lifetimes := {}
		for kind in snapshots: lifetimes[kind] = active(hero,kind).duration_remaining
		await create_timer(.3).timeout
		for kind in snapshots:
			var a = active(hero,kind)
			check(is_instance_valid(a) and a.can_process() and a.is_physics_processing(),kind+" processes after upgrade")
			check(a.duration_remaining < lifetimes[kind],kind+" actually ticks after upgrade")
		check(not victim.is_physics_processing(),"resume preserves intentionally disabled actor")
		if index == 0: check(chain.active and not chain.is_physics_processing(),"first resume preserves chain tail state")
		b.set_external_pause(true)
	check(delay_done,"delayed action resumes")
	check(active(hero,"hound").position != snapshots.hound[1],"hound actually moves after repeated upgrades")
	check(tween_probe.position.x > 0,"owned Tween resumes")
	check(not chain.active,"chain tail eventually finishes on simulation time")
	check(ticker.elapsed > .3 and inactive.elapsed == 0,"resume preserves process flags")
	check(victim.current_hp < target_hp,"summons actually attack after resume")
	# Settings opened directly must acquire pause; close panel keeps pause screen.
	b.set_external_pause(false); ui._open_settings()
	check(ui.paused and ui.settings_panel.visible and b.is_combat_simulation_paused(),"direct settings acquires simulation pause")
	clock = b.run_metrics.elapsed_seconds; hp = hero.current_hp
	hero.apply_poison(.8,.5,.1)
	var poison_time: float = hero.poison_timer
	await create_timer(.3).timeout
	check(hero.poison_timer == poison_time,"pending hero DOT freezes in settings")
	check(b.run_metrics.elapsed_seconds == clock and hero.current_hp == hp,"settings freezes clock and health")
	ui.settings_panel.hide()
	check(b.is_combat_simulation_paused(),"settings close retains parent pause")
	# A second modal reason survives resume of the settings reason.
	b.flow_pause_manager.request_pause("test_nested",[PAUSES.DOMAIN_COMBAT]); b._sync_combat_pause_state()
	ui._resume()
	check(b.is_combat_simulation_paused() and not hero.can_process(),"nested modal survives settings resume")
	b.flow_pause_manager.release_pause("test_nested"); b._sync_combat_pause_state()
	check(hero.can_process(),"last reason resumes simulation")
	# Existing boss controller cannot consume timeout while paused.
	var encounter := ENCOUNTERS.new(); encounter.battle = b; encounter.boss_started = true
	encounter.boss_elapsed = 299.9; b.run_metrics.elapsed_seconds = 901.0
	b.set_external_pause(true); encounter.tick(.5)
	check(is_equal_approx(encounter.boss_elapsed,299.9) and not b.battle_over,"boss deadline freezes")
	encounter.free()
	# Several EXP levels can synchronously open another choice.
	hero.current_exp = hero.exp_to_next_level*4
	hero.player_augment_candidates = [r._card("summoner_hero_gatekeeper",2)]
	ui._show_choices(hero.player_augment_candidates)
	ui._choose("summoner_hero_gatekeeper",ui.choice_generation)
	check(ui.choosing and b.is_combat_simulation_paused(),"queued level retains pause")
	var guard := 0
	while ui.choosing and guard < 10:
		var card: Dictionary = hero.player_augment_candidates[0]
		ui._choose(String(card.id),ui.choice_generation); guard += 1
	check(not ui.choosing and not b.is_combat_simulation_paused(),"last queued level resumes")
	# Battle-end presentation restores subtree even if a modal was open.
	b.set_external_pause(true); b.battle_over = true; b.flow_pause_manager.reset(); b._sync_combat_pause_state()
	check(b.can_process() and not hero.is_physics_processing(),"battle end restores presentation but stops combat")
	await create_timer(.3).timeout
	ui.queue_free(); sibling.queue_free(); stop_audio(b); b.queue_free(); await process_frame
	print("HERO_PAUSE_RESUME_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
