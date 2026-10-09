extends "res://src/monsters/orc.gd"
var combo_status_action: RefCounted
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const BEHAVIOR := preload("res://src/data/wolf_behavior_catalog.gd")
var howl_timer := 0.0
var howl_buff_timer := 0.0
var pack_cast_timer := 0.0
var followup_timer := 0.0
var followup_target: WeakRef
var followup_damage := 0
var hit_counts: Dictionary = {}

func _init() -> void:
	monster_type = "wolf"
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
	# Battle creates a disabled warmup actor before combat: scan FX alpha and
	# build shared frames there, instead of on the first twelve-wolf release.
	if process_mode == Node.PROCESS_MODE_DISABLED:
		COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "wolf_howl")
		COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "wolf_pack_agility")
	if is_instance_valid(combat_authority):
		combat_authority.wolf_pack_runtime.register(self)

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	howl_buff_timer = maxf(howl_buff_timer - delta, 0.0)
	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		followup_target = null
		super._physics_process(delta)
		return
	if howl_timer > 0.0 or pack_cast_timer > 0.0:
		velocity = Vector2.ZERO
		attack_timer = maxf(attack_timer - delta, 0.0)
		if howl_timer > 0.0:
			howl_timer = maxf(howl_timer - delta, 0.0)
			if howl_timer <= 0.0:
				howl_buff_timer = float(BEHAVIOR.HOWL.duration)
				COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "wolf_howl")
		else:
			pack_cast_timer = maxf(pack_cast_timer - delta, 0.0)
			if pack_cast_timer <= 0.0 and is_instance_valid(combat_authority):
				var facing := -1.0 if visual.flip_h else 1.0
				combat_authority.wolf_pack_runtime.queue_pack(global_position, facing)
		if howl_timer <= 0.0 and pack_cast_timer <= 0.0:
			visual_moving_state = -1
			visual.play_locomotion(false)
		return
	_tick_followup(delta)
	super._physics_process(delta)

func can_howl() -> bool:
	return not dying and current_hp > 0 and howl_timer <= 0.0 and pack_cast_timer <= 0.0 and howl_buff_timer <= float(BEHAVIOR.HOWL.refresh_threshold) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func begin_howl() -> void:
	if not can_howl():
		return
	followup_target = null
	howl_timer = float(BEHAVIOR.HOWL.cast_time)
	velocity = Vector2.ZERO
	visual.play_skill()

func try_cast_elite_skill(_skill: Dictionary) -> bool:
	if dying or current_hp <= 0 or howl_timer > 0.0 or pack_cast_timer > 0.0 or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return false
	followup_target = null
	pack_cast_timer = float(BEHAVIOR.PACK.cast_time)
	velocity = Vector2.ZERO
	visual.play_skill()
	return true

func _attack_target(target: Node2D) -> void:
	if followup_target != null:
		return
	combo_status_action = STATUS_SCOPE.action_or_new(target)
	var total := maxi(int(round(float(attack_damage) * (float(BEHAVIOR.HOWL.damage_multiplier) if howl_buff_timer > 0.0 else 1.0))), 1)
	var first := maxi(int(ceil(float(total) * 0.5)), 1)
	var accepted := _deal_hit(target, first, false)
	if accepted and not dying and current_hp > 0 and is_instance_valid(target):
		followup_damage = total if special_augment_configs.has("wolf_crushing_fang") else maxi(total - first, 0)
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
	if is_instance_valid(target) and not target.is_queued_for_deletion() and int(target.get("current_hp")) > 0 and global_position.distance_squared_to(target.global_position) <= attack_range * attack_range and followup_damage > 0:
		_deal_hit(target, followup_damage, true)

func _deal_hit(target: Node2D, damage: int, followup: bool) -> bool:
	var previous_action := STATUS_SCOPE.begin(target,combo_status_action if combo_status_action != null else STATUS_SCOPE.action_or_new(target))
	var result := _status_scoped_deal_hit(target,damage,followup)
	STATUS_SCOPE.finish(target,previous_action)
	return result

func _status_scoped_deal_hit(target: Node2D, damage: int, followup: bool) -> bool:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return false
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	if followup and target.has_method("take_followup_damage"):
		target.call("take_followup_damage", damage, self)
	else:
		target.call("take_damage", damage, self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	var accepted := before > int(target.get("current_hp")) or shield_before > shield_after
	if accepted and special_augment_configs.has("wolf_blood_scent") and target.has_method("apply_bleed"):
		var id := target.get_instance_id()
		var hits := int(hit_counts.get(id, 0)) + 1
		var config: Dictionary = special_augment_configs.wolf_blood_scent
		if hits >= int(config.get("hits", 3)):
			hits = 0
			target.call("apply_bleed", float(config.get("duration", 3.0)), self, float(config.get("total_max_hp_ratio", 0.01)), true)
		hit_counts[id] = hits
	return accepted

func take_damage(amount: int) -> void:
	if howl_timer > 0.0 and special_augment_configs.has("wolf_iron_howl"):
		amount = maxi(int(round(float(amount) * 0.5)), 1) if amount > 0 else 0
	super.take_damage(amount)

func _visual_call(method: StringName, args: Array = []) -> void:
	if method == &"play_hit" and (howl_timer > 0.0 or pack_cast_timer > 0.0):
		return
	super._visual_call(method, args)

func _begin_death() -> void:
	if dying:
		return
	followup_target = null
	howl_timer = 0.0
	pack_cast_timer = 0.0
	hit_counts.clear()
	if is_instance_valid(combat_authority):
		combat_authority.wolf_pack_runtime.record_death(self)
	super._begin_death()
