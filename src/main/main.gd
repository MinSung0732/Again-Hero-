extends Control

const FLOATING_TEXT := preload("res://src/ui/damage_number_spawner.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const TEAM_LOADOUT_STORE := preload("res://src/systems/team_loadout_store.gd")
const DEMON_ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")

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

@onready var monster_info_bookmark: Button = $HUD/MonsterInfoBookmark
@onready var monster_info_panel: PanelContainer = $HUD/MonsterInfoPanel
@onready var monster_info_close: Button = $HUD/MonsterInfoPanel/Margin/VBox/Header/Close
@onready var monster_info_tabs: Array[Button] = [
	$HUD/MonsterInfoPanel/Margin/VBox/Tabs/Tab1,
	$HUD/MonsterInfoPanel/Margin/VBox/Tabs/Tab2,
	$HUD/MonsterInfoPanel/Margin/VBox/Tabs/Tab3,
]
@onready var monster_info_portrait: TextureRect = $HUD/MonsterInfoPanel/Margin/VBox/Portrait
@onready var monster_info_name: Label = $HUD/MonsterInfoPanel/Margin/VBox/Name
@onready var monster_info_stats: Label = $HUD/MonsterInfoPanel/Margin/VBox/Stats
@onready var monster_info_normal: Label = $HUD/MonsterInfoPanel/Margin/VBox/NormalAugments
@onready var monster_info_special: Label = $HUD/MonsterInfoPanel/Margin/VBox/SpecialAugments

@onready var build_label: Label = $HUD/BottomBar/BuildLabel
@onready var status_label: Label = $HUD/BottomBar/Status
@onready var placement_toggle: CheckButton = $HUD/BottomBar/PlacementModeToggle
@onready var demon_progress_label: Label = $HUD/BottomBar/DemonProgressLabel
@onready var demon_exp_bar: ProgressBar = $HUD/BottomBar/DemonExpBar
@onready var command_label: Label = $HUD/BottomBar/CommandLabel
@onready var command_bar: ProgressBar = $HUD/BottomBar/CommandBar
@onready var demon_ultimate_label: Label = $HUD/DemonUltimatePanel/UltimateLabel
@onready var demon_ultimate_bar: ProgressBar = $HUD/DemonUltimatePanel/UltimateBar
@onready var demon_ultimate_1: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate1
@onready var demon_ultimate_2: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate2
@onready var demon_ultimate_3: Button = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate3
@onready var demon_ultimate_1_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate1/CooldownBar
@onready var demon_ultimate_2_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate2/CooldownBar
@onready var demon_ultimate_3_cooldown: ProgressBar = $HUD/DemonUltimatePanel/UltimateButtons/Ultimate3/CooldownBar
@onready var demon_direction_buttons: HBoxContainer = $HUD/DemonUltimatePanel/DirectionButtons
@onready var demon_direction_east: Button = $HUD/DemonUltimatePanel/DirectionButtons/East
@onready var demon_direction_west: Button = $HUD/DemonUltimatePanel/DirectionButtons/West
@onready var demon_direction_north: Button = $HUD/DemonUltimatePanel/DirectionButtons/North
@onready var demon_direction_south: Button = $HUD/DemonUltimatePanel/DirectionButtons/South
@onready var demon_direction_cancel: Button = $HUD/DemonUltimatePanel/DirectionButtons/Cancel
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

@onready var mutation_panel: PanelContainer = $HUD/MutationPanel
@onready var mutation_title: Label = $HUD/MutationPanel/Margin/VBox/Title
@onready var mutation_trigger: Label = $HUD/MutationPanel/Margin/VBox/Trigger
@onready var mutation_choice_0: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice0
@onready var mutation_choice_1: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice1
@onready var mutation_choice_2: Button = $HUD/MutationPanel/Margin/VBox/Choices/Choice2

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
var current_mutation_candidates: Array = []
var debug_refresh_timer: float = 0.0
var battle_loadout_ids: Array = []
var summon_slot_buttons: Array = []
var demon_ultimate_charge_ready: bool = false
var demon_ultimate_cooldowns: Dictionary = {}
var monster_info_selected_index: int = 0
var monster_info_animating: bool = false

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
	battle.demon_ultimate_changed.connect(_on_demon_ultimate_changed)
	battle.demon_ultimate_cooldowns_changed.connect(
		_on_demon_ultimate_cooldowns_changed
	)
	battle.demon_ultimate_used.connect(_on_demon_ultimate_used)
	battle.stage_event_triggered.connect(_on_stage_event_triggered)
	battle.mutation_choice_ready.connect(_on_mutation_choice_ready)
	battle.mutation_selected.connect(_on_mutation_selected)
	battle.mutation_spawn_result.connect(_on_mutation_spawn_result)
	battle.run_time_changed.connect(_on_run_time_changed)
	battle.battle_finished.connect(_on_battle_finished)

	stage_menu_button.pressed.connect(_on_stage_menu_pressed)
	monster_info_bookmark.pressed.connect(_toggle_monster_info)
	monster_info_close.pressed.connect(_close_monster_info)
	for tab_index in range(monster_info_tabs.size()):
		monster_info_tabs[tab_index].pressed.connect(
			_on_monster_info_tab_pressed.bind(tab_index)
		)
	pause_resume_button.pressed.connect(_close_pause_menu)
	pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	pause_lobby_button.pressed.connect(_on_lobby_pressed)

	placement_toggle.toggled.connect(_on_placement_mode_toggled)

	summon_slot_buttons = [
		slime_button,
		spider_button,
		orc_button,
	]
	_load_battle_loadout()
	_configure_battle_loadout_buttons()
	demon_choice_0.pressed.connect(_on_demon_choice_pressed.bind(0))
	demon_choice_1.pressed.connect(_on_demon_choice_pressed.bind(1))
	demon_choice_2.pressed.connect(_on_demon_choice_pressed.bind(2))
	demon_reroll_button.pressed.connect(_on_demon_reroll_pressed)
	mutation_choice_0.pressed.connect(_on_mutation_choice_pressed.bind(0))
	mutation_choice_1.pressed.connect(_on_mutation_choice_pressed.bind(1))
	mutation_choice_2.pressed.connect(_on_mutation_choice_pressed.bind(2))
	demon_ultimate_1.pressed.connect(
		_on_demon_ultimate_pressed.bind("encirclement")
	)
	demon_ultimate_2.pressed.connect(
		_on_demon_ultimate_pressed.bind("line_assault")
	)
	demon_ultimate_3.pressed.connect(
		_on_demon_ultimate_pressed.bind("square_siege")
	)
	demon_direction_east.pressed.connect(
		_on_demon_line_direction_pressed.bind("east")
	)
	demon_direction_west.pressed.connect(
		_on_demon_line_direction_pressed.bind("west")
	)
	demon_direction_north.pressed.connect(
		_on_demon_line_direction_pressed.bind("north")
	)
	demon_direction_south.pressed.connect(
		_on_demon_line_direction_pressed.bind("south")
	)
	demon_direction_cancel.pressed.connect(_close_demon_direction_select)
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
	_on_demon_ultimate_changed(
		float(snapshot.get("demon_ultimate_charge", 0.0)),
		float(snapshot.get("demon_ultimate_max", 100.0)),
		bool(snapshot.get("demon_ultimate_ready", false))
	)
	_on_demon_ultimate_cooldowns_changed(
		Dictionary(snapshot.get("demon_ultimate_cooldowns", {}))
	)
	_on_demon_ultimate_cooldowns_changed(
		Dictionary(snapshot.get("demon_ultimate_cooldowns", {}))
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
		or mutation_panel.visible
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

	var snapshot: Dictionary = battle.get_snapshot()
	pause_stage_label.text = "Stage %d · %s\n상대: %s" % [
		int(snapshot.get("stage_number", 1)),
		String(snapshot.get("stage_name", "스테이지")),
		String(snapshot.get("hero_name", "용사")),
	]
	pause_time_label.text = "남은 시간 %s" % _format_run_time(
		float(snapshot.get("run_remaining_seconds", 0.0))
	)

	battle.set_external_pause(true)
	pause_menu.show()

func _close_pause_menu() -> void:
	if not pause_menu.visible:
		return

	pause_menu.hide()
	if not result_panel.visible:
		battle.set_external_pause(false)

func _on_pause_restart_pressed() -> void:
	pause_menu.hide()
	get_tree().reload_current_scene()

func _on_stage_event_triggered(
	event_type: String,
	event_name: String,
	message: String
) -> void:
	status_label.text = message
	if event_type == "boss":
		run_timer_label.text = "BOSS · %s" % event_name

func _on_mutation_choice_ready(
	event_data: Dictionary,
	candidates: Array
) -> void:
	current_mutation_candidates = candidates.duplicate()
	mutation_panel.show()
	for button in summon_slot_buttons:
		if button is Button:
			button.disabled = true

	mutation_title.text = String(
		event_data.get("ui_title", "돌연변이 선택")
	)
	mutation_trigger.text = String(
		event_data.get(
			"ui_description",
			"편성 몬스터 1종을 돌연변이로 투입합니다."
		)
	)

	var buttons: Array[Button] = [
		mutation_choice_0,
		mutation_choice_1,
		mutation_choice_2,
	]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index >= current_mutation_candidates.size():
			button.hide()
			continue

		button.show()
		var monster_id := String(current_mutation_candidates[index])
		button.text = "%s\n선택" % _get_catalog_monster_name(monster_id)

	status_label.text = "Stage 이벤트: 돌연변이로 투입할 편성 몬스터를 선택하세요."

func _on_mutation_choice_pressed(index: int) -> void:
	if index < 0 or index >= current_mutation_candidates.size():
		return

	var monster_id := String(current_mutation_candidates[index])
	mutation_panel.hide()
	current_mutation_candidates.clear()

	var snapshot: Dictionary = battle.get_snapshot()
	_on_command_changed(
		float(snapshot.get("command_power", 0.0)),
		float(snapshot.get("command_max", 100.0))
	)

	battle.spawn_selected_mutation(monster_id)

func _on_mutation_spawn_result(
	success: bool,
	message: String
) -> void:
	if not success:
		status_label.text = message
		return
	status_label.text = message

func _on_mutation_selected(
	event_type: String,
	mutation_name: String
) -> void:
	if event_type == "miniboss":
		status_label.text = "%s 출현!" % mutation_name
	else:
		status_label.text = "%s 출현!" % mutation_name

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

	if monster_info_panel.visible:
		_refresh_monster_info_panel()

func _on_command_changed(current_value: float, max_value: float) -> void:
	command_label.text = "지휘력 %d / %d" % [int(round(current_value)), int(round(max_value))]
	command_bar.max_value = maxf(max_value, 1.0)
	command_bar.value = current_value

	for slot_index in range(summon_slot_buttons.size()):
		var button = summon_slot_buttons[slot_index]
		if not (button is Button):
			continue

		if slot_index >= battle_loadout_ids.size():
			button.visible = false
			button.disabled = true
			continue

		var monster_id := String(battle_loadout_ids[slot_index])
		var cost: float = battle.get_monster_cost(monster_id)
		button.visible = true
		button.text = "%s\n비용 %.1f" % [
			_get_catalog_monster_name(monster_id),
			cost,
		]
		button.disabled = (
			mutation_panel.visible
			or current_value + 0.001 < cost
		)

func _load_battle_loadout() -> void:
	var valid_ids: Array = []
	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			valid_ids.append(monster_id)

	var fallback_ids: Array = []
	for monster_id in valid_ids:
		fallback_ids.append(monster_id)
		if fallback_ids.size() >= TEAM_LOADOUT_STORE.MAX_SLOTS:
			break

	battle_loadout_ids = TEAM_LOADOUT_STORE.load_ids(
		valid_ids,
		fallback_ids
	)

	if battle.has_method("set_allowed_monster_ids"):
		battle.call("set_allowed_monster_ids", battle_loadout_ids)

func _configure_battle_loadout_buttons() -> void:
	for slot_index in range(summon_slot_buttons.size()):
		var button = summon_slot_buttons[slot_index]
		if not (button is Button):
			continue

		if slot_index >= battle_loadout_ids.size():
			button.visible = false
			button.disabled = true
			continue

		button.visible = true
		button.pressed.connect(
			_on_summon_slot_pressed.bind(slot_index)
		)

func _toggle_monster_info() -> void:
	if monster_info_panel.visible:
		_close_monster_info()
	else:
		_open_monster_info()

func _open_monster_info() -> void:
	if monster_info_animating:
		return
	if battle_loadout_ids.is_empty():
		return

	monster_info_selected_index = clampi(
		monster_info_selected_index,
		0,
		battle_loadout_ids.size() - 1
	)
	_refresh_monster_info_panel()
	monster_info_bookmark.hide()
	monster_info_panel.show()

	var target_position := monster_info_panel.position
	monster_info_panel.position = target_position + Vector2(500.0, 0.0)
	monster_info_animating = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		monster_info_panel,
		"position",
		target_position,
		0.22
	)
	tween.finished.connect(
		func() -> void:
			monster_info_animating = false
	)

func _close_monster_info() -> void:
	if not monster_info_panel.visible or monster_info_animating:
		return

	monster_info_animating = true
	var target_position := monster_info_panel.position + Vector2(500.0, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		monster_info_panel,
		"position",
		target_position,
		0.18
	)
	tween.finished.connect(
		func() -> void:
			monster_info_panel.hide()
			monster_info_panel.position -= Vector2(500.0, 0.0)
			monster_info_bookmark.show()
			monster_info_animating = false
	)

func _on_monster_info_tab_pressed(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= battle_loadout_ids.size():
		return
	monster_info_selected_index = tab_index
	_refresh_monster_info_panel()

func _refresh_monster_info_panel() -> void:
	for index in range(monster_info_tabs.size()):
		var tab := monster_info_tabs[index]
		if index >= battle_loadout_ids.size():
			tab.hide()
			continue

		tab.show()
		var tab_monster_id := String(battle_loadout_ids[index])
		tab.text = _get_catalog_monster_name(tab_monster_id)
		tab.disabled = index == monster_info_selected_index

	if (
		monster_info_selected_index < 0
		or monster_info_selected_index >= battle_loadout_ids.size()
	):
		return

	var monster_id := String(
		battle_loadout_ids[monster_info_selected_index]
	)
	var detail := _build_monster_info_direct(monster_id)

	monster_info_name.text = String(
		detail.get("name", _get_catalog_monster_name(monster_id))
	)
	monster_info_portrait.texture = _load_monster_info_icon(monster_id)

	var stat_lines: PackedStringArray = []
	stat_lines.append(
		"현재 스탯 · 마왕 Lv.%d"
		% int(detail.get("demon_level", 1))
	)
	stat_lines.append(
		"생산비용  %.1f" % float(detail.get("cost", 0.0))
	)
	stat_lines.append(
		"마왕 EXP  %.1f" % float(detail.get("summon_exp", 0.0))
	)

	if detail.has("max_hp"):
		stat_lines.append("최대 HP  %d" % int(detail["max_hp"]))
	if detail.has("attack_damage"):
		stat_lines.append("공격력  %d" % int(detail["attack_damage"]))
	if detail.has("explosion_damage"):
		stat_lines.append("자폭 피해  %d" % int(detail["explosion_damage"]))
	if detail.has("move_speed"):
		stat_lines.append("이동속도  %.0f" % float(detail["move_speed"]))
	if detail.has("attack_cooldown"):
		stat_lines.append(
			"공격 간격  %.2f초" % float(detail["attack_cooldown"])
		)
	if detail.has("self_destruct_fuse"):
		stat_lines.append(
			"자폭 준비  %.2f초" % float(detail["self_destruct_fuse"])
		)
	if detail.has("explosion_radius"):
		stat_lines.append(
			"폭발 반경  %.0f" % float(detail["explosion_radius"])
		)

	monster_info_stats.text = "\n".join(stat_lines)

	var normal_lines: PackedStringArray = []
	for raw_entry in detail.get("normal_augments", []):
		var entry: Dictionary = raw_entry
		var augment_name := String(entry.get("name", "일반증강"))
		var prefix := "%s " % _get_catalog_monster_name(monster_id)
		if augment_name.begins_with(prefix):
			augment_name = augment_name.trim_prefix(prefix)
		normal_lines.append(
			"%s Lv.%d" % [
				augment_name,
				int(entry.get("level", 0)),
			]
		)
	monster_info_normal.text = (
		"아직 획득한 몬스터 일반증강 없음"
		if normal_lines.is_empty()
		else "\n".join(normal_lines)
	)

	var special_lines: PackedStringArray = []
	for raw_entry in detail.get("special_augments", []):
		var entry: Dictionary = raw_entry
		special_lines.append(
			"★ %s" % String(entry.get("name", "특수증강"))
		)
	monster_info_special.text = (
		"아직 획득한 특수증강 없음"
		if special_lines.is_empty()
		else "\n".join(special_lines)
	)

func _build_monster_info_direct(monster_id: String) -> Dictionary:
	var catalog_entry = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(catalog_entry) != TYPE_DICTIONARY:
		return {
			"name": _get_catalog_monster_name(monster_id),
			"cost": 0.0,
			"summon_exp": 0.0,
			"demon_level": 1,
			"normal_augments": [],
			"special_augments": [],
		}

	var base_stats = catalog_entry.get("base_stats", {})
	if typeof(base_stats) != TYPE_DICTIONARY:
		base_stats = {}

	var detail := {
		"name": String(catalog_entry.get("name", monster_id)),
		"cost": float(catalog_entry.get("base_cost", 0.0)),
		"summon_exp": float(catalog_entry.get("summon_exp", 0.0)),
		"demon_level": 1,
		"normal_augments": [],
		"special_augments": [],
	}

	var global_hp := 1.0
	var global_damage := 1.0
	var global_speed := 1.0
	var global_attack_speed := 1.0
	var level_hp := 1.0
	var level_damage := 1.0
	var level_speed := 1.0

	if is_instance_valid(battle):
		detail["demon_level"] = int(battle.get("demon_level"))
		detail["cost"] = battle.get_monster_cost(monster_id)

		var value = battle.get("monster_hp_multiplier")
		if value != null:
			global_hp = float(value)

		value = battle.get("monster_damage_multiplier")
		if value != null:
			global_damage = float(value)

		value = battle.get("monster_speed_multiplier")
		if value != null:
			global_speed = float(value)

		value = battle.get("monster_attack_speed_multiplier")
		if value != null:
			global_attack_speed = float(value)

		if battle.has_method("_get_demon_level_monster_hp_multiplier"):
			level_hp = float(
				battle.call("_get_demon_level_monster_hp_multiplier")
			)
		if battle.has_method(
			"_get_demon_level_monster_damage_multiplier"
		):
			level_damage = float(
				battle.call(
					"_get_demon_level_monster_damage_multiplier"
				)
			)
		if battle.has_method(
			"_get_demon_level_monster_speed_multiplier"
		):
			level_speed = float(
				battle.call(
					"_get_demon_level_monster_speed_multiplier"
				)
			)

	var hp_aug := _get_battle_monster_multiplier(monster_id, "hp")
	var damage_aug := _get_battle_monster_multiplier(
		monster_id,
		"damage"
	)
	var speed_aug := _get_battle_monster_multiplier(monster_id, "speed")
	var cooldown_aug := _get_battle_monster_multiplier(
		monster_id,
		"attack_cooldown"
	)

	if base_stats.has("max_hp"):
		detail["max_hp"] = maxi(
			1,
			int(round(
				float(base_stats["max_hp"])
				* global_hp
				* hp_aug
				* level_hp
			))
		)

	if base_stats.has("attack_damage"):
		detail["attack_damage"] = maxi(
			1,
			int(round(
				float(base_stats["attack_damage"])
				* global_damage
				* damage_aug
				* level_damage
			))
		)

	if base_stats.has("move_speed"):
		detail["move_speed"] = (
			float(base_stats["move_speed"])
			* global_speed
			* speed_aug
			* level_speed
		)

	if base_stats.has("attack_cooldown"):
		detail["attack_cooldown"] = maxf(
			0.10,
			float(base_stats["attack_cooldown"])
			* global_attack_speed
			* cooldown_aug
		)

	if base_stats.has("explosion_damage"):
		detail["explosion_damage"] = maxi(
			1,
			int(round(
				float(base_stats["explosion_damage"])
				* global_damage
				* damage_aug
				* level_damage
			))
		)

	if base_stats.has("explosion_radius"):
		detail["explosion_radius"] = float(
			base_stats["explosion_radius"]
		)

	if base_stats.has("self_destruct_fuse"):
		detail["self_destruct_fuse"] = maxf(
			0.10,
			float(base_stats["self_destruct_fuse"])
			* global_attack_speed
		)

	if is_instance_valid(battle):
		var build_counts = battle.get("demon_build_counts")
		if typeof(build_counts) == TYPE_DICTIONARY:
			for raw_augment in DEMON_AUGMENTS.get_monster_normal_augments(
				monster_id,
				String(catalog_entry.get("name", monster_id))
			):
				var augment: Dictionary = raw_augment
				var augment_id := String(augment.get("id", ""))
				var augment_level := int(
					build_counts.get(augment_id, 0)
				)
				if augment_level <= 0:
					continue
				detail["normal_augments"].append({
					"name": String(
						augment.get("name", augment_id)
					),
					"level": augment_level,
				})

		var special_ids = battle.get("demon_special_augments")
		if typeof(special_ids) == TYPE_ARRAY:
			for raw_id in special_ids:
				var augment_id := String(raw_id)
				var augment := DEMON_AUGMENTS.get_augment(augment_id)
				if String(augment.get("monster_id", "")) != monster_id:
					continue
				detail["special_augments"].append({
					"id": augment_id,
					"name": String(
						augment.get("name", augment_id)
					),
				})

	return detail

func _get_battle_monster_multiplier(
	monster_id: String,
	stat_name: String
) -> float:
	if (
		not is_instance_valid(battle)
		or not battle.has_method("_get_monster_augment_multiplier")
	):
		return 1.0

	return float(
		battle.call(
			"_get_monster_augment_multiplier",
			monster_id,
			stat_name
		)
	)

func _load_monster_info_icon(monster_id: String) -> Texture2D:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return null

	var path := String(data.get("card_icon_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null

	var resource = load(path)
	return resource as Texture2D

func _on_summon_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= battle_loadout_ids.size():
		return

	var monster_id := String(battle_loadout_ids[slot_index])
	_on_summon_pressed(monster_id)

func _get_catalog_monster_name(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return monster_id
	return String(data.get("name", monster_id))

func _is_monster_equipped(monster_id: String) -> bool:
	return monster_id in battle_loadout_ids

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
	if mutation_panel.visible:
		status_label.text = "돌연변이 선택 중에는 몬스터를 소환할 수 없습니다."
		return

	if not _is_monster_equipped(monster_type):
		status_label.text = "%s은(는) 현재 팀에 편성되지 않았습니다." % _get_catalog_monster_name(monster_type)
		return

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

func _on_demon_ultimate_changed(
	current_value: float,
	max_value: float,
	ready: bool
) -> void:
	demon_ultimate_charge_ready = ready
	demon_ultimate_label.text = "마왕 필살기  %d / %d" % [
		int(round(current_value)),
		int(round(max_value)),
	]
	demon_ultimate_bar.max_value = maxf(max_value, 1.0)
	demon_ultimate_bar.value = current_value
	_refresh_demon_ultimate_buttons()

func _on_demon_ultimate_cooldowns_changed(cooldowns: Dictionary) -> void:
	demon_ultimate_cooldowns = cooldowns.duplicate(true)
	_refresh_demon_ultimate_buttons()

func _refresh_demon_ultimate_buttons() -> void:
	var ultimate_buttons := {
		"encirclement": demon_ultimate_1,
		"line_assault": demon_ultimate_2,
		"square_siege": demon_ultimate_3,
	}
	var cooldown_bars := {
		"encirclement": demon_ultimate_1_cooldown,
		"line_assault": demon_ultimate_2_cooldown,
		"square_siege": demon_ultimate_3_cooldown,
	}

	for raw_id in DEMON_ULTIMATES.get_ordered_ids():
		var skill_id := String(raw_id)
		var skill := DEMON_ULTIMATES.get_skill(skill_id)
		var button: Button = ultimate_buttons[skill_id]
		var bar: ProgressBar = cooldown_bars[skill_id]
		var cooldown_max := maxf(float(skill.get("cooldown", 0.0)), 0.0)
		var remaining := maxf(
			float(demon_ultimate_cooldowns.get(skill_id, 0.0)),
			0.0
		)
		var implemented := bool(skill.get("implemented", false))

		bar.max_value = maxf(cooldown_max, 0.1)
		bar.value = remaining
		bar.visible = remaining > 0.001

		if not implemented:
			button.disabled = true
			button.text = "%s\n준비중" % String(
				skill.get("name", "필살기")
			)
			continue

		var ready := demon_ultimate_charge_ready and remaining <= 0.001
		button.disabled = not ready

		var button_title := "필살기"
		match skill_id:
			"encirclement":
				button_title = "1 원형 포위"
			"line_assault":
				button_title = "2 일직선 공세"
			"square_siege":
				button_title = "3 사각 포위"

		if remaining > 0.001:
			button.text = "%s\n쿨타임 %.1f초" % [
				button_title,
				remaining,
			]
		elif demon_ultimate_charge_ready:
			if skill_id == "line_assault":
				button.text = "%s\n방향 선택" % button_title
			else:
				button.text = "%s\n발동 가능" % button_title
		else:
			button.text = "%s\n충전 중" % button_title

func _on_demon_ultimate_pressed(skill_id: String) -> void:
	if skill_id == "line_assault":
		var snapshot: Dictionary = battle.get_snapshot()
		if not bool(snapshot.get("demon_ultimate_ready", false)):
			status_label.text = "마왕 필살기 게이지가 아직 준비되지 않았습니다."
			return
		var cooldowns: Dictionary = snapshot.get(
			"demon_ultimate_cooldowns",
			{}
		)
		var remaining := float(cooldowns.get("line_assault", 0.0))
		if remaining > 0.001:
			status_label.text = "일직선 공세 쿨타임 %.1f초" % remaining
			return
		_open_demon_direction_select()
		return

	if battle.try_use_demon_ultimate(skill_id):
		return

	var skill := DEMON_ULTIMATES.get_skill(skill_id)
	if skill.is_empty():
		return
	if not bool(skill.get("implemented", false)):
		status_label.text = "%s은(는) 다음 단계에서 구현합니다." % String(
			skill.get("name", "필살기")
		)
	else:
		status_label.text = "마왕 필살기 게이지가 아직 준비되지 않았습니다."

func _open_demon_direction_select() -> void:
	$HUD/DemonUltimatePanel/UltimateButtons.hide()
	demon_direction_buttons.show()
	demon_ultimate_label.text = "2번 일직선 공세 · 방향 선택"

func _close_demon_direction_select() -> void:
	demon_direction_buttons.hide()
	$HUD/DemonUltimatePanel/UltimateButtons.show()
	var snapshot: Dictionary = battle.get_snapshot()
	_on_demon_ultimate_changed(
		float(snapshot.get("demon_ultimate_charge", 0.0)),
		float(snapshot.get("demon_ultimate_max", 100.0)),
		bool(snapshot.get("demon_ultimate_ready", false))
	)

func _on_demon_line_direction_pressed(direction: String) -> void:
	if battle.try_use_demon_ultimate("line_assault", direction):
		_close_demon_direction_select()
		return

	status_label.text = "일직선 공세를 발동할 수 없습니다."
	_close_demon_direction_select()

func _on_demon_ultimate_used(
	_skill_id: String,
	skill_name: String,
	message: String
) -> void:
	status_label.text = "%s\n게이지를 모두 소모했습니다." % message

func _on_demon_augment_ready(candidates: Array, rerolls_left: int, demon_level: int) -> void:
	current_demon_candidates = candidates.duplicate(true)
	demon_augment_panel.show()

	var is_special := false
	if not current_demon_candidates.is_empty():
		is_special = (
			String(
				current_demon_candidates[0].get("augment_type", "normal")
			)
			== "special"
		)

	if is_special:
		demon_augment_title.text = "마왕의 특수증강"
		demon_augment_trigger.text = (
			"마왕 Lv.%d · 편성 몬스터 특수증강 1개 선택"
			% demon_level
		)
	else:
		demon_augment_title.text = "마왕의 개입"
		demon_augment_trigger.text = (
			"마왕 Lv.%d · 일반증강 1개 선택"
			% demon_level
		)

	var buttons: Array[Button] = [demon_choice_0, demon_choice_1, demon_choice_2]
	for index in range(buttons.size()):
		if index >= current_demon_candidates.size():
			buttons[index].visible = false
			continue

		buttons[index].visible = true
		var candidate: Dictionary = current_demon_candidates[index]
		var candidate_type := String(
			candidate.get("augment_type", "normal")
		)

		if candidate_type == "special":
			var monster_id := String(candidate.get("monster_id", ""))
			buttons[index].add_theme_font_size_override("font_size", 24)
			buttons[index].text = "★ [%s]\n%s\n\n%s" % [
				_get_catalog_monster_name(monster_id),
				_wrap_augment_card_text(
					String(candidate.get("name", "특수증강")),
					11
				),
				_wrap_augment_card_text(
					String(candidate.get("description", "")),
					13
				),
			]
		else:
			var current_stack := int(candidate.get("current_stack", 0))
			var max_stack := int(candidate.get("max_stack", 1))
			var next_stack := mini(current_stack + 1, max_stack)
			buttons[index].add_theme_font_size_override("font_size", 24)
			buttons[index].text = "%s\nLv.%d → Lv.%d / %d\n\n%s" % [
				_wrap_augment_card_text(
					String(candidate.get("name", "증강")),
					12
				),
				current_stack,
				next_stack,
				max_stack,
				_wrap_augment_card_text(
					String(candidate.get("description", "")),
					14
				),
			]

	var reroll_max := int(battle.get_snapshot().get("demon_reroll_max", 3))
	demon_reroll_button.text = "↻ 새로고침 %d / %d" % [rerolls_left, reroll_max]
	demon_reroll_button.disabled = rerolls_left <= 0
	status_label.text = (
		"특수증강 레벨입니다. 편성 몬스터의 전투 방식을 강화하세요."
		if is_special
		else "일반증강 레벨입니다. 마왕 운영 또는 편성 몬스터를 강화하세요."
	)

func _wrap_augment_card_text(
	value: String,
	max_chars_per_line: int
) -> String:
	var max_chars := maxi(max_chars_per_line, 4)
	var words := value.split(" ", false)
	var lines: PackedStringArray = []
	var current_line := ""

	for raw_word in words:
		var word := String(raw_word)
		if word.length() > max_chars:
			if not current_line.is_empty():
				lines.append(current_line)
				current_line = ""
			var start := 0
			while start < word.length():
				lines.append(
					word.substr(start, mini(max_chars, word.length() - start))
				)
				start += max_chars
			continue

		var candidate := word
		if not current_line.is_empty():
			candidate = "%s %s" % [current_line, word]

		if candidate.length() > max_chars:
			if not current_line.is_empty():
				lines.append(current_line)
			current_line = word
		else:
			current_line = candidate

	if not current_line.is_empty():
		lines.append(current_line)

	return "\n".join(lines)

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
	if monster_info_panel.visible:
		_refresh_monster_info_panel()

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
	pause_menu.hide()
	demon_augment_panel.hide()
	mutation_panel.hide()
	slime_button.disabled = true
	spider_button.disabled = true
	orc_button.disabled = true
	demon_ultimate_1.disabled = true
	demon_ultimate_2.disabled = true
	demon_ultimate_3.disabled = true
	demon_direction_buttons.hide()
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
