extends SceneTree
## Run unchanged in separate processes with original/optimized common helper.
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
class Hero extends BASE.Hero:
	var player_weapons
class Arena extends BASE.Arena:
	var hero: Node
var rows: Array = []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var art: Array[Texture2D] = []
	for data in DATA.WEAPONS.values(): RUNTIME.ART.cache[String(data.effect_dir)] = art
	for id in DATA.WEAPONS:
		for rank in [1,10,11]:
			var arena := Arena.new(); root.add_child(arena)
			var hero := Hero.new(); arena.hero = hero; hero.hero_id = DATA.WEAPONS[id].owner; arena.add_child(hero)
			hero.position = Vector2(900,1200); hero.damage_poison_tracker = BASE.Clearable.new(); hero.burn_runtime = BASE.Clearable.new()
			var runtime := RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime; runtime.passive_siphon = .15
			runtime.levels[id] = mini(rank,10); runtime.weapon_ids.append(id); runtime.cooldowns[id] = 1000
			if rank == 11: runtime.evolved[id] = true
			var data := runtime.stats_for(id)
			for index in 6:
				var actor := BASE.Target.new(); actor.current_hp = 1000000; actor.max_hp = 1000000
				actor.position = hero.position+Vector2(60+index*25,index*3); arena.add_child(actor); arena.targets.append(actor)
			seed(20261017)
			runtime._cast(id)
			var trace: Array = []
			for frame in 80:
				runtime.tick(.05)
				var hp: Array = []
				for actor in arena.targets: hp.append(actor.current_hp)
				trace.append([hp,hero.current_hp,hero.shield_hp,randi()])
			rows.append([id,rank,trace])
			hero.player_weapons = null; arena.free()
	var serialized := JSON.stringify(rows)
	print("PHASE2_WEAPON_REPLAY scenarios=",rows.size()," frames=",rows.size()*80," sha256=",serialized.sha256_text())
	quit()
