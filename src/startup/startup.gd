extends Control

const CATALOG := preload("res://src/data/startup_catalog.gd")
const VIEW := preload("res://src/ui/startup_loading_view.gd")
const PIXEL_FRAME := preload("res://src/ui/battle_pixel_frame_assembler.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
enum Phase { TITLE, RESOURCES, LOADING, LOGIN, ENTERING, ERROR, PROLOGUE }

var phase := Phase.TITLE
var title_screen: Control
var login_screen: Control
var loading_view: Control
var start_button: Button
var guest_button: Button
var status_label: Label
var retry_button: Button
var _pulse: Tween
var _resources: Array[Resource] = []
var _lobby: PackedScene
var _entering := false
var prologue: Control
var profile_cloud: Node # Optional isolated test transport; production uses CloudStore.


func _ready() -> void:
	_build_title()
	loading_view = VIEW.new()
	add_child(loading_view)
	loading_view.hide()
	_build_login()
	login_screen.hide()
	LoginGateway.login_unavailable.connect(_show_auth_notice)
	LoginGateway.local_guest_started.connect(_enter_lobby)
	LoginGateway.authenticated.connect(_enter_lobby)
	CloudStore.conflict_detected.connect(_show_cloud_conflict)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(start_button, "modulate:a", 0.6, 1.1)
	_pulse.tween_property(start_button, "modulate:a", 1.0, 1.1)


func _screen() -> Control:
	var screen := Control.new()
	VIEW.place(self, screen, Rect2(0, 0, 1, 1))
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	VIEW.texture(screen, VIEW.CASTLE, Rect2(0, 0, 1, 1), true)
	VIEW.texture(screen, VIEW.LOGO, Rect2(0.06, 0.065, 0.88, 0.23))
	return screen


func _build_title() -> void:
	title_screen = Control.new()
	VIEW.place(self, title_screen, Rect2(0, 0, 1, 1))
	VIEW.texture(title_screen, load("res://assets/art/UI/startup/touch_start.png") as Texture2D, Rect2(0, 0, 1, 1), true)
	start_button = Button.new()
	VIEW.place(title_screen, start_button, Rect2(0.15, 0.80, 0.70, 0.07))
	start_button.text = "터치하여 게임 시작"
	start_button.add_theme_font_size_override("font_size", 34)
	start_button.add_theme_color_override("font_color", Color("fff4fc"))
	start_button.add_theme_color_override("font_hover_color", Color("fff4fc"))
	start_button.add_theme_color_override("font_pressed_color", Color("fff4fc"))
	start_button.add_theme_color_override("font_outline_color", Color("241035"))
	start_button.add_theme_constant_override("outline_size", 4)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		start_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	start_button.name = "TouchStart"
	start_button.pressed.connect(begin_startup)
	VIEW.label(title_screen, "용사는 성장하고, 마왕은 학습한다.", 26, Rect2(0.12, 0.89, 0.76, 0.035), Color("dcc5ed"))
	VIEW.label(title_screen, "v%s" % ProjectSettings.get_setting("application/config/version", "0.0.0"), 22, Rect2(0.07, 0.95, 0.86, 0.025), Color("bba9c8"))


func _input(event: InputEvent) -> void:
	if phase != Phase.TITLE:
		return
	if (event is InputEventScreenTouch and not event.pressed and not event.canceled) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		begin_startup()
		get_viewport().set_input_as_handled()


func begin_startup() -> void:
	if phase != Phase.TITLE and phase != Phase.ERROR:
		return
	phase = Phase.RESOURCES
	if _pulse:
		_pulse.kill()
	title_screen.hide()
	login_screen.hide()
	retry_button.hide()
	loading_view.show()
	loading_view.configure("게임 리소스 준비 중", "앱에 포함된 파일을 확인합니다.\n별도 다운로드는 필요하지 않습니다.", true)
	_resources.clear()
	for index in range(CATALOG.CORE_RESOURCES.size()):
		var path: String = CATALOG.CORE_RESOURCES[index]
		if not ResourceLoader.exists(path):
			_fail("필요한 리소스를 찾지 못했습니다.\n앱 설치 상태를 확인해 주세요.")
			return
		var resource := await _load_resource(path)
		if resource == null:
			return
		_resources.append(resource)
		loading_view.set_progress(float(index + 1) / CATALOG.CORE_RESOURCES.size())
		# Short readability interval only; progress always comes from completed work.
		await get_tree().create_timer(0.15).timeout
	loading_view.configure("용사 소개 리소스 준비 중", "소개 연출의 이미지와 로딩 프레임을 미리 불러옵니다.", true)
	PresentationWarmup.progress_changed.connect(_on_warmup_progress)
	await PresentationWarmup.prepare_common()
	PresentationWarmup.progress_changed.disconnect(_on_warmup_progress)
	phase = Phase.LOADING
	loading_view.configure("로비 불러오는 중", "몬스터와 로비 화면을 미리 준비합니다.")
	_lobby = await _load_resource(CATALOG.LOBBY_PATH, true) as PackedScene
	if _lobby == null:
		if phase != Phase.ERROR:
			_fail("로비 화면을 열 수 없습니다.")
		return
	loading_view.set_progress(1.0)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	loading_view.hide()
	phase = Phase.LOGIN
	login_screen.show()
	if not LoginGateway.user_id.is_empty():
		await LoginGateway.retry_cloud()
	else:
		await LoginGateway.try_auto_login()

func _show_cloud_conflict() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "저장 데이터 선택"
	dialog.dialog_text = "서버와 이 기기의 진행도가 다릅니다.\n서버 저장을 불러오면 이 기기의 저장은 백업됩니다."
	dialog.ok_button_text = "서버 저장 사용"
	dialog.cancel_button_text = "취소"
	dialog.add_button("이 기기 저장 사용", true, "local")
	add_child(dialog)
	dialog.confirmed.connect(func(): LoginGateway.retry_cloud("remote"); dialog.queue_free())
	dialog.custom_action.connect(func(_action: StringName): LoginGateway.retry_cloud("local"); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(800, 280))


func _on_warmup_progress(completed: int, total: int) -> void:
	loading_view.set_progress(float(completed) / maxi(total, 1))


func _load_resource(path: String, show_progress: bool = false) -> Resource:
	var error := ResourceLoader.load_threaded_request(path)
	if error != OK:
		_fail("리소스 준비를 시작하지 못했습니다. 다시 시도해 주세요.")
		return null
	var progress: Array = []
	while is_inside_tree():
		var state := ResourceLoader.load_threaded_get_status(path, progress)
		if show_progress and not progress.is_empty():
			loading_view.set_progress(float(progress[0]))
		if state == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(path)
		if state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail("리소스를 불러오지 못했습니다. 다시 시도해 주세요.")
			return null
		await get_tree().process_frame
	return null


func _build_login() -> void:
	login_screen = _screen()
	var panel := Panel.new()
	panel.name = "LoginPanel"
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	VIEW.place(login_screen, panel, Rect2(0.10, 0.49, 0.80, 0.43))
	PIXEL_FRAME.add_split_frame(panel, "res://assets/art/UI/01_large_left_panel", 0.9, "", 20, Color(0.04, 0.025, 0.085, 0.96), 24.0)
	VIEW.label(panel, "마왕의 성에 오신 것을 환영합니다", 32, Rect2(0.10, 0.08, 0.80, 0.09))
	for index in range(CATALOG.PROVIDERS.size()):
		var data: Dictionary = CATALOG.PROVIDERS[index]
		var button := _button(panel, String(data.label), Rect2(0.10, 0.21 + index * 0.17, 0.80, 0.13), data.color, data.ink)
		button.name = "%sLogin" % String(data.id).capitalize()
		button.pressed.connect(_request_login.bind(String(data.id)))
	VIEW.label(panel, "──  또는  ──", 23, Rect2(0.10, 0.54, 0.8, 0.055), Color("baa6ca"))
	guest_button = _button(panel, "게스트로 시작", Rect2(0.10, 0.61, 0.80, 0.13), Color("522b75"))
	guest_button.name = "GuestLogin"
	guest_button.pressed.connect(_request_guest)
	status_label = VIEW.label(panel, "계정 로그인은 브라우저에서 진행합니다.\n게스트 데이터는 계정 데이터와 분리됩니다.", 23, Rect2(0.10, 0.79, 0.80, 0.12), Color("c7b0d7"))
	retry_button = _button(self, "다시 시도", Rect2(0.28, 0.64, 0.44, 0.06), Color("522b75"))
	retry_button.pressed.connect(begin_startup)
	retry_button.hide()


func _request_login(provider: String) -> void:
	if phase == Phase.LOGIN:
		LoginGateway.begin_login(provider)


func _show_auth_notice(message: String) -> void:
	status_label.text = message


func _request_guest() -> void:
	if phase != Phase.LOGIN or _entering:
		return
	guest_button.disabled = true
	# Guest is local-only, deliberately not a Supabase anonymous identity.
	var was_guest: bool = LoginGateway.local_guest_active
	LoginGateway.begin_local_guest() # Also cancels any in-flight browser login.
	if was_guest:
		_enter_lobby()


func _enter_lobby() -> void:
	if _entering or phase != Phase.LOGIN or _lobby == null:
		return
	_entering = true
	phase = Phase.ENTERING
	login_screen.hide()
	if not LoginGateway.user_id.is_empty() or LocalTestMode.is_tutorial_preview():
		loading_view.configure("마왕의 기록 확인 중", "계정의 프로필을 불러옵니다.")
		loading_view.show()
		var owner: String = LoginGateway.user_id
		var profile_transport: Node = CloudStore if profile_cloud == null else profile_cloud
		var result := await PROFILE.refresh(profile_transport)
		if owner != LoginGateway.user_id:
			_entering = false
			phase = Phase.LOGIN
			loading_view.hide()
			login_screen.show()
			return
		if not bool(result.get("ok", false)):
			_entering = false
			phase = Phase.LOGIN
			loading_view.hide()
			login_screen.show()
			guest_button.disabled = false
			_show_auth_notice("프로필을 확인하지 못했습니다. 로그인 버튼으로 다시 시도해 주세요.")
			return
		if PROFILE.needs_prologue(result.profile):
			phase = Phase.PROLOGUE
			loading_view.hide()
			prologue = PROLOGUE.new()
			prologue.cloud = profile_transport
			add_child(prologue)
			prologue.finished.connect(func(): prologue.queue_free(); _transition_lobby())
			return
	_transition_lobby()

func _transition_lobby() -> void:
	phase = Phase.ENTERING
	loading_view.configure("마왕의 성으로 이동 중", "로비 화면을 준비합니다.")
	loading_view.set_progress(1.0)
	loading_view.show()
	await get_tree().process_frame
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null and transition.change_scene(CATALOG.LOBBY_PATH, "로비 불러오는 중..."):
		return
	_entering = false
	guest_button.disabled = false
	_fail("로비로 이동하지 못했습니다. 다시 시도해 주세요.")


func _fail(message: String) -> void:
	phase = Phase.ERROR
	loading_view.detail.text = message
	retry_button.show()


func _button(parent: Node, text: String, rect: Rect2, fill: Color, ink: Color = Color("fff4fc")) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_stylebox_override("normal", VIEW.plate(fill))
	button.add_theme_stylebox_override("hover", VIEW.plate(fill.lightened(0.10)))
	button.add_theme_stylebox_override("pressed", VIEW.plate(fill.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", VIEW.plate(fill.darkened(0.35)))
	VIEW.place(parent, button, rect)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button
