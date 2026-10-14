extends RefCounted
## Player-only shared control window. No actor scans or per-tick allocations.
const DATA := preload("res://src/data/hero_mode_catalog.gd")
var remaining := 0.0
func reset() -> void:
	remaining = 0.0
func tick(delta: float) -> void:
	remaining = maxf(remaining-delta,0.0)
func accept(duration: float, resistance: float) -> float:
	if remaining > 0.0 or duration <= 0.0: return 0.0
	var factor := 1.0-clampf(resistance,0.0,1.0)
	var effective := minf(maxf(duration*factor,0.05),DATA.CONTROL_MAX_DURATION)
	remaining = effective+DATA.CONTROL_RECOVERY
	# Existing actor status implementations apply resistance themselves.
	return effective/maxf(factor,0.000001) if factor > 0.0 else 0.05
