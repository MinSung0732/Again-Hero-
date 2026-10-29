extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const GUIDE := preload("res://src/data/ranked_rules_guide.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const WEAPON_DATA := preload("res://src/data/hero_weapon_catalog.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(RULES.VERSION==31,"server and client protocol 31")
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
	check(hero_state.demon_hints == {"augment_hints":[]},"hero receives only empty confirmed demon hints initially")
	check(demon_state.has("hero_build") and demon_state.hero_build.weapons == hero_state.hero_inventory.weapons and demon_state.hero_build.passives == hero_state.hero_inventory.passives and demon_state.hero_build.level == hero_state.hero_inventory.level,"demon sees public weapon, passive, and hero level")
	check(demon_state.hero_build.augments is Array and demon_state.hero_build.augments.is_empty(),"unselected augments are not public")
	check(demon_state.hero_build.keys().size() == 4,"public build contains only approved fields")
	check(not demon_state.has("chest_receipts") and not demon_state.has("hero_inventory") and not demon_state.has("hero_holds") and not demon_state.has("hero_hold_count"),"private chest and held choice state never reach demon")
	check(not demon_state.hero_build.has("augment_holds") and not demon_state.hero_build.has("hold_count") and not demon_state.hero_build.has("rerolls_left") and not demon_state.hero_build.has("reroll_limit") and not demon_state.hero_build.has("chest_receipts"),"public build excludes held choices, count, rerolls and chest details")
	check(JSON.stringify(demon_state).to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT,"public build fits snapshot limit")
	var chosen: Dictionary = room.hero_holds[0].candidates[0]
	check(room.apply("hero","choose",{"number":number,"id":String(chosen.id)}),"held augment can be selected")
	check(String(chosen.name) in room.snapshot("demon").hero_build.augments,"selected augment name reaches demon")
	# Two held copies of the same owned weapon: taking one re-levels the other instead of showing a stale rank.
	room.hero_holds.clear()
	var weapon_id := String(runtime.weapon_ids[0])
	runtime.levels[weapon_id] = 1
	room._choice([runtime.offer_card(weapon_id),runtime.RESTORE_CARD.duplicate()]); room._choice([runtime.offer_card(weapon_id),runtime.RESTORE_CARD.duplicate()])
	var first_number: int = room.hero_holds[0].number
	var second_number: int = room.hero_holds[1].number
	check(String(room.hero_holds[1].candidates[0].name).contains("Lv.2"),"both held copies start at the same next level")
	check(room.apply("hero","choose",{"number":first_number,"id":weapon_id}) and int(runtime.levels[weapon_id]) == 2,"first held copy upgrades the weapon")
	check(int(room.hero_holds[0].number) == second_number and String(room.hero_holds[0].candidates[0].name).contains("Lv.3") and room.hero_holds[0].candidates[0].name == runtime.offer_card(weapon_id).name,"second held copy shows the next level after the first pick")
	check(room.hero_holds[0].wire_candidates == room.snapshot("hero").augment_holds[0].candidates,"refreshed held card reaches the hero wire")
	runtime.levels[weapon_id] = WEAPON_DATA.MAX_LEVEL; room._refresh_hero_holds()
	check(bool(room.hero_holds[0].candidates[0].get("unavailable",false)) and room.snapshot("hero").augment_holds[0].candidates[0].get("unavailable",false),"maxed held card is marked unavailable")
	check(not room.apply("hero","choose",{"number":second_number,"id":weapon_id}) and int(runtime.levels[weapon_id]) == WEAPON_DATA.MAX_LEVEL,"unavailable held card cannot be chosen")
	room.hero_holds.clear(); room._choice([runtime.offer_card(weapon_id) if not runtime.offer_card(weapon_id).is_empty() else {"id":weapon_id,"name":"stale"}])
	room._refresh_hero_holds()
	check(room.hero_holds.size() == 1 and not room.hero_holds[0].candidates.is_empty() and room.hero_holds[0].candidates.all(func(card): return not bool(card.get("unavailable",false)) and String(card.id) != weapon_id),"offer with nothing left is replaced without a reroll")
	room.hero_holds.clear()
	check(JSON.stringify(GUIDE.sections()).contains("상자 골드 없음") and JSON.stringify(GUIDE.sections()).contains("새로고침 3회"),"ranked guide explains chest and rerolls")
	check(JSON.stringify(GUIDE.sections()).contains("보관 중인 선택지는 비공개"),"ranked guide explains public build boundary")
	check(JSON.stringify(GUIDE.sections()).contains("마왕이 고른 증강의 역할 방향만"),"ranked guide explains demon hint boundary")
	var monster_option: Dictionary = DEMON_AUGMENTS.get_augment("slime_damage")
	var role_label := MONSTERS.get_role_label(String(MONSTERS.get_monster("slime").get("role","")))
	room._hold("demon",[monster_option],2)
	var demon_number: int = room.demon_holds[0].number
	check(room.apply("demon","demon_choose",{"number":demon_number,"id":String(monster_option.id)}),"demon held augment selected")
	check(("%s 강화" % role_label) in room.snapshot("hero").demon_hints.augment_hints,"held selection produces catalog role hint")
	check(room._demon_augment_hint(DEMON_AUGMENTS.get_augment("lizard_spear_throw")) == "원거리 강화","role override determines hint")
	var command_option: Dictionary = DEMON_AUGMENTS.get_augment("command_regen")
	for level in [3,4,5,6,7]: room._hold("demon",[command_option],level)
	room._enforce_hold_limit("demon")
	var hidden_state: Dictionary = room.snapshot("hero")
	check("마왕 운영" in hidden_state.demon_hints.augment_hints,"fifth demon offer auto selection produces direction hint")
	check(room.demon_holds.size() == 4 and hidden_state.augment_holds.is_empty(),"demon held count remains private")
	room._hold("demon",[command_option],8)
	room._enforce_hold_limit("demon")
	hidden_state = room.snapshot("hero")
	check("마왕 운영 x2" in hidden_state.demon_hints.augment_hints,"matching hints merge into a bounded count")
	var hidden_json := JSON.stringify(hidden_state)
	check(not hidden_state.has("team") and not hidden_state.has("skills") and not hidden_state.has("transcendent") and not hidden_state.has("demon_charge") and not hidden_state.has("transcend_ready"),"hero snapshot omits demon loadout and ability state")
	check(not hidden_json.contains(String(monster_option.id)) and not hidden_json.contains(String(monster_option.name)) and not hidden_json.contains(String(monster_option.description)) and not hidden_json.contains(String(command_option.id)) and not hidden_json.contains(String(command_option.name)) and not hidden_json.contains(String(command_option.description)),"hero JSON omits selected augment identities")
	check(not hidden_json.contains("command_capacity") and not hidden_json.contains("demon_holds") and not hidden_state.demon_hints.has("rerolls_left") and not hidden_state.demon_hints.has("hold_count"),"hero JSON omits demon held options and rerolls")
	check(hidden_json.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT,"demon hints fit snapshot limit")
	check(not room.battle.external_pause and room.running,"reroll and HUD do not pause combat")
	room.queue_free()
	await create_timer(0.2).timeout
	print("ONLINE_HERO_ABILITIES_PASS checks=",checks); quit()
