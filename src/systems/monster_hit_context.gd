extends RefCounted
## Scoped attack category; distance is never used to guess ranged damage.
static func hit(target: Node, amount: int, kind: String = "untyped", source: Node = null, receipt = null) -> bool:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return false
	var old_kind = target.get_meta("incoming_attack_kind") if target.has_meta("incoming_attack_kind") else null
	var old_source = target.get_meta("_status_damage_source") if target.has_meta("_status_damage_source") else null
	target.set_meta("incoming_attack_kind", kind)
	target.set_meta("_status_damage_source", source)
	var result = target.call("take_damage_with_result", amount, receipt) if receipt != null else target.call("take_damage", amount)
	if is_instance_valid(target):
		if old_kind == null: target.remove_meta("incoming_attack_kind")
		else: target.set_meta("incoming_attack_kind", old_kind)
		if old_source == null: target.remove_meta("_status_damage_source")
		else: target.set_meta("_status_damage_source", old_source)
	return bool(result) if result != null else false

static func attack_kind(source: Node) -> String:
	if is_instance_valid(source) and source.has_method("_is_ranged_ai_archetype"):
		return "ranged" if bool(source.call("_is_ranged_ai_archetype")) else "melee"
	return "untyped"

static func reflect_projectile(target: Node, amount: int, source: Node, projectile: Node2D) -> bool:
	if not is_instance_valid(target) or not target.has_method("try_reflect_projectile"): return false
	return bool(target.call("try_reflect_projectile",projectile,amount,source))
