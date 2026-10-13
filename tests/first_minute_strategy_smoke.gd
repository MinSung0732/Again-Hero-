extends SceneTree
const M := preload("res://src/systems/combat_insight_model.gd")
const RESULT := preload("res://src/ui/battle_result_copy.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void:
	var model := M.new()
	model.reset("stage_1")
	check(model.headline(0).contains("편성 없음"),"empty roster has actionable recovery")
	model.configure_roster(["slime","spider","orc"])
	check(model.headline(0).contains("용사 HP"),"victory goal before first action")
	check(model.hint(0).contains("자동 배치") and not model.hint(0).contains("전장 터치"),"automatic input instructions")
	model.auto_placement = false
	check(model.hint(0).contains("전장 터치"),"manual input instructions")
	model.record_summon("locked_or_invalid")
	check(model.successful_summons == 0,"unavailable monster cannot advance coach")
	model.record_summon("slime")
	check(model.successful_summons == 1 and model.headline(2).contains("성장"),"first success explains enemy growth")
	check(model.hint(12).contains("공세") and model.hint(12).contains("선택"),"observe then change loop")
	model.record_choice("stage-specific skill",15,"실제 전황의 판단 근거",["area"])
	check(model.recommended_id == "orc","actual candidate tags support stage-specific augments")
	check(model.detail_copy().contains("실제 전황"),"actual decision reason preserved")
	check(model.headline(16).contains("stage-specific skill"),"recent actual choice visible")
	model.recommended_cost = 18; model.available_command = 5
	check(model.hint(16).contains("회복 중"),"unaffordable recommendation explains recovery")
	model.available_command = 24
	check(model.hint(16).contains("오크") and model.hint(16).contains("금색"),"equipped card experiment instruction")
	model.record_summon("slime")
	check(not model.switched_after_choice,"same army is not claimed as a switch")
	model.record_summon("orc")
	check(model.switched_after_choice and model.headline(25).contains("공세 변경"),"different actual paid summon advances observation")
	check(not model.headline(25).contains("성공"),"switch does not fabricate counter success")
	model.population_full = true
	check(model.hint(25).contains("인구"),"population blockage is actionable")
	model.population_full = false
	model.sample(0,0,1000,1000); model.sample(10,40,960,1000); model.sample(20,90,910,1000)
	check(model.current_window_damage == 50 and model.previous_window_damage == 40,"actual HP damage windows preserved")
	check(not model.sample(20.2,90,910,1000),"one-second cadence")
	check(model.result_note(false).contains("오크"),"retry retains concrete experiment")
	model.reset("stage_2"); model.configure_roster(["slime"]); model.record_summon("slime")
	model.record_choice("stage mobility",2,"",["mobility"])
	check(model.recommended_id.is_empty(),"never recommends unequipped counter")
	check(not model.hint(11).contains("금색"),"no absent-card highlighting")
	model.reset("stage_1")
	check(model.successful_summons == 0 and model.decision_reason.is_empty() and model.recommended_id.is_empty(),"restart clears guidance")
	var summary := RESULT.format_analysis("직접 소환: 슬라임 2\n전략 전환: 00:20 슬라임→오크\nHero 누적 HP 피해: 90","")
	check(summary.contains("슬라임 2") and summary.contains("슬라임→오크"),"result retains player's actions")
	print("FIRST_MINUTE_STRATEGY_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
