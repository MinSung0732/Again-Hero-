extends "res://src/monsters/orc.gd"
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const BEHAVIOR := preload("res://src/data/dullahan_behavior_catalog.gd")
const PASSIVE: Dictionary = BEHAVIOR.PASSIVE
const DANGER: Dictionary = BEHAVIOR.DANGER
var revive_used := false
var reviving := false
var revive_reverse_started := false
var has_dealt_damage := false
var wall_granted := false
var shield_hp := 0
var wall_max_hp := 0
var danger_cooldown := 0.0
var danger_state := 0 # combat / escape / rest
var escape_target := Vector2.ZERO
var state_timer := 0.0
var rest_heal_elapsed := 0.0
var rest_heal_total := 0
var rest_heal_applied := 0
var charge_timer := 0.0
var charge_multiplier := 2.0
var march_remaining := 0
var march_timer := 0.0
var march_config: Dictionary = {}
var slam_state := 0 # idle / red telegraph / attack
var slam_timer := 0.0
var slam_config: Dictionary = {}
var slam_target: Node2D

func _init() -> void:
	monster_type = "dullahan"
	monster_role = "tank"
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
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(self, COMBAT_STATUS_EFFECT_VISUAL, "slow")
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)

func apply_visual_profile(profile: Dictionary) -> void:
	_sync_wall_capacity()
	visual.apply_visual_profile(profile)

func _sync_wall_capacity() -> void:
	if wall_max_hp > 0 and wall_max_hp != max_hp:
		shield_hp = int(round(float(shield_hp) * max_hp / wall_max_hp))
		wall_max_hp = max_hp

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	_sync_wall_capacity()
	if configs.has("dullahan_dead_wall") and not wall_granted and not has_dealt_damage:
		wall_granted = true
		wall_max_hp = max_hp
		shield_hp = int(round(max_hp * float(configs.dullahan_dead_wall.get("shield_hp_ratio", 2.0))))
	if not configs.has("dullahan_dead_wall"):
		shield_hp = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	_sync_wall_capacity()
	if reviving:
		_tick_revival()
		return
	if current_hp <= 0 or dying:
		return
	danger_cooldown = maxf(danger_cooldown - delta, 0.0)
	charge_timer = maxf(charge_timer - delta, 0.0)
	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		if danger_state != 0:
			_tick_danger(delta, false)
		return
	_tick_march(delta)
	hero_target_refresh_timer = maxf(hero_target_refresh_timer - delta, 0.0)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(hero_target_refresh_timer, hero):
		_refresh_combat_target()
	attack_timer = maxf(attack_timer - delta, 0.0)
	if danger_state != 0:
		_tick_danger(delta)
		return
	if slam_state != 0:
		_tick_slam(delta)
		return
	if current_hp <= int(max_hp * float(DANGER.threshold)) and danger_cooldown <= 0.0:
		_start_danger()
		_tick_danger(delta)
		return
	if not is_instance_valid(hero):
		velocity = Vector2.ZERO
		_update_visual_motion(0.0, false)
		return
	soft_separation_timer = maxf(soft_separation_timer - delta, 0.0)
	if soft_separation_timer <= 0.0:
		soft_separation_bias = MONSTER_RUNTIME_COMMON.compute_soft_separation_bias(self, combat_authority)
		soft_separation_timer = MONSTER_RUNTIME_COMMON.next_soft_separation_delay()
	var offset := hero.global_position - global_position
	_update_visual_lod(offset.length_squared())
	if offset.length_squared() > attack_range * attack_range:
		var speed := move_speed * MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		if special_augment_configs.has("dullahan_dead_wall"):
			speed *= float(special_augment_configs.dullahan_dead_wall.get("approach_multiplier", 0.70))
		if charge_timer > 0.0:
			speed *= charge_multiplier
		far_ai_tick_timer = maxf(far_ai_tick_timer - delta, 0.0)
		if MONSTER_RUNTIME_COMMON.should_refresh_far_navigation(offset.length_squared(), FAR_NAV_DISTANCE * FAR_NAV_DISTANCE, far_ai_tick_timer):
			cached_direction_to_hero = offset.normalized()
			far_ai_tick_timer = MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
		var direction := MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(cached_direction_to_hero, soft_separation_bias)
		velocity = direction * speed
		_update_visual_motion(direction.x, true)
		if offset.length_squared() > FAR_NAV_DISTANCE * FAR_NAV_DISTANCE:
			global_position += velocity * delta
		else:
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		_update_visual_motion(offset.x, false)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			_visual_call(&"play_attack")
			_deal_hit(hero, attack_damage)

func _deal_hit(target: Node2D, amount: int, stun_duration: float = 0.0) -> int:
	var previous_action := STATUS_SCOPE.begin(target,STATUS_SCOPE.action_or_new(target))
	var result := _status_scoped_deal_hit(target,amount,stun_duration)
	STATUS_SCOPE.finish(target,previous_action)
	return result

func _status_scoped_deal_hit(target: Node2D, amount: int, stun_duration: float = 0.0) -> int:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	# Some hero summons expose a void damage method; health deltas determine
	# actual damage consistently for both those targets and the main hero.
	target.call("take_damage", amount, self)
	var applied := maxi(before - int(target.get("current_hp")), 0) + int(round(maxf(shield_before - float(target.get("shield_hp") if target.get("shield_hp") != null else 0.0), 0.0)))
	if applied <= 0:
		return 0
	if target.is_in_group("hero"):
		has_dealt_damage = true
		shield_hp = 0
	var empowered: Dictionary = special_augment_configs.get("dullahan_immortal_thirst", {})
	heal_direct(int(round(applied * float(empowered.get("lifesteal_ratio", PASSIVE.lifesteal_ratio)))))
	if special_augment_configs.has("dullahan_soul_shackles"):
		var config: Dictionary = special_augment_configs.dullahan_soul_shackles
		var stacks := int(target.get_meta("dullahan_soul_stacks", 0)) + 1
		if stacks >= int(config.get("stacks_required", 12)):
			stacks = 0
			stun_duration = maxf(stun_duration, float(config.get("stun_duration", 2.0)))
		target.set_meta("dullahan_soul_stacks", stacks)
	if stun_duration > 0.0 and target.has_method("apply_stun"):
		target.call("apply_stun", stun_duration)
	queue_redraw()
	return applied

func take_damage(amount: int) -> void:
	_apply_dullahan_damage(amount)

func supports_damage_receipt() -> bool:
	return get_script().resource_path == "res://src/monsters/dullahan.gd"

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var receipt_revision: int = receipt.begin(self, amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_dullahan_damage(amount, receipt, receipt_revision)
	return receipt.finish(receipt_revision)

func _apply_dullahan_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	_sync_wall_capacity()
	if amount <= 0 or dying or reviving or current_hp <= 0:
		return
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)
	if amount <= 0:
		return
	var absorbed := mini(shield_hp, amount)
	shield_hp -= absorbed
	var applied := mini(current_hp, amount - absorbed)
	current_hp -= applied
	if receipt != null:
		receipt.record_shield(absorbed, receipt_revision)
		receipt.record_hp(applied, receipt_revision)
	DAMAGE_NUMBERS.show(self, applied + absorbed)
	if slam_state == 0:
		_visual_call(&"play_hit")
	queue_redraw()
	if current_hp <= 0:
		_cancel_slam()
		march_remaining = 0
		danger_state = 0
		if not revive_used:
			revive_used = true
			reviving = true
			set_meta("elite_skill_reviving", true)
			velocity = Vector2.ZERO
			collision_shape.set_deferred("disabled", true)
			_visual_call(&"play_revival_death_pose")
		else:
			if receipt == null:
				_begin_death()
			else:
				_begin_death_with_result(receipt, receipt_revision)

func _tick_revival() -> void:
	velocity = Vector2.ZERO
	if revive_reverse_started:
		return
	if is_instance_valid(visual) and visual.has_method("is_revival_death_pose_ready"):
		if not visual.is_revival_death_pose_ready():
			return
		revive_reverse_started = true
		visual.revival_animation_finished.connect(_complete_revival, CONNECT_ONE_SHOT)
		visual.play_revival_reverse()
	else:
		_complete_revival()

func _complete_revival() -> void:
	if not reviving:
		return
	var config: Dictionary = special_augment_configs.get("dullahan_immortal_thirst", {})
	current_hp = maxi(int(round(max_hp * float(config.get("revive_hp_ratio", PASSIVE.revive_hp_ratio)))), 1)
	reviving = false
	revive_reverse_started = false
	set_meta("elite_skill_reviving", false)
	collision_shape.set_deferred("disabled", false)
	visual_moving_state = -1
	queue_redraw()

func _start_danger() -> void:
	danger_state = 1
	danger_cooldown = float(DANGER.cooldown)
	state_timer = float(DANGER.escape_timeout)
	escape_target = _choose_escape_target()
	_cancel_slam()

func _choose_escape_target() -> Vector2:
	var away := global_position - hero.global_position if is_instance_valid(hero) else Vector2.RIGHT
	var hero_motion := Vector2.ZERO
	if hero is CharacterBody2D:
		hero_motion = hero.velocity
	var direction := away.normalized()
	if direction.length_squared() < 0.001:
		direction = hero_motion.normalized() if hero_motion.length_squared() > 0.001 else Vector2.RIGHT
	# Side-step a hero travelling with us instead of following its moving
	# position and repeatedly reversing while the bodies overlap.
	if away.length_squared() < 0.001 or (hero_motion.length_squared() > 0.001 and direction.dot(hero_motion.normalized()) > 0.5):
		direction = Vector2(-direction.y, direction.x)
	var distance := float(DANGER.escape_distance)
	var target := global_position + direction * distance
	if is_instance_valid(combat_authority) and combat_authority.has_method("clamp_monster_wander_position"):
		target = combat_authority.clamp_monster_wander_position(target)
		# Choose the opposite side if the first route runs into a map edge.
		var alternate: Vector2 = combat_authority.clamp_monster_wander_position(global_position - direction * distance)
		if global_position.distance_squared_to(alternate) > global_position.distance_squared_to(target) + 1.0:
			target = alternate
	return target

func _tick_danger(delta: float, can_move: bool = true) -> void:
	state_timer = maxf(state_timer - delta, 0.0)
	if danger_state == 1:
		var away := global_position - hero.global_position if is_instance_valid(hero) else Vector2.RIGHT
		if away.length_squared() >= float(DANGER.escape_distance) * float(DANGER.escape_distance) or global_position.distance_squared_to(escape_target) <= 16.0 * 16.0 or state_timer <= 0.0:
			danger_state = 2
			COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "dullahan_regen")
			state_timer = float(DANGER.rest_duration)
			rest_heal_elapsed = 0.0
			rest_heal_total = maxi(int(round(max_hp * float(DANGER.recover_hp_ratio))) - current_hp, 0)
			rest_heal_applied = 0
			velocity = Vector2.ZERO
			_update_visual_motion(away.x, false)
			return
		if not can_move:
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return
		var direction := global_position.direction_to(escape_target)
		var speed := move_speed * float(DANGER.speed_multiplier) * MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		velocity = direction * minf(speed, global_position.distance_to(escape_target) / maxf(delta, 0.001))
		_update_visual_motion(direction.x, true)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		rest_heal_elapsed = minf(rest_heal_elapsed + delta, float(DANGER.rest_duration))
		var cumulative := int(round(rest_heal_total * rest_heal_elapsed / float(DANGER.rest_duration)))
		heal_direct(mini(cumulative - rest_heal_applied, maxi(int(round(max_hp * float(DANGER.recover_hp_ratio))) - current_hp, 0)))
		rest_heal_applied = cumulative
		if state_timer <= 0.0:
			heal_direct(maxi(int(round(max_hp * float(DANGER.recover_hp_ratio))) - current_hp, 0))
			danger_state = 0

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if reviving or dying or current_hp <= 0 or danger_state != 0 or slam_state != 0 or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return false
	match String(skill.id):
		"elite_dullahan_charge":
			charge_timer = float(skill.duration)
			charge_multiplier = float(skill.speed_multiplier)
		"elite_dullahan_march":
			march_config = skill
			march_remaining = int(skill.count)
			march_timer = float(skill.interval)
		"elite_dullahan_slam":
			if not is_instance_valid(hero) or global_position.distance_squared_to(hero.global_position) > attack_range * attack_range:
				return false
			slam_config = skill
			slam_target = hero
			slam_state = 1
			slam_timer = float(skill.windup)
			visual.modulate = Color(1.0, 0.35, 0.35)
			velocity = Vector2.ZERO
		_:
			return false
	return true

func _tick_march(delta: float) -> void:
	if march_remaining <= 0 or not is_instance_valid(combat_authority):
		return
	march_timer -= delta
	while march_timer <= 0.0 and march_remaining > 0:
		march_timer += float(march_config.interval)
		march_remaining -= 1
		var position_to_use := global_position + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * float(march_config.radius)
		position_to_use = combat_authority.clamp_monster_wander_position(position_to_use)
		var ids: Array = march_config.summon_ids
		var child = combat_authority._spawn_monster(String(ids[randi_range(0, ids.size() - 1)]), position_to_use, 0.0, true, march_config.get("summon_modifiers", {}))
		if is_instance_valid(child):
			MONSTER_RUNTIME_COMMON.begin_summon_animation(child)

func _tick_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	if slam_state == 1:
		slam_timer = maxf(slam_timer - delta, 0.0)
		if slam_timer <= 0.0:
			slam_state = 2
			visual.animation_finished.connect(_finish_slam, CONNECT_ONE_SHOT)
			_visual_call(&"play_attack")
			attack_timer = attack_cooldown

func _finish_slam() -> void:
	if slam_state != 2:
		return
	if is_instance_valid(slam_target) and global_position.distance_squared_to(slam_target.global_position) <= attack_range * attack_range:
		_deal_hit(slam_target, int(round(attack_damage * float(slam_config.damage_multiplier))), float(slam_config.stun_duration))
	_cancel_slam()

func _cancel_slam() -> void:
	slam_state = 0
	slam_target = null
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		if visual.animation_finished.is_connected(_finish_slam):
			visual.animation_finished.disconnect(_finish_slam)

func _draw() -> void:
	if dying or reviving or not is_instance_valid(visual):
		return
	var height := 230.0
	if visual.sprite_frames != null and visual.sprite_frames.has_animation("idle"):
		var texture: Texture2D = visual.sprite_frames.get_frame_texture("idle", 0)
		if texture != null:
			height = texture.get_height() * visual.scale.y
	var bar_y := -height * 0.5 - 12.0
	var width := 120.0
	MONSTER_RUNTIME_COMMON.draw_support_shield_bar(self, width, bar_y)
	draw_rect(Rect2(-width * 0.5, bar_y, width, 8), Color("202024"), true)
	draw_rect(Rect2(-width * 0.5, bar_y, width * clampf(float(current_hp) / maxi(max_hp, 1), 0.0, 1.0), 8), Color("4de673"), true)
	if shield_hp > 0:
		var ratio := minf(float(shield_hp) / float(max_hp * 2), 1.0)
		draw_rect(Rect2(-width * 0.5, bar_y - 10, width * ratio, 6), Color("a4b8ff"), true)
