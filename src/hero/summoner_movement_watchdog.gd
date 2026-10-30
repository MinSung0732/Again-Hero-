extends RefCounted

# Sample displacement in combat time. A blocked body takes a bounded tangent
# around the obstacle; alternate sides if a later attempt is also blocked.
const STALL_SECONDS := 0.75
const DETOUR_SECONDS := 1.5
const MIN_PROGRESS := 4.0
var elapsed := 0.0
var anchor := Vector2.ZERO
var detour_remaining := 0.0
var detour_direction := Vector2.ZERO
var side := 1.0
var recovered := false

func reset(position: Vector2) -> void:
	elapsed = 0.0
	anchor = position
	detour_remaining = 0.0
	detour_direction = Vector2.ZERO
	side = 1.0
	recovered = false

func direction(position: Vector2, desired: Vector2, speed: float, delta: float) -> Vector2:
	recovered = false
	if speed <= 0.01:
		elapsed = 0.0
		anchor = position
		return desired
	detour_remaining = maxf(0.0, detour_remaining - delta)
	elapsed += delta
	if elapsed >= STALL_SECONDS:
		var minimum := minf(MIN_PROGRESS, speed * STALL_SECONDS * 0.2)
		if position.distance_squared_to(anchor) < minimum * minimum:
			detour_direction = desired.orthogonal() * side
			side = -side
			detour_remaining = DETOUR_SECONDS
			recovered = true
		elapsed = 0.0
		anchor = position
	return detour_direction if detour_remaining > 0.0 else desired
