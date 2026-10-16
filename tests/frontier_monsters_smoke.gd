extends SceneTree
## Run after imports. Exercises real catalog scenes/MonsterVisual, pooled hits and casts;
## isolated target used for exact status/heal accounting, then actual Battle spawn.
const C := preload("res://src/data/monster_catalog.gd")
const D := preload("res://src/data/frontier_monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const CODEX := preload("res://src/data/demon_codex_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SURVIVAL := preload("res://src/data/hero_mode_catalog.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
const HARNESS := preload("res://tests/hero_opening_pressure_smoke.gd")
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
var checks := 0
var failures := 0

class Target extends CharacterBody2D:
	var current_hp := 100000
	var max_hp := 100000
	var active := true
	var invulnerable := false
	var slow := 1.0
	var poison := 0.0
	var burn := 0
	func take_damage(amount: int,_source: Node = null) -> void:
		if not invulnerable: current_hp = maxi(current_hp-amount,0)
	func apply_slow(multiplier: float,_duration: float) -> void: slow = multiplier
	func apply_poison(_duration: float,ratio: float,_interval: float,_source: Node) -> void: poison = ratio
	func apply_burn(_duration: float,amount: int,_source: Node) -> bool:
		burn = amount
		return true

class Arena extends Node2D:
	var hero: Node2D
	var actors: Array = []
	var bolts: Array = []
	var pool: Array = []
	var registry = REGISTRY.new()
	func _init() -> void: registry.begin_session(73)
	func get_nearest_hero_combat_target(_origin: Vector2) -> Node2D: return hero
	func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
	func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
	func fill_monsters_near(_origin: Vector2,_radius: float,result: Array) -> void:
		result.clear()
		result.append_array(actors)
	func acquire_projectile(scene: PackedScene,_key: String) -> Node:
		var node: Node = pool.pop_back() if not pool.is_empty() else null
		if node == null:
			node = scene.instantiate()
			add_child(node)
			bolts.append(node)
		return node
	func recycle_projectile(node: Node,_key: String) -> void:
		node.deactivate_for_pool()
		pool.append(node)

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void: run.call_deferred()

func make_actor(id: String,arena: Arena):
	var actor = C.get_scene(id).instantiate()
	C.apply_runtime_base_stats(actor,id)
	actor.configure_combat_context(arena.hero,arena)
	arena.add_child(actor)
	actor.set_physics_process(false)
	arena.actors.append(actor)
	return actor

func settle_bolts(arena: Arena) -> void:
	for bolt in arena.bolts:
		bolt.set_physics_process(false)
		if bolt.active: bolt._physics_process(1.0)

func config_for(id: String) -> Dictionary:
	var result := {}
	for aug in A.get_special_augments_for_monster(id): result[aug.effect_type] = aug.effect_values
	return result

func run() -> void:
	var arena := Arena.new()
	root.add_child(arena)
	var target := Target.new()
	arena.add_child(target)
	arena.hero = target
	arena.registry.activate(target)
	target.position = Vector2(50,0)
	var elite_count := 0
	for id in D.DEFINITIONS:
		var data: Dictionary = D.DEFINITIONS[id]
		check(id in C.ORDER and C.get_monster(id).name == data.name,id+" catalog")
		check(id in SHOP.get_monster_pool(data.rarity),id+" gacha pool")
		check(id in CODEX.monster_ids(false),id+" codex")
		check(A.get_special_augments_for_monster(id).size() == 3,id+" three special augments")
		check(not A.get_monster_normal_augments(id,data.name).is_empty(),id+" normal augments")
		check(data.elite_skills.size() >= 1 and data.elite_skills.size() <= (2 if data.rarity=="rare" else 1),id+" elite count")
		var actor = make_actor(id,arena)
		check(actor.max_hp == C.get_base_stats(id).max_hp and actor.current_hp == actor.max_hp,id+" canonical before ready")
		check(actor.visual.is_visual_ready(),id+" real normal visual")
		for animation in data.normal_visual.animations:
			check(actor.visual.sprite_frames.get_frame_count(animation) == data.normal_visual.animations[animation].count,id+" normal "+animation)
		check(actor.apply_visual_profile(data.elite_visual),id+" real elite profile")
		for animation in data.elite_visual.animations:
			check(actor.visual.sprite_frames.get_frame_count(animation) == data.elite_visual.animations[animation].count,id+" elite "+animation)
		var before: int = target.current_hp
		actor._attack_target(target)
		settle_bolts(arena)
		check(target.current_hp < before,id+" base attack damage")
		actor.configure_special_augments(config_for(id))
		var shield: int = actor.get_meta("temporary_shield_hp",0)
		for i in 10: actor.configure_special_augments(config_for(id))
		check(int(actor.get_meta("temporary_shield_hp",0)) == shield,id+" repeated configuration does not recharge")
		# First strike stays spent across configuration.
		check(actor.first_attack_spent,id+" no first-hit reset")
		for skill in data.elite_skills:
			elite_count += 1
			actor.position = Vector2.ZERO
			target.position = Vector2(50,0)
			before = target.current_hp
			check(actor.try_cast_elite_skill(skill),id+" cast "+skill.id)
			if skill.kind == "strike":
				var fixed: Vector2 = actor.pending_position
				actor.position += Vector2(75,0)
				check(actor.pending_position == fixed,id+" warning world anchor")
				actor._physics_process(1.0)
				check(target.current_hp < before,id+" delayed strike lands")
				actor.position = Vector2.ZERO
				check(actor.try_cast_elite_skill(skill),id+" second strike starts")
				target.position = Vector2(1000,0)
				before = target.current_hp
				actor._physics_process(1.0)
				check(target.current_hp == before,id+" warning is dodgeable")
				target.position = Vector2(50,0)
				actor.try_cast_elite_skill(skill)
				actor.set_meta("stun_active",true)
				actor._physics_process(1.0)
				check(actor.pending.is_empty() and target.current_hp == before,id+" stun cancels strike")
				actor.set_meta("stun_active",false)
			elif skill.kind == "fan":
				settle_bolts(arena)
				check(target.current_hp < before,id+" fan hits")
			elif skill.kind == "self_ward":
				var remaining: int = actor.get_meta("temporary_shield_hp",0)
				actor.try_cast_elite_skill(skill)
				check(int(actor.get_meta("temporary_shield_hp",0)) == remaining,id+" elite shield never stacks")
		actor.set_meta("silence_active",true)
		check(not actor.try_cast_elite_skill(data.elite_skills[0]),id+" silence blocks elite")
		actor.set_meta("silence_active",false)
	check(elite_count == 37,"thirty-seven elite skills")
	_test_mechanics(arena,target)
	_test_rare_mechanics(arena,target)
	arena.queue_free()
	await process_frame
	await _test_reinforcements()
	await _test_actual_battle()
	print("FRONTIER_MONSTERS checks=",checks," failures=",failures)
	await create_timer(.15).timeout
	quit(0 if failures == 0 else 1)

func _test_rare_mechanics(arena: Arena,target: Target) -> void:
	var by_id := {}
	for actor in arena.actors: by_id[actor.species_id] = actor
	target.current_hp = target.max_hp
	target.position = Vector2(50,0)
	var panther = by_id.dusk_panther
	panther.position = Vector2.ZERO
	panther.current_hp = panther.max_hp
	panther.first_attack_spent = false
	var before: int = target.current_hp
	panther._attack_target(target)
	check(before-target.current_hp == int(round(panther.attack_damage*2.3)),"rare panther augmented first hit")
	panther.configure_special_augments(config_for("dusk_panther"))
	before = target.current_hp
	panther._attack_target(target)
	check(before-target.current_hp == panther.attack_damage,"rare panther no first hit recharge")
	target.current_hp = int(target.max_hp*.3)
	before = target.current_hp
	panther._attack_target(target)
	check(before-target.current_hp == int(round(panther.attack_damage*1.3)),"rare panther execute threshold and damage")
	target.current_hp = target.max_hp
	for pair in [["frost_owl",.73],["thorn_dryad",.68]]:
		var actor = by_id[pair[0]]
		actor.position = Vector2.ZERO
		target.slow = 1.0
		actor._attack_target(target)
		settle_bolts(arena)
		check(is_equal_approx(target.slow,float(pair[1])),String(pair[0])+" augmented slow on real hit")
	var salamander = by_id.ember_salamander
	salamander.position = Vector2.ZERO
	target.burn = 0
	salamander._attack_target(target)
	settle_bolts(arena)
	check(target.burn == int(round(salamander.attack_damage*.45)),"rare salamander augmented burn payload")
	var scorpion = by_id.venom_scorpion
	scorpion.position = Vector2.ZERO
	target.poison = 0.0
	scorpion._attack_target(target)
	settle_bolts(arena)
	check(is_equal_approx(target.poison,.0035),"rare scorpion augmented current hp poison")
	var moth = by_id.moon_moth
	moth.position = Vector2.ZERO
	for actor in arena.actors: actor.set_meta("support_shield_hp",0)
	moth.attack_count = 1
	moth._attack_target(target)
	var protected := 0
	for actor in arena.actors:
		if int(actor.get_meta("support_shield_hp",0))>0: protected+=1
	check(protected == 3,"rare moth augmented two-attack ward caps three allies")
	check(int(moth.get_meta("support_shield_hp",0)) == 0,"rare moth ward excludes self")
	target.current_hp = target.max_hp

func _test_mechanics(arena: Arena,target: Target) -> void:
	var harpy = arena.actors[0]
	target.position = Vector2(50,0)
	harpy.position = Vector2.ZERO
	harpy.attack_count = 2
	var before: int = target.current_hp
	harpy._attack_target(target)
	check(before-target.current_hp == harpy.attack_damage*2,"harpy empowered third hit")
	check(harpy._get_combat_bonuses().move_speed_multiplier > 1.15,"harpy speed augment plus third boost")
	harpy.current_hp = 1
	target.invulnerable = true
	harpy._attack_target(target)
	check(harpy.current_hp == 1,"invulnerability grants no lifesteal")
	target.invulnerable = false
	harpy._attack_target(target)
	check(harpy.current_hp > 1,"lifesteal heals actual hp loss")
	var imp = arena.actors[1]
	imp.position = Vector2.ZERO
	target.burn = 0
	imp._attack_target(target)
	settle_bolts(arena)
	check(target.burn > 0,"imp burn augment")
	check(imp.attack_range == 460.0 and imp.projectile_speed == 435.0,"imp reach override")
	# A pooled target reused during flight cannot receive a previous-life bolt.
	target.position = Vector2(200,0)
	imp._attack_target(target)
	arena.registry.retire_instance(target.get_instance_id())
	arena.registry.activate(target)
	before = target.current_hp
	settle_bolts(arena)
	check(target.current_hp == before,"stale target generation rejected")
	var rogue = arena.actors[4]
	rogue.position = Vector2.ZERO
	target.position = Vector2(50,0)
	target.current_hp = 20000
	before = target.current_hp
	rogue._attack_target(target)
	check(before-target.current_hp == roundi(rogue.attack_damage*1.65),"satyr rogue execute augment")
	var shaman = arena.actors[5]
	shaman.position = Vector2.ZERO
	# Isolate this caster from shields granted by earlier support elite tests.
	for actor in arena.actors: actor.set_meta("support_shield_hp",0)
	shaman.attack_count = 3
	shaman._attack_target(target)
	settle_bolts(arena)
	check(is_equal_approx(target.slow,.7),"shaman slow augment")
	var warded := 0
	for actor in arena.actors:
		if int(actor.get_meta("support_shield_hp",0)) > 0: warded += 1
	check(warded <= 3 and warded > 0,"ward target cap")
	var slime = arena.actors[7]
	slime._attack_target(target)
	check(is_equal_approx(target.poison,.02) and is_equal_approx(target.slow,.7),"toxic poison and slow augments")
	var mimic = make_actor("mimic",arena)
	mimic.configure_special_augments(config_for("mimic"))
	before = target.current_hp
	mimic._attack_target(target)
	check(before-target.current_hp == roundi(mimic.attack_damage*2.8),"mimic first bite augment")
	before = target.current_hp
	mimic.configure_special_augments(config_for("mimic"))
	mimic._attack_target(target)
	check(before-target.current_hp == mimic.attack_damage,"mimic first bite once per life")
	mimic.try_cast_elite_skill(D.DEFINITIONS.mimic.elite_skills[0])
	mimic.take_damage(mimic.current_hp+10000)
	before = target.current_hp
	mimic._physics_process(1.0)
	check(mimic.dying and mimic.pending.is_empty() and target.current_hp == before,"death cancels delayed attack")

func _test_actual_battle() -> void:
	var old_directory := SCOPE.guest_directory
	SCOPE.guest_directory = "user://frontier_monster_fixture"
	SCOPE.select_guest()
	var scene: PackedScene = load("res://src/battle/Battle.tscn")
	var battle = scene.instantiate()
	battle._monster_spawn_resources_warmed = true
	root.add_child(battle)
	battle.set_external_pause(true)
	battle.hero.max_hp = 100000
	battle.hero.current_hp = 100000
	for id in D.DEFINITIONS:
		battle.demon_special_augments.clear()
		var normal = battle._spawn_monster(id,battle.hero.position+Vector2(300,0))
		check(is_instance_valid(normal) and normal.hero == battle.hero,id+" actual Battle spawn")
		check(normal.visual.is_visual_ready(),id+" actual Battle real normal frames")
		_check_layout(normal,D.DEFINITIONS[id].normal_visual,id+" normal")
		var detail: Dictionary = battle.get_monster_run_detail(id)
		check(normal.max_hp == detail.max_hp and normal.attack_damage == detail.attack_damage,id+" runtime-detail stat parity")
		for aug in A.get_special_augments_for_monster(id): battle.demon_special_augments.append(aug.id)
		var boosted = battle._spawn_monster(id,battle.hero.position+Vector2(330,0))
		check(boosted.special_augment_configs.size() == 3,id+" actual augment configs")
		detail = battle.get_monster_run_detail(id)
		check(boosted.max_hp == detail.max_hp and boosted.attack_damage == detail.attack_damage,id+" augmented hp/damage parity")
		check(is_equal_approx(boosted.attack_cooldown,float(detail.attack_cooldown)),id+" augmented interval parity")
		check(is_equal_approx(boosted.move_speed*float(boosted._get_combat_bonuses().move_speed_multiplier),float(detail.move_speed)),id+" augmented movement parity")
		battle.hero.invulnerability_timer = 0.0
		var before: int = battle.hero.current_hp
		boosted._attack_target(battle.hero)
		for bolt in battle.get_children():
			if bolt.get_script() == preload("res://src/monsters/frontier_bolt.gd") and bolt.active: bolt._physics_process(2.0)
		check(battle.hero.current_hp < before,id+" actual Hero receives attack")
		if boosted.behavior.has("slow_duration"): check(battle.hero.slow_timer > 0.0,id+" actual Hero slow")
		if boosted.behavior.has("poison_ratio"): check(battle.hero.poison_timer > 0.0,id+" actual Hero poison")
		if boosted.behavior.has("burn_ratio"): check(battle.hero.burn_runtime.remaining > 0.0,id+" actual Hero burn")
		battle._apply_special_monster_modifiers(boosted,id,{"type":"elite","hp_multiplier":2.0,"visual_scale":1.5})
		check(String(boosted.get_meta("visual_variant")) == "elite",id+" actual elite conversion")
		_check_layout(boosted,D.DEFINITIONS[id].elite_visual,id+" elite")
		check(boosted.visual.sprite_frames.get_frame_count(&"death") == D.DEFINITIONS[id].elite_visual.animations.death.count,id+" actual elite frames")
		check(int(boosted.get_meta("elite_skill_count")) == D.DEFINITIONS[id].elite_skills.size(),id+" actual elite registration")
	# Stop audio before freeing its scene in the dummy audio backend.
	for host in [battle,root.get_node("GameAudio")]:
		for player in host.find_children("*","AudioStreamPlayer",true,false):
			player.stop()
			player.stream = null
		for player in host.find_children("*","AudioStreamPlayer2D",true,false):
			player.stop()
			player.stream = null
	await process_frame
	battle.queue_free()
	await process_frame
	SCOPE.guest_directory = old_directory
	SCOPE.select_guest()

func _test_reinforcements() -> void:
	for difficulty in ["easy","hard"]:
		for stage in range(1,11):
			check(SURVIVAL.late_recruits(stage,difficulty,299.9).is_empty(),"no new early enemies")
			var expected := SURVIVAL.late_recruits(stage,difficulty,300.0)
			for id in expected: check(SURVIVAL.monster_allowed(id,stage,difficulty),"new enemy respects grade")
			check(expected.size() >= 3,"late common recruits")
			var arena := HARNESS.Arena.new()
			root.add_child(arena)
			arena.current_stage_data.number = stage
			arena.campaign_difficulty = difficulty
			arena.hero = HARNESS.Hero.new()
			arena.add_child(arena.hero)
			arena.hero.position = Vector2(1200,1200)
			var director := DIRECTOR.new()
			director.install(arena)
			director.next_elite = 10000.0
			director.giant_index = SURVIVAL.GIANT_TIMES.size()
			director.encounters.next_event = 10000.0
			arena.run_metrics.elapsed_seconds = 299.9
			director.tick(.1)
			for id in expected: check(id not in director.roster,"director early roster unchanged")
			arena.run_metrics.elapsed_seconds = 300.0
			director.tick(.1)
			for id in expected: check(id in director.roster,"director installs late recruit")
			var size: int = director.roster.size()
			for i in 10: director.tick(.1)
			check(director.roster.size() == size,"late roster never duplicates")
			arena.run_metrics.elapsed_seconds = 419.9
			director.tick(.1)
			for id in preload("res://tests/uncommon_monsters_4_smoke.gd").IDS:
				check(id not in director.roster,"uncommon waits until420s")
			arena.run_metrics.elapsed_seconds = 420.0
			director.tick(.1)
			for id in preload("res://tests/uncommon_monsters_4_smoke.gd").IDS:
				check((id in director.roster) == SURVIVAL.monster_allowed(id,stage,difficulty),"director installs eligible uncommon at420s")
			arena.run_metrics.elapsed_seconds = 539.9
			director.tick(.1)
			for id in preload("res://tests/rare_monsters_8_smoke.gd").IDS:
				check(id not in director.roster,"rare not installed at539.9s")
			arena.run_metrics.elapsed_seconds = 540.0
			director.tick(.1)
			var size_after_rare: int = director.roster.size()
			var checkpoint_after_rare: int = director.next_reinforcement
			for i in 10: director.tick(.1)
			check(director.roster.size() == size_after_rare and director.next_reinforcement == checkpoint_after_rare,"late checkpoints consumed once without duplicate roster")
			arena.population = 0
			arena.run_metrics.elapsed_seconds = 610.0
			var rare_ids: Array = preload("res://tests/rare_monsters_8_smoke.gd").IDS
			var before_rare := SURVIVAL.late_recruits(stage,difficulty,539.9)
			var after_rare := SURVIVAL.late_recruits(stage,difficulty,540.0)
			for id in rare_ids:
				check(id not in before_rare,"rare reinforcement waits until540s")
				check((id in after_rare) == SURVIVAL.monster_allowed(id,stage,difficulty),"rare reinforcement respects stage grade")
			for i in range(20):
				arena.population = 0
				director.think_remaining = 0.0
				director.tick(.1)
			for id in rare_ids:
				check((id in director.roster) == SURVIVAL.monster_allowed(id,stage,difficulty),"director installs eligible rare recruit")
			for id in expected: check(id in arena.normal,"late recruit actually spawned")
			var skipped := DIRECTOR.new()
			skipped.install(arena)
			skipped.next_elite = 10000.0
			skipped.giant_index = SURVIVAL.GIANT_TIMES.size()
			skipped.encounters.next_event = 10000.0
			skipped.tick(.1)
			check(skipped.next_reinforcement == skipped.reinforcement_times.size(),"time jump consumes all due checkpoints")
			for id in after_rare: check(id in skipped.roster,"time jump installs every eligible recruit")
			arena.queue_free()
			await process_frame

func _check_layout(actor,profile: Dictionary,label: String) -> void:
	var sprite: AnimatedSprite2D = actor.visual
	var texture := sprite.sprite_frames.get_frame_texture(&"idle",0)
	var b: Array = profile.source_idle_bounds
	var foot := sprite.to_global(Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))-texture.get_size()*.5+sprite.offset)
	var shadow: Sprite2D = actor.get_node("GroundShadow")
	check(foot.distance_to(shadow.global_position) < .1,label+" foot touches shadow")
	check(absf(foot.x-actor.global_position.x) < .1,label+" body center aligned")
	check(is_equal_approx(actor.visible_body_height,float(profile.body_height)),label+" hero-relative visible height")
	var top := sprite.to_global(Vector2(0,float(profile.source_animation_top)-texture.get_height()*.5)+sprite.offset)
	var bar: Vector2 = actor.to_global(Vector2(0,actor.status_bar_y))
	check(bar.y <= top.y-11.9,label+" bars clear all active animation tops")
	check(shadow.display_size.x*absf(actor.global_scale.x) <= 86.1,label+" bounded shadow width")
