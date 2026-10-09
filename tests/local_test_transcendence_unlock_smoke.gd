extends SceneTree
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var mode := root.get_node("LocalTestMode")
	var battle = load("res://src/battle/battle.gd").new()
	var rules := preload("res://src/data/zeus_behavior_catalog.gd").RULES
	battle.transcendence.configure("zeus",rules)
	var before_command: float = battle.command_power
	var before_summons: int = battle.raw_allied_summons
	mode.active = false
	check(not battle.debug_unlock_transcendence(),"normal account blocked")
	mode.active = true
	check(not battle._can_attempt_summon("zeus",true),"locked before test click")
	battle.transcendence.record_command(300)
	battle.transcendence.record_mana(200)
	check(battle.transcendence.ready and not battle.transcendence.test_unlock_confirmed,"natural ready does not confirm click")
	check(not battle._can_attempt_summon("zeus",true),"natural readiness still needs test click")
	check(battle._spawn_monster("zeus",Vector2.ZERO,0.0,false,{"transcendence_summon":true}) == null,"direct spawn cannot bypass test click")
	check(battle.debug_unlock_transcendence(),"explicit test unlock succeeds even if counters already ready")
	check(battle._can_attempt_summon("zeus",true),"summon allowed after confirmation")
	check(battle.command_power == before_command and battle.raw_allied_summons == before_summons,"resources and spawn snapshot unchanged")
	check(not battle.debug_unlock_transcendence(),"duplicate unlock rejected")
	battle.transcendence.consume()
	check(not battle.debug_unlock_transcendence(),"used summon cannot reset")
	battle.transcendence.configure("zeus",rules)
	check(not battle.transcendence.test_unlock_confirmed,"new run clears explicit unlock")
	battle.external_pause = true
	check(not battle.debug_unlock_transcendence(),"menu blocks unlock")
	battle.external_pause = false
	battle.battle_over = true
	check(not battle.debug_unlock_transcendence(),"battle end blocks unlock")
	battle.battle_over = false
	mode.active = false
	battle.transcendence.record_command(300)
	battle.transcendence.record_mana(200)
	check(battle._can_attempt_summon("zeus",true),"normal gameplay natural requirements preserved")
	battle.free()
	print("LOCAL_TEST_TRANSCENDENCE_UNLOCK ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
