extends CharacterBody2D
const HERO_ACTION_INTENT := preload("res://src/hero/hero_action_intent.gd")
const HERO_ACTION_PORT := preload("res://src/hero/hero_action_port.gd")
var action_intent = HERO_ACTION_INTENT.new()
# Baseline compatibility only; the real Hero owns one action_intent.
var ranged_action_intent = action_intent
class TargetPolicy:
	static func is_detectable(node: Node) -> bool:
		return is_instance_valid(node) and bool(node.get_meta("detectable", true))
class BurnSpy:
	var remaining := 0.0
	func update(actor, _delta: float) -> void:
		actor.events.append("burn")
const HERO_TARGET_POLICY = TargetPolicy
var burn_runtime = BurnSpy.new()
var events: Array = []
var target: Node2D
var candidate: Node2D
var fighter_charge_target: Node2D
var fighter_charge_active := false
var current_hp := 100
var is_dying := false
var hero_archetype := "ranged_kiter"
var channeling := false
var purifier_gungnir_casting := false
var attack_timer := 0.0
var retarget_timer := 0.0
var wander_timer := 0.0
var attack_pose_timer := 0.0
var hit_pose_timer := 0.0
var ultimate_flash_timer := 0.0
var level_flash_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var possession_immunity_timer := 0.0
var ai_memory_clock := 0.0
var ai_observation_timer := 0.0
var silence_timer := 0.0
var imposed_skill_cooldown := 0.0
var paralysis_timer := 0.0
var paralysis_ratio := 0.0
var petrify_timer := 0.0
var move_speed := 235.0
var attack_range := 650.0
var purifier_speed := 1.0
var stunned := false
var feared := false
var charmed := false
var poison_kills := false
var channel_starts := false
var player_controlled := false
var player_input_suspended := true
var player_weapon_tick_done := false
var player_weapons
var alchemist_philosopher_channeling := false
var alchemist_philosopher_unlock_pending := false
var berserker_reviving := false
var revive_finishes := false
var weapon_starts_channel := false
var mutations: Dictionary = {}
var range_after_move := -1.0
var timer_after_move := -1.0
var replace_target_after_move := false
var replacement_target: Node2D
func _update_poison(_delta: float) -> void:
	events.append("poison")
	if poison_kills:
		current_hp = 0
func _tick_petrify(delta: float) -> void:
	events.append("petrify")
	petrify_timer = maxf(petrify_timer - delta, 0.0)
func _tick_charm_timers(_delta: float) -> bool:
	events.append("charm_timers")
	return charmed
func _tick_stun_state(_delta: float) -> bool:
	events.append("stun")
	if stunned:
		velocity = Vector2.ZERO
	return stunned
func _tick_fear_state(_delta: float) -> bool:
	events.append("fear")
	if feared:
		velocity = Vector2(19, 23)
	return feared
func _tick_charm_state(_delta: float) -> void:
	events.append("charm")
	velocity = Vector2(-13, 7)
func _finish_fighter_charge() -> void:
	events.append("finish_charge")
	fighter_charge_active = false
func _refresh_ai_observation() -> void:
	events.append("observe")
	ai_observation_timer = 0.35
func get_paralysis_attack_multiplier() -> float:
	return 1.0 - paralysis_ratio
func _update_channel_skill(_delta: float) -> void:
	events.append("channel")
	mutate("channel")
	if channel_starts:
		channeling = true
func _find_nearest_monster() -> Node2D:
	events.append("retarget")
	return candidate
func _move_without_monsters() -> void:
	events.append("wander")
	velocity = Vector2(-15, 30)
func _choose_move_direction(_target: Node2D, distance: float) -> Vector2:
	events.append(["choose", distance])
	return Vector2(0.75, -0.25)
func _apply_heal_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("heal_steer")
	return direction + Vector2(0.1, 0.0)
func _apply_chest_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("chest_steer")
	return direction.rotated(0.1)
func _apply_magnet_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("magnet_steer")
	return direction * 0.8
func _apply_archmage_boundary_steering(direction: Vector2) -> Vector2:
	events.append("archmage_boundary")
	return direction.rotated(-0.15)
func _apply_ranged_boundary_escape(direction: Vector2) -> Vector2:
	events.append("ranged_boundary")
	return direction.rotated(0.2)
func _get_effective_move_multiplier() -> float:
	return move_multiplier
func _get_purifier_move_speed_multiplier() -> float:
	return purifier_speed
func _move_and_slide_with_obstacle_escape() -> void:
	events.append("move")
	mutate("move")
	global_position += velocity * 0.016
	if range_after_move >= 0.0:
		attack_range = range_after_move
	if timer_after_move >= 0.0:
		attack_timer = timer_after_move
	if replace_target_after_move:
		target = replacement_target
func _clamp_to_battlefield() -> void:
	events.append("clamp")
	global_position = global_position.clamp(Vector2.ZERO, Vector2(2000, 2000))
func _fire_projectile(current_target: Node2D) -> void:
	events.append(["fire", current_target.get_instance_id() if is_instance_valid(current_target) else 0])
	if is_instance_valid(current_target) and not channeling:
		attack_timer = 1.5

class IdentitySpy extends RefCounted:
	var host
	func tick_revive(_delta: float):
		host.events.append("revive")
		if host.revive_finishes: host.berserker_reviving = false
class WeaponSpy extends RefCounted:
	var host
	var identity
	func tick(_delta: float):
		host.events.append("weapon_tick")
		host.mutate("weapon_tick")
		if host.weapon_starts_channel: host.alchemist_philosopher_channeling = true
func enable_player(identity_present: bool):
	player_controlled = true
	player_weapons = WeaponSpy.new()
	player_weapons.host = self
	if identity_present:
		player_weapons.identity = IdentitySpy.new()
		player_weapons.identity.host = self
func mutate(point: String):
	if mutations.has(point): hero_archetype = mutations[point]
func _player_move_velocity() -> Vector2:
	events.append("player_velocity")
	mutate("player_velocity")
	return Vector2(33, -17)
func snapshot():
	return [events.duplicate(true), hero_archetype, player_input_suspended, player_weapon_tick_done, berserker_reviving, current_hp, is_dying, velocity, global_position, target, fighter_charge_active, attack_timer, retarget_timer, wander_timer, attack_pose_timer, hit_pose_timer, ultimate_flash_timer, level_flash_timer, slow_timer, move_multiplier, possession_immunity_timer, ai_memory_clock, ai_observation_timer, get_meta("burn_active", false), action_intent.kind, action_intent.attack_kind, action_intent.movement_velocity, action_intent.observed_attack_distance, action_intent.basic_attack_requested, action_intent.pending]

func _update_hero_hit_flash(_delta: float) -> void:
	events.append("_update_hero_hit_flash")
	mutate("_update_hero_hit_flash")

func _update_bleed(_delta: float) -> void:
	events.append("_update_bleed")
	mutate("_update_bleed")

func _update_damage_poison(_delta: float) -> void:
	events.append("_update_damage_poison")
	mutate("_update_damage_poison")

func _tick_received_modifiers(_delta: float) -> void:
	events.append("_tick_received_modifiers")
	mutate("_tick_received_modifiers")

func _update_combat_reposition(_delta: float) -> void:
	events.append("_update_combat_reposition")
	mutate("_update_combat_reposition")

func _update_invulnerability(_delta: float) -> void:
	events.append("_update_invulnerability")
	mutate("_update_invulnerability")

func _update_ultimate(_delta: float) -> void:
	events.append("_update_ultimate")
	mutate("_update_ultimate")

func _update_purifier_gauge(_delta: float) -> void:
	events.append("_update_purifier_gauge")
	mutate("_update_purifier_gauge")

func _update_sage_runtime(_delta: float) -> void:
	events.append("_update_sage_runtime")
	mutate("_update_sage_runtime")

func _update_shield_skill(_delta: float) -> void:
	events.append("_update_shield_skill")
	mutate("_update_shield_skill")

func _update_archmage_skill_runtime(_delta: float) -> void:
	events.append("_update_archmage_skill_runtime")
	mutate("_update_archmage_skill_runtime")

func _update_heal_item_goal(_delta: float) -> void:
	events.append("_update_heal_item_goal")
	mutate("_update_heal_item_goal")

func _update_chest_goal(_delta: float) -> void:
	events.append("_update_chest_goal")
	mutate("_update_chest_goal")

func _update_magnet_item_goal(_delta: float) -> void:
	events.append("_update_magnet_item_goal")
	mutate("_update_magnet_item_goal")

func _update_stage1_pose_visual(_delta: float) -> void:
	events.append("_update_stage1_pose_visual")
	mutate("_update_stage1_pose_visual")

func _prune_offensive_memory() -> void:
	events.append("_prune_offensive_memory")

func _prune_status_memory() -> void:
	events.append("_prune_status_memory")

func _physics_process_rogue(_delta: float) -> void:
	events.append("rogue")
	velocity = Vector2(17, -9)
	mutate("rogue")

func _update_rogue_pose_visual(_delta: float) -> void:
	events.append("rogue_pose")
	mutate("rogue_pose")

func _physics_process_fighter(_delta: float) -> void:
	events.append("fighter")
	velocity = Vector2(17, -9)
	mutate("fighter")

func _update_fighter_pose_visual(_delta: float) -> void:
	events.append("fighter_pose")
	mutate("fighter_pose")

func _physics_process_gunner(_delta: float) -> void:
	events.append("gunner")
	velocity = Vector2(17, -9)
	mutate("gunner")

func _update_gunner_pose_visual(_delta: float) -> void:
	events.append("gunner_pose")
	mutate("gunner_pose")

func _physics_process_berserker(_delta: float) -> void:
	events.append("berserker")
	velocity = Vector2(17, -9)
	mutate("berserker")

func _update_berserker_pose_visual(_delta: float) -> void:
	events.append("berserker_pose")
	mutate("berserker_pose")

func _physics_process_alchemist(_delta: float) -> void:
	events.append("alchemist")
	velocity = Vector2(17, -9)
	mutate("alchemist")

func _update_alchemist_pose_visual(_delta: float) -> void:
	events.append("alchemist_pose")
	mutate("alchemist_pose")

func _physics_process_summoner(_delta: float) -> void:
	events.append("summoner")
	velocity = Vector2(17, -9)
	mutate("summoner")

func _update_summoner_pose_visual(_delta: float) -> void:
	events.append("summoner_pose")
	mutate("summoner_pose")
