extends SceneTree
var failed := false
class Host extends Control:
	var battle: Node
	var hud_layer := Control.new()
	var monster_info_bookmark := Button.new()
	const BATTLE_PIXEL_FRAME_MEDIUM_DIR := ""
	const BATTLE_PIXEL_CENTER_DARK := Color.BLACK
	func _replace_button_frame(_button, _directory, _scale, _color, _inset) -> void: pass
	func _load_monster_card_icon(_id: String) -> Texture2D: return null
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void: run.call_deferred()
func record_metric(runtime, metric: String, amount: int) -> void:
	match metric:
		"command_spent": runtime.record_command(amount)
		"mana_spent": runtime.record_mana(amount)
		"tanks_summoned":
			for i in range(amount): runtime.record_summon("tank")
		"allies_died":
			for i in range(amount): runtime.record_ally_death()
		"controls_summoned":
			for i in range(amount): runtime.record_summon("control")
		"statuses_applied":
			for i in range(amount): runtime.record_status()
func run() -> void:
	var mode := root.get_node("LocalTestMode")
	var battle = load("res://src/battle/battle.gd").new()
	var host := Host.new()
	host.battle = battle
	root.add_child(host)
	host.add_child(host.hud_layer)
	host.add_child(host.monster_info_bookmark)
	var view = load("res://src/ui/transcendence_summon_view.gd").new()
	view.install(host)
	var catalogs := [preload("res://src/data/zeus_behavior_catalog.gd"),preload("res://src/data/bulgasal_behavior_catalog.gd"),preload("res://src/data/izanami_behavior_catalog.gd")]
	var ids := ["zeus","bulgasal","izanami"]
	var before_command: float = battle.command_power
	var before_summons: int = battle.raw_allied_summons
	for index in range(ids.size()):
		var id: String = ids[index]
		var rules: Dictionary = catalogs[index].RULES
		battle.transcendence.configure(id,rules)
		mode.active = false
		check(not battle.debug_unlock_transcendence(),id+": normal account blocks debug unlock")
		mode.active = true
		view.refresh()
		check(not battle._can_attempt_summon(id,true) and view.button.disabled and not view.ready_light.visible,id+": starts locked")
		check(battle._spawn_monster(id,Vector2.ZERO,0.0,false,{"transcendence_summon":true}) == null,id+": direct spawn blocked before requirements")
		for condition in rules.conditions:
			record_metric(battle.transcendence,condition.metric,int(condition.amount)-1)
		check(not battle.transcendence.ready and not battle._can_attempt_summon(id,true),id+": threshold-minus-one stays locked")
		for condition in rules.conditions: record_metric(battle.transcendence,condition.metric,1)
		view.refresh()
		check(battle.transcendence.ready and not battle.transcendence.test_unlock_confirmed,id+": natural conditions independent of click")
		check(battle._can_attempt_summon(id,true) and not view.button.disabled and view.ready_light.visible,id+": natural unlock enables summon and cue")
		check(view.unlock_button.disabled and view.unlock_button.text == "해제 완료",id+": natural unlock reflected in test button")
		battle.transcendence.consume()
		view.refresh()
		check(not battle._can_attempt_summon(id,true) and not view.visible and not battle.debug_unlock_transcendence(),id+": one summon per battle")
		battle.transcendence.configure(id,rules)
		view.refresh()
		check(not battle.transcendence.ready and not battle.transcendence.test_unlock_confirmed,id+": fresh run resets both paths")
		view.unlock_button.pressed.emit()
		check(battle.transcendence.ready and battle.transcendence.test_unlock_confirmed and battle._can_attempt_summon(id,true),id+": actual test button bypasses unfinished conditions")
		check(not battle.debug_unlock_transcendence(),id+": duplicate test unlock rejected")
		battle.external_pause = true
		check(not battle._can_attempt_summon(id,true),id+": menu blocks summon")
		battle.external_pause = false
		battle.demon_augment_selection_active = true
		check(not battle._can_attempt_summon(id,true),id+": augment choice blocks summon")
		battle.demon_augment_selection_active = false
		battle.battle_over = true
		check(not battle._can_attempt_summon(id,true),id+": battle end blocks summon")
		battle.battle_over = false
	check(battle.command_power == before_command and battle.raw_allied_summons == before_summons,"debug counters never change real resources/spawn snapshots")
	mode.active = false
	check(battle._can_attempt_summon("izanami",true),"normal account natural readiness still works")
	host.free()
	battle.free()
	print("LOCAL_TEST_TRANSCENDENCE_UNLOCK ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
