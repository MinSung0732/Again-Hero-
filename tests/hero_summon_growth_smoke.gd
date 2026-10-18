extends SceneTree
## Real Battle/Hero, summon pools, level-up API and chest receipt. Art is optional.
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CASES := {
	"summoner_hero_gate_hound":["hound",1.25,1.70],
	"summoner_hero_scout":["scout",1.43,2.0],
	"summoner_hero_gatekeeper":["gatekeeper",1.07,1.50],
	"summoner_hero_watcher":["watcher",0.0,0.0],
}
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func clear_summons(hero) -> void:
	for row in CASES.values():
		for actor in hero.get("summoner_"+String(row[0])+"_pool"):
			if actor.active: actor.deactivate()
func actor_for(hero, kind: String):
	for actor in hero.get("summoner_"+kind+"_pool"):
		if actor.active: return actor
	return null
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func hit_once(actor, kind: String, target) -> int:
	actor.global_position = target.global_position-Vector2(15,0)
	var before: int = target.current_hp
	match kind:
		"hound": actor._start_attack(target); actor._update_pending_hits(.2)
		"scout": actor._attack_target(target)
		"watcher": actor._fire_at_target(target)
		"gatekeeper": actor._fire_at(target)
	if kind in ["watcher","gatekeeper"]:
		for shot in actor.projectile_pool:
			if shot.active: shot._physics_process(.5)
	return before-int(target.current_hp)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var old_directory := SCOPE.guest_directory
	SCOPE.guest_directory = "user://summon_growth_"+str(Time.get_ticks_usec()); SCOPE.select_guest()
	for id in CASES:
		var previous_duration := 0.0
		var previous_hp := 0.0
		for rank in range(1,11):
			var stats := DATA.GROWTH.resolve(id,DATA.WEAPONS[id],rank,false)
			check(float(stats.summon_duration) > previous_duration,id+" duration grows at every level")
			previous_duration = stats.summon_duration
			if CASES[id][0] != "watcher":
				check(float(stats.summon_hp_ratio) > previous_hp,id+" health grows at every level")
				previous_hp = stats.summon_hp_ratio
			else: check(not stats.has("summon_hp_ratio"),"invulnerable watcher advertises no fake HP")
			check(DATA.description(id,rank).contains("소환 유지"),id+" level card explains duration")
		check(DATA.description(id,10).contains("30 → 32초"),id+" level10 card shows actual duration delta")
	check(DATA.description("survival_duration",1).contains("+6%"),"duration passive card matches six percent")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_8"; battle.hero_player_hero_id = "summoner_hero"
	battle._monster_spawn_resources_warmed = true
	root.add_child(battle); battle.set_external_pause(true)
	await process_frame
	var hero = battle.hero
	var runtime = hero.player_weapons
	check(hero.hero_id == "summoner_hero", "real stage8 player hero installed")
	var original: Dictionary = runtime.native_skills.summon_configs.duplicate(true)
	var target = battle._spawn_monster("orc",hero.position+Vector2(70,0))
	target.set_physics_process(false); target.max_hp = 1000000; target.current_hp = target.max_hp
	for id in CASES:
		clear_summons(hero)
		runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.evolved.clear(); runtime.resolved.clear(); runtime.passives.clear()
		runtime.power = 1.0; runtime.duration_bonus = 1.0; runtime.projectile_power = 1.0
		hero.max_hp = runtime.base_max_hp; hero.current_hp = hero.max_hp
		check(runtime.add(id),id+" owned through real weapon API")
		runtime._cast(id)
		var actor = actor_for(hero,CASES[id][0])
		check(is_instance_valid(actor),id+" real pooled summon created")
		if not is_instance_valid(actor): continue
		var instance: int = actor.get_instance_id()
		var handle: Vector3i = battle.get_battle_entity_handle(actor)
		check(is_equal_approx(actor.duration_total,14.0),id+" level1 remains14s")
		var initial_hit := hit_once(actor,CASES[id][0],target)
		check(initial_hit > 0,id+" level1 real melee or projectile hits")
		var vulnerable: bool = CASES[id][0] != "watcher"
		if vulnerable: check(actor.max_hp == roundi(hero.max_hp*.35),id+" level1 remains35 percent")
		else: check(not actor.take_damage(1000000) and actor.active,"watcher remains invulnerable")
		actor.duration_remaining = 9.0 # Already five seconds old.
		var health_fraction := 1.0
		if vulnerable:
			actor.current_hp = maxi(1,actor.max_hp/2)
			health_fraction = float(actor.current_hp)/float(actor.max_hp)
		var node_count: int = battle.get_child_count()
		var previous_damage: int = actor.attack_damage
		for rank in range(2,11):
			check(runtime.add(id),id+" actual level-up "+str(rank))
			check(actor.get_instance_id() == instance and battle.get_battle_entity_handle(actor) == handle,id+" upgrade preserves entity life")
			check(is_equal_approx(actor.duration_remaining,actor.duration_total-5.0),id+" upgrade preserves elapsed lifetime")
			check(actor.attack_damage > previous_damage,id+" existing summon receives stronger attack")
			previous_damage = actor.attack_damage
			if vulnerable: check(absf(float(actor.current_hp)/float(actor.max_hp)-health_fraction) <= .01,id+" wounded fraction preserved")
		check(battle.get_child_count() == node_count,id+" upgrades allocate no scene actors")
		check(is_equal_approx(actor.duration_total,32.0),id+" level10 lasts32s")
		check(hit_once(actor,CASES[id][0],target) > initial_hit,id+" level10 real hit grows without resummon")
		if vulnerable: check(actor.max_hp == roundi(hero.max_hp*float(CASES[id][1])),id+" role-specific level10 health")
		var before_left: float = actor.duration_remaining
		var before_hp: int = actor.get("current_hp") if vulnerable else 0
		runtime._refresh_owned_summons(id); runtime._refresh_owned_summons(id)
		check(is_equal_approx(actor.duration_remaining,before_left),id+" same settings never refill duration")
		if vulnerable: check(actor.current_hp == before_hp,id+" same settings never heal")
		var receipt: Dictionary = runtime.roll_chest()
		check(receipt.id == id and receipt.evolution,id+" real MAX receipt")
		check(runtime.apply_chest(receipt) and not runtime.apply_chest(receipt),id+" MAX applies once")
		check(is_equal_approx(actor.duration_total,40.0) and is_equal_approx(actor.duration_remaining,35.0),id+" existing MAX summon keeps age at40s")
		if vulnerable: check(actor.max_hp == roundi(hero.max_hp*float(CASES[id][2])),id+" MAX health applies to existing summon")
		check(runtime.add("survival_duration"),id+" duration passive accepted")
		check(is_equal_approx(actor.duration_total,42.4) and is_equal_approx(actor.duration_remaining,37.4),id+" duration passive applies once to existing summon")
		if vulnerable:
			var before_max_hp: int = actor.max_hp
			check(runtime.add("survival_vitality"),id+" vitality passive accepted")
			check(actor.max_hp > before_max_hp and actor.max_hp == roundi(hero.max_hp*float(CASES[id][2])),id+" summon inherits new owner max HP")
		var before_power: int = actor.attack_damage
		check(runtime.add("survival_power"),id+" power passive accepted")
		check(actor.attack_damage > before_power,id+" existing summon inherits power passive")
		# Expiration/death cannot be undone by a stat refresh.
		actor.duration_remaining = 0.0
		runtime._refresh_owned_summons(id)
		check(actor.duration_remaining == 0.0,id+" expired summon never revived")
		actor._physics_process(.01)
		check(actor.dying or not actor.active,id+" real expiration path still releases")
		actor.deactivate()
		runtime._cast(id)
		var reused = actor_for(hero,CASES[id][0])
		check(is_instance_valid(reused) and reused.get_instance_id() == instance,id+" recast reuses existing pool")
		if vulnerable:
			reused.current_hp = 0; reused.dying = true
			runtime._refresh_owned_summons(id)
			check(reused.current_hp == 0 and reused.dying,id+" dying summon never healed or resurrected")
		clear_summons(hero)
	check(runtime.native_skills.summon_configs == original,"original AI profile snapshots remain unchanged")
	# Shared cap and gameplay release accounting are preserved.
	runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.evolved.clear(); runtime.resolved.clear()
	runtime.add("summoner_hero_gate_hound")
	for i in 8: runtime._cast("summoner_hero_gate_hound")
	check(hero._get_active_summon_count() == 3,"shared three-summon cap preserved")
	clear_summons(hero)
	check(hero._get_active_summon_count() == 0,"release counters and registry cleared")
	stop_audio(battle); stop_audio(root.get_node("GameAudio")); await process_frame
	battle.queue_free(); await process_frame; await create_timer(.15).timeout
	SCOPE.guest_directory = old_directory; SCOPE.select_guest()
	print("HERO_SUMMON_GROWTH checks=",checks," failures=",failures)
	quit(1 if failures else 0)
