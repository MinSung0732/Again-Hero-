extends RefCounted

const INTENT := preload("res://src/hero/hero_action_intent.gd")

# Trusted, synchronous local execution only. Future player/network commands
# must validate ownership, life, input bounds and target handles before here.
# This port owns no actor and does not enable any additional game mode.
static func execute_ranged(actor, intent: INTENT) -> bool:
	if not intent.pending or intent.kind != INTENT.Kind.RANGED:
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

static func execute_movement(actor, intent: INTENT) -> bool:
	if not intent.pending or intent.kind != INTENT.Kind.MOVEMENT:
		return false
	var movement := intent.movement_velocity
	intent.clear()
	actor.velocity = movement
	actor._move_and_slide_with_obstacle_escape()
	actor._clamp_to_battlefield()
	return true

static func execute_basic_attack(actor, intent: INTENT, current_target: Node2D) -> bool:
	if not intent.pending or intent.kind != INTENT.Kind.BASIC_ATTACK:
		return false
	var method := intent.attack_kind
	intent.clear()
	# Keep each original attack body and its null-target semantics. In
	# particular, alchemist accepts null to begin a normal vial sequence.
	match method:
		INTENT.AttackKind.ROGUE_COMBO: actor._rogue_combo_attack(current_target)
		INTENT.AttackKind.FIGHTER: actor._fighter_basic_attack(current_target)
		INTENT.AttackKind.GUNNER: actor._gunner_attack(current_target)
		INTENT.AttackKind.BERSERKER: actor._berserker_basic_attack(current_target)
		INTENT.AttackKind.SUMMONER: actor._summoner_basic_attack(current_target)
		INTENT.AttackKind.ALCHEMIST: actor._start_alchemist_basic_attack(current_target)
		_: return false
	return true
