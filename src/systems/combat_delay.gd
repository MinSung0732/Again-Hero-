extends RefCounted
const BATTLE_CLOCK := preload("res://src/systems/battle_clock.gd")
## A delayed combat action follows its owning Battle, not the UI wall clock.
static func wait(owner: Node, seconds: float) -> void:
	var battle := BATTLE_CLOCK.battle_for(owner)
	var tree := owner.get_tree()
	if not is_instance_valid(battle) or (not battle.hero_player_mode and not battle.online_match_mode):
		await tree.create_timer(seconds, false).timeout
		return
	var owner_ref: WeakRef = weakref(owner)
	var battle_ref: WeakRef = weakref(battle)
	var remaining := maxf(seconds,0.0)
	while remaining > 0.0:
		await tree.process_frame
		var source = owner_ref.get_ref()
		var simulation = battle_ref.get_ref()
		if not is_instance_valid(source) or not source.is_inside_tree() or not is_instance_valid(simulation): return
		if simulation.can_process():
			remaining -= simulation.combat_delta(simulation.get_process_delta_time())

## Absolute status deadlines share the same paused clock on writers/readers.
static func now_msec(owner: Node) -> int:
	var scope := owner
	while is_instance_valid(scope):
		if scope.has_method("combat_time_msec"): return int(scope.call("combat_time_msec"))
		scope = scope.get_parent()
	return Time.get_ticks_msec()
