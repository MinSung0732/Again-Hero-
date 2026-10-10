extends RefCounted

const RULES := preload("res://src/data/battle_session_catalog.gd")
const REQUEST := preload("res://src/systems/battle_command.gd")
enum Rejection { NONE, NOT_READY, UNSUPPORTED_MODE, WRONG_VERSION, WRONG_SESSION, WRONG_ACTOR, UNKNOWN_COMMAND, WRONG_ROLE, INVALID_SEQUENCE, INVALID_ARGUMENT, GAMEPLAY_REJECTED }
const LOCAL_ACTOR := 1
var profiling_enabled := false
var last_rejection: int = Rejection.NONE
var accepted_count := 0
var rejected_count := 0
var gameplay_rejected_count := 0
var execution_total_us := 0
var execution_max_us := 0
var _session_id := 0
var _mode: int = RULES.Mode.DEMON_SOLO
var _local_sequence := 0
var _executor := Callable()
var _actor_roles: Dictionary = {}
var _last_sequences: Dictionary = {}

func supports_local_execution() -> bool:
	return RULES.supports_local_execution(_mode)

func begin_session(executor: Callable, mode: int = RULES.Mode.DEMON_SOLO) -> bool:
	# Restart invalidates queued commands from the preceding run. No save writes.
	_session_id += 1
	_mode = mode
	_executor = executor
	_local_sequence = 0
	_actor_roles.clear()
	_last_sequences.clear()
	_actor_roles[LOCAL_ACTOR] = RULES.Role.DEMON
	accepted_count = 0
	rejected_count = 0
	gameplay_rejected_count = 0
	execution_total_us = 0
	execution_max_us = 0
	last_rejection = Rejection.NONE
	return executor.is_valid() and RULES.supports_local_execution(mode)

func submit_local(kind: int, subject: String = "", point: Vector2 = Vector2.ZERO, direction: String = "", revision: int = 0) -> bool:
	_local_sequence += 1
	var request := REQUEST.new(RULES.PROTOCOL_VERSION, _session_id, LOCAL_ACTOR, _local_sequence, kind, subject, point, direction, revision)
	return submit(request)

func _reject(reason: int) -> bool:
	last_rejection = reason
	rejected_count += 1
	return false

func submit(request: REQUEST) -> bool:
	if request == null or not _executor.is_valid():
		return _reject(Rejection.NOT_READY)
	if not RULES.supports_local_execution(_mode):
		return _reject(Rejection.UNSUPPORTED_MODE)
	if request.protocol_version != RULES.PROTOCOL_VERSION:
		return _reject(Rejection.WRONG_VERSION)
	if request.session_id != _session_id:
		return _reject(Rejection.WRONG_SESSION)
	if not _actor_roles.has(request.actor_id):
		return _reject(Rejection.WRONG_ACTOR)
	var role := RULES.command_role(request.kind)
	if role == 0:
		return _reject(Rejection.UNKNOWN_COMMAND)
	if int(_actor_roles[request.actor_id]) != role:
		return _reject(Rejection.WRONG_ROLE)
	if request.sequence <= int(_last_sequences.get(request.actor_id, 0)) or request.sequence > RULES.MAX_SEQUENCE:
		return _reject(Rejection.INVALID_SEQUENCE)
	if not _arguments_valid(request):
		return _reject(Rejection.INVALID_ARGUMENT)
	# Consume before the handler: a failed gameplay action must never become a
	# deferred retry after mana recovers. Nested signal callbacks get new requests.
	_last_sequences[request.actor_id] = request.sequence
	_local_sequence = maxi(_local_sequence, request.sequence) if request.actor_id == LOCAL_ACTOR else _local_sequence
	var started_us := Time.get_ticks_usec() if profiling_enabled else 0
	var result: Variant = _executor.call(request)
	if profiling_enabled:
		var elapsed := Time.get_ticks_usec() - started_us
		execution_total_us += elapsed
		execution_max_us = maxi(execution_max_us, elapsed)
	if not result is bool or not result:
		gameplay_rejected_count += 1
		return _reject(Rejection.GAMEPLAY_REJECTED)
	accepted_count += 1
	last_rejection = Rejection.NONE
	return true

func _arguments_valid(request: REQUEST) -> bool:
	if not is_finite(request.position.x) or not is_finite(request.position.y):
		return false
	if request.direction not in RULES.DIRECTIONS or request.subject_id.length() > RULES.MAX_CONTENT_ID_LENGTH:
		return false
	if request.kind == RULES.Command.DEMON_AUGMENT_CHOOSE or request.kind == RULES.Command.DEMON_AUGMENT_REROLL:
		if request.choice_revision <= 0 or request.choice_revision > RULES.MAX_SEQUENCE:
			return false
		if request.position != Vector2.ZERO or not request.direction.is_empty():
			return false
	elif request.choice_revision != 0:
		return false
	match request.kind:
		RULES.Command.SUMMON_AUTO, RULES.Command.SUMMON_AT, RULES.Command.DEMON_SKILL, RULES.Command.DEMON_AUGMENT_CHOOSE:
			return not request.subject_id.is_empty()
		RULES.Command.SUMMON_TRANSCENDENT, RULES.Command.DEMON_AUGMENT_REROLL:
			return request.subject_id.is_empty()
	return false

func snapshot() -> Dictionary:
	# Explicit diagnostic pull only; callers must not request this every frame.
	return {"protocol_version": RULES.PROTOCOL_VERSION, "session_id": _session_id, "mode": _mode,
		"accepted": accepted_count, "rejected": rejected_count, "gameplay_rejected": gameplay_rejected_count,
		"last_rejection": last_rejection, "execution_total_us": execution_total_us, "execution_max_us": execution_max_us}
