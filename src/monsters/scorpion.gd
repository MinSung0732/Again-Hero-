extends "res://src/monsters/orc.gd"
var combo_status_action: RefCounted
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const BEHAVIOR := preload("res://src/data/scorpion_behavior_catalog.gd")
var followup_target: WeakRef
var followup_timer := 0.0
var consume_scratch: Array = []
var absorbed_stats := {"hp":0.0, "damage":0.0, "speed":0.0, "attack_rate":0.0}

func _init() -> void:
	monster_type = "scorpion"
	monster_role = "swarm"
	max_hp = int(BEHAVIOR.BASE.max_hp)
	move_speed = float(BEHAVIOR.BASE.move_speed)
	attack_damage = int(BEHAVIOR.BASE.attack_damage)
	attack_range = float(BEHAVIOR.BASE.attack_range)
	attack_cooldown = float(BEHAVIOR.BASE.attack_cooldown)
	exp_reward = int(BEHAVIOR.BASE.exp_reward)

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	if not is_instance_valid(hero):
		_refresh_combat_target()
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(self, COMBAT_STATUS_EFFECT_VISUAL, "slow")

func _physics_process(delta: float) -> void:
	_tick_followup(delta)
	super._physics_process(delta)

func _attack_target(target: Node2D) -> void:
	combo_status_action = STATUS_SCOPE.action_or_new(target)
	_deal_hit(target, false)
	if not dying and current_hp > 0 and special_augment_configs.has("scorpion_twin_sting") and is_instance_valid(target):
		followup_target = weakref(target)
		followup_timer = minf(BEHAVIOR.FOLLOWUP_DELAY, attack_cooldown * 0.45)

func _tick_followup(delta: float) -> void:
	if followup_target == null:
		return
	followup_timer = maxf(followup_timer - delta, 0.0)
	if followup_timer > 0.0:
		return
	var target := followup_target.get_ref() as Node2D
	followup_target = null
	if dying or current_hp <= 0 or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	if global_position.distance_squared_to(target.global_position) > attack_range * attack_range:
		return
	visual.play_attack()
	_deal_hit(target, true)

func _deal_hit(target: Node2D, followup: bool = false) -> int:
	var previous_action := STATUS_SCOPE.begin(target,combo_status_action if combo_status_action != null else STATUS_SCOPE.action_or_new(target))
	var result := _status_scoped_deal_hit(target,followup)
	STATUS_SCOPE.finish(target,previous_action)
	return result

func _status_scoped_deal_hit(target: Node2D, followup: bool = false) -> int:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	if followup and target.has_method("take_followup_damage"):
		target.call("take_followup_damage", attack_damage, self)
	else:
		target.call("take_damage", attack_damage, self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	var applied := maxi(before - int(target.get("current_hp")), 0) + int(round(maxf(shield_before - shield_after, 0.0)))
	if applied > 0 and target.has_method("apply_damage_poison"):
		var quick: Dictionary = special_augment_configs.get("scorpion_rapid_venom", {})
		target.call("apply_damage_poison", float(quick.get("duration", BEHAVIOR.POISON_DURATION)), applied, self, 1 if followup else 0)
	return applied

func get_runtime_stat_additions() -> Dictionary:
	return absorbed_stats

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if dying or current_hp <= 0 or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return false
	if not is_instance_valid(combat_authority):
		return false
	var radius := float(skill.get("radius", BEHAVIOR.CONSUME.radius))
	combat_authority.fill_monsters_near(global_position, radius, consume_scratch)
	var nearest: Node2D
	var nearest_distance := radius * radius
	for candidate in consume_scratch:
		if not is_instance_valid(candidate) or candidate == self or candidate.is_queued_for_deletion():
			continue
		if String(candidate.get("monster_type")) != monster_type or bool(candidate.get("dying")) or int(candidate.get("current_hp")) <= 0:
			continue
		if String(candidate.get_meta("visual_variant", "normal")) == "elite" or bool(candidate.get_meta("giant_monster", false)):
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance
	consume_scratch.clear()
	if nearest == null:
		return false
	var added_hp := int(nearest.get("max_hp"))
	var previous_hp := current_hp
	absorbed_stats.hp += added_hp
	absorbed_stats.damage += int(nearest.get_meta("support_base_damage", nearest.get("attack_damage")))
	absorbed_stats.speed += float(nearest.get("move_speed"))
	absorbed_stats.attack_rate += 1.0 / maxf(float(nearest.get("attack_cooldown")), 0.01)
	nearest.call("consume_without_rewards")
	combat_authority._apply_demon_level_scaling_to_monster(self, true)
	current_hp = mini(previous_hp + added_hp, max_hp)
	queue_redraw()
	return true

func supports_damage_receipt() -> bool:
	# Incoming damage is inherited unchanged; only death has actor-specific work.
	return get_script().resource_path == "res://src/monsters/scorpion.gd"

func consume_without_rewards() -> void:
	if dying or current_hp <= 0:
		return
	set_meta("death_type", "consumed")
	current_hp = 0
	_begin_death()

func _begin_death() -> void:
	_begin_scorpion_death()

func _begin_death_with_result(receipt = null, receipt_revision: int = 0) -> void:
	_begin_scorpion_death(receipt, receipt_revision)

func _begin_scorpion_death(receipt = null, receipt_revision: int = 0) -> void:
	if dying:
		return
	followup_target = null
	var swamp: Dictionary = special_augment_configs.get("scorpion_death_swamp", {})
	if not swamp.is_empty() and is_instance_valid(combat_authority):
		combat_authority.scorpion_swamp_runtime.spawn(global_position, attack_damage, swamp, self)
	super._begin_death_with_result(receipt, receipt_revision)
	queue_redraw()
