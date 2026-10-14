extends SceneTree
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
class Hero extends BASE.Hero:
	var player_weapons
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok,message):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	var maxed := {}
	for id in MODE.GROWTH:
		maxed[id] = MODE.GROWTH[id].value*MODE.GROWTH[id].max
		check(MODE.growth_cost(id,1) > MODE.growth_cost(id,0) and MODE.GROWTH[id].max in [5,10],"bounded level/cost "+id)
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := Hero.new(); arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero,0,maxed); hero.player_weapons = runtime
	check(is_equal_approx(runtime.haste,1.0/1.1) and is_equal_approx(runtime.area_bonus,1.1),"research haste/area initialized")
	check(is_equal_approx(hero.exp_gain_multiplier,1.15) and is_equal_approx(runtime.passive_siphon,0.01),"experience and siphon initialized")
	var before := hero.current_hp; runtime.tick(10,false)
	check(hero.current_hp == before+10,"regen is maxHP per second")
	hero.current_hp = 0; runtime.tick(10,false); check(hero.current_hp == 0,"regen cannot resurrect")
	hero.current_hp = 500; runtime.absorb_damage(150); check(hero.current_hp == 501,"siphon banks fractional actual damage")
	runtime.absorb_damage(50); check(hero.current_hp == 502,"fractional siphon completed without loss")
	check(is_equal_approx(runtime.shield_amount(100),120),"generated shield multiplier")
	var shield = load("res://tests/hero_research_shield_harness.gd").new(); root.add_child(shield); shield.player_weapons = runtime
	shield.player_controlled = false; shield._add_purifier_shield_layer(); check(is_equal_approx(shield.shield_hp,10),"demon shield remains original")
	shield.shield_hp = 0; shield.shield_max_hp = 0; shield.player_controlled = true; shield._add_purifier_shield_layer(); check(is_equal_approx(shield.shield_hp,12),"native player shield receives bonus once")
	for id in RUNTIME.DATA.WEAPONS:
		runtime.levels[id] = 1
		var stats := runtime.stats_for(id); var pattern := String(stats.pattern)
		var expected := 1.15 if pattern in RUNTIME.DATA.RANGED_RESEARCH_PATTERNS else 1.0
		if pattern in RUNTIME.DATA.AREA_PATTERNS and pattern not in ["beam","capsule"]: expected *= 1.1
		check(is_equal_approx(float(stats.reach_scale),expected),"range research classification "+id)
	runtime.add("survival_haste"); check(runtime.haste < 1.0/1.1,"passive haste retains research")
	runtime.add("survival_area"); check(runtime.area_bonus > 1.1,"passive area retains research")
	shield.queue_free(); arena.queue_free(); await process_frame
	print("HERO_RESEARCH_RUNTIME checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
