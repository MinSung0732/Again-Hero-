extends RefCounted

# Chronological window. Expired references are released immediately; the head
# advances without shifting the live suffix on every event. Compact only when
# enough slots can be reclaimed, so removal is amortized O(1) per event.
const COMPACT_MINIMUM := 64
var _events: Array = []
var _head := 0


func append(event: Dictionary) -> void:
	_events.append(event)


func size() -> int:
	return _events.size() - _head


func is_empty() -> bool:
	return _head == _events.size()


func get_event(index: int) -> Dictionary:
	return _events[_head + index]


func clear() -> void:
	_events.clear()
	_head = 0


func prune_before(cutoff: float) -> void:
	while _head < _events.size():
		if float(_events[_head].get("time", 0.0)) >= cutoff:
			break # Exact boundary remains in the window, as before.
		_events[_head] = null # Drop the expired event, including nested references.
		_head += 1
	if is_empty():
		clear()
	elif _head >= COMPACT_MINIMUM and _head * 2 >= _events.size():
		var live_count := size()
		for index in range(live_count):
			_events[index] = _events[_head + index]
		_events.resize(live_count)
		_head = 0
