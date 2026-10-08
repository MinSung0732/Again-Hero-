extends RefCounted
## Combat-clock channel; caller supplies action-control interruption and pause handling.
var duration := 0.0
var remaining := 0.0
var active := false
var completed := false
var interrupted := false

func begin(seconds: float) -> void:
	duration = maxf(seconds, 0.001)
	remaining = duration
	active = true
	completed = false
	interrupted = false

func tick(delta: float, blocked: bool) -> bool:
	if not active:
		return false
	if blocked:
		cancel()
		return false
	remaining = maxf(remaining-maxf(delta,0.0),0.0)
	if remaining <= 0.0:
		active = false
		completed = true
		return true
	return false

func cancel() -> void:
	interrupted = active
	active = false
	completed = false

func progress() -> float:
	return clampf(1.0-remaining/maxf(duration,0.001),0.0,1.0)
