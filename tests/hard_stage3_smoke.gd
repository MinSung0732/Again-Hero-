extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const GATE := preload("res://src/data/mode_unlock_catalog.gd")
const HARD := preload("res://src/data/hard_campaign_catalog.gd")

class TrainingMonster:
	extends Node2D
	var current_hp := 1000
	func take_damage(amount: int) -> bool:
		current_hp = maxi(current_hp - amount, 0)
		return amount > 0

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HARD_STAGE3: " + label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var previous_dir := SCOPE.guest_directory
	SCOPE.guest_directory = "user://hard_stage3_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("cleared", "stage_1", true)
	cfg.set_value("cleared", "stage_2", true)
	cfg.set_value("cleared", "stage_3", true)
	cfg.set_value("progress", "current_stage_id", "stage_3")
	cfg.set_value("progress", "highest_unlocked_stage", 4)
	check(SCOPE.save_config(cfg, PROGRESS.SAVE_PATH) == OK, "stage3 easy-clear fixture saved")
	check(GATE.scene_entry_available("res://src/main/Main.tscn", {"difficulty":"hard", "stage_id":"stage_3"}), "stage3 hard entry")
	check(not GATE.difficulty_available("hard", "stage_4", "demon"), "stage4 still locked")
	check(not GATE.difficulty_available("hard", "stage_3", "hero"), "hero hard still locked")

	var battle := load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	var hero = battle.hero
	check(battle.current_stage_id == "stage_3" and hero.hero_id == "sword_shield_hero", "fighter selected")
	check(not hero.hard_stage3_enabled and not hero.hard_stage3_awakened, "easy fighter unchanged")
	var easy_max_hp: int = hero.max_hp
	var easy_attack: int = hero.attack_damage
	var easy_speed: float = hero.move_speed
	var easy_cooldown: float = hero.attack_cooldown
	battle.configure_campaign_difficulty("hard")
	check(battle.campaign_difficulty == "hard" and hero.hard_stage3_enabled, "hard fighter configured")
	check(hero.max_hp == roundi(easy_max_hp * 1.88) and hero.attack_damage == roundi(easy_attack * 1.88), "hp/damage scale once")
	check(is_equal_approx(hero.move_speed, easy_speed * 1.10) and is_equal_approx(hero.attack_cooldown, easy_cooldown / 1.10), "speed/interval scale once")
	check(is_equal_approx(hero.hard_regeneration_multiplier, 1.10), "regeneration configured")

	var front := TrainingMonster.new()
	front.add_to_group("monsters")
	root.add_child(front)
	front.global_position = hero.global_position + Vector2(100, 0)
	var rear := TrainingMonster.new()
	rear.add_to_group("monsters")
	root.add_child(rear)
	rear.global_position = hero.global_position + Vector2(-100, 0)
	hero.target = front
	var observed := {"count": 0, "id": "", "path": ""}
	battle.conditional_skill_unlocked.connect(func(skill_id: String, _name: String, payload: Dictionary) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["id"] = skill_id
		observed["path"] = String(payload.get("cutscene_texture_path", ""))
	)
	hero.current_hp = ceili(float(hero.max_hp) * 0.51)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(int(observed["count"]) == 0, "no early awakening")
	hero.current_hp = floori(float(hero.max_hp) * 0.50)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(hero.hard_stage3_awakened and int(observed["count"]) == 1, "first half hp awakens once")
	check(String(observed["id"]) == String(HARD.STAGE_3.awakening_skill_id) and ResourceLoader.exists(String(observed["path"])), "existing stage3 cutscene")
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	check(int(observed["count"]) == 1 and hero.hard_stage3_guard_timer > 0.0, "cutscene/stance not repeated")
	check(is_equal_approx(hero._get_effective_move_multiplier(), 0.70), "hard stance movement -30%")
	hero.invulnerability_timer = 0.0
	var before_front_hp: int = hero.current_hp
	var before_front_monster_hp: int = front.current_hp
	check(hero.take_damage(100, front), "front valid hit")
	check(before_front_hp - hero.current_hp == 50, "front damage 50% reduced")
	check(front.current_hp < before_front_monster_hp, "front counterattack")
	check(hero.hard_stage3_rear_hits == 0, "front hit never counts toward collapse")
	hero._update_hard_stage3(float(HARD.STAGE_3.guard_seconds) + 0.01)
	check(hero.hard_stage3_guard_timer == 0.0 and hero.hard_stage3_recovery_timer > 0.0, "natural finish starts recovery")
	check(hero.hard_stage3_break_timer == 0.0, "natural finish not broken")
	check(is_equal_approx(hero.hard_stage3_recast_timer, float(HARD.STAGE_3.guard_recast_seconds)), "natural finish starts 7s recast timer")
	hero._update_hard_stage3(float(HARD.STAGE_3.recovery_seconds) + 0.01)
	check(hero.hard_stage3_recovery_timer == 0.0, "natural recovery expires")
	check(hero.hard_stage3_guard_timer == 0.0 and hero.hard_stage3_recast_timer > 0.0, "no early repeat while cooling down")
	hero.target = null
	hero._update_hard_stage3(float(HARD.STAGE_3.guard_recast_seconds) + 0.01)
	check(hero.hard_stage3_guard_timer == 0.0 and hero.hard_stage3_recast_timer == 0.0, "recast waits for a valid enemy")
	hero.target = front
	front.current_hp = 0
	hero._update_hard_stage3(0.02)
	check(hero.hard_stage3_guard_timer == 0.0, "recast ignores defeated enemy")
	front.current_hp = 1000
	hero._update_hard_stage3(0.02)
	check(hero.hard_stage3_guard_timer > 0.0 and hero.hard_stage3_rear_hits == 0, "guard repeats on contact")
	check(int(observed["count"]) == 1 and hero.hard_stage3_awakened, "repeat never replays cutscene")
	hero.fighter_guard_active = true
	hero.shield_hp = 2000.0
	hero.shield_max_hp = 2000.0
	hero.fighter_guard_stored_damage = 10.0
	for i in 2:
		hero.invulnerability_timer = 0.0
		check(hero.take_damage(20, rear), "rear accepted hit " + str(i))
	check(hero.hard_stage3_rear_hits == 2 and hero.hard_stage3_guard_timer > 0.0, "two rear hits do not collapse")
	hero.invulnerability_timer = 0.0
	hero.take_status_damage(20, rear)
	check(hero.hard_stage3_rear_hits == 2, "status/DoT does not count")
	hero.invulnerability_timer = 0.0
	check(hero.take_damage(20, rear), "third rear hit accepted")
	check(hero.hard_stage3_guard_timer == 0.0 and hero.hard_stage3_break_timer > 0.0, "three rear hits collapse stance")
	check(is_equal_approx(hero.hard_stage3_recast_timer, float(HARD.STAGE_3.break_recast_seconds)), "rear break starts longer recast")
	check(hero.damage_taken_increase_ratio >= 0.20 and hero.hard_stage3_recovery_timer == 0.0, "break vulnerability +20% for 2s")
	check(hero.fighter_guard_active and hero.shield_hp > 0.0 and hero.fighter_guard_stored_damage > 10.0, "original guard/shield/storage survive break")
	check(is_equal_approx(hero._get_effective_move_multiplier(), 1.0), "hard movement penalty removed on break")
	hero._update_hard_stage3(float(HARD.STAGE_3.break_seconds) + 0.01)
	check(hero.hard_stage3_break_timer == 0.0 and hero.hard_stage3_recast_timer > 0.0, "break timer ends before recast")
	check(hero.hard_stage3_guard_timer == 0.0, "break cannot restart stance early")
	hero.target = rear
	hero._update_hard_stage3(float(HARD.STAGE_3.break_recast_seconds) + 0.01)
	check(hero.hard_stage3_guard_timer > 0.0 and hero.hard_stage3_rear_hits == 0, "guard repeats after broken cooldown")
	check(hero.hard_stage3_facing_direction.x < -0.9, "new cycle faces current enemy")
	check(int(observed["count"]) == 1, "no extra cutscene after broken cooldown")
	check(not hero.activate_hard_stage3(), "HP-triggered awakening cannot fire twice")

	var first := PROGRESS.complete_hard_stage("stage_3")
	check(bool(first.get("success", false)) and int(first.reward) == 500 and int(first.gold_reward) == 1000 and int(first.demon_token_reward) == 30, "stage3 first reward")
	var repeat := PROGRESS.complete_hard_stage("stage_3")
	check(bool(repeat.get("success", false)) and int(repeat.reward) == 0 and int(repeat.gold_reward) == 0 and int(repeat.demon_token_reward) == 0, "stage3 first reward not duplicated")

	front.queue_free()
	rear.queue_free()
	battle.queue_free()
	await process_frame
	SCOPE.guest_directory = previous_dir
	SCOPE.select_guest()
	print("HARD_STAGE3 checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
