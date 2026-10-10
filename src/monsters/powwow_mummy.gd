extends "res://src/monsters/goblin_thrower.gd"
const BEHAVIOR := preload("res://src/data/powwow_mummy_behavior_catalog.gd")
const SHAMAN_PROJECTILE := preload("res://src/monsters/PowwowMummyProjectile.tscn")
var buff_timer := float(BEHAVIOR.BUFF.interval)
var buff_interval := float(BEHAVIOR.BUFF.interval)
var cast_timer := 0.0
var elite_multi := false
var hit_cooldown_reduction := 0.0
var buff_targets: Array[Node2D] = []
var buff_order: Array[int] = [0,1,2]

func supports_damage_receipt() -> bool:
	# Incoming damage is unchanged; this actor explicitly opts into its parent API.
	return get_script().resource_path == "res://src/monsters/powwow_mummy.gd"

func _init() -> void:
	monster_type = "powwow_mummy"
	monster_role = "ranged"
	max_hp = int(BEHAVIOR.BASE.max_hp)
	move_speed = float(BEHAVIOR.BASE.move_speed)
	attack_damage = int(BEHAVIOR.BASE.attack_damage)
	attack_range = float(BEHAVIOR.BASE.attack_range)
	attack_cooldown = float(BEHAVIOR.BASE.attack_cooldown)
	projectile_speed = float(BEHAVIOR.BASE.projectile_speed)
	projectile_range = float(BEHAVIOR.BASE.projectile_range)
	exp_reward = int(BEHAVIOR.BASE.exp_reward)

func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	var cadence: Dictionary = configs.get("powwow_mummy_quick_ritual",{})
	var next_interval := maxf(float(BEHAVIOR.BUFF.interval) - float(cadence.get("interval_reduction",0.0)),1.0)
	buff_timer = maxf(buff_timer + next_interval - buff_interval,0.0)
	buff_interval = next_interval

func configure_elite_passive(skill: Dictionary) -> void:
	elite_multi = true
	hit_cooldown_reduction = float(skill.get("hit_cooldown_reduction",1.0))

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	buff_timer = maxf(buff_timer - delta,0.0)
	if cast_timer > 0:
		cast_timer = maxf(cast_timer - delta,0.0)
		velocity = Vector2.ZERO
		return
	if buff_timer <= 0 and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		buff_timer = buff_interval
		if _cast_buffs():
			cast_timer = float(BEHAVIOR.BUFF.cast_duration)
			velocity = Vector2.ZERO
			visual.play_skill()
			return
	super._physics_process(delta)

func _cast_buffs() -> bool:
	if not is_instance_valid(combat_authority):
		return false
	buff_targets.clear()
	var count := 3 if elite_multi else 1
	var seen := 0
	for id in combat_authority.active_monsters:
		var ally: Node2D = combat_authority.active_monsters[id]
		if not is_instance_valid(ally) or ally == self or ally.is_queued_for_deletion() or int(ally.get("current_hp")) <= 0 or bool(ally.get("dying")):
			continue
		seen += 1
		if buff_targets.size() < count:
			buff_targets.append(ally)
		else:
			var slot := randi_range(0,seen - 1)
			if slot < count:
				buff_targets[slot] = ally
	buff_order.shuffle()
	for i in range(buff_targets.size()):
		_apply_buff(buff_targets[i],buff_order[i])
	return not buff_targets.is_empty()

func _apply_buff(target: Node2D, kind: int) -> void:
	if not is_instance_valid(target) or int(target.get("current_hp")) <= 0:
		return
	match kind:
		0:
			var config: Dictionary = special_augment_configs.get("powwow_mummy_brave_chant",{})
			var boost := float(config.get("effect_multiplier",1.0))
			combat_authority.support_buff_runtime.apply_courage(target,float(BEHAVIOR.BUFF.duration),float(BEHAVIOR.BUFF.damage_ratio) * boost,float(BEHAVIOR.BUFF.shield_ratio) * boost)
		1:
			var config: Dictionary = special_augment_configs.get("powwow_mummy_restoring_chant",{})
			var missing := maxi(int(target.get("max_hp")) - int(target.get("current_hp")),0)
			var amount := int(round(missing * float(BEHAVIOR.BUFF.heal_missing_ratio) * float(config.get("effect_multiplier",1.0))))
			if target.has_method("heal_direct"):
				var recovered := int(target.call("heal_direct",amount))
				if recovered > 0:
					COMBAT_STATUS_EFFECT_VISUAL.show_on(target, "support_heal")
		2:
			combat_authority.support_buff_runtime.apply_agility(target,float(BEHAVIOR.BUFF.duration),float(BEHAVIOR.BUFF.speed_ratio))

func _fire_projectile(offset_to_hero: Vector2) -> void:
	if offset_to_hero.length_squared() <= 0.001 or not is_instance_valid(combat_authority):
		return
	var projectile = combat_authority.acquire_projectile(SHAMAN_PROJECTILE,"powwow_mummy_projectile")
	var direction := offset_to_hero.normalized()
	projectile.global_position = global_position + direction * 24.0
	projectile.setup(direction,attack_damage,projectile_speed,projectile_range,String(get_meta("visual_variant","")) == "elite")
	projectile.source_ref = weakref(self)

func on_projectile_damage() -> void:
	if not dying and current_hp > 0 and elite_multi:
		buff_timer = maxf(buff_timer - hit_cooldown_reduction,0.0)
