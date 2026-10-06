extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload(
	"res://src/ui/combat_status_effect_visual.gd"
)
const DAMAGE_NUMBERS := preload(
	"res://src/ui/damage_number_spawner.gd"
)
const MONSTER_RUNTIME_COMMON := preload(
	"res://src/monsters/monster_runtime_common.gd"
)
const PROJECTILE_SCENE := preload(
	"res://src/monsters/GhostProjectile.tscn"
)

const PROJECTILE_POOL_KEY := "ghost_projectile"
const NORMAL_FRAME_DIR := "res://assets/art/monsters/ghost/frames"
const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "ghost"
@export var monster_role: String = "controller"
@export var max_hp: int = 92
@export var move_speed: float = 54.0
@export var attack_damage: int = 4
@export var attack_range: float = 275.0
@export var attack_cooldown: float = 2.40
@export var projectile_speed: float = 500.0
@export var projectile_range: float = 360.0
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
var visual_moving_state: int = -1
var visual_facing_sign: int = 0
var far_ai_tick_timer: float = 0.0
var cached_direction_to_hero: Vector2 = Vector2.ZERO
var soft_separation_timer: float = 0.0
var soft_separation_bias: Vector2 = Vector2.ZERO
var visual_lod_suspended: bool = false
var special_augment_configs: Dictionary = {}

var phase_shift_active: bool = false
var phase_shift_elapsed: float = 0.0
var phase_shift_duration: float = 1.0
var phase_shift_alpha: float = 0.22
var phase_shift_target: Vector2 = Vector2.ZERO
var phase_shift_teleported: bool = false


func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = (
		MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	)
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
	if (
		not is_instance_valid(visual)
		or not visual.has_method("apply_visual_profile")
	):
		return
		
	var target_height := float(visual.get("target_height"))
	
	visual.call("apply_visual_profile", {
		"mode": "frames",
		"asset_dir": NORMAL_FRAME_DIR,
		"target_height": target_height,
		"animations": {
			"idle": {
				"prefix": "idle", "count": 5, "fps": 7.0, "loop": true
			},
			"move": {
				"prefix": "walk", "count": 6, "fps": 8.0, "loop": true
			},
			"attack": {
				"prefix": "atk", "count": 7, "fps": 10.0, "loop": false
			},
			"hit": {
				"prefix": "hit", "count": 4, "fps": 12.0, "loop": false
			},
			"death": {
				"prefix": "dead", "count": 7, "fps": 9.0, "loop": false
			},
		},
	})


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

	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0:
			queue_redraw()

	if phase_shift_active:
		_tick_phase_shift(delta)
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
		soft_separation_bias = (
			MONSTER_RUNTIME_COMMON.compute_soft_separation_bias(
				self,
				combat_authority
			)
		)
		soft_separation_timer = (
			MONSTER_RUNTIME_COMMON.next_soft_separation_delay()
		)

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var attack_range_sq := attack_range * attack_range
	var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
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
			far_ai_tick_timer = (
				MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
			)
		var external_multiplier := (
			MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		)
		var move_direction := (
			MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
				direction_to_hero,
				soft_separation_bias
			)
		)
		velocity = move_direction * move_speed * external_multiplier
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
	var idle_multiplier := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	velocity = MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
		soft_separation_bias,
		move_speed * idle_multiplier
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)

	if attack_timer <= 0.0:
		_attack(direction_to_hero)


func _attack(direction_to_hero: Vector2) -> void:
	attack_timer = maxf(attack_cooldown, 0.10)
	_visual_call(&"play_attack")
	if _fire_projectile(direction_to_hero):
		_begin_phase_shift()


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


func _fire_projectile(direction_to_hero: Vector2) -> bool:
	var projectile := _acquire_projectile()
	if projectile == null:
		return false
	projectile.global_position = (
		global_position + direction_to_hero * 18.0
	)
	if not projectile.has_method("setup"):
		return false
	projectile.call(
		"setup",
		direction_to_hero,
		attack_damage,
		projectile_speed,
		projectile_range,
		String(get_meta("visual_variant", "")) == "elite",
		projectile_size_multiplier
	)
	return true


func _begin_phase_shift() -> void:
	var config: Dictionary = special_augment_configs.get(
		"ghost_phase_shift",
		{}
	)
	if config.is_empty() or not is_instance_valid(hero):
		return

	phase_shift_active = true
	phase_shift_elapsed = 0.0
	phase_shift_duration = maxf(
		float(config.get("duration", 1.0)),
		0.10
	)
	phase_shift_alpha = clampf(
		float(config.get("fade_alpha", 0.22)),
		0.05,
		1.0
	)
	phase_shift_teleported = false

	var min_distance := maxf(
		float(config.get("min_distance", 150.0)),
		0.0
	)
	var max_distance := maxf(
		float(config.get("max_distance", 260.0)),
		min_distance
	)
	phase_shift_target = (
		hero.global_position
		+ Vector2.from_angle(randf_range(0.0, TAU))
		* randf_range(min_distance, max_distance)
	)
	if (
		is_instance_valid(combat_authority)
		and combat_authority.has_method("_clamp_manual_spawn_position")
	):
		phase_shift_target = combat_authority.call(
			"_clamp_manual_spawn_position",
			phase_shift_target
		)

	velocity = Vector2.ZERO
	_update_visual_motion(cached_direction_to_hero.x, false)


func _tick_phase_shift(delta: float) -> void:
	velocity = Vector2.ZERO
	phase_shift_elapsed = minf(
		phase_shift_elapsed + delta,
		phase_shift_duration
	)
	var half := phase_shift_duration * 0.5

	if phase_shift_elapsed < half:
		var fade_out := clampf(
			phase_shift_elapsed / maxf(half, 0.01),
			0.0,
			1.0
		)
		if is_instance_valid(visual):
			visual.modulate.a = lerpf(
				1.0,
				phase_shift_alpha,
				fade_out
			)
	else:
		if not phase_shift_teleported:
			phase_shift_teleported = true
			global_position = phase_shift_target
		var fade_in := clampf(
			(phase_shift_elapsed - half) / maxf(half, 0.01),
			0.0,
			1.0
		)
		if is_instance_valid(visual):
			visual.modulate.a = lerpf(
				phase_shift_alpha,
				1.0,
				fade_in
			)

	if phase_shift_elapsed + 0.0001 < phase_shift_duration:
		return

	phase_shift_active = false
	phase_shift_teleported = false
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE


func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying or amount <= 0:
		return

	amount = MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)
	if amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	DAMAGE_NUMBERS.show(self, previous_hp - current_hp)
	hit_flash_timer = 0.10
	queue_redraw()

	if current_hp <= 0:
		_begin_death()
		return
	_visual_call(&"play_hit")


func heal_direct(amount: int) -> int:
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
	visual_lod_suspended = (
		MONSTER_RUNTIME_COMMON.apply_standard_visual_lod(
			self,
			visual,
			visual_lod_suspended,
			distance_sq,
			VISUAL_LOD_DISTANCE
		)
	)


func _update_visual_motion(
	direction_x: float,
	moving: bool
) -> void:
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
	phase_shift_active = false
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
	MONSTER_RUNTIME_COMMON.begin_standard_death(
		self,
		visual,
		collision_shape
	)


func _on_death_animation_finished() -> void:
	queue_free()


func _visual_call(
	method_name: StringName,
	args: Array = []
) -> void:
	if (
		is_instance_valid(visual)
		and visual.has_method(method_name)
	):
		visual.callv(method_name, args)


func _draw() -> void:
	var visual_ready := false
	if (
		is_instance_valid(visual)
		and visual.has_method("is_visual_ready")
	):
		visual_ready = bool(visual.call("is_visual_ready"))

	if not visual_ready:
		var body_color := Color(0.72, 0.82, 0.92, 0.82)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2(0.0, -10.0), 22.0, body_color)

	if dying:
		return

	var bar_width := 58.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -56.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(
			-bar_width / 2.0,
			-56.0,
			bar_width * hp_ratio,
			7.0
		),
		Color(0.3, 0.9, 0.45),
		true
	)
