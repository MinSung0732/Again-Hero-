extends Node2D

var registry: RefCounted
var captured_handle := Vector3i.ZERO
var deactivations := 0
var old_handle_valid_during_deactivation := false

func deactivate_for_pool() -> void:
	deactivations += 1
	old_handle_valid_during_deactivation = registry.resolve(captured_handle) != null
