extends Node

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CONFIG := preload("res://src/network/supabase_config.gd")
const RPC_CODEC := preload("res://src/network/rpc_request_codec.gd")
signal status_changed(message: String)
signal conflict_detected
signal connection_changed(blocked: bool, message: String, terminal: bool)
signal canonical_reloaded
signal operation_released
var ready_for_play := false
var conflict := false
var busy := false
var _generation := 0
var _timer: Timer
var _heartbeat: Timer
var connection_blocked := false
var writes_suspended := true
var terminal := false
var connection_message := ""
var _nonce := ""
var _claimed := false
var _retry_delay := 1.0
var _reload_after_sync := false
var _initialized := false
var _last_http_status := 0
var _rpc_waiters := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_retry_connection)
	add_child(_timer)
	SCOPE.saved_callback = _queue_save
	SCOPE.write_allowed = can_write
	_heartbeat = Timer.new()
	_heartbeat.wait_time = 15.0
	_heartbeat.timeout.connect(_check_connection)
	add_child(_heartbeat)

func _notification(what: int) -> void:
	if not _initialized or terminal: return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_set_connection(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_set_connection(true)
		_retry_connection.call_deferred()

func stop() -> void:
	_generation += 1
	ready_for_play = false
	conflict = false
	_timer.stop()
	_heartbeat.stop()
	_claimed = false
	_nonce = ""
	_initialized = false
	_reload_after_sync = false
	terminal = false
	_rpc_waiters = 0
	_retry_delay = 1.0
	_set_connection(false)
	operation_released.emit() # Wake old-session waiters so they can cancel.

func can_write() -> bool:
	return ready_for_play and not conflict and not writes_suspended and not terminal and _account_context_matches()

static func new_operation_id() -> String:
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]

func _set_connection(blocked: bool, message: String = "서버에 연결 중입니다", final_state: bool = false, suspend_writes: bool = true) -> void:
	if terminal and not final_state: return
	if not blocked and _rpc_waiters > 0: return
	connection_blocked = blocked
	writes_suspended = blocked and suspend_writes
	connection_message = message
	terminal = final_state
	connection_changed.emit(blocked, message, final_state)

func _queue_save() -> void:
	if ready_for_play and not conflict and not terminal:
		status_changed.emit("클라우드에 저장 중…")
		# Finish related synchronous writes in this action; UI input is already
		# blocked. The scope coalesces them until the first actual dispatch.
		_set_connection(true, "서버에 연결 중입니다", false, false)
		if _timer.is_stopped(): _timer.start(0.15)

func _retry_connection() -> void:
	if terminal or not _account_context_matches(): return
	if not _initialized:
		await get_node("/root/LoginGateway").retry_cloud()
	elif SCOPE.dirty:
		await flush()
	else:
		await _check_connection()

func _retry_later(message: String = "서버에 연결 중입니다") -> void:
	if terminal: return
	_set_connection(true, message)
	status_changed.emit(message)
	_timer.start(_retry_delay)
	_retry_delay = minf(_retry_delay * 2.0, 15.0)

func _handle_terminal(result: Dictionary) -> bool:
	if result.get("request_rejected") == true:
		ready_for_play = false
		_timer.stop()
		_heartbeat.stop()
		# Preserve the pending save; retrying an invalid request cannot fix it.
		_set_connection(true, RPC_CODEC.CONTRACT.REJECTED_MESSAGE, true)
		return true
	if result.get("session_replaced") == true or result.get("reauthenticate") == true:
		ready_for_play = false
		_timer.stop()
		_heartbeat.stop()
		_set_connection(true, "다른 기기에서 로그인했습니다. 다시 로그인해 주세요." if result.get("session_replaced") == true else "로그인이 만료되었습니다. 다시 로그인해 주세요.", true)
		return true
	return false

func _unblock_synced() -> void:
	if _reload_after_sync:
		_reload_after_sync = false
		writes_suspended = false # Allow new scene setup to normalize its cache.
		canonical_reloaded.emit()
	else:
		_set_connection(false)

func _sync_rpc(action: String, data: Dictionary = {}) -> Dictionary:
	var parameters := data.duplicate(true)
	parameters["action"] = action
	parameters["session_nonce"] = _nonce
	return await request_rpc("cloud_sync", parameters)

func _check_connection() -> void:
	if busy or not _initialized or terminal or not _account_context_matches(): return
	if SCOPE.dirty:
		await flush()
		return
	busy = true
	var generation := _generation
	var result := await _sync_rpc("check")
	busy = false
	operation_released.emit.call_deferred()
	if generation != _generation: return
	if _handle_terminal(result): return
	if result.get("inactive") == true:
		await get_node("/root/LoginGateway").clear_inactive_session()
	elif result.get("ok") == true:
		_retry_delay = 1.0
		_set_connection(false)
	else:
		_retry_later()

func request_rpc(method: String, data: Dictionary) -> Dictionary:
	var gateway := get_node("/root/LoginGateway")
	if gateway.access_token.is_empty() or not _account_context_matches(): return {}
	var generation := _generation
	var waiting := false
	var delay := 1.0
	var retry_safe := method in ["read_player_profile", "register_player_profile", "complete_player_prologue", "check_player_nickname", "rename_player_nickname"]
	if retry_safe:
		while busy:
			await operation_released
			if generation != _generation: return {}
		busy = true
		_set_connection(true)
	while generation == _generation and not terminal and _account_context_matches():
		var result := await _request_with_token(method, data, gateway.access_token)
		if generation != _generation:
			if retry_safe: _finish_profile_rpc(generation, waiting)
			return {}
		if _last_http_status == 401 and gateway.has_method("refresh_session"):
			if await gateway.refresh_session() and generation == _generation:
				result = await _request_with_token(method, data, gateway.access_token)
		if generation != _generation:
			if retry_safe: _finish_profile_rpc(generation, waiting)
			return {}
		if _handle_terminal(result): break
		if not retry_safe or not result.is_empty() or (_last_http_status > 0 and _last_http_status < 500 and _last_http_status not in [408, 429]):
			if retry_safe: _finish_profile_rpc(generation, waiting)
			return result
		if not waiting:
			waiting = true
			_rpc_waiters += 1
		_set_connection(true)
		# Profile commands (rename via operation UUID) are idempotent. Do not
		# blanket-retry other mutation RPCs without their own recovery contract.
		await get_tree().create_timer(delay).timeout
		delay = minf(delay * 2.0, 15.0)
	if retry_safe: _finish_profile_rpc(generation, waiting)
	return {}

func _finish_profile_rpc(generation: int, waiting: bool) -> void:
	busy = false
	operation_released.emit.call_deferred()
	if generation != _generation: return
	if waiting: _rpc_waiters -= 1
	if not SCOPE.dirty: _set_connection(false)

func link_guest(session: Dictionary, guest: Dictionary) -> Dictionary:
	# Use the newly validated OAuth token without switching the local save owner.
	var mode := get_node("/root/LocalTestMode")
	if mode.active or mode.tutorial_preview or not SCOPE.user_id.is_empty(): return {}
	return await _request_with_token("link_guest_save", {"guest_id": guest.guest_id, "guest_payload": guest.payload}, String(session.get("access_token", "")))

func _request_with_token(method: String, data: Dictionary, token: String) -> Dictionary:
	_last_http_status = 0
	if token.is_empty(): return {}
	var encoded := RPC_CODEC.encode(method, data)
	if not encoded.get("ok", false):
		return {"request_rejected": true, "error_code": "invalid_rpc_argument"}
	var request := HTTPRequest.new()
	request.timeout = 20
	request.body_size_limit = 2000000
	add_child(request)
	var headers := PackedStringArray(["apikey: " + CONFIG.PUBLISHABLE_KEY, "Authorization: Bearer " + token, "Content-Type: application/json"])
	if not _nonce.is_empty(): headers.append("x-game-session: " + _nonce)
	if request.request(_rpc_endpoint(method), headers, HTTPClient.METHOD_POST, String(encoded.body)) != OK:
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	_last_http_status = int(response[1]) if response[0] == HTTPRequest.RESULT_SUCCESS else 0
	if RPC_CODEC.is_permanent_http_error(_last_http_status):
		# Log only status/code, never JWTs, request payloads, names or server detail.
		var error_body: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
		var code := String(error_body.get("code", "")) if error_body is Dictionary else ""
		push_warning("Cloud RPC rejected: HTTP %d, code %s" % [_last_http_status, code])
		return {"request_rejected": true, "http_status": _last_http_status, "error_code": code}
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {}
	var parser := JSON.new()
	if parser.parse((response[3] as PackedByteArray).get_string_from_utf8()) != OK:
		return {} # Malformed server bodies follow the existing retry path.
	return parser.data if parser.data is Dictionary else {}

func _rpc_endpoint(method: String) -> String:
	return CONFIG.PROJECT_URL + "/rest/v1/rpc/" + method

func initialize(_choice: String = "") -> bool:
	# Retained argument for callers; clients cannot choose to overwrite cloud.
	if terminal or not _account_context_matches(): return false
	if busy:
		_retry_later()
		return false
	busy = true
	var generation := _generation
	var owner := SCOPE.user_id
	_set_connection(true)
	if _nonce.is_empty(): _nonce = new_operation_id()
	var claim := await _sync_rpc("claim" if not _claimed else "check")
	var remote: Dictionary = {}
	if generation == _generation and claim.get("ok") == true:
		_claimed = true
		remote = await _sync_rpc("read", {"operation_id": SCOPE.pending_cloud.get("operation_id")})
	busy = false
	operation_released.emit.call_deferred()
	if generation != _generation or owner != SCOPE.user_id or not _account_context_matches(): return false
	if _handle_terminal(claim) or _handle_terminal(remote): return false
	if claim.get("inactive") == true or remote.get("inactive") == true:
		await get_node("/root/LoginGateway").clear_inactive_session()
		return false
	if claim.get("ok") != true or not _valid_revision(remote.get("revision")) or not remote.get("found") is bool:
		_retry_later()
		return false
	var version := int(remote.revision)
	var resume_pending := false
	if remote.found:
		if not SCOPE.valid_payload(remote.get("payload")):
			_set_connection(true, "서버 저장을 읽지 못했습니다. 게임을 다시 실행해 주세요.", true)
			return false
		var pending: Dictionary = SCOPE.pending_cloud
		if not pending.is_empty():
			if remote.get("acknowledged_revision") == version and SCOPE.serial > int(pending.serial):
				SCOPE.revision = version
				SCOPE.pending_cloud = {}
				resume_pending = true
			elif pending.expected_revision == version:
				resume_pending = true
		if not resume_pending:
			# No arbitrary local/remote choice and no value-by-value currency merge.
			if not SCOPE.install(remote.payload, version):
				_set_connection(true, "기기에 저장할 공간을 확보한 후 다시 시도해 주세요.", true)
				return false
	else:
		# First migration only: account-scoped local data; guest remains separate.
		SCOPE.revision = 0
		SCOPE.pending_cloud = {}
		SCOPE.dirty = true
	conflict = false
	ready_for_play = true
	_initialized = true
	_retry_delay = 1.0
	_heartbeat.start()
	if remote.get("legacy") == true: SCOPE.dirty = true
	if SCOPE.dirty:
		if SCOPE.persist() != OK:
			_set_connection(true, "저장 공간을 확인하고 게임을 다시 실행해 주세요.", true)
			return false
		return await flush()
	_unblock_synced()
	status_changed.emit("클라우드 저장 불러오기 완료")
	return true

# Serialize reward claims with normal snapshot writes. Install the server's
# atomic ledger + wallet response only if the account and local serial match.
func tutorial_operation(action: String) -> Dictionary:
	if not ready_for_play or conflict or SCOPE.user_id.is_empty():
		return {}
	var owner := SCOPE.user_id
	var generation := _generation
	if action in ["complete", "skip"] and not await flush():
		return {}
	while busy:
		await operation_released
		if generation != _generation or owner != SCOPE.user_id:
			return {}
	if owner != SCOPE.user_id or generation != _generation or conflict or not ready_for_play:
		return {}
	busy = true
	_set_connection(true)
	_timer.stop()
	var serial := SCOPE.serial
	var result := await _sync_rpc("tutorial", {"tutorial_action": action, "expected_revision": SCOPE.revision})
	busy = false
	# Resume queued work after this response has applied revision/conflict state.
	operation_released.emit.call_deferred()
	if owner != SCOPE.user_id or generation != _generation:
		return {}
	if _handle_terminal(result): return {}
	if result.is_empty() or bool(result.get("conflict", false)):
		_reload_after_sync = true
		_initialized = false
		_retry_later()
		return {}
	if bool(result.get("ok", false)) and action in ["complete", "skip"]:
		if serial != SCOPE.serial or not _valid_revision(result.get("revision")) or not SCOPE.valid_payload(result.get("payload")):
			conflict = true
			_set_connection(true, "보상 저장 응답을 확인하지 못했습니다. 다시 로그인해 주세요.", true)
			return {}
		if not SCOPE.install(result.payload, int(result.get("revision", -1))):
			_set_connection(true, "기기에 저장할 공간을 확보한 뒤 다시 로그인해 주세요.", true)
			return {}
	if SCOPE.dirty:
		_queue_save()
	else:
		_set_connection(false)
	return result

func flush() -> bool:
	var generation := _generation
	var owner := SCOPE.user_id
	if not _account_context_matches(): return false
	while busy:
		await operation_released
		if generation != _generation or owner != SCOPE.user_id: return false
	if not ready_for_play or conflict or terminal: return false
	if not SCOPE.dirty: return true
	_set_connection(true, "서버에 연결 중입니다", false, writes_suspended)
	if SCOPE.pending_cloud.is_empty():
		SCOPE.pending_cloud = {"operation_id": new_operation_id(), "expected_revision": SCOPE.revision,
			"new_payload": SCOPE.files.duplicate(true), "serial": SCOPE.serial}
	# Persist the dispatch boundary before sending: an operation's payload is
	# immutable across timeouts/restarts, while later changes get a new ID.
	SCOPE.pending_cloud["sent"] = true
	if SCOPE.persist() != OK:
		_set_connection(true, "저장 공간을 확인하고 게임을 다시 실행해 주세요.", true)
		return false
	var pending: Dictionary = SCOPE.pending_cloud.duplicate(true)
	busy = true
	var result := await _sync_rpc("save", {"operation_id": pending.operation_id,
		"expected_revision": pending.expected_revision, "new_payload": pending.new_payload})
	busy = false
	operation_released.emit.call_deferred()
	if generation != _generation or owner != SCOPE.user_id or not _account_context_matches(): return false
	if _handle_terminal(result): return false
	if result.get("inactive") == true:
		await get_node("/root/LoginGateway").clear_inactive_session()
		return false
	if result.get("conflict") == true:
		# Fence stays closed until canonical state replaces stale scene caches.
		_reload_after_sync = true
		_initialized = false
		return await initialize()
	if result.get("ok") != true or not _valid_revision(result.get("revision")):
		_retry_later()
		return false
	SCOPE.revision = int(result.revision)
	SCOPE.dirty = SCOPE.serial != int(pending.serial)
	SCOPE.pending_cloud = {}
	if SCOPE.persist() != OK:
		# Keep the exact request for lost acknowledgement / disk failure recovery.
		SCOPE.pending_cloud = pending
		SCOPE.dirty = true
		_set_connection(true, "저장 공간을 확인하고 게임을 다시 실행해 주세요.", true)
		return false
	_retry_delay = 1.0
	status_changed.emit("클라우드 저장 완료")
	if SCOPE.dirty: return await flush()
	_unblock_synced()
	return true


func withdraw_account() -> Dictionary:
	# Flush and serialize against snapshot/tutorial operations. Server state wins
	# if the withdrawal response was lost after its transaction committed.
	var generation := _generation
	var owner := SCOPE.user_id
	if owner.is_empty() or conflict or not await flush():
		return {}
	while busy:
		await operation_released
		if generation != _generation or owner != SCOPE.user_id:
			return {}
	if generation != _generation or owner != SCOPE.user_id or not ready_for_play:
		return {}
	busy = true
	_timer.stop()
	status_changed.emit("계정 탈퇴 처리 중…")
	var result := await request_rpc("request_account_withdrawal", {})
	if generation == _generation and not bool(result.get("ok", false)):
		var lifecycle := await request_rpc("account_lifecycle_status", {})
		if lifecycle.get("inactive") == true:
			result = {"ok": true, "inactive": true, "delete_after": lifecycle.get("delete_after")}
	busy = false
	operation_released.emit.call_deferred()
	if generation != _generation or owner != SCOPE.user_id:
		return {}
	if result.get("ok") == true and result.get("inactive") == true:
		stop()
	elif SCOPE.dirty:
		_queue_save()
	return result


static func _valid_revision(value: Variant) -> bool:
	# JSON numbers may be floats. Never accept a missing, fractional, negative
	# or non-finite acknowledgement and overwrite the local revision with it.
	if value is int:
		return value >= 0
	if value is float:
		return is_finite(value) and value >= 0.0 and value == floor(value) and value <= 9007199254740991.0
	return false

func _account_context_matches() -> bool:
	var gateway := get_node("/root/LoginGateway")
	var mode := get_node("/root/LocalTestMode")
	return not SCOPE.user_id.is_empty() and SCOPE.user_id == gateway.user_id and not mode.active and not mode.tutorial_preview
