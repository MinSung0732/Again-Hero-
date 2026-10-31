extends SceneTree
## Four Stage 4 starters and the remaining hero classes must always be valid.
const WEAPONS := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
var checks := 0
var failures := 0

class MockHero extends Node2D:
	var hero_id := ""
	var build_counts: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_STARTER: "+label)

func run() -> void:
	for hero_id in DATA.STARTERS:
		var hero := MockHero.new()
		hero.hero_id = String(hero_id)
		var runtime := WEAPONS.new()
		runtime.hero = hero
		runtime.available_weapons = DATA.weapon_pool(hero.hero_id)
		var starter := String(DATA.STARTERS[hero_id])
		check(runtime.ensure_starting_weapon(),hero_id+" starter grants successfully")
		check(runtime.weapon_ids.size() == 1 and runtime.weapon_ids[0] == starter,hero_id+" has exactly its starter")
		check(int(runtime.levels.get(starter,0)) == 1 and int(hero.build_counts.get(starter,0)) == 1,hero_id+" starter has rank one")
		check(runtime.ensure_starting_weapon() and runtime.weapon_ids.size() == 1 and int(runtime.levels.get(starter,0)) == 1,hero_id+" repeated guard is idempotent")
		hero.free()
	print("HERO_STARTER checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
