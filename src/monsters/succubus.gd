extends "res://src/monsters/orc.gd"
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

const EMPTY_CONFIG: Dictionary = {}
const BEHAVIOR := preload("res://src/data/succubus_behavior_catalog.gd")
var infiltration_used := false
var infiltration_timer := 0.0
var infiltration_finished := false
var infiltration_collision_layer := 0
var infiltration_collision_mask := 0
var infiltration_shape_disabled := false
var infiltration_ignore_separation := false
var damage_bank := 0
var runtime_additions: Dictionary = {}
var teleport_query: PhysicsShapeQueryParameters2D
var waltz_active := false
var waltz_elapsed := 0.0
var waltz_index := 0
var waltz_total := 0
var waltz_distributed := 0
var waltz_actual_damage := 0
var waltz_healed := 0
var waltz_config: Dictionary = {}

func _init() -> void:
	monster_type = "succubus"
	monster_role = "controller"
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
	teleport_query = PhysicsShapeQueryParameters2D.new()
	teleport_query.shape = collision_shape.shape
	teleport_query.exclude = [get_rid()]
	teleport_query.margin = 2.0

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if infiltration_finished and is_instance_valid(combat_authority):
		combat_authority._apply_demon_level_scaling_to_monster(self, true)

func get_runtime_stat_additions() -> Dictionary:
	return runtime_additions

func get_attack_growth_multiplier() -> float:
	var ambush: Dictionary = special_augment_configs.get("succubus_shadow_ambush", EMPTY_CONFIG)
	return float(ambush.get("damage_multiplier", 1.0)) if infiltration_finished else 1.0

func is_forced_movement_immune() -> bool:
	return infiltration_timer > 0.0

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	if infiltration_timer > 0.0:
		_tick_infiltration(delta)
		return
	var threshold: Dictionary = special_augment_configs.get("succubus_danger_sense", EMPTY_CONFIG)
	if not infiltration_used and not threshold.is_empty() and current_hp <= int(max_hp * float(threshold.hp_ratio)):
		_start_infiltration()
		return
	if waltz_active:
		_tick_waltz(delta)
		return
	super._physics_process(delta)

func _attack_target(target: Node2D) -> void:
	_deal_hit(target, attack_damage)

func _deal_hit(target: Node2D, amount: int) -> int:
	var previous_action := STATUS_SCOPE.begin(target,STATUS_SCOPE.action_or_new(target))
	var result := _status_scoped_deal_hit(target,amount)
	STATUS_SCOPE.finish(target,previous_action)
	return result

func _status_scoped_deal_hit(target: Node2D, amount: int) -> int:
	if dying or infiltration_timer > 0.0 or not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	if bool(target.get_meta("charm_active", false)):
		amount = int(round(amount * float(BEHAVIOR.CHARM.damage_multiplier)))
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage", amount, self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	var applied := maxi(before - int(target.get("current_hp")), 0) + int(round(maxf(shield_before - shield_after, 0.0)))
	if applied > 0:
		damage_bank += applied
		if target.has_method("register_succubus_hit"):
			target.call("register_succubus_hit", self)
	return applied

func take_damage(amount: int) -> void:
	_apply_succubus_damage(amount)

func supports_damage_receipt() -> bool:
	return get_script().resource_path == "res://src/monsters/succubus.gd"

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var receipt_revision: int = receipt.begin(self, amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_succubus_damage(amount, receipt, receipt_revision)
	return receipt.finish(receipt_revision)

func _apply_succubus_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0 or infiltration_timer > 0.0:
		return
	if waltz_active:
		amount = maxi(int(round(amount * float(waltz_config.get("damage_taken_multiplier", 0.5)))), 0)
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self, amount, receipt, receipt_revision)
	if amount <= 0:
		return
	var previous_hp := current_hp
	var threshold: Dictionary = special_augment_configs.get("succubus_danger_sense", EMPTY_CONFIG)
	var remaining := current_hp - amount
	var can_infiltrate := not infiltration_used and (remaining <= 0 or (not threshold.is_empty() and remaining <= int(max_hp * float(threshold.hp_ratio))))
	current_hp = maxi(remaining, 1 if can_infiltrate else 0)
	# Record before popup callbacks and infiltration's optional recovery.
	if receipt != null:
		receipt.record_hp(previous_hp - current_hp, receipt_revision)
	DAMAGE_NUMBERS.show(self, previous_hp - current_hp)
	if can_infiltrate:
		_start_infiltration()
	elif current_hp <= 0:
		if receipt == null:
			_begin_death()
		else:
			_begin_death_with_result(receipt, receipt_revision)
	else:
		_visual_call(&"play_hit")
	queue_redraw()

func _start_infiltration() -> void:
	if infiltration_used or dying or current_hp <= 0:
		return
	infiltration_used = true
	infiltration_timer = float(BEHAVIOR.INFILTRATION.duration)
	_cancel_waltz()
	velocity = Vector2.ZERO
	set_meta("elite_skill_movement_lock", true)
	set_meta("succubus_infiltration_active", true)
	HERO_TARGET_POLICY.set_hidden(self, true)
	infiltration_collision_layer = collision_layer
	infiltration_collision_mask = collision_mask
	infiltration_shape_disabled = collision_shape.disabled
	infiltration_ignore_separation = bool(get_meta("ignore_monster_separation", false))
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	set_meta("ignore_monster_separation", true)
	visual.play_locomotion(false)
	visual.modulate.a = float(BEHAVIOR.INFILTRATION.alpha)
	var recovery: Dictionary = special_augment_configs.get("succubus_shadow_recovery", EMPTY_CONFIG)
	if not recovery.is_empty():
		heal_direct(maxi(int(round(max_hp * float(recovery.hp_ratio))) - current_hp, 0))
	queue_redraw()

func _tick_infiltration(delta: float) -> void:
	velocity = Vector2.ZERO
	infiltration_timer = maxf(infiltration_timer - delta, 0.0)
	if infiltration_timer > 0.0:
		return
	infiltration_finished = true
	set_meta("elite_skill_movement_lock", false)
	set_meta("succubus_infiltration_active", false)
	HERO_TARGET_POLICY.set_hidden(self, false)
	collision_layer = infiltration_collision_layer
	collision_mask = infiltration_collision_mask
	collision_shape.set_deferred("disabled", infiltration_shape_disabled)
	set_meta("ignore_monster_separation", infiltration_ignore_separation)
	visual.modulate.a = 1.0
	visual_moving_state = -1
	if is_instance_valid(combat_authority):
		combat_authority._apply_demon_level_scaling_to_monster(self, true)
	queue_redraw()

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if dying or current_hp <= 0 or infiltration_timer > 0.0 or waltz_active or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return false
	if String(skill.get("kind", "")) == "drain":
		if damage_bank <= 0:
			return false
		var healing := int(round(damage_bank * float(skill.get("heal_ratio", 0.55))))
		damage_bank = 0
		heal_direct(healing)
		visual.play_skill()
		return true
	var target := combat_authority.get("hero") as Node2D if is_instance_valid(combat_authority) else hero
	if not is_instance_valid(target) or int(target.get("current_hp")) <= 0:
		return false
	if String(skill.get("kind", "")) == "cut":
		var facing := Vector2.RIGHT
		var sprite := target.get_node_or_null("HeroSprite") as AnimatedSprite2D
		if sprite != null and sprite.flip_h:
			facing = Vector2.LEFT
		if not _teleport_near(target, -facing):
			return false
		visual.play_attack()
		COMBAT_STATUS_EFFECT_VISUAL.show_on(target, "succubus_cut", facing.x < 0.0)
		_deal_hit(target, int(round(attack_damage * float(skill.damage_multiplier))))
		return true
	if String(skill.get("kind", "")) == "waltz":
		waltz_config = skill.duplicate(true)
		waltz_active = true
		waltz_elapsed = 0.0
		waltz_index = 0
		waltz_distributed = 0
		waltz_actual_damage = 0
		waltz_healed = 0
		waltz_total = int(round(attack_damage * float(skill.damage_multiplier)))
		velocity = Vector2.ZERO
		visual.modulate.a = float(skill.get("alpha", 0.5))
		set_meta("succubus_waltz_active", true)
		return true
	return false

func _tick_waltz(delta: float) -> void:
	velocity = Vector2.ZERO
	var duration := maxf(float(waltz_config.get("duration", 2.5)), 0.1)
	var interval := maxf(float(waltz_config.get("interval", 0.5)), 0.01)
	var count := maxi(int(round(duration / interval)), 1)
	waltz_elapsed = minf(waltz_elapsed + delta, duration)
	var wanted := mini(int(floor((waltz_elapsed + 0.00001) / interval)), count)
	var target := combat_authority.get("hero") as Node2D
	while waltz_index < wanted and waltz_active and not dying and current_hp > 0:
		waltz_index += 1
		var cumulative := int(round(float(waltz_total) * float(waltz_index) / float(count)))
		var damage := cumulative - waltz_distributed
		waltz_distributed = cumulative
		if is_instance_valid(target) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self) and _teleport_near(target, Vector2.RIGHT.rotated(randf() * TAU)):
			visual.play_attack()
			waltz_actual_damage += _deal_hit(target, damage)
			var total_heal := int(round(waltz_actual_damage * float(waltz_config.get("heal_ratio", 0.4))))
			heal_direct(maxi(total_heal - waltz_healed, 0))
			waltz_healed = total_heal
	if waltz_elapsed >= duration:
		_cancel_waltz()

func _teleport_near(target: Node2D, direction: Vector2) -> bool:
	if teleport_query == null or not is_instance_valid(target):
		return false
	teleport_query.transform = collision_shape.global_transform
	teleport_query.collision_mask = collision_mask & ((1 << 2) | (1 << 3))
	var offset := collision_shape.global_position - global_position
	var space := get_world_2d().direct_space_state
	for i in range(int(BEHAVIOR.TELEPORT.directions)):
		var candidate := target.global_position + direction.rotated(TAU * float(i) / float(BEHAVIOR.TELEPORT.directions)) * float(BEHAVIOR.TELEPORT.distance)
		if is_instance_valid(combat_authority):
			candidate = combat_authority._clamp_manual_spawn_position(candidate)
		if candidate.distance_squared_to(target.global_position) < 48.0 * 48.0:
			continue
		teleport_query.transform.origin = candidate + offset
		if not space.intersect_shape(teleport_query, 1).is_empty():
			continue
		global_position = candidate
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
		velocity = Vector2.ZERO
		return true
	return false

func _cancel_waltz() -> void:
	waltz_active = false
	set_meta("succubus_waltz_active", false)
	if is_instance_valid(visual):
		visual.modulate.a = float(BEHAVIOR.INFILTRATION.alpha) if infiltration_timer > 0.0 else 1.0
	visual_moving_state = -1

func _begin_death() -> void:
	_begin_succubus_death()

func _begin_death_with_result(receipt = null, receipt_revision: int = 0) -> void:
	_begin_succubus_death(receipt, receipt_revision)

func _begin_succubus_death(receipt = null, receipt_revision: int = 0) -> void:
	_cancel_waltz()
	super._begin_death_with_result(receipt, receipt_revision)
	queue_redraw()
