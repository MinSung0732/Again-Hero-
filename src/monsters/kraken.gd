extends "res://src/monsters/orc.gd"

const BEHAVIOR := preload("res://src/data/kraken_behavior_catalog.gd")
const TENTACLE := preload("res://src/monsters/kraken_tentacle_fx.gd")
var growth_hits := 0
var growth_stacks := 0
var burst_count := 0
var burst_total := 0
var burst_index := 0
var burst_damage := 0
var burst_timer := 0.0
var dodge_used := false
var dodge_state := 0
var dodge_destination := Vector2.ZERO

func _init() -> void:
	monster_type = "kraken"
	monster_role = "ranged"
	max_hp = int(BEHAVIOR.BASE.max_hp)
	move_speed = 0.0
	attack_damage = int(BEHAVIOR.BASE.attack_damage)
	attack_range = float(BEHAVIOR.BASE.attack_range)
	attack_cooldown = float(BEHAVIOR.BASE.attack_cooldown)
	exp_reward = int(BEHAVIOR.BASE.exp_reward)

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	if not is_instance_valid(hero):
		_refresh_combat_target()
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)
	visual.revival_animation_finished.connect(_finish_dodge)
	TENTACLE.warm_cache()

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	var titan: Dictionary = configs.get("kraken_abyss_titan", {})
	attack_range = float(BEHAVIOR.BASE.attack_range) * float(titan.get("range_multiplier", 1.0))
	scale = Vector2.ONE * float(titan.get("visual_scale", 1.0))
	move_speed = 0.0

func get_attack_growth_multiplier() -> float:
	return 1.0 + growth_stacks * float(BEHAVIOR.ATTACK.growth_per_stack)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if current_hp <= 0 or dying:
		return
	if dodge_state != 0:
		if dodge_state == 1 and visual.is_revival_death_pose_ready():
			global_position = dodge_destination
			MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
			dodge_state = 2
			visual.play_revival_reverse()
		return
	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return
	hero_target_refresh_timer = maxf(hero_target_refresh_timer - delta, 0.0)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(hero_target_refresh_timer, hero):
		_refresh_combat_target()
	if not is_instance_valid(hero):
		burst_count = 0
		return
	var distance_sq := global_position.distance_squared_to(hero.global_position)
	_update_visual_motion(hero.global_position.x - global_position.x, false)
	var dodge: Dictionary = special_augment_configs.get("kraken_abyss_escape", {})
	if not dodge_used and not dodge.is_empty() and distance_sq <= pow(float(dodge.get("trigger_radius", 220.0)), 2):
		_start_dodge()
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	if burst_count > 0:
		burst_timer -= delta
		while burst_count > 0 and burst_timer <= 0.000001:
			_tick_tentacle()
		return
	if attack_timer <= 0.0 and distance_sq <= attack_range * attack_range:
		_start_burst()

func _start_burst() -> void:
	var barrage: Dictionary = special_augment_configs.get("kraken_tentacle_barrage", {})
	burst_count = int(barrage.get("tentacle_count", BEHAVIOR.ATTACK.count))
	burst_total = burst_count
	burst_index = 0
	burst_damage = attack_damage
	burst_timer = 0.0
	attack_timer = attack_cooldown
	visual.play_attack()
	_tick_tentacle()

func _tick_tentacle() -> void:
	var total := burst_total
	if is_instance_valid(hero) and global_position.distance_squared_to(hero.global_position) <= attack_range * attack_range:
		var spot := hero.global_position + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * float(BEHAVIOR.ATTACK.scatter_radius)
		TENTACLE.show_at(combat_authority, spot, scale.x)
		# Integer remainder distribution keeps the sum equal to the attack snapshot.
		var damage := int(burst_damage / total) + (1 if burst_index < burst_damage % total else 0)
		_strike(hero, spot, damage, true)
	burst_index += 1
	burst_count -= 1
	burst_timer += float(BEHAVIOR.ATTACK.duration) / maxi(total - 1, 1)

func _strike(target: Node2D, spot: Vector2, damage: int, grow: bool) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if spot.distance_squared_to(target.global_position) > pow(float(BEHAVIOR.ATTACK.hit_radius), 2):
		return
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage", damage, self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	if grow and (before > int(target.get("current_hp")) or shield_before > shield_after):
		growth_hits += 1
		if growth_hits >= int(BEHAVIOR.ATTACK.growth_hits):
			growth_hits = 0
			growth_stacks += 1
			combat_authority.call("_apply_demon_level_scaling_to_monster", self, true)

func _start_dodge() -> void:
	dodge_used = true
	dodge_state = 1
	burst_count = 0
	var origin: Vector2 = combat_authority.hero.global_position if is_instance_valid(combat_authority.hero) else hero.global_position
	dodge_destination = combat_authority.get_stationary_spawn_position(monster_type, origin, origin - (global_position - origin))
	visual.play_revival_death_pose()

func _finish_dodge() -> void:
	if not dying:
		dodge_state = 0
		attack_timer = 0.0

func _begin_death() -> void:
	if dying:
		return
	burst_count = 0
	var target: Node2D = combat_authority.hero if is_instance_valid(combat_authority) else hero
	for index in range(int(BEHAVIOR.DEATH.count)):
		var spot := global_position + Vector2.from_angle(TAU * index / float(BEHAVIOR.DEATH.count)) * float(BEHAVIOR.DEATH.radius)
		TENTACLE.show_at(combat_authority, spot, scale.x)
		_strike(target, spot, int(round(attack_damage / float(BEHAVIOR.DEATH.damage_divisor))), false)
	super._begin_death()
