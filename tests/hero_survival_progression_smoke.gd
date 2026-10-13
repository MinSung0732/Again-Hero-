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
	check(STORE.character_unlocked("stage_1"),"apprentice opens without clear")
	var config := ConfigFile.new()
	config.set_value("progress","highest_unlocked_stage",10)
	for id in ["stage_2","stage_10"]: config.set_value("cleared",id,true)
	check(SCOPE.save_config(config,PROGRESS.SAVE_PATH) == OK,"easy-clear fixture")
	check(not STORE.character_unlocked("stage_2") and not STORE.character_unlocked("stage_10"),"easy clears do not unlock other heroes")
	check(not STORE.select_stage("stage_2"),"locked selection cannot be saved")
	check(PROGRESS.complete_hard_stage("stage_2").success and STORE.character_unlocked("stage_2"),"hard clear unlocks only matching hero")
	check(not STORE.character_unlocked("stage_10"),"other hero stays locked")
	check(int(PROGRESS.complete_hard_stage("stage_2").reward) == 0,"duplicate hard-clear grant refused")
	check(not PROGRESS.complete_hard_stage("stage_3").success,"hard clear requires easy clear")
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
	var pool := DATA.weapon_pool()
	check(runtime.add(String(pool[1])) and runtime.add(String(pool[2])) and not runtime.add(String(pool[3])),"three weapon slots")
	var chest := runtime.roll_chest(); var old: int = runtime.levels[chest.id]
	check(not chest.evolution and runtime.apply_chest(chest) and int(runtime.levels[chest.id]) == old+1,"non-max chest upgrades owned weapon")
	for index in range(3): check(runtime.add(String(DATA.PASSIVES.keys()[index])),"passive slot")
	check(not runtime.add(String(DATA.PASSIVES.keys()[3])),"three passive slots")
	for repeat in range(20):
		var candidates := runtime.candidates(); check(not candidates.is_empty() and candidates.size() <= 3,"bounded choices")
		for card in candidates: check(runtime.levels.has(card.id) or runtime.passives.has(card.id),"full slots exclude unowned choices")
	for id in runtime.weapon_ids:
		while int(runtime.levels[id]) < DATA.MAX_LEVEL: runtime.add(id)
		var receipt := runtime.roll_chest(); runtime.apply_chest(receipt)
	var blessing := runtime.roll_chest()
	check(blessing.id == "survival_restore" and runtime.apply_chest(blessing),"all evolved gives recovery")
	var original_scope := SCOPE.guest_directory
	SCOPE.guest_directory += "_other"; DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(not STORE.character_unlocked("stage_2"),"hard unlock is account scoped")
	SCOPE.guest_directory = original_scope; fixture.queue_free()
	print("HERO_SURVIVAL_PROGRESSION_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
