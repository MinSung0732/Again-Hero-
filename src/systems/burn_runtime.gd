extends RefCounted
## One refreshable burn; rounded cumulative budgets prevent frame-rate-dependent DOT.
var remaining := 0.0
var duration := 0.0
var elapsed := 0.0
var total := 0
var paid := 0
var tick := 0.0
var source_ref: WeakRef
var revision := 0
func apply(seconds: float, damage: int, source: Node) -> bool:
	if seconds <= 0.0 or damage <= 0:
		return false
	revision += 1
	remaining = seconds
	duration = seconds
	elapsed = 0.0
	total = damage
	paid = 0
	tick = minf(0.25,seconds)
	source_ref = weakref(source) if is_instance_valid(source) else null
	return true
func update(target: Node, delta: float) -> void:
	if remaining <= 0.0:
		return
	elapsed += minf(delta,remaining)
	remaining = maxf(remaining-delta,0.0)
	tick -= delta
	if tick <= 0.0 or remaining <= 0.0:
		var cumulative := int(round(total*minf(elapsed/duration,1.0)))
		var amount := maxi(cumulative-paid,0)
		paid = cumulative
		tick = 0.25
		var version := revision
		if amount > 0:
			target.take_status_damage(amount,source_ref.get_ref() if source_ref != null else null)
		if revision != version:
			return
	if remaining <= 0.0 or target.current_hp <= 0:
		clear()
func clear() -> void:
	revision += 1
	remaining = 0.0
	duration = 0.0
	elapsed = 0.0
	total = 0
	paid = 0
	source_ref = null
