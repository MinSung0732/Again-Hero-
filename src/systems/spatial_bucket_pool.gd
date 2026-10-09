extends RefCounted

# Reuse moving actors' buckets without retaining every cell ever visited.
# The previous-cell list is caller-owned scratch storage, not a keys() copy.
const MAX_SPARE_BUCKETS := 128


static func acquire(spares: Array) -> Array:
	return spares.pop_back() if not spares.is_empty() else []


static func retire_empty(buckets: Dictionary, previous_cells: Array[Vector2i], spares: Array) -> void:
	for cell in previous_cells:
		var bucket: Array = buckets[cell]
		if not bucket.is_empty():
			continue
		buckets.erase(cell)
		if spares.size() < MAX_SPARE_BUCKETS:
			spares.append(bucket)
	previous_cells.clear()
