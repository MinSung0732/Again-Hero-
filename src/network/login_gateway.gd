extends Node

const OAUTH := preload("res://src/network/windows_oauth.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
signal login_requested(provider: String)
signal login_unavailable(message: String)
signal local_guest_started
signal authenticated

var local_guest_active := false
var user_id := ""
var access_token := ""
var _refresh_token := ""
var _expires_at := 0.0
var _oauth: Node
var _refresh_timer: Timer
var _session_generation := 0

func _ready() -> void:
	_oauth = OAUTH.new()
	_oauth.notice.connect(func(message: String): login_unavailable.emit(message))
	_oauth.validated.connect(_on_validated)
	add_child(_oauth)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 30.0
	_refresh_timer.timeout.connect(_refresh_if_needed)
	add_child(_refresh_timer)

func _on_validated(session: Dictionary, user: Dictionary) -> void:
	var id := String(user.get("id", ""))
	if not SCOPE.select_account(id):
		login_unavailable.emit("계정 저장 폴더를 준비하지 못했습니다.")
		return
	_session_generation += 1
	user_id = id
	_set_session(session)
	local_guest_active = false
	_refresh_timer.start()
	authenticated.emit()

func _set_session(session: Dictionary) -> void:
	access_token = String(session.get("access_token", ""))
	_refresh_token = String(session.get("refresh_token", ""))
	_expires_at = Time.get_unix_time_from_system() + float(session.get("expires_in", 3600))

func _refresh_if_needed() -> void:
	if _refresh_token.is_empty() or Time.get_unix_time_from_system() < _expires_at - 90:
		return
	_refresh_timer.stop()
	var generation := _session_generation
	var session: Dictionary = await _oauth.request_json("/token?grant_type=refresh_token", {"refresh_token": _refresh_token})
	if generation != _session_generation:
		return
	if not String(session.get("access_token", "")).is_empty():
		_set_session(session)
	elif Time.get_unix_time_from_system() >= _expires_at:
		access_token = ""
		_refresh_token = ""
		login_unavailable.emit("계정 인증이 만료되었습니다. 다시 실행해 로그인해 주세요.")
		return
	_refresh_timer.start()


func begin_login(provider: String) -> void:
	if provider not in ["google", "kakao"]:
		login_unavailable.emit("지원하지 않는 로그인 방식입니다.")
		return
	login_requested.emit(provider)
	_oauth.begin(provider)


func begin_local_guest() -> void:
	_session_generation += 1
	_oauth.cancel()
	_refresh_timer.stop()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	SCOPE.select_guest()
	if local_guest_active:
		return
	local_guest_active = true
	local_guest_started.emit()


func reset_local_guest() -> void:
	local_guest_active = false
	SCOPE.select_guest()
