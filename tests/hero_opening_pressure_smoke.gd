extends SceneTree
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
const BASE := preload("res://tests/hero_encounters_smoke.gd")
var checks := 0
var failures := 0
class Hero extends BASE.Actor:
	var player_weapons = null
	var build_counts := {}
	var player_move_input := Vector2.RIGHT
class Mutation extends RefCounted:
	func is_active() -> bool: return false
class Arena extends BASE.Arena:
	var command_power := 10000.0
	var command_regen_per_second := 0.0
	var demon_augment_selection_active := false
	var demon_augment_candidates: Array = []
	var mutation_director := Mutation.new()
	var population := 0
	var specials: Array = []
	var normal: Array = []
	func set_allowed_monster_ids(_ids: Array) -> void: pass
	func is_combat_simulation_paused() -> bool: return false
	func get_population_count() -> int: return population
	func get_monster_cost(_id: String) -> float: return 1.0
	var normal_points: Array[Vector2] = []
	func try_summon_at_position(id: String,point: Vector2) -> bool:
		normal.append(id); normal_points.append(point); population += 1; return true
	func spawn_special_monster(id: String, data: Dictionary) -> bool:
		specials.append({"id":id,"data":data,"time":run_metrics.elapsed_seconds}); return true
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	for stage in range(1,11):
		check(DATA.monster_limit(stage) == 144+8*(stage-1),"stage population progression")
	check(DATA.monster_limit(-1) == 144 and DATA.monster_limit(99) == 216,"bounded stage cap")
	for stat in ["hp","damage","speed"]:
		var previous := 0.0
		for tick in range(901):
			var value := DATA.monster_multiplier(stat,tick)
			check(value >= previous and is_finite(value),"monotonic finite "+stat)
			previous = value
		for knot in DATA.MONSTER_GROWTH:
			check(absf(DATA.monster_multiplier(stat,knot.time+0.001)-DATA.monster_multiplier(stat,knot.time-0.001)) < 0.001,"no growth discontinuity")
	for tick in range(901):
		# Compare HP/damage against the pre-patch continuous budget.
		var times := [0.0,30.0,120.0,300.0,600.0,900.0]
		var hp := [0.18,0.18,0.85,2.80,6.00,10.00]
		var damage := [0.45,0.45,0.65,0.95,1.30,1.70]
		for i in range(1,times.size()):
			if tick > times[i]: continue
			var ratio: float = (tick-times[i-1])/(times[i]-times[i-1])
			check(is_equal_approx(DATA.monster_multiplier("hp",tick),lerpf(hp[i-1],hp[i],ratio)),"HP budget unchanged")
			check(is_equal_approx(DATA.monster_multiplier("damage",tick),lerpf(damage[i-1],damage[i],ratio)),"damage budget unchanged")
			break
	check(DATA.monster_multiplier("speed",40)/DATA.monster_multiplier("speed",0) >= 1.3,"noticeable first40 pursuit increase")
	check(DATA.phase_at(39).roster == 3 and DATA.phase_at(40).roster == 5,"early role transition")
	check(DATA.opening_objective(0,false,24).begins_with("첫 포위"),"near opening goal")
	check(DATA.opening_objective(30,false,64).begins_with("첫 정예"),"30sec elite goal")
	check(DATA.opening_objective(40,false,64).contains("강화 상자"),"reward objective before claim")
	check(DATA.opening_objective(40,true,64).contains("24초"),"claimed reward advances countdown")
	check(DATA.opening_objective(120,false,144).is_empty(),"normal timer restores")
	for difficulty in ["easy","hard"]:
		for stage in [1,10]:
			var arena := Arena.new(); root.add_child(arena)
			arena.current_stage_data.number = stage; arena.campaign_difficulty = difficulty
			arena.hero = Hero.new(); arena.add_child(arena.hero); arena.hero.position = Vector2(1200,1200)
			var director := DIRECTOR.new(); director.install(arena)
			for tick in range(401):
				arena.run_metrics.elapsed_seconds = float(tick)*0.1
				if tick >= 340: arena.population = 44 # Ordinary cap full after a telegraphed wave.
				var before := arena.spawned.size(); director.tick(0.1)
				check(arena.spawned.size()-before <= 4,"bounded opening event batch")
				if tick == 240: check(director.encounters.warning > 0 and arena.spawned.is_empty(),"24s warning before any event spawn")
			check(not arena.spawned.is_empty(),"encounter reaches opening40")
			check(not arena.normal_points.is_empty(),"normal director uses explicit map positions")
			for point in arena.normal_points:
				check(point.distance_to(arena.hero.position) >= 360.0,"normal spawn safety distance")
			check(arena.specials.size() == 1 and arena.specials[0].time >= 35 and arena.specials[0].time <= 35.1,"first elite at35 across stages/difficulties")
			check(arena.specials[0].data.spawn_distance == DATA.OPENING_ELITE_DISTANCE,"opening elite closes travel distance")
			check(DATA.monster_allowed(arena.specials[0].id,stage,difficulty),"elite respects grade")
			var before := arena.normal.size(); arena.external_pause = true; director.tick(100)
			check(arena.normal.size() == before,"paused director freezes schedule")
			arena.external_pause = false; arena.population = DATA.monster_limit(stage)
			arena.run_metrics.elapsed_seconds = director.next_elite
			director.tick(1)
			check(arena.specials.size() == 1 and arena.normal.size() == before,"population saturation cannot bypass caps")
			arena.queue_free(); await process_frame
	print("HERO_OPENING_PRESSURE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
