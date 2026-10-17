extends RefCounted
## Scoped attack category; distance is never used to guess ranged damage.
static func hit(target: Node, amount: int, kind: String = "untyped", source: Node = null, receipt = null) -> bool:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return false
	var old_kind = target.get_meta("incoming_attack_kind") if target.has_meta("incoming_attack_kind") else null
	var old_source = target.get_meta("_status_damage_source") if target.has_meta("_status_damage_source") else null
	target.set_meta("incoming_attack_kind", kind)
	target.set_meta("_status_damage_source", source)
	var siphon = _siphon_runtime(source)
	if siphon != null and "hero" in siphon and siphon.hero == target: siphon = null
	var hp_before := int(target.get("current_hp")) if siphon != null and "current_hp" in target else 0
	var result = target.call("take_damage_with_result", amount, receipt) if receipt != null else target.call("take_damage", amount)
	if is_instance_valid(target):
		if old_kind == null: target.remove_meta("incoming_attack_kind")
		else: target.set_meta("incoming_attack_kind", old_kind)
		if old_source == null: target.remove_meta("_status_damage_source")
		else: target.set_meta("_status_damage_source", old_source)
	if siphon != null:
		var remaining := maxi(0,int(target.get("current_hp"))) if is_instance_valid(target) and "current_hp" in target else 0
		siphon.absorb_damage(maxi(0,hp_before-remaining))
	return bool(result) if result != null else false

static func _siphon_runtime(source: Node):
	var hero_source: Node = source
	if is_instance_valid(source) and bool(source.get_meta("survival_geometry",false)):
		var battle := source.get_parent()
		if is_instance_valid(battle) and "hero" in battle: hero_source = battle.hero
	elif is_instance_valid(source) and (source.is_in_group("hero_projectiles") or source.is_in_group("hero_summons") or source.is_in_group("hero_summon_projectiles")):
		var battle := source.get_parent()
		if is_instance_valid(battle) and "hero" in battle: hero_source = battle.hero
	if is_instance_valid(hero_source) and "player_weapons" in hero_source:
		var runtime = hero_source.player_weapons
		if runtime != null and runtime.has_method("absorb_damage") and "passive_siphon" in runtime and float(runtime.passive_siphon) > 0.0: return runtime
	return null

static func attack_kind(source: Node) -> String:
	if is_instance_valid(source) and source.has_method("_is_ranged_ai_archetype"):
		return "ranged" if bool(source.call("_is_ranged_ai_archetype")) else "melee"
	return "untyped"

static func reflect_projectile(target: Node, amount: int, source: Node, projectile: Node2D) -> bool:
	if not is_instance_valid(target) or not target.has_method("try_reflect_projectile"): return false
	return bool(target.call("try_reflect_projectile",projectile,amount,source))
