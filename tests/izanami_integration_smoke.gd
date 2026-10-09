extends SceneTree
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("IZANAMI_INTEGRATION: "+message)
func run() -> void:
	if root.has_node("CloudStore"): root.get_node("CloudStore").stop()
	if root.has_node("LoginGateway"): root.get_node("LoginGateway").remember_session_enabled = false
	if root.has_node("LocalTestMode"): root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://izanami_test_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	check(SHOP.get_monster_pool("transcendent").size()==3 and "izanami" in SHOP.get_monster_pool("transcendent"),"three member pool")
	check(is_equal_approx(SHOP.get_effective_probability("transcendent"),0.5),"rarity stays0.5%")
	check(SHOP.weighted_id(["zeus","bulgasal","izanami"],0.59,"zeus")=="zeus" and SHOP.weighted_id(["zeus","bulgasal","izanami"],0.81,"zeus")=="izanami","pickup3:1:1")
	check(not LOADOUT.save_id("izanami"),"locked registration rejected")
	var progress := ConfigFile.new()
	progress.set_value("meta","gold",1000)
	SCOPE.save_config(progress,COLLECTION.PROGRESS_PATH)
	var rolls: Array = []
	for i in range(11):
		rolls.append({"monster_id":"izanami" if i in [0,5,10] else "slime","source":"pickup","rarity":"transcendent" if i in [0,5,10] else "common","shards":1})
	var award := COLLECTION.award_shard_batch(rolls,1000)
	check(award.success and award.state.izanami.unlocked and award.state.izanami.shards==2,"atomic unlock/duplicates")
	SCOPE.load_config(progress,COLLECTION.PROGRESS_PATH)
	check(int(progress.get_value("meta","gold"))==0,"charge once exact1000")
	check("izanami" in COSMETICS.choices("avatar") and "izanami" in COSMETICS.choices("banner"),"unlock cosmetics")
	check(COSMETICS.select("avatar","izanami") and COSMETICS.select("banner","izanami"),"equip cosmetics")
	check(LOADOUT.save_id("izanami") and LOADOUT.load_id()=="izanami","loadout/save")
	var saved := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg"))
	var overlay = OVERLAY.new()
	root.add_child(overlay)
	overlay.present(rolls)
	overlay._sequence_token += 1
	overlay._show_reveal(0)
	for i in range(11):
		check(overlay._reveal_index==i,"ordered result")
		if i in [0,5,10]:
			check(overlay._phase=="cutscene","real Izanami dispatch")
			overlay._cutscene.set_process(false)
			if i==5: overlay._cutscene.skip()
			else: overlay._cutscene.advance(5.0)
			check(overlay._phase=="reveal" and overlay._reveal_index==i,"normal/skip same result")
		overlay._advance_reveal()
	check(saved==FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg")),"no second award")
	overlay.free()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle._monster_spawn_resources_warmed = true # Other monsters are outside this isolated fixture.
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	battle.hero.set_physics_process(false)
	check(battle.transcendence.monster_id=="izanami" and not battle.transcendence.ready,"real run starts locked")
	for i in range(49): battle.transcendence.record_summon("control")
	battle.hero.apply_slow(0.9,1.0)
	battle.hero.apply_stun(0.1)
	battle.hero.apply_silence(0.1)
	check(battle.raw_statuses_applied==3 and not battle.transcendence.ready,"authority accepted statuses,49 stilllocked")
	check(battle.transcendence.record_summon("control"),"50/3 ready")
	check(battle.try_summon_transcendent(),"real summon dispatch and condition consumption")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	check(actor.summon_snapshot==3 and actor.max_hp==1088 and actor.attack_damage==61,"real spawn growth snapshot")
	check(not battle.try_summon_transcendent(),"once per battle")
	actor.torii_points[0] = battle.hero.global_position
	actor.torii_age[0] = 1.0
	actor.clock = 0.0
	check(battle.get_transcendent_aura_modifier(battle.hero,"outgoing")==0.85,"actual authority aura")
	battle.hero.apply_silence(3.0)
	check(not battle.hero._rogue_can_start_assassination() and not battle.hero._rogue_should_use_slash() and not battle.hero._gunner_should_start_deadeye() and not battle.hero._fighter_should_start_charge(),"silence readiness permits basic-attack fallback")
	var charge: float = battle.hero.ultimate_charge
	battle.hero._use_ultimate()
	check(battle.hero.silence_timer>0 and battle.hero.ultimate_charge==charge,"silence no cast/no spend")
	var hp: int = battle.hero.current_hp
	battle.hero.invulnerability_timer = 0.0
	battle.hero.take_damage(10,actor)
	check(battle.hero.current_hp<hp,"real damage still accepted")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		root.size = Vector2i(540,960)
		actor.position = battle.hero.position+Vector2(100,0)
		actor.gauge = 80.0
		actor.ghost_remaining = 7.0
		actor.torii_points[0] = battle.hero.position+Vector2(0,130)
		actor.torii_age[0] = 1.0
		actor.fire_points[0] = battle.hero.position
		actor.fire_age[0] = 1.1
		actor.fire_delay[0] = 0.75
		actor.effect_layer.queue_redraw()
		actor.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/izanami-combat-native.png")
	battle.free()
	print("IZANAMI_INTEGRATION: "+("PASS" if failures==0 else "FAILED"))
	quit(0 if failures==0 else 1)
