extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const HARD := preload("res://src/data/hard_campaign_catalog.gd")
const GATE := preload("res://src/data/mode_unlock_catalog.gd")

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HARD_STAGE2: " + label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var previous_dir := SCOPE.guest_directory
	SCOPE.guest_directory = "user://hard_stage2_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("cleared", "stage_1", true)
	cfg.set_value("cleared", "stage_2", true)
	cfg.set_value("progress", "current_stage_id", "stage_2")
	cfg.set_value("progress", "highest_unlocked_stage", 3)
	check(SCOPE.save_config(cfg, PROGRESS.SAVE_PATH) == OK, "stage2 easy-clear fixture saved")
	check(GATE.scene_entry_available("res://src/main/Main.tscn", {"difficulty": "hard", "stage_id": "stage_2"}), "hard stage2 entry allowed")
	check(not GATE.difficulty_available("hard", "stage_3", "demon"), "stage3 hard locked")

	var battle := load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	var hero = battle.hero
	check(battle.current_stage_id == "stage_2" and hero.hero_id == "swift_hunter", "stage2 rogue selected")
	# Regression: Stage 2 easy used to stall completely after hard archetype edits.
	# Rogue's own physics tick must advance both the passive gauge and AI timers.
	var easy_charge := hero.ultimate_charge
	hero.attack_timer = 1.0
	hero._physics_process_rogue(0.2)
	check(hero.ultimate_charge > easy_charge, "easy rogue passive gauge advances")
	check(hero.attack_timer < 1.0, "easy rogue AI attack timer advances")
	check(not hero.hard_stage2_enabled and hero.hard_stage2_weakness_timer == 0.0, "easy rogue has no hard-only locks")
	var starting_hp: int = hero.max_hp
	var starting_damage: int = hero.attack_damage
	var starting_move_speed: float = hero.move_speed
	var starting_attack_interval: float = hero.attack_cooldown
	battle.configure_campaign_difficulty("hard")
	check(battle.campaign_difficulty == "hard" and hero.hard_stage2_enabled, "hard rogue configured")
	var hard_charge := hero.ultimate_charge
	hero._physics_process_rogue(0.2)
	check(hero.ultimate_charge > hard_charge, "hard rogue passive gauge advances")
	check(hero.max_hp == roundi(starting_hp * 1.88), "stage2 hp x1.88")
	check(hero.attack_damage == roundi(starting_damage * 1.88), "stage2 attack x1.88")
	check(is_equal_approx(hero.move_speed, starting_move_speed * 1.10), "stage2 move x1.10")
	check(is_equal_approx(hero.attack_cooldown, starting_attack_interval / 1.10), "stage2 attack interval /1.10")
	check(is_equal_approx(hero.hard_regeneration_multiplier, 1.10), "hard regeneration multiplier configured")
	check(not hero.hard_stage1_enabled and not hero.hard_stage2_awakened, "rogue starts without hard activation")

	var observed := {"count": 0, "id": "", "path": ""}
	battle.conditional_skill_unlocked.connect(func(skill_id: String, _name: String, payload: Dictionary) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["id"] = skill_id
		observed["path"] = String(payload.get("cutscene_texture_path", ""))
	)
	hero.current_hp = ceili(float(hero.max_hp) * 0.51)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(int(observed["count"]) == 0, "above-half hp does not awaken")
	hero.current_hp = floori(float(hero.max_hp) * 0.50)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(hero.hard_stage2_awakened and int(observed["count"]) == 1, "first half-hp triggers awakening")
	check(
		String(observed["id"]) == String(HARD.STAGE_2.awakening_skill_id)
		and String(observed["path"]) == String(HARD.STAGE_2.cutscene_texture_path)
		and ResourceLoader.exists(String(observed["path"])),
		"stage2 cutscene points at a real image"
	)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(int(observed["count"]) == 1, "awakening can only happen once")

	hero.rogue_assassination_hit_bonus = 3
	hero.ultimate_charge = float(hero.ultimate_config.get("charge_max", 100.0))
	hero._start_rogue_assassination()
	var expected_hits := int(hero.ultimate_config.get("hit_count", 5)) + 3 + int(HARD.STAGE_2.extra_assassination_hits)
	check(hero.rogue_assassination_active and hero.rogue_assassination_hits_left == expected_hits, "augment extra hits and two hard hits combine")
	hero._end_rogue_assassination()
	check(not hero.rogue_assassination_active and hero.hard_stage2_weakness_timer > 0.0, "assassination end starts weakness")
	check(hero.damage_taken_increase_ratio >= float(HARD.STAGE_2.weakness_damage_taken_increase), "weakness adds incoming damage")
	check(is_equal_approx(hero._get_effective_move_multiplier(), float(HARD.STAGE_2.weakness_move_speed_multiplier)), "weakness slows rogue movement")
	check(not hero._rogue_can_start_assassination() and not hero._rogue_should_use_slash(), "dash and slash locked during weakness")
	hero._start_rogue_assassination()
	check(not hero.rogue_assassination_active, "weakness rejects direct ability trigger")
	hero._update_hard_stage2(float(HARD.STAGE_2.weakness_seconds) + 0.01)
	check(hero.hard_stage2_weakness_timer == 0.0, "weakness timer expires")
	hero.rogue_assassination_hit_bonus = 0

	var first := PROGRESS.complete_hard_stage("stage_2")
	check(bool(first.get("success", false)) and int(first.reward) == 500 and int(first.gold_reward) == 1000 and int(first.demon_token_reward) == 30, "stage2 first hard reward")
	check(PROGRESS.get_research_points() == 500 and PROGRESS.get_gold() == 1000 and PROGRESS.get_demon_token() == 30, "stage2 reward deposited")
	var again := PROGRESS.complete_hard_stage("stage_2")
	check(bool(again.get("success", false)) and int(again.reward) == 0 and int(again.gold_reward) == 0 and int(again.demon_token_reward) == 0, "stage2 repeat has no first bonus")
	battle.queue_free()
	await process_frame
	SCOPE.guest_directory = previous_dir
	SCOPE.select_guest()
	print("HARD_STAGE2 checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
