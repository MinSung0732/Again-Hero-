extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
class TrainingTarget extends Node2D:
	var current_hp := 1000
	var shield_hp := 0
	func take_damage(amount: int, _source: Node) -> void:
		current_hp = maxi(current_hp - amount, 0)

var failed := false
var battle
var hero
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("DULLAHAN_TEST: " + message)
func spawn(position_to_use := Vector2(800, 1000)):
	var knight = battle._spawn_monster("dullahan", position_to_use)
	knight.set_physics_process(false)
	return knight
func hit(knight, amount := 100) -> int:
	hero.invulnerability_timer = 0.0
	return knight._deal_hit(hero, amount)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://dullahan_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	battle.set_process(false)
	battle.set_physics_process(false)
	hero = battle.hero
	hero.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	hero.status_resistances.clear()
	hero.position = Vector2(1000,1000)
	check(CATALOG.get_rarity("dullahan") == "legendary" and CATALOG.get_species("dullahan") == "undead" and CATALOG.get_base_cost("dullahan") == 12, "catalog identity")
	check(CATALOG.get_grade_label("legendary") == "전설", "Korean grade label")
	for candidate in AUGMENTS.get_monster_normal_augments("dullahan", ""):
		check(AUGMENTS.get_augment(candidate.id) == candidate, "normal augment resolves " + candidate.id)
	var configs: Dictionary = {}
	for id in CATALOG.MONSTERS.dullahan.special_augment_ids:
		var augment := AUGMENTS.get_augment(id)
		check(not augment.is_empty(), "special registered " + id)
	# Use the same resolved runtime configs as the battle's special registry.
	battle.demon_special_augments.assign(CATALOG.MONSTERS.dullahan.special_augment_ids)
	configs = battle._get_special_augment_config("dullahan")
	var knight = spawn()
	check(knight.visual.sprite_frames.get_frame_count("attack") == 6, "normal frames")
	check(is_equal_approx(knight.visual.sprite_frames.get_frame_texture("idle",0).get_height() * knight.visual.scale.y, 230), "normal two-times combat height")
	check(knight.shield_hp == knight.max_hp * 2, "wall uses effective maximum HP")
	var initial_hp: int = knight.current_hp
	knight.take_damage(100)
	check(knight.current_hp == initial_hp and knight.shield_hp == knight.max_hp * 2 - 100, "shield absorbs before health")
	knight.configure_special_augments(configs)
	check(knight.shield_hp == knight.max_hp * 2 - 100, "config refresh does not refill shield")
	knight._physics_process(0.01)
	check(is_equal_approx(knight.velocity.length(), knight.move_speed * 0.7), "approach slowed thirty percent")
	var training := TrainingTarget.new()
	battle.add_child(training)
	knight.current_hp = 100
	check(knight._deal_hit(training, 100) == 100 and knight.current_hp == 150 and knight.shield_hp > 0, "void target damage heals but keeps wall until hero damage")
	training.free()
	knight.current_hp = 100
	hero.invulnerability_timer = 10
	check(knight._deal_hit(hero,100) == 0 and not knight.has_dealt_damage and knight.shield_hp > 0, "rejected hit preserves shield and no healing")
	var applied := hit(knight)
	check(applied > 0 and knight.has_dealt_damage and knight.shield_hp == 0 and knight.current_hp == 100 + int(round(applied * 0.5)), "first damage clears shield and heals actual fifty percent")
	battle.demon_special_augments.clear()
	var plain = spawn()
	plain.current_hp = 100
	applied = hit(plain)
	check(plain.current_hp == 100 + int(round(applied * 0.4)), "base lifesteal forty percent")
	hero.set_meta("dullahan_soul_stacks",0)
	var second = spawn()
	second.configure_special_augments(configs)
	hero._clear_stun()
	for i in range(11):
		hit(knight if i % 2 == 0 else second, 10)
	check(hero.stun_timer == 0 and hero.get_meta("dullahan_soul_stacks") == 11, "eleven shared hits no early stun")
	hit(second,10)
	check(hero.stun_timer == 2 and hero.get_meta("dullahan_soul_stacks") == 0, "twelfth shared hit consumes stacks and stuns")
	var fx := FX.new()
	hero.add_child(fx)
	fx.setup(hero,"stun")
	fx._process(1)
	check(fx.visible and fx.sprite_frames.get_frame_count("fx") == 4, "stun pixel frames")
	var fx2 := FX.new()
	hero.add_child(fx2)
	fx2.setup(hero,"stun")
	check(fx.sprite_frames == fx2.sprite_frames, "stun cached frames")
	var hero_position: Vector2 = hero.position
	var attack_timer: float = hero.attack_timer
	hero._physics_process(0.5)
	check(hero.position == hero_position and hero.velocity == Vector2.ZERO and hero.attack_timer == attack_timer and hero.hero_sprite.speed_scale == 0, "stun stops movement and attack animation/action")
	hero._physics_process(1.5)
	check(hero.stun_timer == 0 and not hero.get_meta("stun_active") and hero.hero_sprite.speed_scale > 0, "stun ends and animation resumes")
	hero.status_resistances.stun = 0.5
	hero.apply_stun(2)
	check(hero.stun_timer == 1, "stun resistance")
	hero._clear_stun()
	hero.status_resistances.clear()
	plain.current_hp = int(plain.max_hp * 0.2)
	plain.position = Vector2(850,1000)
	plain._physics_process(0.01)
	check(plain.danger_state == 1 and is_equal_approx(plain.velocity.length(), plain.move_speed * 3.25), "danger at threshold flees at plus225percent")
	plain.position = Vector2(650,1000)
	plain._physics_process(0.01)
	check(plain.danger_state == 2 and plain.velocity == Vector2.ZERO, "escape enters rest")
	plain._physics_process(1.5)
	check(plain.current_hp > plain.max_hp * 0.2 and plain.current_hp < plain.max_hp * 0.5, "rest gradual healing")
	plain.take_damage(10)
	plain._physics_process(1.5)
	check(plain.danger_state == 0 and plain.current_hp == int(round(plain.max_hp * 0.5)), "three-second rest finishes at fifty percent")
	plain.current_hp = 1
	plain._physics_process(0.01)
	check(plain.danger_state == 0, "danger cooldown prevents repeat")
	var deaths := [0]
	plain.died.connect(func(): deaths[0] += 1)
	plain.take_damage(plain.max_hp)
	check(plain.reviving and deaths[0] == 0 and not plain.dying, "first lethal hit is revival not counted death")
	await create_timer(0.5).timeout
	plain._tick_revival()
	await create_timer(0.5).timeout
	check(not plain.reviving and plain.current_hp == int(round(plain.max_hp * 0.15)), "death and reverse finish base fifteen percent revival")
	plain.take_damage(plain.max_hp)
	check(plain.dying and deaths[0] == 1, "second lethal hit final death exactly once")
	second.shield_hp = 0
	second.take_damage(second.max_hp)
	await create_timer(0.5).timeout
	second._tick_revival()
	await create_timer(0.5).timeout
	check(second.current_hp == int(round(second.max_hp * 0.3)) and not second.reviving, "empowered thirty percent revival")
	var elite = spawn(Vector2(1100,1000))
	battle._apply_special_monster_modifiers(elite,"dullahan",{"type":"elite"})
	check(elite.visual.sprite_frames.get_frame_count("death") == 7 and elite.visual.sprite_frames.get_frame_count("hit") == 2, "elite frames include authored hyphen file")
	var armored_elite = spawn(Vector2(600,1000))
	armored_elite.configure_special_augments(configs)
	battle._apply_special_monster_modifiers(armored_elite,"dullahan",{"type":"elite", "hp_multiplier":2.0})
	check(armored_elite.shield_hp == armored_elite.max_hp * 2, "elite scaling preserves two-maxHP wall capacity")
	armored_elite.take_damage(100)
	var shield_fraction: float = float(armored_elite.shield_hp) / armored_elite.max_hp
	armored_elite.max_hp *= 2
	armored_elite.configure_special_augments(configs)
	check(is_equal_approx(float(armored_elite.shield_hp)/armored_elite.max_hp, shield_fraction), "HP growth scales remaining shield without refill")
	armored_elite.revive_used = true
	armored_elite.shield_hp = 0
	armored_elite.take_damage(armored_elite.max_hp)
	armored_elite.free()
	check(is_equal_approx(elite.visual.sprite_frames.get_frame_texture("idle",0).get_height() * elite.visual.scale.y, 280), "elite two-times combat height")
	var runtime = battle.elite_monster_skill_runtime
	runtime.tick(0.01)
	check(elite.charge_timer == 5, "elite charge immediate once")
	elite._physics_process(0.1)
	check(is_equal_approx(elite.velocity.length(), elite.move_speed * 2), "elite approaches at two hundred percent")
	elite.charge_timer = 0
	runtime.tick(4.8)
	check(elite.charge_timer == 0 and elite.slam_state == 0 and elite.march_remaining == 0, "charge not repeated and initial skill cooldowns")
	elite.position = hero.position + Vector2(60,0)
	runtime.tick(0.3)
	check(elite.slam_state == 1 and elite.visual.modulate.g < 1, "slam initial five red windup")
	hero.invulnerability_timer = 0
	hero._clear_stun()
	elite._tick_slam(0.35)
	check(elite.slam_state == 2 and elite.visual.animation == "attack" and elite.visual.modulate.g < 1, "red maintained through attack frames")
	var before_hp: int = hero.current_hp
	await create_timer(0.5).timeout
	check(hero.current_hp < before_hp and hero.stun_timer == 1.5 and elite.visual.modulate == Color.WHITE, "slam damage stun and red restored after animation")
	runtime.tick(4.9)
	check(elite.march_remaining == 10, "march initial ten seconds")
	# Deliberately exaggerate every inherited growth source before reinforcements.
	battle.demon_level = 30
	battle.monster_hp_multiplier = 10
	battle.monster_damage_multiplier = 10
	battle.monster_speed_multiplier = 10
	battle.monster_attack_speed_multiplier = 0.1
	for id in ["skeleton", "skeleton_archer"]:
		battle.monster_collection_upgrade_levels[id] = 20
		battle.monster_augment_modifiers[id] = {"hp":10.0,"damage":10.0,"speed":10.0,"attack_cooldown":0.1}
		battle.demon_special_augments.append_array(CATALOG.MONSTERS[id].special_augment_ids)
	for id in ["monster_power", "monster_vitality", "monster_mobility", "monster_attack_speed"]:
		battle.permanent_research_levels[id] = 50
	var before_count: int = battle.active_monsters.size()
	elite._tick_march(0.5)
	var child
	for monster in battle.active_monsters.values():
		if monster.get_meta("summon_animation_active",false):
			child = monster
	check(is_instance_valid(child), "first sequential summoned skeleton")
	if is_instance_valid(child):
		check(child.monster_type in ["skeleton","skeleton_archer"] and child.position.distance_to(elite.position) <= 250.01, "random skeleton inside diameter500")
		check(child.visual._revival_reverse_playing and COMMON.is_forced_movement_locked(child), "reverse death locks action")
		child.take_damage(1)
		check(child.visual._revival_reverse_playing, "incoming hit cannot interrupt reverse and strand lock")
		await create_timer(0.8).timeout
		check(not COMMON.is_forced_movement_locked(child), "summon reverse ends before action")
	elite._tick_march(4.5)
	check(elite.march_remaining == 0 and battle.active_monsters.size() == before_count + 10, "exactly ten over five seconds")
	for id in ["skeleton", "skeleton_archer"]:
		var seen := false
		for monster in battle.active_monsters.values():
			if monster.monster_type != id or not monster.get_meta("fixed_base_stats", false):
				continue
			seen = true
			monster.set_physics_process(false)
			for stat in CATALOG.get_base_stats(id):
				if stat != "exp_reward" and monster.get(stat) != null:
					check(is_equal_approx(float(monster.get(stat)), float(CATALOG.get_base_stats(id)[stat])), "level zero base stat " + id + ":" + stat)
			check(monster.special_augment_configs.is_empty() and monster.get_meta("monster_collection_upgrade_level") == 0 and monster.exp_reward == 0, "no augment/collection growth or extra summon EXP")
			monster.take_damage(1)
			var hp: int = monster.current_hp
			battle._apply_normal_augments_to_existing_monster(monster,id)
			battle._apply_special_augments_to_monster(monster,id)
			battle._apply_demon_level_scaling_to_monster(monster,true)
			check(monster.current_hp == hp and monster.max_hp == CATALOG.get_base_stats(id).max_hp and monster.attack_damage == CATALOG.get_base_stats(id).attack_damage and monster.special_augment_configs.is_empty(), "later growth refresh stays excluded " + id)
		# Deterministically cover either type if the random ten selected only the other.
		if not seen:
			var fixture = battle._spawn_monster(id, Vector2(600,1000),0.0,true,{"fixed_base_stats":true})
			fixture.set_physics_process(false)
			check(fixture.max_hp == CATALOG.get_base_stats(id).max_hp and fixture.attack_damage == CATALOG.get_base_stats(id).attack_damage and fixture.special_augment_configs.is_empty(), "missing random type fixed-base fixture " + id)
	runtime.tick(29)
	check(elite.march_remaining == 0, "march waits forty-second cooldown")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		knight.position = hero.position + Vector2(-100,0)
		knight.current_hp = knight.max_hp
		elite.position = hero.position + Vector2(100,0)
		hero.apply_stun(2)
		fx._process(1)
		var camera := Camera2D.new()
		battle.add_child(camera)
		camera.position = hero.position
		camera.zoom = Vector2(3,3)
		camera.make_current()
		root.size = Vector2i(900,700)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
	runtime.reset()
	battle.free()
	await create_timer(0.2).timeout
	print("DULLAHAN_SMOKE_FAILED" if failed else "DULLAHAN_SMOKE_OK")
	quit(1 if failed else 0)
