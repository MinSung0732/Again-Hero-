extends SceneTree
const D := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for id in D.WEAPONS:
		for rank in range(1,12):
			var text := D.description(id,rank)
			check(text.length() <= 160 and text.split("\n").size() <= 6,id+str(rank)+" compact complete card")
			check(text.split("\n")[-1].begins_with("#"),id+" mechanical tags last")
			check(not text.contains("Lv.") and not text.contains("상자") and not text.contains("총 피해") and not text.contains("예산"),id+" no progression/backend prose")
			if rank in [1,11]: continue
			var before := D.GROWTH.resolve(id,D.WEAPONS[id],rank-1,false)
			var after := D.GROWTH.resolve(id,D.WEAPONS[id],rank,false)
			if String(after.pattern) not in ["guard","heal"]:
				var gain: float = (after.power*after.damage_scale/(before.power*before.damage_scale)-1.0)*100.0
				check(text.contains("+%.1f%%" % gain),id+" resolved damage delta")
	for id in D.PASSIVES:
		for rank in range(1,D.passive_limit(id)+1):
			var text := D.description(id,rank)
			check(text.length() < 70 and text.split("\n").size() == 2,id+" compact passive")
	check(D.description("survival_area",1).contains("+6%"),"area card uses actual six percent")
	check(D.description("survival_mobility",1).contains("3.5%"),"movement gain keeps fraction")
	check(D.description("summoner_hero_watcher",3).contains("공격 간격 -0.06초"),"subsecond summon interval not rounded away")
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := BASE.Hero.new(); hero.hero_id = "ranged_rookie"; arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero)
	var id := "ranged_rookie_arcane_bolt"
	if not runtime.levels.has(id): runtime.add(id)
	check(runtime._card(id,2).description == D.description(id,2),"real level-up card uses compact text")
	var receipt := runtime.roll_chest()
	check(receipt.description == D.description(id,2),"real ordinary chest uses same exact delta")
	for rank in range(2,11): runtime.add(id)
	receipt = runtime.roll_chest()
	check(receipt.evolution and receipt.description == D.description(id,11),"real MAX chest uses compact changes/tags")
	arena.free()
	print("HERO_COMPACT_CARDS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
