extends RefCounted

# Reused local decision buffer. No Node references, packet data or frame queue.
# Attack distance is the AI's pre-move observation; execution checks the current
# range/cooldown after movement, preserving the original ranged attack order.
enum Kind { NONE, RANGED, MOVEMENT, BASIC_ATTACK }
# Local executor operations, not content IDs or wire protocol commands.
enum AttackKind { NONE, ROGUE_COMBO, FIGHTER, GUNNER, BERSERKER, SUMMONER, ALCHEMIST }
var kind: int = Kind.NONE
var attack_kind: int = AttackKind.NONE
var movement_velocity := Vector2.ZERO
var observed_attack_distance := 0.0
var basic_attack_requested := false
var pending := false

func prepare_ranged(movement: Vector2, distance: float) -> void:
	clear()
	kind = Kind.RANGED
	movement_velocity = movement
	observed_attack_distance = distance
	basic_attack_requested = true
	pending = true

func prepare_movement(movement: Vector2) -> void:
	clear()
	kind = Kind.MOVEMENT
	movement_velocity = movement
	pending = true

func prepare_basic_attack(method: int) -> void:
	clear()
	kind = Kind.BASIC_ATTACK
	attack_kind = method
	basic_attack_requested = true
	pending = true

func clear() -> void:
	kind = Kind.NONE
	attack_kind = AttackKind.NONE
	movement_velocity = Vector2.ZERO
	observed_attack_distance = 0.0
	basic_attack_requested = false
	pending = false
