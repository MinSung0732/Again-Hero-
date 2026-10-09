extends Node

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CONFIG := preload("res://src/network/supabase_config.gd")
signal status_changed(message: String)
signal conflict_detected
signal operation_released
var ready_for_play := false
var conflict := false
var busy := false
var _generation := 0
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(flush)
	add_child(_timer)
	SCOPE.saved_callback = _queue_save

func stop() -> void:
	_generation += 1
	ready_for_play = false
	conflict = false
	_timer.stop()
	operation_released.emit() # Wake old-session waiters so they can cancel.

func _queue_save() -> void:
	if ready_for_play and not conflict:
		status_changed.emit("이 기기에 저장됨 · 클라우드 동기화 대기")
		_timer.start(4.0)

func request_rpc(method: String, data: Dictionary) -> Dictionary:
	var gateway := get_node("/root/LoginGateway")
	if gateway.access_token.is_empty():
		return {}
	var request := HTTPRequest.new()
	request.timeout = 20
	request.body_size_limit = 2000000
	add_child(request)
	var headers := PackedStringArray(["apikey: " + CONFIG.PUBLISHABLE_KEY, "Authorization: Bearer " + gateway.access_token, "Content-Type: application/json"])
	if request.request(CONFIG.PROJECT_URL + "/rest/v1/rpc/" + method, headers, HTTPClient.METHOD_POST, JSON.stringify(data)) != OK:
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {}
	var parser := JSON.new()
	if parser.parse((response[3] as PackedByteArray).get_string_from_utf8()) != OK:
		return {} # Malformed server bodies follow the existing retry path.
	return parser.data if parser.data is Dictionary else {}

func initialize(choice: String = "") -> bool:
	if busy:
		return false
	busy = true
	var generation := _generation
	status_changed.emit("계정의 클라우드 저장 확인 중…")
	var remote := await request_rpc("read_game_save", {})
	busy = false
	# Resume queued work after this response has applied revision/conflict state.
	operation_released.emit.call_deferred()
	if generation != _generation:
		return false
	if remote.is_empty():
		status_changed.emit("클라우드 저장 확인 실패. 로그인 버튼으로 다시 시도해 주세요.")
		return false
	if not _valid_revision(remote.get("revision")) or not remote.get("found") is bool:
		status_changed.emit("지원하지 않는 서버 저장 응답입니다.")
		return false
	var version := int(remote.get("revision", 0))
	if bool(remote.get("found", false)):
		if not SCOPE.valid_payload(remote.get("payload")):
			status_changed.emit("지원하지 않는 서버 저장 데이터입니다.")
			return false
		if SCOPE.dirty and (SCOPE.revision != version or bool(remote.get("legacy", false))) and choice.is_empty():
			conflict = true
			conflict_detected.emit()
			return false
		if choice == "remote" or (not SCOPE.dirty and choice != "local"):
			if not SCOPE.install(remote.payload, version):
				status_changed.emit("서버 저장을 이 기기에 기록하지 못했습니다.")
				return false
		elif choice == "local":
			SCOPE.revision = version
			SCOPE.dirty = true
			if SCOPE.persist() != OK:
				status_changed.emit("저장 상태 기록 실패. 이 기기의 저장 공간을 확인해 주세요.")
				return false
	conflict = false
	ready_for_play = true
	if not bool(remote.get("found", false)) or bool(remote.get("legacy", false)):
		SCOPE.dirty = true
	if SCOPE.dirty:
		return await flush()
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
	_timer.stop()
	var serial := SCOPE.serial
	var result := await request_rpc("account_tutorial", {"action": action, "expected_revision": SCOPE.revision})
	busy = false
	# Resume queued work after this response has applied revision/conflict state.
	operation_released.emit.call_deferred()
	if owner != SCOPE.user_id or generation != _generation:
		return {}
	if bool(result.get("conflict", false)):
		conflict = true
		status_changed.emit("튜토리얼 보상 저장이 다른 기기와 충돌했습니다. 다시 로그인해 주세요.")
		return {}
	if bool(result.get("ok", false)) and action in ["complete", "skip"]:
		if serial != SCOPE.serial or not _valid_revision(result.get("revision")) or not SCOPE.valid_payload(result.get("payload")):
			conflict = true
			return {}
		if not SCOPE.install(result.payload, int(result.get("revision", -1))):
			return {}
	if SCOPE.dirty:
		_queue_save()
	return result

func flush() -> bool:
	# Capture before waiting: an old account waiter must not flush a new one.
	var generation := _generation
	var owner := SCOPE.user_id
	while busy:
		await operation_released
		if generation != _generation or owner != SCOPE.user_id:
			return false
	if not ready_for_play or conflict:
		return false
	if not SCOPE.dirty:
		return true
	busy = true
	var serial := SCOPE.serial
	var result := await request_rpc("save_game_snapshot", {"expected_revision": SCOPE.revision, "new_payload": SCOPE.files.duplicate(true)})
	busy = false
	# Resume queued work after this response has applied revision/conflict state.
	operation_released.emit.call_deferred()
	if generation != _generation:
		return false
	if bool(result.get("conflict", false)):
		conflict = true
		status_changed.emit("다른 기기의 저장과 충돌했습니다. 계정 화면에서 다시 불러와 주세요.")
		conflict_detected.emit()
		return false
	if not bool(result.get("ok", false)) or not _valid_revision(result.get("revision")):
		status_changed.emit("클라우드 저장 실패 · 이 기기에 보관 중, 재시도합니다")
		_timer.start(30.0)
		return false
	SCOPE.revision = int(result.revision)
	SCOPE.dirty = SCOPE.serial != serial
	if SCOPE.persist() != OK:
		SCOPE.dirty = true
		status_changed.emit("저장 상태 기록 실패. 이 기기의 저장 공간을 확인해 주세요.")
		return false
	status_changed.emit("클라우드 저장 완료")
	if SCOPE.dirty:
		_queue_save()
	return true


static func _valid_revision(value: Variant) -> bool:
	# JSON numbers may be floats. Never accept a missing, fractional, negative
	# or non-finite acknowledgement and overwrite the local revision with it.
	if value is int:
		return value >= 0
	if value is float:
		return is_finite(value) and value >= 0.0 and value == floor(value) and value <= 9007199254740991.0
	return false
