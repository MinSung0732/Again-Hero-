extends RefCounted

var main
var flow
var _advancing := false

func install(host, controller) -> void:
	main = host
	flow = controller
	main.battle.begin_tutorial_practice()
	main.battle.summon_result.connect(on_summon)
	main.battle.mutation_spawn_result.connect(on_elite)
	main.battle.demon_augment_applied.connect(on_augment)
	show_next()

func show_next() -> void:
	if not is_instance_valid(main) or not flow.active():
		return
	_advancing = false
	match flow.step:
		"summon":
			flow.guide("summon", func():
				main._on_placement_mode_toggled(false)
				flow.focus_targets([main.summon_slot_1, main.battle_viewport_container], "하단 첫 몬스터 카드 → 용사와 떨어진 전장을 터치해 소환하세요."))
		"augment", "special":
			main.battle.open_tutorial_augment(flow.step == "special")
			flow.guide(flow.step, focus_augment)
		"elite":
			main.battle.open_tutorial_elite()
			flow.guide("elite", func():
				flow.focus_targets([main.mutation_choice_0, main.mutation_choice_1, main.mutation_choice_2], "원하는 몬스터를 골라 엘리트를 소환하세요."))
		"camera":
			flow.guide("camera", finish_practice)

func focus_augment() -> void:
	flow.focus_targets([main.demon_choice_0, main.demon_choice_1, main.demon_choice_2, main.demon_confirm_button], "증강 카드 선택 → ‘선택한 증강 적용’을 눌러 확정하세요.")

func on_summon(_id: String, success: bool, _message: String) -> void:
	if not success or flow.step != "summon" or _advancing:
		return
	_advancing = true
	main._end_touch_hold()
	main._clear_pending_manual_spawn()
	flow.advance("augment", "몬스터 소환에 성공했어요! 소환으로 마왕 EXP를 얻고, 레벨업하면 군단을 강화하는 증강을 선택해요.", show_next)

func on_augment(_name: String, _summary: String) -> void:
	if _advancing or flow.step not in ["augment", "special"]:
		return
	_advancing = true
	# The normal chooser finishes its pending queue after this signal returns.
	if flow.step == "augment":
		flow.advance("elite", "증강을 잘 선택했어요! 다음은 강력한 엘리트 몬스터를 소환해 볼게요.", show_next)
	else:
		flow.advance("camera", "특수증강까지 잘 선택했어요! 몬스터의 고유 능력을 용사의 빌드에 맞춰 활용해 보세요.", show_next)

func on_elite(success: bool, _message: String) -> void:
	if not success or flow.step != "elite" or _advancing:
		return
	_advancing = true
	flow.advance("special", "엘리트 소환 성공! 이제 편성 몬스터의 고유 능력을 강화하는 특수증강을 골라 볼게요.", show_next)

func finish_practice() -> void:
	flow.coach_completed = true
	flow.advance("shop", "전투의 기본 조작을 모두 익혔어요! 연습 전투를 끝내고 상점에서 첫 군단을 소환해 볼게요.", flow.leave_battle)
