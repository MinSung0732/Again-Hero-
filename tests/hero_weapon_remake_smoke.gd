extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const BALANCE := preload("res://src/data/hero_weapon_balance_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
class Arena extends BASE.Arena:
	var generation := 1
	func get_battle_entity_handle(actor: Node) -> Vector3i:
		return Vector3i(targets.find(actor)+1,generation,1)
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		push_error(message); failures += 1
func clear(runtime) -> void:
	for f in runtime.fields: f.left = 0.0
	for f in runtime.delivery.slots: f.left = 0.0
	for f in runtime.evolution.slots: f.left = 0.0
	for f in runtime.pulses: f.active = false
	for f in runtime.projectiles: f.active = false
	runtime.resolved.clear()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var arena := Arena.new(); root.add_child(arena)
	var hero := BASE.Hero.new(); arena.add_child(hero); hero.position = Vector2(900,1200)
	hero.damage_poison_tracker = BASE.Clearable.new(); hero.burn_runtime = BASE.Clearable.new()
	var enemy := BASE.Target.new(); arena.add_child(enemy); enemy.position = hero.position+Vector2(80,0); arena.targets.append(enemy)
	var runtime := RUNTIME.new(); var empty: Array[Texture2D] = []
	for id in DATA.WEAPONS: RUNTIME.ART.cache[String(DATA.WEAPONS[id].get("effect_dir",""))] = empty
	runtime.install(hero)
	check(BALANCE.PROFILES.size() == 100,"100 stable IDs")
	for id in DATA.WEAPONS:
		for level in [1,3,6,10,11]:
			var data := DATA.GROWTH.resolve(id,DATA.WEAPONS[id],mini(level,10),level==11)
			check(data.cooldown > 0 and data.power > 0 and data.range > 0,"valid base "+id)
			check(float(data.cooldown_scale) >= .7,"no explosive haste scaling "+id)
			check(int(data.get("pulse_count",0)) <= 1,"bounded aftershock "+id)
			check(float(data.get("chain_growth",0)) <= .06,"bounded chain growth "+id)
			if level==11:
				var previous := DATA.GROWTH.resolve(id,DATA.WEAPONS[id],10,false)
				check(data.damage_scale > previous.damage_scale and data.has("max_mechanic"),"MAX benefit "+id)
				check(not String(data.max_mechanic.description).is_empty(),"MAX declared "+id)
			var mode := String(DATA.DELIVERY.spec(id,data).get("mode",""))
			if mode=="sentry": check(data.owner=="pistol_hero","only gunner uses sentry")
			if mode=="orbit": check(data.owner in ["ranged_rookie","sage_astra"],"intentional orbit owner")
		# Real generic casts at rank 1, 10, MAX. Native actors separately tested.
		if String(DATA.WEAPONS[id].pattern) in ["summon","piercer","meteor","ice_pillar","singularity"]: continue
		for level in [1,10,11]:
			clear(runtime);runtime.levels[id] = mini(level,10); runtime.magazines[id] = 99; runtime.evolved.erase(id)
			if level==11: runtime.evolved[id] = true
			enemy.current_hp = 100000; runtime._cast(id)
			for step in 80:
				for slot in runtime.delivery.slots:
					if float(slot.left)>0:
						if slot.mode == "orbit":
							runtime.delivery.clock += .1
							enemy.position = runtime.delivery.orbit_point(slot,0)
							runtime.delivery.clock -= .1
						else: enemy.position = Vector2(slot.origin)
				runtime.tick(.1,false)
			if String(DATA.WEAPONS[id].pattern) not in ["guard","heal"]:
				check(enemy.current_hp < 100000,"actual attack causes damage "+id+str(level))
			enemy.position = hero.position+Vector2(80,0)
	# Single-target bolt growth may concentrate every advertised projectile on one boss.
	clear(runtime); var id := "swift_hunter_throwing_knife"
	runtime.evolved.erase(id)
	runtime.levels[id] = 10;runtime._cast(id)
	var active := 0
	for shot in runtime.projectiles:
		if shot.active: active += 1
	check(active == int(runtime.stats_for(id).base_hits)+int(runtime.stats_for(id).get("bonus_hits",0)),"all bolt rounds available against one boss")
	# No movement input exploit; actual movement charges a single ambush.
	runtime.kit.movement = 0;runtime.kit.previous = hero.position
	runtime.kit.tick(1);check(runtime.kit.movement==0,"standing still never charges ambush")
	hero.position += Vector2(180,0);runtime.kit.tick(1)
	var rogue := DATA.GROWTH.resolve("swift_hunter_execution_stiletto",DATA.WEAPONS.swift_hunter_execution_stiletto,1,false)
	check(runtime.kit.cast_factor(rogue)>1 and runtime.kit.cast_factor(rogue)==1,"movement ambush spent once")
	# Element/reagent reactions require alternating hits, actual damage and generation handles.
	for pair in [["archmage_hero_ice_scepter","archmage_hero_lightning_rod"],["chemical_hero_acid_vial","chemical_hero_toxic_dart"]]:
		var first := DATA.GROWTH.resolve(pair[0],DATA.WEAPONS[pair[0]],1,false)
		var second := DATA.GROWTH.resolve(pair[1],DATA.WEAPONS[pair[1]],1,false)
		runtime.kit.records.clear();runtime.kit.order.clear();runtime.kit.cursor=0
		runtime.kit.landed(enemy,first,false)
		check(runtime.kit.factor(enemy,first)==1,"same-element tick cannot react")
		check(runtime.kit.factor(enemy,second)>1,"alternating element reacts")
		runtime.kit.landed(enemy,second,true)
		check(runtime.kit.factor(enemy,first)==1,"reaction cooldown suppresses spam")
		runtime.kit.clock += 4
		check(runtime.kit.factor(enemy,first)==1,"reaction expires")
	var reagent := DATA.GROWTH.resolve("chemical_hero_acid_vial",DATA.WEAPONS.chemical_hero_acid_vial,1,false)
	var catalyst := DATA.GROWTH.resolve("chemical_hero_toxic_dart",DATA.WEAPONS.chemical_hero_toxic_dart,1,false)
	runtime.kit.records.clear();runtime.kit.order.clear();runtime.kit.cursor=0
	runtime.kit.landed(enemy,reagent,false);arena.generation+=1
	check(runtime.kit.factor(enemy,catalyst)==1,"recycled actor cannot inherit reagent")
	for revision in 100:
		arena.generation+=1;runtime.kit.landed(enemy,reagent,false)
	check(runtime.kit.records.size()==64 and runtime.kit.order.size()==64,"reaction state remains bounded at 64")
	var secondary := catalyst.duplicate();secondary.evolution_secondary=true
	check(runtime.kit.factor(enemy,secondary)==1,"secondary damage cannot trigger a reaction")
	# Splash and aftershocks never build MAX marks again, even in a dense group.
	clear(runtime);id="ranged_rookie_sealing_bolt";runtime.levels[id]=10;runtime.evolved[id]=true
	var mark_data := runtime.stats_for(id)
	runtime.evolution.mark_lookup.clear();runtime.evolution.free_marks.clear()
	for index in 64:
		runtime.evolution.marks[index].left=0.0;runtime.evolution.free_marks.append(index)
	enemy.position=hero.position+Vector2(50,0);enemy.current_hp=100000
	runtime._splash(enemy.position,10,80,null,mark_data)
	check(runtime.evolution.mark_lookup.is_empty(),"splash cannot build MAX marks")
	# Emitter recast cannot multiply damage via unbounded parallel zones.
	clear(runtime);id="chemical_hero_poison_flask";runtime.levels[id]=10
	for step in 100: runtime._cast(id)
	active=0
	for f in runtime.delivery.slots:
		if f.left>0:active+=1
	check(active<=3 and runtime.delivery.slots.size()==24,"100 casts bounded")
	arena.queue_free();await process_frame
	print("WEAPON_REMAKE checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
