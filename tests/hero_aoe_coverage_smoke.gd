extends SceneTree
const FIXTURE := preload("res://tests/hero_presentation_range_smoke.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("AOE_COVERAGE: "+label)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var arena := FIXTURE.Arena.new(); root.add_child(arena)
	var fighter := FIXTURE.Fighter.new(); arena.add_child(fighter)
	for index in 74:
		var target := FIXTURE.Target.new(); arena.add_child(target); arena.actors.append(target)
	for id in DATA.WEAPONS:
		var pattern := String(DATA.WEAPONS[id].pattern)
		if pattern not in ["slash","beam","orbit","nova","frost","guard","heal","poison"]: continue
		# Persistent delivery emitters (2026-10-15) resolve over time; covered below with the
		# real Battle grid and by hero_survival_variety/hero_weapon_remake.
		if not RUNTIME.DELIVERY.RULES.spec(String(id),DATA.WEAPONS[id]).is_empty(): continue
		for rank in [1,10]:
			for evolution in [false,true]:
				fighter.hero_id = String(DATA.WEAPONS[id].owner)
				var runtime := RUNTIME.new(); runtime.install(fighter)
				runtime.weapon_ids.clear(); runtime.weapon_ids.append(id); runtime.levels[id] = rank; runtime.cooldowns[id] = 999.0
				if evolution: runtime.evolved[id] = true
				var stats := runtime.stats_for(id)
				var reach := GEOMETRY.reach(stats,rank,evolution)
				var center := Vector2(reach*float(stats.get("orbit_ratio",0.7)) if pattern == "orbit" else reach*0.25,0)
				for index in 72:
					var actor = arena.actors[index]; actor.current_hp = 1000000; actor.position = center+Vector2(index*0.01,0)
				var outside = arena.actors[72]; outside.current_hp = 1000000
				outside.position = center+Vector2(reach*float(stats.get("field_radius_ratio",0.45))+1,0) if pattern == "poison" else Vector2(reach+1,0)
				var hidden = arena.actors[73]; hidden.position = center; hidden.current_hp = 1000000; hidden.set_meta("hero_detection_hidden",true)
				runtime._cast(id)
				if pattern == "poison": runtime.tick(0.01)
				var hit_count := 0
				for index in 72:
					if arena.actors[index].current_hp < 1000000: hit_count += 1
				check(hit_count == 72,"all 72 inside "+id+" rank="+str(rank)+" evolution="+str(evolution)+" hit="+str(hit_count))
				check(outside.current_hp == 1000000,"outside rejected: "+id)
				check(hidden.current_hp == 1000000,"hidden rejected: "+id)
	# Follow-up pulses and impact explosions also cover the whole displayed circle.
	fighter.hero_id = "ranged_rookie"
	var runtime := RUNTIME.new(); runtime.install(fighter)
	for index in 72: arena.actors[index].current_hp = 1000000; arena.actors[index].position = Vector2(50+index*0.01,0)
	arena.actors[72].position = Vector2(101,0)
	runtime._splash(Vector2.ZERO,100,100,arena.actors[0],{"color":"85dcff"})
	for index in 72: check(arena.actors[index].current_hp == (1000000 if index == 0 else 999900),"impact explosion covers every eligible actor")
	for index in 72: arena.actors[index].current_hp = 1000000
	var pulse: Dictionary = runtime.pulses[0]; pulse.active = true; pulse.left = 0.0; pulse.origin = Vector2.ZERO; pulse.direction = Vector2.RIGHT; pulse.radius = 100.0; pulse.damage = 100; pulse.rank = 1; pulse.data = {"color":"85dcff"}
	runtime._tick_pulses(0.01)
	for index in 72: check(arena.actors[index].current_hp == 999900,"follow-up pulse covers every eligible actor")
	check(arena.actors[72].current_hp == 1000000 and arena.actors[73].current_hp == 1000000,"secondary attacks preserve outside/hidden filters")
	# Targeted chain still has the authored count; area fixes do not add shots.
	for index in 72: arena.actors[index].current_hp = 1000000
	runtime.levels["ranged_rookie_star_wand"] = 1
	runtime._cast("ranged_rookie_star_wand")
	var chained := 0
	for index in 72:
		if arena.actors[index].current_hp < 1000000: chained += 1
	check(chained == int(DATA.WEAPONS.ranged_rookie_star_wand.base_hits),"targeted chain retains its authored count")
	arena.queue_free(); await process_frame
	# Real Battle registry/grid and real Hero: a crowded delivery sigil receives all hits.
	# Since 2026-10-15 rune_ring is a fixed sigil emitter (warning, then interval ticks).
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"; root.add_child(battle); battle.set_external_pause(true)
	var hero = battle.hero; var actual = hero.player_weapons
	var id := "ranged_rookie_rune_ring"
	check(actual.add(id),"actual hero learns the sigil field")
	var stats: Dictionary = actual.stats_for(id)
	var radius: float = clampf(GEOMETRY.reach(stats,1,false)*0.32,45.0,180.0)
	var targets: Array = []
	for index in 72:
		var actor = battle._spawn_monster("slime",hero.position+Vector2(radius*0.7+index*0.01,0),0.0,false,{})
		if is_instance_valid(actor):
			actor.set_physics_process(false); actor.max_hp = 1000000; actor.current_hp = 1000000; targets.append(actor)
	check(targets.size() == 72,"72 actual actors registered")
	await physics_frame
	actual._cast(id)
	var sigil: Dictionary = {}
	for slot in actual.delivery.slots:
		if slot.id == id and float(slot.left) > 0.0: sigil = slot
	check(not sigil.is_empty() and is_equal_approx(float(sigil.radius),radius),"sigil footprint uses delivery radius")
	actual.tick(float(sigil.get("warning",0.0))+0.01,false); actual.tick(0.01,false)
	for actor in targets: check(actor.current_hp < 1000000,"real grid field includes every crowded actor")
	battle.queue_free(); await process_frame
	print("HERO_AOE_COVERAGE_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
