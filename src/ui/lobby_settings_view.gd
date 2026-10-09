extends RefCounted

const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const OTHER_ENTRIES := [["profile", "프로필"], ["demon_book", "마왕도감"], ["hero_book", "용사도감"], ["daily", "일일미션"], ["weekly", "주간미션"], ["friends", "친구목록"], ["rank_history", "랭킹기록"], ["practice", "연습전투"], ["settings", "설정"]]

const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const PROFILE_COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const PROFILE_CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
const NOTICE_PATH := "user://notification_settings.cfg"
const TABS := [["game", "게임"], ["sound", "소리"], ["notice", "알림"], ["account", "계정"], ["misc", "기타"]]
const GAME_OPTIONS := [
	{"key": "camera_view_locked", "title": "화면 고정", "description": "켜면 용사를 따라갑니다. 끄면 드래그로 화면을 이동합니다.", "default": true},
	{"key": "battle_frame_enabled", "title": "배틀 프레임", "description": "전장 주변의 마왕성 장식 프레임을 표시합니다.", "default": true},
]
var other_menu: VBoxContainer
var other_menu_buttons := {}
var settings_root: VBoxContainer
var profile_view: RefCounted
var hero_codex_view: RefCounted
var other_navigation: HBoxContainer
var other_back_button: Button
var other_backdrop: Panel
var settings_title_plate: PanelContainer
var menu_title_plate: PanelContainer
var lobby: Control
var buttons := {}
var pages := {}
var selected := "game"
var game_checks := {}
var notice_checks := {}
var account_identity: Label
var cloud_status: Label
var profile_label: Label
var profile_portrait: TextureRect
var profile_avatar_frame: PanelContainer
var profile_setup: Button
var account_heading: MarginContainer
var account_inset: MarginContainer
var profile_card: PanelContainer
var scroll: ScrollContainer
var notice_path := NOTICE_PATH
static var _switch_icons := {}

func install(target: Control) -> void:
	lobby = target
	var box := lobby.other_settings_panel.get_parent() as VBoxContainer
	var margin := box.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_left", 88)
	margin.add_theme_constant_override("margin_right", 88)
	margin.add_theme_constant_override("margin_top", 84)
	margin.add_theme_constant_override("margin_bottom", 72)
	_install_tab_backdrops()
	box.add_theme_constant_override("separation", 28)
	box.get_node("Title").text = "설정"
	var tabs := box.get_node("Tabs") as HBoxContainer
	tabs.add_theme_constant_override("separation", 12)
	lobby.other_settings_tab_button.text = "소리"
	buttons.sound = lobby.other_settings_tab_button
	buttons.account = lobby.other_account_tab_button
	for entry in TABS:
		if not buttons.has(entry[0]):
			var button := Button.new()
			button.text = entry[1]
			button.custom_minimum_size.y = 102
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tabs.add_child(button)
			buttons[entry[0]] = button
			button.pressed.connect(show_page.bind(entry[0]))
		tabs.move_child(buttons[entry[0]], TABS.find(entry))
		buttons[entry[0]].custom_minimum_size.y = 102
	scroll = ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	box.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	for entry in TABS:
		var page: VBoxContainer
		if entry[0] == "sound":
			page = lobby.other_settings_panel
		elif entry[0] == "account":
			page = lobby.other_account_panel
		else:
			page = VBoxContainer.new()
			page.name = String(entry[0]).capitalize() + "Panel"
		if page.get_parent() != null:
			page.reparent(stack)
		else:
			stack.add_child(page)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_FILL
		page.add_theme_constant_override("separation", 26)
		pages[entry[0]] = page
	_build_game()
	_build_sound()
	_build_notice()
	_build_account()
	_header(pages.misc, "기타", "◇")
	_info(pages.misc, "추가 설정을 위한 공간입니다.\n새 기능은 이곳에 순차적으로 추가됩니다.")
	lobby.get_node("/root/CloudStore").status_changed.connect(_on_cloud_status)
	lobby.get_node("/root/LoginGateway").login_unavailable.connect(_on_cloud_status)
	show_page("game")
	_build_other_menu(box)
	profile_view = preload("res://src/ui/lobby_profile_view.gd").new()
	profile_view.install(self, box)
	hero_codex_view = preload("res://src/ui/lobby_hero_codex_view.gd").new()
	hero_codex_view.install(self,box)
	show_menu()

func _install_tab_backdrops() -> void:
	# The same passive backing belongs to each tab and stays inside its outer rails.
	var background := StyleBoxFlat.new()
	background.bg_color = Color("140d22")
	background.set_corner_radius_all(8)
	for tab in [lobby.other_tab, lobby.team_tab, lobby.research_tab]:
		var backdrop := Panel.new()
		backdrop.name = "OtherContentBackdrop" if tab == lobby.other_tab else "ContentBackdrop"
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(backdrop)
		tab.move_child(backdrop, 0)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.offset_left = 80
		backdrop.offset_top = 80
		backdrop.offset_right = -80
		backdrop.offset_bottom = -80
		backdrop.add_theme_stylebox_override("panel", background)
		if tab == lobby.other_tab:
			other_backdrop = backdrop

func _title_plate(parent: Control, title: Label) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.name = "TitlePlate"
	plate.custom_minimum_size = Vector2(460, 66)
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", FRAMES.style("shop_featured_frame", 8))
	parent.add_child(plate)
	# Match TeamTab/ResearchTab title plaques crossing the upper rail.
	plate.anchor_left = 0.5
	plate.anchor_right = 0.5
	plate.offset_left = -230
	plate.offset_right = 230
	plate.offset_top = 18
	plate.offset_bottom = 84
	if title.get_parent() != null:
		title.reparent(plate)
	else:
		plate.add_child(title)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffe7a3"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return plate

func _build_other_menu(box: VBoxContainer) -> void:
	# Keep all existing settings nodes/signals and move them once into a subpage.
	settings_root = VBoxContainer.new()
	settings_root.name = "SettingsContent"
	settings_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_root.add_theme_constant_override("separation", 20)
	var original := box.get_children()
	box.add_child(settings_root)
	for child in original:
		child.reparent(settings_root)
	var heading := HBoxContainer.new()
	other_navigation = heading
	heading.name = "OtherNavigation"
	heading.add_theme_constant_override("separation", 12)
	# One navigation row shared by every Other subpage, outside their content.
	box.add_child(heading)
	box.move_child(heading, 0)
	other_back_button = Button.new()
	other_back_button.name = "BackToOther"
	other_back_button.text = "‹"
	other_back_button.tooltip_text = "기타 목록으로 돌아가기"
	other_back_button.custom_minimum_size = Vector2(80, 88)
	other_back_button.add_theme_font_size_override("font_size", 54)
	other_back_button.add_theme_color_override("font_color", Color("ffe298"))
	other_back_button.add_theme_color_override("font_hover_color", Color("fff8df"))
	for state in ["normal", "hover", "pressed"]:
		other_back_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	other_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	heading.add_child(other_back_button)
	other_back_button.pressed.connect(show_menu)
	var title := settings_root.get_node("Title") as Label
	settings_title_plate = _title_plate(lobby.other_tab, title)
	settings_title_plate.name = "SettingsTitlePlate"
	other_menu = VBoxContainer.new()
	other_menu.name = "OtherMenu"
	other_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	other_menu.add_theme_constant_override("separation", 24)
	box.add_child(other_menu)
	var menu_title := Label.new()
	menu_title.text = "기타"
	menu_title_plate = _title_plate(lobby.other_tab, menu_title)
	menu_title_plate.name = "OtherTitlePlate"
	var menu_scroll := ScrollContainer.new()
	menu_scroll.name = "OtherMenuScroll"
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	other_menu.add_child(menu_scroll)
	var rows := VBoxContainer.new()
	rows.name = "Categories"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 16)
	menu_scroll.add_child(rows)
	for entry in OTHER_ENTRIES:
		var button := Button.new()
		button.name = String(entry[0]).to_pascal_case()
		button.text = String(entry[1]) + ("  ›" if entry[0] in ["settings", "profile", "practice", "hero_book"] else "\n준비 중")
		button.custom_minimum_size.y = 132
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.disabled = entry[0] not in ["settings", "profile", "practice", "hero_book"]
		button.add_theme_font_size_override("font_size", 30)
		button.add_theme_color_override("font_color", Color("fff0c2"))
		button.add_theme_color_override("font_disabled_color", Color("b9a7c6"))
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 18, Color("ba9dca") if state == "disabled" else Color.WHITE))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		rows.add_child(button)
		other_menu_buttons[entry[0]] = button
		if entry[0] == "settings":
			button.pressed.connect(_open_settings)
		elif entry[0] == "practice":
			button.visible = LocalTestMode.is_practice_allowed()
			button.text = "연습전투  ›\n무한 체력 도망 더미 · 등록한 초월 기술 확인"
			button.pressed.connect(lobby._enter_practice_battle)
		elif entry[0] == "hero_book":
			button.pressed.connect(show_hero_codex)
		elif entry[0] == "profile":
			button.pressed.connect(show_profile)

func show_hero_codex() -> void:
	other_navigation.show()
	settings_root.hide()
	settings_title_plate.hide()
	other_menu.hide()
	menu_title_plate.hide()
	profile_view.hide()
	hero_codex_view.show()

func show_profile() -> void:
	if hero_codex_view != null: hero_codex_view.hide()
	other_navigation.show()
	settings_root.hide()
	settings_title_plate.hide()
	other_menu.hide()
	menu_title_plate.hide()
	profile_view.show()

func _open_settings() -> void:
	show_page(selected)

func show_menu() -> void:
	if hero_codex_view != null: hero_codex_view.hide()
	if other_menu_buttons.has("practice"):
		other_menu_buttons.practice.visible = LocalTestMode.is_practice_allowed()
	if other_menu == null:
		return
	if profile_view != null:
		profile_view.hide()
	settings_root.hide()
	settings_title_plate.hide()
	menu_title_plate.show()
	other_navigation.hide()
	other_menu.show()

func _style(fill: Color, edge: Color, width: int = 2) -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_content_margin_all(16)
	return SKIN.skin_style(style)

func _label(parent: Node, text: String, font_size: int, color := Color("f2edf9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _space(parent: Node, height := 20) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)

func _line(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = Color(0.60, 0.40, 0.74, 0.42)
	line.custom_minimum_size.y = 2
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _header(parent: Node, text: String, icon: String) -> void:
	_space(parent, 34)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var glyph := _label(row, icon, 48, Color("eac14d"))
	glyph.custom_minimum_size.x = 60
	glyph.size_flags_horizontal = Control.SIZE_FILL
	_label(row, text, 44, Color("f4d174"))
	_line(parent)

func _info(parent: Node, text: String) -> void:
	_space(parent, 20)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.03, 0.10, 0.80), Color("705885")))
	parent.add_child(panel)
	_label(panel, text, 25, Color("c9b9dd"))

func _toggle(parent: Node, title: String, description: String, check: CheckBox = null) -> CheckBox:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 142
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 12)
	row.add_child(text_box)
	_label(text_box, title, 34)
	_label(text_box, description, 26, Color("bcb0ce"))
	if check == null:
		check = CheckBox.new()
		row.add_child(check)
	else:
		check.reparent(row)
	check.text = ""
	check.custom_minimum_size = Vector2(156, 84)
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check.add_theme_constant_override("check_v_offset", 0)
	for state in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
		check.add_theme_icon_override(state, _toggle_icon(state.begins_with("checked"), state.ends_with("disabled")))
	var state_label := Label.new()
	state_label.name = "State"
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 25)
	state_label.size = Vector2(68, 76)
	check.add_child(state_label)
	var update_state := func(_enabled: bool = false) -> void:
		state_label.text = "ON" if check.button_pressed else "OFF"
		state_label.position = Vector2(8 if check.button_pressed else 78, (check.size.y - 76) * 0.5)
		state_label.modulate.a = 0.4 if check.disabled else 1.0
		check.tooltip_text = title + (" · 켜짐" if check.button_pressed else " · 꺼짐")
	check.toggled.connect(update_state)
	check.resized.connect(update_state)
	update_state.call()
	_line(parent)
	return check

func _toggle_icon(on: bool, disabled: bool) -> Texture2D:
	var key := "%s:%s" % [on, disabled]
	if _switch_icons.has(key):
		return _switch_icons[key]
	var fill := "793ac1" if on else "282235"
	var rim := "efce65" if on else "756c89"
	var thumb_x := 118 if on else 34
	var opacity := "0.40" if disabled else "1"
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="152" height="76"><g opacity="%s"><rect x="3" y="7" width="146" height="62" rx="31" fill="#%s" stroke="#%s" stroke-width="3"/><circle cx="%d" cy="38" r="23" fill="%s" stroke="#b9a0dd" stroke-width="2"/></g></svg>' % [opacity, fill, rim, thumb_x, "#f1e7ff" if on else "#81778e"]
	var image := Image.new()
	image.load_svg_from_string(svg)
	var texture := ImageTexture.create_from_image(image)
	_switch_icons[key] = texture
	return texture

func _build_game() -> void:
	var page: VBoxContainer = pages.game
	_header(page, "게임 플레이", "◇")
	for option in GAME_OPTIONS:
		game_checks[option.key] = _toggle(page, option.title, option.description)
	for key in game_checks:
		game_checks[key].toggled.connect(_save_game.bind(key))
	_info(page, "게임 옵션은 자동 저장되며 다음 전투에도 적용됩니다.")

func _save_game(value: bool, key: String) -> void:
	var config := ConfigFile.new()
	config.load(lobby.gameplay_settings_path)
	config.set_value("gameplay", key, value)
	if config.save(lobby.gameplay_settings_path) != OK:
		_sync_game()

func _sync_game() -> void:
	var config := ConfigFile.new()
	config.load(lobby.gameplay_settings_path)
	for option in GAME_OPTIONS:
		game_checks[option.key].set_pressed_no_signal(bool(config.get_value("gameplay", option.key, option["default"])))

func _build_sound() -> void:
	var page: VBoxContainer = pages.sound
	page.add_theme_constant_override("separation", 12)
	# Keep original controls and signal bindings, replace only their layout.
	var keep := [lobby.bgm_slider, lobby.bgm_value_label, lobby.sfx_slider, lobby.sfx_value_label, lobby.bgm_mute_check, lobby.sfx_mute_check]
	for node in keep:
		node.reparent(lobby)
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	_header(page, "오디오", "♪")
	_volume(page, "배경음", "게임의 배경음악 볼륨을 조절합니다.", lobby.bgm_slider, lobby.bgm_value_label)
	_volume(page, "효과음", "스킬, 전투 등 효과음 볼륨을 조절합니다.", lobby.sfx_slider, lobby.sfx_value_label)
	_space(page, 22)
	_toggle(page, "배경음 끄기", "배경음악을 재생하지 않습니다.", lobby.bgm_mute_check)
	_toggle(page, "효과음 끄기", "효과음을 재생하지 않습니다.", lobby.sfx_mute_check)
	_info(page, "음량은 1~10 단계로 저장되며, 변경 즉시 적용됩니다.")

func _volume(parent: Node, title: String, description: String, slider: HSlider, value: Label) -> void:
	_label(parent, title, 36)
	_label(parent, description, 26, Color("bcb0ce"))
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 94
	row.add_theme_constant_override("separation", 30)
	parent.add_child(row)
	var slider_margin := MarginContainer.new()
	slider_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_margin.add_theme_constant_override("margin_left", 32)
	slider_margin.add_theme_constant_override("margin_right", 32)
	row.add_child(slider_margin)
	slider.reparent(slider_margin)
	slider.custom_minimum_size = Vector2(0, 86)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.add_theme_stylebox_override("slider", _style(Color("191221"), Color("9f7d3e")))
	slider.add_theme_stylebox_override("grabber_area", _style(Color("8543c8"), Color("b886ec")))
	slider.add_theme_stylebox_override("grabber_area_highlight", _style(Color("a458ed"), Color("e3b7ff")))
	# Native slider retains input/keyboard/accessibility; illustrated thumb is passive.
	var empty := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty.fill(Color.TRANSPARENT)
	var texture := ImageTexture.create_from_image(empty)
	for key in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(key, texture)
	var thumb := TextureRect.new()
	thumb.name = "GemThumb"
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	thumb.texture = PresentationWarmup.get_texture("res://assets/art/UI/settings_v2/amethyst_thumb.png")
	thumb.size = Vector2(74, 74)
	slider.add_child(thumb)
	var position_thumb := func(_value: float = 0.0) -> void:
		var ratio := (slider.value - slider.min_value) / (slider.max_value - slider.min_value)
		thumb.position = Vector2(ratio * slider.size.x - 37, (slider.size.y - 74) * 0.5)
	slider.value_changed.connect(position_thumb)
	slider.resized.connect(position_thumb)
	position_thumb.call()
	value.reparent(row)
	value.custom_minimum_size = Vector2(108, 82)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 40)
	value.add_theme_stylebox_override("normal", _style(Color("130e21"), Color("867098")))
	_line(parent)

func _build_notice() -> void:
	_header(pages.notice, "알림 동의", "◇")
	notice_checks.push_enabled = _toggle(pages.notice, "게임 푸시 알림 동의", "게임 소식과 주요 알림 수신에 동의합니다.")
	notice_checks.lunch_enabled = _toggle(pages.notice, "점심 알림 동의", "점심 시간대 게임 알림 수신에 동의합니다.")
	notice_checks.dinner_enabled = _toggle(pages.notice, "저녁 알림 동의", "저녁 시간대 게임 알림 수신에 동의합니다.")
	for key in notice_checks:
		notice_checks[key].toggled.connect(_save_notice.bind(key))
	_info(pages.notice, "동의 설정만 이 기기에 저장됩니다.\n실제 푸시 발송 및 운영체제 권한 연결은 준비 중입니다.")

func _save_notice(value: bool, key: String) -> void:
	var config := ConfigFile.new()
	config.load(notice_path)
	config.set_value("notifications", key, value)
	if config.save(notice_path) != OK:
		_sync_notice()
	_refresh_notice_dependencies()

func _sync_notice() -> void:
	var config := ConfigFile.new()
	config.load(notice_path)
	for key in notice_checks:
		notice_checks[key].set_pressed_no_signal(bool(config.get_value("notifications", key, false)))
	_refresh_notice_dependencies()

func _refresh_notice_dependencies() -> void:
	var enabled: bool = notice_checks.push_enabled.button_pressed
	notice_checks.lunch_enabled.disabled = not enabled
	notice_checks.dinner_enabled.disabled = not enabled
	for check in notice_checks.values():
		check.resized.emit()

func _build_account() -> void:
	var page: VBoxContainer = pages.account
	page.get_node("AccountTitle").hide()
	var guide: Label = page.get_node("Guide")
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	guide.add_theme_font_size_override("font_size", 26)
	# Keep this title outside the clipped/scrolling body, including while dragging.
	account_heading = MarginContainer.new()
	account_heading.name = "AccountHeading"
	for side in ["left", "right"]:
		account_heading.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		account_heading.add_theme_constant_override("margin_" + side, 16)
	scroll.get_parent().add_child(account_heading)
	scroll.get_parent().move_child(account_heading, scroll.get_index())
	var heading_row := HBoxContainer.new()
	heading_row.custom_minimum_size.y = 60
	heading_row.add_theme_constant_override("separation", 24)
	account_heading.add_child(heading_row)
	var heading_icon := _label(heading_row, "◇", 44, Color("eac14d"))
	heading_icon.custom_minimum_size.x = 60
	heading_icon.size_flags_horizontal = Control.SIZE_FILL
	_label(heading_row, "계정 및 저장", 44, Color("f4d174"))
	account_inset = MarginContainer.new()
	account_inset.name = "AccountContentInset"
	account_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		account_inset.add_theme_constant_override("margin_" + side, 28)
	account_inset.add_theme_constant_override("margin_top", 18)
	account_inset.add_theme_constant_override("margin_bottom", 32)
	page.get_parent().add_child(account_inset)
	page.reparent(account_inset)
	account_identity = _label(page, "", 34)
	page.move_child(account_identity, 0)
	cloud_status = _label(page, "", 28, Color("d6bbf4"))
	page.move_child(cloud_status, 1)
	profile_card = PanelContainer.new()
	profile_card.name = "DemonProfileCard"
	profile_card.add_theme_stylebox_override("panel", _style(Color(0.07, 0.035, 0.12, 0.88), Color("705885")))
	page.add_child(profile_card)
	page.move_child(profile_card, 2)
	var profile_padding := MarginContainer.new()
	for side in ["left", "right"]:
		profile_padding.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		profile_padding.add_theme_constant_override("margin_" + side, 16)
	profile_card.add_child(profile_padding)
	var profile_center := CenterContainer.new()
	profile_padding.add_child(profile_center)
	var profile_row := HBoxContainer.new()
	profile_row.name = "DemonProfile"
	profile_row.add_theme_constant_override("separation", 36)
	profile_center.add_child(profile_row)
	profile_avatar_frame = PanelContainer.new()
	profile_avatar_frame.name = "ProfileAvatarFrame"
	profile_avatar_frame.custom_minimum_size = Vector2(212, 212)
	profile_avatar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_avatar_frame.add_theme_stylebox_override("panel", _style(Color("21102f"), Color("eac14d"), 3))
	profile_row.add_child(profile_avatar_frame)
	profile_portrait = TextureRect.new()
	profile_portrait.name = "ProfileAvatarImage"
	profile_portrait.custom_minimum_size = Vector2(180, 180)
	profile_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	profile_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	profile_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	profile_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_avatar_frame.add_child(profile_portrait)
	profile_label = _label(profile_row, "", 30)
	profile_label.custom_minimum_size.x = 380
	profile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	profile_setup = Button.new()
	profile_setup.text = "마왕 프로필 설정"
	profile_setup.custom_minimum_size.y = 88
	profile_setup.add_theme_font_size_override("font_size", 30)
	page.add_child(profile_setup)
	page.move_child(profile_setup, 3)
	SKIN.apply(profile_setup)
	profile_setup.pressed.connect(_open_profile)
	for name in ["KakaoLogin", "GoogleLogin", "CouponButton"]:
		var button := page.get_node(name) as Button
		button.custom_minimum_size.y = 104
		button.add_theme_font_size_override("font_size", 30)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, _style(Color("28163e"), Color("b5964b")))
	_info(page, "게스트 진행은 이 기기에만 저장됩니다.\n계정 변경 전에는 현재 진행도의 저장을 확인합니다.")
	var withdrawal := Button.new()
	withdrawal.name = "AccountWithdrawal"
	withdrawal.text = "계정 탈퇴 · 준비 중"
	withdrawal.disabled = true
	withdrawal.tooltip_text = "아직 탈퇴 기능이 연결되지 않았습니다. 계정이나 저장 데이터는 삭제되지 않습니다."
	withdrawal.custom_minimum_size.y = 88
	withdrawal.add_theme_font_size_override("font_size", 28)
	page.add_child(withdrawal)
	SKIN.apply(withdrawal)

func _open_profile() -> void:
	var gateway := lobby.get_node("/root/LoginGateway")
	if gateway.user_id.is_empty() or not String(PROFILE.get_profile().get("nickname", "")).is_empty() or profile_setup.disabled:
		return
	profile_setup.disabled = true
	var view := PROLOGUE.new()
	lobby.add_child(view)
	view.finished.connect(func(): view.queue_free(); _sync_account())

func _on_cloud_status(_message: String) -> void:
	_sync_account()

func set_profile_avatar(texture: Texture2D) -> void:
	# Display-only preview hook. Profile view owns saved representative selection.
	profile_portrait.texture = texture

func _sync_account() -> void:
	var gateway := lobby.get_node("/root/LoginGateway")
	var cloud := lobby.get_node("/root/CloudStore")
	var mode := lobby.get_node("/root/LocalTestMode")
	var guest: bool = gateway.user_id.is_empty()
	var profile := PROFILE.get_profile()
	var nickname := String(profile.get("nickname", ""))
	profile_label.text = "내 마왕 프로필\n%s\n%s" % [PROFILE.display_name(), "여성" if profile.get("gender", "male") == "female" else "남성"] if not nickname.is_empty() else "내 마왕 프로필\n미설정"
	set_profile_avatar(load(PROFILE_CATALOG.path(PROFILE_COSMETICS.selected_id("avatar"), "avatar")) as Texture2D)
	profile_portrait.visible = not nickname.is_empty()
	profile_avatar_frame.visible = not nickname.is_empty()
	profile_setup.visible = nickname.is_empty() and not guest and not mode.active
	profile_setup.disabled = cloud.busy or gateway.access_token.is_empty()
	var testing: bool = mode.active or mode.tutorial_preview
	account_identity.text = "첫 가입 테스트 · 로컬 전용" if mode.tutorial_preview else ("로컬 테스트 모드" if mode.active else gateway.get_account_display())
	if mode.active or guest:
		cloud_status.text = "클라우드 연결 안 됨 · 기기 저장"
	elif cloud.conflict:
		cloud_status.text = "클라우드 저장 충돌 · 확인 필요"
	elif cloud.busy:
		cloud_status.text = "클라우드 동기화 중…"
	elif gateway.access_token.is_empty():
		cloud_status.text = "인증 만료 · 다시 로그인 필요"
	else:
		cloud_status.text = "클라우드 저장 사용 중" if cloud.ready_for_play else "클라우드 연결 확인 필요"
	pages.account.get_node("KakaoLogin").disabled = guest or mode.active or cloud.busy or gateway.access_token.is_empty()
	pages.account.get_node("GoogleLogin").text = "계정 로그인" if guest else "로그아웃 / 계정 변경"
	pages.account.get_node("GoogleLogin").disabled = testing or cloud.busy
	if testing:
		pages.account.get_node("Guide").text = "일반 계정 로그인은 normaltest 쿠폰으로 테스트 모드 종료 후 가능합니다."
	if profile_view != null:
		profile_view.refresh()

func show_page(id: String) -> void:
	if not pages.has(id):
		return
	if hero_codex_view != null: hero_codex_view.hide()
	if profile_view != null:
		profile_view.hide()
	if settings_root != null:
		other_menu.hide()
		menu_title_plate.hide()
		settings_title_plate.show()
		settings_root.show()
		other_navigation.show()
	var changing := selected != id
	selected = id
	account_heading.visible = id == "account"
	account_inset.visible = id == "account"
	for key in pages:
		pages[key].visible = key == id
		var button: Button = buttons[key]
		var active: bool = key == id
		button.disabled = false
		button.add_theme_font_size_override("font_size", 31)
		button.add_theme_color_override("font_color", Color("ffdf77") if active else Color("d5c9e4"))
		var style := _style(Color("7031a8") if active else Color("171021"), Color("f7ce59") if active else Color("796983"), 3 if active else 2)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, style)
	if changing:
		scroll.scroll_vertical = 0
	_sync_game()
	_sync_notice()
	lobby._sync_audio_settings_ui()
	for slider in [lobby.bgm_slider, lobby.sfx_slider]:
		slider.resized.emit()
	_sync_account()
	for check in game_checks.values() + [lobby.bgm_mute_check, lobby.sfx_mute_check]:
		check.resized.emit()
