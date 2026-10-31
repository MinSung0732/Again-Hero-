extends RefCounted
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const MAP_ASSAULT := preload("res://src/data/hero_map_assault_catalog.gd")
const FRONTIER_MONSTERS := preload("res://src/data/frontier_monster_catalog.gd")
const MONSTER_VISUAL := preload("res://src/monsters/monster_visual.gd")
const GUMIHO_VISUAL := preload("res://src/data/gumiho_behavior_catalog.gd")
const BOSS_VISUAL_PREWARM := preload("res://src/hero_mode/hero_boss_visual_prewarm.gd")
# Keep late recruit scenes ready without loading a whole wave on its unlock frame.
const RECRUIT_PREWARM_LEAD := 20.0
const RECRUIT_PREWARM_INTERVAL := 0.5
const RECRUIT_THREAD_LEAD := 30.0
const RECRUIT_THREAD_INTERVAL := 0.5
var prewarm_entries: Array[Dictionary] = []
var prewarm_index := 0
var prewarm_next_at := 0.0
var thread_index := 0
var thread_next_at := 0.0
var boss_visual_prewarm
var spawn_sequence := 0
var encounters
var battle
var think_remaining := 0.0
var observation_remaining := 0.0
var rotation := 0
var next_elite := DATA.ELITE_FIRST
var giant_index := 0
var special_retry := 0.0
var stage_number := 1
var pressure := 1.0
var supply_scale := 1.0
var population_limit := DATA.MONSTER_LIMIT
var roster: Array = []
var reinforcement_times: Array[float] = []
var next_reinforcement := 0
var preferred: Array = []
var plan := "탐색 공세 · 용사 빌드를 관찰 중"
func install(host) -> void:
	battle = host
	reinforcement_times.clear()
	next_reinforcement = 0
	prewarm_entries.clear()
	prewarm_index = 0
	prewarm_next_at = 0.0
	thread_index = 0
	thread_next_at = 0.0
	stage_number = int(battle.current_stage_data.get("number",1))
	boss_visual_prewarm = null
	# Stage-specific boss choice is deterministic. Prepare no unneeded fox art.
	if DATA.boss_for(stage_number,battle.campaign_difficulty) == "gumiho":
		boss_visual_prewarm = BOSS_VISUAL_PREWARM.new()
		boss_visual_prewarm.configure(GUMIHO_VISUAL.FOX_VISUAL,DATA.DURATION)
	population_limit = DATA.monster_limit(stage_number)
	supply_scale = DATA.pacing_value("supply",stage_number,battle.campaign_difficulty)
	pressure = DATA.stage_pressure(stage_number)*(1.2 if battle.campaign_difficulty == "hard" else 1.0)
	roster = DATA.roster_for(stage_number,battle.campaign_difficulty)
	# Build checkpoints once; no catalog scan or temporary array on ordinary ticks.
	for id in DATA.MONSTERS.ORDER:
		var data: Dictionary = DATA.MONSTERS.MONSTERS[id]
		if data.has("hero_survival_after") and DATA.monster_allowed(id,stage_number,battle.campaign_difficulty):
			var at := float(data.hero_survival_after)
			if at not in reinforcement_times: reinforcement_times.append(at)
			if id not in roster: prewarm_entries.append({"id":String(id),"at":at})
	reinforcement_times.sort()
	prewarm_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.at) < float(b.at) if not is_equal_approx(float(a.at),float(b.at)) else String(a.id) < String(b.id)
	)
	encounters = preload("res://src/hero_mode/hero_encounter_runtime.gd").new(); battle.add_child(encounters); encounters.install(battle)
	var warm_started := Time.get_ticks_usec() if _profiling_enabled() else 0
	battle.set_allowed_monster_ids(roster)
	if warm_started > 0:
		print("[HeroPerf] initial_roster_warm_ms=%.2f roster=%d" % [float(Time.get_ticks_usec()-warm_started)/1000.0,roster.size()])
func _profiling_enabled() -> bool:
	var profile = battle.get("combat_profile")
	return profile != null and bool(profile.get("enabled"))

# Start scene loading in a worker thread before the regular warmup window.
# Never retrieve an unfinished threaded resource on the main thread.
func _request_pending_recruits(elapsed: float) -> void:
	if thread_index >= prewarm_entries.size() or elapsed < thread_next_at: return
	var entry: Dictionary = prewarm_entries[thread_index]
	if elapsed < float(entry.at)-RECRUIT_THREAD_LEAD: return
	thread_index += 1
	thread_next_at = elapsed+RECRUIT_THREAD_INTERVAL
	var monster_id := String(entry.id)
	if DATA.MONSTERS.scene_cache.has(monster_id): return
	var path := String(DATA.MONSTERS.MONSTERS[monster_id].get("scene_path",""))
	if path.is_empty(): return
	var started := Time.get_ticks_usec() if _profiling_enabled() else 0
	if ResourceLoader.load_threaded_request(path,"PackedScene",false) == OK:
		entry["thread_path"] = path
	if started > 0:
		print("[HeroPerf] thread_request_ms=%.2f elapsed=%.1f id=%s" % [
			float(Time.get_ticks_usec()-started)/1000.0,elapsed,monster_id
		])

# Only PackedScene resources are prepared early. Spawn eligibility and roster unlock
# still change exclusively on the original authored reinforcement checkpoint.
func _warm_recruit_normal_visual(monster_id: String, elapsed: float) -> void:
	# PackedScene loading does not create the per-species SpriteFrames cache.
	# Prepare only the observed normal variant to bound mobile memory growth.
	if not FRONTIER_MONSTERS.DEFINITIONS.has(monster_id): return
	var visual_data: Dictionary = FRONTIER_MONSTERS.DEFINITIONS[monster_id]
	var started := Time.get_ticks_usec() if _profiling_enabled() else 0
	var visual = MONSTER_VISUAL.new()
	var ready: bool = visual.apply_visual_profile(visual_data.normal_visual)
	visual.free()
	if started > 0:
		print("[HeroPerf] visual_prewarm_ms=%.2f elapsed=%.1f monster=%s success=%s" % [
			float(Time.get_ticks_usec()-started)/1000.0,elapsed,monster_id,str(ready)
		])

func _prewarm_pending_recruits(elapsed: float) -> void:
	if prewarm_index >= prewarm_entries.size() or elapsed < prewarm_next_at: return
	var entry: Dictionary = prewarm_entries[prewarm_index]
	if elapsed < float(entry.at)-RECRUIT_PREWARM_LEAD: return
	var thread_path := String(entry.get("thread_path",""))
	var threaded_scene: PackedScene # Keep a strong ref through warm_scenes().
	if not thread_path.is_empty():
		var status := ResourceLoader.load_threaded_get_status(thread_path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and elapsed < float(entry.at):
			return # A late worker may finish on the next tick; avoid a blocking get.
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Retain the loaded resource until the normal scene cache pins it.
			threaded_scene = ResourceLoader.load_threaded_get(thread_path) as PackedScene
			if threaded_scene == null: push_warning("Hero recruit threaded scene missing: "+thread_path)
	prewarm_index += 1
	prewarm_next_at = elapsed+RECRUIT_PREWARM_INTERVAL
	var started := Time.get_ticks_usec() if _profiling_enabled() else 0
	DATA.MONSTERS.warm_scenes([String(entry.id)],battle.get_instance_id())
	if started > 0:
		print("[HeroPerf] prewarm_scene_ms=%.2f elapsed=%.1f unlock=%.1f id=%s" % [
			float(Time.get_ticks_usec()-started)/1000.0,elapsed,float(entry.at),String(entry.id)
		])
	_warm_recruit_normal_visual(String(entry.id),elapsed)

func _observe() -> void:
	preferred.clear()
	plan = "탐색 공세 · 여러 역할로 압박"
	var tags: Dictionary = battle.hero.player_weapons.build_tags() if battle.hero.player_weapons != null else AUGMENTS.get_build_tag_counts(battle.hero.build_counts)
	for tag in DATA.COUNTERS:
		if int(tags.get(tag,0)) > 0:
			preferred = DATA.COUNTERS[tag].duplicate()
			plan = "빌드 관측 · "+AUGMENTS.get_tag_label(tag)+"에 대응하는 공세"
			break
	plan += " · "+String(MAP_ASSAULT.NAMES[MAP_ASSAULT.plan_at(float(battle.run_metrics.elapsed_seconds),stage_number)])
func _select_ai_reward() -> bool:
	if battle.demon_augment_selection_active:
		var candidates: Array = battle.demon_augment_candidates
		if not candidates.is_empty():
			battle.choose_demon_augment(String(candidates[randi_range(0,candidates.size()-1)].get("id","")))
		return true
	if battle.mutation_director.is_active():
		var candidates: Array = battle.mutation_director.get_candidates()
		if not candidates.is_empty(): battle.try_choose_mutation(String(candidates[randi_range(0,candidates.size()-1)]))
		return true
	return false
func tick(delta: float) -> void:
	if battle.battle_over or battle.external_pause or not is_instance_valid(battle.hero): return
	if _select_ai_reward() or battle.is_combat_simulation_paused(): return
	encounters.tick(delta)
	var elapsed: float = battle.run_metrics.elapsed_seconds
	if boss_visual_prewarm != null and not boss_visual_prewarm.finished:
		boss_visual_prewarm.tick(elapsed,_profiling_enabled())
	if encounters.finale: plan = encounters.notice; return
	observation_remaining -= delta
	if observation_remaining <= 0.0:
		observation_remaining = DATA.OBSERVE_INTERVAL
		_observe()
	_request_pending_recruits(elapsed)
	_prewarm_pending_recruits(elapsed)
	if next_reinforcement < reinforcement_times.size() and elapsed >= reinforcement_times[next_reinforcement]:
		while next_reinforcement < reinforcement_times.size() and elapsed >= reinforcement_times[next_reinforcement]:
			next_reinforcement += 1
		var roster_changed := false
		for id in DATA.late_recruits(stage_number,battle.campaign_difficulty,elapsed):
			if id not in roster:
				roster.append(id)
				roster_changed = true
		if roster_changed:
			var warm_started := Time.get_ticks_usec() if _profiling_enabled() else 0
			battle.set_allowed_monster_ids(roster)
			if warm_started > 0:
				print("[HeroPerf] reinforcement_warm_ms=%.2f elapsed=%.1f roster=%d" % [
					float(Time.get_ticks_usec()-warm_started)/1000.0,elapsed,roster.size()
				])
	var phase: Dictionary = DATA.phase_at(elapsed)
	battle.command_regen_per_second = float(phase.regen)*pressure*supply_scale
	special_retry = maxf(0.0,special_retry-delta)
	# Telegraph waves may temporarily exceed the ordinary phase cap. Keep the
	# reserved special slot usable while still respecting the global actor cap.
	if special_retry <= 0.0 and battle.get_population_count() < population_limit:
		if giant_index < DATA.GIANT_TIMES.size() and elapsed >= float(DATA.GIANT_TIMES[giant_index]):
			if _special("ogre",true,elapsed): giant_index += 1
			special_retry = 5.0
		elif elapsed >= next_elite:
			if _special("orc" if rotation%2 == 0 else "skeleton_archer",false,elapsed): next_elite += DATA.ELITE_INTERVAL/pressure
			special_retry = 5.0
	think_remaining -= delta
	if think_remaining > 0.0: return
	think_remaining = float(phase.interval)/(pressure*supply_scale)
	var available := mini(roster.size(),int(phase.roster)+(maxi(0,roster.size()-7) if elapsed >= 300 else 0))
	for index in range(int(phase.batch)):
		if battle.get_population_count() >= mini(population_limit,int(phase.limit*pressure*supply_scale))-2: break
		var id := String(roster[rotation%available])
		rotation += 1
		if elapsed > 25.0 and not preferred.is_empty() and randf() < 0.55:
			var counter := String(preferred[rotation%preferred.size()])
			if counter in roster: id = counter
		if battle.command_power >= battle.get_monster_cost(id): _summon_on_map(id,elapsed)

func _summon_on_map(id: String,elapsed: float) -> bool:
	if battle.has_method("hero_spawn_candidate"):
		id = battle.hero_spawn_candidate(id,roster,false)
		if id.is_empty() or battle.command_power < battle.get_monster_cost(id): return false
	var pattern := MAP_ASSAULT.plan_at(elapsed,stage_number)
	# Bounded retries avoid edge clamping beside the hero. No enemy relocation.
	for attempt in 8:
		spawn_sequence += 1
		var point := MAP_ASSAULT.point(pattern,spawn_sequence,battle.hero.position,battle.hero.player_move_input,battle.current_map_size)
		point = battle._clamp_manual_spawn_position(point)
		if point.distance_squared_to(battle.hero.position) < MAP_ASSAULT.MIN_DISTANCE*MAP_ASSAULT.MIN_DISTANCE: continue
		return battle.try_summon_at_position(id,point)
	return false

func _special(id: String,giant: bool,elapsed: float) -> bool:
	if id not in roster or not bool(DATA.MONSTERS.get_monster(id).get("can_be_elite",true)): id = DATA.boss_for(stage_number,battle.campaign_difficulty)
	var scale := (1.0+elapsed/900.0)*pressure
	return battle.spawn_special_monster(id,{"type":"giant" if giant else "elite","name":"대형 군단장" if giant else "엘리트 공세","hp_multiplier":(4.0 if giant else 2.0)*scale,"damage_multiplier":1.2*scale,"speed_multiplier":0.75 if giant else 1.1,"attack_speed_multiplier":1.0,"exp_multiplier":4.0 if giant else 2.0,"visual_scale":1.8 if giant else 1.2,"spawn_distance":DATA.OPENING_ELITE_DISTANCE if not giant and next_elite == DATA.ELITE_FIRST else 650.0})
