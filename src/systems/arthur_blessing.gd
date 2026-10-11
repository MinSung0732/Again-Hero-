extends Node
const DATA := preload("res://src/data/arthur_behavior_catalog.gd")
# Retained per recipient. Expiration removes only this shield, never other buffs.
var target: Node2D
var authority: Node
var remaining := 0.0
var capacity := 0
func _ready() -> void: set_physics_process(false)
static func grant(actor: Node2D, amount: int, seconds: float, battle: Node) -> void:
	var node = actor.get_node_or_null("ArthurBlessing")
	if node == null:
		node = load("res://src/systems/arthur_blessing.gd").new()
		node.name = "ArthurBlessing"
		node.target = actor
		actor.add_child(node)
	node.authority = battle
	node.capacity = maxi(amount,0)
	node.remaining = seconds
	actor.set_meta("arthur_blessing_hp",node.capacity)
	preload("res://src/monsters/monster_runtime_common.gd").note_shield_grant(actor,"shield")
	actor.set_meta("arthur_blessing_capacity",node.capacity)
	node.set_physics_process(true)
	actor.queue_redraw()
func absorb(amount: int, receipt = null, revision: int = 0) -> int:
	var shield := int(target.get_meta("arthur_blessing_hp",0))
	var paid := mini(maxi(amount,0),shield)
	if paid <= 0: return amount
	target.set_meta("arthur_blessing_hp",shield-paid)
	if receipt != null: receipt.record_shield(paid,revision)
	target.queue_redraw()
	if shield-paid == 0 and remaining > 0:
		target.set_meta("arthur_blessing_capacity",0)
		remaining = 0
		set_physics_process(false)
		var source: Node = target.get_meta("_status_damage_source") if target.has_meta("_status_damage_source") else null
		if not is_instance_valid(source) and is_instance_valid(authority): source = authority.hero
		if is_instance_valid(source):
			# Prevent a reflected hit from re-entering the victim's damage helper.
			_reflect.call_deferred(maxi(int(round(capacity*DATA.BLESSING_REFLECT)),1),weakref(source))
	return amount-paid
func _reflect(amount: int, attacker: WeakRef) -> void:
	var source: Node = attacker.get_ref()
	if not is_instance_valid(source) or not is_instance_valid(authority) or authority.battle_over: return
	if not source.has_method("take_damage"): return
	if "monster_type" in source:
		preload("res://src/monsters/monster_runtime_common.gd").damage_monster_from(source,amount,target)
	else: source.take_damage(amount,target)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(authority) or authority.battle_over:
		clear()
		return
	if authority.external_pause or authority.demon_augment_selection_active: return
	remaining = maxf(remaining-delta,0)
	if remaining <= 0: clear()
func clear() -> void:
	remaining = 0
	if is_instance_valid(target):
		target.set_meta("arthur_blessing_hp",0)
		target.set_meta("arthur_blessing_capacity",0)
		target.queue_redraw()
	set_physics_process(false)
