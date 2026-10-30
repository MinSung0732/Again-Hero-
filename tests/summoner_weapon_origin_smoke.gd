extends SceneTree
## Summoner non-summon weapons fire from the owned summon nearest an enemy, use every summon
## slot (not only the first three) and alternate when two summons have targets (10-31).
const KIT := preload("res://src/hero_mode/hero_weapon_kit_runtime.gd")
var failures := 0

class Hero extends Node2D:
	var enemies: Array = []
	func _fill_monster_nodes_near(point: Vector2, reach: float, out: Array) -> void:
		out.clear()
		for enemy in enemies:
			if point.distance_to(enemy.global_position) <= reach: out.append(enemy)

class Authority extends Node2D:
	var active_hero_summons := {}

class Runtime extends RefCounted:
	var hero: Hero
	var authority: Authority
	var scratch: Array = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("SUMMONER_ORIGIN: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var authority := Authority.new(); root.add_child(authority)
	var hero := Hero.new(); authority.add_child(hero)
	var runtime := Runtime.new(); runtime.hero = hero; runtime.authority = authority
	var kit := KIT.new(); kit.install(runtime)
	var data := {"owner": "summoner_hero", "pattern": "slash", "range": 215.0}
	# Four summons; only the fourth (beyond the old three-slot cap) stands next to an enemy.
	var actors: Array = []
	for index in 4:
		var actor := Node2D.new()
		authority.add_child(actor)
		actor.global_position = Vector2(index * 1000.0, 0.0)
		actors.append(actor)
		authority.active_hero_summons[index] = actor
	var owner_script := GDScript.new()
	owner_script.source_code = "extends Node2D\nvar owner_hero\n"
	owner_script.reload()
	for actor in actors:
		var point: Vector2 = actor.global_position
		actor.set_script(owner_script)
		actor.global_position = point
		actor.owner_hero = hero
	var enemy := Node2D.new(); authority.add_child(enemy); enemy.global_position = Vector2(3050, 0)
	hero.enemies = [enemy]
	check(kit.origin(data, hero.global_position) == actors[3].global_position, "fourth summon used when it is the one near an enemy")
	# Two summons near enemies: casts alternate instead of repeating the same summon.
	var second := Node2D.new(); authority.add_child(second); second.global_position = Vector2(1040, 0)
	hero.enemies = [enemy, second]
	var first_pick: Vector2 = kit.origin(data, hero.global_position)
	var second_pick: Vector2 = kit.origin(data, hero.global_position)
	check(first_pick != second_pick and first_pick in [actors[1].global_position, actors[3].global_position] and second_pick in [actors[1].global_position, actors[3].global_position], "alternates between summons with targets")
	# No summon has an enemy in range: the weapon fires from the hero.
	hero.enemies = []
	check(kit.origin(data, Vector2(7, 7)) == Vector2(7, 7), "falls back to hero without targets")
	# Other heroes and summon weapons keep their own origin.
	check(kit.origin({"owner": "summoner_hero", "pattern": "summon", "range": 215.0}, Vector2(1, 1)) == Vector2(1, 1), "summon weapons keep hero origin")
	authority.queue_free()
	await process_frame
	print("SUMMONER_ORIGIN_FAILED" if failures else "SUMMONER_ORIGIN_OK")
	quit(1 if failures else 0)
