extends Control

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const FLOATING_TEXT := preload("res://src/ui/damage_number_spawner.gd")

@onready var battle_viewport_container: SubViewportContainer = $BattleViewportContainer
@onready var battle_viewport: SubViewport = $BattleViewportContainer/BattleViewport
@onready var battle = $BattleViewportContainer/BattleViewport/Battle

@onready var subtitle_label: Label = $HUD/TopBar/Subtitle
@onready var run_timer_label: Label = $HUD/TopBar/RunTimer
@onready var stage_menu_button: Button = $HUD/TopBar/StageMenuButton
@onready var hero_level_label: Label = $HUD/TopBar/HeroLevel
@onready var hero_hp_label: Label = $HUD/TopBar/HeroHP
@onready var monsters_label: Label = $HUD/TopBar/Monsters
@onready var exp_label: Label = $HUD/TopBar/ExpLabel
@onready var exp_bar: ProgressBar = $HUD/TopBar/ExpBar
@onready var debug_balance_label: Label = $HUD/DebugBalance

@onready var build_label: Label = $HUD/BottomBar/BuildLabel
@onready var status_label: Label = $HUD/BottomBar/Status
@onready var placement_toggle: CheckButton = $HUD/BottomBar/PlacementModeToggle
@onready var demon_progress_label: Label = $HUD/BottomBar/DemonProgressLabel
@onready var demon_exp_bar: ProgressBar = $HUD/BottomBar/DemonExpBar
@onready var command_label: Label = $HUD/BottomBar/CommandLabel
@onready var command_bar: ProgressBar = $HUD/BottomBar/CommandBar
@onready var slime_button: Button = $HUD/BottomBar/SummonButtons/SlimeButton
@onready var spider_button: Button = $HUD/BottomBar/SummonButtons/SpiderButton
@onready var orc_button: Button = $HUD/BottomBar/SummonButtons/OrcButton

@onready var stage_select_panel: PanelContainer = $HUD/StageSelectPanel
@onready var stage_research_label: Label = $HUD/StageSelectPanel/Margin/VBox/ResearchPoints
@onready var research_menu_button: Button = $HUD/StageSelectPanel/Margin/VBox/ResearchButton
@onready var stage_1_button: Button = $HUD/StageSelectPanel/Margin/VBox/Stage1Button
@onready var stage_2_button: Button = $HUD/StageSelectPanel/Margin/VBox/Stage2Button
@onready var stage_close_button: Button = $HUD/StageSelectPanel/Margin/VBox/CloseButton

@onready var research_panel: PanelContainer = $HUD/ResearchPanel
@onready var research_points_label: Label = $HUD/ResearchPanel/Margin/VBox/Points
@onready var research_status_label: Label = $HUD/ResearchPanel/Margin/VBox/Status
@onready var research_close_button: Button = $HUD/ResearchPanel/Margin/VBox/CloseButton
@onready var research_mana_reservoir: Button = $HUD/ResearchPanel/Margin/VBox/ManaReservoir
@onready var research_mana_cycle: Button = $HUD/ResearchPanel/Margin/VBox/ManaCycle
@onready var research_slime_logistics: Button = $HUD/ResearchPanel/Margin/VBox/SlimeLogistics
@onready var research_tactical_notebook: Button = $HUD/ResearchPanel/Margin/VBox/TacticalNotebook
@onready var research_rapid_experiment: Button = $HUD/ResearchPanel/Margin/VBox/RapidExperiment

@onready var demon_augment_panel: PanelContainer = $HUD/DemonAugmentPanel
@onready var demon_augment_title: Label = $HUD/DemonAugmentPanel/Margin/VBox/Title
@onready var demon_augment_trigger: Label = $HUD/DemonAugmentPanel/Margin/VBox/Trigger
@onready var demon_choice_0: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice0
@onready var demon_choice_1: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice1
@onready var demon_choice_2: Button = $HUD/DemonAugmentPanel/Margin/VBox/Choices/Choice2
@onready var demon_reroll_button: Button = $HUD/DemonAugmentPanel/Margin/VBox/RerollButton

@onready var result_panel: PanelContainer = $HUD/ResultPanel
@onready var result_title: Label = $HUD/ResultPanel/Margin/VBox/ResultTitle
@onready var result_message: Label = $HUD/ResultPanel/Margin/VBox/ResultMessage
@onready var result_analysis: Label = $HUD/ResultPanel/Margin/VBox/ResultAnalysis
@onready var next_stage_button: Button = $HUD/ResultPanel/Margin/VBox/NextStageButton
@onready var stage_select_result_button: Button = $HUD/ResultPanel/Margin/VBox/StageSelectResultButton
@onready var restart_button: Button = $HUD/ResultPanel/Margin/VBox/RestartButton

var auto_placement: bool = true
var selected_monster_type: String = ""
var current_demon_candidates: Array = []
var return_to_result_after_stage_menu: bool = false
var debug_refresh_timer: float = 0.0

func _ready() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	battle.stats_changed.connect(_on_stats_changed)
	battle.progression_changed.connect(_on_progression_changed)
	battle.hero_leveled_up.connect(_on_hero_leveled_up)
	battle.hero_augment_selected.connect(_on_hero_augment_selected)
	battle.command_changed.connect(_on_command_changed)
	battle.demon_progression_changed.connect(_on_demon_progression_changed)
	battle.summon_result.connect(_on_summon_result)
	battle.demon_augment_ready.connect(_on_demon_augment_ready)
	battle.demon_augment_applied.connect(_on_demon_augment_applied)
	battle.run_time_changed.connect(_on_run_time_changed)
	battle.battle_finished.connect(_on_battle_finished)

	stage_menu_button.pressed.connect(_on_stage_menu_pressed)
	stage_1_button.pressed.connect(_on_stage_choice_pressed.bind("stage_1"))
	stage_2_button.pressed.connect(_on_stage_choice_pressed.bind("stage_2"))
	research_menu_button.pressed.connect(_on_research_menu_pressed)
	stage_close_button.pressed.connect(_on_stage_menu_close_pressed)

	research_mana_reservoir.pressed.connect(_on_research_purchase_pressed.bind("mana_reservoir"))
	research_mana_cycle.pressed.connect(_on_research_purchase_pressed.bind("mana_cycle"))
	research_slime_logistics.pressed.connect(_on_research_purchase_pressed.bind("slime_logistics"))
	research_tactical_notebook.pressed.connect(_on_research_purchase_pressed.bind("tactical_notebook"))
	research_rapid_experiment.pressed.connect(_on_research_purchase_pressed.bind("rapid_experiment"))
	research_close_button.pressed.connect(_on_research_close_pressed)

	placement_toggle.toggled.connect(_on_placement_mode_toggled)
	slime_button.pressed.connect(_on_summon_pressed.bind("slime"))
	spider_button.pressed.connect(_on_summon_pressed.bind("spider"))
	orc_button.pressed.connect(_on_summon_pressed.bind("orc"))
	demon_choice_0.pressed.connect(_on_demon_choice_pressed.bind(0))
	demon_choice_1.pressed.connect(_on_demon_choice_pressed.bind(1))
	demon_choice_2.pressed.connect(_on_demon_choice_pressed.bind(2))
	demon_reroll_button.pressed.connect(_on_demon_reroll_pressed)
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	stage_select_result_button.pressed.connect(_on_lobby_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	var snapshot: Dictionary = battle.get_snapshot()
	_apply_stage_snapshot(snapshot)

	_on_stats_changed(
		int(snapshot.get("hero_hp", 0)),
		int(snapshot.get("hero_max_hp", 0)),
		int(snapshot.get("monsters_left", 0))
	)
	_on_progression_changed(
		int(snapshot.get("hero_level", 1)),
		int(snapshot.get("hero_exp", 0)),
		int(snapshot.get("hero_exp_to_next", 50))
	)
	_on_command_changed(
		float(snapshot.get("command_power", 0.0)),
		float(snapshot.get("command_max", 100.0))
	)
	_on_demon_progression_changed(
		int(snapshot.get("demon_level", 1)),
		float(snapshot.get("demon_exp", 0.0)),
		float(snapshot.get("demon_exp_to_next", 30.0))
	)
	_on_run_time_changed(
		float(snapshot.get("run_elapsed_seconds", 0.0)),
		float(snapshot.get("run_remaining_seconds", 0.0))
	)

	build_label.text = "용사 빌드: %s" % String(snapshot.get("hero_build_summary", "아직 선택 없음"))
	debug_balance_label.text = String(snapshot.get("debug_balance_summary", "[DEBUG]"))
	placement_toggle.button_pressed = true
	_on_placement_mode_toggled(true)

	print("Again, Hero? stage/camera prototype loaded.")
	print("Finite world camera + persistent stage progression enabled.")

func _process(delta: float) -> void:
	debug_refresh_timer -= delta
	if debug_refresh_timer > 0.0:
		return

	debug_refresh_timer = 0.25
	if is_instance_valid(battle) and battle.has_method("get_debug_balance_summary"):
		debug_balance_label.text = String(battle.call("get_debug_balance_summary"))

func _apply_stage_snapshot(snapshot: Dictionary) -> void:
	subtitle_label.text = "Stage %d · %s · %s" % [
		int(snapshot.get("stage_number", 1)),
		String(snapshot.get("stage_name", "첫 번째 침입자")),
		String(snapshot.get("hero_name", "견습 마도사")),
	]

func _input(event: InputEvent) -> void:
	if (
		result_panel.visible
		or stage_select_panel.visible
		or research_panel.visible
		or demon_augment_panel.visible
		or auto_placement
		or selected_monster_type.is_empty()
	):
		return

	var pointer_position := Vector2.ZERO
	var is_pressed := false

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		is_pressed = touch_event.pressed
		pointer_position = touch_event.position
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		is_pressed = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
		pointer_position = mouse_event.position

	if not is_pressed:
		return

	var viewport_rect: Rect2 = battle_viewport_container.get_global_rect()
	if not viewport_rect.has_point(pointer_position):
		return

	var local_pointer := pointer_position - viewport_rect.position
	var viewport_size := Vector2(battle_viewport.size)
	var scale_factor := Vector2(
		viewport_size.x / maxf(viewport_rect.size.x, 1.0),
		viewport_size.y / maxf(viewport_rect.size.y, 1.0)
	)
	var subviewport_pointer := local_pointer * scale_factor
	var canvas_inverse := battle_viewport.get_canvas_transform().affine_inverse()
	var world_position: Vector2 = canvas_inverse * subviewport_pointer
	var battle_position: Vector2 = battle.to_local(world_position)
	var placement_error := String(
		battle.get_manual_spawn_error(
			selected_monster_type,
			battle_position
		)
	)

	if not placement_error.is_empty():
		if battle.is_manual_spawn_too_close_to_hero(battle_position):
			battle.show_manual_spawn_restricted_area()

		FLOATING_TEXT.show_text_at(
			battle,
			battle.to_global(battle_position),
			placement_error
		)
		get_viewport().set_input_as_handled()
		return

	battle.try_summon_at_position(selected_monster_type, battle_position)
	get_viewport().set_input_as_handled()

func _on_stage_menu_pressed() -> void:
	if demon_augment_panel.visible or result_panel.visible:
		return
	_open_stage_menu(false)

func _on_result_stage_menu_pressed() -> void:
	_open_stage_menu(true)

func _open_stage_menu(from_result: bool) -> void:
	return_to_result_after_stage_menu = from_result
	_refresh_stage_menu()

	if from_result:
		result_panel.hide()
	else:
		battle.set_external_pause(true)

	stage_select_panel.show()

func _refresh_stage_menu() -> void:
	var progress: Dictionary = STAGE_PROGRESS.load_state()
	var research_points: int = int(progress.get("research_points", 0))
	stage_research_label.text = "연구 포인트 %d" % research_points

	_configure_stage_button(stage_1_button, "stage_1")
	_configure_stage_button(stage_2_button, "stage_2")

func _on_research_menu_pressed() -> void:
	stage_select_panel.hide()
	research_status_label.text = "연구 항목을 선택하세요."
	_refresh_research_menu()
	research_panel.show()

func _refresh_research_menu() -> void:
	var research_points := STAGE_PROGRESS.get_research_points()
	research_points_label.text = "연구 포인트 %d" % research_points

	_configure_research_button(research_mana_reservoir, "mana_reservoir", research_points)
	_configure_research_button(research_mana_cycle, "mana_cycle", research_points)
	_configure_research_button(research_slime_logistics, "slime_logistics", research_points)
	_configure_research_button(research_tactical_notebook, "tactical_notebook", research_points)
	_configure_research_button(research_rapid_experiment, "rapid_experiment", research_points)

func _configure_research_button(
	button: Button,
	research_id: String,
	research_points: int
) -> void:
	var data: Dictionary = RESEARCH_CATALOG.get_research(research_id)
	if data.is_empty():
		button.disabled = true
		button.text = "미구현 연구"
		return

	var level := STAGE_PROGRESS.get_research_level(research_id)
	var max_level := int(data.get("max_level", 0))
	var name := String(data.get("name", research_id))
	var description := String(data.get("description", ""))

	if level >= max_level:
		button.disabled = true
		button.text = "%s · Lv.%d / %d\n%s\n연구 완료" % [
			name,
			level,
			max_level,
			description,
		]
		return

	var cost := RESEARCH_CATALOG.get_cost(research_id, level)
	button.disabled = research_points < cost
	button.text = "%s · Lv.%d / %d\n%s\n비용: 연구 포인트 %d" % [
		name,
		level,
		max_level,
		description,
		cost,
	]

func _on_research_purchase_pressed(research_id: String) -> void:
	var data: Dictionary = RESEARCH_CATALOG.get_research(research_id)
	if data.is_empty():
		return

	var current_level := STAGE_PROGRESS.get_research_level(research_id)
	var max_level := int(data.get("max_level", 0))
	var cost := RESEARCH_CATALOG.get_cost(research_id, current_level)
	if cost < 0:
		return

	var result: Dictionary = STAGE_PROGRESS.try_purchase_research(
		research_id,
		cost,
		max_level
	)

	if bool(result.get("success", false)):
		research_status_label.text = "%s Lv.%d 연구 완료 · 다음 Run부터 적용" % [
			String(data.get("name", research_id)),
			int(result.get("level", current_level + 1)),
		]
	else:
		match String(result.get("reason", "")):
			"not_enough_points":
				research_status_label.text = "연구 포인트가 부족합니다."
			"max_level":
				research_status_label.text = "이미 최대 레벨 연구입니다."
			_:
				research_status_label.text = "연구 구매에 실패했습니다."

	_refresh_research_menu()

func _on_research_close_pressed() -> void:
	research_panel.hide()
	_refresh_stage_menu()
	stage_select_panel.show()

func _configure_stage_button(button: Button, stage_id: String) -> void:
	var stage: Dictionary = STAGE_CATALOG.get_stage(stage_id)
	if stage.is_empty():
		button.disabled = true
		button.text = "미구현 스테이지"
		return

	var stage_number: int = int(stage.get("number", 0))
	var unlocked: bool = STAGE_PROGRESS.is_stage_unlocked(stage_number)
	var cleared: bool = STAGE_PROGRESS.is_stage_cleared(stage_id)
	var reward_claimed: bool = STAGE_PROGRESS.is_reward_claimed(stage_id)
	var reward: int = int(stage.get("first_clear_reward", 0))
	var hero_profile: Dictionary = HERO_PROFILES.get_profile(
		String(stage.get("hero_id", ""))
	)
	var hero_name: String = String(hero_profile.get("display_name", "용사"))

	var status_text := "해금" if unlocked else "잠김"
	if cleared:
		status_text = "클리어 완료"

	var reward_text := "최초 보상: 연구 포인트 +%d" % reward
	if reward_claimed:
		reward_text = "최초 보상 획득 완료"

	button.disabled = not unlocked
	button.text = "Stage %d · %s\n%s · %s\n%s" % [
		stage_number,
		String(stage.get("display_name", "스테이지")),
		hero_name,
		status_text,
		reward_text,
	]

func _on_stage_choice_pressed(stage_id: String) -> void:
	var stage: Dictionary = STAGE_CATALOG.get_stage(stage_id)
	if stage.is_empty():
		return

	if not STAGE_PROGRESS.is_stage_unlocked(int(stage.get("number", 999))):
		return

	STAGE_PROGRESS.set_current_stage(stage_id)
	get_tree().reload_current_scene()

func _on_stage_menu_close_pressed() -> void:
	research_panel.hide()
	stage_select_panel.hide()

	if return_to_result_after_stage_menu:
		result_panel.show()
	else:
		battle.set_external_pause(false)

	return_to_result_after_stage_menu = false

func _on_run_time_changed(_elapsed_seconds: float, remaining_seconds: float) -> void:
	run_timer_label.text = "남은 시간 %s" % _format_run_time(remaining_seconds)

func _format_run_time(seconds: float) -> String:
	var total := maxi(int(ceil(seconds)), 0)
	var minutes := int(total / 60)
	var remaining := total % 60
	return "%02d:%02d" % [minutes, remaining]

func _on_stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int) -> void:
	hero_hp_label.text = "용사 HP %d / %d" % [hero_hp, hero_max_hp]
	monsters_label.text = "몬스터 %d" % monsters_left

func _on_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	hero_level_label.text = "Lv.%d" % level
	exp_label.text = "EXP %d / %d" % [current_exp, exp_to_next_level]
	exp_bar.max_value = maxf(float(exp_to_next_level), 1.0)
	exp_bar.value = float(current_exp)

func _on_demon_progression_changed(level: int, current_exp: float, exp_to_next_level: float) -> void:
	demon_progress_label.text = "마왕 Lv.%d · EXP %.1f / %.1f" % [
		level,
		current_exp,
		exp_to_next_level,
	]
	demon_exp_bar.max_value = maxf(exp_to_next_level, 1.0)
	demon_exp_bar.value = current_exp

func _on_command_changed(current_value: float, max_value: float) -> void:
	command_label.text = "지휘력 %d / %d" % [int(round(current_value)), int(round(max_value))]
	command_bar.max_value = maxf(max_value, 1.0)
	command_bar.value = current_value

	var slime_cost: float = battle.get_monster_cost("slime")
	var spider_cost: float = battle.get_monster_cost("spider")
	var orc_cost: float = battle.get_monster_cost("orc")

	slime_button.text = "슬라임\n비용 %.1f" % slime_cost
	spider_button.text = "거미\n비용 %.1f" % spider_cost
	orc_button.text = "오크\n비용 %.1f" % orc_cost

	slime_button.disabled = current_value + 0.001 < slime_cost
	spider_button.disabled = current_value + 0.001 < spider_cost
	orc_button.disabled = current_value + 0.001 < orc_cost

func _on_placement_mode_toggled(auto_enabled: bool) -> void:
	auto_placement = auto_enabled

	if auto_placement:
		placement_toggle.text = "자동 배치"
		status_label.text = "자동 배치: 용사 주변 바깥쪽에서 몬스터가 소환됩니다."
	else:
		placement_toggle.text = "수동 배치"
		if selected_monster_type.is_empty():
			status_label.text = "수동 배치: 몬스터 버튼을 선택한 뒤 현재 화면의 전장을 터치하세요."
		else:
			status_label.text = "수동 배치: %s 선택됨 · 현재 화면을 터치하세요." % _get_monster_name(selected_monster_type)

func _on_summon_pressed(monster_type: String) -> void:
	if auto_placement:
		battle.try_summon(monster_type)
		return

	selected_monster_type = monster_type
	status_label.text = "수동 배치: %s 선택됨 · 현재 보이는 전장을 터치해 연속 배치하세요." % _get_monster_name(monster_type)

func _on_summon_result(_monster_type: String, success: bool, message: String) -> void:
	if not success:
		status_label.text = message
		return

	if auto_placement:
		status_label.text = "%s\n자동 배치 모드" % message
	else:
		status_label.text = "%s\n%s 선택 유지 · 계속 터치해서 배치 가능" % [
			message,
			_get_monster_name(selected_monster_type),
		]

func _on_demon_augment_ready(candidates: Array, rerolls_left: int, demon_level: int) -> void:
	current_demon_candidates = candidates.duplicate(true)
	demon_augment_panel.show()
	demon_augment_title.text = "마왕의 개입"
	demon_augment_trigger.text = "마왕 Lv.%d 도달 · 증강 1개 선택" % demon_level

	var buttons: Array[Button] = [demon_choice_0, demon_choice_1, demon_choice_2]
	for index in range(buttons.size()):
		if index >= current_demon_candidates.size():
			buttons[index].visible = false
			continue

		buttons[index].visible = true
		var candidate: Dictionary = current_demon_candidates[index]
		var current_stack := int(candidate.get("current_stack", 0))
		var max_stack := int(candidate.get("max_stack", 1))
		var next_stack := mini(current_stack + 1, max_stack)
		buttons[index].text = "%s\n중첩 %d → %d / %d\n\n%s" % [
			String(candidate.get("name", "증강")),
			current_stack,
			next_stack,
			max_stack,
			String(candidate.get("description", "")),
		]

	var reroll_max := int(battle.get_snapshot().get("demon_reroll_max", 3))
	demon_reroll_button.text = "↻ 새로고침 %d / %d" % [rerolls_left, reroll_max]
	demon_reroll_button.disabled = rerolls_left <= 0
	status_label.text = "소환으로 마왕 EXP를 얻어 레벨업했습니다. 새로고침은 Run 전체 %d회 공유." % reroll_max

func _on_demon_choice_pressed(index: int) -> void:
	if index < 0 or index >= current_demon_candidates.size():
		return

	var candidate: Dictionary = current_demon_candidates[index]
	var augment_id: String = String(candidate.get("id", ""))
	if battle.choose_demon_augment(augment_id):
		demon_augment_panel.hide()
		current_demon_candidates.clear()
		_on_command_changed(
			float(battle.get_snapshot().get("command_power", 0.0)),
			float(battle.get_snapshot().get("command_max", 100.0))
		)

func _on_demon_reroll_pressed() -> void:
	battle.reroll_demon_augments()

func _on_demon_augment_applied(augment_name: String, build_summary: String) -> void:
	status_label.text = "마왕 증강 획득 → %s\n현재 마왕 빌드: %s" % [augment_name, build_summary]

func _get_monster_name(monster_type: String) -> String:
	match monster_type:
		"spider":
			return "거미"
		"orc":
			return "오크"
		_:
			return "슬라임"

func _on_hero_leveled_up(new_level: int) -> void:
	status_label.text = "용사 Lv.%d 도달!\nAI가 증강 후보를 평가합니다." % new_level

func _on_hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String) -> void:
	var candidate_names: PackedStringArray = []
	for candidate in candidates:
		candidate_names.append(String(candidate.get("name", "?")))

	build_label.text = "용사 빌드: %s" % build_summary
	status_label.text = "Lv.%d 후보: %s\nAI → %s · %s" % [
		level,
		" / ".join(candidate_names),
		chosen_name,
		reason,
	]

func _on_battle_finished(message: String, player_won: bool) -> void:
	stage_select_panel.hide()
	research_panel.hide()
	demon_augment_panel.hide()
	slime_button.disabled = true
	spider_button.disabled = true
	orc_button.disabled = true
	placement_toggle.disabled = true

	if player_won:
		result_title.text = "STAGE CLEAR"
		status_label.text = "용사를 쓰러뜨렸습니다. 스테이지 클리어!"
		next_stage_button.visible = battle.can_go_to_next_stage()
	else:
		result_title.text = "EXPERIMENT FAILED"
		status_label.text = "이번 실험이 종료되었습니다."
		next_stage_button.visible = false

	result_message.text = message
	result_analysis.text = battle.get_run_analysis_summary()
	result_panel.show()

func _on_next_stage_pressed() -> void:
	if battle.go_to_next_stage():
		get_tree().reload_current_scene()

func _on_lobby_pressed() -> void:
	get_tree().change_scene_to_file("res://src/lobby/Lobby.tscn")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
