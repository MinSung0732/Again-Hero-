extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const DATA := preload("res://src/data/wolf_behavior_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("WOLF: " + message)

func spawn(position_to_use := Vector2(1100, 1000)):
	var actor = battle._spawn_monster("wolf", position_to_use)
	actor.set_physics_process(false)
	return actor

func target_ready() -> void:
	hero._clear_bleed()
	hero.current_hp = hero.max_hp
	hero.shield_hp = 0
	hero.invulnerability_timer = 0

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://wolf_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1000, 1000)
	hero.max_hp = 100000
	target_ready()
	check(CATALOG.get_rarity("wolf") == "uncommon" and CATALOG.get_species("wolf") == "beast" and CATALOG.get_base_cost("wolf") == 5.0, "classification and cost")
	check(load("res://src/data/shop_catalog.gd").get_monster_pool("uncommon").has("wolf"), "gacha registration")
	check(load("res://src/systems/monster_collection_store.gd").load_state().has("wolf"), "collection registration")
	for augment in AUGMENTS.get_monster_normal_augments("wolf", ""):
		check(AUGMENTS.get_augment(augment.id) == augment, "normal augment lookup")
	var wolf = spawn(hero.position + Vector2(30, 0))
	check(wolf.visual.sprite_frames.get_frame_count("skill") == 3 and wolf.visual.sprite_frames.get_frame_count("attack") == 6, "normal uploaded frames")
	wolf.attack_damage = 13
	wolf._attack_target(hero)
	check(hero.current_hp == hero.max_hp - 7, "first half rounded, attack delayed")
	wolf._tick_followup(0.15)
	check(hero.current_hp == hero.max_hp - 7, "followup still pending")
	wolf._tick_followup(0.02)
	check(hero.current_hp == hero.max_hp - 13, "two hits preserve odd total and bypass own iframe")
	target_ready()
	hero.invulnerability_timer = 99
	wolf._attack_target(hero)
	check(wolf.followup_target == null and hero.current_hp == hero.max_hp, "blocked first hit cannot create iframe-bypassing followup")
	target_ready()
	wolf._attack_target(hero)
	hero.position += Vector2(1000, 0)
	wolf._tick_followup(1.0)
	check(hero.current_hp == hero.max_hp - 7, "second hit checks target range")
	hero.position = Vector2(1000, 1000)
	battle.demon_special_augments.assign(CATALOG.MONSTERS.wolf.special_augment_ids)
	var enhanced = spawn(hero.position + Vector2(30, 0))
	check(enhanced.special_augment_configs.size() == 3, "all specials apply")
	enhanced.attack_damage = 20
	target_ready()
	enhanced._attack_target(hero)
	enhanced._tick_followup(1.0)
	check(hero.current_hp == hero.max_hp - 30 and int(enhanced.hit_counts.get(hero.get_instance_id(), 0)) == 2, "second hit full attack; both accepted hits count")
	hero.invulnerability_timer = 0
	enhanced._deal_hit(hero, 1, false)
	check(hero.bleed_timer == 3 and hero.bleed_total_damage == 1000, "third own hit applies maxHP1percent total bleed")
	var independent = spawn(hero.position + Vector2(20, 0))
	hero._clear_bleed()
	hero.invulnerability_timer = 0
	independent._deal_hit(hero, 1, false)
	hero.invulnerability_timer = 0
	enhanced._deal_hit(hero, 1, false)
	check(hero.bleed_timer == 0, "different wolves do not combine hit counters")
	for hit in range(2):
		hero.invulnerability_timer = 0
		enhanced._deal_hit(hero, 1, false)
	hero._update_bleed(1.0)
	var hp: int = hero.current_hp
	for hit in range(3):
		hero.invulnerability_timer = 0
		enhanced._deal_hit(hero, 1, false)
	check(hero.bleed_timer == 3 and hero.bleed_damage_applied == 0, "bleed refreshes same slot, no stacks")
	hero._update_bleed(3.0)
	check(hero.current_hp == hp - 3 - 1000 and hero.bleed_timer == 0, "exact refreshed bleed budget")
	target_ready()
	var outsider = spawn(Vector2(1600, 1000))
	var dead = spawn(Vector2(1100, 1000))
	dead.take_damage(dead.current_hp + 1000)
	battle.wolf_pack_runtime.tick(0.0)
	check(wolf.howl_timer == 1 and enhanced.howl_timer == 1 and outsider.howl_timer == 0, "nearby allied death begins howl only in radius")
	var old_hp: int = enhanced.current_hp
	enhanced.take_damage(20)
	check(enhanced.current_hp == old_hp - 10 and enhanced.visual.animation == "skill", "half damage during howl without animation interruption")
	wolf._physics_process(0.5)
	check(wolf.howl_buff_timer == 0 and wolf.howl_timer == 0.5, "one-second action lock")
	wolf._physics_process(0.5)
	enhanced._physics_process(1.0)
	check(wolf.howl_buff_timer == 10 and enhanced.howl_buff_timer == 10, "buff starts after cast")
	check(not wolf.can_howl(), "buff over two seconds blocks refresh")
	wolf.howl_buff_timer = 2.0
	check(wolf.can_howl(), "two seconds allows refresh")
	wolf.begin_howl()
	wolf._physics_process(1.0)
	check(wolf.howl_buff_timer == 10, "refresh restores duration without stacking")
	target_ready()
	wolf.attack_damage = 20
	wolf._attack_target(hero)
	wolf._tick_followup(1.0)
	check(hero.current_hp == hero.max_hp - 23, "howl multiplies attack once")
	var elite = spawn(Vector2(1200, 1200))
	battle._apply_special_monster_modifiers(elite, "wolf", {"type":"elite", "name":"엘리트 늑대"})
	check(elite.visual.sprite_frames.get_frame_count("skill") == 3 and elite.visual.sprite_frames.get_frame_texture("skill", 0) == elite.visual.sprite_frames.get_frame_texture("hit", 0), "elite hit fallback")
	battle.elite_monster_skill_runtime.tick(4.9)
	check(elite.pack_cast_timer == 0, "initial cooldown not early")
	battle.elite_monster_skill_runtime.tick(0.11)
	check(elite.pack_cast_timer == 1, "initial five seconds begins pack cast")
	elite._physics_process(0.99)
	check(battle.wolf_pack_runtime.spawn_jobs.is_empty(), "no early pack spawn")
	elite._physics_process(0.02)
	check(battle.wolf_pack_runtime.spawn_jobs.size() == 1, "cast releases one job")
	var before_count: int = battle.monster_population_counts.wolf
	var spawned: Array = []
	for tick_index in range(6):
		battle.wolf_pack_runtime.tick(0.016)
		check(battle.monster_population_counts.wolf == before_count + (tick_index + 1) * 2, "two spawns maximum per tick")
		for actor in battle.wolf_pack_runtime.wolves.values():
			if String(actor.get_meta("spawn_source", "")) == "elite_skill" and not spawned.has(actor):
				actor.set_physics_process(false)
				spawned.append(actor)
	check(spawned.size() == 12 and battle.wolf_pack_runtime.spawn_jobs.is_empty(), "all twelve complete")
	for actor in spawned:
		check(actor.position.x < elite.position.x and actor.special_augment_configs.size() == 3 and actor.get_meta("visual_variant", "normal") == "normal", "behind caster, augmented normal children")
		check(is_equal_approx(actor.move_speed, DATA.BASE.move_speed * 1.3), "thirty percent speed")
		battle._apply_normal_augments_to_existing_monster(actor, "wolf")
		check(is_equal_approx(actor.move_speed, DATA.BASE.move_speed * 1.3), "speed persists across stat refresh")
	var saved_cooldown: float = battle.elite_monster_skill_runtime._skill_states[elite.get_instance_id()].skills[0]._timer
	check(is_equal_approx(saved_cooldown, 20.0), "repeat twenty-second cooldown")
	var canceled = spawn(Vector2(1700, 1700))
	canceled.try_cast_elite_skill({})
	canceled.take_damage(canceled.current_hp + 1000)
	check(canceled.pack_cast_timer == 0 and battle.wolf_pack_runtime.spawn_jobs.is_empty(), "death before release cancels pack")
	battle.wolf_pack_runtime.queue_pack(Vector2(1800, 1800), -1.0)
	battle.set_external_pause(true)
	var paused_count: int = battle.monster_population_counts.wolf
	battle._process(0.2)
	check(battle.monster_population_counts.wolf == paused_count and battle.wolf_pack_runtime.spawn_jobs.size() == 1, "modal pause freezes spawn jobs")
	battle.set_external_pause(false)
	battle.wolf_pack_runtime.spawn_jobs.clear()
	# Batch many deaths before a single runtime tick; each survivor howls once.
	for index in range(32):
		var fallen = spawn(Vector2(1800 + index % 8, 1500 + index / 8))
		fallen.take_damage(fallen.current_hp + 1000)
	var near = spawn(Vector2(1810, 1520))
	var began := Time.get_ticks_usec()
	battle.wolf_pack_runtime.tick(0.0)
	print("WOLF death batch usec: ", Time.get_ticks_usec() - began)
	check(near.howl_timer == 1 and battle.wolf_pack_runtime.used_cells.is_empty(), "batched death grid drained")
	if "--capture" in OS.get_cmdline_user_args():
		await gallery(wolf, elite, spawned)
	battle.wolf_pack_runtime.reset()
	check(battle.wolf_pack_runtime.wolves.is_empty() and battle.wolf_pack_runtime.spawn_jobs.is_empty(), "reset clears registry and queue")
	battle.free()
	await create_timer(0.2).timeout
	print("WOLF: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)

func gallery(normal: Node2D, elite: Node2D, pack: Array) -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var back := ColorRect.new()
	back.size = Vector2(1080,1920)
	back.color = Color(0.09,0.08,0.13)
	layer.add_child(back)
	normal.reparent(layer)
	normal.position = Vector2(270,350)
	normal.visual.play_skill()
	normal.visual.stop()
	normal.visual.frame = 1
	elite.reparent(layer)
	elite.position = Vector2(810,350)
	elite.visual.play_skill()
	elite.visual.stop()
	elite.visual.frame = 1
	for index in range(pack.size()):
		pack[index].reparent(layer)
		pack[index].position = Vector2(210 + (index % 3) * 320, 850 + (index / 3) * 230)
	var label := Label.new()
	label.text = "Wolf howl / Elite hit fallback\nPack hunt: 12 augmented wolves, speed +30%"
	label.position = Vector2(70,100)
	label.add_theme_font_size_override("font_size",32)
	layer.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	root.get_texture().get_image().save_png(args[args.find("--capture") + 1])
	layer.free()
