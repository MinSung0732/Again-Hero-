extends Control

const FLOATING_TEXT := preload("res://src/ui/damage_number_spawner.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")

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

@onready var pause_menu: Control = $HUD/PauseMenu
@onready var pause_stage_label: Label = $HUD/PauseMenu/MenuPanel/Margin/VBox/StageLabel
@onready var pause_time_label: Label = $HUD/PauseMenu/MenuPanel/Margin/VBox/TimeLabel
@onready var pause_resume_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/ResumeButton
@onready var pause_restart_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/RestartButton
@onready var pause_lobby_button: Button = $HUD/PauseMenu/MenuPanel/Margin/VBox/LobbyButton

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
var active_monster_ids: Array[String] = []
var current_demon_candidates: Array = []
var debug_refresh_timer: float = 0.0

func _ready() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	stage_menu_button.pressed.connect(_on_stage_menu_pressed)
	pause_resume_button.pressed.connect(_close_pause_menu)
	pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	pause_lobby_button.pressed.connect(_on_lobby_pressed)

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

	placement_toggle.toggled.connect(_on_placement_mode_toggled)
	slime_button.pressed.connect(_on_summon_slot_pressed.bind(0))
	spider_button.pressed.connect(_on_summon_slot_pressed.bind(1))
	orc_button.pressed.connect(_on_summon_slot_pressed.bind(2))
	demon_choice_0.pressed.connect(_on_demon_choice_pressed.bind(0))
	demon_choice_1.pressed.connect(_on_demon_choice_pressed.bind(1))
	demon_choice_2.pressed.connect(_on_demon_choice_pressed.bind(2))
	demon_reroll_button.pressed.connect(_on_demon_reroll_pressed)
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	stage_select_result_button.pressed.connect(_on_lobby_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	var snapshot: Dictionary = battle.get_snapshot()
	_apply_stage_snapshot(snapshot)
	_configure_summon_loadout(snapshot)

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
	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			_close_pause_menu()
		elif not demon_augment_panel.visible and not result_panel.visible:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if (
		result_panel.visible
		or pause_menu.visible
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

	if pause_menu.visible:
		_close_pause_menu()
	else:
		_open_pause_menu()

func _open_pause_menu() -> void:
	if demon_augment_panel.visible or result_panel.visible:
		return

	pause_stage_label.text = subtitle_label.text
	pause_time_label.text = run_timer_label.text
	pause_menu.show()

	if is_instance_valid(battle) and battle.has_method("set_external_pause"):
		battle.set_external_pause(true)

func _close_pause_menu() -> void:
	if not pause_menu.visible:
		return

	pause_menu.hide()
	if (
		not result_panel.visible
		and is_instance_valid(battle)
		and battle.has_method("set_external_pause")
	):
		battle.set_external_pause(false)

func _on_pause_restart_pressed() -> void:
	pause_menu.hide()
	get_tree().reload_current_scene()

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

func _configure_summon_loadout(snapshot: Dictionary) -> void:
	active_monster_ids.clear()
	for raw_id in snapshot.get("active_monster_ids", []):
		var monster_id := String(raw_id)
		if not monster_id.is_empty():
			active_monster_ids.append(monster_id)

	if selected_monster_type not in active_monster_ids:
		selected_monster_type = ""

	_refresh_summon_buttons(
		float(snapshot.get("command_power", 0.0))
	)

func _on_command_changed(current_value: float, max_value: float) -> void:
	command_label.text = "지휘력 %d / %d" % [int(round(current_value)), int(round(max_value))]
	command_bar.max_value = maxf(max_value, 1.0)
	command_bar.value = current_value
	_refresh_summon_buttons(current_value)

func _refresh_summon_buttons(current_value: float) -> void:
	var buttons: Array[Button] = [slime_button, spider_button, orc_button]

	for index in range(buttons.size()):
		var button := buttons[index]
		if index >= active_monster_ids.size():
			button.visible = false
			button.disabled = true
			continue

		var monster_id := active_monster_ids[index]
		var cost := battle.get_monster_cost(monster_id)
		button.visible = true
		button.text = "%s\n비용 %.1f" % [
			MONSTER_CATALOG.get_name(monster_id),
			cost,
		]
		button.disabled = current_value + 0.001 < cost

func _on_summon_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= active_monster_ids.size():
		return
	_on_summon_pressed(active_monster_ids[slot_index])

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
	return MONSTER_CATALOG.get_name(monster_type)

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
	pause_menu.hide()
	demon_augment_panel.hide()
	for button in [slime_button, spider_button, orc_button]:
		button.disabled = true
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
