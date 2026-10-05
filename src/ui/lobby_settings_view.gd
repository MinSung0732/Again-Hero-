extends RefCounted

const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const NOTICE_PATH := "user://notification_settings.cfg"
const TABS := [["game", "게임"], ["sound", "소리"], ["notice", "알림"], ["account", "계정"], ["misc", "기타"]]
const GAME_OPTIONS := [
	{"key": "camera_view_locked", "title": "화면 고정", "description": "켜면 용사를 따라갑니다. 끄면 드래그로 화면을 이동합니다.", "default": true},
	{"key": "battle_frame_enabled", "title": "배틀 프레임", "description": "전장 주변의 마왕성 장식 프레임을 표시합니다.", "default": true},
]
var lobby: Control
var buttons := {}
var pages := {}
var selected := "game"
var game_checks := {}
var notice_checks := {}
var account_identity: Label
var cloud_status: Label
var scroll: ScrollContainer
var notice_path := NOTICE_PATH
static var _switch_icons := {}

func install(target: Control) -> void:
	lobby = target
	var box := lobby.other_settings_panel.get_parent() as VBoxContainer
	var margin := box.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_bottom", 72)
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
	page.add_theme_constant_override("separation", 16)
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
	_header(page, "계정 및 저장", "◇")
	var header_children: Array[Node] = page.get_children().slice(-3)
	for i in range(header_children.size()):
		page.move_child(header_children[i], i)
	account_identity = _label(page, "", 34)
	page.move_child(account_identity, 3)
	cloud_status = _label(page, "", 28, Color("d6bbf4"))
	page.move_child(cloud_status, 4)
	for name in ["KakaoLogin", "GoogleLogin", "CouponButton"]:
		var button := page.get_node(name) as Button
		button.custom_minimum_size.y = 104
		button.add_theme_font_size_override("font_size", 30)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, _style(Color("28163e"), Color("b5964b")))
	_info(page, "게스트 진행은 이 기기에만 저장됩니다.\n계정 변경 전에는 현재 진행도의 저장을 확인합니다.")

func _on_cloud_status(_message: String) -> void:
	_sync_account()

func _sync_account() -> void:
	var gateway := lobby.get_node("/root/LoginGateway")
	var cloud := lobby.get_node("/root/CloudStore")
	var mode := lobby.get_node("/root/LocalTestMode")
	var guest: bool = gateway.user_id.is_empty()
	account_identity.text = "로컬 테스트 모드" if mode.active else gateway.get_account_display()
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
	pages.account.get_node("GoogleLogin").disabled = mode.active or cloud.busy
	if mode.active:
		pages.account.get_node("Guide").text = "일반 계정 로그인은 normaltest 쿠폰으로 테스트 모드 종료 후 가능합니다."

func show_page(id: String) -> void:
	if not pages.has(id):
		return
	var changing := selected != id
	selected = id
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
