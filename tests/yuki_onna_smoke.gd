extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const DATA := preload("res://src/data/yuki_onna_behavior_catalog.gd")
const SHOT := preload("res://src/monsters/yuki_onna_projectile.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error("YUKI: " + message)

func spawn(position_to_use := Vector2(1100,1000)):
	var actor = battle._spawn_monster("yuki_onna",position_to_use)
	actor.set_physics_process(false)
	return actor

func fire(actor: Node2D) -> Array:
	actor._fire_projectile(Vector2.LEFT * 180.0)
	var shots: Array = []
	for child in battle.get_children():
		if child is SHOT and child.active and child.source_ref.get_ref() == actor:
			child.set_physics_process(false)
			shots.append(child)
	return shots

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://yuki_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1000,1000)
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	hero.invulnerability_timer = 0
	check(CATALOG.get_rarity("yuki_onna") == "rare" and CATALOG.get_species("yuki_onna") == "humanoid" and CATALOG.get_role("yuki_onna") == "control" and CATALOG.get_base_cost("yuki_onna") == 5.5,"classification/cost")
	check(load("res://src/data/shop_catalog.gd").get_monster_pool("rare").has("yuki_onna") and load("res://src/systems/monster_collection_store.gd").load_state().has("yuki_onna"),"gacha/collection")
	for augment in AUGMENTS.get_monster_normal_augments("yuki_onna",""):
		check(AUGMENTS.get_augment(augment.id) == augment,"normal augment lookup")
	var actor = spawn()
	for kind in ["Watcher","OpenGate"]:
		var immune_summon = load("res://src/hero/Summoner%s.tscn" % kind).instantiate()
		battle.add_child(immune_summon)
		immune_summon.activate(Vector2(1500,1500),hero,{})
		immune_summon.set_physics_process(false)
		var immune_shot = fire(actor)[0]
		immune_shot._on_body_entered(immune_summon)
		check(not battle.yuki_runtime.targets.has(immune_summon.get_instance_id()),"invulnerable summon excluded " + kind)
		immune_summon.deactivate(false)
	await process_frame
	check(actor.attack_range == 200 and actor.projectile_speed == 250,"diameter400 and speed250")
	for animation in DATA.NORMAL_VISUAL.animations:
		check(actor.visual.sprite_frames.get_frame_count(animation) == int(DATA.NORMAL_VISUAL.animations[animation].count),"normal art " + animation)
	var first = fire(actor)[0]
	var shot_id: int = first.get_instance_id()
	check(first.projectile_sprite.sprite_frames.get_frame_count("fly") == 8,"eight-frame projectile")
	first._on_body_entered(hero)
	check(battle.yuki_runtime.targets[hero.get_instance_id()].count == 1 and is_equal_approx(hero._get_effective_move_multiplier(),0.9),"accepted projectile applies ten percent slow")
	var hp: int = hero.current_hp
	first._on_body_entered(hero)
	check(hero.current_hp == hp and battle.yuki_runtime.targets[hero.get_instance_id()].count == 1,"duplicate collision ignored")
	await process_frame
	var reused = fire(actor)[0]
	check(reused.get_instance_id() == shot_id and reused.slow_cap == 10 and reused.slow_ratio == 0.1,"projectile pool reuse and reset")
	hero.invulnerability_timer = 100
	reused._on_body_entered(hero)
	check(battle.yuki_runtime.targets[hero.get_instance_id()].count == 1,"immune hit does not stack")
	for index in range(12):
		battle.yuki_runtime.apply_hit(hero,0.1,10,actor)
	var entry: Dictionary = battle.yuki_runtime.targets[hero.get_instance_id()]
	check(entry.count == 10 and is_equal_approx(entry.stack_move,pow(0.9,10)),"shared slow cap ten and multiplicative factors")
	hero.move_multiplier = 0.5
	check(is_equal_approx(hero._get_effective_move_multiplier(),pow(0.9,10)*0.5),"existing slow remains independent")
	battle.yuki_runtime.tick(5.0)
	check(battle.yuki_runtime.targets.is_empty() and hero._get_effective_move_multiplier() == 0.5,"expiry restores only yuki slow")
	hero.move_multiplier = 1.0
	var outside = spawn(Vector2(1600,1000))
	for index in range(6):
		var dead = spawn(Vector2(1120 + index,1000))
		dead.take_damage(dead.current_hp + 1000)
	battle.yuki_runtime.tick(0.0)
	check(actor.chill_stacks == 5 and outside.chill_stacks == 0,"death batch radius and five chill cap")
	check(is_equal_approx(actor._get_effective_attack_cooldown(),actor.attack_cooldown/pow(1.1,5)) and is_equal_approx(actor.chill_projectile_speed,pow(1.05,5)) and is_equal_approx(actor.chill_slow_strength,pow(1.02,5)),"all chill bonuses multiply")
	var chill = actor.get_node("StatusFX_yuki_chill")
	check(chill.visible and chill.sprite_frames.get_frame_count("fx") == 4,"freezing four-frame visual")
	actor._physics_process(4.0)
	check(actor.chill_stacks == 5,"chill lasts five seconds")
	actor._physics_process(1.01)
	check(actor.chill_stacks == 0 and actor.chill_attack_speed == 1,"chill expiry restores bonuses")
	actor.apply_chill(2)
	actor._physics_process(2.0)
	actor.apply_chill(1)
	actor._physics_process(3.01)
	check(actor.chill_stacks == 1,"each chill stack expires independently")
	battle.demon_special_augments.assign(CATALOG.MONSTERS.yuki_onna.special_augment_ids)
	var enhanced = spawn(Vector2(1250,1000))
	enhanced.apply_chill(20)
	check(enhanced.chill_stacks == 8 and enhanced.max_slow_stacks == 15,"special caps eight/fifteen")
	var fans := fire(enhanced)
	check(fans.size() == 3,"three fan projectiles")
	check(is_equal_approx(fans[0].direction.dot(fans[1].direction),cos(DATA.FAN_ANGLE)) and fans[0].direction.y * fans[2].direction.y < 0,"symmetric fifteen-degree fan")
	check(is_equal_approx(fans[0].speed,250.0*pow(1.05,8)) and is_equal_approx(fans[0].slow_ratio,0.1*pow(1.02,8)),"projectiles snapshot chill modifiers")
	battle._apply_normal_augments_to_existing_monster(enhanced,"yuki_onna")
	check(enhanced.chill_stacks == 8 and is_equal_approx(enhanced._get_effective_attack_cooldown(),enhanced.attack_cooldown/pow(1.1,8)),"stat refresh preserves active chill")
	for index in range(15):
		battle.yuki_runtime.apply_hit(hero,0.1,15,enhanced)
	check(battle.yuki_runtime.targets[hero.get_instance_id()].count == 15,"increased slow cap without elite")
	var elite = spawn(Vector2(1300,1100))
	battle._apply_special_monster_modifiers(elite,"yuki_onna",{"type":"elite","name":"엘리트 설녀"})
	for animation in DATA.ELITE_VISUAL.animations:
		check(elite.visual.sprite_frames.get_frame_count(animation) == int(DATA.ELITE_VISUAL.animations[animation].count),"elite art " + animation)
	check(elite.elite_snowflake,"passive registered")
	elite.attack_damage = 20
	hero.invulnerability_timer = 100
	hp = hero.current_hp
	battle.yuki_runtime.tick(0.0)
	entry = battle.yuki_runtime.targets[hero.get_instance_id()]
	check(entry.count == 0 and hero.current_hp == hp - 40 and is_equal_approx(hero._get_effective_move_multiplier(),0.01) and entry.burst_timer == 2,"new elite consumes existing full stacks without another hit,200percent damage and99percent slow")
	hp = hero.current_hp
	battle.yuki_runtime.tick(0.0)
	check(hero.current_hp == hp,"one consumption cannot trigger multiple elites or duplicate ticks")
	battle.yuki_runtime.tick(1.0)
	check(is_equal_approx(hero._get_effective_move_multiplier(),0.01),"burst remains for two seconds")
	battle.yuki_runtime.tick(1.01)
	check(hero._get_effective_move_multiplier() == 1 and battle.yuki_runtime.targets.is_empty(),"burst expires independently")
	battle.yuki_runtime.apply_hit(hero,0.1,10,actor)
	battle.set_external_pause(true)
	var timer: float = battle.yuki_runtime.targets[hero.get_instance_id()].timer
	battle._process(2.0)
	check(battle.yuki_runtime.targets[hero.get_instance_id()].timer == timer,"modal freezes status runtime")
	battle.set_external_pause(false)
	var doomed = spawn(Vector2(1400,1300))
	var orphan_shot = fire(doomed)[0]
	doomed.free()
	hero.invulnerability_timer = 0
	hero.shield_hp = 100
	var previous_stacks: int = battle.yuki_runtime.targets[hero.get_instance_id()].count
	orphan_shot._on_body_entered(hero)
	check(battle.yuki_runtime.targets[hero.get_instance_id()].count == previous_stacks + 1,"released shot survives source deletion and shield hit stacks")
	hero.shield_hp = 0
	for kind in ["Scout","Hound","SuicideDrone","Gatekeeper"]:
		var summon = load("res://src/hero/Summoner%s.tscn" % kind).instantiate()
		battle.add_child(summon)
		summon.activate(Vector2(1500,1500),hero,{})
		summon.set_physics_process(false)
		battle.yuki_runtime.apply_hit(summon,0.1,10,actor)
		check(is_equal_approx(float(summon.get_meta("yuki_slow_multiplier",1.0)),0.9),"summon accepted status " + kind)
		summon.deactivate(false)
		summon.activate(Vector2(1500,1500),hero,{})
		summon.set_physics_process(false)
		check(summon.get_meta("yuki_slow_multiplier",0.0) == 1.0,"pooled summon starts clean " + kind)
		check(not summon.get_node("StatusFX_yuki_slow").visible,"old visual hidden immediately " + kind)
		battle.yuki_runtime.tick(0.0)
		check(not battle.yuki_runtime.targets.has(summon.get_instance_id()),"old generation removed " + kind)
		summon.deactivate(false)
	if "--capture" in OS.get_cmdline_user_args():
		await gallery(actor,enhanced,elite,fans)
	battle.yuki_runtime.reset()
	check(hero._get_effective_move_multiplier() == 1 and battle.yuki_runtime.actors.is_empty() and battle.yuki_runtime.targets.is_empty(),"reset restores movement and clears registries")
	battle.free()
	await create_timer(0.2).timeout
	print("YUKI: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)

func gallery(normal: Node2D,chilled: Node2D,elite: Node2D,fans: Array) -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var back := ColorRect.new()
	back.size = Vector2(1080,1920)
	back.color = Color(0.09,0.08,0.13)
	layer.add_child(back)
	var actors := [normal,chilled,elite]
	for index in range(actors.size()):
		actors[index].set_physics_process(false)
		actors[index].reparent(layer)
		actors[index].position = Vector2(540,380 + index*550)
		actors[index].visual.play_attack()
		actors[index].visual.stop()
		actors[index].visual.frame = 1
	chilled.apply_chill(8)
	var chill_fx = chilled.get_node("StatusFX_yuki_chill")
	chill_fx.stop()
	chill_fx.frame = 2
	chill_fx.visible = true
	chill_fx.set_process(false)
	for index in range(fans.size()):
		fans[index].reparent(layer)
		fans[index].position = Vector2(380+index*160,1100)
		fans[index].rotation = -PI/2 + (index-1)*DATA.FAN_ANGLE
	var label := Label.new()
	label.position = Vector2(80,80)
	label.text = "Yuki-onna / Chill 8 stacks / Elite"
	label.add_theme_font_size_override("font_size",36)
	layer.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	root.get_texture().get_image().save_png(args[args.find("--capture")+1])
	layer.free()
