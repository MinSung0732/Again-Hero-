extends SceneTree
const STORE := preload("res://src/systems/hero_mode_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("LOCAL_HERO: "+label)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var mode := root.get_node("LocalTestMode")
	var directory := "user://local_hero_"+str(Time.get_ticks_usec())
	mode.active = false; mode.tutorial_preview = false; mode.pending_reset_id = ""; mode.original_user_id = ""
	mode.marker_path = directory+"/marker.cfg"; mode.test_directory = directory+"/test"
	SCOPE.select_guest(); SCOPE.guest_directory = directory+"/normal"; DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory); DirAccess.make_dir_recursive_absolute(directory)
	var progress := ConfigFile.new(); progress.set_value("meta","gold",17)
	check(SCOPE.save_config(progress,"user://stage_progress.cfg") == OK,"normal account fixture")
	check(not STORE.character_unlocked("sage_astra"),"normal guest stays locked")
	check(await mode.apply_coupon("localtest"),"real localtest coupon enters isolated save")
	check(STORE.all_characters_unlocked_for_test(),"local test override active")
	for id in CHARACTERS.ORDER:
		check(STORE.character_unlocked(id) and STORE.character_unlocked(String(CHARACTERS.get_character(id).stage)),"all character and legacy stage IDs unlocked: "+id)
		check(STORE.select_hero(id) and STORE.selected_hero() == id,"all characters selectable: "+id)
	check(not STORE.character_unlocked("unknown"),"unknown character stays invalid")
	var test_config := ConfigFile.new(); SCOPE.load_config(test_config,"user://team_loadout.cfg")
	check(not test_config.has_section("hero_collection"),"override does not forge permanent collection")
	SCOPE.load_config(test_config,"user://stage_progress.cfg")
	check(not test_config.has_section("hard_cleared"),"override does not forge hard-clear records")
	var test_directory: String = SCOPE.guest_directory
	SCOPE.guest_directory = directory+"/other"
	check(not STORE.all_characters_unlocked_for_test() and not STORE.character_unlocked("sage_astra"),"stale active flag cannot unlock another guest")
	SCOPE.guest_directory = test_directory; mode.tutorial_preview = true
	check(not STORE.character_unlocked("sage_astra"),"tutorial preview stays locked")
	mode.tutorial_preview = false
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate(); root.add_child(lobby)
	await lobby.main_modes_view.choose_perspective("hero"); lobby.team_button.pressed.emit()
	for id in CHARACTERS.ORDER: check(not lobby.hero_lobby_view.hero_cards[id].disabled,"actual roster card unlocked: "+id)
	lobby.hero_lobby_view._select_character("sage_astra")
	check(STORE.selected_hero() == "sage_astra","actual card click saves locked-by-default sage")
	lobby.queue_free(); await process_frame
	var ticket := STAMINA.try_enter("stage_1",true,-1,false)
	check(ticket.success,"local sage entry receipt")
	root.get_node("SceneTransition").set("_entry_options",{"stage_id":"stage_1","hero_id":"sage_astra","hero_entry":ticket})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(scene)
	if not scene.entry_ready: await scene.entry_started
	check(is_instance_valid(scene.battle) and scene.battle.hero.hero_id == "sage_astra","actual hero entry accepts locally unlocked sage")
	scene.queue_free(); await process_frame
	check(await mode.apply_coupon("normaltest"),"real normaltest coupon exits test save")
	check(not STORE.character_unlocked("sage_astra") and STORE.selected_hero() == CHARACTERS.DEFAULT_HERO,"normal selection and lock restored")
	var normal := ConfigFile.new(); SCOPE.load_config(normal,"user://stage_progress.cfg")
	check(int(normal.get_value("meta","gold",0)) == 17 and not normal.has_section("hard_cleared"),"normal account progress preserved")
	print("LOCAL_TEST_HERO_UNLOCK_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
