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
	"res://src/monsters/GoblinThrowerProjectile.tscn"
)

const PROJECTILE_POOL_KEY := "goblin_thrower_projectile"
const NORMAL_FRAME_DIR := "res://assets/art/monsters/goblinthrower/frames"
const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "goblin_thrower"
@export var monster_role: String = "ranged"
@export var max_hp: int = 56
@export var move_speed: float = 82.0
@export var attack_damage: int = 7
@export var attack_range: float = 275.0
@export var attack_cooldown: float = 1.20
@export var projectile_speed: float = 380.0
@export var projectile_range: float = 340.0
@export var projectile_size_multiplier: float = 1.0
@export var exp_reward: int = 20

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
var visual_lod_suspended: bool = false
var far_ai_tick_timer: float = 0.0
var cached_direction_to_hero: Vector2 = Vector2.ZERO
var soft_separation_timer: float = 0.0
var soft_separation_bias: Vector2 = Vector2.ZERO
var special_augment_configs: Dictionary = {}

var retreating: bool = false
var retreat_heal_buffer: float = 0.0


func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
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
				"prefix": "walk", "count": 5, "fps": 9.0, "loop": true
			},
			"attack": {
				"prefix": "atk", "count": 6, "fps": 12.0, "loop": false
			},
			"hit": {
				"prefix": "hit", "count": 2, "fps": 14.0, "loop": false
			},
			"death": {
				"prefix": "dead", "count": 3, "fps": 10.0, "loop": false
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

	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		_update_visual_motion(0.0, false)
		return

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	if _tick_retreat_and_heal(delta):
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

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var attack_range_sq := attack_range * attack_range
	var external_multiplier := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)

	if distance_sq > attack_range_sq:
		far_ai_tick_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
			far_ai_tick_timer,
			delta
		)
		var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
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
	velocity = MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
		soft_separation_bias,
		move_speed * external_multiplier
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)

	if attack_timer > 0.0:
		return
	attack_timer = _get_effective_attack_cooldown()
	_visual_call(&"play_attack")
	_fire_projectile(offset_to_hero)


func _tick_retreat_and_heal(delta: float) -> bool:
	var config: Dictionary = special_augment_configs.get(
		"goblin_thrower_retreat_heal",
		{}
	)
	if config.is_empty():
		retreating = false
		retreat_heal_buffer = 0.0
		return false

	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	var trigger_ratio := clampf(
		float(config.get("trigger_hp_ratio", 0.35)),
		0.01,
		0.99
	)
	var resume_ratio := clampf(
		float(config.get("resume_hp_ratio", 0.60)),
		trigger_ratio,
		1.0
	)
	if not retreating and hp_ratio <= trigger_ratio:
		retreating = true
	if retreating and hp_ratio >= resume_ratio:
		retreating = false
		retreat_heal_buffer = 0.0
		return false
	if not retreating:
		return false

	var heal_ratio := maxf(
		float(config.get("heal_max_hp_per_second", 0.06)),
		0.0
	)
	retreat_heal_buffer += float(max_hp) * heal_ratio * delta
	var heal_points := int(floor(retreat_heal_buffer))
	if heal_points > 0:
		retreat_heal_buffer -= float(heal_points)
		current_hp = mini(current_hp + heal_points, max_hp)
		queue_redraw()

	var away := hero.global_position.direction_to(global_position)
	if away.length_squared() <= 0.0001:
		away = Vector2.LEFT
	var speed_multiplier := maxf(
		float(config.get("retreat_speed_multiplier", 1.25)),
		0.1
	)
	var external_multiplier := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	velocity = (
		away.normalized()
		* move_speed
		* speed_multiplier
		* external_multiplier
	)
	_update_visual_motion(velocity.x, true)
	move_and_slide()
	return true


func _get_effective_attack_cooldown() -> float:
	var speed_multiplier := 1.0
	var config: Dictionary = special_augment_configs.get(
		"goblin_thrower_rapid_fire",
		{}
	)
	if not config.is_empty():
		speed_multiplier = maxf(
			float(config.get("attack_speed_multiplier", 2.0)),
			1.0
		)
	return maxf(attack_cooldown / speed_multiplier, 0.10)


func _fire_projectile(offset_to_hero: Vector2) -> void:
	if offset_to_hero.length_squared() <= 0.001:
		return

	var damage := attack_damage
	var size_multiplier := projectile_size_multiplier
	var heavy_config: Dictionary = special_augment_configs.get(
		"goblin_thrower_heavy_rock",
		{}
	)
	if (
		not heavy_config.is_empty()
		and randf() < clampf(float(heavy_config.get("chance", 0.15)), 0.0, 1.0)
	):
		damage = maxi(
			int(round(
				float(attack_damage)
				* maxf(float(heavy_config.get("damage_multiplier", 1.50)), 0.0)
			)),
			1
		)
		size_multiplier *= maxf(
			float(heavy_config.get("size_multiplier", 1.65)),
			1.0
		)

	var direction_to_hero := offset_to_hero.normalized()
	var projectile := _acquire_projectile()
	if projectile == null:
		return
	projectile.global_position = global_position + direction_to_hero * 24.0
	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			direction_to_hero,
			damage,
			projectile_speed,
			maxf(projectile_range, offset_to_hero.length() + 48.0),
			String(get_meta("visual_variant", "")) == "elite",
			size_multiplier
		)


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


func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying or amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	DAMAGE_NUMBERS.show(self, previous_hp - current_hp)
	hit_flash_timer = 0.12
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
		var body_color := Color(0.42, 0.74, 0.34)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2(0.0, -8.0), 20.0, body_color)

	if dying:
		return
	var bar_width := 58.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -54.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -54.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)
