extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const FLOW := preload("res://src/systems/flow_pause_manager.gd")
const SCENE := preload("res://src/online/match_scene.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(RULES.VERSION==27 and SCENE != null,"matching protocol and client parse")
	var room = ROOM.new(); root.add_child(room)
	room.set_loadouts({"hero_id":RULES.HERO},{"team_ids":["slime","spider","orc"],"skill_ids":["encirclement"],"transcendence_id":"zeus"})
	room.prepare(); room.start()
	var battle = room.battle
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	check(battle.demon_ultimate_skill_ids == ["encirclement"] and battle.transcendence.monster_id == "zeus","verified loadout enters battle")
	check(not room.apply("demon","skill",{"id":"square_siege"}),"unloaded skill denied")
	check(not room.apply("demon","skill",{"id":"encirclement","direction":42}),"invalid skill format denied")
	battle.demon_ultimate_charge = 100.0
	check(room.apply("demon","skill",{"id":"encirclement"}),"loaded skill accepted")
	check(float(battle.demon_ultimate_cooldowns.encirclement) > 0.0 and battle.demon_ultimate_charge < 100.0,"battle charges gauge and starts cooldown")
	var skill_state: Dictionary = room.snapshot()
	check(skill_state.demon_cooldowns.encirclement > 0.0 and not skill_state.demon_ready.encirclement and skill_state.demon_charge < skill_state.demon_charge_max,"cooldown and availability reach snapshot")
	check(is_equal_approx(float(skill_state.summon_costs.slime),battle.get_monster_cost("slime")) and skill_state.demon_level == battle.demon_level,"live summon cost and demon progress reach snapshot")
	check(not room.snapshot("hero").has("summon_costs") and not room.snapshot("hero").has("demon_exp"),"private lower HUD state stays with demon")
	check(not room.apply("demon","skill",{"id":"encirclement"}),"cooldown denies repeat")
	battle.demon_pending_augments = 1; battle.demon_pending_augment_levels.append(2)
	battle._open_next_demon_augment_if_needed()
	check(not battle.demon_augment_selection_active and room.demon_holds.size() == 1,"online demon offer enters hold")
	var choice_state: Dictionary = room.snapshot("demon")
	check(choice_state.augment_holds.size() == 1 and room.snapshot("hero").augment_holds.is_empty(),"demon hold reaches only own snapshot")
	check(not battle.flow_pause_manager.is_paused(FLOW.DOMAIN_COMBAT) and not battle._hero_subtree_paused,"offer leaves battle running")
	var number: int = room.demon_holds[0].number
	var id := String(room.demon_holds[0].candidates[0].id)
	check(not room.apply("demon","demon_choose",{"id":id,"number":number-1}),"stale number denied")
	check(room.apply("demon","demon_choose",{"id":id,"number":number}),"held candidate accepted")
	check(room.demon_holds.is_empty(),"choice clears held offer")
	battle.demon_pending_augments = 1; battle.demon_pending_augment_levels.append(3)
	battle._open_next_demon_augment_if_needed()
	check(room.demon_holds.size() == 1,"second offer held")
	room.step(9.0)
	check(room.demon_holds.size() == 1 and battle.demon_pending_augments == 0,"time does not select held offer")
	check(not room.apply("demon","transcend",{}),"transcendent requires point")
	check(not battle.try_summon_transcendent(),"automatic transcendent path denied")
	var point: Vector2 = battle.hero.position + Vector2(300,0)
	battle.command_power = maxf(1000.0,battle.get_monster_cost("zeus"))
	check(not room.apply("demon","transcend",{"point":[point.x,point.y]}),"locked transcendence denied")
	battle.transcendence.ready = true
	check(not room.apply("demon","transcend",{"point":[battle.hero.position.x,battle.hero.position.y]}),"manual placement restriction preserved")
	var before: int = battle.active_monsters.size()
	check(room.apply("demon","transcend",{"point":[point.x,point.y]}),"registered transcendence manually summoned")
	check(battle.active_monsters.size() == before+1 and battle.transcendence.used,"one spawn consumes eligibility")
	check(not room.apply("demon","transcend",{"point":[point.x,point.y]}),"second transcendence denied")
	var summoned_feedback := false
	for row in room.feedback.snapshot():
		if row[2] == "transcend": summoned_feedback = true
	check(summoned_feedback,"transcendence feedback published")
	room.finish("","test_complete"); room.queue_free()
	var empty = ROOM.new(); root.add_child(empty)
	empty.set_loadouts({"hero_id":RULES.HERO},{"team_ids":["slime","spider","orc"],"skill_ids":[],"transcendence_id":""})
	empty.prepare(); empty.start(); empty.battle.process_mode = Node.PROCESS_MODE_DISABLED
	check(not empty.apply("demon","transcend",{"point":[point.x,point.y]}),"no transcendence in loadout denied")
	check(not empty.battle.try_summon_transcendent(),"automatic path remains denied without loadout")
	empty.finish("","test_complete"); empty.queue_free()
	await create_timer(0.2).timeout
	print("ONLINE_DEMON_ABILITIES_PASS checks=",checks); quit()
