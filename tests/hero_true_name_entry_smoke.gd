extends SceneTree
const P := preload("res://src/systems/stage_progress.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const NAMES := preload("res://src/data/hero_reveal_catalog.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
var checks := 0
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; push_error(label)
func run():
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://true-name-entry-"+Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var script = load("res://entry_fixture.gd")
	for unlocked in [false, true]:
		var config := ConfigFile.new()
		for id in NAMES.DATA: config.set_value("hero_true_names",NAMES.identity_for(id),unlocked)
		check(SCOPE.save_config(config,P.SAVE_PATH) == OK, "seed name state")
		for stage_id in STAGES.get_ordered_stage_ids():
			var id := String(STAGES.STAGES[stage_id].hero_id)
			var host = script.new()
			host.battle.current_hero_profile = {"id":id,"display_name":"alias"}
			host._begin_stage_entry({"stage_id":stage_id,"hero_id":id})
			var alias := String(DIALOGUES.get_dialogue(stage_id).get("hero_name","용사"))
			var expected := String(NAMES.DATA[id].true_name) if unlocked else alias
			check(host.stage_intro_cutscene.received.hero_name == expected, "actual Main dialogue " + stage_id)
			check(host._stage_intro_active and not host.hud_layer.visible, "entry pause/UI flow kept")
	# Disclosure updates the active snapshot only after a successful scoped save.
	var config := ConfigFile.new(); SCOPE.save_config(config,P.SAVE_PATH)
	var host = script.new()
	host.battle.current_hero_profile = {"id":"sage_astra","display_name":"alias"}
	host._on_stage_intro_dialogue_event("unrelated",{})
	check(host.snapshot.is_empty(), "unrelated event does not change name")
	host._on_stage_intro_dialogue_event("reveal_hero_true_name",{"identity_id":"returning_magic_hero","true_name":"아스트라"})
	check(host.snapshot.hero_name == "아스트라" and P.hero_display_name("ranged_rookie","alias") == "아스트라", "actual story handler updates active and shared names")
	host._skip_entry_dialogue = true
	host._begin_stage_entry({"stage_id":"stage_10","hero_id":"sage_astra"})
	check(host.reveal_count == 1 and not host._skip_entry_dialogue, "restart skip handoff unchanged")
	host.battle.practice_mode = true
	host._begin_stage_entry({})
	check(host.battle_count == 1, "practice entry unchanged")
	print("HERO_TRUE_NAME_ENTRY checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
