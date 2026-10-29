extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var battle = room.battle
	battle._open_mutation_choice({"type":"elite","hp_multiplier":2.8})
	var candidates: Array = battle.mutation_director.get_candidates()
	check(not candidates.is_empty() and not battle.external_pause,"choice remains active without pausing")
	room.step(100.0)
	check(battle.mutation_director.is_active(),"no automatic choice")
	check(not room.apply("demon","elite_choose",{"id":"invalid"}),"invalid candidate rejected")
	var before: int = battle.active_monsters.size()
	check(room.apply("demon","elite_choose",{"id":candidates[0]}),"choose candidate")
	check(room.elite_cards.size() == 1 and battle.active_monsters.size() == before,"stored without spawn")
	var serial: int = room.elite_cards[0].serial
	var hero_pos: Vector2 = battle.hero.position
	battle.command_power = 0
	check(not room.apply("demon","elite_summon",{"serial":serial,"x":hero_pos.x,"y":hero_pos.y}),"too close rejected")
	var point: Vector2 = hero_pos + Vector2(400,0)
	check(room.apply("demon","elite_summon",{"serial":serial,"x":point.x,"y":point.y}),"manual spawn succeeds")
	check(battle.command_power == 0 and room.elite_cards.is_empty() and battle.active_monsters.size() == before + 1,"free spawn consumes card")
	for index in RULES.ELITE_CARD_LIMIT + 1:
		battle._open_mutation_choice({"type":"elite","hp_multiplier":2.8})
		check(room.apply("demon","elite_choose",{"id":battle.mutation_director.get_candidates()[0]}),"hold choice")
	check(room.elite_cards.size() == RULES.ELITE_CARD_LIMIT and int(room.elite_cards[0].serial) == serial + 2 and battle.active_monsters.size() == before + 2,"oldest overflow spawned")
	var demon: Dictionary = room.snapshot("demon")
	var hero: Dictionary = room.snapshot("hero")
	check(demon.elite_cards.size() == 3 and demon.elite_choice.candidates.is_empty(),"demon snapshot restores cards")
	check(not hero.has("elite_cards") and not hero.has("elite_choice"),"hero snapshot hides cards")
	room.finish("hero","test")
	check(room.elite_cards.is_empty(),"cards expire on finish")
	room.queue_free()
	print("ONLINE_ELITE_CARD_PASS checks=",checks); quit()
