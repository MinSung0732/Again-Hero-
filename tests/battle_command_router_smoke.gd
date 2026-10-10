extends SceneTree

const RULES := preload("res://src/data/battle_session_catalog.gd")
const REQUEST := preload("res://src/systems/battle_command.gd")
const ROUTER := preload("res://src/systems/battle_command_router.gd")
var router = ROUTER.new()
var checks := 0
var failures := 0
var calls := 0
var wallet := 10
var allow_action := true
var observed: Array = []
var nested := false

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func execute(request: REQUEST) -> bool:
	calls += 1
	observed.append([request.kind, request.subject_id, request.position, request.direction])
	if nested:
		nested = false
		check(router.submit_local(RULES.Command.DEMON_SKILL, "line_assault", Vector2.ZERO, "north"), "nested action")
		check(request.subject_id == "slime", "nested action preserves outer payload")
	if not allow_action or wallet < 1:
		return false
	wallet -= 1
	return true

func request(sequence: int, kind: int = RULES.Command.SUMMON_AUTO, subject: String = "slime") -> REQUEST:
	return REQUEST.new(RULES.PROTOCOL_VERSION, int(router.snapshot().session_id), 1, sequence, kind, subject)

func denied(command: REQUEST, reason: int, label: String) -> void:
	var before := calls
	check(not router.submit(command), label)
	check(router.last_rejection == reason, label + " reason")
	check(calls == before, label + " must not execute")

func run() -> void:
	check(not router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "uninitialized")
	check(router.begin_session(execute), "solo session")
	check(router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "auto summon")
	check(router.submit_local(RULES.Command.SUMMON_AT, "orc", Vector2(44, 88)), "manual summon")
	check(observed.back() == [RULES.Command.SUMMON_AT, "orc", Vector2(44, 88), ""], "exact position preserved")
	check(router.submit_local(RULES.Command.SUMMON_TRANSCENDENT), "transcendent")
	for direction in ["east", "west", "north", "south"]:
		check(router.submit_local(RULES.Command.DEMON_SKILL, "line_assault", Vector2.ZERO, direction), direction)
		check(observed.back()[3] == direction, "direction preserved " + direction)
	check(router.execution_total_us == 0, "profiling off")
	var duplicate := request(7)
	denied(duplicate, ROUTER.Rejection.INVALID_SEQUENCE, "duplicate")
	denied(request(2), ROUTER.Rejection.INVALID_SEQUENCE, "out of order")
	denied(request(0), ROUTER.Rejection.INVALID_SEQUENCE, "zero sequence")
	denied(request(RULES.MAX_SEQUENCE + 1), ROUTER.Rejection.INVALID_SEQUENCE, "overflow sequence")
	var bad := request(8)
	bad.protocol_version += 1
	denied(bad, ROUTER.Rejection.WRONG_VERSION, "version")
	bad = request(8)
	bad.actor_id = 2
	denied(bad, ROUTER.Rejection.WRONG_ACTOR, "actor")
	denied(request(8, 999), ROUTER.Rejection.UNKNOWN_COMMAND, "unknown command")
	denied(request(8, RULES.Command.SUMMON_AUTO, ""), ROUTER.Rejection.INVALID_ARGUMENT, "empty id")
	denied(request(8, RULES.Command.SUMMON_AUTO, "x".repeat(65)), ROUTER.Rejection.INVALID_ARGUMENT, "long id")
	denied(request(8, RULES.Command.SUMMON_TRANSCENDENT, "slime"), ROUTER.Rejection.INVALID_ARGUMENT, "transcendent payload")
	bad = request(8)
	bad.position = Vector2(NAN, 0)
	denied(bad, ROUTER.Rejection.INVALID_ARGUMENT, "nan")
	bad.position = Vector2(0, INF)
	denied(bad, ROUTER.Rejection.INVALID_ARGUMENT, "infinity")
	bad = request(8)
	bad.direction = "diagonal"
	denied(bad, ROUTER.Rejection.INVALID_ARGUMENT, "direction")
	router._actor_roles[1] = RULES.Role.HERO
	denied(request(8), ROUTER.Rejection.WRONG_ROLE, "wrong role")
	router._actor_roles[1] = RULES.Role.DEMON
	wallet = 0
	var failed := request(8)
	var before := calls
	check(not router.submit(failed), "insufficient wallet")
	check(calls == before + 1 and router.gameplay_rejected_count == 1, "gameplay rejection counted")
	wallet = 10
	denied(failed, ROUTER.Rejection.INVALID_SEQUENCE, "failed action cannot replay after refill")
	check(wallet == 10, "replay cannot debit")
	check(router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "next action after failure")
	var old := request(10)
	check(router.begin_session(execute), "restart")
	check(router.accepted_count == 0 and router.rejected_count == 0, "restart counters")
	denied(old, ROUTER.Rejection.WRONG_SESSION, "previous run")
	check(router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "restart sequence starts fresh")
	nested = true
	check(router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "outer action")
	check(router.accepted_count == 3, "nested counters")
	allow_action = false
	check(not router.submit_local(RULES.Command.DEMON_SKILL, "line_assault", Vector2.ZERO, "east"), "cooldown / gameplay failure propagated")
	allow_action = true
	router.profiling_enabled = true
	check(router.submit_local(RULES.Command.SUMMON_AUTO, "slime"), "profiled action")
	check(router.execution_total_us >= router.execution_max_us, "profile totals")
	check(router.begin_session(execute), "augmentation shape session")
	wallet = 10
	var choice := request(1, RULES.Command.DEMON_AUGMENT_CHOOSE, "fixture_a")
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "choice requires revision")
	choice.choice_revision = -1
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "negative revision")
	choice.choice_revision = RULES.MAX_SEQUENCE + 1
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "overflow revision")
	choice.choice_revision = 1
	choice.direction = "east"
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "choice rejects direction")
	choice.direction = ""
	choice.position = Vector2.ONE
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "choice rejects position")
	choice.position = Vector2.ZERO
	choice.subject_id = ""
	denied(choice, ROUTER.Rejection.INVALID_ARGUMENT, "choice requires id")
	choice.subject_id = "fixture_a"
	check(router.submit(choice), "choice typed request")
	denied(choice, ROUTER.Rejection.INVALID_SEQUENCE, "choice duplicate")
	var reroll := request(2, RULES.Command.DEMON_AUGMENT_REROLL, "fixture_a")
	reroll.choice_revision = 1
	denied(reroll, ROUTER.Rejection.INVALID_ARGUMENT, "reroll rejects subject")
	reroll.subject_id = ""
	check(router.submit(reroll), "reroll typed request")
	var extra := request(3)
	extra.choice_revision = 1
	denied(extra, ROUTER.Rejection.INVALID_ARGUMENT, "summon rejects offer revision")
	extra.choice_revision = 0
	extra.protocol_version = 1
	denied(extra, ROUTER.Rejection.WRONG_VERSION, "v1 rejected after schema upgrade")
	for mode in [RULES.Mode.HERO_SOLO, RULES.Mode.PVP_CASUAL, RULES.Mode.PVP_RANKED, 999]:
		check(not router.begin_session(execute, mode), "future mode unavailable")
		denied(request(1), ROUTER.Rejection.UNSUPPORTED_MODE, "future mode cannot execute")
	check(router.begin_session(execute), "restore solo")
	denied(null, ROUTER.Rejection.NOT_READY, "null command")
	print("battle_command_router_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
