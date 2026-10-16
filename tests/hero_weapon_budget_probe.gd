extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const WINDOW := 30.0
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var arena := BASE.Arena.new();root.add_child(arena)
	var hero := BASE.Hero.new();arena.add_child(hero);hero.position=Vector2(900,1200)
	hero.damage_poison_tracker=BASE.Clearable.new();hero.burn_runtime=BASE.Clearable.new()
	for index in 18:
		var actor := BASE.Target.new();arena.add_child(actor);arena.targets.append(actor)
	var runtime := RUNTIME.new();var empty: Array[Texture2D]=[]
	for id in DATA.WEAPONS:RUNTIME.ART.cache[String(DATA.WEAPONS[id].get("effect_dir",""))]=empty
	runtime.install(hero)
	print("BUDGET\tid\tlevel\ttargets\tdamage_per_second\tattack_normalized_dps")
	for id in DATA.WEAPONS:
		if String(DATA.WEAPONS[id].pattern) in ["summon","piercer","meteor","ice_pillar","singularity","guard","heal"]:continue
		for level in [1,10,11]:
			for count in [1,6,18]:
				runtime.weapon_ids.clear();runtime.weapon_ids.append(id);runtime.levels.clear();runtime.levels[id]=mini(level,10)
				runtime.evolved.clear()
				if level==11:runtime.evolved[id]=true
				runtime.resolved.clear();runtime.cooldowns[id]=0.0;runtime.magazines[id]=9999
				if "kit" in runtime: runtime.kit.records.clear();runtime.kit.order.clear();runtime.kit.casts=0
				for f in runtime.fields:f.left=0.0
				for f in runtime.delivery.slots:f.left=0.0
				for f in runtime.evolution.slots:f.left=0.0
				for f in runtime.pulses:f.active=false
				for f in runtime.projectiles:f.active=false
				for index in 18:
					var actor = arena.targets[index];actor.current_hp=1000000
					actor.position=hero.position+Vector2(90+(index%3)*22,(index/3-2)*20) if index<count else Vector2(-9999,-9999)
				for tick in 300:runtime.tick(.1,true)
				var total:=0
				for index in count:total+=1000000-int(arena.targets[index].current_hp)
				print("BUDGET\t%s\t%d\t%d\t%.3f\t%.3f"%[id,level,count,total/WINDOW,total/WINDOW/hero.attack_damage])
	arena.queue_free();await process_frame;quit()
