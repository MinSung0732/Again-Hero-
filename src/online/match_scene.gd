extends Control
const RULES := preload("res://src/online/match_rules.gd")
const CONFIG := preload("res://src/online/online_config.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const PAD := preload("res://src/hero_mode/hero_move_pad.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
const LOADING := preload("res://src/online/match_loading_view.gd")
const RANKED := preload("res://src/data/ranked_rules.gd")
const RULES_GUIDE := preload("res://src/data/ranked_rules_guide.gd")
const LOADOUT := preload("res://src/online/online_loadout.gd")
const HEROES := preload("res://src/data/hero_character_catalog.gd")
const HERO_STORE := preload("res://src/systems/hero_mode_store.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const TEAM := preload("res://src/systems/team_loadout_store.gd")
const SKILL_STORE := preload("res://src/systems/demon_skill_loadout_store.gd")
const SKILLS := preload("res://src/data/demon_ultimate_catalog.gd")
const TRANSCENDENCE := preload("res://src/systems/transcendence_loadout_store.gd")
const ENTRY := preload("res://src/systems/dungeon_entry_policy.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const TOP_LAYOUT := preload("res://src/ui/castle_battle_chrome.gd")
const RESPONSIVE := preload("res://src/ui/battle_responsive_layout.gd")
const HERO_HUD := preload("res://src/ui/hero_survival_hud.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const PANEL := preload("res://src/ui/illustrated_battle_panel.gd")
var loading
var local_preparing := false
var waiting_for_start := false
var load_revision := 0
const METRICS := preload("res://src/data/online_metrics_catalog.gd")
var metrics_panel: VBoxContainer
var metrics_label: Label
var metrics_left := 0.0
var client
var view
var status: Label
@onready var top_bar: Control = $TopBar
var rows: VBoxContainer
var setup_controls: Array[Control] = []
var top_rects: Array[Rect2] = []
var match_duration := RULES.DURATION
var matched_hero_id := ""
var hud_timer_second := -1
var hud_hp := -1
var hud_max_hp := -1
var hud_monsters := -1
var hud_level := -1
var hud_exp := -1
var hud_exp_next := -1
var hud_mana := -1
var top_menu: PopupMenu
var ranking_row: HBoxContainer
var ranking_icon: TextureRect
var ranking_label: Label
var action_notice: Label
var choices: VBoxContainer
var hold_toggle: Button
var hold_scroll: ScrollContainer
var hold_expanded := false
var hold_signature := ""
var inventory_signature := ""
var hero_build_toggle: Button
var hero_build_scroll: ScrollContainer
var hero_build_panel: VBoxContainer
var hero_build_rows: VBoxContainer
var hero_build_level: Label
var hero_build_augments: Label
var hero_build_signature := ""
var demon_info_toggle: Button
var demon_info_panel: VBoxContainer
var demon_info_hints: Label
var inventory_detail: AcceptDialog
var chest_notice: Label
var chest_queue: Array = []
var chest_last_serial := 0
var chest_seconds := 0.0
var rerolls_left := 0
var reroll_limit := 0
var rules_popup: PopupPanel
var action_row: HBoxContainer
var skill_row: HBoxContainer
var skill_buttons := {}
var summon_ids: Array[String] = []
var summon_buttons: Array[Button] = []
var summon_mana := -1.0
var summon_costs := {}
var summon_cost_signature := ""
var skill_state_signature := ""
var inventory_items := {"weapons":[],"passives":[]}
@onready var demon_panel: Control = $DemonUltimatePanel
@onready var bottom_bar: Control = $BottomBar
var hero_slots: Control
var weapon_buttons: Array[Button] = []
var passive_buttons: Array[Button] = []
var direction_row: HBoxContainer
var skill_direction := "east"
var transcend_button: Button
var transcendence_id := ""
var transcend_placement := false
var demon_skills: Array = []
var queue_button: Button
var endpoint: LineEdit
var test_code: LineEdit
var disconnect_button: Button
var reconnect_button: Button
var initial_local_test := false
var pad
var role := "hero"
var hero_selector: OptionButton
var demon_summary: Label
var selected_monster := "slime"
var movement := Vector2.ZERO
var input_left := 0.0
var last_tick := -1
var initial_owner := ""
var ended := false
var connection_waiting := false
var wait_deadline := 0
var wait_seconds := -1
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var options: Dictionary = get_node("/root/SceneTransition").consume_entry_options()
	role = String(options.get("role","hero")); initial_owner = get_node("/root/LoginGateway").user_id
	initial_local_test = get_node("/root/LocalTestMode").is_online_match_allowed()
	rows = VBoxContainer.new(); add_child(rows); rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.offset_left = 24; rows.offset_right = -24; rows.offset_top = 35; rows.offset_bottom = -30
	_label(rows,"랭킹 매칭",34)
	_label(rows,"선택 용사 ↔ 마왕 · 3분 생존 · 보상/스테미너 변동 없음",22)
	status = _label(rows,"마왕으로 대기합니다." if role == "demon" else "용사로 대기합니다.",26)
	if role == "hero":
		_label(rows,"출전 용사 선택",22)
		hero_selector = OptionButton.new(); hero_selector.custom_minimum_size.y = 68; rows.add_child(hero_selector)
		var available := LOADOUT.unlocked_heroes()
		for id in available:
			hero_selector.add_item(String(HEROES.get_character(id).get("name",id)))
			hero_selector.set_item_metadata(hero_selector.item_count-1,id)
			if id == HERO_STORE.selected_hero(): hero_selector.selected = hero_selector.item_count-1
		if hero_selector.selected < 0 and hero_selector.item_count > 0: hero_selector.selected = 0
	else:
		demon_summary = _label(rows,"",20)
		_refresh_demon_summary()
	ranking_row = HBoxContainer.new(); ranking_row.visible = false; rows.add_child(ranking_row)
	ranking_icon = TextureRect.new(); ranking_icon.custom_minimum_size = Vector2(56,56)
	ranking_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ranking_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ranking_row.add_child(ranking_icon)
	ranking_label = _label(ranking_row,"",22)
	action_notice = _label(rows,"용사: WASD/방향키 또는 전장 드래그 · 마왕: 몬스터 선택 후 전장 터치",22)
	endpoint = LineEdit.new(); endpoint.placeholder_text = "대전 서버 주소 (wss://...)"; endpoint.text = CONFIG.endpoint()
	endpoint.custom_minimum_size.y = 72; endpoint.add_theme_font_size_override("font_size",25); rows.add_child(endpoint)
	if initial_local_test:
		_label(rows,"로컬 테스트 · 서버에 표시된 입장코드를 입력하세요",22)
		test_code = LineEdit.new(); test_code.secret = true
		test_code.placeholder_text = "테스트 서버 입장코드"; test_code.max_length = LOCAL_ACCESS.TICKET_BYTES * 2
		test_code.custom_minimum_size.y = 72; test_code.add_theme_font_size_override("font_size",25); rows.add_child(test_code)
	queue_button = _button(rows,"매칭 시작",_join)
	_button(rows,"규칙 보기",_show_rules)
	if initial_local_test:
		var connection_tests := HBoxContainer.new(); rows.add_child(connection_tests)
		disconnect_button = _button(connection_tests,"연결 끊기 (테스트)",_test_connection.bind(true))
		reconnect_button = _button(connection_tests,"재접속",_test_connection.bind(false))
		disconnect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reconnect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		disconnect_button.disabled = true; reconnect_button.disabled = true
	if initial_local_test:
		var show_metrics := _button(rows,"연결 측정 보기",_toggle_metrics)
		show_metrics.custom_minimum_size.y=56
		metrics_panel=VBoxContainer.new(); rows.add_child(metrics_panel); metrics_panel.visible=false
		metrics_label=_label(metrics_panel,"측정 대기 중…",19)
		var metric_actions := HBoxContainer.new(); metrics_panel.add_child(metric_actions)
		var copy_metrics := _button(metric_actions,"측정값 복사",_copy_metrics)
		var reset_metrics := _button(metric_actions,"측정 초기화",_reset_metrics)
		for button in [copy_metrics,reset_metrics]:
			button.custom_minimum_size.y=56; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	view = VIEW.new(); view.size_flags_vertical = Control.SIZE_EXPAND_FILL; view.custom_minimum_size.y = 400; rows.add_child(view)
	for child in rows.get_children():
		if child is Control and child != status and child != ranking_row and child != action_notice and child != view:
			setup_controls.append(child)
	TOP_LAYOUT.layout_top(top_bar)
	var panel_art := TOP_LAYOUT.texture(self,TOP_LAYOUT.ROOT + "gold_panel.png")
	for name in ["StageFrame","TimerFrame","HeroStatusFrame","MonsterFrame","StageMenuButton"]:
		PANEL.install(top_bar.get_node(name),panel_art)
	if role == "demon":
		for target in [demon_panel.get_node("Frame"),bottom_bar.get_node("AutoFrame")]: PANEL.install(target,panel_art)
		for button in demon_panel.get_node("UltimateButtons").get_children():
			PANEL.install(button,panel_art)
			button.add_theme_font_size_override("font_size",24)
		for button in bottom_bar.get_node("SummonButtons").get_children(): PANEL.install(button,panel_art)
	for child in top_bar.get_children():
		if child is Control and is_zero_approx(child.anchor_left) and is_zero_approx(child.anchor_right):
			top_rects.append(child.get_rect())
	get_viewport().size_changed.connect(_layout_top_bar)
	_layout_top_bar()
	top_menu = PopupMenu.new(); add_child(top_menu)
	top_menu.add_item("규칙 보기",0); top_menu.add_item("대전 나가기",1)
	top_menu.id_pressed.connect(func(id: int):
		if id == 0: _show_rules()
		else: _leave())
	top_bar.get_node("StageMenuButton").pressed.connect(func():
		top_menu.position = Vector2i(top_bar.get_node("StageMenuButton").get_global_rect().position + Vector2(0,80))
		top_menu.popup())
	view.placement.connect(func(point: Vector2):
		if role == "demon" and not ended and not local_preparing and not waiting_for_start and not connection_waiting and not client.reconnecting:
			if transcend_placement:
				if client.command("transcend",{"point":[point.x,point.y]}): transcend_placement = false
			else: client.command("summon",{"id":selected_monster,"point":[point.x,point.y]}))
	if role == "demon":
		hero_build_toggle = _button(rows,"용사 빌드 ▾",_toggle_hero_build)
		hero_build_toggle.custom_minimum_size.y = 48
		hero_build_scroll = ScrollContainer.new(); hero_build_scroll.custom_minimum_size.y = 160
		hero_build_scroll.visible = false; rows.add_child(hero_build_scroll)
		hero_build_panel = VBoxContainer.new(); hero_build_scroll.add_child(hero_build_panel)
		hero_build_level = _label(hero_build_panel,"용사 Lv.1",20)
		hero_build_rows = VBoxContainer.new(); hero_build_panel.add_child(hero_build_rows)
		hero_build_augments = _label(hero_build_panel,"선택한 증강: 없음",18)
	else:
		demon_info_toggle = _button(rows,"마왕 정보 ▾",_toggle_demon_info)
		demon_info_toggle.custom_minimum_size.y = 48
		demon_info_panel = VBoxContainer.new(); demon_info_panel.visible = false; rows.add_child(demon_info_panel)
		_label(demon_info_panel,"편성 ?",18)
		_label(demon_info_panel,"스킬 ?",18)
		_label(demon_info_panel,"초월 ?",18)
		demon_info_hints = _label(demon_info_panel,"증강 방향: 없음",18)
	if role == "demon":
		action_row = bottom_bar.get_node("SummonButtons")
		skill_row = demon_panel.get_node("UltimateButtons")
		for button in action_row.get_children(): button.hide()
		for button in skill_row.get_children(): button.hide()
		bottom_bar.get_node("PlacementModeToggle").hide()
		transcend_button = Button.new(); transcend_button.text = "초월 소환 · 위치 지정"
		transcend_button.position = Vector2(810,14); transcend_button.size = Vector2(218,56)
		transcend_button.pressed.connect(_select_transcendence); bottom_bar.add_child(transcend_button)
		PANEL.install(transcend_button,panel_art)
		transcend_button.disabled = true; transcend_button.hide()
		direction_row = HBoxContainer.new(); rows.add_child(direction_row)
		for direction in ["east","west","north","south"]:
			var button := _button(direction_row,{"east":"동","west":"서","north":"북","south":"남"}[direction],_select_skill_direction.bind(direction))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if role == "hero":
		pad = PAD.new(); add_child(pad); pad.set_mode(PAD.MODE_FREE)
		pad.input_surface = view; pad.movement_changed.connect(func(value: Vector2): movement = value)
		hero_slots = VBoxContainer.new(); hero_slots.name = "HeroInventory"
		hero_slots.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hero_slots.offset_left = 24; hero_slots.offset_right = -24; hero_slots.offset_top = -210
		add_child(hero_slots)
		weapon_buttons = HERO_HUD.inventory_row(hero_slots,"무기",WEAPONS.WEAPON_SLOTS)
		passive_buttons = HERO_HUD.inventory_row(hero_slots,"보조",WEAPONS.PASSIVE_SLOTS)
		for index in weapon_buttons.size(): weapon_buttons[index].pressed.connect(_show_slot_info.bind(true,index))
		for index in passive_buttons.size(): passive_buttons[index].pressed.connect(_show_slot_info.bind(false,index))
		for button in weapon_buttons + passive_buttons: HERO_HUD.update_slot(button,null,"+",""); button.disabled = true
		hero_slots.hide()
		chest_notice = _label(rows,"",23)
	inventory_detail = AcceptDialog.new(); inventory_detail.title = "장착 정보"; add_child(inventory_detail)
	hold_toggle = _button(rows,"증강 보관함 · 0개 ▾",_toggle_holds)
	hold_scroll = ScrollContainer.new(); hold_scroll.custom_minimum_size.y = 250; rows.add_child(hold_scroll)
	hold_scroll.visible = false
	choices = VBoxContainer.new(); choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hold_scroll.add_child(choices)
	_button(rows,"매칭 취소 · 로비로",_leave)
	loading = LOADING.new(); add_child(loading); loading.cancelled.connect(_leave); loading.rules_requested.connect(_show_rules)
	_build_rules_popup()
	client = CLIENT.new(); add_child(client); client.event_received.connect(_event)
	client.connection_recovering.connect(func(active: bool,remaining: float):
		if ended: return
		movement = Vector2.ZERO
		if active: view.feedback.pause_feedback(); view.pause_motion()
		_set_controls(not active and not connection_waiting)
		if active:
			status.text = "테스트 연결 끊김 · 재접속 버튼을 누르세요. 상대의 유예 시간 내에 복귀하세요." if client.test_transport_paused else "연결 복구 중… 잠시 기다려 주세요."
			queue_button.disabled = true)
	client.connection_closed.connect(func(message: String):
		if not ended: status.text = message
		view.feedback.pause_feedback(); view.pause_motion()
		queue_button.disabled = false; ended = true; load_revision += 1; loading.finish(); _set_controls(false))
func _label(parent: Node,value: String,font: int) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font); parent.add_child(label); return label
func _button(parent: Node,value: String,callback: Callable) -> Button:
	var button := Button.new(); button.text = value; button.custom_minimum_size.y = 76
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; button.add_theme_font_size_override("font_size",25)
	parent.add_child(button); button.pressed.connect(callback); return button
func _layout_top_bar() -> void:
	if top_bar == null or top_rects.is_empty(): return
	var width := get_viewport_rect().size.x
	var index := 0
	for child in top_bar.get_children():
		if child is Control and is_zero_approx(child.anchor_left) and is_zero_approx(child.anchor_right):
			var rect := RESPONSIVE.horizontal_rect(top_rects[index],width)
			child.position = rect.position
			child.size = rect.size
			index += 1
	if role == "demon":
		for panel in [demon_panel,bottom_bar]:
			for child in panel.get_children():
				if child is Control and is_zero_approx(child.anchor_left) and is_zero_approx(child.anchor_right):
					var design: Rect2 = child.get_meta("design_rect",child.get_rect())
					child.set_meta("design_rect",design)
					var rect := RESPONSIVE.horizontal_rect(design,width)
					child.position = rect.position; child.size = rect.size
		for button in summon_buttons:
			button.custom_minimum_size.x = 0
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _show_match_layout() -> void:
	for control in setup_controls: control.hide()
	top_bar.show()
	rows.offset_top = 350
	rows.offset_left = 0
	rows.offset_right = 0
	rows.offset_bottom = -465 if role == "demon" else -220
	if role == "demon":
		demon_panel.show(); bottom_bar.show()
	else: hero_slots.show()
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.clip_text = true
	status.add_theme_font_size_override("font_size",21)
	status.custom_minimum_size.y = 32
	_layout_top_bar()

func _set_hud_text(path: String,value: String) -> void:
	var label := top_bar.get_node(path) as Label
	if label.text != value: label.text = value

func _update_hud_progress(level: int,exp: int,exp_next: int) -> void:
	if level != hud_level:
		hud_level = level
		_set_hud_text("HeroLevel","Lv. %d   %s" % [level,String(HEROES.get_character(matched_hero_id).get("name","용사"))])
	if role != "hero": return
	if exp != hud_exp or exp_next != hud_exp_next:
		hud_exp = exp; hud_exp_next = exp_next
		var bar := top_bar.get_node("ExpBar") as ProgressBar
		bar.max_value = maxi(1,exp_next); bar.value = clampi(exp,0,maxi(1,exp_next))
		_set_hud_text("ExpLabel","EXP %d / %d" % [exp,exp_next])

func _update_match_hud(event: Dictionary) -> void:
	var remaining := maxi(0,ceili(match_duration-float(event.seconds)))
	if remaining != hud_timer_second:
		hud_timer_second = remaining
		_set_hud_text("RunTimer","남은 시간 %02d:%02d" % [remaining/60,remaining%60])
	var hp := int(event.hero[2]); var maximum := maxi(1,int(event.hero[3]))
	if hp != hud_hp or maximum != hud_max_hp:
		hud_hp = hp; hud_max_hp = maximum
		var bar := top_bar.get_node("HeroHPBar") as ProgressBar
		bar.max_value = maximum; bar.value = clampi(hp,0,maximum)
		_set_hud_text("HeroHP","HP %d / %d" % [hp,maximum])
	var monsters: int = event.actors.size()
	if monsters != hud_monsters:
		hud_monsters = monsters
		_set_hud_text("Monsters","몬스터 %d" % monsters)
	if role == "demon": _update_hud_progress(int(event.hero[4]),0,0)

func _build_summon_cards(roster: Array) -> void:
	if roster.size() == summon_ids.size():
		var same := true
		for index in roster.size():
			if String(roster[index]) != summon_ids[index]: same = false; break
		if same: return
	summon_ids.clear()
	for id in roster: summon_ids.append(String(id))
	var template := action_row.get_node("Slot1") as Button
	while action_row.get_child_count() < summon_ids.size():
		var button := template.duplicate() as Button
		button.name = "Slot"+str(action_row.get_child_count()+1)
		action_row.add_child(button)
	summon_buttons.clear()
	for index in action_row.get_child_count():
		var button := action_row.get_child(index) as Button
		button.visible = index < summon_ids.size()
		if not button.visible: continue
		var id := summon_ids[index]
		var data: Dictionary = MONSTERS.get_monster(id)
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.get_node("Name").text = String(data.get("name",id))
		button.get_node("Cost").text = ("%.1f" % MONSTERS.get_base_cost(id)) if summon_ids.size() > 3 else "%s · %.1f" % [MONSTERS.get_role_label(MONSTERS.get_role(id)),MONSTERS.get_base_cost(id)]
		if summon_ids.size() > 3:
			TOP_LAYOUT.place(button.get_node("Icon"),Rect2(12,14,76,85))
			TOP_LAYOUT.place(button.get_node("Name"),Rect2(92,21,90,50),19)
			TOP_LAYOUT.place(button.get_node("Cost"),Rect2(92,84,90,36),19)
		else:
			TOP_LAYOUT.place(button.get_node("Icon"),Rect2(26,27,110,108))
			TOP_LAYOUT.place(button.get_node("Name"),Rect2(138,36,176,42),24)
			TOP_LAYOUT.place(button.get_node("Cost"),Rect2(138,86,176,40),24)
		var icon_path := MONSTERS.get_ui_icon_path(id)
		button.get_node("Icon").texture = load(icon_path) if ResourceLoader.exists(icon_path) else null
		if button.pressed.get_connections().size() > 0:
			for connection in button.pressed.get_connections(): button.pressed.disconnect(connection.callable)
		button.pressed.connect(_select_monster.bind(id))
		summon_buttons.append(button)
	if not summon_ids.is_empty(): selected_monster = summon_ids[0]
	_layout_top_bar()

func _update_summon_cards(mana: float,costs: Dictionary) -> void:
	var signature := JSON.stringify(costs)
	if is_equal_approx(mana,summon_mana) and signature == summon_cost_signature: return
	summon_mana = mana
	summon_costs = costs
	summon_cost_signature = signature
	var maximum := 100.0
	var label := bottom_bar.get_node("CommandLabel") as Label
	label.text = "지휘력 %d / %d" % [roundi(mana),roundi(maximum)]
	var bar := bottom_bar.get_node("CommandBar") as ProgressBar
	bar.max_value = maximum; bar.value = mana
	for index in summon_buttons.size():
		var cost := float(costs.get(summon_ids[index],MONSTERS.get_base_cost(summon_ids[index])))
		summon_buttons[index].get_node("Cost").text = ("%.1f" % cost) if summon_ids.size() > 3 else "%s · %.1f" % [MONSTERS.get_role_label(MONSTERS.get_role(summon_ids[index])),cost]
		summon_buttons[index].disabled = ended or connection_waiting or client.reconnecting or local_preparing or waiting_for_start or mana + 0.001 < cost

func _show_slot_info(weapon: bool,index: int) -> void:
	var items: Array = inventory_items.weapons if weapon else inventory_items.passives
	if index < items.size():
		var item: Array = items[index]
		_show_hero_item(String(item[0]),int(item[1]),weapon and item.size() > 2 and item[2] == true)

func _update_hero_slots(inventory: Dictionary) -> void:
	inventory_items = {"weapons":inventory.weapons,"passives":inventory.passives}
	for kind in ["weapons","passives"]:
		var buttons: Array[Button] = weapon_buttons if kind == "weapons" else passive_buttons
		var items: Array = inventory[kind]
		for index in buttons.size():
			var button := buttons[index]
			if index >= items.size():
				HERO_HUD.update_slot(button,null,"+",""); button.disabled = true; continue
			var item: Array = items[index]
			if item.size() < 2 or not item[0] is String or not RULES.number(item[1]): continue
			var id := String(item[0])
			var evolved: bool = kind == "weapons" and item.size() > 2 and item[2] == true
			var data: Dictionary = WEAPONS.WEAPONS.get(id,WEAPONS.PASSIVES.get(id,{}))
			if data.is_empty(): continue
			HERO_HUD.update_slot(button,ICONS.texture(id),"MAX" if evolved else "Lv.%d" % int(item[1]),String(data.get("name",id)))
			button.disabled = false

func _update_demon_controls(event: Dictionary) -> void:
	_update_summon_cards(float(event.mana),event.summon_costs)
	var skill_signature := JSON.stringify([event.get("demon_level",1),event.get("demon_exp",0.0),event.get("demon_exp_next",1.0),event.demon_charge,event.demon_charge_max,event.demon_cooldowns,event.demon_ready,event.transcend_ready,event.transcend_used,connection_waiting,waiting_for_start])
	if skill_signature != skill_state_signature:
		skill_state_signature = skill_signature
		(demon_panel.get_node("DemonLevelLabel") as Label).text = "마왕 Lv.%d" % int(event.get("demon_level",1))
		(demon_panel.get_node("DemonProgressLabel") as Label).text = "EXP %.1f / %.1f" % [float(event.get("demon_exp",0.0)),float(event.get("demon_exp_next",1.0))]
		var exp_bar := demon_panel.get_node("DemonExpBar") as ProgressBar
		exp_bar.max_value = maxf(1.0,float(event.get("demon_exp_next",1.0))); exp_bar.value = float(event.get("demon_exp",0.0))
		(demon_panel.get_node("UltimateLabel") as Label).text = "필살기 %d / %d" % [roundi(float(event.demon_charge)),roundi(float(event.demon_charge_max))]
		var charge_bar := demon_panel.get_node("UltimateBar") as ProgressBar
		charge_bar.max_value = maxf(1.0,float(event.demon_charge_max)); charge_bar.value = float(event.demon_charge)
		for id in skill_buttons:
			var data: Dictionary = SKILLS.get_skill(id)
			var cooldown := float(event.demon_cooldowns.get(id,0.0))
			var button: Button = skill_buttons[id]
			button.get_node("SkillContent").update_state("쿨 %.0f초" % ceilf(cooldown) if cooldown > 0.01 else "사용 가능" if bool(event.demon_ready.get(id,false)) else "필요 %.0f" % float(data.get("mana_cost",0.0)),bool(event.demon_ready.get(id,false)))
			button.disabled = connection_waiting or client.reconnecting or waiting_for_start or not bool(event.demon_ready.get(id,false))
			var cooldown_bar := button.get_node("CooldownBar") as ProgressBar
			cooldown_bar.max_value = maxf(0.1,float(data.get("cooldown",0.0)))
			cooldown_bar.visible = cooldown > 0.01; cooldown_bar.value = cooldown
		transcend_button.disabled = connection_waiting or client.reconnecting or waiting_for_start or not event.transcend_ready or event.transcend_used
		transcend_button.text = "초월 소환 완료" if event.transcend_used else "초월 소환 · 위치 지정" if event.transcend_ready else "초월 해금 대기"
		if event.transcend_used: transcend_placement = false

func _select_monster(id: String) -> void:
	selected_monster = id
	transcend_placement = false
	action_notice.text = "소환 선택: %s · 전장 터치로 배치" % String(MONSTERS.get_monster(id).get("name",id))
func _select_skill_direction(direction: String) -> void:
	skill_direction = direction
	action_notice.text = "직선 포위 방향: %s" % {"east":"동","west":"서","north":"북","south":"남"}.get(direction,direction)
func _use_skill(id: String) -> void:
	if not ended and not connection_waiting and not client.reconnecting:
		client.command("skill",{"id":id,"direction":skill_direction if id == "line_assault" else ""})
func _select_transcendence() -> void:
	transcend_placement = true
	action_notice.text = "초월 소환 위치를 전장에서 터치해 주세요."
func _select_held(id: String,number: int) -> void:
	if not ended and not connection_waiting and not client.reconnecting:
		client.command("choose" if role == "hero" else "demon_choose",{"id":id,"number":number})
func _reroll_held(number: int) -> void:
	if role == "hero" and not ended and not connection_waiting and not client.reconnecting and rerolls_left > 0:
		client.command("reroll",{"number":number})
func _show_hero_item(id: String,level: int,evolved: bool) -> void:
	var data: Dictionary = WEAPONS.WEAPONS.get(id,WEAPONS.PASSIVES.get(id,{}))
	if data.is_empty(): return
	var rank := 11 if evolved else level
	var title := WEAPONS.GROWTH.evolution_name(id) if evolved else String(data.get("name",id))
	inventory_detail.dialog_text = "%s · %s\n%s" % [title,"MAX" if evolved else "Lv.%d" % level,WEAPONS.description(id,rank)]
	inventory_detail.popup_centered(Vector2i(700,320))
func _toggle_hero_build() -> void:
	hero_build_scroll.visible = not hero_build_scroll.visible
	hero_build_toggle.text = "용사 빌드 %s" % ("▴" if hero_build_scroll.visible else "▾")
func _toggle_demon_info() -> void:
	demon_info_panel.visible = not demon_info_panel.visible
	demon_info_toggle.text = "마왕 정보 %s" % ("▴" if demon_info_panel.visible else "▾")
func _update_demon_info(hints: Dictionary) -> void:
	if not hints.get("augment_hints",null) is Array: return
	var names := PackedStringArray()
	for hint in hints.augment_hints:
		if hint is String: names.append(hint)
	demon_info_hints.text = "증강 방향: %s" % ("없음" if names.is_empty() else ", ".join(names))
func _update_hero_build(build: Dictionary) -> void:
	if not RULES.number(build.get("level",null)) or not build.get("augments",null) is Array: return
	if not build.get("weapons",null) is Array or not build.get("passives",null) is Array: return
	if build.weapons.size() > WEAPONS.WEAPON_SLOTS or build.passives.size() > WEAPONS.PASSIVE_SLOTS: return
	var signature := JSON.stringify(build)
	if signature == hero_build_signature: return
	hero_build_signature = signature
	hero_build_level.text = "용사 Lv.%d" % int(build.level)
	var names := PackedStringArray()
	for name in build.augments:
		if name is String: names.append(name)
	hero_build_augments.text = "선택한 증강: %s" % ("없음" if names.is_empty() else ", ".join(names))
	_render_hero_items(hero_build_rows,build)
func _update_hero_inventory(inventory: Dictionary) -> void:
	if not RULES.number(inventory.get("level",null)) or not RULES.number(inventory.get("exp",null)) or not RULES.number(inventory.get("exp_next",null)): return
	if not RULES.number(inventory.get("rerolls_left",null)) or not RULES.number(inventory.get("reroll_limit",null)): return
	if not inventory.get("weapons",null) is Array or not inventory.get("passives",null) is Array: return
	if inventory.weapons.size() > WEAPONS.WEAPON_SLOTS or inventory.passives.size() > WEAPONS.PASSIVE_SLOTS: return
	rerolls_left = int(inventory.rerolls_left); reroll_limit = int(inventory.reroll_limit)
	_update_hud_progress(int(inventory.level),int(inventory.exp),int(inventory.exp_next))
	var signature := JSON.stringify([inventory.weapons,inventory.passives])
	if signature == inventory_signature: return
	inventory_signature = signature
	_update_hero_slots(inventory)
func _render_hero_items(target: VBoxContainer,inventory: Dictionary) -> void:
	for child in target.get_children():
		if child is HBoxContainer: child.queue_free()
	for kind in ["weapons","passives"]:
		var row := HBoxContainer.new(); target.add_child(row)
		for item in inventory[kind]:
			if not item is Array or item.size() < 2 or not item[0] is String or not RULES.number(item[1]): continue
			var id: String = item[0]
			var evolved: bool = kind == "weapons" and item.size() > 2 and item[2] == true
			if not WEAPONS.WEAPONS.has(id) and not WEAPONS.PASSIVES.has(id): continue
			var level := int(item[1])
			var button := _button(row,"MAX" if evolved else "Lv.%d" % level,_show_hero_item.bind(id,level,evolved))
			button.icon = ICONS.texture(id); button.custom_minimum_size = Vector2(100,66)
			button.add_theme_font_size_override("font_size",18)
func _receive_chests(receipts: Array) -> void:
	if receipts.size() > RULES.CHEST_HISTORY_LIMIT: return
	for receipt in receipts:
		if not receipt is Dictionary or not RULES.number(receipt.get("serial",null)) or not receipt.get("name",null) is String: continue
		var serial := int(receipt.serial)
		if serial <= chest_last_serial: continue
		chest_last_serial = serial
		chest_queue.append(receipt.duplicate())
func _advance_chest_notice(delta: float) -> void:
	if chest_notice == null: return
	chest_seconds -= delta
	if chest_seconds > 0: return
	if chest_queue.is_empty(): chest_notice.text = ""; return
	var receipt: Dictionary = chest_queue.pop_front()
	chest_notice.text = "상자 보상 · %s\n%s" % [String(receipt.name),String(receipt.get("description",""))]
	chest_seconds = 2.4
func _toggle_holds() -> void:
	hold_expanded = not hold_expanded
	hold_scroll.visible = hold_expanded
	hold_toggle.text = "증강 보관함 · %d개 %s" % [choices.get_meta("count",0),"▴" if hold_expanded else "▾"]
func _update_holds(holds: Array) -> void:
	var signature := JSON.stringify([holds,rerolls_left,reroll_limit])
	if signature == hold_signature: return
	hold_signature = signature
	choices.set_meta("count",holds.size())
	hold_toggle.text = "증강 보관함 · %d개 %s" % [holds.size(),"▴" if hold_expanded else "▾"]
	hold_toggle.modulate = Color(1.0,0.82,0.4) if not holds.is_empty() else Color.WHITE
	for child in choices.get_children(): choices.remove_child(child); child.queue_free()
	for index in holds.size():
		var offer: Dictionary = holds[index]
		_label(choices,"보관 %d · %d번 선택지" % [index+1,int(offer.number)],20)
		if role == "hero":
			var refresh := _button(choices,"새로고침 · 남은 %d/%d회" % [rerolls_left,reroll_limit],_reroll_held.bind(int(offer.number)))
			refresh.disabled = rerolls_left <= 0 or connection_waiting or client.reconnecting
		for option in offer.candidates:
			var name := String(option.name)
			var description := String(option.get("description",""))
			_button(choices,name if description.is_empty() else "%s · %s" % [name,description],_select_held.bind(String(option.id),int(offer.number)))
	_set_controls(not connection_waiting and not client.reconnecting)
func _build_rules_popup() -> void:
	rules_popup = PopupPanel.new(); add_child(rules_popup)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(720,900); rules_popup.add_child(scroll)
	var sections := VBoxContainer.new(); sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(sections)
	for section in RULES_GUIDE.sections():
		_label(sections,String(section.title),30)
		for item in section.items: _label(sections,"• " + String(item),23)
	_button(sections,"닫기",func(): rules_popup.hide())
func _show_rules() -> void:
	rules_popup.popup_centered(Vector2i(760,1000))
func _demon_loadout() -> Dictionary:
	var owned := COLLECTION.get_unlocked_ids(COLLECTION.load_state())
	var available: Array = []
	for id in owned:
		if MONSTERS.get_rarity(String(id)) != "transcendent": available.append(id)
	var team := TEAM.load_ids(available,TEAM.default_ids(available))
	var skills := SKILL_STORE.load_ids(SKILLS.get_ordered_ids(),SKILLS.get_ordered_ids())
	return {"team_ids":team,"skill_ids":skills,"transcendence_id":TRANSCENDENCE.load_id()}
func _refresh_demon_summary() -> void:
	var chosen := _demon_loadout()
	var names: Array[String] = []
	for id in chosen.team_ids: names.append(String(MONSTERS.get_monster(id).get("name",id)))
	demon_summary.text = "편성: %s\n마왕 스킬: %s · 초월: %s" % [", ".join(names),", ".join(chosen.skill_ids),chosen.transcendence_id if not chosen.transcendence_id.is_empty() else "미등록"]
func _join() -> void:
	var chosen: Dictionary = {"hero_id":String(hero_selector.get_item_metadata(hero_selector.selected))} if role == "hero" and hero_selector.selected >= 0 else _demon_loadout() if role == "demon" else {}
	if role == "hero" and (not LOADOUT.valid(role,chosen) or chosen.hero_id not in LOADOUT.unlocked_heroes()): status.text = "보유한 용사를 선택해 주세요."; return
	if role == "demon":
		_refresh_demon_summary()
		var reason := ENTRY.blocked_reason(chosen.team_ids,chosen.skill_ids,false)
		if not reason.is_empty(): status.text = reason; return
	if get_node("/root/LocalTestMode").is_online_match_allowed() != initial_local_test: status.text = "테스트 모드가 변경되었습니다. 로비에서 다시 입장하세요."; return
	if initial_local_test:
		if not LOCAL_ACCESS.valid_hex(test_code.text.strip_edges(),LOCAL_ACCESS.TICKET_BYTES): status.text = "서버에 표시된 테스트 입장코드를 입력하세요."; return
	elif get_node("/root/LoginGateway").user_id.is_empty() or get_node("/root/LoginGateway").access_token.is_empty(): status.text = "Google 또는 카카오 로그인이 필요합니다."; return
	if not RULES.endpoint_valid(endpoint.text.strip_edges()): status.text = "공용 대전 서버 주소(wss://)를 입력해 주세요."; return
	ended = false; last_tick = -1; transcend_placement = false; connection_waiting = false
	hold_signature = ""; _update_holds([])
	ranking_row.hide()
	view.clear_state()
	if pad != null: pad.enabled = true; pad.reset()
	var error: int = client.join_local_test(endpoint.text.strip_edges(),test_code.text.strip_edges(),role,chosen) if initial_local_test else client.join(endpoint.text.strip_edges(),get_node("/root/LoginGateway").access_token,role,chosen)
	if test_code != null and error == OK: test_code.clear()
	status.text = "서버에 연결 중..." if error == OK else "서버에 연결하지 못했습니다."
	queue_button.disabled = error == OK
	if error == OK: loading.begin(role); _set_controls(false)
func _event(event: Dictionary) -> void:
	match String(event.get("op","")):
		"queued": status.text = "상대 역할 플레이어를 찾는 중..."
		"matched":
			matched_hero_id = String(event.get("hero",HEROES.DEFAULT_HERO))
			match_duration = float(event.get("duration",RULES.DURATION))
			hud_timer_second = -1; hud_hp = -1; hud_max_hp = -1; hud_monsters = -1; hud_level = -1; hud_exp = -1; hud_exp_next = -1; hud_mana = -1
			var stage_id := String(event.get("battlefield",{}).get("stage",""))
			var stage_data: Dictionary = STAGES.get_stage(stage_id)
			_set_hud_text("StageNumber","RANKED")
			_set_hud_text("Subtitle",String(stage_data.get("name",stage_data.get("display_name","랭크 전장"))))
			_set_hud_text("StageHeroName",String(HEROES.get_character(matched_hero_id).get("name","용사")))
			(top_bar.get_node("HeroPortrait") as TextureRect).texture = HERO_HUD.portrait_texture(matched_hero_id)
			(top_bar.get_node("ExpBar") as Control).visible = role == "hero"
			(top_bar.get_node("ExpLabel") as Control).visible = role == "hero"
			_show_match_layout()
			if not bool(event.get("resumed",false)):
				chest_queue.clear(); chest_last_serial = 0; chest_seconds = 0.0; inventory_signature = ""
			transcendence_id = String(event.get("transcendence_id",""))
			if event.get("roster",null) is Array: view.set_match_roster(event.roster,transcendence_id)
			if role == "demon" and event.get("roster",null) is Array:
				_build_summon_cards(event.roster)
				summon_mana = -1.0; skill_state_signature = ""
				skill_buttons.clear()
				demon_skills = event.get("skill_ids",[]) if event.get("skill_ids",[]) is Array else []
				for index in skill_row.get_child_count():
					var button := skill_row.get_child(index) as Button
					button.visible = index < demon_skills.size()
					if not button.visible: continue
					var id := String(demon_skills[index])
					preload("res://src/ui/demon_skill_button_content.gd").attach(button,index,id,String(SKILLS.get_skill(id).get("name",id)))
					for connection in button.pressed.get_connections(): button.pressed.disconnect(connection.callable)
					button.pressed.connect(_use_skill.bind(id))
					skill_buttons[id] = button
				direction_row.visible = "line_assault" in demon_skills
				transcend_button.visible = not transcendence_id.is_empty()
			last_tick = -1; view.resume_motion()
			_refresh_connection_test_controls()
			status.text = "기존 경기로 복귀했습니다." if event.get("resumed",false) else "매칭 완료 · 전투 준비 중..."
			if event.has("feedback_cursor") and not view.FEEDBACK_DATA.valid_cursor(event.feedback_cursor): return
			view.feedback.reset(int(event.get("feedback_cursor",0)))
			load_revision += 1
			local_preparing = true; waiting_for_start = true; _set_controls(false)
			loading.begin(role); loading.show_phase("loading")
			_prepare_match(event,load_revision)
		"connection":
			if event.get("match","") != client.match_id or ended or not event.get("paused",null) is bool or not RULES.number(event.get("remaining",null),RULES.RECONNECT_GRACE): return
			connection_waiting = event.paused
			if connection_waiting: view.feedback.pause_feedback(); view.pause_motion()
			wait_deadline = Time.get_ticks_msec() + int(maxf(0.0,float(event.remaining))*1000.0); wait_seconds = -1
			_set_controls(not connection_waiting and not client.reconnecting)
			if not connection_waiting:
				view.resume_motion(); status.text = "연결이 복구되어 전투를 재개합니다."
		"state":
			if local_preparing: return
			if ended or event.get("match","") != client.match_id or not RULES.number(event.get("tick",null)): return
			if not RULES.number(event.get("seconds",null)) or not RULES.number(event.get("mana",null)): return
			if not event.get("augment_holds",null) is Array or event.augment_holds.size() > RULES.AUGMENT_HOLD_LIMIT: return
			if role == "demon":
				if not RULES.number(event.get("demon_charge",null)) or not RULES.number(event.get("demon_charge_max",null)): return
				if not event.get("demon_cooldowns",null) is Dictionary or not event.get("demon_ready",null) is Dictionary or not event.get("summon_costs",null) is Dictionary or not event.get("transcend_ready",null) is bool or not event.get("transcend_used",null) is bool: return
				if not RULES.number(event.get("demon_level",null)) or not RULES.number(event.get("demon_exp",null)) or not RULES.number(event.get("demon_exp_next",null)): return
				for id in summon_ids:
					if not RULES.number(event.summon_costs.get(id,null)) or float(event.summon_costs[id]) < 0.0: return
				for cooldown in event.demon_cooldowns.values():
					if not RULES.number(cooldown): return
				for ready in event.demon_ready.values():
					if not ready is bool: return
			elif not event.get("demon_hints",null) is Dictionary: return
			for offer in event.augment_holds:
				if not offer is Dictionary or not RULES.number(offer.get("number",null)) or float(offer.number) != floorf(float(offer.number)) or not offer.get("candidates",null) is Array or offer.candidates.is_empty() or offer.candidates.size() > 4: return
				for option in offer.candidates:
					if not option is Dictionary or not option.get("id",null) is String or not option.get("name",null) is String: return
			if int(event.tick) <= last_tick or not view.update_state(event): return
			last_tick = int(event.tick)
			_update_match_hud(event)
			if role == "hero" and event.get("hero_inventory",null) is Dictionary and event.get("chest_receipts",null) is Array:
				_update_hero_inventory(event.hero_inventory)
				_receive_chests(event.chest_receipts)
			if role == "demon" and event.get("hero_build",null) is Dictionary:
				_update_hero_build(event.hero_build)
				_update_hud_progress(int(event.hero_build.get("level",event.hero[4])),0,0)
			if role == "hero": _update_demon_info(event.demon_hints)
			view.feedback.suspended = waiting_for_start or connection_waiting or client.reconnecting
			if waiting_for_start and last_tick > 0 and not connection_waiting and not client.reconnecting:
				waiting_for_start = false; view.feedback.suspended = false; loading.finish(); _set_controls(true)
			if event.has("feedback"): view.feedback.consume(event.feedback,event.feedback_cursor,event.tick)
			if not connection_waiting:
				var mana_value := roundi(float(event.mana))
				if mana_value != hud_mana:
					hud_mana = mana_value
					status.text = "마력 %d" % mana_value
			_update_holds(event.augment_holds)
			if role == "demon": _update_demon_controls(event)
		"result":
			if event.get("match","") != client.match_id or ended: return
			if event.has("feedback"): view.feedback.consume(event.feedback,event.get("feedback_cursor",null),event.get("tick",null))
			view.feedback.result(String(event.get("winner","")),role); view.pause_motion()
			load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
			ended = true; movement = Vector2.ZERO; connection_waiting = false; queue_button.disabled = false
			_set_controls(false)
			_update_holds([])
			status.text = "대전 종료 · "+("무효 경기" if String(event.get("winner","")).is_empty() else "승리" if event.winner == role else "패배")
			var ranking: Variant = event.get("ranking",null)
			if event.get("rated",false) == true and ranking is Dictionary and RULES.number(ranking.get("mmr",null)) and RULES.number(ranking.get("delta",null)):
				var tier_id := String(ranking.get("tier",""))
				var icon := RANKED.icon_path(tier_id)
				if not icon.is_empty() and ResourceLoader.exists(icon):
					ranking_icon.texture = load(icon)
					ranking_label.text = "MMR %s%d → %d · %s" % ["+" if int(ranking.delta) >= 0 else "",int(ranking.delta),int(ranking.mmr),RANKED.display_name(tier_id)]
					ranking_row.show()
			if not ranking_row.visible:
				status.text += "\n점수 변동 없음"
			if pad != null: pad.enabled = false; pad.reset()
		"action":
			if event.get("match","") == client.match_id and event.get("message",null) is String: action_notice.text = event.message
		"error":
			view.feedback.pause_feedback(); view.pause_motion()
			load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
			ended = true
			_set_controls(false)
			status.text = String(RULES.ERROR_MESSAGES.get(event.get("reason","unknown"),"매칭 요청을 처리하지 못했습니다."))
func _prepare_match(event: Dictionary,serial: int) -> void:
	var current := func(): return is_inside_tree() and serial == load_revision and not ended and not client.reconnecting
	await get_tree().process_frame
	if not current.call(): return
	if event.has("battlefield"):
		var progress := func(value: float):
			if current.call(): loading.show_phase("loading",value)
		var prepared: bool = await view.prepare_battlefield_async(event.battlefield,current,progress)
		if not current.call(): return
		if not prepared:
			ended = true; local_preparing = false; waiting_for_start = false; loading.finish()
			client.close(); status.text = "전장 정보를 준비하지 못했습니다."; _set_controls(false); return
	local_preparing = false; loading.show_phase("waiting",1.0)
	client.send({"op":"ready","match":client.match_id})
func _set_controls(enabled: bool) -> void:
	enabled = enabled and not local_preparing and not waiting_for_start
	_refresh_connection_test_controls()
	if not enabled: movement = Vector2.ZERO
	if pad != null:
		pad.enabled = enabled
		if not enabled: pad.reset()
	if role == "demon":
		for index in summon_buttons.size(): summon_buttons[index].disabled = not enabled or summon_mana + 0.001 < float(summon_costs.get(summon_ids[index],MONSTERS.get_base_cost(summon_ids[index])))
	for button in choices.get_children():
		if button is Button: button.disabled = not enabled
	if role == "demon":
		for button in skill_row.get_children(): button.disabled = not enabled or button.disabled
		if transcend_button != null: transcend_button.disabled = not enabled or transcend_button.disabled
func _refresh_connection_test_controls() -> void:
	if disconnect_button == null: return
	var allowed: bool = not ended and get_node("/root/LocalTestMode").is_online_match_allowed() and client.local_test_connection and not client.match_id.is_empty() and not client.resume_token.is_empty() and not client.result_received
	disconnect_button.disabled = not allowed or client.reconnecting or client.socket == null or client.socket.get_ready_state() != WebSocketPeer.STATE_OPEN
	reconnect_button.disabled = not allowed or not client.test_transport_paused
func _test_connection(disconnected: bool) -> void:
	if initial_local_test and not ended and client.set_local_test_disconnected(disconnected):
		_refresh_connection_test_controls()
func _process(delta: float) -> void:
	if client == null: return
	_advance_chest_notice(delta)
	if metrics_panel!=null and metrics_panel.visible:
		metrics_left-=delta
		if metrics_left<=0:
			metrics_left=METRICS.PANEL_SECONDS; _refresh_metrics()
	if not ended and get_node("/root/LocalTestMode").is_online_match_allowed() != initial_local_test: client.close(); view.feedback.pause_feedback(); view.pause_motion(); status.text = "테스트 모드가 변경되어 대전을 종료했습니다."; ended = true; _set_controls(false)
	if not ended and get_node("/root/LoginGateway").user_id != initial_owner: client.close(); view.feedback.pause_feedback(); view.pause_motion(); status.text = "계정이 변경되어 대전을 종료했습니다."; ended = true; _set_controls(false)
	if connection_waiting and not ended and not client.reconnecting:
		var seconds := maxi(0,int(ceil(float(wait_deadline-Time.get_ticks_msec())/1000.0)))
		if seconds != wait_seconds:
			wait_seconds = seconds
			status.text = "상대 연결 복구 대기 · %d초 · 전투 일시정지" % seconds if seconds > 0 else "재접속 결과를 확인하고 있습니다…"
	if ended and loading.visible:
		load_revision += 1; local_preparing = false; waiting_for_start = false; loading.finish()
	if ended or local_preparing or waiting_for_start or connection_waiting or client.reconnecting or role != "hero" or client.match_id.is_empty(): return
	input_left -= delta
	if input_left > 0: return
	input_left = 0.05
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := keyboard.limit_length(1.0) if keyboard.length_squared() > 0 else movement
	client.command("move",[direction.x,direction.y])
func _leave() -> void:
	load_revision += 1; ended = true; view.feedback.pause_feedback(); view.pause_motion(); loading.finish()
	if client != null: client.close()
	if role == "hero": get_tree().set_meta("hero_lobby_return",true)
	get_node("/root/SceneTransition").change_scene("res://src/lobby/Lobby.tscn","로비 준비 중...")
func _exit_tree() -> void:
	load_revision += 1
	if client != null: client.close()

func _toggle_metrics() -> void:
	if metrics_panel==null: return
	metrics_panel.visible=not metrics_panel.visible; metrics_left=0
func _metric_text(sample: Dictionary) -> String:
	return "미측정" if sample.count==0 else "%.1f / %.1f ms" % [sample.mean_ms,sample.p95_ms]
func _refresh_metrics() -> void:
	var data: Dictionary = client.metrics.report(role)
	metrics_label.text="FPS %d · RTT 평균/P95 %s\n수신간격 평균/P95 %s\n입력 처리 확인 평균/P95 %s\n수신 %.1f / 송신 %.1f KiB/s (본문)" % [Engine.get_frames_per_second(),_metric_text(data.rtt),_metric_text(data.state_gap),_metric_text(data.input_confirmation),data.rx_kib_s,data.tx_kib_s]
	if not data.server.is_empty():
		var value: Dictionary=data.server
		var snapshot_text := "미측정" if value.snapshot_samples==0 else "%.2f ms" % value.snapshot_ms
		var encode_text := "미측정" if value.encode_samples==0 else "%.2f ms" % value.encode_ms
		metrics_label.text+="\n서버 전체 물리 %.2f ms · 스냅샷/인코딩 평균 %s / %s\n방 %d · 연결 %d · 몬스터 %d · 투사체 %d · 상태 %.1f KiB" % [value.physics_ms,snapshot_text,encode_text,value.rooms,value.peers,value.actors,value.projectiles,value.snapshot_bytes/1024.0]
func _metrics_json() -> String:
	return JSON.stringify(client.metrics.report(role),"\t")
func _copy_metrics() -> void:
	if DisplayServer.get_name()!="headless": DisplayServer.clipboard_set(_metrics_json())
	action_notice.text="측정값을 복사했습니다." if DisplayServer.get_name()!="headless" else "현재 환경에서는 클립보드를 사용할 수 없습니다."

func _reset_metrics() -> void:
	client.metrics.reset(); metrics_left=0
