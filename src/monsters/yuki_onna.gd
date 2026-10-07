extends "res://src/monsters/goblin_thrower.gd"

const DATA := preload("res://src/data/yuki_onna_behavior_catalog.gd")
const YUKI_PROJECTILE := preload("res://src/monsters/YukiOnnaProjectile.tscn")
var chill_stacks := 0
var chill_timers := PackedFloat32Array()
var max_chill_stacks := int(DATA.CHILL.max_stacks)
var max_slow_stacks := int(DATA.SLOW.max_stacks)
var chill_attack_speed := 1.0
var chill_projectile_speed := 1.0
var chill_slow_strength := 1.0
var elite_snowflake := false

func _init() -> void:
	monster_type = "yuki_onna"
	monster_role = "control"
	max_hp = int(DATA.BASE.max_hp)
	move_speed = float(DATA.BASE.move_speed)
	attack_damage = int(DATA.BASE.attack_damage)
	attack_range = float(DATA.BASE.attack_range)
	attack_cooldown = float(DATA.BASE.attack_cooldown)
	projectile_speed = float(DATA.BASE.projectile_speed)
	projectile_range = float(DATA.BASE.projectile_range)
	exp_reward = int(DATA.BASE.exp_reward)
	chill_timers.resize(8)
	chill_timers.fill(0.0)

func _ready() -> void:
	super._ready()
	if is_instance_valid(combat_authority):
		combat_authority.yuki_runtime.register(self)
		if process_mode == Node.PROCESS_MODE_DISABLED:
			COMBAT_STATUS_EFFECT_VISUAL.show_on(self,"yuki_chill")
			var probe = combat_authority.acquire_projectile(YUKI_PROJECTILE,"yuki_onna_projectile")
			probe._get_frames()
			probe.elite_visual = true
			probe._get_frames()
			combat_authority.recycle_projectile(probe,"yuki_onna_projectile")

func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(DATA.NORMAL_VISUAL)

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	max_chill_stacks = int(DATA.CHILL.max_stacks) + int(configs.get("yuki_eternal_chill",{}).get("extra_stacks",0))
	max_slow_stacks = int(DATA.SLOW.max_stacks) + int(configs.get("yuki_endless_winter",{}).get("extra_stacks",0))

func configure_elite_passive(_skill: Dictionary) -> void:
	elite_snowflake = true
	if is_instance_valid(combat_authority):
		combat_authority.yuki_runtime.register_elite(self)

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	var remaining := 0
	for index in range(chill_stacks):
		var timer := maxf(float(chill_timers[index]) - delta,0.0)
		if timer > 0.0:
			chill_timers[remaining] = timer
			remaining += 1
	if remaining != chill_stacks:
		chill_stacks = remaining
		_refresh_chill_multipliers()
	super._physics_process(delta)

func apply_chill(count: int = 1) -> void:
	if dying or current_hp <= 0:
		return
	var added := mini(count,mini(max_chill_stacks,chill_timers.size()) - chill_stacks)
	for index in range(maxi(added,0)):
		chill_timers[chill_stacks] = float(DATA.CHILL.duration)
		chill_stacks += 1
	if added > 0:
		_refresh_chill_multipliers()
		COMBAT_STATUS_EFFECT_VISUAL.show_on(self,"yuki_chill")

func _refresh_chill_multipliers() -> void:
	chill_attack_speed = pow(float(DATA.CHILL.attack_speed),chill_stacks)
	chill_projectile_speed = pow(float(DATA.CHILL.projectile_speed),chill_stacks)
	chill_slow_strength = pow(float(DATA.CHILL.slow_strength),chill_stacks)

func _get_effective_attack_cooldown() -> float:
	return maxf(attack_cooldown / chill_attack_speed,0.10)

func _fire_projectile(offset_to_hero: Vector2) -> void:
	if offset_to_hero.length_squared() <= 0.001 or not is_instance_valid(combat_authority):
		return
	var count := 3 if special_augment_configs.has("yuki_threefold_snow") else 1
	var direction := offset_to_hero.normalized()
	for index in range(count):
		var angle := (index - 1) * DATA.FAN_ANGLE if count == 3 else 0.0
		var shot_direction := direction.rotated(angle)
		var projectile = combat_authority.acquire_projectile(YUKI_PROJECTILE,"yuki_onna_projectile")
		projectile.global_position = global_position + shot_direction * 24.0
		projectile.setup(shot_direction,attack_damage,projectile_speed * chill_projectile_speed,projectile_range,String(get_meta("visual_variant","")) == "elite")
		projectile.source_ref = weakref(self)
		projectile.slow_ratio = float(DATA.SLOW.ratio) * chill_slow_strength
		projectile.slow_cap = max_slow_stacks

func _begin_death() -> void:
	if dying:
		return
	if is_instance_valid(combat_authority):
		combat_authority.yuki_runtime.record_death(self)
	super._begin_death()
