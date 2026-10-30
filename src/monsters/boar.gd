extends "res://src/monsters/orc.gd"
const CLOCK_BOAR = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/boar_behavior_catalog.gd")
enum Phase { IDLE, WINDUP, DASH }
var phase := Phase.IDLE
var windup_remaining := 0.0
var dash_direction := Vector2.RIGHT
var dash_speed := DATA.MIN_SPEED
var dash_traveled := 0.0
var dash_count := 0
var chained_dash := false
var contact_done := false
var dash_target: WeakRef
var frenzy_remaining := 0.0
var status_bar_head_y := -77.0

func _init() -> void:
	monster_type = "boar"; monster_role = "exploder"
	max_hp = DATA.BASE.max_hp; attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed; attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown; exp_reward = DATA.BASE.exp_reward
	set_meta("combat_attack_type","melee")

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",130.0))*0.5-12.0

func _can_act() -> bool:
	return current_hp > 0 and not dying and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)

func supports_damage_receipt() -> bool: return true

func try_cast_elite_skill(_skill: Dictionary) -> bool:
	if not _can_act() or bool(get_meta("silence_active",false)): return false
	frenzy_remaining = DATA.ELITE_DURATION
	return true

func _attack_target(target: Node2D) -> void:
	if _can_act() and phase == Phase.IDLE: _begin_dash(target)

func _begin_dash(target: Node2D, chained: bool = false) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"): return
	var offset := target.global_position-global_position
	dash_direction = offset.normalized() if offset.length_squared() > 0.001 else Vector2.RIGHT
	dash_target = weakref(target)
	chained_dash = chained
	dash_traveled = 0.0; contact_done = false
	windup_remaining = 0.0 if chained or special_augment_configs.has("boar_instant") else DATA.WINDUP
	phase = Phase.WINDUP
	velocity = Vector2.ZERO
	if windup_remaining <= 0.0: _launch()
	queue_redraw()

func _launch() -> void:
	dash_count += 1
	dash_speed = DATA.THIRD_SPEED if special_augment_configs.has("boar_third_charge") and dash_count%3 == 0 else DATA.MIN_SPEED
	phase = Phase.DASH
	_visual_call(&"play_attack")

func _physics_process(delta: float) -> void:
	var clock_raw_delta := delta
	delta = CLOCK_BOAR.scaled(self, delta)
	if dying or current_hp <= 0: return
	frenzy_remaining = maxf(frenzy_remaining-delta,0.0)
	if not _can_act():
		if phase != Phase.IDLE: _finish_dash(false)
		velocity = Vector2.ZERO
		return
	if phase == Phase.WINDUP:
		if bool(get_meta("silence_active",false)):
			_finish_dash(false)
			return
		windup_remaining = maxf(windup_remaining-delta,0.0)
		if windup_remaining <= 0.0: _launch()
		queue_redraw()
		return
	if phase == Phase.DASH:
		_tick_dash(delta)
		return
	super._physics_process(clock_raw_delta)

func _tick_dash(delta: float) -> void:
	var old_speed := dash_speed
	dash_speed = minf(dash_speed+DATA.ACCELERATION*delta,DATA.MAX_SPEED)
	var slow := MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	var step := minf((old_speed+dash_speed)*0.5*delta*slow,DATA.DASH_DISTANCE-dash_traveled)
	var start := global_position
	velocity = dash_direction*dash_speed*slow
	var collision = move_and_collide(dash_direction*step)
	dash_traveled += start.distance_to(global_position)
	if collision != null and not contact_done:
		var body = collision.get_collider()
		if is_instance_valid(body) and (body.is_in_group("hero") or body.is_in_group("hero_summons")) and body.has_method("take_damage"):
			contact_done = true
			body.call("take_damage",attack_damage,self)
	var target = dash_target.get_ref() if dash_target != null else null
	if not contact_done and is_instance_valid(target) and target.has_method("take_damage"):
		var nearest := Geometry2D.get_closest_point_to_segment(target.global_position,start,global_position)
		if nearest.distance_squared_to(target.global_position) <= DATA.CONTACT_RADIUS*DATA.CONTACT_RADIUS:
			contact_done = true
			target.call("take_damage",attack_damage,self)
	_update_visual_motion(dash_direction.x,true)
	MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
	if collision != null or dash_traveled >= DATA.DASH_DISTANCE-0.01: _finish_dash()

func _finish_dash(allow_chain: bool = true) -> void:
	phase = Phase.IDLE; velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	queue_redraw()
	if allow_chain and not chained_dash and frenzy_remaining > 0.0 and _can_act() and not bool(get_meta("silence_active",false)) and is_instance_valid(hero) and int(hero.get("current_hp")) > 0:
		_begin_dash(hero,true)

func _draw() -> void:
	if dying: return
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
	if phase == Phase.WINDUP:
		draw_arc(Vector2.ZERO,32.0,-PI*0.5,-PI*0.5+TAU*(1.0-windup_remaining/DATA.WINDUP),24,Color("ffd16b"),2.0)
