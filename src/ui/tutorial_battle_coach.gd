extends RefCounted

var main
var flow
var summoned := false
var camera := false
var elite := false
var augmented := false
var elite_taught := false
var augment_taught := false
var lessons: Array[String] = []

func install(host, controller) -> void:
	main = host
	flow = controller
	main.battle.summon_result.connect(on_summon)
	main.settings_camera_lock.toggled.connect(on_camera)
	main.battle.mutation_choice_ready.connect(on_elite_ready)
	main.battle.mutation_spawn_result.connect(on_elite)
	main.battle.demon_augment_ready.connect(on_augment_ready)
	main.battle.demon_augment_applied.connect(on_augment)
	main.battle.battle_finished.connect(func(_message, _won):
		flow.clear_guide()
		flow.show_modal("튜토리얼 전투 종료", "승패와 관계없이 첫 소환 보상을 받을 수 있습니다.\n로비로 돌아가세요.", "로비로 돌아가기", flow.leave_battle))
	flow.guide("summon", func(): flow.point_to(main.summon_slot_1, "지휘력이 차면 카드 선택 → 전장 터치로 소환하세요."))

func on_summon(_id: String, success: bool, _message: String) -> void:
	if not success or summoned:
		return
	summoned = true
	flow.guide("camera", func():
		flow.point_to(main.stage_menu_button, "메뉴 → 설정 → 게임플레이 → 화면 고정 해제")
		if not main.camera_view_locked:
			camera = true
		show_next())

func on_camera(enabled: bool) -> void:
	if not summoned or enabled or camera:
		return
	camera = true
	flow.clear_guide()
	main._show_battle_toast("화면 고정 해제 완료 · 설정을 닫고 전장을 드래그하세요.", 4)
	show_next()

func on_elite_ready(_event: Dictionary, _candidates: Array) -> void:
	if elite_taught:
		return
	elite_taught = true
	lessons.append("elite")
	show_next()

func on_augment_ready(_candidates: Array, _rerolls: int, _level: int) -> void:
	if augment_taught:
		return
	augment_taught = true
	lessons.append("augment")
	show_next()

func show_next() -> void:
	if flow.modal_visible or main.settings_overlay.visible or main.pause_menu.visible:
		return
	if not lessons.is_empty():
		var id: String = lessons.pop_front()
		flow.guide(id, func():
			flow.clear_guide()
			flow.point_to(main.mutation_choice_0 if id == "elite" else main.demon_choice_0, "몬스터를 선택해 엘리트를 소환하세요." if id == "elite" else "증강 카드 선택 → ‘선택한 증강 적용’"))
	elif summoned and camera and elite and augmented:
		flow.coach_completed = true
		flow.guide("complete", flow.leave_battle)
	elif summoned and not camera:
		flow.point_to(main.stage_menu_button, "메뉴 → 설정 → 게임플레이 → 화면 고정 해제")

func on_elite(success: bool, _message: String) -> void:
	if success:
		elite = true
		flow.clear_guide()
		show_next()

func on_augment(_name: String, _summary: String) -> void:
	augmented = true
	flow.clear_guide()
	show_next()
