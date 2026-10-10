extends RefCounted

# Reused local decision buffer. No Node references, packet data or frame queue.
# Attack distance is the AI's pre-move observation; execution checks the current
# range/cooldown after movement, preserving the original ranged attack order.
var movement_velocity := Vector2.ZERO
var observed_attack_distance := 0.0
var basic_attack_requested := false
var pending := false

func prepare_ranged(movement: Vector2, distance: float) -> void:
	movement_velocity = movement
	observed_attack_distance = distance
	basic_attack_requested = true
	pending = true

func clear() -> void:
	movement_velocity = Vector2.ZERO
	observed_attack_distance = 0.0
	basic_attack_requested = false
	pending = false
