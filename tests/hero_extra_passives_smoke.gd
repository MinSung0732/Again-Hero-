extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const FIXTURE := preload("res://tests/hero_weapon_extension_smoke.gd")
const GEO := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
class Hero extends FIXTURE.Hero:
	var status_resistances := {"slow":0.1}
	func take_damage(amount: int) -> void: current_hp -= amount
	var player_weapons
class NativeSkills extends RefCounted:
	var summon_configs := {"watcher":{"attack_range":700.0}}
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	check(DATA.PASSIVES.size() == 16,"eight additions")
	var arena := FIXTURE.Arena.new(); root.add_child(arena)
	var hero := Hero.new(); hero.hero_id = "swift_hunter"; arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime
	for id in ["survival_projectile","survival_reach","survival_projectile_power"]:
		check(not runtime.add(id),"melee blocks "+id)
	check(not runtime.add("survival_multishot"),"no projectile weapon blocks count")
	check(runtime.add("swift_hunter_throwing_knife"),"melee obtains projectile weapon")
	check(runtime.add("survival_multishot") and runtime.add("survival_multishot") and not runtime.add("survival_multishot"),"additional projectiles capped at two")
	check(int(runtime.stats_for("swift_hunter_throwing_knife").bonus_hits) == 2,"actual projectile stats increment")
	check(runtime.add("survival_siphon"),"lifesteal equipped")
	var target := FIXTURE.Target.new(); arena.add_child(target); target.current_hp = 1000
	hero.current_hp = 500
	HIT.hit(target,200,"ranged",hero)
	check(hero.current_hp == 501,"actual dealt damage heals")
	target.current_hp = 1; var before: int = hero.current_hp
	HIT.hit(target,10000,"ranged",hero)
	check(hero.current_hp == before,"overkill is not healing income")
	HIT.hit(hero,100,"ranged",hero)
	check(hero.current_hp == before-100,"self-reflected damage never grants lifesteal")
	check(runtime.add("survival_slow_resist") and is_equal_approx(hero.status_resistances.slow,0.14),"resistance preserves base and adds four percent")
	check(runtime.add("survival_area"),"area equipped")
	check(float(runtime.stats_for("swift_hunter_dagger").area_scale) > 1,"actual area stat")
	check(GEO.contains("beam",Vector2(100,60),Vector2.RIGHT,300,1,{"area_scale":1.5}) and not GEO.contains("beam",Vector2(100,60),Vector2.RIGHT,300,1,{}),"area width matches hit geometry")
	check(runtime.add("survival_duration"),"duration equipped")
	runtime.add("swift_hunter_venom_steps")
	check(float(runtime.stats_for("swift_hunter_venom_steps").field_duration) > float(DATA.WEAPONS.swift_hunter_venom_steps.field_duration),"actual field duration")
	check(runtime.add("survival_power") and runtime.passives.size() == 6,"six-slot limit maintained")
	check(not runtime.add("survival_armor"),"seventh persistent passive rejected")
	var slots := runtime.passives.size(); hero.current_hp = 100
	check(runtime.add("survival_recovery") and hero.current_hp == 350 and runtime.passives.size() == slots,"instant recovery uses no slot")
	hero.current_hp = hero.max_hp; check(not runtime.add("survival_recovery"),"full health recovery rejected")
	for iteration in 30:
		for card in runtime.candidates(): check(card.id not in ["survival_projectile","survival_reach","survival_projectile_power","survival_recovery"],"ineligible candidates omitted")
	var ranged := Hero.new(); ranged.hero_id = "ranged_rookie"; arena.add_child(ranged)
	var other := RUNTIME.new(); other.install(ranged)
	var base := other.stats_for("ranged_rookie_arcane_bolt")
	check(other.add("survival_reach") and float(other.stats_for("ranged_rookie_arcane_bolt").reach_scale) > float(base.reach_scale),"range invalidates cache")
	check(other.add("survival_projectile_power") and float(other.stats_for("ranged_rookie_arcane_bolt").power) > float(base.power),"projectile damage applied")
	check(other.add("survival_projectile"),"ranged projectile speed allowed")
	other.native_skills = NativeSkills.new()
	other.levels["summoner_hero_watcher"] = 1
	var summon := other.stats_for("summoner_hero_watcher")
	check(is_equal_approx(summon.summon_config.attack_range,728.0),"summon range snapshot scaled")
	check(summon.summon_config.survival_overrides.attack_range == summon.summon_config.attack_range,"summon spawn override retains range")
	check(float(summon.power) > float(DATA.WEAPONS.summoner_hero_watcher.power),"ranged summon projectile damage boosted")
	print("HERO_EXTRA_PASSIVES checks=",checks," failures=",failures)
	arena.queue_free(); await process_frame
	quit(1 if failures else 0)
