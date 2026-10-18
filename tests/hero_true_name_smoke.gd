extends SceneTree
const P := preload("res://src/systems/stage_progress.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const NAMES := preload("res://src/data/hero_reveal_catalog.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
const EXPECTED := {
	"stage_1": ["아스트라", "Astra"], "stage_2": ["아길리스", "Agilis"],
	"stage_3": ["피르무스", "Firmus"], "stage_4": ["솔리투도", "Sōlitūdō"],
	"stage_5": ["아스트라", "Astra"], "stage_6": ["데멘티아", "Dementia"],
	"stage_7": ["릭소사", "rixosa"], "stage_8": ["데쿠스", "Decus"],
	"stage_9": ["미티스", "Mitis"], "stage_10": ["아스트라", "Astra"],
}
var checks := 0
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func fresh_guest():
	SCOPE.select_guest(); SCOPE.write_allowed = Callable(); SCOPE.saved_callback = Callable()
	SCOPE.guest_directory = "user://true-names-" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
func config() -> ConfigFile:
	var result := ConfigFile.new(); SCOPE.load_config(result, P.SAVE_PATH); return result
func clear(stage_id: String) -> Dictionary:
	var stage: Dictionary = STAGES.get_stage(stage_id)
	var next: Dictionary = STAGES.get_stage(String(stage.get("next_stage_id", "")))
	return P.complete_stage(stage_id, int(stage.number), String(stage.get("next_stage_id", "")), int(next.get("number", 0)), int(stage.get("first_clear_reward", 0)))
func unlocked(stage_id: String) -> bool:
	return P.is_hero_true_name_unlocked(stage_id, NAMES.identity_for(String(STAGES.STAGES[stage_id].hero_id)))
func uuid() -> String:
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
func run():
	fresh_guest()
	for stage_id in EXPECTED:
		var id := String(STAGES.STAGES[stage_id].hero_id)
		var data: Dictionary = NAMES.DATA[id]
		check(data.true_name == EXPECTED[stage_id][0] and data.latin_name == EXPECTED[stage_id][1], "canonical spelling " + stage_id)
		check(P.hero_display_name(id, "alias") == "alias", "locked alias " + stage_id)
		var reveal := NAMES.get_reveal_data(id, "alias", "portrait")
		check(reveal.true_name_label == "%s (%s)" % EXPECTED[stage_id], "reveal bilingual label " + stage_id)
	for stage_id in EXPECTED:
		var id := String(STAGES.STAGES[stage_id].hero_id)
		var story: bool = bool(NAMES.DATA[id].get("unlock_rule", {}).get("story_only", false))
		fresh_guest()
		for count in range(1, 11):
			var result := clear(stage_id)
			check(result.success, "save clear " + stage_id)
			check(unlocked(stage_id) == (count == 10 and not story), "9/10 boundary " + stage_id)
			check(int(config().get_value("hero_clear_counts",stage_id,0)) == count, "exact clear count")
			check(int(result.gold_reward) == (int(STAGES.CLEAR_GOLD_REWARDS.stage_first_clear) if count == 1 else 0), "first gold never duplicated")
		if not story:
			check(P.hero_display_name(id, "alias") == EXPECTED[stage_id][0], "unlocked name " + stage_id)
			check(P.hero_display_name(id, "alias", true) == "%s (%s)" % EXPECTED[stage_id], "latin display " + stage_id)
			for other in EXPECTED:
				if NAMES.identity_for(String(STAGES.STAGES[other].hero_id)) != NAMES.identity_for(id): check(not unlocked(other), "independent hero identity")
		fresh_guest()
		check(clear(stage_id).success, "hard prerequisite")
		var result := P.complete_hard_stage(stage_id)
		check(result.success and unlocked(stage_id) == (not story), "hard first unlock " + stage_id)
		check(int(config().get_value("hero_hard_clear_counts",stage_id,0)) == 1, "hard count")
		check(P.complete_hard_stage(stage_id).reward == 0, "hard reward stays first only")
	# Encounters cannot substitute for victories.
	fresh_guest()
	for i in range(101): P.record_hero_encounter("stage_2", "swift_hunter")
	check(not unlocked("stage_2"), "101 encounters are not clears")
	# Only proven old clears can be migrated; old hard wins already qualify.
	var old := config(); old.set_value("cleared","stage_2",true); old.set_value("hard_cleared","stage_3",true)
	old.set_value("hero_true_names","chemical_hero",true)
	check(SCOPE.save_config(old,P.SAVE_PATH) == OK, "legacy seed")
	check(not unlocked("stage_2") and unlocked("stage_3") and unlocked("stage_7"), "legacy hard and explicit unlock preserved")
	check(clear("stage_2").success and int(config().get_value("hero_clear_counts","stage_2",0)) == 2, "old easy flag proves one clear")
	# Astra continues using the same story event, shared across versions.
	fresh_guest()
	var shared := NAMES.identity_for("ranged_rookie")
	check(shared == NAMES.identity_for("archmage_hero") and shared == NAMES.identity_for("sage_astra"), "Astra shared identity")
	check(P.reveal_hero_true_name(shared), "story disclosure saves")
	for stage_id in ["stage_1","stage_5","stage_10"]: check(unlocked(stage_id), "all Astra versions reveal")
	var story_event := false
	for line in DIALOGUES.get_dialogue("stage_10").get("lines", []):
		if line.get("event", "") == "reveal_hero_true_name": story_event = line.get("identity_id", "") == shared and line.get("apply_on_skip", false)
	check(story_event, "existing stage10 story and skip retained")
	# Real account bundle rollback, retry, isolation, restart and JSON cloud transport.
	var a := uuid(); var b := uuid()
	check(SCOPE.select_account(a), "select account A")
	var seed := ConfigFile.new(); seed.set_value("cleared","stage_2",true); seed.set_value("hero_clear_counts","stage_2",9)
	check(SCOPE.save_config(seed,P.SAVE_PATH) == OK, "account counter seed")
	var before := SCOPE.files.duplicate(true)
	SCOPE.write_allowed = func(): return false
	check(not clear("stage_2").success and SCOPE.files == before and not unlocked("stage_2"), "failed save cannot count or unlock")
	SCOPE.write_allowed = Callable()
	check(clear("stage_2").success and unlocked("stage_2"), "successful retry reaches 10 once")
	check(int(config().get_value("hero_clear_counts","stage_2",0)) == 10, "retry count exact")
	var payload: Dictionary = JSON.parse_string(JSON.stringify(SCOPE.files))
	check(SCOPE.valid_payload(payload) and SCOPE.dirty and SCOPE.pending_cloud.new_payload == SCOPE.files, "unlock/counter in existing cloud request")
	check(SCOPE.select_account(b) and not unlocked("stage_2"), "account B cannot see A")
	check(P.hero_display_name("swift_hunter", "alias") == "alias", "account B alias")
	check(SCOPE.select_account(a) and unlocked("stage_2"), "account restart persists name")
	check(SCOPE.install(payload,17) and unlocked("stage_2"), "JSON cloud install preserves unlock and counter")
	check(P.hero_display_name("swift_hunter", "alias") == "아길리스", "cloud restored display")
	var hard_seed := config(); hard_seed.set_value("cleared","stage_3",true); SCOPE.save_config(hard_seed,P.SAVE_PATH)
	before = SCOPE.files.duplicate(true); SCOPE.write_allowed = func(): return false
	check(not P.complete_hard_stage("stage_3").success and SCOPE.files == before and not unlocked("stage_3"), "failed hard save cannot unlock")
	SCOPE.write_allowed = Callable()
	check(P.complete_hard_stage("stage_3").success and unlocked("stage_3"), "hard retry saves exactly once")
	fresh_guest(); check(not unlocked("stage_2"), "guest has no account unlock leakage")
	print("HERO_TRUE_NAME checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
