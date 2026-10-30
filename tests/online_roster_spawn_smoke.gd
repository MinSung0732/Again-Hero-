extends SceneTree
const RULES := preload("res://src/online/match_rules.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const ROOM := preload("res://src/online/battle_room.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var fallback: Dictionary = room.ranked_usage().role_counts
	var expected := {}
	for id in room.roster:
		var role := MONSTERS.get_role(String(id))
		expected[role] = int(expected.get(role, 0)) + 1
	check(fallback == expected, "no summons uses roster roles")
	var battle = room.battle
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	# Keep this immediate factory test independent of auto-selected demon augments.
	battle.demon_exp_gain_multiplier = 0.0
	var point: Vector2 = battle.hero.position + Vector2(300,0)
	check(battle.run_metrics.elapsed_seconds == 0.0,"opening instant")
	check(not battle.hero_control_spawns.allows("spider",false,1,0.0,0),"solo controller grace would reject the opening spider")
	for id in RULES.ROSTER:
		battle.command_power = RULES.OPENING_MANA
		var before: int = battle.active_monsters.size()
		var cost: float = battle.get_monster_cost(id)
		check(room.apply("demon","summon",{"id":id,"point":[point.x,point.y]}),"online roster summon: "+id)
		check(battle.active_monsters.size() == before+1,"one real actor: "+id)
		check(is_equal_approx(battle.command_power,RULES.OPENING_MANA-cost),"catalog cost charged once: "+id)
		check(room.last_action_message.contains("수동 배치"),"success feedback: "+id)
	check(room.ranked_usage().role_counts == expected, "accepted summons counted by catalog role")
	# Online control-heavy armies are governed by mana/population, not solo AI pacing.
	for index in 3:
		battle.command_power = RULES.OPENING_MANA
		check(room.apply("demon","summon",{"id":"spider","point":[point.x,point.y]}),"repeated spider accepted without solo interval/species cap")
	check(battle.hero_control_spawns.members.is_empty() and battle.hero_control_spawns.next_spawn == 0.0,"online spawns never consume solo budget")
	var count: int = battle.active_monsters.size()
	battle.command_power = 0.0
	check(not room.apply("demon","summon",{"id":"spider","point":[point.x,point.y]}) and room.last_action_message.contains("지휘력"),"insufficient mana still rejected with reason")
	check(battle.active_monsters.size() == count and battle.command_power == 0.0,"failed paid summon preserves state")
	var spider_role := MONSTERS.get_role("spider")
	check(int(room.ranked_usage().role_counts[spider_role]) == int(expected[spider_role]) + 3, "rejected summons do not count")
	battle.command_power = RULES.OPENING_MANA
	check(not room.apply("demon","summon",{"id":"spider","point":[battle.hero.position.x,battle.hero.position.y]}) and room.last_action_message.contains("가까움"),"hero proximity restriction preserved")
	check(not room.apply("demon","summon",{"id":"spider","point":[-1,-1]}) and room.last_action_message.contains("전장"),"bounds preserved")
	check(not room.apply("demon","summon",{"id":"zeus","point":[point.x,point.y]}),"outside online roster rejected")
	check(battle._spawn_monster("zeus",point) == null,"factory also enforces online roster")
	var original_max_command: float = battle.max_command
	battle.max_command = float(count)
	check(not room.apply("demon","summon",{"id":"spider","point":[point.x,point.y]}) and room.last_action_message.contains("인구"),"online population cap still enforced")
	check(battle.active_monsters.size() == count and battle.command_power == RULES.OPENING_MANA,"denied actions allocate nothing and charge nothing")
	# Elite rewards use the verified online roster, never solo supply pacing.
	battle.max_command = original_max_command
	var elite_count: int = battle.active_monsters.size()
	check(battle.spawn_special_monster("spider",{"type":"elite","name_prefix":"엘리트"}),"online opening controller elite reward bypasses solo pacing")
	check(battle.active_monsters.size() == elite_count+1 and String(battle.active_monsters.values().back().monster_type) == "spider","online elite preserves selected species")
	check(battle.hero_control_spawns.members.is_empty() and battle.hero_control_spawns.next_spawn == 0.0,"online elite never consumes solo supply state")
	# The very same factory still applies solo controller pacing.
	battle.online_match_mode = false
	check(battle._spawn_monster("spider",point) == null,"solo opening controller gate unchanged")
	battle.online_match_mode = true
	room.finish("","test_complete"); room.queue_free(); await create_timer(0.2).timeout
	print("ONLINE_ROSTER_SPAWN_PASS checks=",checks); quit()
