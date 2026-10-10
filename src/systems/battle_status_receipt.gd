extends RefCounted

# Caller-owned buffer. Records an accepted application, including legacy refreshes.
var revision := 0
var victim_life := Vector3i.ZERO
var victim_instance_id := 0
var identity_verified := false
var status_id: StringName = &""
var requested_duration := 0.0
var requested_strength := 0.0
var applied_duration := 0.0
var applied_strength := 0.0
var accepted := false
var complete := false

func begin(victim: Node, kind: StringName, duration: float, strength: float) -> int:
	revision += 1
	victim_instance_id = victim.get_instance_id()
	var scope := victim.get_parent()
	victim_life = scope.call("get_battle_entity_handle", victim) if is_instance_valid(scope) and scope.has_method("get_battle_entity_handle") else Vector3i.ZERO
	identity_verified = victim_life != Vector3i.ZERO and scope.has_method("resolve_battle_entity") and scope.call("resolve_battle_entity", victim_life) == victim
	status_id = kind
	requested_duration = duration
	requested_strength = strength
	applied_duration = 0.0
	applied_strength = 0.0
	accepted = false
	complete = false
	return revision

func record_application(duration: float, strength: float, expected_revision: int) -> void:
	if revision == expected_revision:
		applied_duration = duration
		applied_strength = strength
		accepted = true

func finish(expected_revision: int) -> bool:
	if revision != expected_revision:
		return false
	complete = true
	return true
