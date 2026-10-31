extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const HARD := preload("res://src/data/hard_campaign_catalog.gd")
const GATE := preload("res://src/data/mode_unlock_catalog.gd")
const MAIN := preload("res://src/main/main.gd")

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HARD_STAGE1: " + label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var previous_dir := SCOPE.guest_directory
	SCOPE.guest_directory = "user://hard_stage1_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("cleared", "stage_1", true)
	check(SCOPE.save_config(cfg, PROGRESS.SAVE_PATH) == OK, "easy stage1 fixture saved")
	check(GATE.difficulty_available("hard", "stage_1", "demon"), "stage1 hard available")
	check(not GATE.difficulty_available("hard", "stage_2", "demon"), "stage2 hard remains locked")
	check(not GATE.difficulty_available("hard", "stage_1", "hero"), "hero hard remains locked")
	check(MAIN.should_skip_entry_dialogue("hard", false, "stage_1", "stage_1"), "hard first entry skips story dialogue")
	check(MAIN.should_skip_entry_dialogue("hard", false, "stage_2", "stage_1"), "hard skip independent of retry flag")
	check(not MAIN.should_skip_entry_dialogue("easy", false, "stage_1", "stage_1"), "easy first entry retains dialogue")
	check(MAIN.should_skip_entry_dialogue("easy", true, "stage_1", "stage_1"), "easy same-stage retry skips dialogue")
	check(not MAIN.should_skip_entry_dialogue("easy", true, "stage_2", "stage_1"), "easy other-stage retry retains dialogue")
	var battle := load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	var initial_hp: int = battle.hero.max_hp
	var initial_damage: int = battle.hero.attack_damage
	var initial_speed: float = battle.hero.move_speed
	var initial_cooldown: float = battle.hero.attack_cooldown
	battle.configure_campaign_difficulty("hard")
	check(battle.campaign_difficulty == "hard", "battle hard configured")
	check(battle.hero.max_hp == roundi(initial_hp * 1.88), "hard hp 1.88")
	check(battle.hero.attack_damage == roundi(initial_damage * 1.88), "hard damage 1.88")
	check(is_equal_approx(battle.hero.move_speed, initial_speed * 1.10), "hard speed 1.10")
	check(is_equal_approx(battle.hero.attack_cooldown, initial_cooldown / 1.10), "hard attack interval /1.10")
	check(is_equal_approx(battle.hero.hard_regeneration_multiplier, 1.10), "regeneration scale configured")
	check(not battle.hero.hard_stage1_awakened, "not awakened on entry")
	var observed := {"count": 0, "path": ""}
	battle.conditional_skill_unlocked.connect(func(_id: String, _name: String, payload: Dictionary) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["path"] = String(payload.get("cutscene_texture_path", ""))
	)
	battle.hero.current_hp = floori(float(battle.hero.max_hp) * 0.50)
	battle.hero.health_changed.emit(battle.hero.current_hp, battle.hero.max_hp)
	check(battle.hero.hard_stage1_awakened, "50 percent starts awakening")
	check(int(observed["count"]) == 1 and String(observed["path"]) == String(HARD.STAGE_1.cutscene_texture_path), "cutscene signal and asset")
	battle.hero.health_changed.emit(battle.hero.current_hp, battle.hero.max_hp)
	check(int(observed["count"]) == 1, "awakening emitted only once")
	var target := Node2D.new()
	root.add_child(target)
	target.global_position = battle.hero.global_position + Vector2(250.0, 0.0)
	for i in 3:
		battle.hero._fire_projectile(target)
	check(battle.hero.hard_stage1_attack_count == 0 and battle.hero.hard_stage1_windup_timer > 0.0, "third volley queues piercer warning")
	battle.hero._update_hard_stage1(float(HARD.STAGE_1.piercer_windup_seconds) + 0.01)
	check(battle.hero.hard_stage1_weakness_timer > 0.0, "piercer starts weakness")
	check(battle.hero.damage_taken_increase_ratio >= 0.20, "vulnerability applied")
	battle.hero._fire_projectile(target)
	check(battle.hero.hard_stage1_attack_count == 0, "weakness prevents new basic volley")
	var first := PROGRESS.complete_hard_stage("stage_1")
	check(first.get("success", false) and int(first.reward) == 500 and int(first.gold_reward) == 1000 and int(first.demon_token_reward) == 30, "fixed first clear reward")
	var second := PROGRESS.complete_hard_stage("stage_1")
	check(second.get("success", false) and int(second.reward) == 0 and int(second.gold_reward) == 0 and int(second.demon_token_reward) == 0, "repeat clear first rewards not duplicated")
	check(PROGRESS.get_gold() == 1000 and PROGRESS.get_demon_token() == 30 and PROGRESS.get_research_points() == 500, "wallet saved once")
	check(HARD.run_reward_multiplier("victory") > HARD.run_reward_multiplier("defeat") and HARD.run_reward_multiplier("defeat") > HARD.run_reward_multiplier("abandon"), "ordinary reward policy")
	target.queue_free()
	battle.queue_free()
	await process_frame
	SCOPE.guest_directory = previous_dir
	SCOPE.select_guest()
	print("HARD_STAGE1 checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
