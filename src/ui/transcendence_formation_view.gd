extends RefCounted
const DATA := preload("res://src/data/transcendence_catalog.gd")
const STORE := preload("res://src/systems/transcendence_loadout_store.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var lobby: Control
var layout: VBoxContainer
var tab: Button
var content: VBoxContainer
var registered: VBoxContainer
var grid: GridContainer
var heading: Label
var empty: Label
var descending := true
var collection_state: Dictionary = {}

func panel(parent: Control, gold: bool = false) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = lobby._team_formation_view.panel_style(gold)
	style.set_corner_radius_all(0)
	frame.add_theme_stylebox_override("panel",style)
	parent.add_child(frame)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,16)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)
	return box

func label(parent: Control, text: String, size: int = 24) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func button(parent: Control, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 64
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	lobby._apply_lobby_button_skin(result,false,22)
	lobby._team_formation_view.fit_action(result)
	result.pressed.connect(action)
	return result

func install(host: Control) -> void:
	lobby = host
	layout = host.get_node(host.TEAM_FORMATION_VIEW.PATH)
	tab = button(layout.get_node("ModeTabs"),"초월 등록",host._show_formation_mode.bind("transcendence"))
	content = VBoxContainer.new()
	content.name = "TranscendenceContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",16)
	layout.add_child(content)
	layout.move_child(content,layout.get_node("ModeTabs").get_index()+1)
	# Replace the slot contents inside the shared equipped area, keeping the
	# guide, summary and mode tabs at the same positions in every mode.
	var equipped := layout.get_node("EquippedArea/Margin/Content") as VBoxContainer
	heading = equipped.get_node("EquippedHeading") as Label
	registered = VBoxContainer.new()
	registered.name = "TranscendenceRegistered"
	registered.custom_minimum_size.y = 244.0
	registered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	registered.alignment = BoxContainer.ALIGNMENT_CENTER
	registered.add_theme_constant_override("separation",16)
	equipped.add_child(registered)
	registered.hide()
	var guide := panel(content)
	label(guide,"초월 몬스터는 일반 팀 편성에 등장하지 않습니다.",22)
	label(guide,"전투 중 개체별 조건을 달성하면 오른쪽에서 소환 버튼이 나타납니다.\n전투당 한 번만 소환할 수 있습니다.",22)
	var header := HBoxContainer.new()
	content.add_child(header)
	label(header,"◇  초월 몬스터 목록",26).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(header,"레벨 높은순 ▾",_toggle_sort).name = "LevelSort"
	empty = label(content,"초월 몬스터가 아직 추가되지 않았습니다.\n새 초월 몬스터가 추가되면 이 목록에 표시됩니다.",25)
	var scroll := ScrollContainer.new()
	scroll.name = "TranscendenceScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	content.hide()

func refresh(showing: bool) -> void:
	content.visible = showing
	lobby._apply_lobby_button_skin(tab,showing,22)
	tab.add_theme_stylebox_override("disabled",lobby.PIXEL_PANEL_SKIN.button_style(lobby.primary_button_style))
	tab.add_theme_color_override("font_disabled_color",Color("fff0d2"))
	tab.disabled = showing
	registered.visible = showing
	layout.get_node("EquippedArea/Margin/Content/SlotRow").visible = not showing
	for name in ["ListHeader","UnlockFilters","MonsterScroll","Status"]:
		layout.get_node(name).visible = not showing
	if showing:
		layout.get_node("EmptyCollection").hide()
	else:
		return
	collection_state = COLLECTION.load_state()
	for child in registered.get_children():
		child.free()
	for child in grid.get_children():
		child.free()
	var selected := STORE.load_id()
	heading.text = "◇  등록된 초월 몬스터  %d / 1  ◇" % (0 if selected.is_empty() else 1)
	if selected.is_empty():
		label(registered,"등록된 초월몬스터가 없습니다",28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label(registered,"아래 목록에서 한 종류를 등록하세요.",22).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_build_card(registered,selected,selected,true)
	var state := collection_state
	var ids := DATA.get_ids()
	ids.sort_custom(func(a,b):
		var left := COLLECTION.get_upgrade_level(a,state)
		var right := COLLECTION.get_upgrade_level(b,state)
		return a < b if left == right else (left > right if descending else left < right))
	empty.visible = ids.is_empty()
	for id in ids:
		_build_card(panel(grid,true),String(id),selected,false)

func _build_card(box: VBoxContainer, id: String, selected: String, registered_card: bool) -> void:
	var state := collection_state
	var unlocked := COLLECTION.is_unlocked(id,state)
	var row := HBoxContainer.new()
	box.add_child(row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(110,130)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.texture = lobby._team_monster_card_icon(id)
	row.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	label(details,"초월 · " + lobby.MONSTER_CATALOG.get_monster_name(id),24)
	if not bool(lobby.MONSTER_CATALOG.MONSTERS[id].get("combat_enabled", true)):
		label(details,"Lv.%d · 전투 능력 준비 중" % COLLECTION.get_upgrade_level(id,state),20)
	else:
		label(details,"Lv.%d · 코스트 %.1f" % [COLLECTION.get_upgrade_level(id,state),lobby.MONSTER_CATALOG.get_base_cost(id)],20)
	label(details,"전투 중 1회 소환",20).add_theme_color_override("font_color",Color("f0cb68"))
	label(box,"전투 소환 준비 중" if not bool(lobby.MONSTER_CATALOG.MONSTERS[id].get("combat_enabled", true)) else "해금: " + DATA.describe(id),20)
	if not registered_card:
		label(box,"조각 %d / %d" % [COLLECTION.get_shards(id,state),lobby.MONSTER_CATALOG.get_shards_required(id)],20)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var chosen := id == selected
	var register_button := button(actions,"등록 해제" if chosen else "등록하기",_register.bind("" if chosen else id))
	register_button.disabled = not unlocked or (not chosen and DATA.MONSTERS.get_scene(id) == null)
	button(actions,"상세정보",lobby._open_monster_detail.bind(id))
	if not registered_card:
		button(actions,"강화",_upgrade.bind(id)).disabled = not unlocked
	if not unlocked:
		box.modulate = Color(0.52,0.52,0.52,1)

func _register(id: String) -> void:
	if STORE.save_id(id):
		refresh(true)
	else:
		lobby.team_status_label.text = "초월 등록을 저장하지 못했습니다. 다시 시도해 주세요."
		lobby.team_status_label.show()

func _upgrade(id: String) -> void:
	lobby._upgrade_team_monster(id)
	refresh(true)
	lobby.team_status_label.show()

func _toggle_sort() -> void:
	descending = not descending
	content.get_node("HBoxContainer/LevelSort").text = "레벨 높은순 ▾" if descending else "레벨 낮은순 ▴"
	refresh(true)
