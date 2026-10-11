extends Node
const STATUS_RECEIPT = preload("res://src/systems/battle_status_receipt.gd")
var status_receipt = STATUS_RECEIPT.new()
var status_result_complete := false

var target: Node
var burn_remaining: float = 0.0
var burn_tick_timer: float = 0.0
var burn_tick_interval: float = 0.5
var burn_damage: int = 0
var freeze_remaining: float = 0.0
var restore_physics_processing: bool = true

func setup(new_target: Node) -> void:
	target = new_target
	name = "ArchmageElementStatus"

func apply_burn(damage_per_tick: int, duration: float, tick_interval: float) -> void:
	status_result_complete = false
	if not is_instance_valid(target):
		_apply_element_burn(damage_per_tick, duration, tick_interval)
		return
	var revision: int = status_receipt.begin(target,&"element_burn",duration,float(damage_per_tick),damage_per_tick)
	_apply_element_burn(damage_per_tick, duration, tick_interval,status_receipt,revision)
	status_result_complete = status_receipt.finish(revision)

func _apply_element_burn(damage_per_tick: int, duration: float, tick_interval: float, receipt = null, revision: int = 0) -> void:
	if damage_per_tick <= 0 or duration <= 0.0:
		return
	burn_damage = maxi(burn_damage, damage_per_tick)
	burn_remaining = maxf(burn_remaining, duration)
	burn_tick_interval = maxf(tick_interval, 0.05)
	burn_tick_timer = minf(
		burn_tick_timer if burn_tick_timer > 0.0 else burn_tick_interval,
		burn_tick_interval
	)
	if receipt != null:
		receipt.record_application(burn_remaining,float(burn_damage),revision)

func apply_freeze(duration: float) -> void:
	status_result_complete = false
	if not is_instance_valid(target):
		_apply_element_freeze(duration)
		return
	var revision: int = status_receipt.begin(target,&"freeze",duration,1.0)
	_apply_element_freeze(duration,status_receipt,revision)
	status_result_complete = status_receipt.finish(revision)

func _apply_element_freeze(duration: float, receipt = null, revision: int = 0) -> void:
	if duration <= 0.0 or not is_instance_valid(target):
		return
	if freeze_remaining <= 0.0:
		restore_physics_processing = target.is_physics_processing()
		target.set_physics_process(false)
		var velocity_value = target.get("velocity")
		if typeof(velocity_value) == TYPE_VECTOR2:
			target.set("velocity", Vector2.ZERO)
	freeze_remaining = maxf(freeze_remaining, duration)
	if receipt != null:
		receipt.record_application(freeze_remaining,1.0,revision)

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return

	if burn_remaining > 0.0:
		burn_remaining = maxf(burn_remaining - delta, 0.0)
		burn_tick_timer -= delta
		while burn_tick_timer <= 0.0 and burn_remaining > 0.0:
			if target.has_method("take_damage"):
				target.call("take_damage", burn_damage)
			burn_tick_timer += burn_tick_interval

	if freeze_remaining > 0.0:
		freeze_remaining = maxf(freeze_remaining - delta, 0.0)
		if freeze_remaining <= 0.0:
			_restore_target_physics()

	if burn_remaining <= 0.0 and freeze_remaining <= 0.0:
		queue_free()

func _restore_target_physics() -> void:
	if not is_instance_valid(target):
		return
	target.set_physics_process(restore_physics_processing)

func _exit_tree() -> void:
	if freeze_remaining > 0.0:
		_restore_target_physics()
