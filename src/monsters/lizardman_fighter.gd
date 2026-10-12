extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/lizardman_fighter_behavior_catalog.gd")
var status_bar_head_y := -77.0
var tail_used := false
var escape_remaining := 0.0
var escape_direction := Vector2.ZERO
var escape_left := 0.0
var escape_recovery_pending := false
var tails_eaten := 0
var eater_active := false
var runtime_additions := {"hp_multiplier":1.0,"damage_multiplier":1.0,"speed_multiplier":1.0,"attack_speed_multiplier":1.0}

func _init() -> void:
	monster_type = "lizardman_fighter"
	monster_role = "exploder"
	max_hp = DATA.BASE.max_hp
	attack_damage = DATA.BASE.attack_damage
	move_speed = DATA.BASE.move_speed
	attack_range = DATA.BASE.attack_range
	attack_cooldown = DATA.BASE.attack_cooldown
	exp_reward = DATA.BASE.exp_reward
	set_meta("noncollision_family",DATA.FAMILY)

func _ready() -> void:
	super._ready()
	apply_visual_profile(DATA.NORMAL_VISUAL)

func apply_visual_profile(profile: Dictionary) -> void:
	if is_instance_valid(visual) and visual.apply_visual_profile(profile):
		status_bar_head_y = visual.position.y-float(profile.get("target_height",130.0))*0.5-12.0
		queue_redraw()

func _tail_runtime():
	return combat_authority.get("lizard_tail_runtime") if is_instance_valid(combat_authority) else null

func configure_elite_passive(_skill: Dictionary) -> void:
	if eater_active: return
	eater_active = true
	var runtime = _tail_runtime()
	if runtime != null: runtime.register_eater(self)

func _exit_tree() -> void:
	var runtime = _tail_runtime()
	if runtime != null: runtime.unregister_eater(self)

func get_runtime_stat_additions() -> Dictionary:
	return runtime_additions

func consume_lizard_tail() -> void:
	if dying or current_hp <= 0: return
	tails_eaten += 1
	var multiplier := 1.0+DATA.FOOD_STAT_STEP*tails_eaten
	for key in runtime_additions: runtime_additions[key] = multiplier
	if is_instance_valid(combat_authority) and combat_authority.has_method("refresh_monster_runtime_stats"):
		combat_authority.refresh_monster_runtime_stats(self)
	queue_redraw()

func supports_damage_receipt() -> bool:
	return true

func take_damage(amount: int) -> void:
	_apply_lizard_damage(amount)

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var revision: int = receipt.begin(self,amount)
	_apply_lizard_damage(amount,receipt,revision)
	return receipt.finish(revision)

func _apply_lizard_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if amount <= 0 or dying or current_hp <= 0: return
	super._apply_orc_damage(amount,receipt,revision)
	if not dying and current_hp > 0 and not tail_used and float(current_hp)/maxi(max_hp,1) <= DATA.TAIL_TRIGGER_RATIO:
		_begin_tail_escape()

func _begin_tail_escape() -> void:
	tail_used = true
	var source = get_meta("_status_damage_source",null)
	if not is_instance_valid(source) or not source is Node2D: source = hero
	escape_direction = (global_position-source.global_position).normalized() if is_instance_valid(source) else Vector2(-visual_facing_sign,0)
	if escape_direction.length_squared() < 0.01: escape_direction = Vector2(-visual_facing_sign,0)
	escape_left = DATA.ESCAPE_DISTANCE
	if is_instance_valid(combat_authority) and combat_authority.has_method("_clamp_manual_spawn_position"):
		var target := global_position+escape_direction*escape_left
		var safe: Vector2 = combat_authority.call("_clamp_manual_spawn_position",target)
		if not safe.is_equal_approx(target):
			var low := 0.0
			var high := escape_left
			for _step in range(14):
				var mid := (low+high)*0.5
				var point := global_position+escape_direction*mid
				var clamped: Vector2 = combat_authority.call("_clamp_manual_spawn_position",point)
				if clamped.is_equal_approx(point): low = mid
				else: high = mid
			escape_left = low
	escape_remaining = DATA.ESCAPE_SECONDS
	escape_recovery_pending = true
	var runtime = _tail_runtime()
	if runtime != null: runtime.spawn_tail(global_position,visual_facing_sign)
	_visual_call(&"play_locomotion",[true])

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	if escape_remaining > 0.0:
		if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self) or bool(get_meta("stun_active",false)):
			velocity = Vector2.ZERO
			return
		var distance := minf(escape_left,DATA.ESCAPE_DISTANCE/DATA.ESCAPE_SECONDS*delta)
		velocity = escape_direction*DATA.ESCAPE_DISTANCE/DATA.ESCAPE_SECONDS
		var collision = move_and_collide(escape_direction*distance)
		escape_left = maxf(escape_left-distance,0.0)
		escape_remaining = maxf(escape_remaining-delta,0.0)
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
		if collision != null or escape_left <= 0.01 or escape_remaining <= 0.0: _finish_tail_escape()
		return
	super._physics_process(delta)

func _finish_tail_escape() -> void:
	escape_remaining = 0.0
	escape_left = 0.0
	velocity = Vector2.ZERO
	if escape_recovery_pending and special_augment_configs.has("lizard_tail_regrowth"):
		heal_direct(int(round((max_hp-current_hp)*DATA.RECOVERY_RATIO)))
	escape_recovery_pending = false

func _draw() -> void:
	if dying: return
	MONSTER_RUNTIME_COMMON.draw_status_bars(self,self,status_bar_head_y)
