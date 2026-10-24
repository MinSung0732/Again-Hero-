extends SceneTree

const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const DEMON := preload("res://src/data/demon_augment_catalog.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const VIEW := preload("res://src/ui/augment_compare_view.gd")
const POPUP := preload("res://src/ui/augment_hold_popup.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed = true; push_error(message)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var first: Array = WEAPONS.compare("ranged_rookie_arcane_bolt",1)
	check(not first.is_empty() and first[0].current == "없음","new weapon has no current value")
	var passive_id := ""
	for id in WEAPONS.PASSIVES:
		if not bool(WEAPONS.PASSIVES[id].get("one_shot",false)):
			passive_id = String(id); break
	var passive: Dictionary = WEAPONS.PASSIVES[passive_id]
	var passive_rows: Array = WEAPONS.compare(passive_id,3)
	check(not passive_rows.is_empty() and passive_rows[0].current != passive_rows[0].next,"passive cumulative values change")
	var normal: Dictionary = DEMON.get_augment("command_capacity")
	var zero: Array = DEMON.compare(normal,0)
	var one: Array = DEMON.compare(normal,1)
	check(zero[0].current == "100" and zero[0].next == "110" and one[0].current == "110" and one[0].next == "120","demon stacks advance")
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var runtime = room.battle.hero.player_weapons
	var weapon_id := String(runtime.weapon_ids[0])
	check(runtime.add(weapon_id),"weapon reaches level two")
	var before: Dictionary = runtime.stats_for(weapon_id)
	var before_damage: int = runtime._cast_damage(weapon_id,before)
	var card: Dictionary = runtime.offer_card(weapon_id)
	check(not card.is_empty() and card.compare[0].current == str(before_damage),"level three card current damage matches runtime")
	room._choice([card])
	var held_before: Array = room.hero_holds[0].wire_candidates[0].compare.duplicate(true)
	check(runtime.add(weapon_id),"weapon reaches level three")
	var after: Dictionary = runtime.stats_for(weapon_id)
	check(card.compare[0].next == str(runtime._cast_damage(weapon_id,after)),"level three card next damage matches runtime")
	check(card.compare[1].next == "%s초" % WEAPONS.CARD_TEXT.number(float(after.cooldown)*runtime.haste*float(after.cooldown_scale)),"weapon interval matches runtime")
	room._refresh_hero_holds()
	check(room.hero_holds[0].wire_candidates[0].compare != held_before,"held hero compare refreshes")
	check(runtime.add(passive_id) and runtime.add(passive_id),"passive reaches level two")
	var passive_card: Dictionary = runtime.offer_card(passive_id)
	check(passive_card.compare == passive_rows,"passive cumulative card matches catalog")
	var wire: Array = room._wire_candidates([{"id":"test","name":"test","description":"test","compare":zero}])
	check(wire[0].compare == zero,"wire preserves compare")
	var long_rows: Array = []
	for index in 9: long_rows.append({"label":"x".repeat(40),"current":"y".repeat(40),"next":"z".repeat(40)})
	wire = room._wire_candidates([{"id":"test","name":"test","description":"test","compare":long_rows}])
	check(wire[0].compare.size() == RULES.MAX_COMPARE_ROWS and wire[0].compare[0].label.length() == RULES.MAX_COMPARE_FIELD_LENGTH,"wire compare bounds")
	check(str(roundi(room.battle.max_command)) == zero[0].current,"demon stack zero matches runtime")
	room.battle._apply_demon_augment(normal)
	room.battle.demon_build_counts["command_capacity"] = 1
	check(str(roundi(room.battle.max_command)) == zero[0].next and str(roundi(room.battle.max_command)) == one[0].current,"demon stack one matches runtime")
	room._demon_offer([normal],0,2)
	room.battle._apply_demon_augment(normal)
	room.battle.demon_build_counts["command_capacity"] = 2
	room._refresh_demon_holds()
	check(str(roundi(room.battle.max_command)) == one[0].next and room.demon_holds[0].wire_candidates[0].compare[0].current == "120","held demon compare refreshes after stack")
	var host := Control.new(); root.add_child(host)
	var label := VIEW.add(host,zero)
	check(label.text.contains("100 →") and label.text.contains("[color="),"shared colored text")
	var own: Dictionary = room.snapshot("hero")
	var other: Dictionary = room.snapshot("demon")
	check(other.augment_holds.size() == 1 and other.augment_holds[0].candidates[0].id == "command_capacity" and own.augment_holds[0].candidates[0].has("compare"),"opponent holds stay private")
	check(JSON.stringify(own).to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT,"private snapshot stays within wire limit")
	for width in [1080,1536]:
		var popup = POPUP.new()
		root.add_child(popup)
		popup.set_anchors_preset(Control.PRESET_TOP_LEFT)
		popup.size = Vector2(width,1920)
		popup.set_holds(own.augment_holds)
		popup.open_index(0)
		check(popup.size.x == width and popup.popup.position.x >= 0.0 and popup.popup.position.y >= 0.0 and popup.popup.position.x+popup.popup.size.x <= width and popup.popup.position.y+popup.popup.size.y <= 1920.0,"popup fits %d x 1920" % width)
		popup.queue_free()
	room.queue_free()
	print("AUGMENT_COMPARE_FAIL checks=" if failed else "AUGMENT_COMPARE_PASS checks=",checks); quit(1 if failed else 0)
