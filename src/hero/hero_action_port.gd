extends RefCounted

const INTENT := preload("res://src/hero/hero_action_intent.gd")

# Trusted, synchronous local execution only. Future player/network commands
# must validate ownership, life, input bounds and target handles before here.
# This port owns no actor and does not enable any additional game mode.
static func execute_ranged(actor, intent: INTENT) -> bool:
	if not intent.pending:
		return false
	# Consume before callbacks; never replay last frame's movement or attack.
	var movement := intent.movement_velocity
	var distance := intent.observed_attack_distance
	var attack_requested := intent.basic_attack_requested
	intent.clear()
	actor.velocity = movement
	actor._move_and_slide_with_obstacle_escape()
	actor._clamp_to_battlefield()
	if attack_requested and distance <= actor.attack_range and actor.attack_timer <= 0.0:
		# Read the actor's current target after movement, as the original did.
		actor._fire_projectile(actor.target)
	return true
