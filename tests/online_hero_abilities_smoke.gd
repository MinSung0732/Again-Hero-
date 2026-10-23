extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const GUIDE := preload("res://src/data/ranked_rules_guide.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(RULES.VERSION == 12,"server and client protocol 12")
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var runtime = room.battle.hero.player_weapons
	var gold_before: float = runtime.gold_bonus
	check(not room.apply("hero","chest",{"id":"survival_restore"}),"client cannot request or choose chest reward")
	room._chest_opened(); room._chest_opened()
	check(room.chest_receipts.size() == 2 and runtime.last_applied_chest == 2,"server rolls and applies each chest")
	check(int(room.chest_receipts[0].serial) == 1 and int(room.chest_receipts[1].serial) == 2,"multiple chests preserve order")
	check(runtime.gold_bonus == gold_before and not room.snapshot("hero").has("chest_gold"),"ranked chest awards no account gold")
	check(not room.battle.external_pause and room.running,"chest display never pauses combat")
	var candidate: Array = runtime.candidates()
	room._choice(candidate)
	var number: int = room.hero_holds[0].number
	check(not room.apply("hero","reroll",{"number":number+1}),"wrong held number rejected")
	var before: int = runtime.rerolls_remaining()
	var old_ids: Array = []
	for option in room.hero_holds[0].candidates: old_ids.append(String(option.id))
	check(room.apply("hero","reroll",{"number":number}),"server rerolls held candidates")
	check(runtime.rerolls_remaining() == before-1 and int(room.hero_holds[0].number) == number,"reroll consumes one and keeps offer number")
	var changed := false
	for option in room.hero_holds[0].candidates:
		if String(option.id) not in old_ids: changed = true
	check(changed and room.hero_holds[0].wire_candidates == room.snapshot("hero").augment_holds[0].candidates,"new candidates fixed in server hold and wire")
	runtime.rerolls_used = runtime.reroll_limit
	check(not room.apply("hero","reroll",{"number":number}),"zero rerolls rejects request")
	var hero_state: Dictionary = room.snapshot("hero")
	var demon_state: Dictionary = room.snapshot("demon")
	check(hero_state.hero_inventory.weapons.size() > 0 and hero_state.hero_inventory.rerolls_left == 0,"own snapshot has weapon levels and rerolls")
	check(hero_state.hero_inventory.has("passives") and hero_state.hero_inventory.has("exp") and hero_state.hero_inventory.has("level"),"own snapshot has passives and level EXP")
	check(hero_state.chest_receipts.size() == 2 and not demon_state.has("chest_receipts") and not demon_state.has("hero_inventory"),"private rewards and build never reach demon")
	check(JSON.stringify(GUIDE.sections()).contains("상자 골드 없음") and JSON.stringify(GUIDE.sections()).contains("새로고침 3회"),"ranked guide explains chest and rerolls")
	check(not room.battle.external_pause and room.running,"reroll and HUD do not pause combat")
	room.queue_free()
	await create_timer(0.2).timeout
	print("ONLINE_HERO_ABILITIES_PASS checks=",checks); quit()
