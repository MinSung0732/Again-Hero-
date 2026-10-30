extends SceneTree

const ROOM := preload("res://src/online/battle_room.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
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
	expect(normal.x > 0.0 and normal.y > 0.0, "normal movement")
	expect(normal.distance_to(legacy) < 0.01, "normal matches direct movement")
	expect(absf(slow.x / normal.x - 0.25) < 0.03 and absf(slow.y / normal.y - 0.25) < 0.03, "quarter movement")
	expect(stopped.length() < 0.001, "pause movement")
	expect(battle.combat_delta(2.0) == 0.0, "pause delta")
	battle.external_pause = false
	battle.set_clock_scale(2.0)
	expect(battle.combat_delta(2.0) == 2.0, "normal delta and upper clamp")
	battle.set_clock_scale(0.0)
	expect(is_equal_approx(battle.clock_scale, 0.05), "lower clamp")
	print("BATTLE_CLOCK ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
