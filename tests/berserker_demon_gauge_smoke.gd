extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error("BERSERKER_GAUGE: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://gauge_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	for stage in ["stage_6","stage_1"]:
		PROGRESS.set_current_stage(stage)
		var battle = load("res://src/battle/Battle.tscn").instantiate()
		root.add_child(battle)
		battle.set_process(false)
		battle.set_physics_process(false)
		await battle.prepare_spawn_resources()
		var hero = battle.hero
		hero.set_physics_process(false)
		battle.demon_ultimate_charge = 0
		hero.max_hp = 10000
		hero.current_hp = 10000
		hero.shield_hp = 0
		if stage == "stage_6":
			check(hero.hero_archetype == "berserker_madness","actual stage six profile")
			for i in range(20):
				hero._pay_berserker_skill_hp_cost(0.1)
				hero.heal_direct(10000)
			check(battle.demon_ultimate_charge == 0 and battle.run_metrics.total_damage_dealt == 0,"twenty blood art cost/heal cycles do not grant gauge or damage metrics")
			hero.ultimate_charge = 0
			hero.notify_berserker_skill_kill()
			check(hero.ultimate_charge > 0 and battle.demon_ultimate_charge == 0,"hero madness kill gauge preserved separately")
		hero.invulnerability_timer = 0
		hero.take_damage(100)
		check(battle.demon_ultimate_charge == 25 and battle.run_metrics.total_damage_dealt == 100,"real hit charges exactly once " + stage)
		hero.heal_direct(100)
		check(battle.demon_ultimate_charge == 25,"heal does not charge " + stage)
		hero.invulnerability_timer = 100
		hero.take_damage(100)
		check(battle.demon_ultimate_charge == 25,"blocked hit no charge " + stage)
		hero.take_status_damage(100)
		check(battle.demon_ultimate_charge == 50 and battle.run_metrics.total_damage_dealt == 200,"status HP damage once " + stage)
		hero.invulnerability_timer = 0
		hero.shield_hp = 200
		hero.take_damage(100)
		check(battle.demon_ultimate_charge == 50,"full shield no HP charge " + stage)
		hero.invulnerability_timer = 0
		hero.shield_hp = 25
		hero.take_damage(100)
		check(battle.demon_ultimate_charge == 68.75 and battle.run_metrics.total_damage_dealt == 275,"partial shield actual HP damage only " + stage)
		hero.current_hp = 20
		hero.health_changed.emit(20,10000)
		check(battle.demon_ultimate_charge == 68.75,"health synchronization alone does not charge " + stage)
		hero.invulnerability_timer = 0
		hero.take_damage(10000)
		check(battle.demon_ultimate_charge == 73.75 and battle.run_metrics.total_damage_dealt == 295,"lethal overkill charges twenty actual HP once " + stage)
		battle.free()
	print("BERSERKER_GAUGE: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
