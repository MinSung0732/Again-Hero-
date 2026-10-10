extends RefCounted

# Run-time clock only: advanced by the existing RUN_TIMER pause domain.
# No wall-clock reads, timers, RNG or per-step containers. This is NOT a fixed
# physics tick, the shared clock of every actor, or a network authority driver.
var elapsed_seconds: float = 0.0
var advance_count := 0

func reset() -> void:
	elapsed_seconds = 0.0
	advance_count = 0

func advance(delta: float) -> void:
	# A malformed external delta must not poison deadlines/strategy timestamps.
	if not is_finite(delta) or delta <= 0.0:
		return
	elapsed_seconds += delta
	advance_count += 1

func snapshot() -> Dictionary:
	# Explicit diagnostic pull; never request a snapshot every frame.
	return {"elapsed_seconds": elapsed_seconds, "advance_count": advance_count}
