extends Control

const VIEW := preload("res://src/ui/startup_loading_view.gd")
var host: Control
var login_action: Callable
var panel: PanelContainer
var pages := {}
var tab_buttons := {}
var account_label: Label
var audio_controls := {}

func install(target: Control, action: Callable) -> void:
	host = target
	login_action = action
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0,0,0,0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(dim)
	panel = PanelContainer.new(); panel.add_theme_stylebox_override("panel",VIEW.plate(Color("171024")))
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	panel.add_child(margin)
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation",18); margin.add_child(rows)
	var heading := HBoxContainer.new(); rows.add_child(heading)
	var title := _label(heading,"옵션",38); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading,"닫기",close)
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation",16); rows.add_child(tabs)
	for id in ["sound","account"]:
		tab_buttons[id] = _button(tabs,"사운드" if id == "sound" else "계정",_show_page.bind(id))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; rows.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(body)
	for id in ["sound","account"]:
		var page := VBoxContainer.new(); page.add_theme_constant_override("separation",20)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(page); pages[id] = page
	_build_sound(); _build_account()
	resized.connect(_fit); _fit(); hide()

func _label(parent: Node, text: String, font_size: int = 28) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",Color("f4e4ff"))
	parent.add_child(label); return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(100,82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.add_theme_font_size_override("font_size",28)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,VIEW.plate(Color("432354")))
	button.pressed.connect(action); parent.add_child(button); return button

func _build_sound() -> void:
	_label(pages.sound,"음량은 즉시 적용되고 이 기기에 저장됩니다.")
	for id in ["bgm","sfx"]:
		var title := "배경음" if id == "bgm" else "효과음"
		var row := VBoxContainer.new(); row.add_theme_constant_override("separation",12); pages.sound.add_child(row)
		var value := _label(row,title,32)
		var slider := HSlider.new(); slider.min_value = AudioSettings.MIN_LEVEL; slider.max_value = AudioSettings.MAX_LEVEL
		slider.step = 1; slider.custom_minimum_size.y = 84; slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var mute := CheckButton.new(); mute.text = title+" 끄기"; mute.custom_minimum_size.y = 82
		mute.add_theme_font_size_override("font_size",28); row.add_child(mute)
		audio_controls[id] = {"slider":slider,"value":value,"mute":mute,"title":title}
		slider.value_changed.connect(_volume.bind(id))
		mute.toggled.connect(_mute.bind(id))

func _volume(value: float, id: String) -> void:
	if id == "bgm": AudioSettings.set_bgm_level(roundi(value))
	else: AudioSettings.set_sfx_level(roundi(value))
	audio_controls[id].value.text = "%s  %d / 10" % [audio_controls[id].title,roundi(value)]

func _mute(value: bool, id: String) -> void:
	if id == "bgm": AudioSettings.set_bgm_muted(value)
	else: AudioSettings.set_sfx_muted(value)

func _build_account() -> void:
	account_label = _label(pages.account,"",32)
	_label(pages.account,"Google 또는 카카오로 기존 계정에 로그인할 수 있습니다.\n게스트 진행도는 이 기기에 저장됩니다.\n계정 연동·프로필 변경은 로비의 계정 설정에서 이용하세요.")
	_button(pages.account,"로그인 화면으로",_go_to_login)

func _go_to_login() -> void:
	close()
	if login_action.is_valid(): login_action.call()

func _show_page(id: String) -> void:
	for key in pages:
		pages[key].visible = key == id
		tab_buttons[key].disabled = key == id

func open() -> void:
	for id in audio_controls:
		var control: Dictionary = audio_controls[id]
		var level: int = AudioSettings.bgm_level if id == "bgm" else AudioSettings.sfx_level
		control.slider.set_value_no_signal(level)
		control.mute.set_pressed_no_signal(AudioSettings.bgm_muted if id == "bgm" else AudioSettings.sfx_muted)
		control.value.text = "%s  %d / 10" % [control.title,level]
	account_label.text = "로그인 전" if LoginGateway.user_id.is_empty() and not LoginGateway.local_guest_active else LoginGateway.get_account_display()
	_show_page("sound"); show(); move_to_front(); _fit(); tab_buttons.account.grab_focus()

func close() -> void:
	hide()
	if is_instance_valid(host.options_button): host.options_button.grab_focus()

func _fit() -> void:
	if panel == null: return
	var width := maxf(240,minf(860,size.x-48))
	var height := maxf(300,minf(860,size.y-48))
	panel.position = (size-Vector2(width,height))*0.5
	panel.size = Vector2(width,height)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close(); get_viewport().set_input_as_handled()
