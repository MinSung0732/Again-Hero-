extends "res://src/monsters/bat.gd"

const BANSHEE_FRAME_DIR := "res://assets/art/monsters/Banshee/frames"
const WINDUP_DURATION := 0.5
const CHARGE_TINT := Color(1.0, 0.62, 0.62, 1.0)

var spawn_origin := Vector2.ZERO
var origin_initialized := false
var charge_state: int = 0 # 0 wander, 1 windup, 2 pursuit
var windup_timer: float = 0.0

func _init() -> void:
	monster_type = "banshee"
	monster_role = "controller"
	max_hp = 88
	move_speed = 110.0
	attack_damage = 4
	attack_cooldown = 1.0
	charge_speed_multiplier = 3.0
	exp_reward = 26

func _apply_normal_visual_profile() -> void:
	if not is_instance_valid(visual):
		return
	if not visual.has_method("apply_visual_profile"):
		return
	visual.call("apply_visual_profile", {
		"mode": "frames",
		"asset_dir": BANSHEE_FRAME_DIR,
		"target_height": 86.0,
		"animations": {
			"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
			"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
			"attack": {"prefix": "atk", "count": 6, "fps": 12.0, "loop": false},
			"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
			"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
		},
	})

func _physics_process(delta: float) -> void:
	if not origin_initialized:
		spawn_origin = global_position
		origin_initialized = true
	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		hero_target_refresh_timer,
		delta
	)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(
		hero_target_refresh_timer,
		hero
	):
		_refresh_combat_target()

	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		set_meta("banshee_charge_stealth_active", false)
		return

	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		set_meta("banshee_charge_stealth_active", false)
		_update_visual_motion(0.0, false)
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	soft_separation_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		soft_separation_timer,
		delta
	)
	if soft_separation_timer <= 0.0:
		soft_separation_bias = (
			MONSTER_RUNTIME_COMMON.compute_soft_separation_bias(
				self,
				combat_authority
			)
		)
		soft_separation_timer = (
			MONSTER_RUNTIME_COMMON.next_soft_separation_delay()
		)

	if hit_flash_timer > 0.0:
		var previous_hit_flash := hit_flash_timer
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
			queue_redraw()

	var external_slow := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	var base_move_speed := move_speed * external_slow
	if not is_instance_valid(hero):
		set_meta("banshee_charge_stealth_active", false)
		_move_wandering(base_move_speed)
		return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var attack_range_sq := attack_range * attack_range
	if charge_state == 0 and distance_sq <= detection_range * detection_range:
		charge_state = 1
		windup_timer = WINDUP_DURATION
		_update_visual_motion(offset_to_hero.x, false)
		_visual_call(&"play_attack")
	if charge_state == 1:
		velocity = Vector2.ZERO
		windup_timer = maxf(windup_timer - delta, 0.0)
		if is_instance_valid(visual):
			visual.modulate = Color.WHITE.lerp(CHARGE_TINT, 1.0 - windup_timer / WINDUP_DURATION)
		if windup_timer <= 0.0:
			charge_state = 2
		return
	var charging := charge_state == 2 and distance_sq > attack_range_sq
	set_meta("banshee_charge_stealth_active", charging and special_augment_configs.has("banshee_charge_stealth"))
	if is_instance_valid(visual):
		visual.modulate = CHARGE_TINT if charge_state == 2 else Color.WHITE
		if bool(get_meta("banshee_charge_stealth_active", false)):
			visual.modulate.a = 0.35
	if charge_state == 2:
		if distance_sq <= attack_range_sq:
			_attack_target(offset_to_hero)
		else:
			_move_charging(offset_to_hero, distance_sq, base_move_speed * charge_speed_multiplier, delta)
		return

	_move_wandering(base_move_speed)

func _pick_new_wander_target() -> void:
	wander_timer = randf_range(1.6, 3.4)
	var direction := Vector2.from_angle(randf_range(0.0, TAU))
	var candidate := spawn_origin + direction * randf_range(80.0, 220.0)
	if (
		is_instance_valid(combat_authority)
		and combat_authority.has_method("clamp_monster_wander_position")
	):
		var clamped = combat_authority.call(
			"clamp_monster_wander_position",
			candidate
		)
		if typeof(clamped) == TYPE_VECTOR2:
			candidate = clamped
	wander_target = candidate

func _deal_attack_damage() -> int:
	if not is_instance_valid(hero) or not hero.has_method("take_damage"):
		return 0
	var damage := attack_damage + int(round(float(hero.get("current_hp")) * 0.005))
	if not bool(hero.call("take_damage", damage, self)):
		return 0
	if hero.has_method("apply_slow"):
		hero.call("apply_slow", 0.90, 1.0)
	var config: Dictionary = special_augment_configs.get("banshee_bleeding", {})
	if not config.is_empty() and randf() < float(config.get("chance", 0.20)) and hero.has_method("apply_bleed"):
		hero.call("apply_bleed", float(config.get("duration", 3.0)), self)
	return damage

func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying:
		return
	var previous_hp := current_hp
	if bool(get_meta("banshee_charge_stealth_active", false)):
		var config: Dictionary = special_augment_configs.get("banshee_charge_stealth", {})
		amount = maxi(int(round(float(amount) * float(config.get("damage_taken_multiplier", 0.50)))), 0)
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10
	_visual_call(&"play_hit")
	queue_redraw()
	if current_hp <= 0:
		_begin_death()
