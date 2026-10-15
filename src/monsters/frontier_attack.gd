extends RefCounted
## Shared hit payload; one token per cast, copied only on attack, never per frame.
const SCOPE := preload("res://src/systems/status_action_scope.gd")

static func target_alive(target: Node) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion(): return false
	if target.get("current_hp") != null and int(target.get("current_hp")) <= 0: return false
	if target.get("active") != null and not bool(target.get("active")): return false
	return not target.has_method("is_combat_targetable") or bool(target.call("is_combat_targetable"))

static func hit(target: Node, amount: int, owner: Node, payload: Dictionary, action: RefCounted) -> void:
	if not target_alive(target) or not target.has_method("take_damage"): return
	var previous := SCOPE.begin(target,action)
	var before := int(target.get("current_hp")) if target.get("current_hp") != null else 0
	target.call("take_damage",maxi(amount,1),owner)
	var applied := maxi(before-int(target.get("current_hp")),0) if is_instance_valid(target) and target.get("current_hp") != null else 0
	# Invulnerability, shields and lethal hits do not grant free extra statuses/healing.
	if applied > 0:
		if target_alive(owner) and owner.has_method("heal_direct") and float(payload.get("lifesteal",0.0)) > 0.0:
			owner.call("heal_direct",int(round(applied*float(payload.lifesteal))))
		if target_alive(target):
			if float(payload.get("slow_duration",0.0)) > 0.0 and target.has_method("apply_slow"):
				target.call("apply_slow",float(payload.get("slow_multiplier",1.0)),float(payload.slow_duration))
			if float(payload.get("poison_ratio",0.0)) > 0.0 and target.has_method("apply_poison"):
				target.call("apply_poison",float(payload.get("poison_duration",3.0)),float(payload.poison_ratio),0.5,owner)
			if float(payload.get("burn_ratio",0.0)) > 0.0 and target.has_method("apply_burn"):
				target.call("apply_burn",float(payload.get("burn_duration",2.0)),maxi(1,int(round(amount*float(payload.burn_ratio)))),owner)
	SCOPE.finish(target,previous)
