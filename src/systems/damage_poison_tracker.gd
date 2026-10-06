extends RefCounted

var entries: Dictionary = {}
var expired_ids: Array = []
var ticking := false
var clear_requested := false

func apply(source: Node, total_damage: int, duration: float, channel: int = 0) -> bool:
	if not is_instance_valid(source) or total_damage <= 0 or duration <= 0.0:
		return false
	var id: Variant = source.get_instance_id() if channel == 0 else "%d:%d" % [source.get_instance_id(), channel]
	if entries.has(id):
		return false
	entries[id] = {"source":weakref(source), "total":total_damage, "duration":duration, "elapsed":0.0, "applied":0, "tick":minf(0.5,duration)}
	return true

func tick(target: Node, delta: float) -> void:
	ticking = true
	expired_ids.clear()
	for id in entries:
		var entry: Dictionary = entries[id]
		entry.elapsed = minf(float(entry.elapsed) + delta, float(entry.duration))
		entry.tick = float(entry.tick) - delta
		if float(entry.tick) <= 0.0 or float(entry.elapsed) >= float(entry.duration):
			var cumulative := int(round(float(entry.total) * float(entry.elapsed) / float(entry.duration)))
			var amount := maxi(cumulative - int(entry.applied),0)
			entry.applied = cumulative
			entry.tick = 0.5
			var source: Node = entry.source.get_ref()
			if amount > 0:
				target.call("take_recorded_poison_damage", amount, source)
			if clear_requested:
				break
		if float(entry.elapsed) >= float(entry.duration):
			expired_ids.append(id)
	ticking = false
	if clear_requested:
		clear_requested = false
		clear()
		return
	for id in expired_ids:
		entries.erase(id)

func clear() -> void:
	if ticking:
		clear_requested = true
		return
	entries.clear()
	expired_ids.clear()
