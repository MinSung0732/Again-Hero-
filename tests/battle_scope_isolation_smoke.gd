extends SceneTree
## Two actual authoritative rooms share one SceneTree like the match server.
## Battle-owned pickups, projectiles, monsters and hero item queries must
## resolve only their own room. No socket traffic.
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const BATTLE_SCOPE := preload("res://src/systems/battle_scope.gd")
const PICKUP_SCENES := {
	&"exp_orbs": "res://src/battle/ExpOrb.tscn",
	&"heal_items": "res://src/battle/HealItem.tscn",
	&"magnet_items": "res://src/battle/MagnetItem.tscn",
}
const PROJECTILE_SCENES := {
	"scope_basic": "res://src/hero/HeroProjectile.tscn",
	"scope_gunner": "res://src/hero/GunnerProjectile.tscn",
}
var checks := 0
var failures := 0


func _initialize() -> void: run.call_deferred()


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("BATTLE_SCOPE_FAIL " + label)


func stop_audio(host: Node) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null


func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var rooms: Array = []
	for index in 2:
		var room := ROOM.new(); root.add_child(room); room.prepare()
		expect(room.is_prepared, "room %d prepared" % index)
		rooms.append(room)
	var battles: Array = rooms.map(func(room): return room.battle)
	var heroes: Array = battles.map(func(battle): return battle.hero)
	expect(heroes[0] != heroes[1], "distinct room heroes")
	# The first tree hero belongs to room 0; room 1 must never resolve to it.
	expect(get_first_node_in_group("hero") == heroes[0], "tree-wide first hero is room 0")

	var pickups := {}
	for index in 2:
		var battle = battles[index]
		expect(battle.get_scoped_hero() == heroes[index], "room %d scoped hero" % index)
		for group_name in PICKUP_SCENES:
			var item: Node2D = load(PICKUP_SCENES[group_name]).instantiate()
			battle.add_child(item)
			# Same local point in both rooms: only world ownership differs.
			item.global_position = heroes[0].global_position
			pickups[[index, group_name]] = item
			expect(item.get("hero") == heroes[index], "room %d %s resolves own hero" % [index, group_name])
		var orb: Node2D = pickups[[index, &"exp_orbs"]]
		orb.call("setup", 1)
		expect(orb.get("hero") == heroes[index], "room %d pooled orb setup keeps own hero" % index)
		for pool_key in PROJECTILE_SCENES:
			var projectile = battle.acquire_projectile(load(PROJECTILE_SCENES[pool_key]), pool_key)
			projectile.call("setup", Vector2.RIGHT, 1, 1.0, 1.0)
			expect(projectile.get("source_hero") == heroes[index], "room %d %s source hero" % [index, pool_key])
			expect(projectile.call("_get_chest_nodes_cached") is Array, "room %d %s chest cache" % [index, pool_key])
		var monster = battle._spawn_monster(String(RULES.ROSTER[0]), heroes[index].global_position + Vector2(260, 0))
		expect(is_instance_valid(monster), "room %d monster spawned" % index)
		if is_instance_valid(monster):
			expect(monster.get("hero") == heroes[index], "room %d monster resolves own hero" % index)
			expect(BATTLE_SCOPE.resolve_hero(monster) == heroes[index], "room %d monster scope" % index)

	for index in 2:
		var hero = heroes[index]
		for group_name in PICKUP_SCENES:
			var nodes: Array = hero._get_aux_group_nodes_cached(group_name)
			expect(nodes.has(pickups[[index, group_name]]), "room %d hero sees own %s" % [index, group_name])
			expect(not nodes.has(pickups[[1 - index, group_name]]), "room %d hero ignores other %s" % [index, group_name])
			var again: Array = hero._get_aux_group_nodes_cached(group_name)
			expect(again == nodes and is_same(again, nodes), "room %d %s cache reused in frame" % [index, group_name])

	# Solo battles keep the previous tree-wide group result unchanged.
	battles[0].online_match_mode = false
	var solo: Array = []
	battles[0].fill_scoped_group(&"exp_orbs", solo)
	expect(solo.size() == get_nodes_in_group(&"exp_orbs").size(), "solo scoped group equals tree group")
	battles[0].online_match_mode = true

	# Standalone nodes without a Battle authority still use the tree fallback.
	var loose: Node2D = load(PICKUP_SCENES[&"heal_items"]).instantiate()
	root.add_child(loose)
	expect(loose.get("hero") == heroes[0], "standalone fallback uses tree hero")
	loose.queue_free()

	for room in rooms: stop_audio(room)
	stop_audio(root.get_node("GameAudio"))
	for room in rooms: room.queue_free()
	await process_frame
	if failures == 0:
		print("BATTLE_SCOPE_ISOLATION_PASS checks=", checks)
		quit(0)
	else:
		print("BATTLE_SCOPE_ISOLATION_FAIL failures=", failures, " checks=", checks)
		quit(1)
