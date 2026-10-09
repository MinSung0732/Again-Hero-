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
var stun_remaining := 0.0
var silence_remaining := 0.0
var physics_before_stun := false
var bleed_remaining := 0.0
var bleed_duration := 0.0
var bleed_elapsed := 0.0
var bleed_budget := 0
var bleed_paid := 0
var bleed_source: WeakRef
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
static func apply_slow(actor: Node2D, multiplier: float, seconds: float) -> bool:
	if seconds <= 0 or actor.current_hp <= 0: return false
	if actor.has_method("apply_slow"):
		actor.apply_slow(multiplier,seconds)
		return true
	var node := component(actor)
	node.set_physics_process(true)
	node.slow_remaining = maxf(node.slow_remaining,seconds)
	actor.set_meta("received_slow_multiplier",minf(float(actor.get_meta("received_slow_multiplier",1.0)),multiplier))
	return true
static func reset_on(actor: Node2D) -> void:
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node != null: node.clear()
func clear() -> void:
	if stun_remaining > 0 and is_instance_valid(target) and target.current_hp > 0 and (not "active" in target or target.active): target.set_physics_process(physics_before_stun)
	stun_remaining = 0
	silence_remaining = 0
	bleed_remaining = 0
	bleed_source = null
	target.set_meta("stun_active",false)
	target.set_meta("silence_active",false)
	target.set_meta("bleed_active",false)
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
		_tick_extra(delta)
		burn.update(self,delta)
		poison.tick(self,delta)
	target.set_meta("burn_active",burn.remaining > 0.0)
	if burn.remaining <= 0.0 and poison.entries.is_empty() and slow_remaining <= 0.0 and stun_remaining <= 0 and silence_remaining <= 0 and bleed_remaining <= 0: set_physics_process(false)
func take_status_damage(amount: int, source: Node) -> bool:
	return bool(target.take_status_damage(amount,source)) if target.has_method("take_status_damage") else _damage_fallback(amount,source)
func take_recorded_poison_damage(amount: int, source: Node) -> bool:
	return take_status_damage(amount,source)

static func apply_stun(actor: Node2D, seconds: float) -> void:
	if actor.current_hp <= 0 or seconds <= 0: return
	if actor.has_method("apply_stun"):
		actor.apply_stun(seconds)
		return
	var node := component(actor)
	if node.stun_remaining <= 0: node.physics_before_stun = actor.is_physics_processing()
	node.stun_remaining = maxf(node.stun_remaining,seconds)
	actor.set_meta("stun_active",true)
	actor.set_physics_process(false)
	node.set_physics_process(true)
static func apply_silence(actor: Node2D, seconds: float) -> void:
	if actor.current_hp <= 0 or seconds <= 0: return
	if actor.has_method("apply_silence"):
		actor.apply_silence(seconds)
		return
	var node := component(actor)
	node.silence_remaining = maxf(node.silence_remaining,seconds)
	actor.set_meta("silence_active",true)
	node.set_physics_process(true)
static func apply_bleed_current(actor: Node2D, seconds: float, ratio: float, source: Node) -> bool:
	if actor.current_hp <= 0 or bool(actor.get_meta("bleed_active",false)): return false
	if actor.has_method("apply_bleed"):
		return bool(actor.apply_bleed(seconds,source,float(actor.current_hp)*ratio/maxf(float(actor.max_hp),1),false))
	var node := component(actor)
	node.bleed_remaining = seconds
	node.bleed_duration = seconds
	node.bleed_elapsed = 0
	node.bleed_budget = maxi(int(round(actor.current_hp*ratio)),1)
	node.bleed_paid = 0
	node.bleed_source = weakref(source)
	actor.set_meta("bleed_active",true)
	VISUAL.show_on(actor,"bleed")
	node.set_physics_process(true)
	return true
func _tick_extra(delta: float) -> void:
	if stun_remaining > 0:
		stun_remaining = maxf(0,stun_remaining-delta)
		if stun_remaining <= 0:
			target.set_meta("stun_active",false)
			target.set_physics_process(physics_before_stun)
	silence_remaining = maxf(0,silence_remaining-delta)
	target.set_meta("silence_active",silence_remaining > 0)
	if bleed_remaining > 0:
		var step := minf(delta,bleed_remaining)
		bleed_remaining = maxf(0,bleed_remaining-delta)
		bleed_elapsed += step
		var total := int(round(bleed_budget*minf(bleed_elapsed/bleed_duration,1)))
		var amount := total-bleed_paid
		bleed_paid = total
		if amount > 0: take_status_damage(amount,bleed_source.get_ref() if bleed_source != null else null)
		target.set_meta("bleed_active",bleed_remaining > 0)

func _damage_fallback(amount: int, source: Node) -> bool:
	if "monster_type" in target:
		target.take_damage(amount)
		return true
	return bool(target.take_damage(amount,source))
