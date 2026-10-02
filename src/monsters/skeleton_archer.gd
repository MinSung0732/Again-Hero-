extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const MONSTER_RUNTIME_COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const PROJECTILE_SCENE := preload("res://src/monsters/SkeletonArcherProjectile.tscn")
const PROJECTILE_POOL_KEY := "skeleton_archer_projectile"

const NORMAL_FRAME_DIR := "res://assets/art/monsters/skelletonarcher/frames"
const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "skeleton_archer"
@export var monster_role: String = "ranged"
@export var max_hp: int = 48
@export var move_speed: float = 88.0
@export var attack_damage: int = 8
@export var attack_range: float = 137.5
@export var attack_cooldown: float = 1.55
@export var projectile_speed: float = 300.0
@export var projectile_range: float = 190.0
@export var projectile_size_multiplier: float = 1.0
@export var exp_reward: int = 24

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var combat_authority: Node
var hero_target_refresh_timer: float = 0.0
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false
var reviving: bool = false
var revive_used: bool = false
var revive_timer: float = 0.0
var revive_reverse_started: bool = false
var visual_moving_state: int = -1
var visual_facing_sign: int = 0
var far_ai_tick_timer: float = 0.0
var cached_direction_to_hero: Vector2 = Vector2.ZERO
var soft_separation_timer: float = 0.0
var soft_separation_bias: Vector2 = Vector2.ZERO
var visual_lod_suspended: bool = false
var special_augment_configs: Dictionary = {}

var attack_windup_timer: float = -1.0
var burst_shot_timer: float = -1.0
var burst_shots_remaining: int = 0
var burst_total_shots: int = 0
var burst_interval: float = 0.40
var attack_power_mode: bool = false
var attack_damage_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("monsters")
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	current_hp = max_hp
	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	hero_target_refresh_timer = 0.0
	_apply_normal_visual_profile()
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(
		self,
		COMBAT_STATUS_EFFECT_VISUAL,
		"slow"
	)
	queue_redraw()


func _apply_normal_visual_profile() -> void:
	if not is_instance_valid(visual):
		return
	if not visual.has_method("apply_visual_profile"):
		return
	var target_height := float(visual.get("target_height"))
	var profile := {
		"mode": "frames",
		"asset_dir": NORMAL_FRAME_DIR,
		"target_height": target_height,
		"animations": {
			"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
			"move": {"prefix": "walk", "count": 6, "fps": 9.0, "loop": true},
			"attack": {"prefix": "atk", "count": 6, "fps": 14.0, "loop": false},
			"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
			"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
		},
	}
	visual.call("apply_visual_profile", profile)


func configure_combat_context(
	primary_hero: Node2D,
	authority: Node
) -> void:
	hero = primary_hero
	combat_authority = authority


func configure_special_augments(configs: Dictionary) -> void:
	special_augment_configs = configs.duplicate(true)


func _refresh_combat_target() -> void:
	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.TARGET_REFRESH_INTERVAL
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	hero = MONSTER_RUNTIME_COMMON.resolve_combat_target(
		self,
		hero,
		combat_authority
	)


func _physics_process(delta: float) -> void:
	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		hero_target_refresh_timer,
		delta
	)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(
		hero_target_refresh_timer,
		hero
	):
		_refresh_combat_target()

	if reviving:
		_tick_revival(delta)
		return
	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0:
			queue_redraw()

	if _tick_attack_sequence(delta):
		velocity = Vector2.ZERO
		_update_visual_motion(cached_direction_to_hero.x, false)
		return

	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		_update_visual_motion(0.0, false)
		return

	soft_separation_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		soft_separation_timer,
		delta
	)
	if soft_separation_timer <= 0.0:
		soft_separation_bias = MONSTER_RUNTIME_COMMON.compute_soft_separation_bias(
			self,
			combat_authority
		)
		soft_separation_timer = MONSTER_RUNTIME_COMMON.next_soft_separation_delay()

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
	var attack_range_sq := attack_range * attack_range
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		far_ai_tick_timer,
		delta
	)

	if distance_sq > attack_range_sq:
		var direction_to_hero := cached_direction_to_hero
		if MONSTER_RUNTIME_COMMON.should_refresh_far_navigation(
			distance_sq,
			far_nav_sq,
			far_ai_tick_timer
		):
			direction_to_hero = offset_to_hero.normalized()
			cached_direction_to_hero = direction_to_hero
			far_ai_tick_timer = MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
		var external_slow := MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(
			self
		)
		var move_direction := MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
			direction_to_hero,
			soft_separation_bias
		)
		velocity = move_direction * move_speed * external_slow
		_update_visual_motion(move_direction.x, true)
		if distance_sq > far_nav_sq:
			global_position += velocity * delta
		else:
			move_and_slide()
		return

	var direction_to_hero := (
		offset_to_hero.normalized()
		if distance_sq > 0.001
		else cached_direction_to_hero
	)
	cached_direction_to_hero = direction_to_hero
	var idle_external_slow := MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(
		self
	)
	velocity = MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
		soft_separation_bias,
		move_speed * idle_external_slow
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)

	if attack_timer <= 0.0:
		_begin_attack_sequence()


func _begin_attack_sequence() -> void:
	var power: Dictionary = special_augment_configs.get(
		"skeleton_archer_power_shot",
		{}
	)
	var triple: Dictionary = special_augment_configs.get(
		"skeleton_archer_triple_shot",
		{}
	)
	attack_power_mode = not power.is_empty()
	attack_damage_multiplier = maxf(
		float(power.get("damage_multiplier", 1.0)),
		0.01
	)
	burst_total_shots = (
		maxi(int(triple.get("shot_count", 3)), 1)
		if not triple.is_empty()
		else 1
	)
	burst_shots_remaining = burst_total_shots
	burst_interval = maxf(float(triple.get("shot_interval", 0.40)), 0.01)
	burst_shot_timer = -1.0
	_visual_call(&"play_attack")

	var windup := (
		maxf(float(power.get("windup_delay", 0.25)), 0.0)
		if attack_power_mode
		else 0.0
	)
	if windup > 0.0:
		attack_windup_timer = windup
		return
	attack_windup_timer = -1.0
	_fire_next_burst_shot()


func _tick_attack_sequence(delta: float) -> bool:
	if attack_windup_timer >= 0.0:
		attack_windup_timer = maxf(attack_windup_timer - delta, 0.0)
		if attack_windup_timer > 0.0:
			return true
		attack_windup_timer = -1.0
		_fire_next_burst_shot()
		return _is_attack_sequence_active()

	if burst_shots_remaining > 0 and burst_shot_timer >= 0.0:
		burst_shot_timer = maxf(burst_shot_timer - delta, 0.0)
		if burst_shot_timer > 0.0:
			return true
		burst_shot_timer = -1.0
		_visual_call(&"play_attack")
		_fire_next_burst_shot()
		return _is_attack_sequence_active()

	return false


func _is_attack_sequence_active() -> bool:
	return (
		attack_windup_timer >= 0.0
		or (burst_shots_remaining > 0 and burst_shot_timer >= 0.0)
	)


func _fire_next_burst_shot() -> void:
	if burst_shots_remaining <= 0:
		_finish_attack_sequence()
		return

	if is_instance_valid(hero):
		var offset := hero.global_position - global_position
		if offset.length_squared() > 0.001:
			cached_direction_to_hero = offset.normalized()
		_fire_projectile(cached_direction_to_hero)

	burst_shots_remaining -= 1
	if burst_shots_remaining > 0:
		burst_shot_timer = burst_interval
	else:
		_finish_attack_sequence()


func _finish_attack_sequence() -> void:
	attack_windup_timer = -1.0
	burst_shot_timer = -1.0
	burst_shots_remaining = 0
	burst_total_shots = 0
	attack_timer = maxf(attack_cooldown, 0.10)


func _cancel_attack_sequence() -> void:
	attack_windup_timer = -1.0
	burst_shot_timer = -1.0
	burst_shots_remaining = 0
	burst_total_shots = 0


func _acquire_projectile() -> Area2D:
	var projectile_parent := get_parent()
	if not is_instance_valid(projectile_parent):
		return null
	if projectile_parent.has_method("acquire_projectile"):
		var pooled = projectile_parent.call(
			"acquire_projectile",
			PROJECTILE_SCENE,
			PROJECTILE_POOL_KEY
		)
		if pooled is Area2D:
			return pooled as Area2D
	var projectile := PROJECTILE_SCENE.instantiate() as Area2D
	if projectile != null:
		projectile_parent.add_child(projectile)
	return projectile


func _fire_projectile(direction_to_hero: Vector2) -> void:
	var projectile := _acquire_projectile()
	if projectile == null:
		return
	projectile.global_position = global_position + direction_to_hero * 18.0
	var is_elite := String(get_meta("visual_variant", "")) == "elite"
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			direction_to_hero,
			maxi(
				int(round(
					float(attack_damage) * attack_damage_multiplier
				)),
				1
			),
			projectile_speed,
			projectile_range,
			attack_power_mode,
			is_elite,
			projectile_size_multiplier
		)


func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying or reviving or amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.12
	queue_redraw()

	if current_hp <= 0:
		if _can_revive():
			_begin_revival()
		else:
			_begin_death()
		return

	_visual_call(&"play_hit")


func _can_revive() -> bool:
	if revive_used:
		return false
	var config: Dictionary = special_augment_configs.get(
		"skeleton_archer_revive",
		{}
	)
	return not config.is_empty()


func _begin_revival() -> void:
	revive_used = true
	reviving = true
	set_meta("elite_skill_reviving", true)
	velocity = Vector2.ZERO
	_cancel_attack_sequence()
	var config: Dictionary = special_augment_configs.get(
		"skeleton_archer_revive",
		{}
	)
	revive_timer = maxf(float(config.get("revive_delay", 2.0)), 0.05)
	revive_reverse_started = false
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		_visual_call(&"play_revival_death_pose")
	queue_redraw()


func _tick_revival(delta: float) -> void:
	revive_timer = maxf(revive_timer - delta, 0.0)
	velocity = Vector2.ZERO
	if revive_timer > 0.0 or revive_reverse_started:
		return

	if (
		is_instance_valid(visual)
		and visual.has_method("is_revival_death_pose_ready")
		and not bool(visual.call("is_revival_death_pose_ready"))
	):
		return

	revive_reverse_started = true
	if (
		is_instance_valid(visual)
		and visual.has_signal("revival_animation_finished")
		and visual.has_method("play_revival_reverse")
	):
		var revive_finished := Callable(self, "_complete_revival")
		if not visual.is_connected(
			"revival_animation_finished",
			revive_finished
		):
			visual.connect(
				"revival_animation_finished",
				revive_finished,
				Object.CONNECT_ONE_SHOT
			)
		visual.call("play_revival_reverse")
		return

	_complete_revival()


func _complete_revival() -> void:
	if not reviving:
		return
	var config: Dictionary = special_augment_configs.get(
		"skeleton_archer_revive",
		{}
	)
	current_hp = maxi(
		int(round(
			float(max_hp)
			* clampf(float(config.get("revive_hp_ratio", 1.0)), 0.01, 1.0)
		)),
		1
	)
	reviving = false
	revive_reverse_started = false
	set_meta("elite_skill_reviving", false)
	attack_timer = maxf(attack_cooldown, 0.10)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
	queue_redraw()


func heal_direct(amount: int) -> int:
	if reviving:
		return 0
	var recovered := MONSTER_RUNTIME_COMMON.apply_direct_heal(
		self,
		amount,
		current_hp,
		max_hp,
		dying
	)
	current_hp += recovered
	return recovered


func _update_visual_lod(distance_sq: float) -> void:
	visual_lod_suspended = MONSTER_RUNTIME_COMMON.apply_standard_visual_lod(
		self,
		visual,
		visual_lod_suspended,
		distance_sq,
		VISUAL_LOD_DISTANCE
	)


func _update_visual_motion(direction_x: float, moving: bool) -> void:
	var facing_sign := 0
	if direction_x > 0.01:
		facing_sign = 1
	elif direction_x < -0.01:
		facing_sign = -1
	if facing_sign != 0 and facing_sign != visual_facing_sign:
		visual_facing_sign = facing_sign
		_visual_call(&"set_facing_direction", [direction_x])
	var moving_state := 1 if moving else 0
	if moving_state != visual_moving_state:
		visual_moving_state = moving_state
		_visual_call(&"play_locomotion", [moving])


func _begin_death() -> void:
	set_meta("elite_skill_reviving", false)
	_cancel_attack_sequence()
	MONSTER_RUNTIME_COMMON.begin_standard_death(
		self,
		visual,
		collision_shape
	)


func _on_death_animation_finished() -> void:
	queue_free()


func _visual_call(method_name: StringName, args: Array = []) -> void:
	if not is_instance_valid(visual):
		return
	if not visual.has_method(method_name):
		return
	visual.callv(method_name, args)


func _draw() -> void:
	var visual_ready := false
	if is_instance_valid(visual) and visual.has_method("is_visual_ready"):
		visual_ready = bool(visual.call("is_visual_ready"))
	if not visual_ready:
		var body_color := Color(0.80, 0.78, 0.70)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2(0.0, -8.0), 22.0, body_color)
		draw_line(Vector2(-16.0, 12.0), Vector2(18.0, 34.0), body_color, 5.0)

	if dying:
		return
	var bar_width := 64.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -51.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -51.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)
	if reviving:
		var config: Dictionary = special_augment_configs.get(
			"skeleton_archer_revive",
			{}
		)
		var total_delay := maxf(float(config.get("revive_delay", 2.0)), 0.05)
		var progress := 1.0 - clampf(revive_timer / total_delay, 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			29.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * progress,
			20,
			Color(0.72, 0.84, 1.0, 0.85),
			4.0
		)
