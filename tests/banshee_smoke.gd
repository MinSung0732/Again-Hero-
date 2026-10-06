extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BANSHEE_TEST: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://banshee_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	battle.set_process(false)
	battle.set_physics_process(false)
	var hero = battle.hero
	hero.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero.max_hp = 10000
	hero.current_hp = 10000
	hero.shield_hp = 0
	hero.status_resistances.clear()
	hero.invulnerability_timer = 0
	check(CATALOG.get_base_cost("banshee") == 6.5 and CATALOG.get_rarity("banshee") == "uncommon" and CATALOG.get_species("banshee") == "undead", "catalog cost/rarity/species")
	check(CATALOG.get_base_stats("banshee").attack_cooldown == 1.0, "normal attack speed")
	# Every generated choice must resolve when clicked and when build counts rebuild.
	for monster_id in CATALOG.ORDER:
		for candidate in AUGMENTS.get_monster_normal_augments(monster_id, ""):
			check(AUGMENTS.get_augment(candidate.id) == candidate, "normal choice resolves: " + candidate.id)
	var normal_choices := AUGMENTS.get_monster_normal_augments("banshee", "")
	for candidate in normal_choices:
		battle.demon_augment_selection_active = true
		battle.demon_augment_candidates.assign([candidate])
		battle.demon_pending_augments = 1
		check(battle.choose_demon_augment(candidate.id), "banshee normal click accepted: " + candidate.id)
		check(battle.demon_build_counts.get(candidate.id, 0) == 1, "normal count recorded")
	var augmented = battle._spawn_monster("banshee", Vector2(500,1000))
	augmented.set_physics_process(false)
	check(augmented.max_hp > 88 and augmented.move_speed > 110.0 and augmented.attack_cooldown < 1.0, "normal HP/speed/attack speed applied to new banshee")
	check(battle.monster_augment_modifiers.banshee.damage > 1.0, "normal damage retained after rebuild")
	for candidate in normal_choices:
		battle.demon_augment_selection_active = true
		battle.demon_augment_candidates.assign([candidate])
		battle.demon_pending_augments = 1
		check(battle.choose_demon_augment(candidate.id), "second normal choice accepted")
		check(battle.demon_build_counts.get(candidate.id, 0) == 2, "normal stacks increment")
	check(is_equal_approx(augmented.move_speed, 110.0 * 1.04 * 1.04), "later normal choice updates living banshee")
	augmented.free()
	battle.demon_build_counts.clear()
	battle.monster_augment_modifiers.clear()
	for id in CATALOG.MONSTERS.banshee.special_augment_ids:
		check(not AUGMENTS.get_augment(id).is_empty(), "augment registered: " + id)
	for duration in [3.0, 5.0, 10.0, 0.75]:
		hero.current_hp = 10000
		hero._clear_bleed()
		check(hero.apply_bleed(duration), "bleed starts")
		var timer: float = hero.bleed_timer
		check(not hero.apply_bleed(10.0) and hero.bleed_timer == timer, "bleed no stack or refresh")
		for i in range(int(ceil(duration / 0.25))):
			hero._update_bleed(0.25)
		check(hero.current_hp == 10000 - int(round(40 * duration)), "exact duration-scaled bleed damage: " + str(duration))
		check(not hero.get_meta("bleed_active"), "bleed ends")
	hero.current_hp = 10000
	hero._clear_bleed()
	hero.apply_bleed(0.1)
	hero._update_bleed(1.0)
	check(hero.current_hp == 9996, "large delta flushes final partial tick")
	hero.current_hp = 10000
	hero.position = Vector2(1000,1000)
	var banshee = battle._spawn_monster("banshee", Vector2(700,1000), 6.5)
	banshee.set_physics_process(false)
	check(banshee.visual.sprite_frames.get_frame_count("attack") == 6 and banshee.visual.sprite_frames.get_frame_count("hit") == 2, "existing normal frames loaded")
	banshee.configure_special_augments({"banshee_bleeding": {"chance": 1.0, "duration": 3.0}, "banshee_charge_stealth": {"damage_taken_multiplier": 0.5}})
	var pos: Vector2 = banshee.position
	banshee._physics_process(0.1)
	check(banshee.charge_state == 1 and banshee.position == pos and banshee.visual.animation == "attack", "one attack telegraph, no movement")
	check(banshee.visual.modulate.g < 1 and banshee.visual.modulate.g > 0.62, "gentle red fade")
	banshee._physics_process(0.5)
	check(banshee.charge_state == 2, "windup completes")
	banshee._physics_process(0.01)
	check(is_equal_approx(banshee.velocity.length(), banshee.move_speed * 3.0), "300 percent pursuit")
	check(banshee.get_meta("banshee_charge_stealth_active") and is_equal_approx(banshee.visual.modulate.a,0.35), "stealth only during pursuit")
	var hp: int = banshee.current_hp
	banshee.take_damage(10)
	check(banshee.current_hp == hp - 5, "stealth reduces damage by 50 percent")
	hero.invulnerability_timer = 10
	check(banshee._deal_attack_damage() == 0 and hero.bleed_timer == 0, "rejected hit applies no debuffs")
	hero.invulnerability_timer = 0
	var hero_hp: int = hero.current_hp
	banshee._deal_attack_damage()
	check(hero.current_hp == hero_hp - banshee.attack_damage - int(round(hero_hp * 0.005)), "single base plus current HP hit")
	check(is_equal_approx(hero.move_multiplier, 0.90) and is_equal_approx(hero.slow_timer, 1.0) and is_equal_approx(hero.bleed_timer,3.0), "slow and three second bleed on accepted hit")
	hero._clear_bleed()
	hero.fear_timer = 0
	hero.possession_immunity_timer = 0
	var elite = battle._spawn_monster("banshee", Vector2(800,1100),0,false,{"exclude_all_augments":true})
	elite.set_physics_process(false)
	battle._apply_special_monster_modifiers(elite,"banshee",{})
	var runtime = battle.elite_monster_skill_runtime
	elite.current_hp = 1
	runtime.tick(4.9)
	check(hero.fear_timer == 0, "initial cooldown five seconds")
	runtime.tick(0.2)
	check(hero.fear_timer == 2 and elite.current_hp == 1, "two second possession with nonlethal cost")
	hero.fear_timer = 0
	hero.possession_immunity_timer = 0
	runtime.tick(19.0)
	check(hero.fear_timer == 0, "possession cannot cast before twenty seconds")
	hero.possession_immunity_timer = 3
	runtime.tick(1.0)
	check(hero.fear_timer == 0, "post-fear target immunity blocks possession")
	hero.possession_immunity_timer = 0
	elite.current_hp = elite.max_hp
	runtime.tick(0.1)
	check(elite.current_hp == elite.max_hp - int(round(elite.max_hp * 0.20)) and hero.fear_timer == 2, "twenty percent self HP cost")
	var fx := FX.new()
	hero.add_child(fx)
	fx.setup(hero,"fear")
	fx._process(1.0)
	check(fx.visible and fx.sprite_frames.get_frame_count("fx") == 4 and fx.sprite_frames.get_frame_texture("fx",0).resource_path.contains("fear_frames"), "real fear pixel effect")
	var fx2 := FX.new()
	hero.add_child(fx2)
	fx2.setup(hero,"fear")
	check(fx2.sprite_frames == fx.sprite_frames, "fear frame cache reused")
	battle.demon_special_augments.assign(["banshee_death_possession", "banshee_bleeding", "banshee_charge_stealth"])
	battle.monster_hp_multiplier = 5
	battle.monster_damage_multiplier = 5
	battle.monster_speed_multiplier = 5
	battle.monster_attack_speed_multiplier = 0.2
	battle.monster_augment_modifiers["banshee"] = {"hp": 5.0,"damage":5.0,"speed":5.0,"attack_cooldown":0.2}
	battle.banshee_deaths_toward_elite = 29
	var dead = battle._spawn_monster("banshee",Vector2(600,1000))
	dead.set_physics_process(false)
	dead.take_damage(dead.current_hp)
	check(battle.banshee_deaths_toward_elite == 0, "thirtieth death consumes counter")
	var spawned: Node2D
	for monster in battle.active_monsters.values():
		if monster != elite and bool(monster.get_meta("exclude_all_augments",false)):
			spawned = monster
	check(is_instance_valid(spawned), "death threshold spawns elite")
	if is_instance_valid(spawned):
		spawned.set_physics_process(false)
		check(spawned.max_hp == 88 and spawned.attack_damage == 4 and is_equal_approx(spawned.move_speed,110) and is_equal_approx(spawned.attack_cooldown,1), "spawned elite excludes all normal/global augments")
		battle._refresh_alive_monsters_for_augments()
		check(spawned.special_augment_configs.is_empty() and spawned.max_hp == 88, "later augment selections stay excluded")
		check(spawned.get_meta("visual_variant") == "elite" and spawned.visual.sprite_frames.get_frame_count("death") == 5, "elite visual and skill linked")
		if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			hero.position = Vector2(1000,1000)
			hero.invulnerability_timer = 0
			hero.modulate = Color.WHITE
			banshee.position = Vector2(930,1000)
			banshee.visual.modulate = Color.WHITE
			banshee.visual.play_locomotion(false)
			spawned.position = Vector2(1070,1000)
			var camera := Camera2D.new()
			battle.add_child(camera)
			camera.position = hero.position
			camera.zoom = Vector2(3,3)
			camera.make_current()
			root.size = Vector2i(900,700)
			fx._process(1.0)
			await process_frame
			await RenderingServer.frame_post_draw
			var path := OS.get_cmdline_user_args()[-1]
			root.get_texture().get_image().save_png(path)
		spawned.take_damage(spawned.current_hp)
		check(battle.banshee_deaths_toward_elite == 0, "unaugmented elite death cannot feed recursion")
	runtime.reset()
	runtime = null
	battle.free()
	await create_timer(0.2).timeout
	print("BANSHEE_SMOKE_OK" if not failed else "BANSHEE_SMOKE_FAILED")
	quit(1 if failed else 0)
