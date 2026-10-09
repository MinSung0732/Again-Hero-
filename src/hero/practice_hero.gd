extends "res://src/hero/hero.gd"
## Real Hero status/visual interfaces, with optional 1-damage attacks, no EXP or death authority.
const INFINITE_HP := 1000000000
const FLEE_SPEED := 210.0
const DECISION_INTERVAL := 0.25
var practice_clock := 0.0
var decision_remaining := 0.0
var flee_direction := Vector2.RIGHT
var observed_damage := 0
var practice_attack_enabled := true
var practice_target: Node2D
const TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

func _ready() -> void:
	super._ready()
	max_hp = INFINITE_HP
	current_hp = INFINITE_HP
	attack_damage = 1
	move_speed = FLEE_SPEED
	set_meta("practice_dummy",true)
	queue_redraw()

func _physics_process_actions(delta: float) -> void:
	practice_clock += delta
	_update_hero_hit_flash(delta)
	_update_poison(delta)
	_update_bleed(delta)
	_update_damage_poison(delta)
	_tick_petrify(delta)
	_tick_received_modifiers(delta)
	attack_timer = maxf(attack_timer-delta,0.0)
	attack_pose_timer = maxf(attack_pose_timer-delta,0.0)
	if _tick_stun_state(delta) or petrify_timer > 0.0:
		return
	hit_pose_timer = maxf(hit_pose_timer-delta,0.0)
	slow_timer = maxf(slow_timer-delta,0.0)
	if slow_timer <= 0.0:
		move_multiplier = 1.0
	decision_remaining -= delta
	if decision_remaining <= 0.0:
		decision_remaining = DECISION_INTERVAL
		# Cached registry/spatial query, no group scan or per-frame target list.
		var nearest: Node2D = get_parent().get_nearest_monster_target(global_position,600.0)
		practice_target = nearest
		flee_direction = (global_position-nearest.global_position).normalized() if is_instance_valid(nearest) else Vector2.RIGHT.rotated(practice_clock*0.35)
		if flee_direction.is_zero_approx():
			flee_direction = Vector2.RIGHT
		var bounds := _get_battlefield_movement_bounds().grow(-78.0)
		if position.x < bounds.position.x and flee_direction.x < 0: flee_direction.x = absf(flee_direction.x)
		if position.x > bounds.end.x and flee_direction.x > 0: flee_direction.x = -absf(flee_direction.x)
		if position.y < bounds.position.y and flee_direction.y < 0: flee_direction.y = absf(flee_direction.y)
		if position.y > bounds.end.y and flee_direction.y > 0: flee_direction.y = -absf(flee_direction.y)
		flee_direction = flee_direction.normalized()
	velocity = flee_direction*FLEE_SPEED*move_multiplier
	_move_and_slide_with_obstacle_escape()
	_clamp_to_battlefield()
	if get_slide_collision_count() > 0:
		# Turn tangentially rather than repeatedly running into a pillar/wall.
		var normal := get_slide_collision(0).get_normal()
		var tangent := Vector2(-normal.y,normal.x)
		flee_direction = tangent if tangent.dot(flee_direction)>=0 else -tangent
		decision_remaining = DECISION_INTERVAL
	if practice_attack_enabled and attack_timer <= 0.0 and TARGET_POLICY.is_detectable(practice_target):
		_fire_practice_projectile(practice_target)
	_update_stage1_pose_visual(delta)
	queue_redraw()

func _take_damage_internal(amount: int, _source: Node, _ignore_invulnerability: bool, _grant_invulnerability: bool, _damage_already_mitigated: bool = false) -> bool:
	if amount <= 0:
		return false
	# No finite subtraction: even a lethal/status hit cannot trigger death.
	observed_damage += amount
	accepted_damage_hit.emit(_source)
	DAMAGE_NUMBERS.show(self,amount)
	hit_pose_timer = 0.12
	current_hp = INFINITE_HP
	max_hp = INFINITE_HP
	health_changed.emit(current_hp,max_hp)
	queue_redraw()
	return true

func gain_exp(_amount: int) -> void:
	pass

func set_practice_attack_enabled(enabled: bool) -> void:
	practice_attack_enabled = enabled

func _fire_practice_projectile(target_node: Node2D) -> void:
	var direction := global_position.direction_to(target_node.global_position)
	if direction.is_zero_approx():
		return
	var projectile := _acquire_projectile(PROJECTILE_SCENE,"hero_basic_projectile")
	if projectile == null:
		return
	attack_timer = 1.0 / maxf(get_paralysis_attack_multiplier(),0.01)
	attack_pose_timer = 0.34
	_face_attack_direction(direction.x)
	_restart_stage1_animation("attack")
	projectile.global_position = global_position+direction*46.0
	projectile.call("setup",direction,1,projectile_speed,600.0,hero_id,0.0,0.0,null)
