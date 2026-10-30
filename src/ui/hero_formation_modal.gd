extends Control
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const ROW_SKIN := preload("res://src/ui/mission_row_skin.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
var owner_id := ""
var selected_tab := "weapon"
var content: VBoxContainer
var scroll: ScrollContainer
var weapon_tab: Button
var passive_tab: Button
var focus_buttons: Array[Button] = []
func open(id: String, kind: String = "augment") -> void:
	owner_id = id; name = "HeroFormationModal"; set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP; z_index = 100
	var shade := ColorRect.new(); shade.color = Color(0,0,0,0.82); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(shade)
	var panel := PanelContainer.new(); panel.name = "ModalPanel"; add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -460; panel.offset_right = 460; panel.offset_top = -570; panel.offset_bottom = 570
	var style := StyleBoxFlat.new(); style.bg_color = Color("101e2c"); style.border_color = Color("d3b365"); style.set_border_width_all(3); style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel",SKIN.skin_style(style))
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation",16); panel.add_child(rows)
	var header := HBoxContainer.new(); rows.add_child(header)
	var title := label(header,String(CHARACTERS.get_character(id).name)+" · "+("증강" if kind == "augment" else "기술" if kind == "skills" else "상세 정보"),30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new(); close.name = "CloseModal"; close.text = "닫기"; close.custom_minimum_size = Vector2(100,70); close.add_theme_font_size_override("font_size",26); ROW_SKIN.apply_button(close); header.add_child(close); close.pressed.connect(queue_free); focus_buttons.append(close)
	if kind == "augment":
		label(rows,"전투 중 최대 무기 6개 · 보조 6개 / 아래 효과는 처음 획득할 때 기준",21)
		var tabs := HBoxContainer.new(); rows.add_child(tabs)
		weapon_tab = tab(tabs,"무기 증강",_show_weapons)
		passive_tab = tab(tabs,"보조 증강",_show_passives)
	scroll = ScrollContainer.new(); scroll.name = "ModalScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; rows.add_child(scroll)
	content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",14); scroll.add_child(content)
	if kind == "details":
		label(content,String(CHARACTERS.get_character(id).style),26)
		label(content,"이동은 직접 조작 · 공격은 자동\n레벨업 시 무기·보조 증강 선택 · 최대 레벨 무기는 상자에서 진화\n15분 후 등장하는 대형 보스를 처치하면 클리어",25)
		label(content,"기본 능력치는 모든 용사가 동일하며, 공통 영구 성장과 전투 중 증강이 적용됩니다. 용사의 차이는 전용 무기와 고유 전투 방식입니다.",23)
	else: _show_weapons()
	close.grab_focus()
func label(parent: Node, value: String, font: int) -> Label:
	var result := Label.new(); result.text = value; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; result.add_theme_font_size_override("font_size",font); parent.add_child(result); return result
func tab(parent: Node, value: String, action: Callable) -> Button:
	var button := Button.new(); button.text = value; button.toggle_mode = true; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.custom_minimum_size.y = 64; button.add_theme_font_size_override("font_size",25); ROW_SKIN.apply_button(button); parent.add_child(button); button.pressed.connect(action); focus_buttons.append(button); return button
func _clear() -> void:
	for child in content.get_children(): content.remove_child(child); child.queue_free()
	scroll.scroll_vertical = 0
func _show_weapons() -> void:
	selected_tab = "weapon"; _clear()
	if weapon_tab != null: weapon_tab.set_pressed_no_signal(true); passive_tab.set_pressed_no_signal(false)
	for id in WEAPONS.weapon_pool(owner_id): _entry(id,String(WEAPONS.WEAPONS[id].name),WEAPONS.card_tags(id))
func _show_passives() -> void:
	selected_tab = "passive"; _clear(); weapon_tab.set_pressed_no_signal(false); passive_tab.set_pressed_no_signal(true)
	label(content,"실제 선택 가능 여부는 용사와 현재 장착한 무기에 따라 달라집니다.",21)
	for id in WEAPONS.PASSIVES:
		if WEAPONS.passive_allowed(id,owner_id,WEAPONS.weapon_pool(owner_id)):
			_entry(id,String(WEAPONS.PASSIVES[id].name),WEAPONS.description(id,1))
func _entry(id: String, title: String, description: String) -> void:
	var row := HBoxContainer.new(); row.name = id; row.add_theme_constant_override("separation",18); content.add_child(row)
	var icon := TextureRect.new(); icon.texture = ICONS.texture(id); icon.custom_minimum_size = Vector2(80,80); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; row.add_child(icon)
	var text := VBoxContainer.new(); text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(text)
	label(text,title,26); label(text,description,22)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled(); queue_free()

func _input(event: InputEvent) -> void:
	if not visible or not event.is_pressed(): return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled(); queue_free(); return
	var forward := event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down")
	var backward := event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up")
	if forward or backward:
		var index := focus_buttons.find(get_viewport().gui_get_focus_owner())
		focus_buttons[posmod(index+(1 if forward else -1),focus_buttons.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() not in focus_buttons:
		get_viewport().set_input_as_handled()
