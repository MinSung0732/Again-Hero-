extends SceneTree
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const TEAM := preload("res://src/systems/team_loadout_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BULGASAL_INTEGRATION: "+message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled=false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active=false
	SCOPE.guest_directory="user://bulgasal_integration_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	check(not COLLECTION.is_unlocked("bulgasal"),"fresh collection locked")
	check(not LOADOUT.save_id("bulgasal"),"locked registration rejected")
	var rolls: Array = []
	for index in range(11):
		rolls.append({"monster_id":"bulgasal" if index in [0,5,10] else "slime","source":"pickup","rarity":"transcendent" if index in [0,5,10] else "common","shards":1})
	var progress := ConfigFile.new()
	progress.set_value("meta","gold",1000)
	check(SCOPE.save_config(progress,COLLECTION.PROGRESS_PATH)==OK,"isolated gold setup")
	var award := COLLECTION.award_shard_batch(rolls,1000)
	check(award.success and award.awards.size()==11,"atomic 10+1 reward")
	check(award.state.bulgasal.unlocked and award.state.bulgasal.shards==2,"first unlock then two duplicate shards")
	check(SCOPE.load_config(progress,COLLECTION.PROGRESS_PATH)==OK and int(progress.get_value("meta","gold"))==0,"exact1000 paid once")
	check("bulgasal" in COSMETICS.choices("avatar") and "bulgasal" in COSMETICS.choices("banner"),"unlock awards existing icon/banner")
	check(COSMETICS.select("avatar","bulgasal") and COSMETICS.select("banner","bulgasal"),"cosmetic selection")
	check(COSMETICS.selected_id("avatar")=="bulgasal" and COSMETICS.selected_id("banner")=="bulgasal","cosmetics persist")
	check(LOADOUT.save_id("bulgasal") and LOADOUT.load_id()=="bulgasal","transcendence registration persists")
	check(not TEAM.save_ids(["bulgasal"],CATALOG.ORDER),"ordinary team excludes transcendent")
	var save_before := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg"))
	var gold_before := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg"))
	var overlay = OVERLAY.new()
	root.add_child(overlay)
	overlay.present(rolls)
	overlay._sequence_token+=1 # Skip door animation, retain real dispatch.
	overlay._show_reveal(0)
	var seen: Array[int]=[]
	for index in range(11):
		check(overlay._reveal_index==index,"ordered reveal "+str(index))
		if index in [0,5,10]:
			seen.append(index)
			check(overlay._phase=="cutscene" and overlay._cutscene._running,"Bulgasal dispatch")
			overlay._cutscene.set_process(false)
			if index==5: overlay._cutscene.skip()
			else: overlay._cutscene.advance(5)
			check(overlay._phase=="reveal" and overlay._reveal_index==index,"normal/skip returns same reward")
		overlay._advance_reveal()
	check(seen==[0,5,10],"multiple wins order")
	check(FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg"))==save_before and FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg"))==gold_before,"presentation cannot award or charge again")
	overlay.queue_free()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	battle.hero.set_physics_process(false)
	battle.hero.position=Vector2(1200,1000)
	battle.hero.max_hp=100000
	battle.hero.current_hp=100000
	battle.command_power=9999
	battle.demon_exp_to_next_level=1000000
	check(battle.transcendence.monster_id=="bulgasal" and not battle.transcendence.ready,"registered real battle begins locked")
	var tank_id := ""
	for id in CATALOG.ORDER:
		if CATALOG.get_role(id)=="tank" and CATALOG.get_rarity(id)!="transcendent":
			tank_id=id
			break
	check(not tank_id.is_empty(),"existing tank available")
	var generated = battle._spawn_monster(tank_id,Vector2(400,400))
	generated.set_physics_process(false)
	check(battle.transcendence.tanks_summoned==0,"generated tank does not count as player summon")
	var direct = battle._spawn_monster(tank_id,Vector2(500,400),0,false,{"counts_population":true})
	direct.set_physics_process(false)
	check(battle.transcendence.tanks_summoned==1,"real player tank spawn counts")
	generated.current_hp=0
	battle._on_monster_died(generated)
	check(battle.raw_allied_deaths==1 and battle.transcendence.allies_died==1,"generated ally death counts")
	battle.raw_allied_deaths=100
	battle.transcendence.tanks_summoned=65
	battle.transcendence.allies_died=100
	battle.transcendence._evaluate()
	check(battle.try_summon_transcendent(),"real Bulgasal summon")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	actor.pillars.set_physics_process(false)
	actor.position=battle.hero.position+Vector2(100,0)
	check(actor.max_hp==1950 and actor.move_speed==270 and actor.attack_cooldown==1.6,"actual actor stats and death snapshot")
	check(not battle.try_summon_transcendent(),"once per battle")
	battle.hero.invulnerability_timer=0
	battle.hero.shield_hp=0
	var hp_before: int=battle.hero.current_hp
	actor.resolve_rock_impact(battle.hero.position)
	check(battle.hero.current_hp<hp_before and battle.hero.stun_timer>0,"real Hero rock damage/stun")
	battle.hero.invulnerability_timer=0
	hp_before=battle.hero.current_hp
	actor.landing_position=battle.hero.position
	actor._set_phase("land")
	actor._physics_process(0.25)
	var hp_landing: int=battle.hero.current_hp
	actor._tick_waves(0.01)
	check(hp_landing<hp_before and battle.hero.current_hp<hp_landing,"real Hero landing plus one followup wave")
	var hp_wave: int=battle.hero.current_hp
	actor._tick_waves(1)
	check(battle.hero.current_hp==hp_wave,"remaining rays do not hit again")
	actor.transcend_level=1
	battle.hero.invulnerability_timer=5
	hp_before=battle.hero.current_hp
	actor.resolve_rock_impact(battle.hero.position)
	check(battle.hero.current_hp<hp_before,"Lv1 actual Hero invulnerability bypass")
	actor.transcend_level=4
	actor.position=battle.hero.position+Vector2(10,0)
	actor._set_phase("burrow")
	battle.hero.invulnerability_timer=5
	hp_before=battle.hero.current_hp
	actor._physics_process(0.01)
	check(battle.hero.current_hp<hp_before and actor.phase=="idle","Lv4 actual burrow hit ignores immunity and restores phase")
	battle.queue_free()
	await process_frame
	print("BULGASAL_INTEGRATION: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
