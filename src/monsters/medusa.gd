extends "res://src/monsters/orc.gd"
const BEHAVIOR := preload("res://src/data/medusa_behavior_catalog.gd")
var pursuit_multiplier := 1.0
var poison_aura_remaining := 0.0
var poison_duration := 5.0
var elite_aura: Dictionary = {}
var aura_timer := 0.0
var aura_scratch: Array = []

func _init() -> void:
	monster_type = "medusa"
	monster_role = "controller"
	max_hp = int(BEHAVIOR.BASE.max_hp)
	move_speed = float(BEHAVIOR.BASE.move_speed)
	attack_damage = int(BEHAVIOR.BASE.attack_damage)
	attack_range = float(BEHAVIOR.BASE.attack_range)
	attack_cooldown = float(BEHAVIOR.BASE.attack_cooldown)
	exp_reward = int(BEHAVIOR.BASE.exp_reward)
	set_meta("ignore_monster_separation", true)

func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	if not is_instance_valid(hero):
		_refresh_combat_target()
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(self, COMBAT_STATUS_EFFECT_VISUAL, "slow")

func configure_elite_passive(skill: Dictionary) -> void:
	elite_aura = skill.duplicate(true)
	aura_timer = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if current_hp <= 0 or dying:
		return
	poison_aura_remaining = maxf(poison_aura_remaining - delta,0.0)
	_tick_aura(delta)
	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		return
	hero_target_refresh_timer = maxf(hero_target_refresh_timer - delta,0.0)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(hero_target_refresh_timer,hero):
		_refresh_combat_target()
	attack_timer = maxf(attack_timer - delta,0.0)
	if not is_instance_valid(hero):
		velocity = Vector2.ZERO
		_update_visual_motion(0.0,false)
		return
	var offset := hero.global_position - global_position
	_update_visual_lod(offset.length_squared())
	if offset.length_squared() > attack_range * attack_range:
		pursuit_multiplier = minf(pursuit_multiplier + delta * float(BEHAVIOR.PURSUIT.growth_per_second), float(BEHAVIOR.PURSUIT.max_multiplier))
		velocity = offset.normalized() * get_actual_move_speed()
		_update_visual_motion(offset.x,true)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_update_visual_motion(offset.x,false)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			visual.play_attack()
			_deal_hit(hero)

func get_actual_move_speed() -> float:
	return move_speed * pursuit_multiplier * MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)

func _deal_hit(target: Node2D) -> int:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	var damage := attack_damage
	var speed: Dictionary = special_augment_configs.get("medusa_serpent_momentum", {})
	damage += int(round(get_actual_move_speed() * float(speed.get("speed_damage_ratio",0.0))))
	var shatter: Dictionary = special_augment_configs.get("medusa_stone_shatter", {})
	if bool(target.get_meta("petrify_active",false)):
		damage = int(round(damage * float(shatter.get("damage_multiplier",1.0))))
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage",damage,self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	var applied := maxi(before - int(target.get("current_hp")),0) + int(round(maxf(shield_before - shield_after,0.0)))
	if applied <= 0:
		return 0
	pursuit_multiplier = 1.0
	if poison_aura_remaining > 0.0 and target.has_method("apply_damage_poison"):
		target.call("apply_damage_poison",poison_duration,applied,self)
	var residue: Dictionary = special_augment_configs.get("medusa_stone_residue", {})
	if target.has_method("register_medusa_hit"):
		target.call("register_medusa_hit",float(BEHAVIOR.STONE.duration),float(residue.get("slow_multiplier",1.0)),float(residue.get("slow_duration",0.0)))
	return applied

func _tick_aura(delta: float) -> void:
	if elite_aura.is_empty() or not is_instance_valid(combat_authority):
		return
	aura_timer -= delta
	if aura_timer > 0.0:
		return
	aura_timer = float(elite_aura.get("refresh_interval",0.2))
	var radius := float(elite_aura.get("radius",250.0))
	combat_authority.fill_monsters_near(global_position,radius,aura_scratch)
	for raw_node in aura_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		if String(raw_node.get("monster_type")) != monster_type or int(raw_node.get("current_hp")) <= 0:
			continue
		if global_position.distance_squared_to(raw_node.global_position) > radius * radius:
			continue
		raw_node.poison_aura_remaining = float(elite_aura.get("buff_linger",0.35))
		raw_node.poison_duration = float(elite_aura.get("duration",5.0))
	aura_scratch.clear()

func _begin_death() -> void:
	super._begin_death()
	queue_redraw()

func _draw() -> void:
	super._draw()
	if not dying and not elite_aura.is_empty():
		draw_arc(Vector2.ZERO,float(elite_aura.get("radius",250.0)) / maxf(absf(global_scale.x),0.01),0.0,TAU,72,Color(0.52,0.88,0.35,0.65),1.0,true)
