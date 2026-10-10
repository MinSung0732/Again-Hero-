extends RefCounted

# Caller owns and reuses this buffer. A nested begin invalidates the older writer.
var revision := 0
var victim_life := Vector3i.ZERO
var victim_instance_id := 0
var identity_verified := false
var requested_damage := 0
var hp_damage := 0
var shield_absorbed := 0
var accepted := false
var death_started := false
var complete := false

func begin(victim: Node, amount: int) -> int:
	revision += 1
	victim_instance_id = victim.get_instance_id()
	var scope := victim.get_parent()
	victim_life = scope.call("get_battle_entity_handle", victim) if is_instance_valid(scope) and scope.has_method("get_battle_entity_handle") else Vector3i.ZERO
	identity_verified = victim_life != Vector3i.ZERO and scope.has_method("resolve_battle_entity") and scope.call("resolve_battle_entity", victim_life) == victim
	requested_damage = amount
	hp_damage = 0
	shield_absorbed = 0
	accepted = false
	death_started = false
	complete = false
	return revision

func record_shield(amount: int, expected_revision: int) -> void:
	if revision == expected_revision:
		shield_absorbed += amount
		accepted = accepted or amount > 0

func record_hp(amount: int, expected_revision: int) -> void:
	if revision == expected_revision:
		hp_damage += amount
		accepted = accepted or amount > 0

func record_death_started(expected_revision: int) -> void:
	if revision == expected_revision:
		death_started = true

func finish(expected_revision: int) -> bool:
	if revision != expected_revision:
		return false
	complete = true
	return true
