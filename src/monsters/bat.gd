extends CharacterBody2D
var attack_status_action: RefCounted
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")

const COMBAT_STATUS_EFFECT_VISUAL := preload(
	"res://src/ui/combat_status_effect_visual.gd"
)
const DAMAGE_NUMBERS := preload(
	"res://src/ui/damage_number_spawner.gd"
)
const MONSTER_RUNTIME_COMMON := preload(
	"res://src/monsters/monster_runtime_common.gd"
)

const NORMAL_FRAME_DIR := "res://assets/art/monsters/bat/frames"
const FAR_NAV_DISTANCE := 900.0
const VISUAL_LOD_DISTANCE := 1400.0
const WANDER_REACHED_DISTANCE_SQ := 24.0 * 24.0

signal died

@export var monster_type: String = "bat"
@export var monster_role: String = "swarm"
@export var max_hp: int = 72
@export var move_speed: float = 72.0
@export var attack_damage: int = 6
@export var attack_range: float = 62.0
@export var attack_cooldown: float = 0.62
@export var detection_range: float = 420.0
@export var charge_speed_multiplier: float = 3.75
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
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var special_augment_configs: Dictionary = {}


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
	if not is_instance_valid(visual):
		return
	if not visual.has_method("apply_visual_profile"):
		return
	visual.call("apply_visual_profile", {
		"mode": "frames",
		"asset_dir": NORMAL_FRAME_DIR,
		"target_height": 86.0,
		"animations": {
			"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
			"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
			"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
			"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
			"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
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

	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
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
		_move_wandering(base_move_speed)
		return

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	_update_visual_lod(distance_sq)
	var attack_range_sq := attack_range * attack_range
	var always_charge := special_augment_configs.has(
		"bat_permanent_charge"
	)
	var charging := (
		always_charge
		or distance_sq <= detection_range * detection_range
	)

	if distance_sq <= attack_range_sq:
		_attack_target(offset_to_hero)
		return

	if charging:
		_move_charging(
			offset_to_hero,
			distance_sq,
			base_move_speed * charge_speed_multiplier,
			delta
		)
		return

	_move_wandering(base_move_speed)


func _move_charging(
	offset_to_hero: Vector2,
	distance_sq: float,
	effective_speed: float,
	delta: float
) -> void:
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
		far_ai_tick_timer = MONSTER_RUNTIME_COMMON.next_far_navigation_delay()

	velocity = direction_to_hero * effective_speed
	_update_visual_motion(direction_to_hero.x, true)
	if distance_sq > far_nav_sq:
		global_position += velocity * delta
	else:
		move_and_slide()


func _move_wandering(effective_speed: float) -> void:
	if (
		wander_timer <= 0.0
		or global_position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE_SQ
	):
		_pick_new_wander_target()

	var desired_direction := global_position.direction_to(wander_target)
	var move_direction := (
		MONSTER_RUNTIME_COMMON.blend_soft_separation_direction(
			desired_direction,
			soft_separation_bias
		)
	)
	velocity = move_direction * effective_speed
	_update_visual_motion(move_direction.x, true)
	move_and_slide()


func _pick_new_wander_target() -> void:
	wander_timer = randf_range(1.6, 3.4)
	var direction := Vector2.from_angle(randf_range(0.0, TAU))
	var candidate := global_position + direction * randf_range(120.0, 320.0)
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


func _attack_target(offset_to_hero: Vector2) -> void:
	var direction_to_hero := (
		offset_to_hero.normalized()
		if offset_to_hero.length_squared() > 0.001
		else cached_direction_to_hero
	)
	cached_direction_to_hero = direction_to_hero
	velocity = MONSTER_RUNTIME_COMMON.get_soft_separation_idle_velocity(
		soft_separation_bias,
		move_speed
	)
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(direction_to_hero.x, false)
	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown
	_visual_call(&"play_attack")
	var damage_dealt := _deal_attack_damage()
	_apply_lifesteal(damage_dealt)
	if damage_dealt > 0:
		_apply_elite_poison()


func _deal_attack_damage() -> int:
	attack_status_action = STATUS_SCOPE.action_or_new(hero)
	var previous_action := STATUS_SCOPE.begin(hero,attack_status_action)
	var result := _status_scoped_deal_attack_damage()
	STATUS_SCOPE.finish(hero,previous_action)
	return result

func _status_scoped_deal_attack_damage() -> int:
	if not is_instance_valid(hero) or not hero.has_method("take_damage"):
		return 0
	var hp_before_value = hero.get("current_hp")
	var shield_before_value = hero.get("shield_hp")
	var hit_result = hero.call("take_damage", attack_damage, self)
	if hit_result is bool and not bool(hit_result):
		return 0

	var damage_dealt := 0
	var hp_after_value = hero.get("current_hp")
	if hp_before_value != null and hp_after_value != null:
		damage_dealt += maxi(
			int(hp_before_value) - int(hp_after_value),
			0
		)
	var shield_after_value = hero.get("shield_hp")
	if shield_before_value != null and shield_after_value != null:
		damage_dealt += maxi(
			int(ceil(float(shield_before_value) - float(shield_after_value))),
			0
		)
	if damage_dealt <= 0 and not (hit_result is bool):
		damage_dealt = attack_damage
	return damage_dealt


func _apply_lifesteal(damage_dealt: int) -> void:
	if damage_dealt <= 0:
		return
	var config: Dictionary = special_augment_configs.get(
		"bat_lifesteal",
		{}
	)
	if config.is_empty():
		return
	var heal_amount := maxi(
		int(round(
			float(damage_dealt)
			* maxf(float(config.get("heal_ratio", 0.70)), 0.0)
		)),
		0
	)
	heal_direct(heal_amount)


func _apply_elite_poison() -> void:
	var previous_action := STATUS_SCOPE.begin(hero,attack_status_action)
	_status_scoped_apply_elite_poison()
	STATUS_SCOPE.finish(hero,previous_action)

func _status_scoped_apply_elite_poison() -> void:
	if not bool(get_meta("elite_bat_poison_fang_active", false)):
		return
	if not is_instance_valid(hero) or not hero.has_method("apply_poison"):
		return
	hero.call(
		"apply_poison",
		float(get_meta("elite_bat_poison_duration", 3.0)),
		float(get_meta("elite_bat_poison_hp_ratio", 0.05)),
		float(get_meta("elite_bat_poison_tick_interval", 0.50)),
		self
	)


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
	_apply_bat_damage(amount)

func supports_damage_receipt() -> bool:
	# A derived actor must explicitly support its own damage implementation.
	return get_script().resource_path == "res://src/monsters/bat.gd"

func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt == null:
		take_damage(amount)
		return false
	var receipt_revision: int = receipt.begin(self, amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_bat_damage(amount, receipt, receipt_revision)
	return receipt.finish(receipt_revision)

func _apply_bat_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:
	if current_hp <= 0 or dying:
		return
	amount = MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)
	if amount <= 0:
		return
	var previous_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	var applied_damage := previous_hp - current_hp
	if receipt != null:
		receipt.record_hp(applied_damage, receipt_revision)
	DAMAGE_NUMBERS.show(self, applied_damage)
	hit_flash_timer = 0.10
	_visual_call(&"play_hit")
	queue_redraw()
	if current_hp <= 0:
		_begin_death(receipt, receipt_revision)


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
	if visual.has_method(method_name):
		visual.callv(method_name, args)


func _draw() -> void:
	var visual_ready := false
	if is_instance_valid(visual) and visual.has_method("is_visual_ready"):
		visual_ready = bool(visual.call("is_visual_ready"))
	if not visual_ready:
		var body_color := Color(0.28, 0.17, 0.38)
		if hit_flash_timer > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2.ZERO, 22.0, body_color)
		draw_polygon(
			PackedVector2Array([
				Vector2(-18.0, -4.0),
				Vector2(-42.0, -20.0),
				Vector2(-34.0, 12.0),
			]),
			PackedColorArray([body_color])
		)
		draw_polygon(
			PackedVector2Array([
				Vector2(18.0, -4.0),
				Vector2(42.0, -20.0),
				Vector2(34.0, 12.0),
			]),
			PackedColorArray([body_color])
		)

	if dying:
		return
	var bar_width := 62.0
	MONSTER_RUNTIME_COMMON.draw_support_shield_bar(self, bar_width, -65.0)
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(-bar_width / 2.0, -65.0, bar_width, 7.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(-bar_width / 2.0, -65.0, bar_width * hp_ratio, 7.0),
		Color(0.3, 0.9, 0.45),
		true
	)
