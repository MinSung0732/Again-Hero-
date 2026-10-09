extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const ACTION := preload("res://src/systems/status_action_scope.gd")
const IZANAMI := preload("res://src/monsters/Izanami.tscn")
const SHUTEN := preload("res://src/monsters/ShutenDoji.tscn")
var failures := 0
var raw_events := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("STATUS_ACTION: "+message)
func stop(actor: Node) -> void:
	actor.set_physics_process(false)
	actor.set_process(false)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://status-action-"+Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	stop(battle)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	stop(hero)
	hero.max_hp = 1000000
	hero.current_hp = 1000000
	hero.shield_hp = 0
	hero.global_position = Vector2(500,500)
	hero.status_applied.connect(func(_kind):raw_events+=1)
	battle.transcendence.configure("shuten_doji",preload("res://src/data/shuten_doji_behavior_catalog.gd").RULES)
	for i in range(40): battle.transcendence.record_summon("control")
	var token := ACTION.Token.new()
	var previous := ACTION.begin(hero,token)
	for i in range(10):
		hero.apply_slow(0.5,1)
		hero.apply_stun(1)
		hero.apply_damage_taken_increase(1,.1)
	ACTION.finish(hero,previous)
	check(raw_events==30 and battle.raw_statuses_applied==1,"thirty actual status refreshes count as one originating action")
	check(not battle.transcendence.ready and battle.transcendence.statuses_applied==1,"one multi-status action does not satisfy three-action unlock")
	check(ACTION.current(hero)==null,"action scope restored")
	# A real basic attack with slow plus special bleed counts once.
	var banshee = load("res://src/monsters/Banshee.tscn").instantiate()
	banshee.configure_combat_context(hero,battle)
	battle.add_child(banshee)
	stop(banshee)
	banshee.special_augment_configs = {"banshee_bleeding":{"chance":1.0,"duration":3.0}}
	hero._clear_bleed()
	hero.invulnerability_timer = 0
	var count: int = battle.raw_statuses_applied
	banshee._deal_attack_damage()
	check(battle.raw_statuses_applied==count+1 and hero.get_meta("bleed_active",false),"actual Banshee slow plus bleed share one attack")
	hero.invulnerability_timer = 0
	banshee._deal_attack_damage()
	check(battle.raw_statuses_applied==count+2 and battle.transcendence.ready,"a fresh attack counts again and unlocks at three actions")
	# Repeated, overlapping elite webs share the cast token, while a new cast
	# remains distinct even when it refreshes exactly the same slow status.
	count = battle.raw_statuses_applied
	var web_skill := {"_status_action":ACTION.Token.new(),"duration":3.0,"tick_interval":0.1,"radius":150.0}
	battle.elite_monster_skill_runtime._create_spider_web(hero.global_position,web_skill)
	battle.elite_monster_skill_runtime._create_spider_web(hero.global_position,web_skill)
	for i in range(10): battle.elite_monster_skill_runtime._tick_spider_webs(0.1)
	check(battle.raw_statuses_applied==count+1,"two overlapping webs and twenty ticks count once per cast")
	web_skill["_status_action"] = ACTION.Token.new()
	battle.elite_monster_skill_runtime._create_spider_web(hero.global_position,web_skill)
	battle.elite_monster_skill_runtime._tick_spider_webs(0.1)
	check(battle.raw_statuses_applied==count+2,"a second web cast counts once independently")
	# Multi-shot attack and pooled lifecycle: three hits, one credit each volley.
	var yuki = load("res://src/monsters/YukiOnna.tscn").instantiate()
	yuki.configure_combat_context(hero,battle)
	battle.add_child(yuki)
	stop(yuki)
	yuki.special_augment_configs = {"yuki_threefold_snow":{}}
	for volley in range(2):
		count = battle.raw_statuses_applied
		yuki._fire_projectile(Vector2.RIGHT*300)
		var hits := 0
		for shot in get_nodes_in_group("monster_projectiles"):
			if shot.get_script().resource_path != "res://src/monsters/yuki_onna_projectile.gd" or not shot.active: continue
			hero.invulnerability_timer = 0
			shot._on_body_entered(hero)
			hits += 1
		check(hits==3 and battle.raw_statuses_applied==count+1,"actual threefold volley counts once "+str(volley))
		await process_frame
	# Delayed petrify residue remains attached to the same attack.
	count = battle.raw_statuses_applied
	previous = ACTION.begin(hero,ACTION.Token.new())
	hero.apply_petrify(1,.5,2)
	ACTION.finish(hero,previous)
	hero._tick_petrify(2)
	check(battle.raw_statuses_applied==count+1,"petrify and delayed residue slow count once")
	# Both actors and actual battle detail use the identical pre-summon count.
	count = battle.raw_statuses_applied
	var izanami = IZANAMI.instantiate()
	izanami.configure_transcendence(count,0)
	var shuten = SHUTEN.instantiate()
	shuten.configure_transcendence(count,0)
	check(izanami.attack_damage==55+count and izanami.max_hp==int(round(1080+count*1.5)),"Izanami snapshot formula")
	check(shuten.attack_damage==220+count and shuten.max_hp==2500+count,"Shuten snapshot formula")
	var iza_before: int = izanami.attack_damage
	var shu_before: int = shuten.attack_damage
	hero.apply_silence(1)
	check(izanami.attack_damage==iza_before and shuten.attack_damage==shu_before,"post-summon events do not grow frozen actors")
	izanami.free()
	shuten.free()
	battle.free()
	await process_frame
	print("STATUS_ACTION_GROWTH "+("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
