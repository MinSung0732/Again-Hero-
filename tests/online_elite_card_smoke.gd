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
	for i in 99: room._on_hero_kill()
	check(not battle.mutation_director.is_active(),"99 kills no choice")
	room._on_hero_kill()
	check(battle.mutation_director.is_active(),"100 kills opens choice")
	var candidates: Array = battle.mutation_director.get_candidates()
	check(not candidates.is_empty() and not battle.external_pause,"choice remains active without pausing")
	check(not room.apply("demon","elite_choose",{"id":"invalid"}),"invalid candidate rejected")
	for i in 150: room._on_hero_kill()
	check(room.elite_pending.size() == 1,"active choice queues next threshold")
	check(room.apply("demon","elite_choose",{"id":candidates[0]}),"choose candidate")
	check(battle.mutation_director.is_active() and room.elite_pending.is_empty(),"pending opens after choice")
	check(room.apply("demon","elite_choose",{"id":battle.mutation_director.get_candidates()[0]}),"second choice")
	for i in 150: room._on_hero_kill()
	check(battle.mutation_director.is_active(),"next 150 opens choice")
	check(room.apply("demon","elite_choose",{"id":battle.mutation_director.get_candidates()[0]}),"third choice")
	var before: int = battle.active_monsters.size()
	for i in 150: room._on_hero_kill()
	check(room.elite_pending.size() == 1 and room.elite_cards.size() == 3 and battle.active_monsters.size() == before,"full cards queue without spawn")
	var demon: Dictionary = room.snapshot("demon")
	var hero: Dictionary = room.snapshot("hero")
	check(demon.elite_pending == 1 and demon.elite_cards.size() == 3,"demon receives pending")
	check(not hero.has("elite_cards") and not hero.has("elite_choice") and not hero.has("elite_pending"),"hero snapshot hides elite data")
	var serial: int = room.elite_cards[0].serial
	var point: Vector2 = battle.hero.position + Vector2(400,0)
	check(room.apply("demon","elite_summon",{"serial":serial,"x":point.x,"y":point.y}),"manual spawn succeeds")
	check(room.elite_pending.is_empty() and battle.mutation_director.is_active(),"summon opens pending")
	room._queue_elite(preload("res://src/data/mutation_catalog.gd").SPECIAL_AUGMENT_EXHAUSTED_EVENT)
	check(room.elite_pending.size() == 1,"special reward queues during choice")
	room.finish("hero","test")
	check(room.elite_cards.is_empty() and room.elite_pending.is_empty(),"cards and pending expire on finish")
	var other = ROOM.new(); root.add_child(other); other.prepare(); other.start()
	other.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var custom_map: Dictionary = preload("res://src/data/ranked_map_catalog.gd").get_map("plaza")
	custom_map.elite.first_kills = 2; custom_map.elite.every_kills = 3
	other.configure_elite_thresholds(custom_map.elite)
	other._on_hero_kill(); check(not other.battle.mutation_director.is_active(),"custom threshold waits")
	other._on_hero_kill(); check(other.battle.mutation_director.is_active(),"custom first threshold")
	for i in 3: other._on_hero_kill()
	check(other.elite_pending.size() == 1,"custom interval")
	other.finish("hero","test"); other.queue_free()
	room.queue_free()
	print("ONLINE_ELITE_CARD_PASS checks=",checks); quit()
