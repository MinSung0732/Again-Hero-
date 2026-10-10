extends "res://src/monsters/orc.gd"
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const BEHAVIOR := preload("res://src/data/mummy_behavior_catalog.gd")
var shield_hp := 0
var shield_capacity := 0
var shield_basis_hp := 0
var shield_broken := false
var elite_curse: Dictionary = {}
var movement_bonuses := {"move_speed_multiplier":1.0, "attack_speed_multiplier":1.0, "berserk_active":false}

func _init() -> void:
	monster_type = "mummy"
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
	shield_basis_hp = max_hp
	shield_capacity = int(round(max_hp * BEHAVIOR.SHIELD_RATIO))
	shield_hp = shield_capacity
	visual.apply_visual_profile(BEHAVIOR.NORMAL_VISUAL)
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(self, COMBAT_STATUS_EFFECT_VISUAL, "slow")
	queue_redraw()

func _sync_shield_capacity() -> void:
	if shield_basis_hp <= 0 or shield_basis_hp == max_hp:
		return
	shield_hp = int(round(float(shield_hp) * max_hp / shield_basis_hp)) if not shield_broken else 0
	shield_capacity = int(round(max_hp * BEHAVIOR.SHIELD_RATIO))
	shield_basis_hp = max_hp
	queue_redraw()

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	_sync_shield_capacity()

func apply_visual_profile(profile: Dictionary) -> void:
	_sync_shield_capacity()
	visual.apply_visual_profile(profile)

func configure_elite_passive(skill: Dictionary) -> void:
	elite_curse = skill.duplicate(true)
	movement_bonuses.move_speed_multiplier = float(skill.get("move_speed_multiplier",1.3))
	combat_bonus_refresh_timer = 0.0

func _physics_process(delta: float) -> void:
	_sync_shield_capacity()
	super._physics_process(delta)

func _get_combat_bonuses() -> Dictionary:
	return movement_bonuses

func _attack_target(target: Node2D) -> void:
	_deal_hit(target)

func _deal_hit(target: Node2D) -> int:
	return _deal_damage(target,attack_damage)

func _deal_damage(target: Node2D, amount: int) -> int:
	var previous_action := STATUS_SCOPE.begin(target,STATUS_SCOPE.action_or_new(target))
	var result := _status_scoped_deal_damage(target,amount)
	STATUS_SCOPE.finish(target,previous_action)
	return result

func _status_scoped_deal_damage(target: Node2D, amount: int) -> int:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return 0
	var before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage",amount,self)
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	var applied := maxi(before - int(target.get("current_hp")),0) + int(round(maxf(shield_before - shield_after,0.0)))
	if applied <= 0:
		return 0
	var reduction: Dictionary = special_augment_configs.get("mummy_dry_wound",{})
	if not reduction.is_empty() and target.has_method("apply_healing_reduction"):
		target.call("apply_healing_reduction",float(reduction.duration),float(reduction.reduction))
	if not elite_curse.is_empty() and target.has_method("apply_damage_taken_increase"):
		target.call("apply_damage_taken_increase",float(elite_curse.duration),float(elite_curse.damage_increase))
	return applied

func take_damage(amount: int) -> void:
	_apply_mummy_damage(amount)

func supports_damage_receipt() -> bool:
	# A derived actor must explicitly support its own damage implementation.
	return get_script().resource_path == "res://src/monsters/mummy.gd"

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var receipt_revision: int = receipt.begin(self, amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_mummy_damage(amount, receipt, receipt_revision)
	return receipt.finish(receipt_revision)

func _apply_mummy_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0:
		return
	_sync_shield_capacity()
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)
	if amount <= 0:
		return
	var absorbed := mini(shield_hp,amount)
	shield_hp -= absorbed
	var health_damage := mini(current_hp,amount - absorbed)
	current_hp -= health_damage
	if receipt != null:
		receipt.record_shield(absorbed, receipt_revision)
		receipt.record_hp(health_damage, receipt_revision)
	DAMAGE_NUMBERS.show(self,absorbed + health_damage)
	_visual_call(&"play_hit")
	queue_redraw()
	if absorbed > 0 and shield_hp == 0 and not shield_broken:
		shield_broken = true
		if special_augment_configs.has("mummy_broken_seal"):
			var target := MONSTER_RUNTIME_COMMON.resolve_combat_target(self,hero,combat_authority)
			if is_instance_valid(target) and target.has_method("take_damage"):
				_deal_damage(target,shield_capacity)
	if current_hp <= 0:
		if receipt == null:
			_begin_death()
		else:
			_begin_death_with_result(receipt, receipt_revision)

func _draw() -> void:
	super._draw()
	if not dying and shield_hp > 0:
		var ratio := clampf(float(shield_hp) / maxi(shield_capacity,1),0.0,1.0)
		draw_rect(Rect2(-43,-72,86,5),Color(0.12,0.14,0.24),true)
		draw_rect(Rect2(-43,-72,86 * ratio,5),Color(0.38,0.80,1.0),true)
