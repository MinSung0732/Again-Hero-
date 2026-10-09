extends Node
## Lazy, retained status component for enemy summons lacking Hero's status methods.
const BURN := preload("res://src/systems/burn_runtime.gd")
const POISON := preload("res://src/systems/damage_poison_tracker.gd")
const VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
var burn = BURN.new()
var poison = POISON.new()
var target: Node2D
var authority: Node
var slow_remaining := 0.0
var current_hp: int:
	get: return int(target.get("current_hp")) if is_instance_valid(target) else 0
static func component(actor: Node2D) -> Node:
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node == null:
		node = load("res://src/systems/received_afflictions.gd").new()
		node.name = "ReceivedAfflictions"
		node.target = actor
		actor.add_child(node)
	return node
static func apply_burn(actor: Node2D, seconds: float, damage: int, source: Node) -> bool:
	if actor.has_method("apply_burn"): return bool(actor.apply_burn(seconds,damage,source))
	var node := component(actor)
	node.set_physics_process(true)
	var accepted: bool = node.burn.apply(seconds,damage,source)
	if accepted:
		actor.set_meta("burn_active",true)
		VISUAL.show_on(actor,"burn")
	return accepted
static func apply_poison(actor: Node2D, seconds: float, damage: int, source: Node, channel: int) -> bool:
	if actor.has_method("apply_damage_poison"): return bool(actor.apply_damage_poison(seconds,damage,source,channel))
	var node := component(actor)
	node.set_physics_process(true)
	return bool(node.poison.apply(source,damage,seconds,channel))
static func apply_slow(actor: Node2D, multiplier: float, seconds: float) -> void:
	if actor.has_method("apply_slow"):
		actor.apply_slow(multiplier,seconds)
		return
	var node := component(actor)
	node.set_physics_process(true)
	node.slow_remaining = maxf(node.slow_remaining,seconds)
	actor.set_meta("received_slow_multiplier",minf(float(actor.get_meta("received_slow_multiplier",1.0)),multiplier))
static func reset_on(actor: Node2D) -> void:
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node != null: node.clear()
func clear() -> void:
	set_physics_process(false)
	burn.clear()
	poison.clear()
	slow_remaining = 0.0
	target.set_meta("burn_active",false)
	target.set_meta("received_slow_multiplier",1.0)
func _ready() -> void:
	set_physics_process(false)
	authority = target.get_parent()
	while is_instance_valid(authority) and not authority.has_method("get_transcendent_aura_modifier"):
		authority = authority.get_parent()
func _physics_process(delta: float) -> void:
	if is_instance_valid(authority) and (authority.battle_over or authority.external_pause or authority.demon_augment_selection_active): return
	if current_hp <= 0 or ("active" in target and not bool(target.active)):
		clear()
	else:
		slow_remaining = maxf(slow_remaining-delta,0.0)
		if slow_remaining <= 0.0: target.set_meta("received_slow_multiplier",1.0)
		burn.update(self,delta)
		poison.tick(self,delta)
	target.set_meta("burn_active",burn.remaining > 0.0)
	if burn.remaining <= 0.0 and poison.entries.is_empty() and slow_remaining <= 0.0: set_physics_process(false)
func take_status_damage(amount: int, source: Node) -> bool:
	return bool(target.take_status_damage(amount,source)) if target.has_method("take_status_damage") else bool(target.take_damage(amount,source))
func take_recorded_poison_damage(amount: int, source: Node) -> bool:
	return take_status_damage(amount,source)
