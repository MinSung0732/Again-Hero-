extends RefCounted

# Reusable reservation for one delayed target, scoped to its originating battle.
# Allocate WeakRefs at capture only; resolve performs no container allocation.
var _target: WeakRef
var _scope: WeakRef
var _tracked := false
var _handle := Vector3i.ZERO

func capture(target: Node, scope: Node) -> bool:
	clear()
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	_target = weakref(target)
	if is_instance_valid(scope):
		_scope = weakref(scope)
		# An incomplete registry interface must fail closed, not silently fall back.
		_tracked = scope.has_method("get_battle_entity_handle") or scope.has_method("resolve_battle_entity")
		if _tracked:
			if not scope.has_method("get_battle_entity_handle") or not scope.has_method("resolve_battle_entity"):
				clear()
				return false
			_handle = scope.call("get_battle_entity_handle", target)
	if resolve(scope) == null:
		clear()
		return false
	return true

func resolve(scope: Node) -> Node:
	if _target == null:
		return null
	var target = _target.get_ref()
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return null
	if _scope != null:
		var captured_scope = _scope.get_ref()
		if not is_instance_valid(captured_scope) or captured_scope.is_queued_for_deletion() or captured_scope != scope:
			return null
	elif is_instance_valid(scope):
		return null
	if _tracked:
		if _handle == Vector3i.ZERO or scope.call("resolve_battle_entity", _handle) != target:
			return null
	return target as Node

func clear() -> void:
	_target = null
	_scope = null
	_tracked = false
	_handle = Vector3i.ZERO
