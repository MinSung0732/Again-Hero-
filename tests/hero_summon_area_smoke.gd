extends SceneTree
const D := preload("res://src/data/hero_weapon_catalog.gd")
const H := preload("res://tests/hero_summon_growth_smoke.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var checks := 0
var failures := 0
class Reflector extends Node2D:
	var current_hp := 1000
	func take_damage(_amount: int) -> void: pass
	func try_reflect_projectile(_shot: Node2D,_amount: int,_source: Node) -> bool: return true
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func clear_summons(hero) -> void:
	for row in H.CASES.values():
		for actor in hero.get("summoner_"+String(row[0])+"_pool"):
			if actor.active: actor.deactivate()
func actor_for(hero,kind: String):
	for actor in hero.get("summoner_"+kind+"_pool"):
		if actor.active: return actor
	return null
func place(target,point: Vector2) -> void:
	target.global_position = point
	target.current_hp = target.max_hp
	COMMON.notify_forced_position_change(target)
func hit_once(actor,kind: String,target) -> void:
	match kind:
		"hound": actor._start_attack(target); actor._update_pending_hits(.2); actor.pending_hits = 0
		"scout": actor._attack_target(target)
		"watcher": actor._fire_at_target(target)
		"gatekeeper": actor._fire_at(target)
	if kind in ["watcher","gatekeeper"]:
		for shot in actor.projectile_pool:
			if shot.active:
				shot.set_physics_process(false)
				shot._impact_target()
				shot.deactivate()
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var old := SCOPE.guest_directory
	SCOPE.guest_directory = "user://summon_area_"+str(Time.get_ticks_usec()); SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_8"; battle.hero_player_hero_id = "summoner_hero"
	battle._monster_spawn_resources_warmed = true
	root.add_child(battle); battle.set_external_pause(true)
	await process_frame
	var hero = battle.hero
	var runtime = hero.player_weapons
	var original: Dictionary = runtime.native_skills.summon_configs.duplicate(true)
	var victims: Array = []
	for index in 18:
		var target = battle._spawn_monster("orc",hero.position+Vector2(50+index,0))
		target.set_physics_process(false); target.max_hp = 1000000; target.current_hp = target.max_hp
		victims.append(target)
	for id in H.CASES:
		clear_summons(hero)
		runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.evolved.clear(); runtime.resolved.clear(); runtime.passives.clear()
		runtime.area_bonus = 1.0; runtime.projectile_bonus = 0
		var kind: String = H.CASES[id][0]
		runtime.add(id); runtime._cast(id)
		var actor = actor_for(hero,kind)
		check(is_instance_valid(actor),id+" real summon")
		if not is_instance_valid(actor): continue
		actor.set_physics_process(false)
		var instance: int = actor.get_instance_id()
		for rank in [1,2,3,4,5,6,7,8,9,10,11]:
			if rank in range(2,11): runtime.add(id)
			elif rank == 11:
				var receipt: Dictionary = runtime.roll_chest()
				check(receipt.evolution and runtime.apply_chest(receipt),id+" MAX through real chest")
			check(actor.get_instance_id() == instance,id+" upgrades existing instance")
			var stats: Dictionary = runtime.stats_for(id)
			var radius: float = stats.summon_area_radius
			check(is_equal_approx(actor.area_attack.radius,radius),id+str(rank)+" live area radius")
			actor.global_position = hero.position
			var main = victims[0]
			place(main,actor.position+Vector2(50,0))
			for i in range(1,14): place(victims[i],actor.position+Vector2(30+(i%4)*5,(i%3-1)*8))
			var center: Vector2 = actor.position if kind == "scout" else main.position
			place(victims[14],center+Vector2(0,maxf(radius,1)+3)) # outside actual radius
			place(victims[15],actor.position-Vector2(5,0)) # behind cone, inside circles
			place(victims[16],center); victims[16].set_meta("hero_detection_hidden",true)
			place(victims[17],center); victims[17].current_hp = 0 # dead candidate stays in query
			await physics_frame
			# Compare the same strike with AoE disabled: the primary must not be doubled.
			actor.area_attack.radius = 0.0
			if kind == "gatekeeper": actor.consecutive_target_id = 0; actor.consecutive_target_steps = 0
			hit_once(actor,kind,main)
			var primary_damage: int = main.max_hp-main.current_hp
			main.current_hp = main.max_hp
			actor.area_attack.radius = radius
			if kind == "gatekeeper": actor.consecutive_target_id = 0; actor.consecutive_target_steps = 0
			var parent_nodes: Array[Node] = battle.get_children()
			hit_once(actor,kind,main)
			var damaged := 0
			for i in range(1,16):
				if victims[i].current_hp < victims[i].max_hp: damaged += 1
			check(main.current_hp < main.max_hp,id+str(rank)+" primary still hits")
			check(main.max_hp-main.current_hp == primary_damage,id+" AoE excludes primary duplicate")
			check(damaged == int(stats.summon_area_targets),id+str(rank)+" exact bounded additional targets: "+str(damaged))
			check(victims[14].current_hp == victims[14].max_hp,id+" out of radius safe")
			check(victims[16].current_hp == victims[16].max_hp and victims[17].current_hp == 0,id+" hidden/dead ignored")
			if kind == "hound": check(victims[15].current_hp == victims[15].max_hp,id+" cone does not hit rear")
			var allocated_attack := false
			for child in battle.get_children():
				if child not in parent_nodes and child.get_script() != preload("res://src/ui/damage_number.gd"): allocated_attack = true
			check(not allocated_attack,id+" area attack creates no attack nodes; existing damage popups allowed")
			if rank in [3,6,9,10,11]:
				check(D.description(id,rank).contains("반경"),id+" milestone explained")
				for i in range(1,16): place(victims[i],center+Vector2(2000+i*10,0))
				place(victims[1],center+Vector2(radius,0))
				place(victims[2],center+Vector2(radius+.5,0))
				main.current_hp = main.max_hp
				await physics_frame
				hit_once(actor,kind,main)
				check(victims[1].current_hp < victims[1].max_hp and victims[2].current_hp == victims[2].max_hp,id+str(rank)+" exact spatial radius boundary")
			if rank >= 3 and kind in ["hound","scout"]: check(actor.area_attack.flash_left > 0.0,id+" visible melee area pulse")
		if kind in ["watcher","gatekeeper"]:
			var reflector := Reflector.new(); battle.add_child(reflector)
			reflector.position = actor.position+Vector2(50,0)
			place(victims[1],reflector.position+Vector2(5,0))
			await physics_frame
			if kind == "watcher": actor._fire_at_target(reflector)
			else: actor._fire_at(reflector)
			for shot in actor.projectile_pool:
				if not shot.active: continue
				shot._impact_target()
				check(not shot.active and shot.area_attack.radius == 0,id+" reflected projectile recycles without splash")
			check(victims[1].current_hp == victims[1].max_hp,id+" reflection prevents nearby AoE damage")
			reflector.queue_free()
		check(runtime.add("survival_area"),id+" area passive acquired")
		check(is_equal_approx(actor.area_attack.radius,runtime.stats_for(id).summon_area_radius*1.06),id+" area passive applied once to live summon")
		actor.deactivate()
		check(actor.area_attack.radius == 0 and actor.area_attack.flash_left == 0,id+" pool clears area and flash")
		# Original AI activation of the same pooled actor has no survival AoE.
		var config: Dictionary = original[kind].duplicate(true)
		config["owner_attack_damage"] = hero.attack_damage
		actor.activate(hero.position,hero,config)
		check(actor.area_attack.radius == 0,id+" original AI profile remains single target")
		actor.deactivate()
		runtime._cast(id)
		var reused = actor_for(hero,kind)
		check(is_instance_valid(reused) and reused.get_instance_id() == instance,id+" real cast reuses pool after original profile")
		check(is_equal_approx(reused.area_attack.radius,runtime.stats_for(id).summon_area_radius*1.06),id+" fresh summon restores upgraded AoE")
		clear_summons(hero)
	check(original == runtime.native_skills.summon_configs,"original summon configs unchanged")
	stop_audio(battle); stop_audio(root.get_node("GameAudio")); await process_frame
	battle.queue_free(); await process_frame; await create_timer(.15).timeout
	SCOPE.guest_directory = old; SCOPE.select_guest()
	print("HERO_SUMMON_AREA checks=",checks," failures=",failures)
	quit(1 if failures else 0)
