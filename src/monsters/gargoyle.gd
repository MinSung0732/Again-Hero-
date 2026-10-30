extends "res://src/monsters/orc.gd"
const CLOCK_GARGOYLE = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/gargoyle_behavior_catalog.gd")
var status_bar_head_y := -82.0
var stored_damage := 0.0
var petrify_restore_tint := Color.WHITE
var petrify_effect: Node
var petrify_timer: float:
	get: return petrify_remaining
var petrify_used := false
var petrify_remaining := 0.0
var petrify_budget := 0
var petrify_paid := 0
var petrify_elapsed := 0.0
var shield_granted := false
var ally_scratch: Array = []
var movement_bonuses := {"move_speed_multiplier":1.0,"attack_speed_multiplier":1.0,"berserk_active":false}

func _init() -> void:
	monster_type = "gargoyle"
	monster_role = "tank"
	max_hp = DATA.BASE.max_hp
	attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed
	attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown
	exp_reward = DATA.BASE.exp_reward

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)
	add_to_group("ranged_guards")
	set_meta("ranged_guard", true)
	_grant_augmented_shield()

func apply_visual_profile(profile: Dictionary) -> void:
	if not is_instance_valid(visual): return
	if visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",140.0))*0.5-12.0
		if petrify_remaining > 0.0:
			visual.set_base_animation_speed(0.0)
			visual.self_modulate = petrify_restore_tint*DATA.PETRIFY_TINT
		queue_redraw()

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if is_node_ready(): _grant_augmented_shield()

func _grant_augmented_shield() -> void:
	if shield_granted or not special_augment_configs.has("gargoyle_sky_bastion"): return
	shield_granted = true
	MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"ranged",int(round(max_hp*DATA.RANGED_SHIELD_RATIO)))

func _get_combat_bonuses() -> Dictionary:
	return movement_bonuses

func ranged_damage_multiplier() -> float:
	var ratio := float(current_hp)/maxi(max_hp,1)
	var progress := clampf((DATA.LOW_HP_START-ratio)/(DATA.LOW_HP_START-DATA.LOW_HP_MAX),0.0,1.0)
	return 1.0-DATA.RANGED_REDUCTION-DATA.EXTRA_REDUCTION*progress

func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_GARGOYLE.scaled(self, delta)
	if dying or current_hp <= 0: return
	if petrify_remaining > 0.0:
		var step := minf(delta,petrify_remaining)
		petrify_remaining = maxf(petrify_remaining-step,0.0)
		petrify_elapsed += step
		var cumulative := int(round(petrify_budget*minf(petrify_elapsed/DATA.PETRIFY_SECONDS,1.0)))
		heal_direct(maxi(cumulative-petrify_paid,0))
		petrify_paid = cumulative
		if petrify_remaining <= 0.0: _set_petrify_visual(false)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	super._physics_process(clock_raw_delta)

func _attack_target(target: Node2D) -> void:
	var hp_before := int(target.get("current_hp"))
	var shield_before := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	target.call("take_damage",attack_damage,self)
	if not is_instance_valid(target): return
	var shield_after := float(target.get("shield_hp")) if target.get("shield_hp") != null else 0.0
	if (hp_before > int(target.get("current_hp")) or shield_before > shield_after) and stored_damage > 0.0:
		var healing := int(round(stored_damage*DATA.STORAGE_HEAL_RATIO))
		stored_damage = 0.0
		heal_direct(healing)

func supports_damage_receipt() -> bool:
	return true

func take_damage(amount: int) -> void:
	_apply_gargoyle_damage(amount)

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var revision: int = receipt.begin(self,amount)
	_apply_gargoyle_damage(amount,receipt,revision)
	return receipt.finish(revision)

func _apply_gargoyle_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0: return
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,revision)
	var paid := mini(current_hp,maxi(amount,0))
	current_hp -= paid
	if receipt != null: receipt.record_hp(paid,revision)
	if special_augment_configs.has("gargoyle_recompense"):
		stored_damage += paid*DATA.STORAGE_RATIO
	if petrify_remaining <= 0.0: _visual_call(&"play_hit")
	DAMAGE_NUMBERS.show(self,paid)
	queue_redraw()
	if current_hp <= 0:
		if is_instance_valid(visual): visual.set_base_animation_speed(1.0)
		_begin_death_with_result(receipt,revision)
	elif not petrify_used and special_augment_configs.has("gargoyle_stone_slumber") and float(current_hp)/maxi(max_hp,1) <= DATA.LOW_HP_START:
		petrify_used = true
		petrify_remaining = DATA.PETRIFY_SECONDS
		petrify_budget = int(round((max_hp-current_hp)*DATA.PETRIFY_HEAL_RATIO))
		petrify_elapsed = 0.0
		petrify_paid = 0
		_set_petrify_visual(true)

func _set_petrify_visual(active: bool) -> void:
	if not active and not bool(get_meta("petrify_active",false)): return
	set_meta("petrify_active",active)
	if is_instance_valid(visual):
		if active: petrify_restore_tint = visual.self_modulate
		visual.self_modulate = petrify_restore_tint*DATA.PETRIFY_TINT if active else petrify_restore_tint
		visual.set_base_animation_speed(0.0 if active else 1.0)
	if active:
		petrify_effect = COMBAT_STATUS_EFFECT_VISUAL.show_on(self,"petrify")
	elif is_instance_valid(petrify_effect):
		petrify_effect.hide()
		petrify_effect.stop()
		petrify_effect.set_process(false)

func _begin_death() -> void:
	petrify_remaining = 0.0
	_set_petrify_visual(false)
	super._begin_death()

func _begin_death_with_result(receipt = null, revision: int = 0) -> void:
	petrify_remaining = 0.0
	_set_petrify_visual(false)
	super._begin_death_with_result(receipt,revision)

func try_cast_elite_skill(skill: Dictionary) -> bool:
	if dying or current_hp <= 0 or petrify_remaining > 0.0 or bool(get_meta("stun_active",false)) or bool(get_meta("silence_active",false)) or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self): return false
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("fill_monsters_near"): return false
	var radius := float(skill.get("radius",DATA.GUARD_RADIUS))
	ally_scratch.clear()
	combat_authority.call("fill_monsters_near",global_position,radius,ally_scratch)
	for ally in ally_scratch:
		if is_instance_valid(ally) and not ally.is_queued_for_deletion() and int(ally.get("current_hp")) > 0 and global_position.distance_squared_to(ally.global_position) <= radius*radius:
			MONSTER_RUNTIME_COMMON.grant_typed_shield(ally,"ranged",int(skill.get("shield_amount",150)))
	ally_scratch.clear()
	return true

func _draw() -> void:
	if dying: return
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
