extends SceneTree

const ROOM := preload("res://src/online/battle_room.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HERO_SHOT := preload("res://src/hero/HeroProjectile.tscn")
const HOUND := preload("res://src/hero/SummonerHound.tscn")
const ORB := preload("res://src/battle/ExpOrb.tscn")
const MONSTER_SHOT := preload("res://src/monsters/SkeletonArcherProjectile.tscn")
const RATIO_TOLERANCE := 0.03
const ANIMATION_RATIO_TOLERANCE := 0.12
var failures := 0

func _initialize() -> void: run.call_deferred()

func expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("BATTLE_CLOCK_FAIL " + label)

func measure(battle: Node, hero: CharacterBody2D, monster: CharacterBody2D, scale: float, paused: bool, direct := false) -> Vector2:
	battle.set_clock_scale(scale)
	battle.external_pause = paused
	hero.global_position = Vector2(1000, 1000)
	monster.global_position = Vector2(2000, 2000)
	for i in 24:
		await physics_frame
		hero.velocity = Vector2(120, 0)
		monster.velocity = Vector2(120, 0)
		if direct:
			hero.move_and_slide()
			monster.move_and_slide()
		else:
			hero._move_and_slide_with_obstacle_escape()
			COMMON.move_and_slide_profiled(monster)
	return Vector2(hero.global_position.x - 1000, monster.global_position.x - 2000)

func check_projectiles(battle: Node) -> void:
	var hero_shot = HERO_SHOT.instantiate()
	var monster_shot = MONSTER_SHOT.instantiate()
	battle.add_child(hero_shot)
	battle.add_child(monster_shot)
	hero_shot.set_physics_process(false)
	monster_shot.set_physics_process(false)
	for scale in [1.0, 0.25, 1.0]:
		battle.set_clock_scale(scale)
		hero_shot.setup(Vector2.RIGHT, 1, 100.0, 10000.0)
		monster_shot.setup(Vector2.RIGHT, 1, 100.0, 10000.0, false, false)
		hero_shot.set_physics_process(false)
		monster_shot.set_physics_process(false)
		hero_shot._physics_process(1.0)
		monster_shot._physics_process(1.0)
		expect(absf(hero_shot.traveled_distance - 100.0 * scale) < 0.01, "hero projectile " + str(scale))
		expect(absf(monster_shot.traveled_distance - 100.0 * scale) < 0.01, "monster projectile " + str(scale))
	hero_shot.queue_free()
	monster_shot.queue_free()

func check_timers_and_orb(battle: Node, hero: Node2D, monster: Node) -> void:
	var zeus = load("res://src/monsters/Zeus.tscn").instantiate()
	zeus.configure_transcendence(0, 0)
	battle.add_child(zeus)
	zeus.global_position = Vector2(1200, 1200)
	var orb = ORB.instantiate()
	battle.add_child(orb)
	orb.set_physics_process(false)
	zeus.set_physics_process(false)
	hero.global_position = Vector2(1000, 1000)
	for scale in [1.0, 0.25, 1.0]:
		battle.set_clock_scale(scale)
		monster.attack_timer = 10.0
		monster._physics_process(0.1)
		expect(absf(10.0 - monster.attack_timer - 0.1 * scale) < 0.001, "attack cooldown " + str(scale))
		zeus.charge_remaining = 10.0
		zeus._physics_process(0.1)
		expect(absf(10.0 - zeus.charge_remaining - 0.1 * scale) < 0.001, "zeus charge " + str(scale))
		orb.global_position = hero.global_position + Vector2(100, 0)
		orb.hero = hero
		orb._placement_pending = false
		orb.pickup_delay_left = 0.0
		orb.burst_time = 0.0
		orb.magnetized = true
		orb._physics_process(0.01)
		var distance: float = 100.0 - orb.global_position.distance_to(hero.global_position)
		if not orb.has_meta("normal_distance"):
			orb.set_meta("normal_distance", distance)
		else:
			expect(absf(distance / float(orb.get_meta("normal_distance")) - scale) < RATIO_TOLERANCE, "orb attraction")
	orb.queue_free()
	zeus.queue_free()

func measure_hound(battle: Node, hero: Node2D, target: Node2D, scale: float) -> float:
	battle.set_clock_scale(scale)
	var hound = HOUND.instantiate()
	battle.add_child(hound)
	hound.activate(Vector2(1000, 1000), hero, {"move_speed": 120.0})
	hound.set_physics_process(false)
	hound.collision_layer = 0
	hound.collision_mask = 0
	hound.visual.play(&"idle")
	target.global_position = Vector2(1700, 1000)
	hound.target = target
	hound.retarget_timer = 100.0
	for i in 24:
		await physics_frame
		hound._physics_process(1.0 / 60.0)
	var distance: float = hound.global_position.x - 1000.0
	hound.queue_free()
	return distance

func measure_attack_animation(battle: Node, visual: AnimatedSprite2D, scale: float) -> float:
	battle.set_clock_scale(scale)
	visual.set_base_animation_speed(1.0)
	visual.play(&"attack")
	visual.set_frame_and_progress(0, 0.0)
	await create_timer(0.12).timeout
	return float(visual.frame) + visual.frame_progress

func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var room := ROOM.new()
	root.add_child(room)
	room.prepare()
	room.start()
	var battle = room.battle
	battle.set_process(false)
	var hero = battle.hero
	var monster = battle._spawn_monster("orc", hero.global_position + Vector2(300, 0))
	hero.set_physics_process(false)
	monster.set_physics_process(false)
	hero.collision_layer = 0; hero.collision_mask = 0
	monster.collision_layer = 0; monster.collision_mask = 0
	hero.player_controlled = false
	var legacy: Vector2 = await measure(battle, hero, monster, 1.0, false, true)
	var normal: Vector2 = await measure(battle, hero, monster, 1.0, false)
	var slow: Vector2 = await measure(battle, hero, monster, 0.25, false)
	var stopped: Vector2 = await measure(battle, hero, monster, 0.25, true)
	expect(battle.combat_delta(2.0) == 0.0, "pause delta")
	battle.external_pause = false
	check_projectiles(battle)
	check_timers_and_orb(battle, hero, monster)
	var hound_normal := await measure_hound(battle, hero, monster, 1.0)
	var hound_slow := await measure_hound(battle, hero, monster, 0.25)
	var hound_restored := await measure_hound(battle, hero, monster, 1.0)
	expect(hound_normal > 0.0 and absf(hound_restored / hound_normal - 1.0) < RATIO_TOLERANCE, "hound movement restored")
	expect(hound_normal > 0.0 and absf(hound_slow / hound_normal - 0.25) < RATIO_TOLERANCE, "hound movement")
	var attack_normal := await measure_attack_animation(battle, monster.visual, 1.0)
	var attack_slow := await measure_attack_animation(battle, monster.visual, 0.25)
	expect(attack_normal > 0.0 and absf(attack_slow / attack_normal - 0.25) < ANIMATION_RATIO_TOLERANCE, "attack animation frame")
	monster.visual.set_base_animation_speed(0.8)
	hero._set_hero_animation_speed(1.2)
	battle.set_clock_scale(0.25)
	expect(is_equal_approx(monster.visual.speed_scale, 0.2), "monster animation quarter speed")
	expect(is_equal_approx(hero.hero_sprite.speed_scale, 0.3), "hero animation quarter speed")
	battle.set_clock_scale(1.0)
	expect(is_equal_approx(monster.visual.speed_scale, 0.8), "monster animation restored")
	expect(is_equal_approx(hero.hero_sprite.speed_scale, 1.2), "hero animation restored")
	expect(normal.x > 0.0 and normal.y > 0.0, "normal movement")
	expect(normal.distance_to(legacy) < 0.01, "normal matches direct movement")
	expect(absf(slow.x / normal.x - 0.25) < RATIO_TOLERANCE and absf(slow.y / normal.y - 0.25) < RATIO_TOLERANCE, "quarter movement")
	expect(stopped.length() < 0.001, "pause movement")
	battle.external_pause = false
	battle.set_clock_scale(2.0)
	expect(battle.combat_delta(2.0) == 2.0, "normal delta and upper clamp")
	battle.set_clock_scale(0.0)
	expect(is_equal_approx(battle.clock_scale, 0.05), "lower clamp")
	print("BATTLE_CLOCK ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
