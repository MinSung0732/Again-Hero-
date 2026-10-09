extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MANTICORE_INTEGRATION: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://manticore_integration_"+Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	check("manticore" in SHOP.get_monster_pool("transcendent"),"shipping pool registered")
	check(is_equal_approx(SHOP.get_effective_probability("transcendent"),0.5),"grade probability unchanged")
	check(MONSTERS.get_species("manticore")=="beast" and MONSTERS.get_role("manticore")=="exploder","beast/exploder")
	check(not MONSTERS.MONSTERS.manticore.can_be_elite and not MONSTERS.MONSTERS.manticore.can_be_giant and not MONSTERS.MONSTERS.manticore.normal_augments_enabled and MONSTERS.MONSTERS.manticore.special_augment_ids.is_empty(),"no ordinary growth modifiers")
	check("manticore" not in COSMETICS.choices("avatar"),"locked cosmetics")
	var unit := 0.0
	var pool := SHOP.get_monster_pool("transcendent")
	unit = (pool.find("manticore")+0.5)/float(pool.size())
	check(SHOP.roll_monster("transcendent",unit)=="manticore","actual weighted roll")
	var batch := COLLECTION.award_shard_batch([{"monster_id":"manticore","rarity":"transcendent","shards":1,"source":"summon"}],0,false)
	check(batch.success and COLLECTION.is_unlocked("manticore"),"real award unlock")
	check("manticore" in COSMETICS.choices("avatar") and "manticore" in COSMETICS.choices("banner") and "manticore_plus_banner" not in COSMETICS.choices("banner"),"unlock icon/banner only")
	var state := COLLECTION.load_state()
	state.manticore.shards = MONSTERS.get_shards_required("manticore")*5
	COLLECTION.save_state(state)
	for level in range(1,6):
		var result := COLLECTION.try_upgrade("manticore")
		check(result.success and result.level==level,"actual upgrade "+str(level))
	check("manticore_plus_banner" in COSMETICS.choices("banner") and "manticore_plus_banner" not in COSMETICS.choices("avatar"),"five-tier separate banner")
	check(COSMETICS.select("banner","manticore_plus_banner"),"equip five-tier banner")
	check(LOADOUT.save_id("manticore"),"actual transcendent formation")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	check(not battle.try_summon_transcendent(),"combat locked")
	hero.take_status_damage(399,null)
	check(not battle.transcendence.ready,"real399 HP damage locked")
	hero.take_status_damage(1,null)
	check(battle.transcendence.ready and battle.run_metrics.total_damage_dealt==400,"actual damage signal unlock")
	var command_before: float = battle.command_power
	check(battle.try_summon_transcendent(),"actual summon success")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	check(actor.monster_type=="manticore" and actor.transcend_level==5 and actor.summon_snapshot==400 and actor.attack_damage==65 and actor.max_hp==1750,"actual scene level and damage snapshot")
	check(battle.command_power==command_before and not battle.try_summon_transcendent(),"free once")
	check(battle._spawn_monster("manticore",Vector2.ZERO)==null,"no normal spawn bypass")
	hero.apply_burn(1.0,49,actor)
	check(battle.get_transcendent_aura_modifier(hero,"outgoing")==0.5,"burn halves actual outgoing pipeline")
	hero.burn_runtime.update(hero,1.0)
	hero.set_meta("burn_active",hero.burn_runtime.remaining>0.0)
	check(battle.get_transcendent_aura_modifier(hero,"outgoing")==1.0,"burn restores without mutating base stats")
	# Real pooled enemy summon: AoE status component and reuse cleanup.
	var scout = load("res://src/hero/SummonerScout.tscn").instantiate()
	battle.add_child(scout)
	scout.activate(actor.position+Vector2(70,-30),hero,{"max_hp":10000,"owner_attack_damage":100})
	scout.set_physics_process(false)
	battle.set_hero_summon_active(scout,true)
	hero.position = actor.position+Vector2(80,-30)
	actor._refresh_other_enemies(1.0)
	actor.flame_remaining = 30.0
	actor.transcend_level = 0
	var scout_before: int = scout.current_hp
	for i in range(100): actor._tick_other_enemies(0.01)
	actor._tick_other_enemies(0.001)
	check(scout.current_hp==scout_before-65 and bool(scout.get_meta("burn_active",false)),"actual secondary cone contact and burn")
	check(preload("res://src/data/status_effect_catalog.gd").outgoing_multiplier(scout)==0.5,"secondary attack half")
	preload("res://src/systems/received_afflictions.gd").apply_slow(scout,0.7,3.0)
	check(preload("res://src/data/status_effect_catalog.gd").movement_multiplier(scout)==0.7,"secondary slow")
	scout.deactivate(false)
	check(not bool(scout.get_meta("burn_active",false)) and scout.get_meta("received_slow_multiplier",1.0)==1.0,"pool reuse clears statuses")
	scout.queue_free()
	var pieces_before: int = battle.get_tree().get_nodes_in_group("exp_orbs").size()
	actor.escaped = true
	actor.take_damage(1000000)
	check(actor.dying and bool(actor.get_meta("transcendent_death_handled",false)),"actual death authority handled")
	check(battle.get_tree().get_nodes_in_group("exp_orbs").size()==pieces_before+15,"common death drops")
	battle.queue_free()
	await process_frame
	print("MANTICORE_INTEGRATION "+("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
