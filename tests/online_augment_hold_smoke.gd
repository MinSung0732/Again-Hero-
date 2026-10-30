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
	check(RULES.VERSION == 37 and RULES.AUGMENT_HOLD_LIMIT == 4,"protocol and hold limit")
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var hero = room.battle.hero
	var original_hp: int = hero.current_hp
	hero.current_hp = maxi(1,original_hp-100)
	var source := [{"id":"survival_restore","name":"회복","description":"고정 후보"}]
	room._choice(source)
	source[0].name = "변조된 후보"
	check(room.hero_holds[0].candidates[0].name == "회복","received candidates are fixed copies")
	check(not room.apply("hero","choose",{"number":999,"id":"survival_restore"}),"wrong offer number rejected")
	check(not room.apply("hero","choose",{"number":room.hero_holds[0].number,"id":"unknown"}),"candidate outside fixed offer rejected")
	var oldest: int = room.hero_holds[0].number
	for index in 3: room._choice([{"id":"survival_restore","name":"회복"}])
	check(room.hero_holds.size() == RULES.AUGMENT_HOLD_LIMIT and room.hero_holds[0].number == oldest,"four held in arrival order")
	room.step(30.0)
	check(room.hero_holds.size() == 4 and not room.battle.external_pause,"no timeout and no battle pause")
	room._choice([{"id":"survival_restore","name":"회복"}])
	check(room.hero_holds.size() == 4 and room.hero_holds[0].number != oldest and hero.current_hp > original_hp-100,"fifth auto selects oldest")
	var hero_state: Dictionary = room.snapshot("hero")
	var demon_state: Dictionary = room.snapshot("demon")
	check(hero_state.augment_holds.size() == 4 and demon_state.augment_holds.is_empty(),"opponent snapshot hides held count and candidates")
	check(not demon_state.has("choices") and not demon_state.has("choice_revision"),"shared snapshot has no hold metadata")
	var selected: int = room.hero_holds[0].number
	check(room.apply("hero","choose",{"number":float(selected),"id":"survival_restore"}),"valid JSON numeric item applies")
	check(not room.apply("hero","choose",{"number":selected,"id":"survival_restore"}),"replayed item denied")
	var battle = room.battle
	var first_demon_number: int = room.next_offer_number+1
	battle.demon_pending_augments = 5
	for level in [2,3,4,5,6]: battle.demon_pending_augment_levels.append(level)
	battle._open_next_demon_augment_if_needed()
	var applied_count: int = battle.demon_special_augments.size()
	for count in battle.demon_build_counts.values(): applied_count += int(count)
	check(room.demon_holds.size() == 4 and room.demon_holds[0].number == first_demon_number+1 and applied_count > 0 and not battle.demon_augment_selection_active,"demon fifth offer applies oldest")
	var demon_number: int = room.demon_holds[0].number
	var demon_id := String(room.demon_holds[0].candidates[0].id)
	var demon_rerolls_before: int = battle.demon_rerolls_left
	var demon_snapshot: Dictionary = room.snapshot("demon")
	check(int(demon_snapshot.demon_rerolls_left) == demon_rerolls_before and int(demon_snapshot.demon_reroll_limit) == battle.demon_reroll_max and not room.snapshot("hero").has("demon_rerolls_left"),"demon reroll budget is private to demon")
	check(room.apply("demon","reroll",{"number":demon_number}) and battle.demon_rerolls_left == demon_rerolls_before-1 and not battle.demon_augment_selection_active,"demon held reroll spends demon budget")
	check(room.demon_holds[0].number == demon_number and room.demon_holds[0].candidates.size() <= RULES.MAX_OFFER_CANDIDATES,"demon reroll keeps offer slot")
	demon_id = String(room.demon_holds[0].candidates[0].id)
	battle.demon_rerolls_left = 0
	check(not room.apply("demon","reroll",{"number":demon_number}),"demon reroll denied at zero")
	check(not room.apply("demon","demon_choose",{"number":demon_number+999,"id":demon_id}),"demon wrong number denied")
	check(not room.apply("demon","demon_choose",{"number":demon_number,"id":"invalid"}),"demon foreign candidate denied")
	check(room.apply("demon","demon_choose",{"number":float(demon_number),"id":demon_id}),"demon held JSON numeric choice applies")
	check(room.snapshot("hero").augment_holds.size() == 3 and room.snapshot("demon").augment_holds.size() == 3,"both private queues isolated")
	# A held copy becomes invalid after another pick reaches the stack cap.
	room.demon_holds.clear()
	var augment_data := preload("res://src/data/demon_augment_catalog.gd")
	var capped: Dictionary = augment_data.get_augment("command_regen")
	var fallback: Dictionary = augment_data.get_augment("command_capacity")
	battle.demon_build_counts[String(capped.id)] = int(capped.max_stack)
	room._hold("demon",[capped,fallback],2)
	room._refresh_demon_holds()
	check(bool(room.demon_holds[0].candidates[0].get("unavailable",false)),"capped held demon card becomes unavailable")
	check(not room.apply("demon","demon_choose",{"number":room.demon_holds[0].number,"id":String(capped.id)}),"capped held card rejected without consuming offer")
	room.demon_holds.clear()
	room._hold("demon",[capped],2)
	var retained_number: int = room.demon_holds[0].number
	var retained_rerolls: int = battle.demon_rerolls_left
	room._refresh_demon_holds()
	check(room.demon_holds[0].number == retained_number and room.demon_holds[0].candidates.all(func(card): return not bool(card.get("unavailable",false)) and String(card.id) != String(capped.id)),"fully exhausted held demon offer is replaced in place")
	check(battle.demon_rerolls_left == retained_rerolls and not battle.demon_augment_selection_active,"replacement consumes no reroll and preserves active state")
	room.demon_holds.clear()
	var special_options: Array = augment_data.get_special_augments_for_monster("slime")
	check(not special_options.is_empty(),"special regression uses catalog options")
	var owned_special: Dictionary = special_options[0]
	battle.demon_special_augments.append(String(owned_special.id))
	room._hold("demon",[owned_special,fallback],3)
	room._refresh_demon_holds()
	check(bool(room.demon_holds[0].candidates[0].get("unavailable",false)),"owned special held card becomes unavailable")
	var guide_text := JSON.stringify(GUIDE.sections())
	check(guide_text.contains("최대 %d개" % RULES.AUGMENT_HOLD_LIMIT),"guide uses hold constant")
	check(guide_text.contains("+10~30") and guide_text.contains("-10~25") and guide_text.contains("중도 이탈 -25"),"guide uses rating rules")
	room.finish("hero","test_complete")
	check(room.hero_holds.is_empty() and room.demon_holds.is_empty() and room.snapshot("hero").augment_holds.is_empty(),"held items expire on result")
	room.queue_free()
	await create_timer(0.2).timeout
	print("ONLINE_AUGMENT_HOLD_PASS checks=",checks); quit()
