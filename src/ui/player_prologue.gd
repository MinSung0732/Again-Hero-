extends Control

signal finished
const DATA := preload("res://src/data/prologue_catalog.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const VIEW := preload("res://src/ui/startup_loading_view.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const CHAMBER := preload("res://assets/art/UI/prologue/ruined_throne.png")
const MALE := preload("res://assets/art/demonking/demonking_portrait_male.png")
const FEMALE := preload("res://assets/art/demonking/demonking_portrait_female.png")
var cloud: Node
var background: TextureRect
var portrait: TextureRect
var speaker: Label
var text_label: Label
var hint: Label
var choice: Panel
var name_input: LineEdit
var dice: Button
var confirm: Button
var error_label: Label
var _name_scroll: ScrollContainer
var _name_content: Control
var _name_screen_bottom := 0.0
var _name_layout_size := Vector2.ZERO
var _name_layout_height := -1.0
var _name_keyboard_seen := false
const NAME_CONTENT_HEIGHT := 460.0
var gender := "male"
var nickname := ""
var index := 0
var busy := false
var _typing_time := 0.0
var _last_tap := -1000
var _fade: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	cloud = get_node("/root/CloudStore") if cloud == null else cloud
	var black := ColorRect.new()
	black.color = Color.BLACK
	VIEW.place(self, black, Rect2(0, 0, 1, 1))
	background = VIEW.texture(self, CHAMBER, Rect2(0, 0, 1, 1), true)
	background.modulate.a = 0
	portrait = VIEW.texture(self, MALE, Rect2(0.06, 0.16, 0.88, 0.62))
	portrait.hide()
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", VIEW.plate(Color(0.035, 0.018, 0.065, 0.97)))
	VIEW.place(self, panel, Rect2(0.06, 0.76, 0.88, 0.20))
	SKIN.apply(panel)
	speaker = VIEW.label(panel, "마왕", 36, Rect2(0.07, 0.08, 0.86, 0.18), Color("ffda78"))
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label = VIEW.label(panel, "", 38, Rect2(0.07, 0.30, 0.86, 0.48))
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint = VIEW.label(panel, "터치하여 계속  ▸", 24, Rect2(0.07, 0.80, 0.86, 0.13), Color("b6a0c7"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gui_input.connect(_on_input)
	var saved := PROFILE.get_profile()
	nickname = String(saved.get("nickname", ""))
	gender = String(saved.get("gender", "male"))
	if not nickname.is_empty():
		index = DATA.AFTER_REGISTRATION
		background.modulate.a = 0.55
		_reveal_portrait()
	_show_line()

func _process(delta: float) -> void:
	if is_instance_valid(_name_scroll):
		_update_name_layout()
	if busy or is_instance_valid(choice) or text_label.visible_characters < 0:
		return
	_typing_time += delta
	var interval := 0.065 if text_label.text.contains("……") else 0.035
	while _typing_time >= interval:
		_typing_time -= interval
		text_label.visible_characters += 1
		if text_label.visible_characters >= text_label.get_total_character_count():
			text_label.visible_characters = -1
			break

func _on_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) or (event is InputEventScreenTouch and not event.pressed and not event.canceled):
		advance()
		accept_event()

func advance() -> void:
	if busy or is_instance_valid(choice) or Time.get_ticks_msec() - _last_tap < 160:
		return
	_last_tap = Time.get_ticks_msec()
	if text_label.visible_characters >= 0:
		text_label.visible_characters = -1
		return
	if String(DATA.LINES[index].get("kind", "")) == "ending":
		_finish()
		return
	index += 1
	_show_line()

func _show_line() -> void:
	var line: Dictionary = DATA.LINES[index]
	var kind := String(line.get("kind", "demon"))
	if line.has("light"):
		if _fade:
			_fade.kill()
		_fade = create_tween()
		_fade.tween_property(background, "modulate:a", float(line.light), 0.8)
	if kind in ["gender", "name"]:
		text_label.visible_characters = -1
		text_label.text = "나는 분명—" if kind == "gender" else "내 이름은—"
		hint.text = "성별을 선택해 주세요" if kind == "gender" else "이름을 결정해 주세요"
		_build_choice(kind)
		return
	speaker.text = ("마왕(%s)" % nickname if not nickname.is_empty() else "마왕") if kind == "demon" else ""
	text_label.text = String(line.get("text", "")).replace("{nickname}", nickname)
	text_label.visible_characters = 0
	_typing_time = 0
	hint.text = "터치하여 마왕의 성으로  ▸" if kind == "ending" else "터치하여 계속  ▸"

func _button(parent: Control, title: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = title
	button.add_theme_font_size_override("font_size", 34)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, VIEW.plate(Color("482264") if state != "disabled" else Color("21172b")))
	VIEW.place(parent, button, rect)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	SKIN.apply(button)
	return button

func _build_choice(kind: String) -> void:
	choice = Panel.new()
	choice.mouse_filter = Control.MOUSE_FILTER_STOP
	choice.add_theme_stylebox_override("panel", VIEW.plate(Color(0.055, 0.025, 0.095, 0.98)))
	VIEW.place(self, choice, Rect2(0.10, 0.43, 0.80, 0.28))
	choice.mouse_filter = Control.MOUSE_FILTER_STOP
	SKIN.apply(choice)
	if kind == "gender":
		VIEW.label(choice, "마왕의 성별을 선택하세요", 37, Rect2(0.07, 0.07, 0.86, 0.18), Color("ffdf8a"))
		_button(choice, "남성", Rect2(0.08, 0.40, 0.40, 0.28)).pressed.connect(_select_gender.bind("male"))
		_button(choice, "여성", Rect2(0.52, 0.40, 0.40, 0.28)).pressed.connect(_select_gender.bind("female"))
		VIEW.label(choice, "선택한 모습으로 이후 대사에 등장합니다.", 25, Rect2(0.05, 0.76, 0.90, 0.13), Color("cbb6df"))
		return
	# Keep a readable content height; only the viewport shrinks for tall keyboards.
	_name_scroll = ScrollContainer.new()
	VIEW.place(choice, _name_scroll, Rect2(0, 0, 1, 1))
	_name_scroll.offset_left = 20
	_name_scroll.offset_top = 16
	_name_scroll.offset_right = -20
	_name_scroll.offset_bottom = -16
	_name_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_name_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_name_content = Control.new()
	_name_content.custom_minimum_size.y = NAME_CONTENT_HEIGHT
	_name_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_name_scroll.add_child(_name_content)
	VIEW.label(_name_content, "마왕의 이름을 입력하세요", 37, Rect2(0.07, 0.07, 0.86, 0.18), Color("ffdf8a"))
	name_input = LineEdit.new()
	name_input.max_length = 6
	name_input.placeholder_text = "최대 6글자"
	name_input.add_theme_font_size_override("font_size", 36)
	VIEW.place(_name_content, name_input, Rect2(0.08, 0.31, 0.68, 0.19))
	SKIN.apply(name_input)
	name_input.mouse_filter = Control.MOUSE_FILTER_STOP
	dice = _button(_name_content, "⚄", Rect2(0.79, 0.31, 0.13, 0.19))
	dice.tooltip_text = "무작위 테스트 이름 (서버 등록 없음)" if PROFILE._preview() else "무작위 닉네임 (결정 시 중복 검사)"
	dice.pressed.connect(func(): name_input.text = PROFILE.random_name(name_input.text); _validate_name(name_input.text))
	confirm = _button(_name_content, "결정", Rect2(0.25, 0.70, 0.50, 0.19))
	confirm.disabled = true
	confirm.pressed.connect(_register_name)
	error_label = VIEW.label(_name_content, "한글·영문·숫자 1~6글자 · 중복 불가", 24, Rect2(0.04, 0.52, 0.92, 0.16), Color("cbb6df"))
	name_input.text_changed.connect(_validate_name)
	name_input.text_submitted.connect(func(_text: String): _register_name())
	name_input.focus_entered.connect(func(): _name_keyboard_seen = false)
	# Capture the unobscured bottom before focus can resize the Android window.
	_name_screen_bottom = (get_viewport().get_screen_transform() * (get_global_transform_with_canvas() * Vector2(0, size.y))).y
	_name_layout_height = -1.0
	name_input.grab_focus()
	_update_name_layout()
	_validate_name(name_input.text)

static func keyboard_available_height(local_height: float, screen_top: float, screen_scale: float, screen_bottom: float, keyboard_pixels: float) -> float:
	# Keyboard height is physical pixels, unlike stretched canvas coordinates.
	# min also handles OS resize: do not subtract the keyboard a second time.
	return clampf((screen_bottom - keyboard_pixels - screen_top) / maxf(screen_scale, 0.001), 0.0, local_height)

static func name_choice_rect(view_size: Vector2, available_height: float, editing: bool) -> Rect2:
	if not editing:
		return Rect2(view_size * Vector2(0.10, 0.43), view_size * Vector2(0.80, 0.28))
	var margin := minf(24.0, available_height * 0.05)
	var height := minf(NAME_CONTENT_HEIGHT + 32.0, available_height - margin * 2.0)
	return Rect2(view_size.x * 0.10, maxf(margin, (available_height - height) * 0.5), view_size.x * 0.80, maxf(0.0, height))

func _update_name_layout() -> void:
	var screen_transform := get_viewport().get_screen_transform() * get_global_transform_with_canvas()
	var screen_top := (screen_transform * Vector2.ZERO).y
	var scale_y := screen_transform.y.length()
	var keyboard_pixels := float(DisplayServer.virtual_keyboard_get_height()) if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0.0
	var mobile_focus := OS.has_feature("mobile") and name_input.has_focus()
	if keyboard_pixels > 0.0:
		_name_keyboard_seen = true
	if keyboard_pixels <= 0.0 and (not mobile_focus or _name_keyboard_seen):
		_name_screen_bottom = (screen_transform * Vector2(0, size.y)).y
	var available := keyboard_available_height(size.y, screen_top, scale_y, _name_screen_bottom, keyboard_pixels)
	# Some Android keyboards initially report zero. Put the focused form in the
	# upper half until a real inset arrives, keeping entry usable on those devices.
	var waiting_for_keyboard := mobile_focus and not _name_keyboard_seen
	if keyboard_pixels <= 0.0 and waiting_for_keyboard:
		available = minf(available, size.y * 0.5)
	_apply_name_layout(available, keyboard_pixels > 0.0 or waiting_for_keyboard)

func _apply_name_layout(available_height: float, editing: bool) -> void:
	var rect := name_choice_rect(size, available_height, editing)
	if _name_layout_size == size and is_equal_approx(_name_layout_height, rect.position.y) and choice.size == rect.size:
		return
	_name_layout_size = size
	_name_layout_height = rect.position.y
	choice.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	choice.position = rect.position
	choice.size = rect.size
	if editing:
		_name_scroll.call_deferred("ensure_control_visible", name_input)

func _validate_name(value: String) -> void:
	confirm.disabled = busy or not PROFILE.valid_name(value)
	error_label.text = "한글·영문·숫자 1~6글자 · 결정 시 중복 검사"
	if PROFILE._preview():
		error_label.text = "로컬 테스트 이름 · 서버 등록/중복 검사 없음"

func _select_gender(value: String) -> void:
	if busy or not is_instance_valid(choice) or String(DATA.LINES[index].get("kind", "")) != "gender":
		return
	gender = value
	_close_choice()
	_reveal_portrait()
	index += 1
	_show_line()

func _reveal_portrait() -> void:
	# Before registration the explicit gender choice owns the reveal. On resume
	# the saved cosmetic owns it, just like every later dialogue.
	portrait.texture = load(PROFILE.portrait_path()) if not nickname.is_empty() else (FEMALE if gender == "female" else MALE)
	portrait.show()
	portrait.modulate.a = 0
	create_tween().tween_property(portrait, "modulate:a", 1.0, 0.8)

func _close_choice() -> void:
	if is_instance_valid(_name_scroll):
		name_input.release_focus()
		if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
			DisplayServer.virtual_keyboard_hide()
		_name_scroll = null
		_name_content = null
	var old := choice
	choice = null
	old.hide()
	old.queue_free()
	_last_tap = Time.get_ticks_msec()

func _register_name() -> void:
	if busy or not is_instance_valid(choice) or not is_instance_valid(confirm) or confirm.disabled:
		return
	busy = true
	confirm.disabled = true
	dice.disabled = true
	name_input.editable = false
	error_label.text = "테스트 프로필 로컬 저장 중…" if PROFILE._preview() else "중복 확인 및 프로필 저장 중…"
	var result := await PROFILE.register(cloud, name_input.text, gender)
	if not is_inside_tree():
		return
	busy = false
	if not bool(result.get("ok", false)):
		dice.disabled = false
		name_input.editable = true
		confirm.disabled = not PROFILE.valid_name(name_input.text)
		error_label.text = "이미 사용 중인 이름입니다. 다른 이름을 골라 주세요." if result.get("error") == "duplicate" else "저장하지 못했습니다. 연결 확인 후 다시 결정해 주세요."
		return
	nickname = String(result.profile.nickname)
	_close_choice()
	index += 1
	_show_line()

func _finish() -> void:
	if busy:
		return
	busy = true
	hint.text = "귀환 기록 저장 중…"
	var saved := await PROFILE.complete(cloud)
	if not is_inside_tree():
		return
	busy = false
	if not saved:
		hint.text = "저장 실패 · 터치하여 다시 시도"
		return
	busy = true # No second completion while the caller removes this screen.
	finished.emit()
