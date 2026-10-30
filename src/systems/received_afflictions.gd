extends Node
const CLOCK_RECEIVED_AFFLICTIONS = preload("res://src/systems/battle_clock.gd")
const STATUS_RECEIPT = preload("res://src/systems/battle_status_receipt.gd")
var status_receipt = STATUS_RECEIPT.new()
var status_result_complete := false
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")
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
	var status_revision: int = node.status_receipt.begin(actor,&"burn",seconds,1.0,damage)
	node.set_physics_process(true)
	var accepted: bool = node.burn.apply(seconds,damage,source)
	if accepted:
		node.status_receipt.record_application(node.burn.remaining,1.0,status_revision)
		node.status_receipt.record_damage_budget(node.burn.total,status_revision)
		actor.set_meta("burn_active",true)
		VISUAL.show_on(actor,"burn")
	node.status_result_complete = node.status_receipt.finish(status_revision)
	return accepted
static func apply_poison(actor: Node2D, seconds: float, damage: int, source: Node, channel: int) -> bool:
	if actor.has_method("apply_damage_poison"): return bool(actor.apply_damage_poison(seconds,damage,source,channel))
	var node := component(actor)
	var status_revision: int = node.status_receipt.begin(actor,&"poison",seconds,1.0,damage)
	node.set_physics_process(true)
	var accepted := bool(node.poison.apply(source,damage,seconds,channel))
	if accepted:
		node.status_receipt.record_application(seconds,1.0,status_revision)
		node.status_receipt.record_damage_budget(damage,status_revision)
	node.status_result_complete = node.status_receipt.finish(status_revision)
	return accepted
static func apply_slow(actor: Node2D, multiplier: float, seconds: float, action: RefCounted = null) -> bool:
	if seconds <= 0 or actor.current_hp <= 0:
		_invalidate_component_result(actor)
		return false
	if actor.has_method("apply_slow"):
		var previous := STATUS_SCOPE.begin(actor,action)
		actor.apply_slow(multiplier,seconds)
		STATUS_SCOPE.finish(actor,previous)
		return true
	var node := component(actor)
	var status_revision: int = node.status_receipt.begin(actor,&"slow",seconds,1.0-multiplier)
	node.set_physics_process(true)
	node.slow_remaining = maxf(node.slow_remaining,seconds)
	actor.set_meta("received_slow_multiplier",minf(float(actor.get_meta("received_slow_multiplier",1.0)),multiplier))
	node.status_receipt.record_application(node.slow_remaining,1.0-float(actor.get_meta("received_slow_multiplier",1.0)),status_revision)
	node.status_result_complete = node.status_receipt.finish(status_revision)
	return true
static func reset_on(actor: Node2D) -> void:
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node != null: node.clear()
func clear() -> void:
	status_result_complete = false
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
	delta = CLOCK_RECEIVED_AFFLICTIONS.scaled(self, delta)
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

static func apply_stun(actor: Node2D, seconds: float, action: RefCounted = null) -> void:
	if actor.current_hp <= 0 or seconds <= 0:
		_invalidate_component_result(actor)
		return
	if actor.has_method("apply_stun"):
		var previous := STATUS_SCOPE.begin(actor,action)
		actor.apply_stun(seconds)
		STATUS_SCOPE.finish(actor,previous)
		return
	var node := component(actor)
	var status_revision: int = node.status_receipt.begin(actor,&"stun",seconds,1.0)
	if node.stun_remaining <= 0: node.physics_before_stun = actor.is_physics_processing()
	node.stun_remaining = maxf(node.stun_remaining,seconds)
	actor.set_meta("stun_active",true)
	actor.set_physics_process(false)
	node.set_physics_process(true)
	node.status_receipt.record_application(node.stun_remaining,1.0,status_revision)
	node.status_result_complete = node.status_receipt.finish(status_revision)
static func apply_silence(actor: Node2D, seconds: float, action: RefCounted = null) -> void:
	if actor.current_hp <= 0 or seconds <= 0:
		_invalidate_component_result(actor)
		return
	if actor.has_method("apply_silence"):
		var previous := STATUS_SCOPE.begin(actor,action)
		actor.apply_silence(seconds)
		STATUS_SCOPE.finish(actor,previous)
		return
	var node := component(actor)
	var status_revision: int = node.status_receipt.begin(actor,&"silence",seconds,1.0)
	node.silence_remaining = maxf(node.silence_remaining,seconds)
	actor.set_meta("silence_active",true)
	node.set_physics_process(true)
	node.status_receipt.record_application(node.silence_remaining,1.0,status_revision)
	node.status_result_complete = node.status_receipt.finish(status_revision)
static func apply_bleed_current(actor: Node2D, seconds: float, ratio: float, source: Node, action: RefCounted = null) -> bool:
	if actor.current_hp <= 0 or bool(actor.get_meta("bleed_active",false)):
		_invalidate_component_result(actor)
		return false
	if actor.has_method("apply_bleed"):
		var previous := STATUS_SCOPE.begin(actor,action)
		var accepted := bool(actor.apply_bleed(seconds,source,float(actor.current_hp)*ratio/maxf(float(actor.max_hp),1),false))
		STATUS_SCOPE.finish(actor,previous)
		return accepted
	var node := component(actor)
	var status_revision: int = node.status_receipt.begin(actor,&"bleed",seconds,ratio)
	node.bleed_remaining = seconds
	node.bleed_duration = seconds
	node.bleed_elapsed = 0
	node.bleed_budget = maxi(int(round(actor.current_hp*ratio)),1)
	node.bleed_paid = 0
	node.bleed_source = weakref(source)
	actor.set_meta("bleed_active",true)
	node.status_receipt.record_application(node.bleed_remaining,float(node.bleed_budget)/maxi(actor.current_hp,1),status_revision)
	node.status_receipt.record_damage_budget(node.bleed_budget,status_revision)
	VISUAL.show_on(actor,"bleed")
	node.set_physics_process(true)
	node.status_result_complete = node.status_receipt.finish(status_revision)
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
		preload("res://src/monsters/monster_runtime_common.gd").damage_monster_from(target,amount,source)
		return true
	return bool(target.take_damage(amount,source))

static func _supports_result(actor: Node2D, method: StringName) -> bool:
	# Native actors opt in; generic components expose their own recorded result.
	# An unavailable result must never trigger another application.
	return actor.has_method("supports_status_receipt") and actor.supports_status_receipt() and actor.has_method(method)

static func _reject_result(actor: Node2D, kind: StringName, seconds: float, strength: float, receipt) -> bool:
	return receipt.finish(receipt.begin(actor,kind,seconds,strength))

static func apply_slow_with_result(actor: Node2D, multiplier: float, seconds: float, receipt, action: RefCounted = null) -> bool:
	if receipt == null:
		apply_slow(actor,multiplier,seconds,action)
		return false
	if not _supports_result(actor,&"apply_slow_with_result"):
		var revision: int = receipt.begin(actor,&"slow",seconds,1.0-multiplier)
		if actor.has_method("apply_slow"):
			apply_slow(actor,multiplier,seconds,action)
			return false
		if seconds <= 0 or actor.current_hp <= 0:
			return receipt.finish(revision)
		apply_slow(actor,multiplier,seconds,action)
		return _copy_component_result(actor,receipt,revision)
	# The adapter's duration guard is stricter than native Hero's minimum time.
	if seconds <= 0 or actor.current_hp <= 0:
		return _reject_result(actor,&"slow",seconds,1.0-multiplier,receipt)
	var previous := STATUS_SCOPE.begin(actor,action)
	var completed: bool = actor.apply_slow_with_result(multiplier,seconds,receipt)
	STATUS_SCOPE.finish(actor,previous)
	return completed

static func apply_stun_with_result(actor: Node2D, seconds: float, receipt, action: RefCounted = null) -> bool:
	if receipt == null:
		apply_stun(actor,seconds,action)
		return false
	if not _supports_result(actor,&"apply_stun_with_result"):
		var revision: int = receipt.begin(actor,&"stun",seconds,1.0)
		if actor.has_method("apply_stun"):
			apply_stun(actor,seconds,action)
			return false
		if actor.current_hp <= 0 or seconds <= 0:
			return receipt.finish(revision)
		apply_stun(actor,seconds,action)
		return _copy_component_result(actor,receipt,revision)
	if actor.current_hp <= 0 or seconds <= 0:
		return _reject_result(actor,&"stun",seconds,1.0,receipt)
	var previous := STATUS_SCOPE.begin(actor,action)
	var completed: bool = actor.apply_stun_with_result(seconds,receipt)
	STATUS_SCOPE.finish(actor,previous)
	return completed

static func apply_silence_with_result(actor: Node2D, seconds: float, receipt, action: RefCounted = null) -> bool:
	if receipt == null:
		apply_silence(actor,seconds,action)
		return false
	if not _supports_result(actor,&"apply_silence_with_result"):
		var revision: int = receipt.begin(actor,&"silence",seconds,1.0)
		if actor.has_method("apply_silence"):
			apply_silence(actor,seconds,action)
			return false
		if actor.current_hp <= 0 or seconds <= 0:
			return receipt.finish(revision)
		apply_silence(actor,seconds,action)
		return _copy_component_result(actor,receipt,revision)
	if actor.current_hp <= 0 or seconds <= 0:
		return _reject_result(actor,&"silence",seconds,1.0,receipt)
	var previous := STATUS_SCOPE.begin(actor,action)
	var completed: bool = actor.apply_silence_with_result(seconds,receipt)
	STATUS_SCOPE.finish(actor,previous)
	return completed

static func apply_bleed_current_with_result(actor: Node2D, seconds: float, ratio: float, source: Node, receipt, action: RefCounted = null) -> bool:
	if receipt == null:
		apply_bleed_current(actor,seconds,ratio,source,action)
		return false
	if not _supports_result(actor,&"apply_bleed_with_result"):
		var revision: int = receipt.begin(actor,&"bleed",seconds,ratio)
		if actor.has_method("apply_bleed"):
			apply_bleed_current(actor,seconds,ratio,source,action)
			return false
		if actor.current_hp <= 0 or bool(actor.get_meta("bleed_active",false)):
			return receipt.finish(revision)
		apply_bleed_current(actor,seconds,ratio,source,action)
		return _copy_component_result(actor,receipt,revision)
	var max_hp_ratio := float(actor.current_hp)*ratio/maxf(float(actor.max_hp),1)
	if actor.current_hp <= 0 or bool(actor.get_meta("bleed_active",false)):
		return _reject_result(actor,&"bleed",seconds,max_hp_ratio,receipt)
	var previous := STATUS_SCOPE.begin(actor,action)
	var completed: bool = actor.apply_bleed_with_result(seconds,receipt,source,max_hp_ratio,false)
	STATUS_SCOPE.finish(actor,previous)
	return completed
static func _copy_component_result(actor: Node2D, receipt, revision: int) -> bool:
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node == null or not node.status_result_complete:
		return false
	var result = node.status_receipt
	if result.accepted:
		receipt.record_application(result.applied_duration,result.applied_strength,revision)
		receipt.record_damage_budget(result.applied_damage_budget,revision)
	return receipt.finish(revision)

static func apply_burn_with_result(actor: Node2D, seconds: float, damage: int, source: Node, receipt) -> bool:
	if receipt == null:
		apply_burn(actor,seconds,damage,source)
		return false
	if _supports_result(actor,&"apply_burn_with_result"):
		return actor.apply_burn_with_result(seconds,damage,receipt,source)
	var revision: int = receipt.begin(actor,&"burn",seconds,1.0,damage)
	apply_burn(actor,seconds,damage,source)
	return false if actor.has_method("apply_burn") else _copy_component_result(actor,receipt,revision)

static func apply_poison_with_result(actor: Node2D, seconds: float, damage: int, source: Node, channel: int, receipt) -> bool:
	if receipt == null:
		apply_poison(actor,seconds,damage,source,channel)
		return false
	if _supports_result(actor,&"apply_damage_poison_with_result"):
		return actor.apply_damage_poison_with_result(seconds,damage,source,receipt,channel)
	var revision: int = receipt.begin(actor,&"poison",seconds,1.0,damage)
	apply_poison(actor,seconds,damage,source,channel)
	return false if actor.has_method("apply_damage_poison") else _copy_component_result(actor,receipt,revision)

static func _invalidate_component_result(actor: Node2D) -> void:
	# Reject without constructing a component, and never expose an older result.
	var node := actor.get_node_or_null("ReceivedAfflictions")
	if node != null: node.status_result_complete = false
