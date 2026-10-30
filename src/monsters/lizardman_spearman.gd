extends "res://src/monsters/lizardman_fighter.gd"
const CLOCK_LIZARDMAN_SPEARMAN = preload("res://src/systems/battle_clock.gd")
const SPEAR := preload("res://src/data/lizardman_spearman_behavior_catalog.gd")
const PROJECTILE := preload("res://src/monsters/LizardSpearProjectile.tscn")
var projectile_speed := SPEAR.PROJECTILE_SPEED
var projectile_range := SPEAR.RANGED_RANGE
var melee_range_snapshot := -1.0
var ranged_attack_speed_multiplier := 1.6
var elite_charge := false
var elite_ready := false
var ready_stacks := 0
var charge_timer := SPEAR.CHARGE_INITIAL
var charging := false
var charge_remaining := 0.0
var charge_bonus_pending := false
var reposition_remaining := 0.0
var reposition_goal := Vector2.ZERO
var reposition_side := 1.0

func _init() -> void:
	monster_type = "lizardman_spearman"
	monster_role = "exploder"
	max_hp = SPEAR.BASE.max_hp
	attack_damage = SPEAR.BASE.attack_damage
	move_speed = SPEAR.BASE.move_speed
	attack_range = SPEAR.BASE.attack_range
	attack_cooldown = SPEAR.BASE.attack_cooldown
	exp_reward = SPEAR.BASE.exp_reward
	set_meta("noncollision_family",DATA.FAMILY)

func _ready() -> void:
	super._ready()
	apply_visual_profile(SPEAR.NORMAL_VISUAL)

func is_ranged_mode() -> bool:
	return special_augment_configs.has("lizard_spear_throw")

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if melee_range_snapshot < 0.0: melee_range_snapshot = attack_range
	var ranged := is_ranged_mode()
	var conversion: Dictionary = configs.get("lizard_spear_throw",{})
	var stats: Dictionary = conversion.get("runtime_stat_multipliers",SPEAR.RANGED_STATS)
	for key in runtime_additions: runtime_additions[key] = float(stats.get(key,1.0)) if ranged else 1.0
	if ranged:
		ranged_attack_speed_multiplier = float(stats.get("attack_speed_multiplier",1.6))
		runtime_additions.attack_speed_multiplier *= 1.0+ready_stacks*SPEAR.READY_STEP
		charging = false
		charge_bonus_pending = false
	monster_role = "ranged" if ranged else "exploder"
	set_meta("combat_attack_type","ranged" if ranged else "melee")
	attack_range = SPEAR.RANGED_RANGE*(melee_range_snapshot/SPEAR.BASE.attack_range) if ranged else melee_range_snapshot
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)

func configure_elite_passive(skill: Dictionary) -> void:
	if String(skill.get("id","")) == "elite_lizard_spear_charge": elite_charge = true
	if String(skill.get("id","")) == "elite_lizard_spear_ready": elite_ready = true

func _can_act() -> bool:
	return not dying and current_hp > 0 and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func _attack_target(target: Node2D) -> void:
	if not _can_act() or not is_instance_valid(target): return
	if is_ranged_mode():
		if not _throw_spear(target): return
		if elite_ready:
			ready_stacks = mini(ready_stacks+1,SPEAR.READY_MAX_STACKS)
			runtime_additions.attack_speed_multiplier = ranged_attack_speed_multiplier*(1.0+ready_stacks*SPEAR.READY_STEP)
			if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
				combat_authority.refresh_monster_runtime_stats(self)
			attack_timer = minf(attack_timer,attack_cooldown)
	else:
		var amount := int(round(attack_damage*SPEAR.CHARGE_MULTIPLIER)) if charge_bonus_pending else attack_damage
		charge_bonus_pending = false
		var landed = target.call("take_damage",amount,self)
		if landed != false: on_spear_contact(target)
	if special_augment_configs.has("lizard_spear_footwork"): _begin_reposition(target)

func _throw_spear(target: Node2D) -> bool:
	var parent := get_parent()
	var projectile = parent.acquire_projectile(PROJECTILE,"lizard_spear_projectile") if parent.has_method("acquire_projectile") else PROJECTILE.instantiate()
	if projectile == null: return false
	if projectile.get_parent() == null: parent.add_child(projectile)
	var aim := target.global_position-global_position
	projectile.global_position = global_position
	projectile.setup(self,aim,attack_damage,attack_range,String(get_meta("visual_variant","")) == "elite")
	return true

func on_spear_contact(target: Node) -> void:
	if not special_augment_configs.has("lizard_spear_repulse") or not is_instance_valid(target) or not target is Node2D: return
	if target.get("current_hp") != null and int(target.get("current_hp")) <= 0: return
	if not MONSTER_RUNTIME_COMMON.can_be_forced_moved(target): return
	if target.has_method("is_movement_effect_immune") and bool(target.call("is_movement_effect_immune")): return
	var offset: Vector2 = target.global_position-global_position
	if offset.length() > SPEAR.CLOSE_HIT_RANGE: return
	var direction := offset.normalized() if offset.length_squared()>0.01 else Vector2(visual_facing_sign,0)
	if target is CharacterBody2D: target.move_and_collide(direction*SPEAR.KNOCKBACK_DISTANCE)
	else: target.global_position += direction*SPEAR.KNOCKBACK_DISTANCE
	MONSTER_RUNTIME_COMMON.notify_forced_position_change(target)

func _begin_reposition(target: Node2D) -> void:
	if not is_instance_valid(target): return
	var offset := global_position-target.global_position
	var angle := offset.angle() if offset.length_squared()>0.01 else PI
	var radius := clampf(offset.length(),45.0,attack_range*0.85)
	reposition_side *= -1.0
	for side in [reposition_side,-reposition_side]:
		var point := target.global_position+Vector2.from_angle(angle+SPEAR.REPOSITION_ANGLE*side)*radius
		if is_instance_valid(combat_authority) and combat_authority.has_method("_clamp_manual_spawn_position"):
			point = combat_authority.call("_clamp_manual_spawn_position",point)
		if point.distance_to(target.global_position) <= attack_range and point.distance_to(global_position)>8.0:
			reposition_goal = point
			reposition_remaining = SPEAR.REPOSITION_SECONDS
			return

func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_LIZARDMAN_SPEARMAN.scaled(self, delta)
	if dying or current_hp <= 0: return
	if escape_remaining > 0.0:
		charging = false
		charge_bonus_pending = false
		reposition_remaining = 0.0
		super._physics_process(clock_raw_delta)
		return
	charge_timer = maxf(charge_timer-delta,0.0)
	if not _can_act():
		velocity = Vector2.ZERO
		return
	if is_ranged_mode() and charging:
		charging = false
		charge_bonus_pending = false
	if charging:
		_tick_charge(delta)
		return
	if elite_charge and not is_ranged_mode() and not bool(get_meta("silence_active",false)) and charge_timer <= 0.0 and is_instance_valid(hero) and int(hero.get("current_hp")) > 0:
		charging = true
		charge_remaining = SPEAR.CHARGE_LIMIT
		charge_timer = SPEAR.CHARGE_COOLDOWN
		reposition_remaining = 0.0
		_tick_charge(delta)
		return
	if reposition_remaining > 0.0:
		attack_timer = maxf(attack_timer-delta,0.0)
		var offset := reposition_goal-global_position
		var step := minf(offset.length(),move_speed*delta)
		var collision = move_and_collide(offset.normalized()*step)
		velocity = offset.normalized()*move_speed
		_update_visual_motion(velocity.x,true)
		reposition_remaining = maxf(reposition_remaining-delta,0.0)
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
		if collision != null or offset.length() <= step+0.1: reposition_remaining = 0.0
		return
	super._physics_process(clock_raw_delta)

func _tick_charge(delta: float) -> void:
	if not is_instance_valid(hero) or int(hero.get("current_hp")) <= 0:
		charging = false
		velocity = Vector2.ZERO
		return
	var offset := hero.global_position-global_position
	var distance := offset.length()
	if distance <= attack_range+0.1:
		charging = false
		charge_bonus_pending = true
		velocity = Vector2.ZERO
		_visual_call(&"play_attack")
		_attack_target(hero)
		attack_timer = attack_cooldown
		return
	velocity = offset.normalized()*SPEAR.CHARGE_SPEED
	_update_visual_motion(velocity.x,true)
	var collision = move_and_collide(offset.normalized()*minf(maxf(distance-attack_range,0.0),SPEAR.CHARGE_SPEED*delta))
	charge_remaining = maxf(charge_remaining-delta,0.0)
	MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
	if collision != null or charge_remaining <= 0.0:
		charging = false
		velocity = Vector2.ZERO
