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
	"res://src/monsters/KoboltProjectile.tscn"
)

const NORMAL_FRAME_DIR := "res://assets/art/monsters/kobolt/frames"
const PROJECTILE_POOL_KEY := "kobolt_projectile"
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "kobolt"
@export var monster_role: String = "ranged"
@export var max_hp: int = 95
@export var move_speed: float = 0.0
@export var attack_damage: int = 28
@export var attack_range: float = 750.0
@export var attack_cooldown: float = 1.80
@export var projectile_speed: float = 385.0
@export var projectile_range: float = 750.0
@export var projectile_size_multiplier: float = 1.0
@export var exp_reward: int = 32

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var combat_authority: Node
var hero_target_refresh_timer: float = 0.0
var attack_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dying: bool = false
var visual_facing_sign: int = 0
var visual_lod_suspended: bool = false
var special_augment_configs: Dictionary = {}


func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	attack_timer = randf_range(0.15, 0.75)
	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	set_meta("forced_movement_immune", true)
	set_meta("movement_effect_immune", true)
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
			"idle": {"prefix": "idle", "count": 5, "fps": 6.0, "loop": true},
			"attack": {"prefix": "atk", "count": 5, "fps": 14.0, "loop": false},
			"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
			"death": {"prefix": "dead", "count": 2, "fps": 10.0, "loop": false},
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
	velocity = Vector2.ZERO
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
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0:
			queue_redraw()

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	if distance_sq > 0.001:
		_set_facing_direction(offset_to_hero.x)

	var unlimited_range_config: Dictionary = special_augment_configs.get(
		"kobolt_unlimited_range",
		{}
	)
	var unlimited_range := not unlimited_range_config.is_empty()
	if not unlimited_range and distance_sq > attack_range * attack_range:
		return
	if attack_timer > 0.0:
		return

	attack_timer = _get_effective_attack_cooldown()
	_visual_call(&"play_attack")
	_fire_projectile(offset_to_hero, unlimited_range_config)


func _get_effective_attack_cooldown() -> float:
	var attack_speed_multiplier := 1.0
	if bool(get_meta("elite_kobolt_fighting_spirit_active", false)):
		attack_speed_multiplier = maxf(
			float(get_meta(
				"elite_kobolt_fighting_spirit_attack_speed_multiplier",
				1.60
			)),
			1.0
		)
	return maxf(attack_cooldown / attack_speed_multiplier, 0.10)


func _fire_projectile(
	offset_to_hero: Vector2,
	unlimited_range_config: Dictionary
) -> void:
	if offset_to_hero.length_squared() <= 0.001:
		return
	var direction_to_hero := offset_to_hero.normalized()
	var projectile := _acquire_projectile()
	if projectile == null:
		return
	projectile.set_meta("combat_source",weakref(self))
	projectile.global_position = global_position + direction_to_hero * 28.0

	var speed_config: Dictionary = special_augment_configs.get(
		"kobolt_projectile_speed",
		{}
	)
	var speed_multiplier := maxf(
		float(speed_config.get("speed_multiplier", 1.0)),
		0.01
	)
	var unlimited_range := not unlimited_range_config.is_empty()
	var max_travel_range := projectile_range
	var falloff_start_range := -1.0
	var falloff_distance := 0.0
	var minimum_damage_multiplier := 1.0
	if unlimited_range:
		max_travel_range = maxf(offset_to_hero.length() + 96.0, projectile_range)
		falloff_start_range = projectile_range
		falloff_distance = maxf(
			float(unlimited_range_config.get(
				"damage_falloff_distance",
				1050.0
			)),
			1.0
		)
		minimum_damage_multiplier = clampf(
			float(unlimited_range_config.get(
				"min_damage_multiplier",
				0.50
			)),
			0.0,
			1.0
		)

	if projectile.has_method("setup"):
		projectile.call(
			"setup",
			direction_to_hero,
			attack_damage,
			projectile_speed * speed_multiplier,
			max_travel_range,
			String(get_meta("visual_variant", "")) == "elite",
			projectile_size_multiplier,
			falloff_start_range,
			falloff_distance,
			minimum_damage_multiplier
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
	_apply_kobolt_damage(amount)

func supports_damage_receipt() -> bool:
	# Inherited receipt code must not bypass a derived actor's take_damage override.
	return get_script().resource_path == "res://src/monsters/kobolt.gd"

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var receipt_revision: int = receipt.begin(self, amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_kobolt_damage(amount, receipt, receipt_revision)
	return receipt.finish(receipt_revision)

func _apply_kobolt_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if current_hp <= 0 or dying or amount <= 0:
		return
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)
	if amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	if receipt != null:
		receipt.record_hp(previous_hp - current_hp, receipt_revision)
	DAMAGE_NUMBERS.show(self, previous_hp - current_hp)
	hit_flash_timer = 0.12
	queue_redraw()

	if current_hp <= 0:
		_begin_death(receipt, receipt_revision)
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


func is_forced_movement_immune() -> bool:
	return true


func is_movement_effect_immune() -> bool:
	return true


func _set_facing_direction(direction_x: float) -> void:
	var facing_sign := 0
	if direction_x > 0.01:
		facing_sign = 1
	elif direction_x < -0.01:
		facing_sign = -1
	if facing_sign == 0 or facing_sign == visual_facing_sign:
		return
	visual_facing_sign = facing_sign
	_visual_call(&"set_facing_direction", [direction_x])


func _update_visual_lod(distance_sq: float) -> void:
	visual_lod_suspended = MONSTER_RUNTIME_COMMON.apply_standard_visual_lod(
		self,
		visual,
		visual_lod_suspended,
		distance_sq,
		VISUAL_LOD_DISTANCE
	)


func _begin_death(receipt = null, receipt_revision: int = 0) -> void:
	MONSTER_RUNTIME_COMMON.begin_standard_death(
		self,
		visual,
		collision_shape,
		&"_on_death_animation_finished",
		receipt,
		receipt_revision
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
		var body_color := Color(0.72, 0.31, 0.24)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2(0.0, -7.0), 23.0, body_color)
		draw_line(Vector2(-10.0, 15.0), Vector2(24.0, 0.0), body_color, 6.0)

	if dying:
		return
	var bar_width := 68.0
	MONSTER_RUNTIME_COMMON.draw_support_shield_bar(self, bar_width, -56.0)
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -56.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -56.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)
