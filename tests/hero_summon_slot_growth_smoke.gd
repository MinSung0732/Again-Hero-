extends SceneTree
const H := preload("res://tests/hero_summon_growth_smoke.gd")
const SHARED := preload("res://src/hero/hero_summoner_runtime.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func clear_summons(hero) -> void:
	for row in H.CASES.values():
		for actor in hero.get("summoner_"+String(row[0])+"_pool"):
			if actor.active: actor.deactivate()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var b = load("res://src/battle/Battle.tscn").instantiate()
	b.hero_player_mode = true; b.hero_player_stage = "stage_8"; b.hero_player_hero_id = "summoner_hero"
	b._monster_spawn_resources_warmed = true; root.add_child(b); b.set_external_pause(true)
	await process_frame
	var hero = b.hero; var r = hero.player_weapons
	# Slot logic only: repeated play/stop on a paused MP3 leaves dummy-driver
	# playback references at shutdown. Audio behavior has separate smoke tests.
	hero.level_up_audio.stop(); hero.level_up_audio.stream = null
	# Follow the real level-up entry point, including pool growth at each milestone.
	for rank in range(1,31):
		if rank > 1: hero._level_up()
		hero.player_augment_candidates.clear()
		var expected := 3+SHARED.get_level_slot_bonus(rank)
		check(hero.level == rank and hero._get_summoner_slot_capacity() == expected,"level "+str(rank)+" shared slot growth")
		check(r.native_skills.summon_capacity() == expected,"native cap agrees with Hero at "+str(rank))
		if rank % 5 != 0: continue
		var before_nodes: int = b.get_child_count()
		var pools: int = hero.summoner_hound_pool.size()
		check(pools >= expected+hero.SUMMONER_POOL_HEADROOM,"milestone expands actual pool at "+str(rank))
		for index in expected+2: r._cast("summoner_hero_gate_hound")
		check(hero._get_active_summon_count() == expected,"real casts fill grown slots at "+str(rank))
		check(b.get_child_count() == before_nodes and hero.summoner_hound_pool.size() == pools,"casts use prepared pool at "+str(rank))
		clear_summons(hero)
	# Lower baseline for the kind-reservation regression. Pool keeps its capacity.
	hero.level = 4
	for index in 3: r._cast("summoner_hero_gate_hound")
	check(r.add("summoner_hero_gatekeeper"),"learn gatekeeper after slots are occupied")
	r._cast("summoner_hero_gatekeeper")
	check(hero.summoner_active_gatekeepers == 1 and hero._get_active_summon_count() == 3,"gatekeeper still replaces a duplicate")
	check(r.add("summoner_hero_scout") and r.add("summoner_hero_watcher"),"learn all four kinds")
	r._cast("summoner_hero_scout"); r._cast("summoner_hero_watcher")
	check(hero._get_summoner_slot_capacity() == 4 and hero._get_active_summon_count() == 4,"four kinds retain guaranteed places")
	for rank in [5,10,15,20,25,30]:
		hero.level = rank-1; hero._level_up(); hero.player_augment_candidates.clear()
		var expected := 4+SHARED.get_level_slot_bonus(rank)
		check(hero._get_summoner_slot_capacity() == expected,"four-kind base also gains milestone at "+str(rank))
		for index in expected: r._cast("summoner_hero_gate_hound")
		check(hero._get_active_summon_count() == expected,"all kinds plus extra hounds fill "+str(expected)+" slots")
		check(hero.summoner_active_gatekeepers >= 1 and hero.summoner_active_scouts >= 1 and hero.summoner_active_watchers >= 1,"extra copies preserve other kinds")
	# Explicit slot bonuses remain additive with level and kind minimum.
	hero.summoner_slot_bonus = 2; hero._ensure_summoner_pool_capacity()
	check(hero._get_summoner_slot_capacity() == 12,"level30 plus four kinds plus two extra slots")
	for index in 4: r._cast("summoner_hero_gate_hound")
	check(hero._get_active_summon_count() == 12,"explicit bonus also affects real casting")
	clear_summons(hero)
	# AI continues to use its original base and the same five-level rule.
	hero.player_controlled = false; hero.summoner_slot_base = 5; hero.summoner_slot_bonus = 0
	for rank in [1,4,5,9,10,15,20]:
		hero.level = rank
		check(hero._get_summoner_slot_capacity() == 5+SHARED.get_level_slot_bonus(rank),"AI original level growth at "+str(rank))
	stop_audio(b); stop_audio(root.get_node("GameAudio")); b.queue_free(); await process_frame
	print("HERO_SUMMON_SLOT_GROWTH checks=",checks," failures=",failures)
	quit(1 if failures else 0)
