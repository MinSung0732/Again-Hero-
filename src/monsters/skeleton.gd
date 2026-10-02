extends CharacterBody2D

const COMBAT_STATUS_EFFECT_VISUAL := preload(
	"res://src/ui/combat_status_effect_visual.gd"
)
const MONSTER_RUNTIME_COMMON := preload(
	"res://src/monsters/monster_runtime_common.gd"
)
const DAMAGE_NUMBERS := preload(
	"res://src/ui/damage_number_spawner.gd"
)

const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0

signal died

@export var monster_type: String = "skeleton"
@export var monster_role: String = "tank"
@export var max_hp: int = 105
@export var move_speed: float = 112.0
@export var attack_damage: int = 10
@export var attack_range: float = 78.0
@export var attack_cooldown: float = 1.25
@export var hits_per_attack: int = 2
@export var hit_damage_multiplier: float = 1.0
@export var second_hit_delay: float = 0.14
@export var exp_reward: int = 28

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int
var hero: Node2D
var combat_authority: Node
var hero_target_refresh_timer := 0.0
var attack_timer := 0.0
var hit_flash_timer := 0.0
var dying := false
var reviving := false
var revive_used := false
var revive_timer := 0.0
var revive_reverse_started := false
var visual_moving_state := -1
var visual_facing_sign := 0
var far_ai_tick_timer := 0.0
var cached_direction_to_hero := Vector2.ZERO
var soft_separation_timer := 0.0
var soft_separation_bias := Vector2.ZERO
var visual_lod_suspended := false
var special_augment_configs: Dictionary = {}
var bone_bond_refresh_timer := 0.0
var bone_bond_active := false
var bone_bond_scratch: Array = []
var pending_second_hit_timer := -1.0
var pending_second_hit_damage := 0
var pending_second_hit_target: Node2D


func _ready() -> void:
	add_to_group("monsters")
	far_ai_tick_timer = MONSTER_RUNTIME_COMMON.initial_far_navigation_delay()
	soft_separation_timer = (
		MONSTER_RUNTIME_COMMON.initial_soft_separation_delay()
	)
	bone_bond_refresh_timer = randf_range(0.0, 0.12)
	current_hp = max_hp
	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
	if not is_instance_valid(combat_authority):
		combat_authority = get_parent()
	MONSTER_RUNTIME_COMMON.attach_status_effect_visual(
		self,
		COMBAT_STATUS_EFFECT_VISUAL,
		"slow"
	)
	queue_redraw()


func configure_combat_context(
	primary_hero: Node2D,
	authority: Node
) -> void:
	hero = primary_hero
	combat_authority = authority


func configure_special_augments(configs: Dictionary) -> void:
	special_augment_configs = configs.duplicate(true)
	if not special_augment_configs.has("skeleton_bone_bond"):
		bone_bond_active = false


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
	_tick_pending_second_hit(delta)
	_tick_bone_bond(delta)

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

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if hit_flash_timer <= 0.0:
			queue_redraw()

	if not is_instance_valid(hero):
		_refresh_combat_target()
		if not is_instance_valid(hero):
			velocity = Vector2.ZERO
			_update_visual_motion(0.0, false)
			return

	var external_speed := (
		MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	)
	var effective_move_speed := (
		move_speed
		* external_speed
		* _get_bone_bond_value("move_speed_multiplier", 1.0)
	)
	var effective_attack_cooldown := attack_cooldown / maxf(
		_get_bone_bond_value("attack_speed_multiplier", 1.0),
		0.01
	)

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
			far_ai_tick_timer = (
				MONSTER_RUNTIME_COMMON.next_far_navigation_delay()
			)
		var move_direction := (
			MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
				direction_to_hero,
				soft_separation_bias
			)
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

	if attack_timer <= 0.0:
		attack_timer = effective_attack_cooldown
		_perform_attack(hero)


func _perform_attack(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	_visual_call(&"play_attack")

	var damage_multiplier := _get_bone_bond_value(
		"damage_multiplier",
		1.0
	)
	var ambush_multiplier := 1.0
	if bool(get_meta("elite_skeleton_ambush_active", false)):
		ambush_multiplier = maxf(
			float(get_meta(
				"elite_skeleton_ambush_attack_multiplier",
				1.50
			)),
			1.0
		)
		_break_ambush()

	var hit_damage := maxi(
		int(round(
			float(attack_damage)
			* maxf(hit_damage_multiplier, 0.0)
			* damage_multiplier
			* ambush_multiplier
		)),
		1
	)
	_apply_attack_hit(target, hit_damage)

	if hits_per_attack >= 2:
		pending_second_hit_target = target
		pending_second_hit_damage = hit_damage
		pending_second_hit_timer = maxf(second_hit_delay, 0.01)


func _tick_pending_second_hit(delta: float) -> void:
	if pending_second_hit_timer < 0.0:
		return
	pending_second_hit_timer -= delta
	if pending_second_hit_timer > 0.0:
		return
	pending_second_hit_timer = -1.0
	var target := pending_second_hit_target
	pending_second_hit_target = null
	if is_instance_valid(target):
		_apply_attack_hit(target, pending_second_hit_damage, true)


func _apply_attack_hit(
	target: Node2D,
	damage: int,
	is_followup_hit: bool = false
) -> void:
	if not is_instance_valid(target) or damage <= 0:
		return
	if (
		is_followup_hit
		and target.has_method("take_followup_damage")
	):
		target.call("take_followup_damage", damage, self)
		return
	if target.has_method("take_damage"):
		target.call("take_damage", damage, self)


func _tick_bone_bond(delta: float) -> void:
	var config: Dictionary = special_augment_configs.get(
		"skeleton_bone_bond",
		{}
	)
	if config.is_empty():
		bone_bond_active = false
		return
	bone_bond_refresh_timer = maxf(
		bone_bond_refresh_timer - delta,
		0.0
	)
	if bone_bond_refresh_timer > 0.0:
		return
	bone_bond_refresh_timer = maxf(
		float(config.get("refresh_interval", 0.12)),
		0.05
	)
	bone_bond_active = false
	if (
		not is_instance_valid(combat_authority)
		or not combat_authority.has_method("fill_monsters_near")
	):
		return

	bone_bond_scratch.clear()
	combat_authority.call(
		"fill_monsters_near",
		global_position,
		maxf(float(config.get("radius", 75.0)), 1.0),
		bone_bond_scratch
	)
	var skeleton_count := 0
	for raw_monster in bone_bond_scratch:
		if not is_instance_valid(raw_monster):
			continue
		if String(raw_monster.get("monster_type")) != "skeleton":
			continue
		if int(raw_monster.get("current_hp")) <= 0:
			continue
		skeleton_count += 1
		if skeleton_count >= maxi(
			int(config.get("required_count", 3)),
			1
		):
			bone_bond_active = true
			break
	bone_bond_scratch.clear()


func _get_bone_bond_value(key: String, fallback: float) -> float:
	if not bone_bond_active:
		return fallback
	var config: Dictionary = special_augment_configs.get(
		"skeleton_bone_bond",
		{}
	)
	return maxf(float(config.get(key, fallback)), 0.01)


func take_damage(amount: int) -> void:
	if current_hp <= 0 or dying or reviving or amount <= 0:
		return

	var damage_multiplier := 1.0
	if bool(get_meta("elite_skeleton_ambush_active", false)):
		damage_multiplier *= clampf(
			float(get_meta(
				"elite_skeleton_ambush_damage_taken_multiplier",
				0.50
			)),
			0.0,
			1.0
		)

	var guard: Dictionary = special_augment_configs.get(
		"skeleton_necrotic_guard",
		{}
	)
	if (
		not guard.is_empty()
		and is_instance_valid(combat_authority)
		and combat_authority.has_method("has_living_elite_skeleton")
		and bool(combat_authority.call("has_living_elite_skeleton"))
	):
		damage_multiplier *= clampf(
			float(guard.get("damage_taken_multiplier", 0.75)),
			0.0,
			1.0
		)

	var reduced_damage := maxi(
		int(round(float(amount) * damage_multiplier)),
		1
	)
	var previous_hp := current_hp
	current_hp = maxi(current_hp - reduced_damage, 0)
	var applied_damage := previous_hp - current_hp
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.12
	queue_redraw()

	if current_hp <= 0:
		if _can_revive():
			_begin_revival()
		else:
			_notify_elite_alive(false)
			_break_ambush()
			_begin_death()
		return

	_visual_call(&"play_hit")


func _can_revive() -> bool:
	if revive_used:
		return false
	var config: Dictionary = special_augment_configs.get(
		"skeleton_return_of_dead",
		{}
	)
	return not config.is_empty()


func _begin_revival() -> void:
	revive_used = true
	reviving = true
	set_meta("elite_skill_reviving", true)
	velocity = Vector2.ZERO
	pending_second_hit_timer = -1.0
	pending_second_hit_target = null
	_break_ambush()
	_notify_elite_alive(false)
	var config: Dictionary = special_augment_configs.get(
		"skeleton_return_of_dead",
		{}
	)
	revive_timer = maxf(
		float(config.get("revive_delay", 2.0)),
		0.05
	)
	revive_reverse_started = false
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	if is_instance_valid(visual):
		visual.modulate = Color(0.38, 0.42, 0.46, 0.45)
		_visual_call(&"play_revival_death_pose")
	queue_redraw()


func _tick_revival(delta: float) -> void:
	velocity = Vector2.ZERO
	if revive_reverse_started:
		return

	revive_timer = maxf(revive_timer - delta, 0.0)
	var can_reverse_visual := (
		is_instance_valid(visual)
		and visual.has_method("is_revival_death_pose_ready")
		and visual.has_signal("revival_animation_finished")
		and visual.has_method("play_revival_reverse")
	)
	if can_reverse_visual:
		if not bool(visual.call("is_revival_death_pose_ready")):
			return
		revive_reverse_started = true
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
		visual.call(
			"play_revival_reverse",
			maxf(revive_timer, 0.05)
		)
		return

	if revive_timer > 0.0:
		return
	revive_reverse_started = true
	_complete_revival()


func _complete_revival() -> void:
	if not reviving:
		return
	var config: Dictionary = special_augment_configs.get(
		"skeleton_return_of_dead",
		{}
	)
	current_hp = maxi(
		int(round(
			float(max_hp)
			* clampf(
				float(config.get("revive_hp_ratio", 1.0)),
				0.01,
				1.0
			)
		)),
		1
	)
	reviving = false
	revive_reverse_started = false
	set_meta("elite_skill_reviving", false)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
	_visual_call(&"play_locomotion", [false])
	_notify_elite_alive(true)
	queue_redraw()


func _break_ambush() -> void:
	if not bool(get_meta("elite_skeleton_ambush_active", false)):
		return
	set_meta("elite_skeleton_ambush_active", false)
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE


func _notify_elite_alive(alive: bool) -> void:
	if String(get_meta("visual_variant", "")) != "elite":
		return
	if (
		is_instance_valid(combat_authority)
		and combat_authority.has_method("set_elite_skeleton_alive")
	):
		combat_authority.call("set_elite_skeleton_alive", self, alive)


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
		var body_color := Color(0.78, 0.77, 0.70)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2(0.0, -8.0), 24.0, body_color)
		draw_rect(Rect2(-22.0, 12.0, 44.0, 42.0), body_color, true)
	if dying:
		return

	var bar_width := 70.0
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -55.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -55.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)

	if reviving:
		var config: Dictionary = special_augment_configs.get(
			"skeleton_return_of_dead",
			{}
		)
		var total_delay := maxf(
			float(config.get("revive_delay", 2.0)),
			0.05
		)
		var revive_progress := 1.0 - clampf(
			revive_timer / total_delay,
			0.0,
			1.0
		)
		draw_arc(
			Vector2.ZERO,
			31.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * revive_progress,
			20,
			Color(0.72, 0.84, 1.0, 0.85),
			4.0
		)
