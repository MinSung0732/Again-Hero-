extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var checks := 0
var failures := 0

class HeroFixture extends Node2D:
	var hero_id := "ranged_rookie"
	var build_counts: Dictionary = {}
	var max_hp := 1200
	var current_hp := 600
	var move_speed := 270.0
	var exp_gain_multiplier := 1.0
	var exp_pickup_radius := 150.0
	func heal_direct(amount: int) -> int:
		var before := current_hp; current_hp = mini(max_hp,current_hp+amount); return current_hp-before

func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SURVIVAL: "+label)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://hero_survival_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(MODE.DURATION == 900.0,"all heroes survive 15 minutes")
	check(not STORE.character_unlocked("stage_1"),"hero mode is locked before demon easy3")
	# Hero mode opens after demon easy stage 3; each hero needs its origin stage (2026-10-14).
	var config := ConfigFile.new()
	config.set_value("progress","highest_unlocked_stage",10)
	for id in ["stage_2","stage_3","stage_10"]: config.set_value("cleared",id,true)
	check(SCOPE.save_config(config,PROGRESS.SAVE_PATH) == OK,"easy-clear fixture")
	check(STORE.character_unlocked("stage_2") and STORE.character_unlocked("stage_10") and not STORE.character_unlocked("stage_4"),"demon easy clears unlock matching heroes")
	check(STORE.select_stage("stage_2"),"unlocked character selection saved")
	check(PROGRESS.complete_hard_stage("stage_2").success,"demon hard requires matching easy clear")
	check(int(PROGRESS.complete_hard_stage("stage_2").reward) == 0,"duplicate hard-clear grant refused")
	check(not PROGRESS.complete_hard_stage("stage_4").success,"hard clear requires easy clear")
	check(MODE.roster_for(1) != MODE.roster_for(10) and MODE.stage_pressure(10) > MODE.stage_pressure(1),"stage changes roster and pressure")
	check(float(MODE.phase_at(899.0).interval) < float(MODE.phase_at(0.0).interval) and int(MODE.phase_at(899.0).batch) > int(MODE.phase_at(0.0).batch),"late waves increase cadence and amount")
	check(MODE.GIANT_TIMES.size() == 5 and MODE.GIANT_TIMES[-1] < MODE.DURATION,"five large-monster encounters before finish")
	for starter in DATA.STARTERS.values(): check(DATA.WEAPONS.has(starter),"starter exists")
	var fixture := HeroFixture.new(); root.add_child(fixture)
	for id in DATA.WEAPONS:
		fixture.hero_id = String(DATA.WEAPONS[id].owner)
		var runtime := RUNTIME.new(); runtime.install(fixture)
		while int(runtime.levels.get(id,0)) < DATA.MAX_LEVEL: check(runtime.add(id),"weapon rank advances: "+id)
		check(not runtime.add(id),"weapon stops at level 10: "+id)
		var chest := runtime.roll_chest()
		check(chest.id == id and chest.evolution,"max weapon is evolution priority: "+id)
		check(runtime.apply_chest(chest) and runtime.evolved.has(id),"evolution applies: "+id)
		var clone := chest.duplicate(); clone.applied = false
		check(not runtime.apply_chest(clone),"receipt cannot replay through a cloned dictionary")
	fixture.hero_id = "ranged_rookie"
	var runtime := RUNTIME.new(); runtime.install(fixture)
	var pool := DATA.weapon_pool(fixture.hero_id)
	for id in pool.slice(1,6): check(runtime.add(String(id)),"six weapon slots")
	check(not runtime.add(String(pool[6])),"seventh weapon rejected")
	var chest := runtime.roll_chest(); var old: int = runtime.levels[chest.id]
	check(not chest.evolution and runtime.apply_chest(chest) and int(runtime.levels[chest.id]) == old+1,"non-max chest upgrades owned weapon")
	for index in range(6): check(runtime.add(String(DATA.PASSIVES.keys()[index])),"passive slot")
	check(not runtime.add(String(DATA.PASSIVES.keys()[6])),"six passive slots")
	for repeat in range(20):
		var candidates := runtime.candidates(); check(not candidates.is_empty() and candidates.size() <= 3,"bounded choices")
		# One-shot recovery cards never take a slot; they are offered while HP is missing.
		for card in candidates: check(runtime.levels.has(card.id) or runtime.passives.has(card.id) or bool(DATA.PASSIVES.get(card.id,{}).get("one_shot",false)),"full slots exclude unowned choices")
	for id in runtime.weapon_ids:
		while int(runtime.levels[id]) < DATA.MAX_LEVEL: runtime.add(id)
		var receipt := runtime.roll_chest(); runtime.apply_chest(receipt)
	var passive_reward := runtime.roll_chest()
	check(passive_reward.kind == "passive" and runtime.apply_chest(passive_reward),"all weapons evolved upgrade owned passive")
	for id in runtime.passives:
		while int(runtime.passives[id]) < DATA.passive_limit(id): runtime.add(String(id))
	var blessing := runtime.roll_chest()
	check(blessing.id == "survival_restore" and runtime.apply_chest(blessing),"all evolved gives recovery")
	check(DATA.PASSIVES.size() == 16 and DATA.PASSIVE_SLOTS == 6,"sixteen passive types, six equipped")
	var stats_fixture := HeroFixture.new(); root.add_child(stats_fixture)
	var stats_runtime := RUNTIME.new(); stats_runtime.install(stats_fixture)
	for id in ["survival_projectile","survival_magnet","survival_armor","survival_haste","survival_vitality","survival_mobility"]:
		for rank in DATA.MAX_LEVEL: check(stats_runtime.add(id),"new passive advances: "+id)
		check(not stats_runtime.add(id),"passive max rank")
	# Passive values are retuned in the catalog (10-14..10-16); expect value*max_rank of each.
	var full := func(id: String) -> float: return float(DATA.PASSIVES[id].value)*DATA.passive_limit(id)
	check(is_equal_approx(stats_runtime.projectile_speed,1.0+full.call("survival_projectile")),"projectile speed scales by catalog rank ten bonus")
	check(is_equal_approx(stats_fixture.exp_pickup_radius,150.0*(1.0+full.call("survival_magnet"))),"pickup radius affects hero property")
	check(is_equal_approx(stats_runtime.damage_multiplier,1.0-minf(full.call("survival_armor"),0.30)),"incoming damage capped at thirty percent reduction")
	check(is_equal_approx(stats_runtime.haste,1.0/(1.0+full.call("survival_haste"))),"attack frequency increases by catalog bonus")
	var vitality_gain := roundi(1200*full.call("survival_vitality"))
	check(stats_fixture.max_hp == 1200+vitality_gain and stats_fixture.current_hp == 600+vitality_gain,"vitality adds fixed starting-hp share and heals")
	check(is_equal_approx(stats_fixture.move_speed,270.0*(1.0+full.call("survival_mobility"))),"mobility uses starting speed")
	check(stats_runtime.projectiles.size() == 64,"bounded projectile pool")
	var learning_fixture := HeroFixture.new(); root.add_child(learning_fixture)
	learning_fixture.exp_gain_multiplier = 1.25
	var learning_runtime := RUNTIME.new(); learning_runtime.install(learning_fixture)
	for id in ["survival_power","survival_learning"]:
		for rank in DATA.MAX_LEVEL: check(learning_runtime.add(id),"power and XP passive advance: "+id)
	check(is_equal_approx(learning_runtime.power,1.0+full.call("survival_power")),"all weapon damage increases by catalog bonus")
	check(is_equal_approx(learning_fixture.exp_gain_multiplier,1.25*(1.0+full.call("survival_learning"))),"XP passive preserves the starting multiplier")
	learning_fixture.queue_free()
	check(MODE.required_exp(1) == 60 and MODE.required_exp(10) == 352 and MODE.required_exp(30) == 1928,"fifteen minute XP curve")
	# Opening pressure was raised again on 10-14/10-15; never below the 10-13 dense opening.
	check(float(MODE.phase_at(0).interval) <= 0.9 and int(MODE.phase_at(0).batch) >= 2 and int(MODE.phase_at(0).limit) >= 36,"denser first wave")
	stats_fixture.queue_free()
	var original_scope := SCOPE.guest_directory
	SCOPE.guest_directory += "_other"; DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(not STORE.character_unlocked("stage_2"),"global hero unlock is account scoped")
	SCOPE.guest_directory = original_scope; fixture.queue_free()
	print("HERO_SURVIVAL_PROGRESSION_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
