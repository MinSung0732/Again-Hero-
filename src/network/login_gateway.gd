extends Node
const CONNECTION_POLICY := preload("res://src/data/cloud_connection_catalog.gd")

const OAUTH := preload("res://src/network/windows_oauth.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const VAULT := preload("res://src/network/session_vault.gd")
const GUEST := preload("res://src/systems/guest_progress_store.gd")
signal guest_link_failed(message: String)
signal guest_link_state_changed
signal guest_link_status(message: String)
var guest_link_busy := false
var _guest_link_intent: Dictionary = {}
signal login_requested(provider: String)
signal login_unavailable(message: String)
signal local_guest_started
signal authenticated
signal account_deactivated

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
var withdrawal_busy := false
var _cloud: Node
var _guest_vault_clears := 0
var _refresh_busy := false
var _auto_login_pending := false
signal refresh_finished

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Windows DPAPI and AndroidKeyStore store refresh tokens without plaintext.
	# On unsupported Android editor builds the vault fails closed.
	_cloud = get_node("/root/CloudStore")
	_vault = VAULT.new()
	add_child(_vault)
	_cloud.status_changed.connect(func(message: String): login_unavailable.emit(message))
	_oauth = OAUTH.new()
	_oauth.notice.connect(_on_oauth_notice)
	_oauth.validated.connect(_on_validated)
	add_child(_oauth)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 30.0
	_refresh_timer.timeout.connect(_refresh_if_needed)
	add_child(_refresh_timer)

func _on_validated(session: Dictionary, user: Dictionary) -> void:
	if withdrawal_busy or get_node("/root/LocalTestMode").tutorial_preview:
		return # A late OAuth callback must never leave the isolated preview.
	if not _guest_link_intent.is_empty():
		await _link_validated_guest(session, user)
		return
	if not get_node("/root/LocalTestMode").exit_local_test():
		login_unavailable.emit("테스트 모드 종료 상태를 저장하지 못했습니다. 다시 시도해 주세요.")
		return
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
		# A pending guest logout must finish deleting the old credential before
		# a newer OAuth login saves its rotated refresh token.
		while _guest_vault_clears > 0:
			await get_tree().process_frame
			if generation != _session_generation:
				return
		if not await _vault.save_session(user_id, _refresh_token):
			login_unavailable.emit("자동 로그인 정보를 보관하지 못했습니다. 이번 로그인은 유지됩니다.")
	if generation != _session_generation:
		return
	await retry_cloud()

func retry_cloud(choice: String = "") -> void:
	if user_id.is_empty():
		return
	var generation := _session_generation
	var mode := get_node("/root/LocalTestMode")
	if not mode.exit_local_test():
		login_unavailable.emit("테스트 모드 종료 상태를 저장하지 못했습니다. 다시 시도해 주세요.")
		return
	if await _cloud.initialize(choice) and generation == _session_generation:
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
	_auto_login_pending = false
	_cloud._set_connection(true)
	login_unavailable.emit("자동 로그인 확인 중…")
	var session: Dictionary = await _oauth.request_json("/token?grant_type=refresh_token", {"refresh_token": cached.get("refresh_token", "")})
	if generation != _session_generation:
		_auth_busy = false
		return
	if String(session.get("access_token", "")).is_empty():
		_auth_busy = false
		if _oauth.get("last_http_status") in [400, 401, 403]:
			_cloud._set_connection(true, CONNECTION_POLICY.SESSION_EXPIRED, true)
		else:
			_auto_login_pending = true
			_cloud._set_connection(true)
			_refresh_timer.start(3.0)
		login_unavailable.emit("자동 로그인 확인 실패. 로그인 버튼으로 다시 로그인해 주세요.")
		return
	# Persist the rotated refresh token immediately, even if the user lookup fails.
	await _vault.save_session(String(cached.get("user_id", "")), String(session.get("refresh_token", "")))
	if generation != _session_generation:
		_auth_busy = false
		return
	var user: Dictionary = await _oauth.request_json("/user", null, String(session.access_token))
	_auth_busy = false
	if generation != _session_generation: return
	if String(user.get("id", "")) == String(cached.get("user_id", "")) and not user.is_empty():
		await _on_validated(session, user)
	elif not user.is_empty() or _oauth.get("last_http_status") in [401,403]:
		_cloud._set_connection(true, "계정 정보를 확인하지 못했습니다. 다시 로그인해 주세요.", true)
	else:
		_auto_login_pending = true
		_cloud._set_connection(true)
		_refresh_timer.start(3.0)
		login_unavailable.emit(CONNECTION_POLICY.CONNECTING)

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
	if _auto_login_pending and user_id.is_empty():
		await try_auto_login()
	elif not _refresh_token.is_empty() and Time.get_unix_time_from_system() >= _expires_at - 90:
		await refresh_session()

func refresh_session() -> bool:
	var generation := _session_generation
	while _refresh_busy:
		await refresh_finished
		if generation != _session_generation: return false
		return not access_token.is_empty() and Time.get_unix_time_from_system() < _expires_at
	if _refresh_token.is_empty(): return false
	_refresh_busy = true
	var session: Dictionary = await _oauth.request_json("/token?grant_type=refresh_token", {"refresh_token": _refresh_token})
	if generation != _session_generation:
		_refresh_busy = false
		refresh_finished.emit.call_deferred()
		return false
	var success := not String(session.get("access_token", "")).is_empty()
	if success:
		_set_session(session)
		if remember_session_enabled: await _vault.save_session(user_id, _refresh_token)
	elif _oauth.get("last_http_status") in [400, 401, 403]:
		_cloud._set_connection(true, CONNECTION_POLICY.SESSION_EXPIRED, true)
	else:
		# Transient offline must not destroy a still recoverable refresh token.
		_cloud._retry_later()
	_refresh_busy = false
	refresh_finished.emit.call_deferred()
	return success and generation == _session_generation

func return_to_login() -> void:
	# No guest-start signal: a failed login must not start guest lobby entry.
	_auto_login_pending = false
	_session_generation += 1
	var generation := _session_generation
	_cloud.stop()
	get_node("/root/SceneTransition").cancel()
	_oauth.cancel()
	_refresh_timer.stop()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	local_guest_active = false
	account_provider = ""
	account_label = ""
	SCOPE.select_guest()
	await _vault.clear_session()
	if generation == _session_generation:
		get_tree().change_scene_to_file("res://src/startup/Startup.tscn")


func begin_login(provider: String) -> void:
	if withdrawal_busy or guest_link_busy:
		return
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
	if not get_node("/root/LocalTestMode").exit_local_test():
		login_unavailable.emit("테스트 모드 종료 상태를 저장하지 못했습니다. 다시 시도해 주세요.")
		return
	cancel_guest_link()
	login_requested.emit(provider)
	_oauth.begin(provider)


func begin_local_guest(preserve_session: bool = false) -> void:
	_auto_login_pending = false
	if withdrawal_busy:
		return
	cancel_guest_link()
	account_provider = ""
	account_label = ""
	_session_generation += 1
	var generation := _session_generation
	_cloud.stop()
	_oauth.cancel()
	_refresh_timer.stop()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	SCOPE.select_guest()
	if not GUEST.ensure_available():
		login_unavailable.emit("게스트 저장을 준비하지 못했습니다. 다시 시도해 주세요.")
		return
	if remember_session_enabled and not preserve_session:
		_guest_vault_clears += 1
		await _vault.clear_session()
		_guest_vault_clears -= 1
	if generation != _session_generation:
		return
	if local_guest_active:
		return
	local_guest_active = true
	local_guest_started.emit()

func is_guest_link_pending() -> bool:
	return guest_link_busy or (not _guest_link_intent.is_empty() and is_instance_valid(_oauth) and _oauth.busy)

func _on_oauth_notice(message: String) -> void:
	login_unavailable.emit(message)
	if _guest_link_intent.is_empty(): return
	if _oauth.busy:
		guest_link_status.emit(message)
	else:
		_guest_link_intent.clear()
		guest_link_failed.emit(message)
	guest_link_state_changed.emit()

func begin_guest_link(provider: String) -> void:
	if is_guest_link_pending():
		guest_link_status.emit("브라우저에서 연동을 완료하거나 연동 취소 후 다시 선택해 주세요.")
		return
	if withdrawal_busy or _auth_busy:
		guest_link_failed.emit("계정 상태를 확인 중입니다. 잠시 후 다시 시도해 주세요.")
		return
	if not user_id.is_empty() or provider not in ["google","kakao"] or not GUEST.is_guest():
		guest_link_failed.emit("게스트 계정에서 사용할 수 있습니다.")
		return
	var guest := GUEST.capture()
	if guest.is_empty():
		guest_link_failed.emit("게스트 저장을 확인하지 못했습니다. 진행도를 유지한 채 연동을 중단했습니다.")
		return
	_session_generation += 1
	_guest_link_intent = guest
	_oauth.begin(provider)
	guest_link_state_changed.emit()

func cancel_guest_link() -> void:
	_guest_link_intent.clear()
	guest_link_busy = false
	if is_instance_valid(_oauth): _oauth.cancel()
	guest_link_state_changed.emit()

func _link_validated_guest(session: Dictionary, user: Dictionary) -> void:
	if guest_link_busy: return
	var generation := _session_generation
	var guest := GUEST.capture() # Include saves made while the browser was open.
	if guest.is_empty() or guest.guest_id != _guest_link_intent.guest_id or guest.directory != _guest_link_intent.directory:
		cancel_guest_link()
		guest_link_failed.emit("게스트 저장이 변경되어 연동을 중단했습니다. 다시 시도해 주세요.")
		return
	guest_link_busy = true
	guest_link_state_changed.emit()
	login_unavailable.emit("게스트 계정 연동 확인 중…")
	var result: Dictionary = await _cloud.link_guest(session, guest)
	if generation != _session_generation or _guest_link_intent.is_empty(): return
	guest_link_busy = false
	if result.get("ok") != true:
		_guest_link_intent.clear()
		var error := String(result.get("error", ""))
		var message := "이미 가입된 계정입니다.\n다른 구글·카카오 계정으로 연동해 주세요.\n현재 게스트 진행도는 유지됩니다." if error == "already_registered" else ("이미 다른 계정으로 이전한 게스트 진행도입니다.\n기존 계정 로그인으로 이용해 주세요." if error == "guest_already_linked" else ("연동용 이름을 준비하지 못했습니다.\n게스트 진행도는 유지됩니다. 다시 시도해 주세요." if error == "nickname_taken" else "계정 연동을 완료하지 못했습니다.\n게스트 진행도는 유지됩니다. 같은 계정으로 다시 시도해 주세요."))
		guest_link_failed.emit(message)
		return
	var id := String(user.get("id", ""))
	if not SCOPE.valid_payload(result.get("payload")) or not _cloud._valid_revision(result.get("revision")) or not SCOPE.select_account(id) or not SCOPE.install(result.payload, int(result.revision)) or not GUEST.mark_consumed(guest.directory, guest.guest_id, id):
		SCOPE.guest_directory = guest.directory
		SCOPE.select_guest()
		_guest_link_intent.clear()
		guest_link_failed.emit("연동 저장을 기기에 기록하지 못했습니다.\n게스트 진행도는 유지됩니다. 같은 계정으로 다시 시도해 주세요.")
		return
	_guest_link_intent.clear()
	_cloud.stop()
	_session_generation += 1
	generation = _session_generation
	user_id = id
	_set_account_display(user)
	_set_session(session)
	local_guest_active = false
	_refresh_timer.start()
	if remember_session_enabled:
		while _guest_vault_clears > 0:
			await get_tree().process_frame
			if generation != _session_generation: return
		if not await _vault.save_session(user_id, _refresh_token): login_unavailable.emit("자동 로그인 정보를 보관하지 못했습니다. 이번 로그인은 유지됩니다.")
	if generation == _session_generation: await retry_cloud()

func reset_guest_progress() -> bool:
	if guest_link_busy or withdrawal_busy or not user_id.is_empty() or not GUEST.is_guest(): return false
	_session_generation += 1
	cancel_guest_link()
	get_node("/root/TutorialFlow").clear_guide()
	return GUEST.reset()


func reset_local_guest() -> void:
	local_guest_active = false
	SCOPE.select_guest()

func suspend_for_local_test() -> void:
	if withdrawal_busy:
		return
	cancel_guest_link()
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
	if withdrawal_busy or guest_link_busy:
		return false
	cancel_guest_link()
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


func withdraw_account() -> bool:
	var mode := get_node("/root/LocalTestMode")
	if withdrawal_busy or _auth_busy or mode.active or mode.tutorial_preview or user_id.is_empty() or access_token.is_empty():
		return false
	withdrawal_busy = true
	var generation := _session_generation
	var result: Dictionary = await _cloud.withdraw_account()
	if generation != _session_generation:
		withdrawal_busy = false
		return false
	if result.get("ok") != true or result.get("inactive") != true:
		withdrawal_busy = false
		login_unavailable.emit("계정 탈퇴를 확인하지 못했습니다. 연결과 저장 상태를 확인한 뒤 다시 시도해 주세요.")
		return false
	await clear_inactive_session()
	withdrawal_busy = false
	return true


func clear_inactive_session() -> void:
	# Do not call logout(): inactive accounts cannot flush. Invalidate callbacks
	# and clear memory before awaiting the platform vault operation.
	_session_generation += 1
	cancel_guest_link()
	var generation := _session_generation
	_cloud.stop()
	get_node("/root/SceneTransition").cancel()
	_oauth.cancel()
	_refresh_timer.stop()
	user_id = ""
	access_token = ""
	_refresh_token = ""
	_expires_at = 0.0
	account_provider = ""
	account_label = ""
	local_guest_active = false
	SCOPE.select_guest()
	await _vault.clear_session()
	if generation != _session_generation:
		return
	login_unavailable.emit("비활성화된 계정입니다. 탈퇴한 계정 데이터는 30일 보관 후 영구 삭제됩니다.")
	account_deactivated.emit()
