extends RefCounted

# Scalar observation flags. HP depletion is not an authoritative death receipt:
# actors may revive, absorb, heal, or emit callbacks during take_damage.
const HP_UNKNOWN := 1
const LIFE_CHANGED := 2
const TARGET_GONE := 4
const HP_DEPLETED := 8
const LEGACY_UNTRACKED := 16
const IDENTITY_UNVERIFIED := 32

static func observe_legacy_hit(target: Node, scope: Node, victim_life: Vector3i, hp_before: int) -> int:
	if hp_before < 0:
		return HP_UNKNOWN
	if not is_instance_valid(target):
		return TARGET_GONE if hp_before > 0 else 0
	var flags := 0
	if not is_instance_valid(scope) or scope.is_queued_for_deletion():
		return LIFE_CHANGED
	if scope.has_method("get_battle_entity_handle"):
		if victim_life == Vector3i.ZERO:
			return LIFE_CHANGED | IDENTITY_UNVERIFIED
		var last_life: Vector3i
		if scope.has_method("get_last_battle_entity_handle"):
			last_life = scope.call("get_last_battle_entity_handle", target)
			if last_life != victim_life:
				return LIFE_CHANGED
		else:
			# Legacy adapter cannot distinguish retire from reuse followed by retire.
			last_life = scope.call("get_battle_entity_handle", target)
			if last_life != victim_life and last_life != Vector3i.ZERO:
				return LIFE_CHANGED
			flags |= IDENTITY_UNVERIFIED
	else:
		flags |= LEGACY_UNTRACKED | IDENTITY_UNVERIFIED
	var hp_after = target.get("current_hp")
	if hp_after == null:
		return flags | HP_UNKNOWN
	if hp_before > 0 and int(hp_after) <= 0:
		flags |= HP_DEPLETED
	return flags

static func is_legacy_kill_candidate(observation: int) -> bool:
	return (observation & (LIFE_CHANGED | HP_UNKNOWN)) == 0 and (observation & (HP_DEPLETED | TARGET_GONE)) != 0
