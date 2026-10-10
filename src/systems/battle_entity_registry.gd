extends RefCounted

# Handle: Vector3i(session epoch, slot ID, generation). Instance IDs are only
# local lookup keys, never the transport identity. Metadata is bounded by peak
# concurrent registrations rather than total spawns. No strong Node ownership.
const LAST_LIFE_META := &"_battle_last_entity_handle"
const MAX_COMPONENT := 2147483647
var _epoch := 0
var _nodes: Array[WeakRef] = []
var _generations: Array[int] = []
var _instance_ids: Array[int] = []
var _free_slots: Array[int] = []
var _by_instance: Dictionary = {}
var active_count := 0

func begin_session(epoch: int) -> bool:
	# Reject repeats: clearing with the same epoch could resurrect old handles.
	if epoch <= _epoch or epoch > MAX_COMPONENT:
		return false
	_epoch = epoch
	_nodes.clear()
	_generations.clear()
	_instance_ids.clear()
	_free_slots.clear()
	_by_instance.clear()
	active_count = 0
	return true

func activate(node: Node) -> Vector3i:
	if _epoch <= 0 or not is_instance_valid(node) or node.is_queued_for_deletion():
		return Vector3i.ZERO
	var instance_id := node.get_instance_id()
	if _by_instance.has(instance_id):
		var existing: int = _by_instance[instance_id]
		if _nodes[existing] != null and _nodes[existing].get_ref() == node:
			return Vector3i(_epoch, existing + 1, _generations[existing])
		_retire_slot(existing)
	var slot: int
	if _free_slots.is_empty():
		if _nodes.size() >= MAX_COMPONENT:
			return Vector3i.ZERO
		slot = _nodes.size()
		_nodes.append(null)
		_generations.append(1)
		_instance_ids.append(0)
	else:
		slot = _free_slots.pop_back()
		_generations[slot] += 1
	_nodes[slot] = weakref(node)
	_instance_ids[slot] = instance_id
	_by_instance[instance_id] = slot
	active_count += 1
	var handle := Vector3i(_epoch, slot + 1, _generations[slot])
	node.set_meta(LAST_LIFE_META, handle)
	return handle

func get_last_handle(node: Node) -> Vector3i:
	# Observation only: this survives retire but never grants resolve/command authority.
	if not is_instance_valid(node):
		return Vector3i.ZERO
	var value = node.get_meta(LAST_LIFE_META, Vector3i.ZERO)
	if typeof(value) != TYPE_VECTOR3I:
		return Vector3i.ZERO
	var handle: Vector3i = value
	return handle if handle.x == _epoch and handle.x > 0 and handle.y > 0 and handle.z > 0 else Vector3i.ZERO

func get_handle(node: Node) -> Vector3i:
	if not is_instance_valid(node):
		return Vector3i.ZERO
	var slot := int(_by_instance.get(node.get_instance_id(), -1))
	if slot < 0:
		return Vector3i.ZERO
	var handle := Vector3i(_epoch, slot + 1, _generations[slot])
	return handle if resolve(handle) == node else Vector3i.ZERO

func resolve(handle: Vector3i) -> Node:
	if not _matches(handle):
		return null
	var slot := handle.y - 1
	var node = _nodes[slot].get_ref()
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		_retire_slot(slot)
		return null
	return node as Node

func retire(handle: Vector3i) -> bool:
	if not _matches(handle):
		return false
	_retire_slot(handle.y - 1)
	return true

func retire_instance(instance_id: int) -> bool:
	var slot := int(_by_instance.get(instance_id, -1))
	if slot < 0:
		return false
	_retire_slot(slot)
	return true

func _matches(handle: Vector3i) -> bool:
	var slot := handle.y - 1
	return handle.x == _epoch and handle.x > 0 and slot >= 0 and slot < _nodes.size() and handle.z == _generations[slot] and _nodes[slot] != null

func _retire_slot(slot: int) -> void:
	if _nodes[slot] == null:
		return
	_by_instance.erase(_instance_ids[slot])
	_nodes[slot] = null
	_instance_ids[slot] = 0
	active_count -= 1
	# Never wrap a generation and accidentally validate a very old handle.
	if _generations[slot] < MAX_COMPONENT:
		_free_slots.append(slot)

func snapshot() -> Dictionary:
	# Explicit diagnostics only. No whole registry enumeration or deep copy.
	return {"session_id": _epoch, "active_count": active_count,
		"slot_count": _nodes.size(), "free_slot_count": _free_slots.size()}
