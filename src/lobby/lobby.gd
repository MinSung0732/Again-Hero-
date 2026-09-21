extends Control

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const TEAM_LOADOUT_STORE := preload("res://src/systems/team_loadout_store.gd")

const BATTLE_SCENE_PATH := "res://src/main/Main.tscn"

@onready var title_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/Title
@onready var resource_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ResourceLabel
@onready var progress_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ProgressLabel

@onready var shop_tab: Control = $SafeArea/Layout/Content/ShopTab
@onready var team_tab: Control = $SafeArea/Layout/Content/TeamTab
@onready var main_tab: Control = $SafeArea/Layout/Content/MainTab
@onready var research_tab: Control = $SafeArea/Layout/Content/ResearchTab
@onready var other_tab: Control = $SafeArea/Layout/Content/OtherTab

@onready var shop_button: Button = $BottomNav/NavMargin/NavButtons/ShopButton
@onready var team_button: Button = $BottomNav/NavMargin/NavButtons/TeamButton
@onready var main_button: Button = $BottomNav/NavMargin/NavButtons/MainButton
@onready var research_button: Button = $BottomNav/NavMargin/NavButtons/ResearchButton
@onready var other_button: Button = $BottomNav/NavMargin/NavButtons/OtherButton

@onready var team_summary_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/Summary
@onready var team_slot_1_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot1/Label
@onready var team_slot_2_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot2/Label
@onready var team_slot_3_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot3/Label
@onready var team_monster_1_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterList/Monster1Button
@onready var team_monster_2_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterList/Monster2Button
@onready var team_monster_3_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterList/Monster3Button
@onready var team_status_label: Label = $SafeArea/Layout/Content/TeamTab/TeamLayout/Status

@onready var prev_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/PrevButton
@onready var next_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/NextButton
@onready var stage_number_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/StageNumber
@onready var stage_name_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/StageName
@onready var portrait_texture: TextureRect = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/PortraitFrame/FrameMargin/PortraitInner/PortraitTexture
@onready var portrait_placeholder: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/PortraitFrame/FrameMargin/PortraitInner/PortraitPlaceholder
@onready var portrait_badge: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/PortraitFrame/FrameMargin/PortraitInner/PortraitBadge
@onready var hero_name_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/HeroName
@onready var stage_description_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/StageDescription
@onready var stage_status_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/StageStatus
@onready var stage_reward_label: Label = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/StageReward
@onready var enter_stage_button: Button = $SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/EnterButton

@onready var research_points_label: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/Points
@onready var research_status_label: Label = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/Status
@onready var research_list: VBoxContainer = $SafeArea/Layout/Content/ResearchTab/ResearchLayout/ResearchScroll/ResearchList

var stage_ids: Array[String] = []
var selected_stage_index: int = 0
var current_tab: String = "main"

var team_monster_ids: Array[String] = []
var team_preview_ids: Array[String] = []

var panel_style := StyleBoxFlat.new()
var header_style := StyleBoxFlat.new()
var stage_card_style := StyleBoxFlat.new()
var portrait_outer_style := StyleBoxFlat.new()
var portrait_inner_style := StyleBoxFlat.new()
var nav_style := StyleBoxFlat.new()
var nav_active_style := StyleBoxFlat.new()
var nav_button_style := StyleBoxFlat.new()
var nav_button_active_style := StyleBoxFlat.new()
var primary_button_style := StyleBoxFlat.new()
var secondary_button_style := StyleBoxFlat.new()

func _ready() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

	_build_styles()
	_apply_styles()
	_connect_navigation()
	_setup_team_preview()

	stage_ids = STAGE_CATALOG.get_ordered_stage_ids()
	if stage_ids.is_empty():
		stage_ids.append("stage_1")

	var saved_stage_id := String(
		STAGE_PROGRESS.load_state().get("current_stage_id", stage_ids[0])
	)
	var saved_index := stage_ids.find(saved_stage_id)
	selected_stage_index = saved_index if saved_index >= 0 else 0

	_switch_tab("main")
	_refresh_header()
	_refresh_stage_card()
	_rebuild_research_list()

func _build_styles() -> void:
	panel_style = _make_style(
		Color("171423"),
		Color("4d405f"),
		3,
		26
	)
	header_style = _make_style(
		Color("130f1c"),
		Color("6d557b"),
		2,
		22
	)
	stage_card_style = _make_style(
		Color("21182a"),
		Color("a57938"),
		5,
		30
	)
	portrait_outer_style = _make_style(
		Color("0e0b14"),
		Color("d4a84e"),
		8,
		26
	)
	portrait_inner_style = _make_style(
		Color("12162a"),
		Color("695227"),
		3,
		18
	)
	nav_style = _make_style(
		Color("100d17"),
		Color("3f334d"),
		2,
		0
	)
	nav_active_style = _make_style(
		Color("191321"),
		Color("765a89"),
		2,
		0
	)
	nav_button_style = _make_style(
		Color("17131f"),
		Color("3a3045"),
		2,
		18
	)
	nav_button_active_style = _make_style(
		Color("35233c"),
		Color("d0a64a"),
		4,
		18
	)
	primary_button_style = _make_style(
		Color("6c3b87"),
		Color("d4af52"),
		4,
		18
	)
	secondary_button_style = _make_style(
		Color("282133"),
		Color("685674"),
		3,
		18
	)

func _make_style(
	background: Color,
	border: Color,
	border_width: int,
	corner_radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 16.0
	style.content_margin_top = 12.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 12.0
	return style

func _apply_styles() -> void:
	$SafeArea/Layout/Header.add_theme_stylebox_override("panel", header_style)
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard.add_theme_stylebox_override("panel", stage_card_style)
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/PortraitFrame.add_theme_stylebox_override("panel", portrait_outer_style)
	$SafeArea/Layout/Content/MainTab/StageLayout/StagePicker/StageCard/CardMargin/CardVBox/PortraitFrame/FrameMargin/PortraitInner.add_theme_stylebox_override("panel", portrait_inner_style)
	$BottomNav.add_theme_stylebox_override("panel", nav_style)

	for button in [prev_stage_button, next_stage_button]:
		button.add_theme_stylebox_override("normal", secondary_button_style)
		button.add_theme_stylebox_override("hover", secondary_button_style)
		button.add_theme_stylebox_override("pressed", secondary_button_style)

	enter_stage_button.add_theme_stylebox_override("normal", primary_button_style)
	enter_stage_button.add_theme_stylebox_override("hover", primary_button_style)
	enter_stage_button.add_theme_stylebox_override("pressed", primary_button_style)

	for panel in [
		$SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot1,
		$SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot2,
		$SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot3,
	]:
		panel.add_theme_stylebox_override("panel", stage_card_style)

func _connect_navigation() -> void:
	shop_button.pressed.connect(_switch_tab.bind("shop"))
	team_button.pressed.connect(_switch_tab.bind("team"))
	main_button.pressed.connect(_switch_tab.bind("main"))
	research_button.pressed.connect(_switch_tab.bind("research"))
	other_button.pressed.connect(_switch_tab.bind("other"))

	prev_stage_button.pressed.connect(_change_stage.bind(-1))
	next_stage_button.pressed.connect(_change_stage.bind(1))
	enter_stage_button.pressed.connect(_enter_selected_stage)

	team_monster_1_button.pressed.connect(_toggle_team_preview_slot.bind(0))
	team_monster_2_button.pressed.connect(_toggle_team_preview_slot.bind(1))
	team_monster_3_button.pressed.connect(_toggle_team_preview_slot.bind(2))

func _switch_tab(tab_id: String) -> void:
	current_tab = tab_id

	shop_tab.visible = tab_id == "shop"
	team_tab.visible = tab_id == "team"
	main_tab.visible = tab_id == "main"
	research_tab.visible = tab_id == "research"
	other_tab.visible = tab_id == "other"

	_refresh_nav_button(shop_button, tab_id == "shop")
	_refresh_nav_button(team_button, tab_id == "team")
	_refresh_nav_button(main_button, tab_id == "main")
	_refresh_nav_button(research_button, tab_id == "research")
	_refresh_nav_button(other_button, tab_id == "other")

	if tab_id == "team":
		_refresh_team_preview()
	elif tab_id == "research":
		_rebuild_research_list()

func _refresh_nav_button(button: Button, selected: bool) -> void:
	var style := nav_button_active_style if selected else nav_button_style
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override(
		"font_color",
		Color("ffe29a") if selected else Color("d8cfdf")
	)

func _setup_team_preview() -> void:
	team_monster_ids = MONSTER_CATALOG.get_ids()
	team_monster_ids.sort_custom(
		func(a: String, b: String) -> bool:
			return MONSTER_CATALOG.get_base_cost(a) < MONSTER_CATALOG.get_base_cost(b)
	)

	var default_ids: Array[String] = []
	for monster_id in team_monster_ids:
		if default_ids.size() >= TEAM_LOADOUT_STORE.MAX_SLOTS:
			break
		default_ids.append(monster_id)

	team_preview_ids = TEAM_LOADOUT_STORE.load_ids(
		team_monster_ids,
		default_ids
	)

	_refresh_team_preview()

func _refresh_team_preview() -> void:
	var slot_labels: Array[Label] = [
		team_slot_1_label,
		team_slot_2_label,
		team_slot_3_label,
	]
	var monster_buttons: Array[Button] = [
		team_monster_1_button,
		team_monster_2_button,
		team_monster_3_button,
	]

	for slot_index in range(slot_labels.size()):
		if slot_index < team_preview_ids.size():
			var monster_id := team_preview_ids[slot_index]
			slot_labels[slot_index].text = "%d\n%s\n%s" % [
				slot_index + 1,
				MONSTER_CATALOG.get_name(monster_id),
				MONSTER_CATALOG.get_role_label(
					MONSTER_CATALOG.get_role(monster_id)
				),
			]
		else:
			slot_labels[slot_index].text = "%d\n빈 슬롯" % (slot_index + 1)

	var selected_names: PackedStringArray = []
	for monster_id in team_preview_ids:
		selected_names.append(MONSTER_CATALOG.get_name(monster_id))

	team_summary_label.text = "저장된 편성 %d / %d · %s" % [
		team_preview_ids.size(),
		TEAM_LOADOUT_STORE.MAX_SLOTS,
		" / ".join(selected_names),
	]

	for index in range(monster_buttons.size()):
		var button := monster_buttons[index]
		if index >= team_monster_ids.size():
			button.visible = false
			continue

		var monster_id := team_monster_ids[index]
		var data := MONSTER_CATALOG.get_monster(monster_id)
		var selected := monster_id in team_preview_ids
		button.visible = true
		button.text = "%s  ·  %s  ·  기본 비용 %.0f\n%s" % [
			String(data.get("name", monster_id)),
			MONSTER_CATALOG.get_role_label(String(data.get("role", ""))),
			float(data.get("base_cost", 0.0)),
			"선택됨 · 탭해서 빼기" if selected else "탭해서 넣기",
		]

		var style := primary_button_style if selected else secondary_button_style
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)

func _toggle_team_preview_slot(button_index: int) -> void:
	if button_index < 0 or button_index >= team_monster_ids.size():
		return

	var monster_id := team_monster_ids[button_index]
	if monster_id in team_preview_ids:
		if team_preview_ids.size() <= 1:
			team_status_label.text = "최소 1종은 편성해야 합니다."
			return
		team_preview_ids.erase(monster_id)
		team_status_label.text = "%s 편성 해제" % MONSTER_CATALOG.get_name(monster_id)
	else:
		if team_preview_ids.size() >= TEAM_LOADOUT_STORE.MAX_SLOTS:
			team_status_label.text = "편성 슬롯은 최대 %d칸입니다." % TEAM_LOADOUT_STORE.MAX_SLOTS
			return
		team_preview_ids.append(monster_id)
		team_status_label.text = "%s 편성 추가" % MONSTER_CATALOG.get_name(monster_id)

	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_preview_ids,
		team_monster_ids
	)
	if saved:
		team_status_label.text += " · 자동 저장 완료"
	else:
		team_status_label.text = "편성 저장에 실패했습니다."

	_refresh_team_preview()

func _refresh_header() -> void:
	var state := STAGE_PROGRESS.load_state()
	var highest := int(state.get("highest_unlocked_stage", 1))
	var research_points := int(state.get("research_points", 0))
	title_label.text = "용사, 또 너야?"
	resource_label.text = "연구 포인트  %d" % research_points
	progress_label.text = "최고 해금  Stage %d" % highest

func _change_stage(direction: int) -> void:
	if stage_ids.is_empty():
		return

	selected_stage_index = clampi(
		selected_stage_index + direction,
		0,
		stage_ids.size() - 1
	)
	_refresh_stage_card()

func _refresh_stage_card() -> void:
	if stage_ids.is_empty():
		return

	selected_stage_index = clampi(
		selected_stage_index,
		0,
		stage_ids.size() - 1
	)

	var stage_id := stage_ids[selected_stage_index]
	var stage := STAGE_CATALOG.get_stage(stage_id)
	var stage_number := int(stage.get("number", selected_stage_index + 1))
	var hero_profile := HERO_PROFILES.get_profile(
		String(stage.get("hero_id", ""))
	)
	var hero_name := String(hero_profile.get("display_name", "정체불명의 용사"))
	var unlocked := STAGE_PROGRESS.is_stage_unlocked(stage_number)
	var cleared := STAGE_PROGRESS.is_stage_cleared(stage_id)
	var reward_claimed := STAGE_PROGRESS.is_reward_claimed(stage_id)
	var reward := int(stage.get("first_clear_reward", 0))
	var duration_seconds := float(stage.get("run_duration_seconds", 0.0))
	var minutes := int(round(duration_seconds / 60.0))

	stage_number_label.text = "STAGE %02d" % stage_number
	stage_name_label.text = String(stage.get("display_name", "미지의 침입자"))
	hero_name_label.text = hero_name
	stage_description_label.text = String(
		stage.get(
			"lobby_description",
			"이 침입자의 전투 패턴을 관찰하고 카운터를 준비하세요."
		)
	)

	var status_parts: PackedStringArray = []
	status_parts.append("클리어 완료" if cleared else ("입장 가능" if unlocked else "잠김"))
	if minutes > 0:
		status_parts.append("제한 %d분" % minutes)
	stage_status_label.text = " · ".join(status_parts)

	if reward_claimed:
		stage_reward_label.text = "최초 클리어 보상 획득 완료"
	else:
		stage_reward_label.text = "최초 클리어  연구 포인트 +%d" % reward

	enter_stage_button.disabled = not unlocked
	enter_stage_button.text = "던전 입장" if unlocked else "스테이지 잠김"

	prev_stage_button.disabled = selected_stage_index <= 0
	next_stage_button.disabled = selected_stage_index >= stage_ids.size() - 1

	portrait_badge.text = "침입자 · %s" % hero_name
	_apply_portrait(String(stage.get("portrait_path", "")), hero_name)

func _apply_portrait(path: String, hero_name: String) -> void:
	var texture := _load_texture(path)
	portrait_texture.texture = texture
	portrait_texture.visible = texture != null
	portrait_placeholder.visible = texture == null
	portrait_placeholder.text = "%s\n\n초상화 준비 중" % hero_name

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null

	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)

	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource

	return null

func _enter_selected_stage() -> void:
	if stage_ids.is_empty():
		return

	var stage_id := stage_ids[selected_stage_index]
	var stage := STAGE_CATALOG.get_stage(stage_id)
	if stage.is_empty():
		return

	var stage_number := int(stage.get("number", 999))
	if not STAGE_PROGRESS.is_stage_unlocked(stage_number):
		return

	STAGE_PROGRESS.set_current_stage(stage_id)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _rebuild_research_list() -> void:
	for child in research_list.get_children():
		child.queue_free()

	var research_points := STAGE_PROGRESS.get_research_points()
	research_points_label.text = "보유 연구 포인트  %d" % research_points

	for research_id in RESEARCH_CATALOG.get_ordered_ids():
		var data := RESEARCH_CATALOG.get_research(research_id)
		if data.is_empty():
			continue

		var level := STAGE_PROGRESS.get_research_level(research_id)
		var max_level := int(data.get("max_level", 0))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 150)
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_stylebox_override("normal", secondary_button_style)
		button.add_theme_stylebox_override("hover", secondary_button_style)
		button.add_theme_stylebox_override("pressed", secondary_button_style)

		if level >= max_level:
			button.disabled = true
			button.text = "%s  Lv.%d / %d\n%s\n연구 완료" % [
				String(data.get("name", research_id)),
				level,
				max_level,
				String(data.get("description", "")),
			]
		else:
			var cost := RESEARCH_CATALOG.get_cost(research_id, level)
			button.disabled = research_points < cost
			button.text = "%s  Lv.%d / %d\n%s\n비용 %d" % [
				String(data.get("name", research_id)),
				level,
				max_level,
				String(data.get("description", "")),
				cost,
			]
			button.pressed.connect(_purchase_research.bind(research_id))

		research_list.add_child(button)

func _purchase_research(research_id: String) -> void:
	var data := RESEARCH_CATALOG.get_research(research_id)
	if data.is_empty():
		return

	var level := STAGE_PROGRESS.get_research_level(research_id)
	var max_level := int(data.get("max_level", 0))
	var cost := RESEARCH_CATALOG.get_cost(research_id, level)
	var result := STAGE_PROGRESS.try_purchase_research(
		research_id,
		cost,
		max_level
	)

	if bool(result.get("success", false)):
		research_status_label.text = "%s Lv.%d 연구 완료" % [
			String(data.get("name", research_id)),
			int(result.get("level", level + 1)),
		]
	else:
		research_status_label.text = "연구 포인트가 부족하거나 이미 완료된 연구입니다."

	_refresh_header()
	_rebuild_research_list()
