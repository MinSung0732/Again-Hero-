extends SceneTree
const C := preload("res://src/data/stage_catalog.gd")
const E := preload("res://src/data/campaign_experience_catalog.gd")
const M := preload("res://src/systems/combat_insight_model.gd")
const P := preload("res://src/systems/stage_progress.gd")
const S := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const MC := preload("res://src/data/monster_catalog.gd")
const TEAM := preload("res://src/systems/team_loadout_store.gd")
const GDAT := preload("res://src/data/gumiho_behavior_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var gateway := root.get_node_or_null("LoginGateway")
	if gateway != null: gateway.remember_session_enabled = false
	var folder := "user://campaign_smoke_"+Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder); S.select_guest(); S.guest_directory = folder
	var mode := root.get_node_or_null("LocalTestMode")
	if mode != null: mode.active = false; mode.tutorial_preview = false; mode.test_directory = folder.path_join("isolated")
	check(GDAT.NORMAL_VISUAL.target_height == 240.03 and GDAT.ELITE_VISUAL.target_height == 203.2 and GDAT.FOX_VISUAL.target_height == 222.25,"normal gumiho additional135percent; elite/fox preserved")
	var total := 0.0
	for id in ["stage_1","stage_2","stage_3"]:
		var stage := C.get_stage(id); total += float(stage.run_duration_seconds)
		check(stage.opening_command == 24,"opening resources:"+id)
		var previous := -1.0
		for event in stage.event_timeline:
			check(event.at_seconds > previous and event.at_seconds < stage.run_duration_seconds,"timeline valid:"+id); previous = event.at_seconds
		stage.event_timeline[0].at_seconds = 999.0
		check(C.get_stage(id).event_timeline[0].at_seconds == E.PROFILES[id].events[0],"catalog deepcopy:"+id)
	check(total == 720,"first three time limits12min")
	check(C.get_stage("stage_4") == C.STAGES.stage_4,"stage4 untouched")
	var model := M.new(); model.reset("stage_1")
	for i in 31: model.sample(i,i*10,1000-i*10,1000)
	check(model.current_window_damage == 100 and model.previous_window_damage == 100,"rolling10sec actualHPdamage")
	check(not model.sample(30.1,999,1,1000),"no duplicate sample in same second")
	model.reset("stage_1"); model.sample(0,0,1000,1000); model.sample(10,50,800,1000)
	check(model.current_window_damage == 50 and model.previous_window_damage == 0,"early samples no fabricated pastdamage")
	model.record_choice("민첩한 발놀림",10)
	check(model.counter == E.COUNTERS.mobility and model.headline(12).contains("민첩한 발놀림"),"actual augment tags yield counter")
	check(model.result_note(false).contains("다음 실험"),"failure action")
	model.sample(11,60,190,1000); check(model.result_note(false).contains("19%"),"near win realHP evidence")
	check(model.result_note(true).contains("폭탄쥐"),"next opponent/newtool hook")
	check(TEAM.default_ids(MC.ORDER) == ["slime","spider","orc"],"starter defaults independent of new monster order")
	model.reset("stage_1"); model.record_choice("민첩한 발놀림",1); model.configure_roster(["slime","spider","orc"]); model.record_summon("slime"); model.record_choice("민첩한 발놀림",1)
	model.available_command = 24; model.recommended_cost = 7
	check(model.hint(1).contains("거미"),"early choice recommends an equipped counter")
	check(TEAM.save_ids([],COLLECTION.get_unlocked_ids()) and TEAM.load_ids(COLLECTION.get_unlocked_ids(),TEAM.default_ids(COLLECTION.get_unlocked_ids())).is_empty(),"intentionally empty formation preserved")
	check(TEAM.save_ids(["orc","spider"],COLLECTION.get_unlocked_ids()) and TEAM.load_ids(COLLECTION.get_unlocked_ids(),[] ) == ["orc","spider"],"saved order/partial formation preserved")
	check(E.counter_hint(["area","mobility"],"fallback") == E.COUNTERS.area,"priority hint")
	check(not COLLECTION.is_unlocked("bomb_rat"),"new account bomb locked")
	var reward := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(reward.success and reward.gold_reward == 1000 and reward.reward == 300,"normal clear reward maintained")
	check(COLLECTION.is_unlocked("bomb_rat") and P.is_campaign_reward_claimed("stage_1"),"new monster awarded with claim")
	check(reward.campaign_reward.unlocked and reward.campaign_reward.monster_id == "bomb_rat","reward presentation")
	var repeat := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(repeat.success and repeat.gold_reward == 0 and repeat.reward == 0 and repeat.campaign_reward.is_empty(),"repeated clear no duplicate rewards")
	check(COLLECTION.get_shards("bomb_rat") == 0,"new unlock not free shards")
	for stage in ["stage_2","stage_3"]:
		var id := String(E.PROFILES[stage].reward_monster)
		var number: int = C.get_stage(stage).number
		var result := P.complete_stage(stage,number,"stage_%d" % (number+1),number+1,450)
		check(result.success and COLLECTION.is_unlocked(id),"later guaranteed tool:"+id)
	# Pre-owned monster gets shards once, never overwrites level or other collection entries.
	var cfg := ConfigFile.new(); S.load_config(cfg,"user://stage_progress.cfg"); cfg.set_value("milestone_reward_claimed","campaign_stage_1",false); S.save_config(cfg,"user://stage_progress.cfg")
	var owned := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(not owned.campaign_reward.unlocked and owned.campaign_reward.shards == 10 and COLLECTION.get_shards("bomb_rat") == 10,"preowned10shards")
	P.complete_stage("stage_1",1,"stage_2",2,300); check(COLLECTION.get_shards("bomb_rat") == 10,"owned reward duplicate protected")
	# A corrupt collection cannot claim progress or grant currency ahead of the monster.
	var corrupt_folder := folder.path_join("corrupt"); DirAccess.make_dir_recursive_absolute(corrupt_folder); S.guest_directory = corrupt_folder
	var bad := FileAccess.open(corrupt_folder.path_join("monster_collection.cfg"),FileAccess.WRITE); bad.store_string("[invalid"); bad.close()
	var failed := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(not failed.success and not P.is_stage_cleared("stage_1") and not P.is_campaign_reward_claimed("stage_1"),"bad collection no partial grant")
	DirAccess.remove_absolute(corrupt_folder.path_join("monster_collection.cfg"))
	var retry := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(retry.success and retry.gold_reward == 1000 and retry.campaign_reward.unlocked,"storage recovery full retry")
	# Logged-in account bundles isolate data and stage+collection advance in one serial.
	var uid := "12345678-1234-1234-1234-"+Crypto.new().generate_random_bytes(6).hex_encode()
	check(S.select_account(uid),"account namespace selected")
	var serial_before := S.serial
	var account := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(account.success and S.serial == serial_before+1 and S.files.has("monster_collection.cfg") and S.files.has("stage_progress.cfg"),"account single bundle transaction")
	check(S.valid_payload(S.files),"save schema compatible")
	# Simulated write failure after both rewards were prepared: bundle+flags roll back together.
	var progress := ConfigFile.new(); S.load_config(progress,"user://stage_progress.cfg")
	progress.set_value("milestone_reward_claimed","campaign_stage_1",false); S.save_config(progress,"user://stage_progress.cfg")
	var snapshot := S.files.duplicate(true); var saved_serial := S.serial
	var blocked := S.resolve("user://save_bundle.json.tmp"); DirAccess.make_dir_recursive_absolute(blocked)
	var blocked_result := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(not blocked_result.success and S.files == snapshot and S.serial == saved_serial and not P.is_campaign_reward_claimed("stage_1"),"failed save rolls back currency/collection/claim")
	DirAccess.remove_absolute(blocked)
	var recovered := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(recovered.success and recovered.campaign_reward.shards == 10,"failed-save retry awards exactly once")
	# Maximum-level duplicate becomes research rather than unusable shards.
	var collection := COLLECTION.load_state(); collection.bomb_rat.level = MC.get_max_upgrade_level("bomb_rat"); collection.bomb_rat.shards = 0; COLLECTION.save_state(collection)
	S.load_config(progress,"user://stage_progress.cfg"); progress.set_value("milestone_reward_claimed","campaign_stage_1",false); S.save_config(progress,"user://stage_progress.cfg")
	var before_points: int = P.load_state().research_points
	var maxed := P.complete_stage("stage_1",1,"stage_2",2,300)
	check(maxed.success and maxed.campaign_reward.research == 10*MC.get_shard_research_points("bomb_rat") and P.load_state().research_points == before_points+maxed.campaign_reward.research and COLLECTION.get_shards("bomb_rat") == 0 and maxed.research_points == P.load_state().research_points,"maxed duplicate conversion atomic")
	S.select_guest(); S.guest_directory = folder.path_join("different"); DirAccess.make_dir_recursive_absolute(S.guest_directory)
	check(not COLLECTION.is_unlocked("bomb_rat") and not P.is_campaign_reward_claimed("stage_1"),"other account/guest no leaked reward")
	print("CAMPAIGN_EXPERIENCE_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
