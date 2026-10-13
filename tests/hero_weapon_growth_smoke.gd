extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const GROWTH := DATA.GROWTH
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("WEAPON_GROWTH: "+label)
func relocate(actor, position: Vector2) -> void:
	actor.global_position = position; COMMON.notify_forced_position_change(actor)
func reset(runtime, hero) -> void:
	for field in runtime.fields: field.left = 0.0
	for pulse in runtime.pulses: pulse.active = false
	for shot in runtime.projectiles: shot.active = false
	for pattern in runtime.native_skills.actors_by_pattern:
		var key: String = runtime.native_skills.SCENES[pattern][1]
		for actor in runtime.native_skills.actors_by_pattern[pattern]:
			if actor not in hero.get_parent().projectile_pools[key]: hero.get_parent().recycle_projectile(actor,key)
	for actor in runtime.identity.native_actors:
		if actor.active: hero.get_parent().recycle_projectile(actor,String(actor.get_meta("identity_pool_key","")))
	for kind in ["hound","watcher","scout","gatekeeper"]:
		for actor in hero.get("summoner_"+kind+"_pool"):
			if actor.active: actor.deactivate()
	hero.alchemist_gas = hero.alchemist_gas_max; hero.gunner_ammo = hero.gunner_magazine_size
	hero.gunner_reloading = false; hero.gunner_reload_timer = 0.0
	hero.current_hp = hero.max_hp; hero.rogue_combo_index = 0
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://weapon_growth_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(GROWTH.PROFILES.size() == 100 and DATA.WEAPONS.size() == 100,"all existing IDs have growth profiles")
	var names: Dictionary = {}
	for id in DATA.WEAPONS:
		check(GROWTH.PROFILES.has(id),"profile present "+id)
		var name := GROWTH.evolution_name(id)
		check(not names.has(name) and name != String(DATA.WEAPONS[id].name),"unique evolved identity "+id); names[name] = true
		for rank in [3,6,10]:
			check(not GROWTH.PROFILES[id][[3,6,10].find(rank)+1].is_empty(),"mechanical milestone "+id+str(rank))
		var base := GROWTH.resolve(id,DATA.WEAPONS[id],1,false)
		check(is_equal_approx(base.damage_scale,1.0) and not base.has("bonus_hits"),"Lv1 preserved "+id)
		check(not GROWTH.evolution_description(id).is_empty() and not DATA.description(id,10).contains("상자") and not DATA.description(id,10).contains("진화"),"player-facing progression "+id)
	for hero_id in DATA.HERO_WEAPONS:
		var battle = load("res://src/battle/Battle.tscn").instantiate()
		battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = String(hero_id)
		root.add_child(battle); battle.set_external_pause(true)
		var hero = battle.hero; var runtime = hero.player_weapons
		var target = battle._spawn_monster("orc",hero.position+Vector2(80,0),0,false,{})
		target.set_physics_process(false); target.max_hp = 1000000; target.current_hp = 1000000
		for id in DATA.weapon_pool(hero_id):
			reset(runtime,hero); runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.evolved.clear(); runtime.add(String(id))
			# Real level-up API and real chest receipt; evolution cannot be selected as Lv11.
			for rank in range(2,11): runtime.add(String(id))
			var receipt: Dictionary = runtime.roll_chest()
			check(receipt.id == id and receipt.evolution and receipt.name == GROWTH.evolution_name(id),"real evolution receipt "+String(id))
			for phase in [3,6,10,11]:
				var awakened: bool = phase == 11
				var rank: int = mini(10,phase)
				runtime.levels[id] = rank
				reset(runtime,hero)
				if awakened:
					check(runtime.apply_chest(receipt) and not runtime.apply_chest(receipt),"evolution applies once "+String(id))
				var data: Dictionary = runtime.stats_for(String(id)); var pattern := String(data.pattern)
				var radius := GEOMETRY.reach(data,rank,awakened)
				relocate(target,hero.position+Vector2(radius*float(data.get("orbit_ratio",0.7)) if pattern == "orbit" else 80.0,0)); await physics_frame
				var nodes: Array[Node] = battle.get_children()
				runtime._cast(String(id))
				var reused := true
				for child in battle.get_children():
					if child not in nodes and child.get_script() != preload("res://src/ui/damage_number.gd"): reused = false
				check(reused,"upgrade cast only permits existing damage-popup lazy pool "+String(id))
				var pulses := 0; var fields := 0; var shots := 0
				for pulse in runtime.pulses:
					if pulse.active: pulses += 1
				for field in runtime.fields:
					if field.left > 0: fields += 1
				for shot in runtime.projectiles:
					if shot.active: shots += 1
				check(pulses == int(data.get("pulse_count",0)),"actual secondary pulse count "+String(id))
				if pattern == "poison": check(fields == int(data.get("field_count",1)),"actual multi-field count "+String(id))
				if runtime.native_skills.SCENES.has(pattern):
					var native_active := 0
					for actor in runtime.native_skills.actors_by_pattern[pattern]:
						if (bool(actor.active) if pattern in ["piercer","ice_pillar"] else int(actor.state) != 0): native_active += 1
					check(native_active == mini(int(runtime.native_skills.SCENES[pattern][2]),int(data.base_hits)+int(data.get("bonus_hits",0))),"actual native multi-actor count "+String(id))
				if pattern in ["burst","combo"] and not (runtime.identity.spec.has("native_basic") and id == runtime.identity.starter):
					check(shots == mini(6,int(data.base_hits)+int(data.get("bonus_hits",0))),"actual delayed sequence "+String(id))
				if pattern == "summon":
					var active = null
					for actor in hero.get("summoner_"+String(data.summon_kind)+"_pool"):
						if actor.active: active = actor; break
					check(is_instance_valid(active) and hero._get_active_summon_count() == 1,"real evolved summon "+String(id))
					if is_instance_valid(active):
						check(is_equal_approx(active.duration_total,float(data.summon_duration)),"summon duration snapshot "+String(id))
						for key in data.summon_patch: check(is_equal_approx(float(active.get(key)),float(data.summon_patch[key])),"summon property "+String(id)+key)
				if id == "swift_hunter_dagger":
					check(hero.rogue_combo_index == 1 and hero.rogue_bonus_combo_hits == 0,"native combo and temporary profile restoration")
					var length: int = 3+int(data.get("native_combo_bonus",0))
					for index in length-1: runtime._cast(String(id))
					check(hero.rogue_combo_index == 0,"native four/five/six-hit finisher wraps at actual upgraded length")
				if id == "sage_astra_starlight" and awakened:
					var piercing := false
					for actor in runtime.identity.native_actors:
						if actor.active and actor.get_meta("identity_pool_key","") == "sage_piercing_projectile": piercing = true
					check(piercing and int(hero.sage_config.third_attack_interval) == 3,"all-basic piercing and original AI config restoration")
				check(runtime.projectiles.size() == 64 and runtime.pulses.size() == 24 and runtime.fields.size() == 8,"fixed capacities after evolution")
		battle.queue_free(); await process_frame
	await exact_effects()
	await presentation()
	print("HERO_WEAPON_GROWTH_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func exact_effects() -> void:
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; battle.hero_player_hero_id = "ranged_rookie"
	root.add_child(battle); battle.set_external_pause(true)
	var hero = battle.hero; var runtime = hero.player_weapons
	var a = battle._spawn_monster("orc",hero.position+Vector2(80,0),0,false,{})
	var b = battle._spawn_monster("orc",hero.position+Vector2(180,0),0,false,{})
	for actor in [a,b]: actor.max_hp = 1000000; actor.current_hp = 1000000; actor.set_physics_process(false)
	await physics_frame
	# Broad grid candidates outside a splash circle must remain untouched.
	var data := GROWTH.resolve("ranged_rookie_arcane_bolt",DATA.WEAPONS.ranged_rookie_arcane_bolt,10,true)
	relocate(b,a.position+Vector2(111,0)); await physics_frame
	runtime._splash(a.position,100,110,a,data)
	check(a.current_hp == 1000000 and b.current_hp == 1000000,"splash excludes primary and radius+1")
	relocate(b,a.position+Vector2(109,0)); await physics_frame
	runtime._splash(a.position,100,110,a,data)
	check(b.current_hp == 999900,"splash includes radius-1 and cannot recurse")
	# Pulse delay, exact footprint and fixed saturation without node allocation.
	for actor in [a,b]: actor.current_hp = 1000000
	data = GROWTH.resolve("ranged_rookie_pulse_staff",DATA.WEAPONS.ranged_rookie_pulse_staff,10,true)
	runtime._after_cast(data,a.position,Vector2.RIGHT,a,100,100,10)
	runtime._tick_pulses(0.1); check(a.current_hp == 1000000,"secondary pulse waits for delay")
	runtime._tick_pulses(0.15); check(a.current_hp == 999935 and b.current_hp == 1000000,"secondary pulse exact radius and ratio")
	var nodes: int = battle.get_child_count()
	for index in 30: runtime._after_cast(data,a.position,Vector2.RIGHT,a,100,100,10)
	var active := 0
	for pulse in runtime.pulses:
		if pulse.active: active += 1
	check(active == 24 and battle.get_child_count() == nodes,"secondary pulse saturation stays fixed")
	# Overlapping fan rays hit once, and all rays share the rendered geometry.
	reset(runtime,hero); runtime.scratch.clear(); runtime.scratch.append(a)
	a.current_hp = 1000000; relocate(a,hero.position+Vector2(50,0))
	data = GROWTH.resolve("purifier_hero_holy_lance",DATA.WEAPONS.purifier_hero_holy_lance,10,true)
	runtime._cast_fan(data,hero.position,Vector2.RIGHT,500,10,100)
	check(a.current_hp == 999900,"overlapping five-ray fan hits one actor once")
	# Final shot explodes only on the last live, actually landed shot.
	a.current_hp = 1000000; b.current_hp = 1000000; relocate(b,a.position+Vector2(80,0)); await physics_frame
	data = GROWTH.resolve("pistol_hero_revolver",DATA.WEAPONS.pistol_hero_revolver,10,true)
	var shot := {"data":data,"finisher":false,"damage":100}
	runtime._finish_shot(shot,a); check(a.current_hp == 1000000,"non-final shot has no finisher")
	shot.finisher = true; runtime._finish_shot(shot,a)
	check(a.current_hp == 999850 and b.current_hp == 999850,"final shot applies real 150% explosion")
	# Chain escalation uses sequential struck count, not a cosmetic tooltip.
	reset(runtime,hero); runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.evolved.clear(); runtime.add("ranged_rookie_star_wand")
	runtime.levels.ranged_rookie_star_wand = 10
	a.current_hp = 1000000; b.current_hp = 1000000
	runtime._cast("ranged_rookie_star_wand")
	check(1000000-b.current_hp > 1000000-a.current_hp,"later chain receives escalation")
	battle.queue_free(); await process_frame

func presentation() -> void:
	var capture: bool = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var unlocks := ConfigFile.new(); unlocks.set_value("hard_cleared","stage_7",true)
	SCOPE.save_config(unlocks,"user://stage_progress.cfg")
	var stamina := preload("res://src/systems/stamina_store.gd")
	var paid := stamina.try_enter("stage_1",true,-1,false)
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"chemical_hero","hero_entry":paid})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(scene)
	if not scene.entry_ready: await scene.entry_started
	scene._pause()
	check(is_instance_valid(scene.battle),"isolated unlocked visual fixture enters HeroMode")
	if not is_instance_valid(scene.battle): scene.queue_free(); return
	var runtime = scene.battle.hero.player_weapons
	var id := "chemical_hero_acid_vial"
	while int(runtime.levels[id]) < 10: runtime.add(id)
	scene._show_choices([{"id":id,"name":"산성 약병 Lv.10","description":DATA.description(id,10)},{"id":"chemical_hero_life_elixir","name":"현자의 비약 Lv.6","description":DATA.description("chemical_hero_life_elixir",6)},{"id":"sage_astra_absolute_zero","name":"빙점폭발 Lv.10","description":DATA.description("sage_astra_absolute_zero",10)}])
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("again-hero-weapon-growth-cards.png"))
	scene.choosing = false; scene.pending_chests = 1; scene._begin_roulette(); scene.roulette_tween.kill(); scene._finish_roulette()
	await process_frame
	check(scene.overlay.size.y <= 640 and scene.overlay.get_global_rect().encloses(scene.roulette_reel.get_global_rect()),"evolved description and reel fit actual rendered modal")
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("again-hero-weapon-growth-evolution.png"))
	for weapon_id in DATA.WEAPONS:
		runtime.weapon_ids.clear(); runtime.weapon_ids.append(String(weapon_id)); runtime.levels.clear(); runtime.levels[weapon_id] = 10; runtime.evolved.clear()
		scene.pending_chests = 1; scene._begin_roulette(); scene.roulette_tween.kill(); scene._finish_roulette(); await process_frame
		check(scene.overlay.size.y <= 640 and scene.overlay.get_global_rect().encloses(scene.roulette_reel.get_global_rect()),"all sixty evolved receipts fit modal "+String(weapon_id))
	scene.queue_free(); await process_frame
