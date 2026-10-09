extends Node

const OAUTH := preload("res://src/network/windows_oauth.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const VAULT := preload("res://src/network/session_vault.gd")
signal login_requested(provider: String)
signal login_unavailable(message: String)
signal local_guest_started
signal authenticated

var local_guest_active := false
var user_id := ""
var account_provider := ""
var account_label := ""
var access_token := ""
var _refresh_token := ""
var _expires_at := 0.0
var _oauth: Node
var _refresh_timer: Timer
var _session_generation := 0
var _vault: Node
var remember_session_enabled := true
var _auth_busy := false
var _cloud: Node

func _ready() -> void:
	# Windows DPAPI and AndroidKeyStore store refresh tokens without plaintext.
	# On unsupported Android editor builds the vault fails closed.
	_cloud = get_node("/root/CloudStore")
	_vault = VAULT.new()
	add_child(_vault)
	_cloud.status_changed.connect(func(message: String): login_unavailable.emit(message))
	_oauth = OAUTH.new()
	_oauth.notice.connect(func(message: String): login_unavailable.emit(message))
	_oauth.validated.connect(_on_validated)
	add_child(_oauth)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 30.0
	_refresh_timer.timeout.connect(_refresh_if_needed)
	add_child(_refresh_timer)

func _on_validated(session: Dictionary, user: Dictionary) -> void:
	if get_node("/root/LocalTestMode").tutorial_preview:
		return # A late OAuth callback must never leave the isolated preview.
	_cloud.stop()
	var id := String(user.get("id", ""))
	if not SCOPE.select_account(id):
		login_unavailable.emit("계정 저장 폴더를 준비하지 못했습니다.")
		return
	_session_generation += 1
	user_id = id
	_set_account_display(user)
	_set_session(session)
	local_guest_active = false
	_refresh_timer.start()
	var generation := _session_generation
	if remember_session_enabled:
		if not await _vault.save_session(user_id, _refresh_token):
			login_unavailable.emit("자동 로그인 정보를 보관하지 못했습니다. 이번 로그인은 유지됩니다.")
	if generation != _session_generation:
		return
	await retry_cloud()

func retry_cloud(choice: String = "") -> void:
	var generation := _session_generation
	var mode := get_node("/root/LocalTestMode")
	var resetting: bool = mode.pending_reset_id == user_id and not user_id.is_empty()
	if resetting and not mode.reset_progress():
		login_unavailable.emit("일반 플레이 초기화 저장 실패. 다시 시도해 주세요.")
		return
	if await _cloud.initialize("local" if resetting else choice) and generation == _session_generation:
		if resetting:
			mode.pending_reset_id = ""
			if not mode.persist():
				login_unavailable.emit("초기화 상태 기록 실패. 저장 공간을 확인해 주세요.")
				return
		authenticated.emit()

func try_auto_login() -> void:
	if get_node("/root/LocalTestMode").active or get_node("/root/LocalTestMode").tutorial_preview:
		begin_local_guest(true)
		return
	if not user_id.is_empty():
		await retry_cloud()
		return
	if not remember_session_enabled or _auth_busy or not user_id.is_empty():
		return
	_auth_busy = true
	var generation := _session_generation
	var cached: Dictionary = await _vault.read_session()
	if generation != _session_generation or cached.is_empty():
		_auth_busy = false
		return
	login_unavailable.emit("자동 로그인 확인 중…")
	var session: Dictionary = await _oauth.request_json("/token?grant_type=refresh_token", {"refresh_token": cached.get("refresh_token", "")})
	if generation != _session_generation:
		_auth_busy = false
		return
	if String(session.get("access_token", "")).is_empty():
		_auth_busy = false
		login_unavailable.emit("자동 로그인 확인 실패. 로그인 버튼으로 다시 로그인해 주세요.")
		return
	# Persist the rotated refresh token immediately, even if the user lookup fails.
	await _vault.save_session(String(cached.get("user_id", "")), String(session.get("refresh_token", "")))
	var user: Dictionary = await _oauth.request_json("/user", null, String(session.access_token))
	_auth_busy = false
	if generation == _session_generation and String(user.get("id", "")) == String(cached.get("user_id", "")) and not user.is_empty():
		await _on_validated(session, user)
	else:
		login_unavailable.emit("계정 확인 실패. 다시 로그인해 주세요.")

func _set_session(session: Dictionary) -> void:
	access_token = String(session.get("access_token", ""))
	_refresh_token = String(session.get("refresh_token", ""))
	_expires_at = Time.get_unix_time_from_system() + float(session.get("expires_in", 3600))


func _set_account_display(user: Dictionary) -> void:
	# Display-only fields from the already validated /user response. Never
	# use metadata as authorization, save ownership or cloud connection proof.
	var metadata: Dictionary = user.get("app_metadata", {})
	account_provider = String(metadata.get("provider", ""))
	var details: Dictionary = user.get("user_metadata", {})
	account_label = String(user.get("email", ""))
	if account_label.is_empty():
		account_label = String(details.get("name", details.get("nickname", "")))
	account_label = account_label.strip_edges().left(80)


func get_account_display() -> String:
	if user_id.is_empty():
		return "게스트 계정 · 이 기기"
	var provider := String({"kakao": "카카오", "google": "Google"}.get(account_provider, "연결된 계정"))
	var identity := account_label if not account_label.is_empty() else "ID " + user_id.left(8)
	return provider + " 로그인\n" + identity

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
		if remember_session_enabled:
			await _vault.save_session(user_id, _refresh_token)
	elif Time.get_unix_time_from_system() >= _expires_at:
		access_token = ""
		_refresh_token = ""
		login_unavailable.emit("계정 인증이 만료되었습니다. 다시 실행해 로그인해 주세요.")
		return
	_refresh_timer.start()


func begin_login(provider: String) -> void:
	if get_node("/root/LocalTestMode").tutorial_preview:
		login_unavailable.emit("normaltest 쿠폰으로 첫 가입 테스트를 종료한 뒤 로그인해 주세요.")
		return
	if _auth_busy:
		return
	if not access_token.is_empty():
		retry_cloud()
		return
	if provider not in ["google", "kakao"]:
		login_unavailable.emit("지원하지 않는 로그인 방식입니다.")
		return
	login_requested.emit(provider)
	_oauth.begin(provider)


func begin_local_guest(preserve_session: bool = false) -> void:
	account_provider = ""
	account_label = ""
	_session_generation += 1
	_cloud.stop()
	if remember_session_enabled and not preserve_session:
		await _vault.clear_session()
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

func suspend_for_local_test() -> void:
	account_provider = ""
	account_label = ""
	_session_generation += 1
	_cloud.stop()
	_oauth.cancel()
	_refresh_timer.stop()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	local_guest_active = false

func logout() -> bool:
	if not user_id.is_empty() and (_cloud.conflict or not await _cloud.flush()):
		login_unavailable.emit("저장을 완료하지 못했습니다. 동기화 후 다시 시도해 주세요.")
		return false
	# Supabase local-scope logout does not invalidate sessions on other devices.
	if not access_token.is_empty():
		await _oauth.request_json("/logout?scope=local", {}, access_token)
	_session_generation += 1
	_cloud.stop()
	_oauth.cancel()
	_refresh_timer.stop()
	if remember_session_enabled:
		await _vault.clear_session()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	local_guest_active = false
	SCOPE.select_guest()
	account_provider = ""
	account_label = ""
	return true
