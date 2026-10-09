extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const ART := preload("res://src/data/skill_icon_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("SHUTEN_INTEGRATION: "+label)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://shuten_integration_"+Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var id := "shuten_doji"
	var pool := SHOP.get_monster_pool("transcendent")
	check(id in pool,"actual draw pool registered")
	check(MONSTERS.get_species(id)=="humanoid" and MONSTERS.get_role(id)=="control","human control")
	var entry: Dictionary = MONSTERS.MONSTERS[id]
	check(not entry.can_be_elite and not entry.can_be_giant and not entry.normal_augments_enabled and entry.special_augment_ids.is_empty(),"no ordinary augment elite or giant")
	check(id not in COSMETICS.choices("avatar"),"cosmetics locked before collection")
	check(SHOP.roll_monster("transcendent",(pool.find(id)+.5)/float(pool.size()))==id,"actual draw selection")
	var batch := COLLECTION.award_shard_batch([{"monster_id":id,"rarity":"transcendent","shards":1,"source":"summon"}],0,false)
	check(batch.success and COLLECTION.is_unlocked(id),"actual shard award unlock")
	check(id in COSMETICS.choices("avatar") and id in COSMETICS.choices("banner"),"profile icon banner unlock")
	for name in ["혈주연무","귀염지폭","쇄혼귀면","귀왕해방"]:
		check(ResourceLoader.exists(ART.path("transcendent",id,name)),"skill icon "+name)
	var state := COLLECTION.load_state()
	state[id].shards = MONSTERS.get_shards_required(id)*5
	COLLECTION.save_state(state)
	for level in range(1,6):
		var result := COLLECTION.try_upgrade(id)
		check(result.success and result.level==level,"actual tier "+str(level))
	check(LOADOUT.save_id(id),"transcendent team slot")
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
	check(not battle.try_summon_transcendent(),"battle starts locked")
	# Real successful population summons; removal permits a forty-summon history
	# without bypassing the game's simultaneous population cap.
	for i in range(40):
		var unit = battle._spawn_monster("yuki_onna",Vector2(500,500),0,false,{"counts_population":true})
		check(unit!=null,"actual control summon "+str(i))
		if unit!=null:
			unit.set_physics_process(false)
			unit.queue_free()
		await process_frame
	check(battle.transcendence.controls_summoned==40 and not battle.transcendence.ready,"forty controls alone locked")
	hero.apply_slow(0.5,1)
	hero.apply_stun(1)
	check(not battle.transcendence.ready,"two actual statuses locked")
	hero.apply_silence(1)
	check(battle.transcendence.ready and battle.raw_statuses_applied>=3,"third actual enemy status unlocks")
	var command_before: float = battle.command_power
	check(battle.try_summon_transcendent(),"actual successful summon")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	check(actor.monster_type==id and actor.transcend_level==5 and actor.attack_damage==223 and actor.max_hp==2503 and actor.summon_snapshot==3,"actual scene and tier with pre-summon status snapshot")
	check(battle.command_power==command_before and not battle.try_summon_transcendent(),"free once per battle")
	check(battle._spawn_monster(id,Vector2.ZERO)==null,"normal spawn cannot bypass unlock")
	# Production Hero chain statuses, DOT and post-release immunity.
	actor.gauge = 100
	actor._cast_chain(hero)
	actor._bind_chain(0,hero)
	check(hero.silence_timer>0 and actor.chain_state[0]==2,"native Hero silence and bind")
	var hp_before: int = hero.current_hp
	actor._tick_chains(3)
	check(hp_before-hero.current_hp==558,"native Hero total chain DOT")
	hero._clear_bleed()
	var current: int = hero.current_hp
	preload("res://src/systems/received_afflictions.gd").apply_bleed_current(hero,7,.06,actor)
	check(hero.bleed_total_damage==int(round(current*.06)),"native Hero current health bleed budget")
	# Exercise the complete autonomous physics path, not only isolated skills.
	actor.arrival = 0
	actor.gauge = 100
	actor.cooldowns.fill(0)
	hero.global_position = actor.global_position+Vector2(50,0)
	for step in range(30): actor._physics_process(0.1)
	check(actor.attack_damage==223 and actor.action_serial>2,"autonomous casts preserve frozen growth snapshot")
	actor.revival_used = true
	actor.set_meta("support_shield_hp",0)
	var drops: int = battle.get_tree().get_nodes_in_group("exp_orbs").size()
	actor.take_damage(1000000)
	check(actor.dying and bool(actor.get_meta("transcendent_death_handled",false)),"production death pipeline")
	check(battle.get_tree().get_nodes_in_group("exp_orbs").size()==drops+15,"common fifteen death drops")
	battle.queue_free()
	await process_frame
	print("SHUTEN_INTEGRATION "+("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
