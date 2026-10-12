extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/dark_elf_archer_behavior_catalog.gd")
const PROJECTILE := preload("res://src/monsters/DarkElfArrow.tscn")
var projectile_speed := DATA.BASE.projectile_speed
var projectile_range := DATA.BASE.projectile_range
var base_range_snapshot := -1.0
var quiet_time := 0.0
var stealth_active := false
var reposition_goal := Vector2.ZERO
var reposition_active := false
var reposition_side := 1.0
var burst_remaining := 0
var burst_timer := 0.0
var burst_target: WeakRef
var status_bar_head_y := -82.0

func _init() -> void:
	monster_type = "dark_elf_archer"; monster_role = "ranged"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward
	set_meta("combat_attack_type","ranged")

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",140.0))*0.5-12.0
	_sync_stealth_visual()

func _can_act() -> bool:
	return current_hp > 0 and not dying and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func configure_special_augments(configs: Dictionary) -> void:
	super.configure_special_augments(configs)
	if base_range_snapshot < 0.0: base_range_snapshot = attack_range
	attack_range = base_range_snapshot*float(configs.get("dark_elf_far_sight",{}).get("range_multiplier",1.0))
	projectile_range = attack_range

func supports_damage_receipt() -> bool: return true

func _apply_orc_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if amount > 0 and current_hp > 0 and not dying:
		quiet_time = 0.0
		if stealth_active: amount = maxi(1,ceili(amount*DATA.STEALTH_DAMAGE_RATIO))
	super._apply_orc_damage(amount,receipt,receipt_revision)

func _enter_stealth() -> void:
	if stealth_active or dying or current_hp <= 0: return
	stealth_active = true
	_sync_stealth_visual()
	if special_augment_configs.has("dark_elf_shadow_shield"):
		MONSTER_RUNTIME_COMMON.grant_typed_shield(self,"ranged",maxi(1,int(round(max_hp*0.1))),false)

func _leave_stealth() -> void:
	stealth_active = false
	# Restart the three-second preparation after firing, preventing per-frame reentry/shield spam.
	quiet_time = 0.0
	_sync_stealth_visual()

func _sync_stealth_visual() -> void:
	if is_instance_valid(visual): visual.self_modulate.a = DATA.STEALTH_ALPHA if stealth_active else 1.0

func _attack_target(target: Node2D) -> void:
	if not _can_act() or burst_remaining > 0 or not is_instance_valid(target): return
	var multiplier := DATA.AMBUSH_MULTIPLIER if stealth_active else 1.0
	if _fire(target,int(round(attack_damage*multiplier)),false):
		_leave_stealth()
		_begin_reposition(target)

func _fire(target: Node2D, amount: int, bypass: bool) -> bool:
	var parent := get_parent()
	var arrow = parent.acquire_projectile(PROJECTILE,"dark_elf_arrow") if parent.has_method("acquire_projectile") else PROJECTILE.instantiate()
	if arrow == null: return false
	if arrow.get_parent() == null: parent.add_child(arrow)
	arrow.global_position = global_position
	arrow.setup(self,target.global_position-global_position,amount,attack_range,bypass,target)
	_visual_call(&"play_attack")
	return true

func try_cast_elite_skill(_skill: Dictionary) -> bool:
	if not _can_act() or burst_remaining > 0 or bool(get_meta("silence_active",false)) or not is_instance_valid(hero) or int(hero.get("current_hp")) <= 0 or global_position.distance_squared_to(hero.global_position) > attack_range*attack_range: return false
	burst_target = weakref(hero)
	burst_remaining = DATA.BURST_SHOTS
	burst_timer = 0.0
	_leave_stealth()
	_tick_burst(0.0)
	return true

func _tick_burst(delta: float) -> void:
	burst_timer -= delta
	if burst_timer > 0.0: return
	var target = burst_target.get_ref() if burst_target != null else null
	if not is_instance_valid(target) or int(target.get("current_hp")) <= 0 or global_position.distance_squared_to(target.global_position) > attack_range*attack_range:
		burst_remaining = 0
		return
	if _fire(target,int(round(attack_damage*DATA.BURST_DAMAGE)),true):
		burst_remaining -= 1
		burst_timer = DATA.BURST_INTERVAL
		attack_timer = attack_cooldown
		quiet_time = 0.0
		_begin_reposition(target)

func _begin_reposition(target: Node2D) -> void:
	var away := global_position-target.global_position
	if away.length_squared() < 0.001: away = Vector2.LEFT
	away = away.normalized()
	reposition_side *= -1.0
	# Prefer away-from-target; near the range edge prefer a lateral position inside firing range.
	var best := global_position
	var best_distance := global_position.distance_squared_to(target.global_position)
	for i in range(3):
		var direction := away if i == 0 else away.rotated((PI*0.5 if i == 1 else -PI*0.5)*reposition_side)
		var point := global_position+direction*DATA.REPOSITION_DISTANCE
		var offset := point-target.global_position
		if offset.length() > attack_range: point = target.global_position+offset.normalized()*attack_range
		if is_instance_valid(combat_authority) and combat_authority.has_method("_clamp_manual_spawn_position"): point = combat_authority.call("_clamp_manual_spawn_position",point)
		var distance := point.distance_squared_to(target.global_position)
		if point.distance_squared_to(global_position) > 16.0 and (best == global_position or distance > best_distance):
			best = point; best_distance = distance
	reposition_goal = best
	reposition_active = best.distance_squared_to(global_position) > 16.0

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	quiet_time += delta
	if quiet_time >= DATA.STEALTH_DELAY and burst_remaining == 0: _enter_stealth()
	if not _can_act():
		burst_remaining = 0; reposition_active = false; velocity = Vector2.ZERO
		return
	if bool(get_meta("silence_active",false)): burst_remaining = 0
	if burst_remaining > 0: _tick_burst(delta)
	if reposition_active:
		attack_timer = maxf(attack_timer-delta,0.0)
		var offset := reposition_goal-global_position
		var speed := move_speed*DATA.REPOSITION_SPEED_MULTIPLIER*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		var step := minf(offset.length(),speed*delta)
		velocity = offset.normalized()*speed
		var collision = move_and_collide(offset.normalized()*step)
		_update_visual_motion(velocity.x,true)
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
		if collision != null or offset.length() <= step+0.01: reposition_active = false
		return
	if burst_remaining > 0:
		attack_timer = maxf(attack_timer-delta,0.0)
		return
	super._physics_process(delta)

func _draw() -> void:
	if not dying: MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
