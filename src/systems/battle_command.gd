extends RefCounted

# One small request per user action; no per-frame command allocation.
# actor_id is a trusted session slot, NOT a network peer ID or account UUID.
# Keep this transport-neutral. Future packets must be decoded/validated into it;
# never send a Godot Object over RPC or accept the client's role/cost/damage.
var protocol_version: int
var session_id: int
var actor_id: int
var sequence: int
var kind: int
var subject_id: String
var position: Vector2
var direction: String
var choice_revision: int

func _init(version: int, session: int, actor: int, order: int, action: int,
	subject: String = "", point: Vector2 = Vector2.ZERO, facing: String = "", revision: int = 0) -> void:
	protocol_version = version
	session_id = session
	actor_id = actor
	sequence = order
	kind = action
	subject_id = subject
	position = point
	direction = facing
	choice_revision = revision
