extends SceneTree
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
var checks := 0
var failures := 0
class HeroFixture extends Node2D:
	var hero_id := "ranged_rookie"
	var build_counts: Dictionary = {}
	var max_hp := 1200
	var move_speed := 270.0
	var exp_pickup_radius := 150.0
	var exp_gain_multiplier := 1.0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("CHARACTER_FORMATION: "+label)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest(); SCOPE.guest_directory = "user://character_formation_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var progress := ConfigFile.new(); progress.set_value("progress","current_stage_id","stage_1"); progress.set_value("progress","highest_unlocked_stage",1); progress.set_value("cleared","stage_2",true)
	check(SCOPE.save_config(progress,"user://stage_progress.cfg") == OK,"isolated campaign fixture")
	var config := ConfigFile.new(); config.set_value("team","monster_ids","orc,spider,slime"); config.set_value("hero_growth","stage_1_vitality",2)
	check(SCOPE.save_config(config,"user://team_loadout.cfg") == OK,"legacy loadout fixture")
	check(STORE.selected_hero() == CHARACTERS.DEFAULT_HERO,"default apprentice")
	check(STORE.growth_level(CHARACTERS.DEFAULT_HERO,"vitality") == 2,"legacy character growth migrates by origin key")
	check(not STORE.select_battle_stage("stage_10"),"new account cannot skip hero stages")
	for number in range(1,10): config.set_value("hero_progress","stage_%d_wins" % number,1)
	check(SCOPE.save_config(config,"user://team_loadout.cfg") == OK,"prior hero wins migrate separately from campaign")
	check(STORE.select_battle_stage("stage_10") and STORE.selected_hero() == CHARACTERS.DEFAULT_HERO,"map selection never changes hero")
	check(not STORE.select_hero("swift_hunter"),"easy clear is insufficient to select locked hero")
	check(PROGRESS.complete_hard_stage("stage_2").success and STORE.select_hero("swift_hunter"),"matching hard clear unlocks hero selection")
	check(STORE.selected_battle_stage() == "stage_10","hero selection never changes map")
	var ticket := STAMINA.try_enter("stage_10",true,-1,false)
	check(ticket.success and not STAMINA.claim_battle_entry("stage_10").is_empty(),"independent map has valid stamina receipt")
	SCOPE.load_config(progress,"user://stage_progress.cfg")
	check(String(progress.get_value("progress","current_stage_id","")) == "stage_1","hero entry preserves demon campaign stage")
	check(int(progress.get_value("progress","highest_unlocked_stage",0)) == 1,"map selection does not grant campaign unlocks")
	SCOPE.load_config(config,"user://team_loadout.cfg")
	check(config.get_value("team","monster_ids","") == "orc,spider,slime","demon formation preserved")
	check(STORE.set_character_owned_in_config(config,"sage_astra") and not STORE.set_character_owned_in_config(config,"unknown"),"future collection grant validates stable hero IDs")
	check(SCOPE.save_configs({"team_loadout.cfg":config}) == OK and STORE.character_unlocked("sage_astra"),"collection ownership is usable without hard clear")
	var fixture := HeroFixture.new(); root.add_child(fixture)
	var seen: Dictionary = {}
	for hero_id in CHARACTERS.ORDER:
		var pool := WEAPONS.weapon_pool(hero_id)
		check(pool.size() == 10,"ten weapons: "+hero_id)
		check(String(WEAPONS.STARTERS[hero_id]) in pool,"starter belongs to own kit")
		fixture.hero_id = hero_id; fixture.build_counts.clear()
		var runtime := RUNTIME.new(); runtime.install(fixture)
		for id in pool:
			check(not seen.has(id) and String(WEAPONS.WEAPONS[id].owner) == hero_id,"unique ownership: "+String(id)); seen[id] = true
		for candidate in runtime.candidates():
			if WEAPONS.is_weapon(candidate.id): check(String(candidate.id) in pool,"level-up only offers own weapons")
		var foreign := "swift_hunter_dagger" if hero_id == CHARACTERS.DEFAULT_HERO else "ranged_rookie_arcane_bolt"
		check(not runtime.add(foreign),"foreign weapon rejected")
	check(seen.size() == 100,"one hundred weapons total")
	var original := SCOPE.guest_directory; SCOPE.guest_directory += "_other"; DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	check(STORE.selected_hero() == CHARACTERS.DEFAULT_HERO and STORE.selected_battle_stage() == "stage_1" and not STORE.character_unlocked("sage_astra"),"character map and collection ownership are account scoped")
	SCOPE.guest_directory = original; fixture.queue_free()
	print("HERO_CHARACTER_FORMATION_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
