extends RefCounted
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const EFFECTS := preload("res://src/ui/combat_status_effect_visual.gd")
var entries: Dictionary = {}
var expired_ids: Array[int] = []

func _entry(target: Node) -> Dictionary:
	var id := target.get_instance_id()
	if not entries.has(id):
		entries[id] = {"target":weakref(target),"damage_timer":0.0,"speed_timer":0.0}
	return entries[id]

func apply_courage(target: Node2D, duration: float, damage_ratio: float, shield_ratio: float) -> void:
	if not _alive(target):
		return
	var entry := _entry(target)
	var base_damage := int(target.get_meta("support_base_damage",COMMON.get_attack_stat(target))) if float(entry.damage_timer) > 0 else COMMON.get_attack_stat(target)
	entry.damage_timer = maxf(float(entry.damage_timer),duration)
	var multiplier := maxf(float(target.get_meta("support_damage_multiplier",1.0)),1.0 + damage_ratio)
	target.set_meta("support_damage_multiplier",multiplier)
	COMMON.set_unbuffed_attack_damage(target,base_damage)
	var shield := int(round(float(target.get("max_hp")) * shield_ratio))
	target.set_meta("support_shield_hp",maxi(int(target.get_meta("support_shield_hp",0)),shield))
	target.set_meta("support_shield_capacity",maxi(int(target.get_meta("support_shield_capacity",0)),int(target.get_meta("support_shield_hp",0))))
	target.queue_redraw()
	EFFECTS.show_on(target, "support_courage")

func apply_agility(target: Node2D, duration: float, speed_ratio: float) -> void:
	if not _alive(target):
		return
	var entry := _entry(target)
	entry.speed_timer = maxf(float(entry.speed_timer),duration)
	target.set_meta("support_speed_multiplier",maxf(float(target.get_meta("support_speed_multiplier",1.0)),1.0 + speed_ratio))
	EFFECTS.show_on(target, "support_agility")

func tick(delta: float) -> void:
	expired_ids.clear()
	for id in entries:
		var entry: Dictionary = entries[id]
		var target: Node = entry.target.get_ref()
		if not _alive(target):
			if is_instance_valid(target):
				_restore_damage(target)
				target.set_meta("support_speed_multiplier",1.0)
				target.set_meta("support_shield_hp",0)
			expired_ids.append(id)
			continue
		if float(entry.damage_timer) > 0:
			entry.damage_timer = maxf(float(entry.damage_timer) - delta,0.0)
			if float(entry.damage_timer) <= 0:
				_restore_damage(target)
		if float(entry.speed_timer) > 0:
			entry.speed_timer = maxf(float(entry.speed_timer) - delta,0.0)
			if float(entry.speed_timer) <= 0:
				target.set_meta("support_speed_multiplier",1.0)
		if float(entry.damage_timer) <= 0 and float(entry.speed_timer) <= 0:
			expired_ids.append(id)
	for id in expired_ids:
		entries.erase(id)

func _restore_damage(target: Node) -> void:
	if float(target.get_meta("support_damage_multiplier",1.0)) > 1.0:
		var base_damage := int(target.get_meta("support_base_damage",COMMON.get_attack_stat(target)))
		target.set_meta("support_damage_multiplier",1.0)
		COMMON.set_unbuffed_attack_damage(target,base_damage)

func _alive(target: Node) -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and int(target.get("current_hp")) > 0 and not bool(target.get("dying"))
