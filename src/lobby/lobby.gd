extends Control

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const SHOP_CATALOG := preload("res://src/data/shop_catalog.gd")
const MONSTER_COLLECTION_STORE := preload("res://src/systems/monster_collection_store.gd")
const TEAM_LOADOUT_STORE := preload("res://src/systems/team_loadout_store.gd")

const BATTLE_SCENE_PATH := "res://src/main/Main.tscn"
const TEAM_MAX_SLOTS := 3

@onready var title_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/Title
@onready var resource_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ResourceLabel
@onready var progress_label: Label = $SafeArea/Layout/Header/HeaderMargin/HeaderVBox/ResourceRow/ProgressLabel

@onready var shop_tab: Control = $SafeArea/Layout/Content/ShopTab
@onready var shop_gold_label: Label = $SafeArea/Layout/Content/ShopTab/ShopLayout/Gold
@onready var shop_single_button: Button = $SafeArea/Layout/Content/ShopTab/ShopLayout/BuyRow/SingleButton
@onready var shop_multi_button: Button = $SafeArea/Layout/Content/ShopTab/ShopLayout/BuyRow/MultiButton
@onready var shop_rates_label: Label = $SafeArea/Layout/Content/ShopTab/ShopLayout/Rates
@onready var shop_result_label: Label = $SafeArea/Layout/Content/ShopTab/ShopLayout/ResultPanel/Result
@onready var shop_status_label: Label = $SafeArea/Layout/Content/ShopTab/ShopLayout/Status

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
@onready var team_slot_1_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot1Button
@onready var team_slot_2_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot2Button
@onready var team_slot_3_button: Button = $SafeArea/Layout/Content/TeamTab/TeamLayout/SlotRow/Slot3Button
@onready var team_monster_list: ItemList = $SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterList
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

var monster_collection_state: Dictionary = {}
var team_catalog_ids: Array = []
var team_available_ids: Array = []
var team_selected_ids: Array = []

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

	for button in [team_slot_1_button, team_slot_2_button, team_slot_3_button]:
		button.add_theme_stylebox_override("normal", stage_card_style)
		button.add_theme_stylebox_override("hover", stage_card_style)
		button.add_theme_stylebox_override("pressed", primary_button_style)


func _connect_navigation() -> void:
	shop_button.pressed.connect(_switch_tab.bind("shop"))
	team_button.pressed.connect(_on_team_tab_pressed)
	main_button.pressed.connect(_switch_tab.bind("main"))
	research_button.pressed.connect(_switch_tab.bind("research"))
	other_button.pressed.connect(_switch_tab.bind("other"))

	prev_stage_button.pressed.connect(_change_stage.bind(-1))
	next_stage_button.pressed.connect(_change_stage.bind(1))
	enter_stage_button.pressed.connect(_enter_selected_stage)

	shop_single_button.pressed.connect(_open_monster_boxes.bind(1))
	shop_multi_button.pressed.connect(
		_open_monster_boxes.bind(SHOP_CATALOG.MULTI_DRAW_COUNT)
	)

	team_slot_1_button.pressed.connect(_on_team_slot_pressed.bind(0))
	team_slot_2_button.pressed.connect(_on_team_slot_pressed.bind(1))
	team_slot_3_button.pressed.connect(_on_team_slot_pressed.bind(2))
	team_monster_list.item_selected.connect(_on_team_item_selected)


func _on_team_tab_pressed() -> void:
	current_tab = "team"

	shop_tab.hide()
	team_tab.show()
	main_tab.hide()
	research_tab.hide()
	other_tab.hide()

	# Update this immediately so a device screenshot tells us the handler ran.
	team_summary_label.text = "컬렉션 생성 중…"
	team_status_label.text = "MonsterCatalog 목록을 만드는 중입니다."

	_setup_team_preview()

	_refresh_nav_button(shop_button, false)
	_refresh_nav_button(team_button, true)
	_refresh_nav_button(main_button, false)
	_refresh_nav_button(research_button, false)
	_refresh_nav_button(other_button, false)

func _switch_tab(tab_id: String) -> void:
	current_tab = tab_id

	shop_tab.visible = tab_id == "shop"
	team_tab.visible = tab_id == "team"
	main_tab.visible = tab_id == "main"
	research_tab.visible = tab_id == "research"
	other_tab.visible = tab_id == "other"

	if tab_id == "shop":
		_rebuild_shop_list()
	elif tab_id == "research":
		_rebuild_research_list()

	_refresh_nav_button(shop_button, tab_id == "shop")
	_refresh_nav_button(team_button, tab_id == "team")
	_refresh_nav_button(main_button, tab_id == "main")
	_refresh_nav_button(research_button, tab_id == "research")
	_refresh_nav_button(other_button, tab_id == "other")

func _refresh_nav_button(button: Button, selected: bool) -> void:
	var style := nav_button_active_style if selected else nav_button_style
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override(
		"font_color",
		Color("ffe29a") if selected else Color("d8cfdf")
	)

func _format_shop_number(value: int) -> String:
	var digits := str(maxi(value, 0))
	var result := ""
	var group_count := 0

	for index in range(digits.length() - 1, -1, -1):
		if group_count > 0 and group_count % 3 == 0:
			result = "," + result
		result = digits.substr(index, 1) + result
		group_count += 1

	return result

func _rebuild_shop_list() -> void:
	shop_gold_label.text = "보유 골드  %s" % _format_shop_number(SHOP_CATALOG.TEST_GOLD)
	shop_single_button.text = "상자 1회\n%s 골드" % _format_shop_number(SHOP_CATALOG.SINGLE_DRAW_COST)
	shop_multi_button.text = "상자 10+1회\n%s 골드" % _format_shop_number(SHOP_CATALOG.MULTI_DRAW_COST)

	var rate_lines: PackedStringArray = []
	for raw_rarity in SHOP_CATALOG.RARITY_ORDER:
		var rarity_id := String(raw_rarity)
		var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
		if rarity_data.is_empty():
			continue

		var min_shards := int(rarity_data.get("shard_min", 1))
		var max_shards := int(rarity_data.get("shard_max", min_shards))
		var shard_text := (
			"%d" % min_shards
			if min_shards == max_shards
			else "%d~%d" % [min_shards, max_shards]
		)
		rate_lines.append(
			"%s %.0f%% · 조각 %s" % [
				SHOP_CATALOG.get_rarity_label(rarity_id),
				float(rarity_data.get("weight", 0.0)),
				shard_text,
			]
		)

	shop_rates_label.text = "\n".join(rate_lines)
	shop_status_label.text = (
		"테스트 골드 %s · 구매 시 골드 차감 없음"
		% _format_shop_number(SHOP_CATALOG.TEST_GOLD)
	)

func _open_monster_boxes(draw_count: int) -> void:
	if draw_count <= 0:
		return

	var aggregated: Dictionary = {}
	var rarity_counts: Dictionary = {}
	var unlock_names: PackedStringArray = []

	for _draw_index in range(draw_count):
		var roll := _roll_monster_shard()
		if roll.is_empty():
			continue

		var monster_id := String(roll.get("monster_id", ""))
		var rarity_id := String(roll.get("rarity", ""))
		var shard_amount := int(roll.get("shards", 0))
		if monster_id.is_empty() or shard_amount <= 0:
			continue

		var before_state := MONSTER_COLLECTION_STORE.load_state()
		var was_unlocked := MONSTER_COLLECTION_STORE.is_unlocked(
			monster_id,
			before_state
		)
		var updated_state := MONSTER_COLLECTION_STORE.add_shards(
			monster_id,
			shard_amount
		)
		var is_unlocked := MONSTER_COLLECTION_STORE.is_unlocked(
			monster_id,
			updated_state
		)

		aggregated[monster_id] = (
			int(aggregated.get(monster_id, 0)) + shard_amount
		)
		rarity_counts[rarity_id] = (
			int(rarity_counts.get(rarity_id, 0)) + 1
		)

		if not was_unlocked and is_unlocked:
			unlock_names.append(_team_monster_name(monster_id))

		monster_collection_state = updated_state

	var result_lines: PackedStringArray = []
	result_lines.append(
		"상자 %d회 결과" % draw_count
	)

	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		var total_shards := int(aggregated.get(monster_id, 0))
		if total_shards <= 0:
			continue

		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		var rarity_id := ""
		if typeof(data) == TYPE_DICTIONARY:
			rarity_id = String(data.get("rarity", ""))

		result_lines.append(
			"%s [%s]  +%d 조각" % [
				_team_monster_name(monster_id),
				SHOP_CATALOG.get_rarity_label(rarity_id),
				total_shards,
			]
		)

	if not unlock_names.is_empty():
		result_lines.append(
			"해금: %s" % " / ".join(unlock_names)
		)

	shop_result_label.text = "\n".join(result_lines)
	shop_status_label.text = (
		"골드 차감 없음 · 표시 골드 %s 유지"
		% _format_shop_number(SHOP_CATALOG.TEST_GOLD)
	)
	_refresh_header()

func _roll_monster_shard() -> Dictionary:
	var rarity_id := _roll_shop_rarity()
	if rarity_id.is_empty():
		return {}

	var candidates: Array = []
	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		if typeof(data) != TYPE_DICTIONARY:
			continue
		if String(data.get("rarity", "")) == rarity_id:
			candidates.append(monster_id)

	if candidates.is_empty():
		return {}

	var selected_id := String(
		candidates[randi_range(0, candidates.size() - 1)]
	)
	var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
	var min_shards := maxi(int(rarity_data.get("shard_min", 1)), 1)
	var max_shards := maxi(int(rarity_data.get("shard_max", min_shards)), min_shards)

	return {
		"monster_id": selected_id,
		"rarity": rarity_id,
		"shards": randi_range(min_shards, max_shards),
	}

func _roll_shop_rarity() -> String:
	var total_weight := 0.0
	for raw_rarity in SHOP_CATALOG.RARITY_ORDER:
		var rarity_data := SHOP_CATALOG.get_rarity(String(raw_rarity))
		total_weight += maxf(float(rarity_data.get("weight", 0.0)), 0.0)

	if total_weight <= 0.0:
		return ""

	var roll := randf_range(0.0, total_weight)
	var cumulative := 0.0

	for raw_rarity in SHOP_CATALOG.RARITY_ORDER:
		var rarity_id := String(raw_rarity)
		var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
		cumulative += maxf(float(rarity_data.get("weight", 0.0)), 0.0)
		if roll <= cumulative:
			return rarity_id

	return String(SHOP_CATALOG.RARITY_ORDER.back())

func _setup_team_preview() -> void:
	team_catalog_ids.clear()
	team_available_ids.clear()
	team_selected_ids.clear()
	team_monster_list.clear()

	team_status_label.text = "Catalog 원본 데이터 확인 중"

	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		if not MONSTER_CATALOG.MONSTERS.has(monster_id):
			continue

		team_catalog_ids.append(monster_id)
		team_available_ids.append(monster_id)

		if team_selected_ids.size() < TEAM_MAX_SLOTS:
			team_selected_ids.append(monster_id)

		team_monster_list.add_item(
			_team_collection_card_text(monster_id),
			_team_monster_card_icon(monster_id)
		)

	team_status_label.text = "Catalog %d종 확인" % team_catalog_ids.size()

	if team_catalog_ids.is_empty():
		team_summary_label.text = "등록된 몬스터 없음"
		team_status_label.text = "MonsterCatalog ORDER/MONSTERS에 등록된 몬스터가 없습니다."
		return

	_refresh_team_preview()
	team_status_label.text = "컬렉션 %d종 표시 완료 · 저장 편성 확인 중" % team_catalog_ids.size()
	call_deferred("_restore_saved_team_selection")

func _restore_saved_team_selection() -> void:
	var saved_collection := MONSTER_COLLECTION_STORE.load_state()
	var unlocked_ids := MONSTER_COLLECTION_STORE.get_unlocked_ids(
		saved_collection
	)

	if not unlocked_ids.is_empty():
		monster_collection_state = saved_collection
		team_available_ids.clear()
		for raw_id in unlocked_ids:
			team_available_ids.append(String(raw_id))

	var fallback_ids: Array = []
	for raw_id in team_selected_ids:
		var monster_id := String(raw_id)
		if monster_id not in team_available_ids:
			continue
		fallback_ids.append(monster_id)
		if fallback_ids.size() >= TEAM_MAX_SLOTS:
			break

	if fallback_ids.is_empty():
		for raw_id in team_available_ids:
			fallback_ids.append(String(raw_id))
			if fallback_ids.size() >= TEAM_MAX_SLOTS:
				break

	var saved_ids = TEAM_LOADOUT_STORE.load_ids(
		team_available_ids,
		fallback_ids
	)

	team_selected_ids.clear()
	for raw_id in saved_ids:
		team_selected_ids.append(String(raw_id))

	_refresh_team_preview()
	team_status_label.text = "컬렉션/편성 복원 완료 · 카드를 탭해 변경하세요."

func _refresh_team_preview() -> void:
	_refresh_team_slot(team_slot_1_button, 0)
	_refresh_team_slot(team_slot_2_button, 1)
	_refresh_team_slot(team_slot_3_button, 2)

	var selected_names := ""
	for raw_id in team_selected_ids:
		var monster_id := String(raw_id)
		if not selected_names.is_empty():
			selected_names += " / "
		selected_names += _team_monster_name(monster_id)

	team_summary_label.text = "편성 %d / %d · %s" % [
		team_selected_ids.size(),
		TEAM_MAX_SLOTS,
		selected_names,
	]

	for item_index in range(team_catalog_ids.size()):
		if item_index >= team_monster_list.item_count:
			break

		var monster_id := String(team_catalog_ids[item_index])
		var available := monster_id in team_available_ids
		var selected := monster_id in team_selected_ids

		team_monster_list.set_item_text(
			item_index,
			_team_collection_card_text(monster_id)
		)
		team_monster_list.set_item_icon(
			item_index,
			_team_monster_card_icon(monster_id)
		)
		team_monster_list.set_item_disabled(
			item_index,
			not available
		)

		if not available:
			team_monster_list.set_item_custom_bg_color(
				item_index,
				Color("17141c")
			)
			team_monster_list.set_item_custom_fg_color(
				item_index,
				Color("77717d")
			)
		elif selected:
			team_monster_list.set_item_custom_bg_color(
				item_index,
				Color("3a2845")
			)
			team_monster_list.set_item_custom_fg_color(
				item_index,
				Color("ffe29a")
			)
		else:
			team_monster_list.set_item_custom_bg_color(
				item_index,
				Color("21182a")
			)
			team_monster_list.set_item_custom_fg_color(
				item_index,
				Color("ebe4ef")
			)

func _refresh_team_slot(button: Button, slot_index: int) -> void:
	if slot_index < team_selected_ids.size():
		var monster_id := String(team_selected_ids[slot_index])
		button.text = "%d\n%s\n%s\n\n탭해서 해제" % [
			slot_index + 1,
			_team_monster_name(monster_id),
			_team_monster_role_label(monster_id),
		]
		button.disabled = team_selected_ids.size() <= 1
	else:
		button.text = "%d\n빈 슬롯" % (slot_index + 1)
		button.disabled = true

func _on_team_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= team_selected_ids.size():
		return
	_remove_team_monster(String(team_selected_ids[slot_index]))

func _on_team_item_selected(item_index: int) -> void:
	if item_index < 0 or item_index >= team_catalog_ids.size():
		return

	var monster_id := String(team_catalog_ids[item_index])
	if monster_id in team_selected_ids:
		_remove_team_monster(monster_id)
	else:
		_add_team_monster(monster_id)

	team_monster_list.deselect_all()

func _remove_team_monster(monster_id: String) -> void:
	if monster_id not in team_selected_ids:
		return

	if team_selected_ids.size() <= 1:
		team_status_label.text = "최소 1종은 편성해야 합니다."
		return

	team_selected_ids.erase(monster_id)
	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_selected_ids,
		team_available_ids
	)
	team_status_label.text = (
		"%s 편성 해제 · 저장 완료" % _team_monster_name(monster_id)
		if saved
		else "%s 편성 해제 · 저장 실패" % _team_monster_name(monster_id)
	)
	_refresh_team_preview()

func _add_team_monster(monster_id: String) -> void:
	if monster_id in team_selected_ids:
		return

	if monster_id not in team_available_ids:
		team_status_label.text = "아직 사용할 수 없는 몬스터입니다."
		return

	if team_selected_ids.size() >= TEAM_MAX_SLOTS:
		team_status_label.text = "편성 슬롯은 최대 %d칸입니다." % TEAM_MAX_SLOTS
		return

	team_selected_ids.append(monster_id)
	var saved := TEAM_LOADOUT_STORE.save_ids(
		team_selected_ids,
		team_available_ids
	)
	team_status_label.text = (
		"%s 편성 추가 · 저장 완료" % _team_monster_name(monster_id)
		if saved
		else "%s 편성 추가 · 저장 실패" % _team_monster_name(monster_id)
	)
	_refresh_team_preview()

func _team_collection_card_text(monster_id: String) -> String:
	if monster_id not in team_available_ids:
		var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
		var required := 1
		if typeof(data) == TYPE_DICTIONARY:
			required = maxi(int(data.get("shards_required", 1)), 1)

		var shards := MONSTER_COLLECTION_STORE.get_shards(
			monster_id,
			monster_collection_state
		)
		return "%s\n[잠김]\n조각 %d / %d" % [
			_team_monster_name(monster_id),
			shards,
			required,
		]

	var state_text := (
		"[편성 중] · 탭해서 해제"
		if monster_id in team_selected_ids
		else "탭해서 편성"
	)
	return "%s\n%s · 비용 %.0f\n%s" % [
		_team_monster_name(monster_id),
		_team_monster_role_label(monster_id),
		_team_monster_cost(monster_id),
		state_text,
	]

func _team_monster_card_icon(monster_id: String) -> Texture2D:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return null

	# Optional future field. When monster art is committed, add:
	# "card_icon_path": "res://assets/art/monsters/<id>/<file>.png"
	var icon_path := String(data.get("card_icon_path", ""))
	if icon_path.is_empty():
		return null

	return _load_texture(icon_path)

func _team_monster_name(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return monster_id
	return String(data.get("name", monster_id))

func _team_monster_role_label(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var role_id := String(data.get("role", ""))
	return String(MONSTER_CATALOG.ROLE_LABELS.get(role_id, role_id))

func _team_monster_cost(monster_id: String) -> float:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return 0.0
	return float(data.get("base_cost", 0.0))

func _refresh_header() -> void:
	var state := STAGE_PROGRESS.load_state()
	var highest := int(state.get("highest_unlocked_stage", 1))
	title_label.text = "용사, 또 너야?"
	resource_label.text = "골드  %s" % _format_shop_number(SHOP_CATALOG.TEST_GOLD)
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
