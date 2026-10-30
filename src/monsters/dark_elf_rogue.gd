extends "res://src/monsters/orc.gd"
const CLOCK_DARK_ELF_ROGUE = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/dark_elf_rogue_behavior_catalog.gd")
const TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")
var quiet_time := 0.0
var stealth_active := false
var dark_remaining := 0.0
var followup_target: WeakRef
var followup_timer := 0.0
var combo_action: RefCounted
var reposition_active := false
var reposition_goal := Vector2.ZERO
var reposition_side := 1.0
var status_bar_head_y := -82.0

func _init() -> void:
	monster_type = "dark_elf_rogue"; monster_role = "exploder"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward
	set_meta("combat_attack_type","melee")

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",140.0))*0.5-12.0
	_sync_visibility()

func supports_damage_receipt() -> bool: return true

func _can_act() -> bool:
	return current_hp > 0 and not dying and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func _apply_orc_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if amount > 0 and current_hp > 0 and not dying:
		quiet_time = 0.0
		if dark_remaining > 0.0: amount = maxi(1,ceili(amount*DATA.DARK_DAMAGE_TAKEN))
		elif stealth_active: amount = maxi(1,ceili(amount*DATA.STEALTH_DAMAGE_RATIO))
	super._apply_orc_damage(amount,receipt,receipt_revision)

func _enter_stealth() -> void:
	if stealth_active or dark_remaining > 0.0 or dying or current_hp <= 0: return
	stealth_active = true
	_sync_visibility()

func _sync_visibility() -> void:
	modulate.a = 0.0 if dark_remaining > 0.0 else 1.0
	if is_instance_valid(visual): visual.self_modulate.a = DATA.STEALTH_ALPHA if stealth_active else 1.0
	queue_redraw()

func try_cast_elite_skill(_skill: Dictionary) -> bool:
	if not _can_act() or bool(get_meta("silence_active",false)) or dark_remaining > 0.0: return false
	followup_target = null
	dark_remaining = DATA.DARK_DURATION
	stealth_active = false; quiet_time = 0.0
	combat_bonus_cache.clear()
	TARGET_POLICY.set_hidden(self,true)
	_sync_visibility()
	return true

func _clear_dark() -> void:
	dark_remaining = 0.0
	stealth_active = false; quiet_time = 0.0
	combat_bonus_cache.clear()
	TARGET_POLICY.set_hidden(self,false)
	_sync_visibility()

func _get_combat_bonuses() -> Dictionary:
	return {"move_speed_multiplier":DATA.DARK_MOVE_MULTIPLIER if dark_remaining > 0.0 else 1.0,"attack_speed_multiplier":1.0,"berserk_active":false}

func _is_backstab(target: Node2D) -> bool:
	var sprite = target.get("hero_sprite")
	if not is_instance_valid(sprite) or not (sprite is Sprite2D or sprite is AnimatedSprite2D): return false
	var facing := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	return (global_position-target.global_position).dot(facing) < -0.01

func _deal_hit(target: Node2D, multiplier: float, followup: bool) -> bool:
	var backstab := special_augment_configs.has("dark_elf_rogue_backstab") and _is_backstab(target)
	var amount := maxi(1,int(round(attack_damage*multiplier*(DATA.BACKSTAB_MULTIPLIER if backstab else 1.0))))
	var had_color := target.has_meta("damage_number_color_once")
	var previous_color = target.get_meta("damage_number_color_once") if had_color else null
	var had_critical := target.has_meta("damage_number_critical_once")
	var previous_critical = target.get_meta("damage_number_critical_once") if had_critical else null
	if backstab:
		target.set_meta("damage_number_color_once",DATA.BACKSTAB_COLOR)
		target.set_meta("damage_number_critical_once",true)
	var previous_action := STATUS_SCOPE.begin(target,combo_action)
	var result = target.call("take_followup_damage",amount,self) if followup and target.has_method("take_followup_damage") else target.call("take_damage",amount,self)
	STATUS_SCOPE.finish(target,previous_action)
	if backstab and is_instance_valid(target):
		if had_color: target.set_meta("damage_number_color_once",previous_color)
		elif target.has_meta("damage_number_color_once"): target.remove_meta("damage_number_color_once")
		if had_critical: target.set_meta("damage_number_critical_once",previous_critical)
		elif target.has_meta("damage_number_critical_once"): target.remove_meta("damage_number_critical_once")
	return result != false

func _attack_target(target: Node2D) -> void:
	if not _can_act() or followup_target != null or not is_instance_valid(target) or not target.has_method("take_damage"): return
	combo_action = STATUS_SCOPE.action_or_new(target)
	var hidden := dark_remaining > 0.0
	var multiplier := 1.0
	# Elite and normal stealth are mutually exclusive, never 225% multiplied by 150/300%.
	if hidden: multiplier = DATA.DARK_STRIKE_MULTIPLIER
	elif stealth_active: multiplier = DATA.ENHANCED_AMBUSH if special_augment_configs.has("dark_elf_rogue_assassinate") else DATA.AMBUSH_MULTIPLIER
	var accepted := _deal_hit(target,multiplier,false)
	if hidden and accepted: _clear_dark()
	elif not hidden:
		stealth_active = false; quiet_time = 0.0; _sync_visibility()
	if accepted and is_instance_valid(target) and not dying and current_hp > 0:
		followup_target = weakref(target)
		followup_timer = minf(DATA.FOLLOWUP_DELAY,attack_cooldown*0.45)
	_begin_reposition(target)

func _tick_followup(delta: float) -> void:
	if followup_target == null: return
	followup_timer = maxf(followup_timer-delta,0.0)
	if followup_timer > 0.0: return
	var target = followup_target.get_ref()
	followup_target = null
	if is_instance_valid(target) and not target.is_queued_for_deletion() and int(target.get("current_hp")) > 0 and global_position.distance_squared_to(target.global_position) <= attack_range*attack_range:
		_deal_hit(target,1.0,true)

func _begin_reposition(target: Node2D) -> void:
	if not is_instance_valid(target): return
	var away := global_position-target.global_position
	if away.length_squared() < 0.001: away = Vector2.LEFT
	away = away.normalized(); reposition_side *= -1.0
	var best := global_position
	var best_distance := global_position.distance_squared_to(target.global_position)
	for i in range(3):
		var direction := away if i == 0 else away.rotated((PI*0.5 if i == 1 else -PI*0.5)*reposition_side)
		var point := global_position+direction*DATA.REPOSITION_DISTANCE
		var offset := point-target.global_position
		if offset.length() > attack_range: point = target.global_position+offset.normalized()*attack_range
		if is_instance_valid(combat_authority) and combat_authority.has_method("_clamp_manual_spawn_position"): point = combat_authority.call("_clamp_manual_spawn_position",point)
		var distance := point.distance_squared_to(target.global_position)
		if point.distance_squared_to(global_position)>16.0 and (best == global_position or distance>best_distance):
			best = point; best_distance = distance
	reposition_goal = best
	reposition_active = best.distance_squared_to(global_position)>16.0

func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_DARK_ELF_ROGUE.scaled(self, delta)
	if dying or current_hp <= 0: return
	quiet_time += delta
	if dark_remaining > 0.0:
		dark_remaining = maxf(dark_remaining-delta,0.0)
		if dark_remaining <= 0.0: _clear_dark()
	if quiet_time >= DATA.STEALTH_DELAY: _enter_stealth()
	if not _can_act():
		followup_target = null; reposition_active = false; velocity = Vector2.ZERO
		return
	_tick_followup(delta)
	if dying or current_hp <= 0: return
	if reposition_active:
		attack_timer = maxf(attack_timer-delta,0.0)
		var offset := reposition_goal-global_position
		var speed := move_speed*DATA.REPOSITION_SPEED*(DATA.DARK_MOVE_MULTIPLIER if dark_remaining>0.0 else 1.0)*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		var step := minf(offset.length(),speed*delta)
		velocity = offset.normalized()*speed
		var collision = move_and_collide(offset.normalized()*step)
		_update_visual_motion(velocity.x,true)
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
		if collision != null or offset.length() <= step+0.01: reposition_active = false
		return
	super._physics_process(clock_raw_delta)

func _begin_death() -> void:
	followup_target = null; _clear_dark()
	super._begin_death()

func _begin_death_with_result(receipt = null, receipt_revision: int = 0) -> void:
	followup_target = null; _clear_dark()
	super._begin_death_with_result(receipt,receipt_revision)

func _exit_tree() -> void:
	TARGET_POLICY.set_hidden(self,false)

func _draw() -> void:
	if not dying and dark_remaining <= 0.0: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
