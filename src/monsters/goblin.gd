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

const NORMAL_FRAME_DIR := "res://assets/art/monsters/goblin/frames"
const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0
const PACK_RADIUS := 180.0
const PACK_REFRESH_INTERVAL := 0.20
const COWARD_MULTIPLIER := 0.80
const LARGE_PACK_COUNT := 10
const BASE_LARGE_PACK_MULTIPLIER := 1.10

signal died

@export var monster_type: String = "goblin"
@export var monster_role: String = "swarm"
@export var max_hp: int = 84
@export var move_speed: float = 155.0
@export var attack_damage: int = 7
@export var attack_range: float = 68.0
@export var attack_cooldown: float = 0.72
@export var exp_reward: int = 22

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

var pack_refresh_timer: float = 0.0
var pack_multiplier: float = COWARD_MULTIPLIER
var pack_scratch: Array = []
var survival_time: float = 0.0
var survivor_growth_done: bool = false
var stealth_remaining: float = 0.0
var stealth_damage_multiplier: float = 1.0
var stealth_opacity: float = 1.0


func _ready() -> void:
	add_to_group("monsters")
	current_hp = max_hp
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	pack_refresh_timer = randf_range(0.0, PACK_REFRESH_INTERVAL)
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
	if not is_instance_valid(visual) or not visual.has_method("apply_visual_profile"):
		return
	visual.call("apply_visual_profile", {
		"mode": "frames",
		"asset_dir": NORMAL_FRAME_DIR,
		"target_height": 94.0,
		"animations": {
			"idle": {"prefix": "idle", "count": 4, "fps": 7.0, "loop": true},
			"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
			"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
			"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
			"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
		},
	})


func configure_combat_context(primary_hero: Node2D, authority: Node) -> void:
	hero = primary_hero
	combat_authority = authority


func configure_special_augments(configs: Dictionary) -> void:
	special_augment_configs = configs.duplicate(true)
	_configure_spawn_stealth()
	_try_survivor_growth()


func _configure_spawn_stealth() -> void:
	var config: Dictionary = special_augment_configs.get("goblin_spawn_stealth", {})
	if config.is_empty():
		return
	var duration := maxf(float(config.get("duration", 1.0)), 0.0)
	if duration <= 0.0 or survival_time >= duration:
		return
	stealth_remaining = maxf(duration - survival_time, 0.0)
	stealth_damage_multiplier = clampf(
		float(config.get("damage_taken_multiplier", 0.50)),
		0.0,
		1.0
	)
	stealth_opacity = clampf(float(config.get("opacity", 0.42)), 0.05, 1.0)
	if is_instance_valid(visual):
		visual.modulate = Color(1.0, 1.0, 1.0, stealth_opacity)


func _finish_spawn_stealth() -> void:
	stealth_remaining = 0.0
	stealth_damage_multiplier = 1.0
	stealth_opacity = 1.0
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE


func _refresh_combat_target() -> void:
	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.TARGET_REFRESH_INTERVAL
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	hero = MONSTER_RUNTIME_COMMON.resolve_combat_target(self, hero, combat_authority)


func _physics_process(delta: float) -> void:
	survival_time += delta
	_tick_spawn_stealth(delta)
	_try_survivor_growth()

	hero_target_refresh_timer = MONSTER_RUNTIME_COMMON.tick_countdown(
		hero_target_refresh_timer,
		delta
	)
	if MONSTER_RUNTIME_COMMON.should_refresh_target(hero_target_refresh_timer, hero):
		_refresh_combat_target()

	if current_hp <= 0 or dying:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	pack_refresh_timer = maxf(pack_refresh_timer - delta, 0.0)
	if pack_refresh_timer <= 0.0:
		_refresh_pack_state()
		pack_refresh_timer = PACK_REFRESH_INTERVAL

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

	if hit_flash_timer > 0.0:
		var previous_hit_flash := hit_flash_timer
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
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

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var attack_range_sq := attack_range * attack_range
	var external_multiplier := MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	var effective_move_speed := move_speed * external_multiplier * pack_multiplier

	if distance_sq > attack_range_sq:
		far_ai_tick_timer = MONSTER_RUNTIME_COMMON.tick_countdown(far_ai_tick_timer, delta)
		var far_nav_sq := FAR_NAV_DISTANCE * FAR_NAV_DISTANCE
		var direction_to_hero := cached_direction_to_hero
		if MONSTER_RUNTIME_COMMON.should_refresh_far_navigation(
			distance_sq,
			far_nav_sq,
			far_ai_tick_timer
		):
			direction_to_hero = offset_to_hero.normalized()
			cached_direction_to_hero = direction_to_hero
			far_ai_tick_timer = MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
		var move_direction := MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
			direction_to_hero,
			soft_separation_bias
		)
		velocity = move_direction * effective_move_speed
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
		effective_move_speed
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)
	if attack_timer > 0.0:
		return

	attack_timer = maxf(attack_cooldown / maxf(pack_multiplier, 0.01), 0.10)
	_visual_call(&"play_attack")
	if hero.has_method("take_damage"):
		var effective_damage := maxi(
			int(round(float(attack_damage) * pack_multiplier)),
			1
		)
		hero.call("take_damage", effective_damage, self)


func _tick_spawn_stealth(delta: float) -> void:
	if stealth_remaining <= 0.0:
		return
	stealth_remaining = maxf(stealth_remaining - delta, 0.0)
	if stealth_remaining <= 0.0:
		_finish_spawn_stealth()


func _try_survivor_growth() -> void:
	if survivor_growth_done:
		return
	if bool(get_meta("giant_monster", false)) or String(get_meta("visual_variant", "")) == "elite":
		survivor_growth_done = true
		return
	var config: Dictionary = special_augment_configs.get("goblin_survivor_growth", {})
	if config.is_empty():
		return
	if survival_time < maxf(float(config.get("survival_time", 8.0)), 0.0):
		return
	if (
		not is_instance_valid(combat_authority)
		or not combat_authority.has_method("promote_monster_to_giant")
	):
		return
	survivor_growth_done = bool(combat_authority.call(
		"promote_monster_to_giant",
		self,
		monster_type
	))


func _refresh_pack_state() -> void:
	if (
		not is_instance_valid(combat_authority)
		or not combat_authority.has_method("fill_monsters_near")
	):
		pack_multiplier = COWARD_MULTIPLIER
		return

	pack_scratch.clear()
	combat_authority.call("fill_monsters_near", global_position, PACK_RADIUS, pack_scratch)
	var radius_sq := PACK_RADIUS * PACK_RADIUS
	var nearby_goblins := 0
	for raw_monster in pack_scratch:
		var candidate := raw_monster as Node2D
		if (
			not is_instance_valid(candidate)
			or candidate.is_queued_for_deletion()
			or String(candidate.get("monster_type")) != "goblin"
		):
			continue
		var hp_value = candidate.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if global_position.distance_squared_to(candidate.global_position) > radius_sq:
			continue
		nearby_goblins += 1
		if nearby_goblins >= LARGE_PACK_COUNT:
			break
	pack_scratch.clear()

	if nearby_goblins < 2:
		pack_multiplier = COWARD_MULTIPLIER
		return
	if nearby_goblins < LARGE_PACK_COUNT:
		pack_multiplier = 1.0
		return

	var pack_config: Dictionary = special_augment_configs.get("goblin_pack_mastery", {})
	pack_multiplier = maxf(
		float(pack_config.get("large_pack_multiplier", BASE_LARGE_PACK_MULTIPLIER)),
		1.0
	)


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


func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying or amount <= 0:
		return
	var remaining_damage := amount
	if stealth_remaining > 0.0:
		remaining_damage = maxi(
			int(round(float(remaining_damage) * stealth_damage_multiplier)),
			1
		)

	var shield_hp := maxi(int(get_meta("elite_shield_hp", 0)), 0)
	if shield_hp > 0:
		var absorbed := mini(shield_hp, remaining_damage)
		shield_hp -= absorbed
		remaining_damage -= absorbed
		set_meta("elite_shield_hp", shield_hp)
		queue_redraw()
		if remaining_damage <= 0:
			return

	var previous_hp := current_hp
	current_hp = maxi(current_hp - remaining_damage, 0)
	DAMAGE_NUMBERS.show(self, previous_hp - current_hp)
	hit_flash_timer = 0.10
	_visual_call(&"play_hit")
	queue_redraw()
	if current_hp <= 0:
		_begin_death()


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


func _begin_death() -> void:
	MONSTER_RUNTIME_COMMON.begin_standard_death(self, visual, collision_shape)


func _on_death_animation_finished() -> void:
	queue_free()


func _visual_call(method_name: StringName, args: Array = []) -> void:
	if is_instance_valid(visual) and visual.has_method(method_name):
		visual.callv(method_name, args)


func _draw() -> void:
	var visual_ready := false
	if is_instance_valid(visual) and visual.has_method("is_visual_ready"):
		visual_ready = bool(visual.call("is_visual_ready"))
	if not visual_ready:
		var body_color := Color(0.28, 0.62, 0.24)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2.ZERO, 21.0, body_color)
		draw_circle(Vector2(-8.0, -16.0), 8.0, body_color)
		draw_circle(Vector2(8.0, -16.0), 8.0, body_color)

	if dying:
		return
	var bar_width := 58.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(Rect2(-bar_width / 2.0, -58.0, bar_width, 7.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(
		Rect2(-bar_width / 2.0, -58.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)

	var shield_hp := maxf(float(get_meta("elite_shield_hp", 0.0)), 0.0)
	var shield_max := maxf(float(get_meta("elite_shield_max_hp", 0.0)), 0.0)
	if shield_hp > 0.0 and shield_max > 0.0:
		var shield_ratio := clampf(shield_hp / shield_max, 0.0, 1.0)
		draw_rect(
			Rect2(-bar_width / 2.0, -67.0, bar_width, 5.0),
			Color(0.10, 0.15, 0.20),
			true
		)
		draw_rect(
			Rect2(-bar_width / 2.0, -67.0, bar_width * shield_ratio, 5.0),
			Color(0.35, 0.80, 1.0),
			true
		)
