extends Node

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
	if damage_per_tick <= 0 or duration <= 0.0:
		return
	burn_damage = maxi(burn_damage, damage_per_tick)
	burn_remaining = maxf(burn_remaining, duration)
	burn_tick_interval = maxf(tick_interval, 0.05)
	burn_tick_timer = minf(
		burn_tick_timer if burn_tick_timer > 0.0 else burn_tick_interval,
		burn_tick_interval
	)

func apply_freeze(duration: float) -> void:
	if duration <= 0.0 or not is_instance_valid(target):
		return
	if freeze_remaining <= 0.0:
		restore_physics_processing = target.is_physics_processing()
		target.set_physics_process(false)
		var velocity_value = target.get("velocity")
		if velocity_value is Vector2:
			target.set("velocity", Vector2.ZERO)
	freeze_remaining = maxf(freeze_remaining, duration)

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
