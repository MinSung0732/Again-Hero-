extends SceneTree
const LOADOUT := preload("res://src/online/online_loadout.gd")
const HEROES := preload("res://src/data/hero_character_catalog.gd")
const HERO_STORE := preload("res://src/systems/hero_mode_store.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var heroes := LOADOUT.unlocked_heroes()
	for id in HEROES.ORDER: check((String(id) in heroes) == HERO_STORE.character_unlocked(String(id)),"catalog unlock derivation: "+String(id))
	var selected := String(HEROES.ORDER[0])
	var locked := String(HEROES.ORDER[-1])
	var snapshot := {"progress":{"cleared":{"stage_3":true,"stage_1":true}},"monsters":{},"team_ids":"slime,spider,orc","skill_ids":"encirclement,line_assault,square_siege","transcendence_id":""}
	check(LOADOUT.owned("hero",{"hero_id":selected},snapshot),"owned hero")
	check(not LOADOUT.owned("hero",{"hero_id":locked},snapshot),"locked hero")
	var demon := {"team_ids":["slime","spider","orc"],"skill_ids":["encirclement","line_assault","square_siege"],"transcendence_id":""}
	check(LOADOUT.owned("demon",demon,snapshot),"owned saved formation")
	var bad := demon.duplicate(true); bad.team_ids[0] = "manticore"
	check(not LOADOUT.owned("demon",bad,snapshot),"unowned monster")
	bad = demon.duplicate(true); bad.team_ids.pop_back()
	check(not LOADOUT.owned("demon",bad,snapshot),"incomplete formation")
	check(not LOADOUT.valid("demon",{"team_ids":["slime"],"skill_ids":[],"transcendence_id":"a".repeat(65)}),"wire size")
	var other_hero := String(HEROES.ORDER[1])
	var room = ROOM.new(); root.add_child(room); room.set_loadouts({"hero_id":other_hero},demon)
	check(room.hero_id == other_hero and room.roster == demon.team_ids and room.skill_ids == demon.skill_ids,"room loadout assigned")
	room.prepare()
	check(room.is_prepared and room.battle.hero_player_hero_id == other_hero and room.battle.online_match_rules.roster == demon.team_ids,"battle loadout applied")
	check(room.battle.permanent_research_levels.is_empty() and room.battle.current_hero_profile.get("hero_research_bonuses",{}).is_empty(),"online research absent")
	var server = SERVER.new(); root.add_child(server)
	check(not server._loadout_verification_required(),"missing service key skips verification")
	var seat_data := {"seats":{"demon":{"uid":"demon"},"hero":{"uid":"hero"}},"rated":false}
	check(not server._result_can_record(seat_data,"hero","survived"),"unverified match unrated")
	room.queue_free(); server.queue_free()
	print("ONLINE_LOADOUT_PASS checks=",checks); quit()
