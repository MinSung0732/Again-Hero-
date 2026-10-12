extends RefCounted
const DATA := preload("res://src/data/gumiho_behavior_catalog.gd")
var stacks: Dictionary = {}
func reset() -> void: stacks.clear()
func get_stacks(target: Node) -> int:
	return int(stacks.get(target.get_instance_id(),0)) if is_instance_valid(target) else 0
func record_attack(caster: Node2D,target: Node) -> void:
	if not is_instance_valid(target) or not target.has_method("apply_charm") or int(target.get("current_hp")) <= 0 or bool(target.get_meta("charm_active",false)) or float(target.get("charm_immunity_timer")) > 0.0: return
	var id := target.get_instance_id()
	var count := int(stacks.get(id,0))+1
	stacks[id] = count
	if count < DATA.CHARM_STACKS: return
	stacks[id] = 0
	var old = target.get_meta("incoming_charm_immunity") if target.has_meta("incoming_charm_immunity") else null
	target.set_meta("incoming_charm_immunity",DATA.CHARM_IMMUNITY)
	target.call("apply_charm",caster,DATA.CHARM_DURATION)
	if old == null: target.remove_meta("incoming_charm_immunity")
	else: target.set_meta("incoming_charm_immunity",old)
