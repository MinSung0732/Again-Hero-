extends RefCounted
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const MAP_ASSAULT := preload("res://src/data/hero_map_assault_catalog.gd")
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
var reinforcements_installed := false
var preferred: Array = []
var plan := "탐색 공세 · 용사 빌드를 관찰 중"
func install(host) -> void:
	battle = host
	reinforcements_installed = false
	stage_number = int(battle.current_stage_data.get("number",1))
	population_limit = DATA.monster_limit(stage_number)
	supply_scale = DATA.pacing_value("supply",stage_number,battle.campaign_difficulty)
	pressure = DATA.stage_pressure(stage_number)*(1.2 if battle.campaign_difficulty == "hard" else 1.0)
	roster = DATA.roster_for(stage_number,battle.campaign_difficulty)
	encounters = preload("res://src/hero_mode/hero_encounter_runtime.gd").new(); battle.add_child(encounters); encounters.install(battle)
	battle.set_allowed_monster_ids(roster)
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
	if encounters.finale: plan = encounters.notice; return
	observation_remaining -= delta
	if observation_remaining <= 0.0:
		observation_remaining = DATA.OBSERVE_INTERVAL
		_observe()
	var elapsed: float = battle.run_metrics.elapsed_seconds
	if not reinforcements_installed and elapsed >= 300.0:
		reinforcements_installed = true
		for id in DATA.late_recruits(stage_number,battle.campaign_difficulty,elapsed):
			if id not in roster: roster.append(id)
		battle.set_allowed_monster_ids(roster)
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
