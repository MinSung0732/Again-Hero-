extends RefCounted
## Cache only broad-phase bucket membership, never live target/HP/position decisions.
## Each Battle owns a bounded cache; query order matches the original cell walk.
const CAPACITY := 16
class Entry extends RefCounted:
	var key := Rect2i()
	var nodes: Array = []
var enabled := true
var entries: Array[Entry] = []
var index: Dictionary = {}
var revision := -1
var cursor := 0
var requests := 0
var hits := 0
var bucket_reads := 0
func _init() -> void:
	for slot in CAPACITY: entries.append(Entry.new())
func reset() -> void:
	revision = -1; cursor = 0; index.clear()
	requests = 0; hits = 0; bucket_reads = 0
	for entry in entries: entry.nodes.clear()
func fill(grid: Dictionary, low: Vector2i, high: Vector2i, snapshot_revision: int, result: Array) -> void:
	requests += 1
	if not enabled:
		result.clear(); _gather(grid,low,high,result)
		return
	if revision != snapshot_revision:
		index.clear(); cursor = 0; revision = snapshot_revision
	var key := Rect2i(low,high-low+Vector2i.ONE)
	var entry: Entry = index.get(key)
	if entry == null:
		entry = entries[cursor]
		if index.get(entry.key) == entry: index.erase(entry.key)
		cursor = (cursor+1)%CAPACITY
		entry.key = key; entry.nodes.clear()
		_gather(grid,low,high,entry.nodes)
		index[key] = entry
		result.assign(entry.nodes)
		return # Gather just checked liveness; no callbacks can run between these operations.
	else: hits += 1
	# Keep exactly the original live-node append path on hits. Avoid rewriting
	# every Array element during dense queries; callers still own their scratch.
	result.clear()
	for node in entry.nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion(): result.append(node)

func _gather(grid: Dictionary, low: Vector2i, high: Vector2i, result: Array) -> void:
	bucket_reads += (high.x-low.x+1)*(high.y-low.y+1)
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			var bucket = grid.get(Vector2i(x,y))
			if not bucket is Array: continue
			for node in bucket:
				if is_instance_valid(node) and not node.is_queued_for_deletion(): result.append(node)
