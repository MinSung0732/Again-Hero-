extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)
signal augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal ultimate_used(ultimate_id: String, ultimate_name: String)

const AUGMENT_CATALOG := preload("res://src/data/hero_augment_catalog.gd")
const BUILD_AI := preload("res://src/ai/hero_build_ai.gd")
const PROJECTILE_SCENE := preload("res://src/hero/HeroProjectile.tscn")
const GUNNER_PROJECTILE_SCENE := preload("res://src/hero/GunnerProjectile.tscn")
const ARCHMAGE_PROJECTILE_SCENE := preload("res://src/hero/ArchmageProjectile.tscn")
const ARCHMAGE_SKILL_PROJECTILE_SCENE := preload("res://src/hero/ArchmageSkillProjectile.tscn")
const ULTIMATE_PIERCING_PROJECTILE_SCENE := preload(
	"res://src/hero/UltimatePiercingProjectile.tscn"
)
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const STATUS_EFFECT_CATALOG := preload("res://src/data/status_effect_catalog.gd")
const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
const STAGE1_FRAME_SIZE := Vector2(64, 64)
const STAGE1_FRAME_DIR := "res://assets/art/heroes/stage1_mage/frames"
const STAGE1_SHIELD_EFFECT_BASE_PATH := "res://assets/art/heroes/stage1_mage/frames/effect_02"
const STAGE1_SHIELD_EFFECT_FRAME_COUNT := 6
const STAGE1_SHIELD_EFFECT_FRAME_SIZE := Vector2(512, 512)
const STAGE1_SHIELD_EFFECT_TARGET_SIZE := 180.0
const STAGE1_CHANNEL_EFFECT_BASE_PATH := "res://assets/art/heroes/stage1_mage/frames/effect_03"
const STAGE1_CHANNEL_EFFECT_FRAME_COUNT := 6
const STAGE1_CHANNEL_EFFECT_TARGET_SIZE := 300.0
const STAGE2_FRAME_DIR := "res://assets/art/heroes/stage2_rogue/frames"
const STAGE2_EFFECT1_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_01"
const STAGE2_EFFECT2_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_02"
const STAGE2_EFFECT3_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_03"
const STAGE3_FRAME_DIR := "res://assets/art/heroes/stage3_fighter/frames"
const STAGE3_BLOCK_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect1"
const STAGE3_SLASH_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect2"
const STAGE3_THRUST_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect3"
const STAGE3_AURA_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect4"
const STAGE3_CHARGE_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect5"
const STAGE4_FRAME_DIR := "res://assets/art/heroes/stage4_gunner/frames"
const STAGE5_FRAME_DIR := "res://assets/art/heroes/stage5_archmage/frames"

# 모든 용사 도트의 화면상 체급 기준은 Stage 1 견습 마법용사다.
# 원본 PNG 캔버스 크기가 아니라 투명 여백을 제외한 실제 도트 높이를
# 기준으로 자동 정규화한다.
const HERO_REFERENCE_SHEET_PATH := "res://assets/art/heroes/stage1_mage/stage1_mage_spritesheet.png"
const HERO_REFERENCE_FRAME_SIZE := Vector2i(64, 64)
const HERO_REFERENCE_RENDER_SCALE := 3.0
# Stage 1 is now built from 256x256 standalone frames, so do not fall back to
# scale=3 when the legacy sheet reference cannot provide a valid used rect.
# Keep the on-screen body height close to the old in-battle mage size instead.
const STAGE1_TARGET_VISIBLE_HEIGHT := 108.0

const APPROACH_DISTANCE_RATIO := 0.86
const FIELD_MARGIN := 72.0
const WANDER_REACHED_DISTANCE := 42.0
const WANDER_MIN_TARGET_DISTANCE := 260.0
const OFFENSE_MEMORY_WINDOW := 20.0
const OFFENSE_MEMORY_MIN_WEIGHT := 0.25
const STATUS_MEMORY_WINDOW := 20.0
const STATUS_MEMORY_MIN_WEIGHT := 0.25
const INVULNERABILITY_BLINK_INTERVAL := 0.07

static var _archmage_fx_frames_cache: Dictionary = {}

@export var max_hp: int = 300
@export var move_speed: float = 230.0
@export var attack_damage: int = 34
@export var attack_range: float = 430.0
@export var attack_cooldown: float = 0.62
@export var projectile_speed: float = 680.0
@export var projectile_splash_radius: float = 0.0
@export var projectile_splash_damage_ratio: float = 0.0
@export var exp_pickup_radius: float = 150.0
@export var exp_gain_multiplier: float = 1.0
var heal_item_multiplier: float = 1.0
@export var ai_sense_radius: float = 420.0
@export var kite_distance: float = 210.0
@export var invulnerability_duration: float = 0.35
@export var facing_switch_delay: float = 0.14
@export var facing_min_horizontal_speed: float = 18.0

var hero_id: String = "ranged_rookie"
var hero_display_name: String = "견습 마법용사"
var hero_archetype: String = "ranged_kiter"
var sprite_sheet_path: String = ""
var sprite_frame_dir: String = ""
var augment_pool_ids: Array[String] = []
var level_growth_config: Dictionary = {}

var rogue_combo_config: Dictionary = {}
var rogue_slash_config: Dictionary = {}
var rogue_combo_index: int = 0
var rogue_slash_cooldown_timer: float = 0.0
var rogue_slash_duration_timer: float = 0.0
var rogue_slash_tick_timer: float = 0.0
var rogue_slash_active: bool = false
var rogue_assassination_active: bool = false
var rogue_assassination_hits_left: int = 0
var rogue_assassination_timer: float = 0.0
var rogue_assassination_cast_timer: float = 0.0
var rogue_combo_damage_multiplier: float = 1.0
var rogue_combo_recovery_multiplier: float = 1.0
var rogue_bonus_combo_hits: int = 0
var rogue_slash_shield_ratio_bonus: float = 0.0
var rogue_assassination_hit_bonus: int = 0
var rogue_execute_threshold_bonus: float = 0.0
var rogue_lifesteal_ratio: float = 0.0
var rogue_lifesteal_buffer: float = 0.0
var rogue_combo_direction: Vector2 = Vector2.RIGHT
var rogue_attack_collision_ignore_timer: float = 0.0
var rogue_saved_collision_mask: int = -1
var fighter_basic_config: Dictionary = {}
var fighter_guard_active: bool = false
var fighter_guard_duration_timer: float = 0.0
var fighter_guard_stored_damage: float = 0.0
var fighter_guard_charge_seconds: float = 20.0
var fighter_guard_shield_ratio_bonus: float = 0.0
var fighter_guard_release_ratio_bonus: float = 0.0
var fighter_guard_damage_reduction_bonus: float = 0.0
var fighter_guard_move_multiplier_bonus: float = 0.0
var fighter_reflect_ratio: float = 0.0
var fighter_basic_damage_multiplier: float = 1.0
var fighter_slash_half_width_bonus: float = 0.0
var fighter_thrust_length_bonus: float = 0.0
var fighter_thrust_damage_bonus: float = 0.0
var fighter_slash_mastery_stacks: int = 0
var fighter_slash_bonus_hits_remaining: int = 0
var fighter_slash_combo_timer: float = 0.0
var fighter_slash_combo_direction: Vector2 = Vector2.ZERO
var fighter_slash_combo_swing_index: int = 0
var common_attack_speed_bonus: float = 0.0
var projectile_count_bonus: int = 0
var fighter_charge_config: Dictionary = {}
var fighter_charge_cooldown_timer: float = 0.0
var fighter_charge_active: bool = false
var fighter_charge_target: Node2D
var fighter_charge_start: Vector2 = Vector2.ZERO
var fighter_charge_end: Vector2 = Vector2.ZERO
var fighter_charge_duration: float = 0.0
var fighter_charge_elapsed: float = 0.0
var fighter_charge_chain_count: int = 0
var fighter_charge_afterimage_timer: float = 0.0
var fighter_courage_bonus: float = 0.0
var fighter_charge_kill_heal: float = 0.0

var gunner_config: Dictionary = {}
var gunner_ammo: int = 12
var gunner_magazine_size: int = 12
var gunner_reloading: bool = false
var gunner_reload_timer: float = 0.0
var gunner_backstep_cooldown: float = 0.0
var gunner_collision_ignore_timer: float = 0.0
var gunner_saved_collision_mask: int = -1
var gunner_cylinder_cooldown: float = 0.0
var gunner_cylinder_decision_timer: float = 0.0
var gunner_deadeye_cooldown: float = 0.0
var gunner_deadeye_active: bool = false
var gunner_deadeye_shots_left: int = 0
var gunner_deadeye_shot_timer: float = 0.0
var gunner_deadeye_direction: Vector2 = Vector2.RIGHT
var gunner_ricochet_stacks: int = 0
var gunner_afterimage_shot_stacks: int = 0
var gunner_reload_move_speed_bonus: float = 0.0
var gunner_deadeye_shot_multiplier: float = 2.0
var gunner_low_hp_backstep_bonus: float = 0.0
var gunner_powder_bonus_per_ammo: float = 0.0
var gunner_powder_consumed_stacks: int = 0

var archmage_element_config: Dictionary = {}
var archmage_last_element: String = ""
var archmage_skill_config: Dictionary = {}
var archmage_skill_cooldowns: Dictionary = {}
var archmage_element_orbs: Dictionary = {}
var archmage_orbit_sprites: Dictionary = {}
var archmage_orbit_angle: float = 0.0
var archmage_chain_dagger_active: bool = false
var archmage_casting_sequence: bool = false

var ultimate_config: Dictionary = {}
var ultimate_charge: float = 0.0
var ultimate_flash_timer: float = 0.0
var ultimate_cooldown_timer: float = 0.0

var shield_skill_config: Dictionary = {}
var shield_cooldown_timer: float = 0.0
var shield_duration_timer: float = 0.0
var shield_hp: float = 0.0
var shield_max_hp: float = 0.0

var channel_skill_config: Dictionary = {}
var channel_cooldown_timer: float = 0.0
var channel_duration_timer: float = 0.0
var channel_tick_timer: float = 0.0
var channeling: bool = false
var channel_hid_hero_sprite: bool = false
var ai_settings: Dictionary = {
	"id": "default",
	"display_name": "기본",
	"observation_interval": 4.0,
	"stack_inertia": 1.0,
	"new_branch_penalty": 0.5,
	"heal_item_desire": 1.0,
	"heal_risk_tolerance": 0.50,
	"heal_detour_weight": 1.0,
	"augment_biases": {},
}

var battlefield_size: Vector2 = Vector2(3200, 3200)

# Same-frame monster queries are common across targeting, AI and AoE skills.
# Cache only for the current process/physics frame pair so combat semantics do not change.
var _monster_nodes_cache: Array = []
var _monster_nodes_cache_process_frame: int = -1
var _monster_nodes_cache_physics_frame: int = -1


func _get_monster_nodes_cached() -> Array:
	var process_frame := Engine.get_process_frames()
	var physics_frame := Engine.get_physics_frames()
	if (
		process_frame != _monster_nodes_cache_process_frame
		or physics_frame != _monster_nodes_cache_physics_frame
	):
		_monster_nodes_cache = get_tree().get_nodes_in_group("monsters")
		_monster_nodes_cache_process_frame = process_frame
		_monster_nodes_cache_physics_frame = physics_frame
	return _monster_nodes_cache


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("query_monsters_near")
	):
		var nearby = battle.call("query_monsters_near", origin, radius)
		if nearby is Array:
			return nearby
	return _get_monster_nodes_cached()


func _get_monster_nodes_in_rect(world_rect: Rect2) -> Array:
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("query_monsters_in_rect")
	):
		var nearby = battle.call("query_monsters_in_rect", world_rect)
		if nearby is Array:
			return nearby
	return _get_monster_nodes_cached()


var current_hp: int
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 50
var build_counts: Dictionary = {}

var target: Node2D
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var hit_flash_timer: float = 0.0
var level_flash_timer: float = 0.0
var attack_pose_timer: float = 0.0
var hit_pose_timer: float = 0.0
var invulnerability_timer: float = 0.0
var is_dying: bool = false
var slow_timer: float = 0.0
var move_multiplier: float = 1.0
var strafe_sign: float = 1.0
var combat_strafe_burst_timer: float = 0.0
var combat_strafe_cooldown_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var facing_candidate_sign: int = 0
var facing_candidate_timer: float = 0.0

var ai_memory_clock: float = 0.0
var offensive_memory_events: Array = []
var status_effect_events: Array = []
var status_resistances: Dictionary = {}
var ai_observation_timer: float = 0.0
var ai_observed_context: Dictionary = {}
var ai_observed_context_time: float = 0.0

var heal_item_target: Node2D
var heal_item_retarget_timer: float = 0.0
var heal_item_steering_direction: Vector2 = Vector2.ZERO
var chest_target: Node2D
var chest_retarget_timer: float = 0.0
var chest_steering_direction: Vector2 = Vector2.ZERO

@onready var follow_camera: Camera2D = $Camera2D
@onready var hero_sprite: AnimatedSprite2D = $HeroSprite
@onready var shield_effect: AnimatedSprite2D = $ShieldEffect
@onready var channel_effect: AnimatedSprite2D = $ChannelEffect
@onready var rogue_attack_effect: AnimatedSprite2D = $RogueAttackEffect

func configure_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return

	hero_id = String(profile.get("id", hero_id))
	hero_display_name = String(profile.get("display_name", hero_display_name))
	hero_archetype = String(profile.get("archetype", hero_archetype))
	sprite_sheet_path = String(profile.get("sprite_sheet_path", ""))
	sprite_frame_dir = String(profile.get("sprite_frame_dir", ""))
	var profile_level_growth = profile.get("level_growth", {})
	level_growth_config = (
		profile_level_growth.duplicate(true)
		if typeof(profile_level_growth) == TYPE_DICTIONARY
		else {}
	)
	var profile_combo = profile.get("rogue_combo", {})
	rogue_combo_config = (
		profile_combo.duplicate(true)
		if typeof(profile_combo) == TYPE_DICTIONARY
		else {}
	)
	var profile_fighter_charge = profile.get("fighter_charge_skill", {})
	fighter_charge_config = (
		profile_fighter_charge.duplicate(true)
		if typeof(profile_fighter_charge) == TYPE_DICTIONARY
		else {}
	)
	fighter_charge_cooldown_timer = maxf(
		float(fighter_charge_config.get("initial_cooldown", 6.0)),
		0.0
	)
	fighter_charge_active = false
	fighter_charge_target = null
	fighter_charge_start = Vector2.ZERO
	fighter_charge_end = Vector2.ZERO
	fighter_charge_duration = 0.0
	fighter_charge_elapsed = 0.0
	fighter_charge_chain_count = 0
	fighter_charge_afterimage_timer = 0.0
	fighter_courage_bonus = 0.0
	fighter_charge_kill_heal = 0.0
	fighter_slash_mastery_stacks = 0
	fighter_slash_bonus_hits_remaining = 0
	fighter_slash_combo_timer = 0.0
	fighter_slash_combo_direction = Vector2.ZERO
	fighter_slash_combo_swing_index = 0
	common_attack_speed_bonus = 0.0
	projectile_count_bonus = 0
	heal_item_target = null
	heal_item_retarget_timer = 0.0
	heal_item_steering_direction = Vector2.ZERO
	chest_target = null
	chest_retarget_timer = 0.0
	chest_steering_direction = Vector2.ZERO
	var profile_fighter_basic = profile.get("fighter_basic", {})
	fighter_basic_config = (
		profile_fighter_basic.duplicate(true)
		if typeof(profile_fighter_basic) == TYPE_DICTIONARY
		else {}
	)
	var profile_gunner = profile.get("gunner", {})
	gunner_config = (
		profile_gunner.duplicate(true)
		if typeof(profile_gunner) == TYPE_DICTIONARY
		else {}
	)
	gunner_magazine_size = maxi(int(gunner_config.get("magazine_size", 12)), 1)
	gunner_ammo = gunner_magazine_size
	gunner_reloading = false
	gunner_reload_timer = 0.0
	gunner_backstep_cooldown = 0.0
	gunner_collision_ignore_timer = 0.0
	gunner_saved_collision_mask = -1
	gunner_cylinder_cooldown = 0.0
	gunner_cylinder_decision_timer = 0.0
	gunner_deadeye_cooldown = 0.0
	gunner_deadeye_active = false
	gunner_deadeye_shots_left = 0
	gunner_deadeye_shot_timer = 0.0
	gunner_deadeye_direction = Vector2.RIGHT
	gunner_ricochet_stacks = 0
	gunner_afterimage_shot_stacks = 0
	gunner_reload_move_speed_bonus = 0.0
	gunner_deadeye_shot_multiplier = 2.0
	gunner_low_hp_backstep_bonus = 0.0
	gunner_powder_bonus_per_ammo = 0.0
	gunner_powder_consumed_stacks = 0
	var profile_archmage_elements = profile.get("archmage_elements", {})
	archmage_element_config = (
		profile_archmage_elements.duplicate(true)
		if typeof(profile_archmage_elements) == TYPE_DICTIONARY
		else {}
	)
	archmage_last_element = ""
	var profile_archmage_skills = profile.get("archmage_skills", {})
	archmage_skill_config = (
		profile_archmage_skills.duplicate(true)
		if typeof(profile_archmage_skills) == TYPE_DICTIONARY
		else {}
	)
	archmage_skill_cooldowns.clear()
	for skill_key in [
		"combustion",
		"ice_bolt",
		"earth_spikes",
		"holy_power",
		"chain_dagger",
		"harmony",
		"storm",
	]:
		archmage_skill_cooldowns[skill_key] = 0.0
	archmage_element_orbs.clear()
	archmage_orbit_sprites.clear()
	archmage_orbit_angle = 0.0
	archmage_chain_dagger_active = false
	archmage_casting_sequence = false
	var profile_rogue_slash = profile.get("rogue_slash_skill", {})
	rogue_slash_config = (
		profile_rogue_slash.duplicate(true)
		if typeof(profile_rogue_slash) == TYPE_DICTIONARY
		else {}
	)
	rogue_slash_cooldown_timer = maxf(
		float(rogue_slash_config.get("initial_cooldown", 0.0)),
		0.0
	)
	rogue_slash_duration_timer = 0.0
	rogue_slash_tick_timer = 0.0
	rogue_slash_active = false
	rogue_assassination_active = false
	rogue_assassination_hits_left = 0
	rogue_assassination_timer = 0.0
	rogue_assassination_cast_timer = 0.0
	rogue_combo_index = 0
	rogue_combo_damage_multiplier = 1.0
	rogue_combo_recovery_multiplier = 1.0
	rogue_bonus_combo_hits = 0
	rogue_slash_shield_ratio_bonus = 0.0
	rogue_assassination_hit_bonus = 0
	rogue_execute_threshold_bonus = 0.0
	rogue_lifesteal_ratio = 0.0
	rogue_lifesteal_buffer = 0.0
	rogue_combo_direction = Vector2.RIGHT
	rogue_attack_collision_ignore_timer = 0.0
	rogue_saved_collision_mask = -1
	fighter_guard_active = false
	fighter_guard_duration_timer = 0.0
	fighter_guard_stored_damage = 0.0
	fighter_guard_charge_seconds = 20.0
	fighter_guard_shield_ratio_bonus = 0.0
	fighter_guard_release_ratio_bonus = 0.0
	fighter_guard_damage_reduction_bonus = 0.0
	fighter_guard_move_multiplier_bonus = 0.0
	fighter_reflect_ratio = 0.0
	fighter_basic_damage_multiplier = 1.0
	fighter_slash_half_width_bonus = 0.0
	fighter_thrust_length_bonus = 0.0
	fighter_thrust_damage_bonus = 0.0
	fighter_slash_mastery_stacks = 0
	fighter_slash_bonus_hits_remaining = 0
	fighter_slash_combo_timer = 0.0
	fighter_slash_combo_direction = Vector2.ZERO
	fighter_slash_combo_swing_index = 0
	var profile_ultimate = profile.get("ultimate", {})
	ultimate_config = (
		profile_ultimate.duplicate(true)
		if typeof(profile_ultimate) == TYPE_DICTIONARY
		else {}
	)
	fighter_guard_charge_seconds = maxf(
		float(ultimate_config.get("charge_seconds", fighter_guard_charge_seconds)),
		1.0
	)
	ultimate_charge = 0.0
	ultimate_cooldown_timer = maxf(
		float(ultimate_config.get("initial_cooldown", 0.0)),
		0.0
	)
	var profile_shield = profile.get("shield_skill", {})
	shield_skill_config = (
		profile_shield.duplicate(true)
		if typeof(profile_shield) == TYPE_DICTIONARY
		else {}
	)
	shield_cooldown_timer = maxf(
		float(shield_skill_config.get("initial_cooldown", 0.0)),
		0.0
	)
	shield_duration_timer = 0.0
	shield_hp = 0.0
	shield_max_hp = 0.0

	var profile_channel = profile.get("channel_skill", {})
	channel_skill_config = (
		profile_channel.duplicate(true)
		if typeof(profile_channel) == TYPE_DICTIONARY
		else {}
	)
	channel_cooldown_timer = maxf(
		float(channel_skill_config.get("initial_cooldown", 0.0)),
		0.0
	)
	channel_duration_timer = 0.0
	channel_tick_timer = 0.0
	channeling = false

	augment_pool_ids.clear()
	for raw_augment_id in profile.get("augment_pool_ids", []):
		var augment_id := String(raw_augment_id)
		if not augment_id.is_empty() and augment_id not in augment_pool_ids:
			augment_pool_ids.append(augment_id)

	var profile_ai_settings: Dictionary = profile.get("ai_settings", {})
	if not profile_ai_settings.is_empty():
		ai_settings = profile_ai_settings.duplicate(true)

	max_hp = int(profile.get("max_hp", max_hp))
	move_speed = float(profile.get("move_speed", move_speed))
	attack_damage = int(profile.get("attack_damage", attack_damage))
	attack_range = float(profile.get("attack_range", attack_range))
	attack_cooldown = float(profile.get("attack_cooldown", attack_cooldown))
	projectile_speed = float(profile.get("projectile_speed", projectile_speed))
	exp_pickup_radius = float(profile.get("exp_pickup_radius", exp_pickup_radius))
	exp_gain_multiplier = 1.0
	heal_item_multiplier = 1.0
	ai_sense_radius = float(profile.get("ai_sense_radius", ai_sense_radius))
	kite_distance = float(profile.get("kite_distance", kite_distance))
	facing_switch_delay = maxf(
		float(profile.get("facing_switch_delay", facing_switch_delay)),
		0.0
	)
	facing_min_horizontal_speed = maxf(
		float(profile.get("facing_min_horizontal_speed", facing_min_horizontal_speed)),
		0.0
	)
	invulnerability_duration = maxf(
		float(profile.get("invulnerability_duration", invulnerability_duration)),
		0.0
	)

func configure_battlefield(size: Vector2) -> void:
	battlefield_size = Vector2(
		maxf(size.x, 1080.0),
		maxf(size.y, 1920.0)
	)

func _ready() -> void:
	add_to_group("hero")
	_attach_status_effect_visual("slow")
	_apply_camera_limits()
	_apply_profile_visual()
	_apply_stage1_shield_visual()
	_apply_stage1_channel_visual()
	_apply_stage2_rogue_effect_visuals()
	_apply_stage3_fighter_effect_visuals()
	_apply_stage4_gunner_effect_visuals()
	if (
		not rogue_attack_effect.animation_finished.is_connected(
			Callable(self, "_on_rogue_attack_effect_finished")
		)
	):
		rogue_attack_effect.animation_finished.connect(
			Callable(self, "_on_rogue_attack_effect_finished")
		)
	if (
		not channel_effect.animation_finished.is_connected(
			Callable(self, "_on_fighter_guard_release_effect_finished")
		)
	):
		channel_effect.animation_finished.connect(
			Callable(self, "_on_fighter_guard_release_effect_finished")
		)
	current_hp = max_hp
	exp_to_next_level = _required_exp_for_level(level)
	strafe_sign = -1.0 if randf() < 0.5 else 1.0
	_pick_new_wander_target()
	_refresh_ai_observation()
	health_changed.emit(current_hp, max_hp)
	progression_changed.emit(level, current_exp, exp_to_next_level)
	queue_redraw()

func _attach_status_effect_visual(effect_type: String) -> void:
	var effect := COMBAT_STATUS_EFFECT_VISUAL.new()
	add_child(effect)
	effect.setup(self, effect_type)


func _physics_process(delta: float) -> void:
	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	_update_combat_reposition(delta)

	if hero_archetype == "rogue_combo":
		_physics_process_rogue(delta)
		return

	if hero_archetype == "sword_shield":
		_physics_process_fighter(delta)
		return

	if hero_archetype == "pistol_gunner":
		_physics_process_gunner(delta)
		return

	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()

	ai_observation_timer = maxf(ai_observation_timer - delta, 0.0)
	if ai_observation_timer <= 0.0:
		_refresh_ai_observation()

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	ultimate_flash_timer = maxf(ultimate_flash_timer - delta, 0.0)
	_update_invulnerability(delta)
	_update_ultimate(delta)
	_update_shield_skill(delta)
	_update_channel_skill(delta)
	if hero_archetype == "archmage_elementalist":
		_update_archmage_skill_runtime(delta)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if channeling:
		velocity = Vector2.ZERO
		return

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)

	if not is_instance_valid(target) or target.is_queued_for_deletion() or retarget_timer <= 0.0:
		target = _find_nearest_monster()
		retarget_timer = 0.12

	if not is_instance_valid(target):
		_move_without_monsters()
		_update_stage1_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_move_direction(target, distance)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	if hero_archetype == "archmage_elementalist":
		move_direction = _apply_archmage_boundary_steering(move_direction)
	velocity = move_direction * move_speed * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

	if distance <= attack_range and attack_timer <= 0.0:
		_fire_projectile(target)

	_update_stage1_pose_visual(delta)

func _physics_process_gunner(delta: float) -> void:
	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()

	ai_observation_timer = maxf(ai_observation_timer - delta, 0.0)
	if ai_observation_timer <= 0.0:
		_refresh_ai_observation()

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	gunner_backstep_cooldown = maxf(gunner_backstep_cooldown - delta, 0.0)
	gunner_cylinder_cooldown = maxf(gunner_cylinder_cooldown - delta, 0.0)
	gunner_cylinder_decision_timer = maxf(gunner_cylinder_decision_timer - delta, 0.0)
	gunner_deadeye_cooldown = maxf(gunner_deadeye_cooldown - delta, 0.0)
	_update_invulnerability(delta)
	_update_gunner_collision_ignore(delta)

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0

	if gunner_deadeye_active:
		_update_gunner_deadeye(delta)
		_update_gunner_pose_visual(delta)
		return

	if gunner_reloading:
		gunner_reload_timer = maxf(gunner_reload_timer - delta, 0.0)
		queue_redraw()
		if gunner_cylinder_decision_timer <= 0.0:
			gunner_cylinder_decision_timer = 0.35
			if _gunner_should_use_cylinder():
				_use_gunner_cylinder_strike()
		if gunner_reload_timer <= 0.0:
			_finish_gunner_reload()

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)
	if not is_instance_valid(target) or target.is_queued_for_deletion() or retarget_timer <= 0.0:
		target = _find_nearest_monster()
		retarget_timer = 0.10

	if not is_instance_valid(target):
		_move_without_monsters()
		_update_gunner_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_move_direction(target, distance)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	move_direction = _apply_gunner_boundary_steering(move_direction)
	var gunner_speed_scale := 1.0 + (gunner_reload_move_speed_bonus if gunner_reloading else 0.0)
	velocity = move_direction * move_speed * move_multiplier * gunner_speed_scale
	move_and_slide()
	_clamp_to_battlefield()

	if _gunner_should_start_deadeye():
		_start_gunner_deadeye()
		return

	if not gunner_reloading and distance <= attack_range and attack_timer <= 0.0:
		_gunner_attack(target)

	_update_gunner_pose_visual(delta)


func _update_gunner_pose_visual(delta: float) -> void:
	if hero_archetype != "pistol_gunner" or not hero_sprite.visible or is_dying:
		return
	if hit_pose_timer > 0.0:
		return
	# 공격 중에는 발사 방향을 유지한다. 그 외에는 실제 이동 방향을 따른다.
	if attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)
	var speed := velocity.length()
	if speed > 4.0:
		var movement_ratio := speed / maxf(move_speed, 1.0)
		var animation_speed := clampf(movement_ratio, 0.78, 1.45)
		_play_stage1_animation("move", animation_speed)
	else:
		_play_stage1_animation("idle", 1.0)


func _apply_archmage_boundary_steering(base_direction: Vector2) -> Vector2:
	var center_direction := global_position.direction_to(battlefield_size * 0.5)

	var soft_margin := 440.0
	var hard_margin := 150.0
	var left_space := global_position.x - FIELD_MARGIN
	var right_space := battlefield_size.x - FIELD_MARGIN - global_position.x
	var top_space := global_position.y - FIELD_MARGIN
	var bottom_space := battlefield_size.y - FIELD_MARGIN - global_position.y

	var inward := Vector2.ZERO
	if left_space < soft_margin:
		inward.x += 1.0 - clampf(left_space / soft_margin, 0.0, 1.0)
	if right_space < soft_margin:
		inward.x -= 1.0 - clampf(right_space / soft_margin, 0.0, 1.0)
	if top_space < soft_margin:
		inward.y += 1.0 - clampf(top_space / soft_margin, 0.0, 1.0)
	if bottom_space < soft_margin:
		inward.y -= 1.0 - clampf(bottom_space / soft_margin, 0.0, 1.0)

	var near_horizontal_edge := minf(left_space, right_space) < hard_margin
	var near_vertical_edge := minf(top_space, bottom_space) < hard_margin
	if near_horizontal_edge and near_vertical_edge:
		var corner_escape := center_direction * 2.8
		if inward.length_squared() > 0.001:
			corner_escape += inward.normalized() * 2.2
		if corner_escape.length_squared() > 0.01:
			return corner_escape.normalized()

	# Do not invent movement while the archmage is comfortably inside the field.
	# This lets the new combat spacing logic actually stand and cast.
	if inward.length_squared() <= 0.001:
		return (
			base_direction.normalized()
			if base_direction.length_squared() > 0.01
			else Vector2.ZERO
		)

	if base_direction.length_squared() <= 0.01:
		return inward.normalized()

	var edge_pressure := clampf(inward.length(), 0.0, 1.5)
	var inward_weight := lerpf(0.95, 2.8, clampf(edge_pressure, 0.0, 1.0))
	var desired := base_direction.normalized() + inward.normalized() * inward_weight
	if desired.length_squared() <= 0.01:
		return center_direction.normalized()
	return desired.normalized()

func _apply_gunner_boundary_steering(base_direction: Vector2) -> Vector2:
	if base_direction.length_squared() <= 0.01:
		return Vector2.ZERO

	# 회복 아이템/상자를 직접 향하는 동안에는 목적지 접근을 방해하지 않는다.
	if is_instance_valid(heal_item_target) or is_instance_valid(chest_target):
		return base_direction.normalized()

	var soft_margin := 360.0
	var left_space := global_position.x - FIELD_MARGIN
	var right_space := battlefield_size.x - FIELD_MARGIN - global_position.x
	var top_space := global_position.y - FIELD_MARGIN
	var bottom_space := battlefield_size.y - FIELD_MARGIN - global_position.y

	var inward := Vector2.ZERO
	if left_space < soft_margin:
		inward.x += 1.0 - clampf(left_space / soft_margin, 0.0, 1.0)
	if right_space < soft_margin:
		inward.x -= 1.0 - clampf(right_space / soft_margin, 0.0, 1.0)
	if top_space < soft_margin:
		inward.y += 1.0 - clampf(top_space / soft_margin, 0.0, 1.0)
	if bottom_space < soft_margin:
		inward.y -= 1.0 - clampf(bottom_space / soft_margin, 0.0, 1.0)

	if inward.length_squared() <= 0.001:
		return base_direction.normalized()

	var pressure := clampf(inward.length(), 0.0, 1.35)
	var inward_weight := lerpf(0.75, 2.35, clampf(pressure, 0.0, 1.0))
	var desired := base_direction.normalized() + inward.normalized() * inward_weight
	if desired.length_squared() <= 0.01:
		return inward.normalized()
	return desired.normalized()


func _gunner_attack(current_target: Node2D) -> void:
	if gunner_reloading or gunner_ammo <= 0 or not is_instance_valid(current_target):
		return
	var direction := global_position.direction_to(current_target.global_position).normalized()
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	gunner_ammo -= 1
	_gunner_register_ammo_consumed(1)
	if gunner_ammo <= 0:
		_refresh_gunner_empty_magazine_shield()
	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.30
	_face_attack_direction(direction.x)
	_restart_stage1_animation("attack", 1.0)
	_play_gunner_muzzle_flash(direction)
	_spawn_gunner_bullet(direction)
	var random_angle := deg_to_rad(randf_range(-float(gunner_config.get("random_shot_angle_degrees", 28.0)), float(gunner_config.get("random_shot_angle_degrees", 28.0))))
	_spawn_gunner_bullet(direction.rotated(random_angle))
	if randf() <= clampf(float(gunner_config.get("quickdraw_chance", 0.03)), 0.0, 1.0):
		gunner_ammo = gunner_magazine_size
		gunner_reloading = false
	elif gunner_ammo <= 0:
		_start_gunner_reload()
	queue_redraw()


func _spawn_gunner_bullet(direction: Vector2, is_deadeye_shot: bool = false) -> void:
	var headshot := randf() <= clampf(float(gunner_config.get("headshot_chance", 0.10)), 0.0, 1.0)
	var damage := maxi(
		1,
		int(round(float(attack_damage) * _gunner_powder_damage_multiplier()))
	)
	if headshot:
		damage = maxi(1, int(round(float(damage) * float(gunner_config.get("headshot_multiplier", 1.20)))))
	var projectile := GUNNER_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction.normalized() * 42.0
	projectile.call(
		"setup",
		direction,
		damage,
		projectile_speed,
		attack_range,
		headshot,
		gunner_ricochet_stacks,
		is_deadeye_shot
	)


func _spawn_gunner_bullet_from(origin: Vector2, direction: Vector2) -> void:
	var headshot := randf() <= clampf(float(gunner_config.get("headshot_chance", 0.10)), 0.0, 1.0)
	var damage := maxi(
		1,
		int(round(float(attack_damage) * _gunner_powder_damage_multiplier()))
	)
	if headshot:
		damage = maxi(1, int(round(float(damage) * float(gunner_config.get("headshot_multiplier", 1.20)))))
	var projectile := GUNNER_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = origin + direction.normalized() * 42.0
	projectile.call(
		"setup",
		direction,
		damage,
		projectile_speed,
		attack_range,
		headshot,
		gunner_ricochet_stacks,
		false
	)


func _refresh_gunner_empty_magazine_shield() -> void:
	var shield_ratio := clampf(
		float(gunner_config.get("empty_mag_shield_ratio", 0.10)),
		0.0,
		1.0
	)
	var refreshed_shield := float(max_hp) * shield_ratio
	if refreshed_shield <= 0.0:
		return

	# 갱신형: 기존 실드에 더하지 않고 항상 새 10% 값으로 덮어쓴다.
	shield_max_hp = refreshed_shield
	shield_hp = refreshed_shield
	queue_redraw()


func _gunner_register_ammo_consumed(amount: int) -> void:
	if amount <= 0 or gunner_powder_bonus_per_ammo <= 0.0:
		return
	gunner_powder_consumed_stacks += amount


func _gunner_powder_damage_multiplier() -> float:
	if gunner_powder_bonus_per_ammo <= 0.0 or gunner_powder_consumed_stacks <= 0:
		return 1.0
	return 1.0 + gunner_powder_bonus_per_ammo * float(gunner_powder_consumed_stacks)


func _start_gunner_reload() -> void:
	gunner_powder_consumed_stacks = 0
	gunner_reloading = true
	gunner_reload_timer = maxf(float(gunner_config.get("reload_seconds", 2.4)), 0.1)
	attack_timer = maxf(attack_timer, gunner_reload_timer)
	queue_redraw()


func _finish_gunner_reload() -> void:
	gunner_reloading = false
	gunner_reload_timer = 0.0
	gunner_ammo = gunner_magazine_size
	attack_timer = 0.05
	queue_redraw()


func _gunner_surround_pressure() -> float:
	var radius := maxf(float(gunner_config.get("surrounded_radius", 220.0)), 1.0)
	var required := maxi(int(gunner_config.get("surrounded_enemy_count", 4)), 1)
	var nearby := _count_monsters_near(global_position, radius)
	return clampf(float(nearby) / float(required), 0.0, 1.5)


func _gunner_should_backstep_on_hit() -> bool:
	if gunner_backstep_cooldown > 0.0:
		return false
	var pressure := _gunner_surround_pressure()
	var base_chance := clampf(float(gunner_config.get("backstep_base_chance", 0.30)), 0.0, 1.0)
	var surround_bonus := maxf(float(gunner_config.get("surrounded_backstep_bonus", 0.55)), 0.0)
	var chance := base_chance + minf(pressure, 1.0) * surround_bonus
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	if hp_ratio <= 0.40:
		chance += gunner_low_hp_backstep_bonus
	chance = clampf(chance, 0.0, 1.0)
	return randf() <= chance


func _gunner_should_use_cylinder() -> bool:
	if not gunner_reloading or gunner_cylinder_cooldown > 0.0:
		return false
	var nearby := _count_monsters_near(
		global_position,
		maxf(float(gunner_config.get("cylinder_radius", 190.0)), 1.0)
	)
	var base_required := maxi(int(gunner_config.get("cylinder_base_enemy_count", 2)), 1)
	var surrounded_required := maxi(
		int(gunner_config.get("cylinder_surrounded_enemy_count", 4)),
		base_required
	)
	if nearby >= surrounded_required:
		return true
	if nearby < base_required:
		return false
	# 포위 상태에 가까울수록 장전 중 방어 행동의 우선도가 올라간다.
	var weight := clampf(
		float(nearby - base_required + 1)
		/ float(maxi(surrounded_required - base_required + 1, 1)),
		0.0,
		1.0
	)
	return randf() <= 0.30 + weight * 0.45


func _start_gunner_backstep() -> void:
	gunner_backstep_cooldown = maxf(float(gunner_config.get("backstep_cooldown", 7.0)), 0.1)
	invulnerability_timer = maxf(invulnerability_timer, float(gunner_config.get("backstep_invulnerability", 0.75)))
	var escape_direction := _find_gunner_escape_direction()
	var start_position := global_position
	var distance := maxf(float(gunner_config.get("backstep_distance", 260.0)), 0.0)
	_spawn_gunner_afterimage(start_position, 0.88, 0.52, 1.10)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.25, 0.72, 0.46, 1.08)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.50, 0.58, 0.40, 1.06)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.75, 0.42, 0.34, 1.04)
	if gunner_afterimage_shot_stacks > 0:
		var counter_direction := -escape_direction
		for shot_index in range(gunner_afterimage_shot_stacks * 2):
			var spread := deg_to_rad(randf_range(-10.0, 10.0))
			_spawn_gunner_bullet_from(start_position, counter_direction.rotated(spread))
	global_position += escape_direction * distance
	_clamp_to_battlefield()
	if gunner_saved_collision_mask < 0:
		gunner_saved_collision_mask = collision_mask
	collision_mask = 0
	gunner_collision_ignore_timer = 0.22


func _spawn_gunner_afterimage(
	world_position: Vector2,
	alpha: float,
	fade_time: float,
	scale_multiplier: float = 1.0
) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(hero_sprite.animation):
		return
	var frame_texture := hero_sprite.sprite_frames.get_frame_texture(
		hero_sprite.animation,
		hero_sprite.frame
	)
	if frame_texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = frame_texture
	ghost.centered = hero_sprite.centered
	ghost.flip_h = hero_sprite.flip_h
	ghost.flip_v = hero_sprite.flip_v
	ghost.offset = hero_sprite.offset
	ghost.scale = hero_sprite.scale * maxf(scale_multiplier, 1.0)
	ghost.rotation = hero_sprite.rotation
	ghost.global_position = world_position
	ghost.z_index = hero_sprite.z_index
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.82, 0.94, 1.0, clampf(alpha, 0.08, 0.95))
	get_parent().add_child(ghost)

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, maxf(fade_time, 0.05))
	tween.tween_property(
		ghost,
		"scale",
		ghost.scale * 1.04,
		maxf(fade_time, 0.05)
	)
	tween.finished.connect(Callable(ghost, "queue_free"))


func _find_gunner_escape_direction() -> Vector2:
	var best := Vector2.RIGHT
	var best_score := INF
	var sample_count := 32
	var dash_distance := maxf(float(gunner_config.get("backstep_distance", 260.0)), 1.0)
	var threat_radius := maxf(dash_distance + 360.0, 560.0)
	var repulsion := Vector2.ZERO
	var monster_positions: Array[Vector2] = []

	for node in _get_monster_nodes_near(global_position, threat_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var monster_position := monster.global_position
		monster_positions.append(monster_position)

		var offset := monster_position - global_position
		var distance := offset.length()
		if distance <= 0.001 or distance > threat_radius:
			continue
		var proximity := 1.0 - clampf(distance / threat_radius, 0.0, 1.0)
		repulsion -= offset.normalized() * (0.35 + proximity * proximity * 2.65)

	var preferred_away := (
		repulsion.normalized()
		if repulsion.length_squared() > 0.001
		else Vector2.ZERO
	)

	for i in range(sample_count):
		var dir := Vector2.from_angle(TAU * float(i) / float(sample_count))
		var raw_endpoint := global_position + dir * dash_distance
		var endpoint := Vector2(
			clampf(raw_endpoint.x, FIELD_MARGIN, battlefield_size.x - FIELD_MARGIN),
			clampf(raw_endpoint.y, FIELD_MARGIN, battlefield_size.y - FIELD_MARGIN)
		)
		var actual_dash_distance := global_position.distance_to(endpoint)
		if actual_dash_distance <= 1.0:
			continue

		var endpoint_danger := 0.0
		var endpoint_close_count := 0
		var endpoint_near_count := 0
		var corridor_density := 0.0
		var corridor_count := 0
		var side := Vector2(-dir.y, dir.x)
		var danger_radius := 320.0

		for monster_position in monster_positions:
			var endpoint_distance := endpoint.distance_to(monster_position)
			if endpoint_distance < danger_radius:
				endpoint_danger += 1.0 - clampf(
					endpoint_distance / danger_radius,
					0.0,
					1.0
				)
			if endpoint_distance <= 115.0:
				endpoint_close_count += 1
			if endpoint_distance <= 220.0:
				endpoint_near_count += 1

			var offset := monster_position - global_position
			var forward := offset.dot(dir)
			if forward <= 0.0 or forward > actual_dash_distance + 120.0:
				continue
			var lateral := absf(offset.dot(side))
			if lateral > 185.0:
				continue

			corridor_count += 1
			var forward_weight := 1.0 - clampf(
				forward / maxf(actual_dash_distance + 120.0, 1.0),
				0.0,
				1.0
			) * 0.35
			var center_weight := 1.0 - clampf(lateral / 185.0, 0.0, 1.0) * 0.60
			corridor_density += maxf(forward_weight * center_weight, 0.15)

		var boundary_loss := clampf(
			(dash_distance - actual_dash_distance) / dash_distance,
			0.0,
			1.0
		)
		var away_alignment_penalty := 0.0
		if preferred_away.length_squared() > 0.001:
			away_alignment_penalty = (1.0 - dir.dot(preferred_away)) * 7.0

		var score := (
			float(endpoint_close_count) * 90.0
			+ float(endpoint_near_count) * 16.0
			+ float(corridor_count) * 11.0
			+ corridor_density * 13.0
			+ endpoint_danger * 18.0
			+ away_alignment_penalty
			+ boundary_loss * 28.0
		)
		if score < best_score:
			best_score = score
			best = global_position.direction_to(endpoint)

	return best.normalized()

func _update_gunner_collision_ignore(delta: float) -> void:
	if gunner_collision_ignore_timer <= 0.0:
		return
	gunner_collision_ignore_timer = maxf(gunner_collision_ignore_timer - delta, 0.0)
	if gunner_collision_ignore_timer <= 0.0 and gunner_saved_collision_mask >= 0:
		collision_mask = gunner_saved_collision_mask
		gunner_saved_collision_mask = -1


func _use_gunner_cylinder_strike() -> void:
	gunner_cylinder_cooldown = maxf(float(gunner_config.get("cylinder_cooldown", 10.0)), 0.1)
	_play_gunner_cylinder_dust()
	var radius := maxf(float(gunner_config.get("cylinder_radius", 190.0)), 1.0)
	var knockback := maxf(float(gunner_config.get("cylinder_knockback", 145.0)), 0.0)
	var slow_multiplier := clampf(float(gunner_config.get("cylinder_slow_multiplier", 0.50)), 0.1, 1.0)
	var slow_duration := maxf(float(gunner_config.get("cylinder_slow_duration", 2.0)), 0.1)
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or global_position.distance_to(monster.global_position) > radius:
			continue
		var dir := global_position.direction_to(monster.global_position)
		if dir.length_squared() <= 0.0:
			dir = Vector2.RIGHT
		monster.global_position += dir.normalized() * knockback
		var damage_ratio := maxf(float(gunner_config.get("cylinder_damage_ratio", 0.0)), 0.0)
		if damage_ratio > 0.0 and monster.has_method("take_damage"):
			monster.call("take_damage", maxi(1, int(round(float(attack_damage) * damage_ratio))))
		monster.set_meta("gunner_slow_multiplier", slow_multiplier)
		monster.set_meta("gunner_slow_until", Time.get_ticks_msec() + int(slow_duration * 1000.0))


func _gunner_deadeye_best_direction() -> Dictionary:
	var sample_count := maxi(int(gunner_config.get("deadeye_cluster_samples", 36)), 8)
	var max_range := maxf(float(gunner_config.get("deadeye_cluster_range", 620.0)), 1.0)
	var half_width := maxf(float(gunner_config.get("deadeye_corridor_half_width", 105.0)), 1.0)
	var best_direction := Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	var best_score := 0.0
	var best_hits := 0
	var monster_offsets: Array[Vector2] = []

	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var offset := monster.global_position - global_position
		if offset.length_squared() <= max_range * max_range:
			monster_offsets.append(offset)

	for index in range(sample_count):
		var direction := Vector2.from_angle(TAU * float(index) / float(sample_count))
		var side := Vector2(-direction.y, direction.x)
		var score := 0.0
		var hits := 0
		for offset in monster_offsets:
			var forward := offset.dot(direction)
			if forward <= 0.0 or forward > max_range:
				continue
			var lateral := absf(offset.dot(side))
			if lateral > half_width:
				continue
			hits += 1
			var distance_weight := 1.0 - clampf(forward / max_range, 0.0, 1.0) * 0.35
			var center_weight := 1.0 - clampf(lateral / half_width, 0.0, 1.0) * 0.45
			score += maxf(distance_weight * center_weight, 0.1)
		if score > best_score:
			best_score = score
			best_hits = hits
			best_direction = direction

	return {
		"direction": best_direction.normalized(),
		"score": best_score,
		"hits": best_hits,
	}

func _gunner_should_start_deadeye() -> bool:
	if gunner_reloading or gunner_deadeye_cooldown > 0.0:
		return false
	var min_ammo := maxi(int(gunner_config.get("deadeye_min_ammo", 3)), 1)
	if gunner_ammo < min_ammo:
		return false

	var aim := _gunner_deadeye_best_direction()
	var score := float(aim.get("score", 0.0))
	var min_score := maxf(float(gunner_config.get("deadeye_min_cluster_score", 3.0)), 0.0)
	if score < min_score:
		return false
	var force_score := maxf(float(gunner_config.get("deadeye_force_cluster_score", 5.5)), min_score)
	if score >= force_score:
		return true

	# 밀집도가 높을수록 발동 확률 증가. 최소 문턱에서는 낮게, 강한 밀집에서는 거의 확정.
	var t := clampf((score - min_score) / maxf(force_score - min_score, 0.001), 0.0, 1.0)
	return randf() <= lerpf(0.28, 0.82, t)


func _start_gunner_deadeye() -> void:
	if gunner_ammo <= 0:
		return
	var aim := _gunner_deadeye_best_direction()
	var aim_direction: Vector2 = aim.get(
		"direction",
		Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	)
	if aim_direction.length_squared() <= 0.0:
		aim_direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	gunner_deadeye_cooldown = maxf(float(gunner_config.get("deadeye_cooldown", 20.0)), 0.1)
	gunner_deadeye_active = true
	var deadeye_consumed_ammo := gunner_ammo
	gunner_deadeye_shots_left = maxi(
		1,
		int(round(float(deadeye_consumed_ammo) * gunner_deadeye_shot_multiplier))
	)
	_gunner_register_ammo_consumed(deadeye_consumed_ammo)
	gunner_ammo = 0
	_refresh_gunner_empty_magazine_shield()
	gunner_deadeye_shot_timer = 0.0
	gunner_deadeye_direction = aim_direction.normalized()
	_face_attack_direction(gunner_deadeye_direction.x)
	queue_redraw()


func _update_gunner_deadeye(delta: float) -> void:
	var speed_bonus := maxf(float(gunner_config.get("deadeye_move_speed_multiplier", 1.30)), 1.0)
	var deadeye_move_direction := _apply_gunner_boundary_steering(gunner_deadeye_direction)
	velocity = deadeye_move_direction * move_speed * move_multiplier * speed_bonus
	move_and_slide()
	_clamp_to_battlefield()
	gunner_deadeye_shot_timer = maxf(gunner_deadeye_shot_timer - delta, 0.0)
	if gunner_deadeye_shot_timer <= 0.0 and gunner_deadeye_shots_left > 0:
		_play_gunner_muzzle_flash(gunner_deadeye_direction)
		_spawn_gunner_bullet(gunner_deadeye_direction, true)
		gunner_deadeye_shots_left -= 1
		gunner_deadeye_shot_timer = maxf(float(gunner_config.get("deadeye_shot_interval", 0.08)), 0.03)
	if gunner_deadeye_shots_left <= 0:
		gunner_deadeye_active = false
		_start_gunner_reload()


func _count_monsters_near(origin: Vector2, radius: float) -> int:
	var count := 0
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster != null and origin.distance_squared_to(monster.global_position) <= radius_sq:
			count += 1
	return count

func _physics_process_rogue(delta: float) -> void:
	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()

	ai_observation_timer = maxf(ai_observation_timer - delta, 0.0)
	if ai_observation_timer <= 0.0:
		_refresh_ai_observation()

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	ultimate_flash_timer = maxf(ultimate_flash_timer - delta, 0.0)
	ultimate_cooldown_timer = maxf(
		ultimate_cooldown_timer - delta,
		0.0
	)
	rogue_slash_cooldown_timer = maxf(
		rogue_slash_cooldown_timer - delta,
		0.0
	)
	_update_rogue_attack_collision_ignore(delta)

	_update_invulnerability(delta)
	_update_rogue_slash(delta)

	var passive_charge := maxf(
		float(ultimate_config.get("charge_per_second", 0.0)),
		0.0
	)
	if passive_charge > 0.0 and not rogue_assassination_active:
		_add_ultimate_charge(passive_charge * delta)

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if rogue_assassination_active:
		_update_rogue_assassination(delta)
		return

	if _rogue_can_start_assassination():
		_start_rogue_assassination()
		return

	if (
		not rogue_slash_active
		and rogue_slash_cooldown_timer <= 0.0
		and _rogue_should_use_slash()
	):
		_start_rogue_slash()

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)

	if (
		not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or retarget_timer <= 0.0
	):
		target = _find_nearest_monster()
		retarget_timer = 0.10

	if not is_instance_valid(target):
		rogue_combo_index = 0
		rogue_combo_direction = Vector2.RIGHT
		_move_without_monsters()
		_update_rogue_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var speed_scale := 1.0
	if rogue_slash_active:
		speed_scale = clampf(
			float(
				rogue_slash_config.get(
					"move_speed_multiplier",
					0.48
				)
			),
			0.1,
			1.0
		)

	var move_direction := _choose_melee_spacing_direction(
		target,
		distance,
		0.88
	)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	if move_direction.length_squared() > 0.01:
		velocity = (
			move_direction
			* move_speed
			* move_multiplier
			* speed_scale
		)
		move_and_slide()
		_clamp_to_battlefield()
	else:
		velocity = Vector2.ZERO

	if (
		not rogue_slash_active
		and distance <= attack_range
		and attack_timer <= 0.0
	):
		_rogue_combo_attack(target)

	_update_rogue_pose_visual(delta)

func _rogue_combo_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var target_direction := global_position.direction_to(
		current_target.global_position
	)
	if target_direction.length_squared() <= 0.0:
		target_direction = (
			Vector2.LEFT
			if hero_sprite.flip_h
			else Vector2.RIGHT
		)

	if rogue_combo_index == 0:
		rogue_combo_direction = target_direction.normalized()
	elif rogue_combo_direction.length_squared() <= 0.0:
		rogue_combo_direction = target_direction.normalized()

	var direction := rogue_combo_direction.normalized()
	_face_attack_direction(direction.x)

	var lunge_distance := maxf(
		float(rogue_combo_config.get("lunge_distance", 85.0)),
		0.0
	)
	var target_distance := global_position.distance_to(
		current_target.global_position
	)
	var lunge_stop_distance := maxf(
		float(rogue_combo_config.get("lunge_stop_distance", 26.0)),
		0.0
	)
	lunge_distance = minf(
		lunge_distance,
		maxf(target_distance - lunge_stop_distance, 0.0)
	)
	var lunge_start := global_position
	global_position += direction * lunge_distance
	_clamp_to_battlefield()
	var lunge_end := global_position

	_start_rogue_attack_collision_ignore(
		maxf(
			float(
				rogue_combo_config.get(
					"collision_ignore_duration",
					0.28
				)
			),
			0.0
		)
	)

	var damage_multipliers = rogue_combo_config.get(
		"damage_multipliers",
		[0.75, 0.85, 1.10]
	)
	var damage_ratio := 1.0
	if (
		typeof(damage_multipliers) == TYPE_ARRAY
		and not damage_multipliers.is_empty()
	):
		var damage_index := mini(
			rogue_combo_index,
			damage_multipliers.size() - 1
		)
		damage_ratio = float(damage_multipliers[damage_index])

	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* damage_ratio
			* rogue_combo_damage_multiplier
		))
	)

	var aoe_radii = rogue_combo_config.get(
		"aoe_radii",
		[95.0, 110.0, 130.0]
	)
	var aoe_offsets = rogue_combo_config.get(
		"aoe_forward_offsets",
		[48.0, 54.0, 62.0]
	)
	var aoe_radius := 95.0
	var aoe_offset := 48.0
	if typeof(aoe_radii) == TYPE_ARRAY and not aoe_radii.is_empty():
		var radius_index := mini(
			rogue_combo_index,
			aoe_radii.size() - 1
		)
		aoe_radius = float(aoe_radii[radius_index])
	if typeof(aoe_offsets) == TYPE_ARRAY and not aoe_offsets.is_empty():
		var offset_index := mini(
			rogue_combo_index,
			aoe_offsets.size() - 1
		)
		aoe_offset = float(aoe_offsets[offset_index])

	var corridor_end := lunge_end + direction * aoe_offset
	var corridor_vector := corridor_end - lunge_start
	var corridor_length_squared := corridor_vector.length_squared()
	var main_id := current_target.get_instance_id()
	var knockback_distance := float(
		rogue_combo_config.get(
			"knockback_distance",
			30.0
		)
	)
	var secondary_lifesteal := clampf(
		float(
			rogue_combo_config.get(
				"secondary_lifesteal_efficiency",
				0.50
			)
		),
		0.0,
		1.0
	)

	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var nearest_point := lunge_start
		if corridor_length_squared > 0.001:
			var projection := clampf(
				(
					(monster.global_position - lunge_start)
					.dot(corridor_vector)
					/ corridor_length_squared
				),
				0.0,
				1.0
			)
			nearest_point = (
				lunge_start
				+ corridor_vector * projection
			)
		if (
			nearest_point.distance_squared_to(monster.global_position)
			> aoe_radius * aoe_radius
		):
			continue

		var is_main_target := monster.get_instance_id() == main_id
		var actual_damage := _rogue_damage_target(
			monster,
			damage,
			1.0 if is_main_target else secondary_lifesteal
		)
		if actual_damage <= 0 or not is_instance_valid(monster):
			continue

		_rogue_apply_knockback(
			monster,
			direction,
			knockback_distance
		)

	_damage_treasure_chests(corridor_end, aoe_radius, damage)
	attack_pose_timer = 0.26
	_restart_stage1_animation("attack", 1.0)
	_play_rogue_effect(
		rogue_attack_effect,
		"stab",
		direction
	)

	_add_ultimate_charge(
		float(ultimate_config.get("charge_on_attack", 0.0))
	)

	var combo_length := 3 + maxi(rogue_bonus_combo_hits, 0)
	var hit_intervals = rogue_combo_config.get(
		"hit_intervals",
		[0.24, 0.26, 0.28, 0.30]
	)
	var interval := attack_cooldown
	if typeof(hit_intervals) == TYPE_ARRAY and not hit_intervals.is_empty():
		var interval_index := mini(
			rogue_combo_index,
			hit_intervals.size() - 1
		)
		interval = float(hit_intervals[interval_index])

	var is_finisher := rogue_combo_index >= combo_length - 1
	if is_finisher:
		interval = maxf(
			float(
				rogue_combo_config.get(
					"finisher_recovery",
					1.05
				)
			),
			0.08
		)
		interval *= rogue_combo_recovery_multiplier

	interval = _get_common_attack_interval(interval)
	attack_timer = maxf(interval, 0.08)
	rogue_combo_index = (rogue_combo_index + 1) % combo_length
	if rogue_combo_index == 0:
		rogue_combo_direction = Vector2.ZERO

func _start_rogue_attack_collision_ignore(duration: float) -> void:
	if duration <= 0.0 or is_dying:
		return

	if rogue_saved_collision_mask < 0:
		rogue_saved_collision_mask = collision_mask
	collision_mask = 0
	rogue_attack_collision_ignore_timer = maxf(
		rogue_attack_collision_ignore_timer,
		duration
	)

func _update_rogue_attack_collision_ignore(delta: float) -> void:
	if rogue_attack_collision_ignore_timer <= 0.0:
		if rogue_saved_collision_mask >= 0 and not is_dying:
			collision_mask = rogue_saved_collision_mask
			rogue_saved_collision_mask = -1
		return

	rogue_attack_collision_ignore_timer = maxf(
		rogue_attack_collision_ignore_timer - delta,
		0.0
	)
	if (
		rogue_attack_collision_ignore_timer <= 0.0
		and rogue_saved_collision_mask >= 0
		and not is_dying
	):
		collision_mask = rogue_saved_collision_mask
		rogue_saved_collision_mask = -1

func _rogue_damage_target(
	current_target: Node2D,
	damage: int,
	lifesteal_efficiency: float = 1.0
) -> int:
	if (
		not is_instance_valid(current_target)
		or damage <= 0
		or not current_target.has_method("take_damage")
	):
		return 0

	var hp_before_value = current_target.get("current_hp")
	var hp_before := 0
	var can_measure := hp_before_value != null
	if can_measure:
		hp_before = maxi(int(hp_before_value), 0)

	current_target.call("take_damage", damage)

	if not can_measure:
		return 0

	var hp_after := 0
	if is_instance_valid(current_target):
		var hp_after_value = current_target.get("current_hp")
		if hp_after_value != null:
			hp_after = maxi(int(hp_after_value), 0)

	var actual_damage := maxi(hp_before - hp_after, 0)
	_apply_rogue_lifesteal(
		actual_damage,
		lifesteal_efficiency
	)
	return actual_damage

func _apply_rogue_lifesteal(
	actual_damage: int,
	efficiency: float
) -> void:
	if (
		actual_damage <= 0
		or rogue_lifesteal_ratio <= 0.0
		or current_hp <= 0
		or current_hp >= max_hp
	):
		return

	rogue_lifesteal_buffer += (
		float(actual_damage)
		* rogue_lifesteal_ratio
		* clampf(efficiency, 0.0, 1.0)
	)
	var heal_amount := int(floor(rogue_lifesteal_buffer))
	if heal_amount <= 0:
		return

	rogue_lifesteal_buffer -= float(heal_amount)
	var previous_hp := current_hp
	current_hp = mini(
		current_hp + heal_amount,
		max_hp
	)
	if current_hp == previous_hp:
		return

	health_changed.emit(current_hp, max_hp)
	queue_redraw()

func _rogue_apply_knockback(
	current_target: Node2D,
	direction: Vector2,
	distance: float
) -> void:
	if not is_instance_valid(current_target) or distance <= 0.0:
		return
	var hp_value = current_target.get("current_hp")
	if hp_value != null and int(hp_value) <= 0:
		return

	current_target.global_position += direction.normalized() * distance

func _rogue_should_use_slash() -> bool:
	if rogue_slash_config.is_empty():
		return false

	var radius := maxf(
		float(rogue_slash_config.get("radius", 205.0)),
		0.0
	)
	var required := maxi(
		int(
			rogue_slash_config.get(
				"enemy_count_trigger",
				3
			)
		),
		1
	)
	var nearby := 0
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > radius:
			continue
		nearby += 1
		if nearby >= required:
			return true
	return false

func _start_rogue_slash() -> void:
	rogue_combo_index = 0
	rogue_slash_active = true
	rogue_slash_duration_timer = maxf(
		float(rogue_slash_config.get("duration", 1.20)),
		0.1
	)
	rogue_slash_tick_timer = 0.0
	rogue_slash_cooldown_timer = maxf(
		float(rogue_slash_config.get("cooldown", 14.0)),
		0.0
	)

	var shield_ratio := maxf(
		float(
			rogue_slash_config.get(
				"shield_hp_ratio",
				0.18
			)
		)
		+ rogue_slash_shield_ratio_bonus,
		0.0
	)
	shield_max_hp = float(max_hp) * shield_ratio
	shield_hp = shield_max_hp

	_apply_rogue_slash_tick()
	queue_redraw()

func _update_rogue_slash(delta: float) -> void:
	if not rogue_slash_active:
		return

	rogue_slash_duration_timer = maxf(
		rogue_slash_duration_timer - delta,
		0.0
	)
	rogue_slash_tick_timer = maxf(
		rogue_slash_tick_timer - delta,
		0.0
	)

	if rogue_slash_tick_timer <= 0.0:
		_apply_rogue_slash_tick()
		rogue_slash_tick_timer = maxf(
			float(
				rogue_slash_config.get(
					"tick_interval",
					0.24
				)
			),
			0.08
		)

	if rogue_slash_duration_timer <= 0.0:
		rogue_slash_active = false
		shield_effect.visible = false

func _apply_rogue_slash_tick() -> void:
	var radius := maxf(
		float(rogue_slash_config.get("radius", 205.0)),
		0.0
	)
	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(
				float(
					rogue_slash_config.get(
						"damage_ratio",
						0.50
					)
				),
				0.0
			)
		))
	)

	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > radius:
			continue
		if monster.has_method("take_damage"):
			_rogue_damage_target(
				monster,
				damage,
				0.50
			)

	if shield_effect.sprite_frames != null:
		shield_effect.visible = true
		shield_effect.stop()
		shield_effect.animation = &"slash"
		shield_effect.frame = 0
		shield_effect.play(&"slash")

func _rogue_can_start_assassination() -> bool:
	if ultimate_config.is_empty():
		return false
	if ultimate_cooldown_timer > 0.0:
		return false

	var charge_max := maxf(
		float(ultimate_config.get("charge_max", 100.0)),
		1.0
	)
	if ultimate_charge + 0.001 < charge_max:
		return false

	return _find_rogue_assassination_target() != null

func _start_rogue_assassination() -> void:
	rogue_combo_index = 0
	rogue_assassination_active = true
	rogue_assassination_hits_left = maxi(
		int(ultimate_config.get("hit_count", 5))
		+ rogue_assassination_hit_bonus,
		1
	)
	rogue_assassination_cast_timer = maxf(
		float(ultimate_config.get("cast_time", 0.35)),
		0.0
	)
	rogue_assassination_timer = 0.0
	ultimate_charge = 0.0
	ultimate_cooldown_timer = maxf(
		float(ultimate_config.get("cooldown", 8.0)),
		0.0
	)
	velocity = Vector2.ZERO
	modulate.a = 0.18
	ultimate_used.emit(
		String(ultimate_config.get("id", "shadow_assassination")),
		String(ultimate_config.get("name", "급습-암살"))
	)
	queue_redraw()

func _update_rogue_assassination(delta: float) -> void:
	velocity = Vector2.ZERO

	if rogue_assassination_cast_timer > 0.0:
		rogue_assassination_cast_timer = maxf(
			rogue_assassination_cast_timer - delta,
			0.0
		)
		return

	rogue_assassination_timer = maxf(
		rogue_assassination_timer - delta,
		0.0
	)
	if rogue_assassination_timer > 0.0:
		return

	var current_target := _find_rogue_assassination_target()
	if current_target == null:
		_end_rogue_assassination()
		return

	var approach_direction := global_position.direction_to(
		current_target.global_position
	)
	if approach_direction.length_squared() <= 0.0:
		approach_direction = Vector2.RIGHT

	var behind_offset := maxf(
		float(ultimate_config.get("behind_offset", 54.0)),
		0.0
	)
	global_position = (
		current_target.global_position
		+ approach_direction * behind_offset
	)
	_clamp_to_battlefield()
	_face_attack_direction(-approach_direction.x)

	var base_damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(
				float(
					ultimate_config.get(
						"damage_ratio",
						0.85
					)
				),
				0.0
			)
		))
	)
	var damage := base_damage
	var stage_event_type := String(
		current_target.get_meta(
			"stage_event_type",
			""
		)
	)
	var current_target_hp = current_target.get("current_hp")
	var max_target_hp = current_target.get("max_hp")
	var is_special_target := not stage_event_type.is_empty()

	if (
		not is_special_target
		and current_target_hp != null
		and max_target_hp != null
	):
		var execute_ratio := clampf(
			float(
				ultimate_config.get(
					"execute_hp_ratio",
					0.30
				)
			)
			+ rogue_execute_threshold_bonus,
			0.0,
			0.20
		)
		var hp_ratio := (
			float(current_target_hp)
			/ float(maxi(int(max_target_hp), 1))
		)
		if hp_ratio <= execute_ratio:
			damage = maxi(int(current_target_hp), damage)
	elif is_special_target:
		damage = maxi(
			1,
			int(round(
				float(damage)
				* maxf(
					float(
						ultimate_config.get(
							"elite_damage_multiplier",
							1.75
						)
					),
					1.0
				)
			))
		)

	var main_target_id := current_target.get_instance_id()
	_rogue_damage_target(
		current_target,
		damage,
		1.0
	)

	var assassination_aoe_radius := maxf(
		float(ultimate_config.get("aoe_radius", 120.0)),
		0.0
	)
	var secondary_damage := maxi(
		1,
		int(round(
			float(base_damage)
			* clampf(
				float(
					ultimate_config.get(
						"secondary_damage_ratio",
						0.78
					)
				),
				0.0,
				2.0
			)
		))
	)
	var secondary_lifesteal := clampf(
		float(
			ultimate_config.get(
				"secondary_lifesteal_efficiency",
				0.50
			)
		),
		0.0,
		1.0
	)

	for node in _get_monster_nodes_near(current_target.global_position, assassination_aoe_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if monster.get_instance_id() == main_target_id:
			continue
		if (
			current_target.global_position.distance_to(
				monster.global_position
			)
			> assassination_aoe_radius
		):
			continue

		_rogue_damage_target(
			monster,
			secondary_damage,
			secondary_lifesteal
		)

	attack_pose_timer = 0.20
	_restart_stage1_animation("attack", 1.35)
	_play_rogue_effect(
		channel_effect,
		"assassinate",
		-approach_direction
	)

	rogue_assassination_hits_left -= 1
	if rogue_assassination_hits_left <= 0:
		_end_rogue_assassination()
		return

	rogue_assassination_timer = maxf(
		float(ultimate_config.get("hit_interval", 0.18)),
		0.08
	)

func _find_rogue_assassination_target() -> Node2D:
	var radius := maxf(
		float(ultimate_config.get("target_radius", 520.0)),
		1.0
	)
	var best: Node2D = null
	var best_score := INF

	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var distance := global_position.distance_to(
			monster.global_position
		)
		if distance > radius:
			continue

		var hp_ratio := 1.0
		var max_hp_value = monster.get("max_hp")
		if hp_value != null and max_hp_value != null:
			hp_ratio = (
				float(hp_value)
				/ float(maxi(int(max_hp_value), 1))
			)

		var score := distance + hp_ratio * 120.0
		if score < best_score:
			best_score = score
			best = monster

	return best

func _end_rogue_assassination() -> void:
	rogue_assassination_active = false
	rogue_assassination_hits_left = 0
	rogue_assassination_timer = 0.0
	rogue_assassination_cast_timer = 0.0
	modulate.a = 1.0
	channel_effect.visible = false
	queue_redraw()

func _play_rogue_effect(
	effect_sprite: AnimatedSprite2D,
	animation_name: String,
	direction: Vector2
) -> void:
	if effect_sprite.sprite_frames == null:
		return
	if not effect_sprite.sprite_frames.has_animation(animation_name):
		return

	effect_sprite.visible = true
	effect_sprite.position = direction.normalized() * 28.0
	effect_sprite.rotation = direction.angle()
	effect_sprite.stop()
	effect_sprite.animation = animation_name
	effect_sprite.frame = 0
	effect_sprite.play(animation_name)

func _on_rogue_attack_effect_finished() -> void:
	rogue_attack_effect.visible = false

func _update_rogue_pose_visual(delta: float) -> void:
	if not hero_sprite.visible or is_dying:
		return
	if hit_pose_timer > 0.0 or attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)

	if velocity.length() > 4.0:
		_play_stage1_animation("move", 1.0)
	else:
		_play_stage1_animation("idle", 1.0)

func _on_fighter_guard_release_effect_finished() -> void:
	if hero_archetype == "sword_shield":
		channel_effect.visible = false
		channel_effect.position = Vector2.ZERO
	elif (
		hero_archetype == "pistol_gunner"
		and channel_effect.animation == &"cylinder_dust"
	):
		channel_effect.visible = false
		channel_effect.position = Vector2.ZERO
		channel_effect.modulate = Color.WHITE


func _apply_profile_visual() -> void:
	hero_sprite.visible = false
	hero_sprite.sprite_frames = null
	hero_sprite.modulate = Color.WHITE
	hero_sprite.rotation = 0.0
	hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if hero_archetype == "archmage_elementalist":
		var archmage_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE5_FRAME_DIR
		)
		var archmage_frames := SpriteFrames.new()
		if archmage_frames.has_animation("default"):
			archmage_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			archmage_frames, "idle", archmage_dir, "idle", 4, 6.0, true
		):
			return
		_add_named_sequence_animation(
			archmage_frames, "move", archmage_dir, "walk", 7, 10.0, true
		)
		_add_named_sequence_animation(
			archmage_frames, "attack", archmage_dir, "atk", 7, 17.0, false
		)
		_add_named_sequence_animation(
			archmage_frames, "hit", archmage_dir, "hit", 3, 14.0, false
		)
		_add_named_sequence_animation(
			archmage_frames, "death", archmage_dir, "dead", 4, 10.0, false
		)
		hero_sprite.sprite_frames = archmage_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_id == "ranged_rookie":
		var frame_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE1_FRAME_DIR
		)

		var frames := SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")

		if not _add_named_sequence_animation(
			frames, "idle", frame_dir, "idle", 4, 5.5, true
		):
			return
		if not _add_named_sequence_animation(
			frames, "move", frame_dir, "walk", 7, 10.0, true
		):
			return
		if not _add_named_sequence_animation(
			frames, "attack", frame_dir, "atk", 7, 18.0, false
		):
			return
		if not _add_named_sequence_animation(
			frames, "hit", frame_dir, "hit", 3, 14.0, false
		):
			return
		if not _add_named_sequence_animation(
			frames, "death", frame_dir, "dead", 4, 10.0, false
		):
			return

		hero_sprite.sprite_frames = frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_archetype == "pistol_gunner":
		var gunner_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE4_FRAME_DIR
		)
		var gunner_frames := SpriteFrames.new()
		if gunner_frames.has_animation("default"):
			gunner_frames.remove_animation("default")
		if not _add_named_sequence_animation(gunner_frames, "idle", gunner_dir, "idle", 9, 8.0, true):
			return
		_add_named_sequence_animation(gunner_frames, "move", gunner_dir, "walk", 9, 12.0, true)
		_add_named_sequence_animation(gunner_frames, "attack", gunner_dir, "atk", 9, 20.0, false)
		_add_named_sequence_animation(gunner_frames, "hit", gunner_dir, "hit", 3, 15.0, false)
		_add_named_sequence_animation(gunner_frames, "death", gunner_dir, "dead", 6, 10.0, false)
		hero_sprite.sprite_frames = gunner_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_archetype == "sword_shield":
		var fighter_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE3_FRAME_DIR
		)
		var fighter_frames := SpriteFrames.new()
		if fighter_frames.has_animation("default"):
			fighter_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			fighter_frames, "idle", fighter_dir, "hero_idle", 6, 6.0, true
		):
			return
		_add_named_sequence_animation(
			fighter_frames, "move", fighter_dir, "hero_move", 6, 9.0, true
		)
		_add_named_sequence_animation(
			fighter_frames, "attack", fighter_dir, "hero_attack", 6, 13.0, false
		)
		_add_named_sequence_animation(
			fighter_frames, "hit", fighter_dir, "hero_hit", 6, 12.0, false
		)
		hero_sprite.sprite_frames = fighter_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_archetype != "rogue_combo":
		return

	var frame_dir := (
		sprite_frame_dir
		if not sprite_frame_dir.is_empty()
		else STAGE2_FRAME_DIR
	)
	var rogue_frames := SpriteFrames.new()
	if rogue_frames.has_animation("default"):
		rogue_frames.remove_animation("default")

	if not _add_sequence_animation(
		rogue_frames, "idle", frame_dir, 1, 4, 6.0, true
	):
		return
	_add_sequence_animation(
		rogue_frames, "move", frame_dir, 5, 6, 11.0, true
	)
	_add_sequence_animation(
		rogue_frames, "attack", frame_dir, 11, 6, 18.0, false
	)
	_add_sequence_animation(
		rogue_frames, "hit", frame_dir, 17, 3, 14.0, false
	)
	_add_sequence_animation(
		rogue_frames, "death", frame_dir, 20, 4, 10.0, false
	)

	hero_sprite.sprite_frames = rogue_frames
	hero_sprite.visible = true
	_apply_normalized_hero_visual_scale()
	hero_sprite.speed_scale = 1.0
	hero_sprite.play("idle")

func _apply_normalized_hero_visual_scale() -> void:
	if hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation("idle"):
		return
	if hero_sprite.sprite_frames.get_frame_count("idle") <= 0:
		return

	var texture := hero_sprite.sprite_frames.get_frame_texture(
		"idle",
		0
	)
	if texture == null:
		return

	var image := texture.get_image()
	if image == null or image.is_empty():
		return

	var used_rect := image.get_used_rect()
	if used_rect.size.y <= 0:
		return

	var target_height := _get_stage1_reference_render_height()
	if hero_id == "ranged_rookie":
		# The remade Stage 1 mage uses standalone 256x256 frames. The legacy
		# sheet can be empty/invalid for the old 64x64 reference crop, which
		# previously triggered scale=3 and made the new mage enormous.
		target_height = STAGE1_TARGET_VISIBLE_HEIGHT
	elif target_height <= 0.0:
		target_height = STAGE1_TARGET_VISIBLE_HEIGHT

	var normalized_scale := target_height / float(
		used_rect.size.y
	)
	hero_sprite.scale = Vector2(
		normalized_scale,
		normalized_scale
	)

func _get_stage1_reference_render_height() -> float:
	var reference_texture := _load_stage1_texture(
		HERO_REFERENCE_SHEET_PATH
	)
	if reference_texture == null:
		return 0.0

	var image := reference_texture.get_image()
	if image == null or image.is_empty():
		return 0.0

	var frame_rect := Rect2i(
		Vector2i.ZERO,
		HERO_REFERENCE_FRAME_SIZE
	)
	var frame_image := image.get_region(frame_rect)
	if frame_image == null or frame_image.is_empty():
		return 0.0

	var used_rect := frame_image.get_used_rect()
	if used_rect.size.y <= 0:
		return 0.0

	return (
		float(used_rect.size.y)
		* HERO_REFERENCE_RENDER_SCALE
	)

func _add_named_sequence_animation(
	frames: SpriteFrames,
	animation_name: String,
	base_dir: String,
	file_prefix: String,
	frame_count: int,
	fps: float,
	loop_animation: bool
) -> bool:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)

	for index in range(1, frame_count + 1):
		var path := "%s/%s_%02d.png" % [
			base_dir,
			file_prefix,
			index,
		]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Hero named frame load failed: %s" % path)
			return false
		frames.add_frame(animation_name, texture)

	return true


func _add_sequence_animation(
	frames: SpriteFrames,
	animation_name: String,
	base_dir: String,
	start_index: int,
	frame_count: int,
	fps: float,
	loop_animation: bool
) -> bool:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)

	for offset in range(frame_count):
		var frame_index := start_index + offset
		var path := "%s/frame_%02d.png" % [base_dir, frame_index]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Hero frame load failed: %s" % path)
			return false
		frames.add_frame(animation_name, texture)
	return true

func _build_stage2_effect_frames(
	base_dir: String,
	animation_name: String,
	fps: float = 18.0
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, false)

	for index in range(1, 7):
		var path := "%s/frame_%02d.png" % [base_dir, index]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Stage 2 rogue effect frame load failed: %s" % path)
			return null
		frames.add_frame(animation_name, texture)
	return frames

func _apply_stage2_rogue_effect_visuals() -> void:
	rogue_attack_effect.visible = false
	rogue_attack_effect.sprite_frames = null

	if hero_archetype != "rogue_combo":
		return

	var attack_frames := _build_stage2_effect_frames(
		STAGE2_EFFECT1_DIR,
		"stab",
		20.0
	)
	var assassination_frames := _build_stage2_effect_frames(
		STAGE2_EFFECT2_DIR,
		"assassinate",
		22.0
	)
	var slash_frames := _build_stage2_effect_frames(
		STAGE2_EFFECT3_DIR,
		"slash",
		18.0
	)

	if attack_frames != null:
		rogue_attack_effect.sprite_frames = attack_frames
		rogue_attack_effect.scale = Vector2(0.65, 0.65)

	if assassination_frames != null:
		channel_effect.sprite_frames = assassination_frames
		channel_effect.scale = Vector2(0.72, 0.72)
		channel_effect.position = Vector2.ZERO

	if slash_frames != null:
		shield_effect.sprite_frames = slash_frames
		shield_effect.scale = Vector2(0.52, 0.52)
		shield_effect.position = Vector2.ZERO
		shield_effect.z_index = 3

func _apply_stage1_shield_visual() -> void:
	shield_effect.visible = false
	shield_effect.sprite_frames = null
	shield_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if hero_id != "ranged_rookie":
		return

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"shield")
	frames.set_animation_speed(&"shield", 10.0)
	frames.set_animation_loop(&"shield", true)

	for index in range(1, STAGE1_SHIELD_EFFECT_FRAME_COUNT + 1):
		var path := "%s/frame_%02d.png" % [
			STAGE1_SHIELD_EFFECT_BASE_PATH,
			index,
		]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Stage 1 shield effect frame load failed: %s" % path)
			shield_effect.sprite_frames = null
			return
		frames.add_frame(&"shield", texture)

	shield_effect.sprite_frames = frames
	var uniform_scale := (
		STAGE1_SHIELD_EFFECT_TARGET_SIZE
		/ STAGE1_SHIELD_EFFECT_FRAME_SIZE.x
	)
	shield_effect.scale = Vector2(uniform_scale, uniform_scale)

func _apply_stage1_channel_visual() -> void:
	channel_effect.visible = false
	channel_effect.sprite_frames = null
	channel_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if hero_id != "ranged_rookie":
		return

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"channel")
	frames.set_animation_speed(&"channel", 10.0)
	frames.set_animation_loop(&"channel", true)

	var source_extent := 0.0
	for index in range(1, STAGE1_CHANNEL_EFFECT_FRAME_COUNT + 1):
		var path := "%s/frame_%02d.png" % [
			STAGE1_CHANNEL_EFFECT_BASE_PATH,
			index,
		]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Stage 1 channel effect frame load failed: %s" % path)
			channel_effect.sprite_frames = null
			return

		var texture_size := texture.get_size()
		source_extent = maxf(
			source_extent,
			maxf(texture_size.x, texture_size.y)
		)
		frames.add_frame(&"channel", texture)

	if source_extent <= 0.0:
		push_warning("Stage 1 channel effect: invalid source frame size.")
		channel_effect.sprite_frames = null
		return

	channel_effect.sprite_frames = frames
	var uniform_scale := (
		STAGE1_CHANNEL_EFFECT_TARGET_SIZE
		/ source_extent
	)
	channel_effect.scale = Vector2(uniform_scale, uniform_scale)

func _load_stage1_sheet_texture() -> Texture2D:
	return _load_stage1_texture(sprite_sheet_path)

func _load_stage1_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null

	# Stage 1 art is intentionally loaded from the source PNG first.
	# Some moved effect PNGs still carry stale .import metadata pointing at
	# their pre-frames/ paths, which can make ResourceLoader return the old
	# cached .ctex even after the PNG itself was replaced.
	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(path)
		if error == OK:
			return ImageTexture.create_from_image(image)

	# Fallback to Godot's imported resource only when the raw source cannot
	# be read (for example, on a packaged platform).
	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture

	return null

func _add_stage1_sheet_animation(
	frames: SpriteFrames,
	animation_name: String,
	sheet: Texture2D,
	row: int,
	frame_count: int,
	fps: float,
	loop_animation: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)

	for column in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.filter_clip = true
		atlas.region = Rect2(
			Vector2(column, row) * STAGE1_FRAME_SIZE,
			STAGE1_FRAME_SIZE
		)
		frames.add_frame(animation_name, atlas)

func _play_stage1_animation(animation_name: String, speed_scale: float = 1.0) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(animation_name):
		return

	hero_sprite.speed_scale = speed_scale
	if hero_sprite.animation != animation_name:
		hero_sprite.play(animation_name)

func _restart_stage1_animation(animation_name: String, speed_scale: float = 1.0) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(animation_name):
		return

	hero_sprite.stop()
	hero_sprite.animation = animation_name
	hero_sprite.frame = 0
	hero_sprite.frame_progress = 0.0
	hero_sprite.speed_scale = speed_scale
	hero_sprite.play(animation_name)

func _update_stage1_pose_visual(delta: float) -> void:
	if hero_id not in ["ranged_rookie", "archmage_hero"] or not hero_sprite.visible or is_dying:
		return

	if hit_pose_timer > 0.0:
		return

	# 공격 중에는 발사 순간에 잡은 방향을 유지한다.
	if attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)

	var speed := velocity.length()
	if speed > 4.0:
		var movement_ratio := speed / maxf(move_speed, 1.0)
		var animation_speed := clampf(movement_ratio, 0.72, 1.35)
		_play_stage1_animation("move", animation_speed)
	else:
		_play_stage1_animation("idle", 1.0)

func _update_facing_from_horizontal(horizontal_speed: float, delta: float) -> void:
	if absf(horizontal_speed) < facing_min_horizontal_speed:
		facing_candidate_sign = 0
		facing_candidate_timer = 0.0
		return

	var desired_sign := -1 if horizontal_speed < 0.0 else 1
	var current_sign := -1 if hero_sprite.flip_h else 1

	if desired_sign == current_sign:
		facing_candidate_sign = 0
		facing_candidate_timer = 0.0
		return

	if facing_candidate_sign != desired_sign:
		facing_candidate_sign = desired_sign
		facing_candidate_timer = facing_switch_delay
		return

	facing_candidate_timer = maxf(facing_candidate_timer - delta, 0.0)
	if facing_candidate_timer > 0.0:
		return

	hero_sprite.flip_h = desired_sign < 0
	facing_candidate_sign = 0
	facing_candidate_timer = 0.0

func _face_attack_direction(horizontal_direction: float) -> void:
	if not hero_sprite.visible or absf(horizontal_direction) <= 0.001:
		return

	hero_sprite.flip_h = horizontal_direction < 0.0
	facing_candidate_sign = 0
	facing_candidate_timer = 0.0

func _apply_camera_limits() -> void:
	if not is_instance_valid(follow_camera):
		return

	follow_camera.limit_left = 0
	follow_camera.limit_top = 0
	follow_camera.limit_right = int(battlefield_size.x)
	follow_camera.limit_bottom = int(battlefield_size.y)
	follow_camera.position_smoothing_enabled = true
	follow_camera.position_smoothing_speed = 7.0

func _move_without_monsters() -> void:
	if is_instance_valid(heal_item_target):
		var heal_direction := _apply_heal_item_steering(Vector2.ZERO, 0.016)
		if heal_direction.length_squared() > 0.01:
			velocity = heal_direction * move_speed * 0.90 * move_multiplier
			move_and_slide()
			_clamp_to_battlefield()
			return

	if is_instance_valid(chest_target):
		var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			velocity = chest_direction * move_speed * 0.72 * move_multiplier
			move_and_slide()
			_clamp_to_battlefield()
			if global_position.distance_to(chest_target.global_position) <= 90.0 and attack_timer <= 0.0:
				chest_target.call("take_damage", attack_damage)
				attack_timer = _get_common_attack_interval(attack_cooldown)
			return

	var nearest_exp_orb := _find_nearest_exp_orb()
	if is_instance_valid(nearest_exp_orb):
		var exp_direction := global_position.direction_to(nearest_exp_orb.global_position)
		velocity = exp_direction * move_speed * 0.90 * move_multiplier
		move_and_slide()
		_clamp_to_battlefield()
		return

	if wander_timer <= 0.0 or position.distance_to(wander_target) <= WANDER_REACHED_DISTANCE:
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	velocity = direction * move_speed * 0.72 * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

func _find_nearest_exp_orb() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("exp_orbs"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var orb := node as Node2D
		if orb == null:
			continue

		var distance := global_position.distance_squared_to(orb.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = orb

	return nearest

func _pick_new_wander_target() -> void:
	var candidate := Vector2(battlefield_size.x * 0.5, battlefield_size.y * 0.5)

	for _attempt in range(6):
		candidate = Vector2(
			randf_range(FIELD_MARGIN, battlefield_size.x - FIELD_MARGIN),
			randf_range(FIELD_MARGIN, battlefield_size.y - FIELD_MARGIN)
		)
		if position.distance_to(candidate) >= WANDER_MIN_TARGET_DISTANCE:
			break

	wander_target = candidate
	wander_timer = randf_range(2.6, 5.0)

func _update_combat_reposition(delta: float) -> void:
	combat_strafe_burst_timer = maxf(
		combat_strafe_burst_timer - delta,
		0.0
	)
	combat_strafe_cooldown_timer = maxf(
		combat_strafe_cooldown_timer - delta,
		0.0
	)

	if (
		combat_strafe_burst_timer <= 0.0
		and combat_strafe_cooldown_timer <= 0.0
	):
		if randf() < 0.55:
			strafe_sign *= -1.0
		combat_strafe_burst_timer = randf_range(0.22, 0.38)
		combat_strafe_cooldown_timer = randf_range(0.75, 1.30)


func _choose_melee_spacing_direction(
	nearest_target: Node2D,
	nearest_distance: float,
	approach_ratio: float
) -> Vector2:
	if not is_instance_valid(nearest_target):
		return Vector2.ZERO

	if nearest_distance > attack_range * approach_ratio:
		return global_position.direction_to(nearest_target.global_position)

	# Melee heroes should not orbit their target. Only make a short
	# disengage when they are almost overlapping.
	if nearest_distance >= attack_range * 0.46:
		return Vector2.ZERO

	var away := nearest_target.global_position.direction_to(global_position)
	if away.length_squared() <= 0.001:
		away = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT

	if combat_strafe_burst_timer > 0.0:
		var tangent := Vector2(-away.y, away.x) * strafe_sign
		var desired := away * 0.90 + tangent * 0.24
		if desired.length_squared() > 0.001:
			return desired.normalized()

	return away.normalized()


func _choose_move_direction(nearest_target: Node2D, nearest_distance: float) -> Vector2:
	var avoidance := Vector2.ZERO

	for node in _get_monster_nodes_near(global_position, kite_distance):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var monster := node as Node2D
		if monster == null:
			continue

		var distance := global_position.distance_to(monster.global_position)
		if distance <= 0.0 or distance > kite_distance:
			continue

		var weight := 1.0 - clampf(distance / kite_distance, 0.0, 1.0)
		avoidance += monster.global_position.direction_to(global_position) * (0.35 + weight)

	if avoidance.length_squared() > 0.01:
		return avoidance.normalized()

	if not is_instance_valid(nearest_target):
		return Vector2.ZERO

	var to_target := global_position.direction_to(nearest_target.global_position)
	var away := -to_target

	# Outside the preferred range, approach normally.
	if nearest_distance > attack_range * APPROACH_DISTANCE_RATIO:
		return to_target

	# Too close: prioritize opening distance instead of circling.
	if nearest_distance < attack_range * 0.58:
		var retreat := away
		if combat_strafe_burst_timer > 0.0:
			var retreat_tangent := Vector2(-to_target.y, to_target.x) * strafe_sign
			retreat = away * 0.86 + retreat_tangent * 0.30
		return retreat.normalized()

	# Inside the firing band, stand and shoot most of the time.
	# Brief side-step bursts make the hero reposition without tracing circles.
	if combat_strafe_burst_timer <= 0.0:
		return Vector2.ZERO

	var tangent := Vector2(-to_target.y, to_target.x) * strafe_sign
	var reposition := away * 0.38 + tangent * 0.62
	return reposition.normalized()

func _clamp_to_battlefield() -> void:
	var clamped_position := position
	var hit_edge := false

	if clamped_position.x < FIELD_MARGIN or clamped_position.x > battlefield_size.x - FIELD_MARGIN:
		hit_edge = true
	if clamped_position.y < FIELD_MARGIN or clamped_position.y > battlefield_size.y - FIELD_MARGIN:
		hit_edge = true

	clamped_position.x = clampf(clamped_position.x, FIELD_MARGIN, battlefield_size.x - FIELD_MARGIN)
	clamped_position.y = clampf(clamped_position.y, FIELD_MARGIN, battlefield_size.y - FIELD_MARGIN)
	position = clamped_position

	if hit_edge:
		strafe_sign *= -1.0
		combat_strafe_burst_timer = 0.0
		combat_strafe_cooldown_timer = minf(
			combat_strafe_cooldown_timer,
			0.18
		)

func _update_heal_item_goal(delta: float) -> void:
	heal_item_retarget_timer = maxf(heal_item_retarget_timer - delta, 0.0)
	if current_hp <= 0 or max_hp <= 0:
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return

	var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	if hp_ratio >= 0.60:
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return

	if (
		heal_item_retarget_timer > 0.0
		and is_instance_valid(heal_item_target)
		and not heal_item_target.is_queued_for_deletion()
	):
		return

	heal_item_retarget_timer = randf_range(0.15, 0.30)
	heal_item_target = null

	var desire := _heal_item_desire_for_hp(hp_ratio)
	desire *= maxf(float(ai_settings.get("heal_item_desire", 1.0)), 0.0)
	if desire <= 0.0:
		return

	var risk_tolerance := clampf(
		float(ai_settings.get("heal_risk_tolerance", 0.50)),
		0.0,
		1.0
	)
	var best_score := -INF
	for node in get_tree().get_nodes_in_group("heal_items"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var item := node as Node2D
		if item == null:
			continue

		var distance := global_position.distance_to(item.global_position)
		# At moderate HP, behave like a player preserving position: only detour for nearby heals.
		if hp_ratio > 0.40 and distance > 480.0:
			continue

		var path_midpoint := global_position.lerp(item.global_position, 0.5)
		var path_danger := _estimate_monster_danger(path_midpoint, 260.0)
		var item_danger := _estimate_monster_danger(item.global_position, 220.0)
		var distance_penalty := clampf(distance / 900.0, 0.0, 2.5)
		var danger_penalty := (
			(path_danger * 0.75 + item_danger)
			* lerpf(1.45, 0.45, risk_tolerance)
		)
		var score := desire * 3.2 - distance_penalty - danger_penalty

		if score > best_score and score > 0.20:
			best_score = score
			heal_item_target = item

	if not is_instance_valid(heal_item_target):
		heal_item_steering_direction = Vector2.ZERO


func _heal_item_desire_for_hp(hp_ratio: float) -> float:
	if hp_ratio >= 0.60:
		return 0.0
	if hp_ratio >= 0.40:
		return lerpf(0.12, 0.30, (0.60 - hp_ratio) / 0.20)
	if hp_ratio >= 0.25:
		return lerpf(0.48, 0.68, (0.40 - hp_ratio) / 0.15)
	if hp_ratio >= 0.10:
		return lerpf(0.78, 0.94, (0.25 - hp_ratio) / 0.15)
	return 1.0


func _estimate_monster_danger(at_position: Vector2, radius: float) -> float:
	var danger := 0.0
	var safe_radius := maxf(radius, 1.0)
	var safe_radius_sq := safe_radius * safe_radius
	for node in _get_monster_nodes_near(at_position, safe_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := at_position.distance_squared_to(monster.global_position)
		if distance_sq >= safe_radius_sq:
			continue
		var distance := sqrt(distance_sq)
		danger += 1.0 - clampf(distance / safe_radius, 0.0, 1.0)
	return danger

func _get_crowd_avoidance_direction(radius: float = 230.0) -> Vector2:
	var avoidance := Vector2.ZERO
	var safe_radius := maxf(radius, 1.0)
	var safe_radius_sq := safe_radius * safe_radius
	for node in _get_monster_nodes_near(global_position, safe_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := global_position - monster.global_position
		var distance_sq := offset.length_squared()
		if distance_sq <= 0.0 or distance_sq >= safe_radius_sq:
			continue
		var distance := sqrt(distance_sq)
		var weight := 1.0 - clampf(distance / safe_radius, 0.0, 1.0)
		avoidance += offset / distance * (0.35 + weight)
	return avoidance.normalized() if avoidance.length_squared() > 0.01 else Vector2.ZERO

func _update_chest_goal(delta: float) -> void:
	chest_retarget_timer = maxf(chest_retarget_timer - delta, 0.0)
	if (
		is_instance_valid(chest_target)
		and not chest_target.is_queued_for_deletion()
		and chest_retarget_timer > 0.0
	):
		return

	chest_target = null
	chest_retarget_timer = 0.45
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("treasure_chests"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null:
			continue
		var distance_sq := global_position.distance_squared_to(chest.global_position)
		if distance_sq < best_distance:
			best_distance = distance_sq
			chest_target = chest


func _apply_chest_steering(base_direction: Vector2, delta: float) -> Vector2:
	if not is_instance_valid(chest_target) or chest_target.is_queued_for_deletion():
		chest_target = null
		chest_steering_direction = Vector2.ZERO
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	var distance := global_position.distance_to(chest_target.global_position)
	var chest_direction := global_position.direction_to(chest_target.global_position)
	# 상자는 행동을 취소하는 목표가 아니라 장기적인 이동 편향이다.
	var chest_weight := lerpf(0.22, 0.42, clampf(1.0 - distance / 1100.0, 0.0, 1.0))
	var combat_weight := 1.0
	var desired := base_direction * combat_weight + chest_direction * chest_weight
	if desired.length_squared() <= 0.01:
		desired = chest_direction
	desired = desired.normalized()

	if chest_steering_direction.length_squared() <= 0.01:
		chest_steering_direction = desired
	else:
		chest_steering_direction = chest_steering_direction.lerp(
			desired,
			clampf(delta * 2.4, 0.0, 1.0)
		).normalized()
	return chest_steering_direction


func _damage_treasure_chests(origin: Vector2, radius: float, damage: int) -> void:
	for node in get_tree().get_nodes_in_group("treasure_chests"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or origin.distance_to(chest.global_position) > radius:
			continue
		if chest.has_method("take_damage"):
			chest.call("take_damage", maxi(damage, 1))


func _apply_heal_item_steering(base_direction: Vector2, delta: float) -> Vector2:
	if not is_instance_valid(heal_item_target) or heal_item_target.is_queued_for_deletion():
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	var desire := _heal_item_desire_for_hp(hp_ratio)
	desire *= maxf(float(ai_settings.get("heal_item_desire", 1.0)), 0.0)
	var risk_tolerance := clampf(
		float(ai_settings.get("heal_risk_tolerance", 0.50)),
		0.0,
		1.0
	)
	var detour_weight := maxf(float(ai_settings.get("heal_detour_weight", 1.0)), 0.0)

	var heal_direction := global_position.direction_to(heal_item_target.global_position)
	var avoidance := _get_crowd_avoidance_direction(240.0)
	var local_danger := _estimate_monster_danger(global_position, 210.0)
	var heal_weight := clampf(desire, 0.0, 1.15)
	var combat_weight := maxf(0.35, 1.0 - heal_weight * 0.55)
	var avoidance_weight := (
		(0.60 + local_danger * 0.34)
		* lerpf(1.25, 0.70, risk_tolerance)
		* detour_weight
	)

	var desired := base_direction * combat_weight + heal_direction * heal_weight
	if avoidance.length_squared() > 0.01:
		desired += avoidance * avoidance_weight
	if desired.length_squared() <= 0.01:
		desired = heal_direction
	desired = desired.normalized()

	if heal_item_steering_direction.length_squared() <= 0.01:
		heal_item_steering_direction = desired
	else:
		var turn_speed := lerpf(3.8, 7.5, heal_weight)
		heal_item_steering_direction = heal_item_steering_direction.lerp(
			desired,
			clampf(delta * turn_speed, 0.0, 1.0)
		).normalized()

	return heal_item_steering_direction


func _find_nearest_monster() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF

	for group_name in ["monsters", "treasure_chests"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var combat_target := node as Node2D
			if combat_target == null:
				continue
			var hp_value = combat_target.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			var distance := global_position.distance_squared_to(combat_target.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = combat_target

	return nearest

func _fire_projectile(current_target: Node2D) -> void:
	if channeling:
		return
	if not is_instance_valid(current_target):
		return
	if hero_archetype == "archmage_elementalist":
		_fire_archmage_projectile(current_target)
		return

	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.34
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")

	var projectile_count := 1 + clampi(projectile_count_bonus, 0, 4)
	var spread_step := deg_to_rad(12.0)
	var center_index := float(projectile_count - 1) * 0.5
	for index in range(projectile_count):
		var angle_offset := (float(index) - center_index) * spread_step
		var projectile_direction := shot_direction.rotated(angle_offset).normalized()
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = global_position + projectile_direction * 46.0
		projectile.call(
			"setup",
			projectile_direction,
			attack_damage,
			projectile_speed,
			attack_range,
			hero_id,
			projectile_splash_radius,
			projectile_splash_damage_ratio
		)

	_add_ultimate_charge(
		float(ultimate_config.get("charge_on_attack", 0.0))
	)


func _fire_archmage_projectile(current_target: Node2D) -> void:
	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.34
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")

	var element := _roll_next_archmage_element()
	var projectile := ARCHMAGE_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + shot_direction * 52.0
	projectile.call(
		"setup",
		shot_direction,
		attack_damage,
		projectile_speed,
		attack_range,
		element,
		archmage_element_config,
		self
	)
	_add_archmage_gauge(
		maxf(float(archmage_skill_config.get("gauge_per_basic_attack", 4.0)), 0.0)
	)


func _roll_next_archmage_element() -> String:
	var configured = archmage_element_config.get(
		"elements",
		["earth", "fire", "ice", "light", "wind", "holy"]
	)
	var elements: Array[String] = []
	if typeof(configured) == TYPE_ARRAY:
		for raw_element in configured:
			var element := String(raw_element)
			if not element.is_empty() and element not in elements:
				elements.append(element)

	if elements.is_empty():
		elements = ["earth", "fire", "ice", "light", "wind", "holy"]

	var candidates := elements.duplicate()
	if candidates.size() > 1 and not archmage_last_element.is_empty():
		candidates.erase(archmage_last_element)

	var chosen := String(candidates[randi_range(0, candidates.size() - 1)])
	archmage_last_element = chosen
	return chosen



func _update_archmage_skill_runtime(delta: float) -> void:
	for raw_key in archmage_skill_cooldowns.keys():
		var key := String(raw_key)
		archmage_skill_cooldowns[key] = maxf(
			float(archmage_skill_cooldowns.get(key, 0.0)) - delta,
			0.0
		)

	_add_archmage_gauge(
		maxf(float(archmage_skill_config.get("gauge_per_second", 3.0)), 0.0) * delta
	)
	archmage_orbit_angle = fmod(archmage_orbit_angle + delta * 1.9, TAU)
	_update_archmage_orbit_positions()

	if archmage_casting_sequence:
		return

	var gauge_max := maxf(float(archmage_skill_config.get("gauge_max", 100.0)), 1.0)
	if ultimate_charge + 0.001 < gauge_max:
		return

	var chosen := _choose_archmage_skill()
	if chosen.is_empty():
		return
	_use_archmage_skill(chosen)


func _add_archmage_gauge(amount: float) -> void:
	if amount <= 0.0 or hero_archetype != "archmage_elementalist":
		return
	var gauge_max := maxf(float(archmage_skill_config.get("gauge_max", 100.0)), 1.0)
	ultimate_charge = minf(ultimate_charge + amount, gauge_max)
	queue_redraw()


func restore_archmage_gauge(amount: float) -> void:
	_add_archmage_gauge(amount)


func _choose_archmage_skill() -> String:
	var scores: Dictionary = {}
	var nearby_220 := _count_monsters_near(global_position, 220.0)
	var nearby_360 := _count_monsters_near(global_position, 360.0)
	var total_monsters := _get_monster_nodes_cached().size()

	if _archmage_skill_ready("combustion"):
		scores["combustion"] = 1.2 + float(nearby_220) * 0.65
	if _archmage_skill_ready("ice_bolt") and is_instance_valid(target):
		scores["ice_bolt"] = 2.2
	if _archmage_skill_ready("earth_spikes"):
		scores["earth_spikes"] = 1.4 + minf(float(total_monsters) * 0.14, 2.2)
	if _archmage_skill_ready("holy_power"):
		scores["holy_power"] = 1.1 + float(nearby_360) * 0.45
	if _archmage_skill_ready("chain_dagger") and not archmage_chain_dagger_active and total_monsters > 0:
		scores["chain_dagger"] = 1.4 + minf(float(total_monsters) * 0.25, 2.6)
	if _archmage_skill_ready("storm"):
		scores["storm"] = 1.0 + float(nearby_360) * 0.55

	var cooling_count := 0
	for key in ["combustion", "ice_bolt", "earth_spikes", "holy_power", "chain_dagger", "storm"]:
		if float(archmage_skill_cooldowns.get(key, 0.0)) > 0.0:
			cooling_count += 1
	if _archmage_skill_ready("harmony") and cooling_count >= 1:
		scores["harmony"] = 3.0 + float(cooling_count) * 1.10

	if scores.is_empty():
		return ""

	var total_score := 0.0
	for raw_score in scores.values():
		total_score += maxf(float(raw_score), 0.05)
	var roll := randf() * total_score
	for raw_key in scores.keys():
		var key := String(raw_key)
		roll -= maxf(float(scores[key]), 0.05)
		if roll <= 0.0:
			return key
	return String(scores.keys()[scores.size() - 1])


func _archmage_skill_ready(skill_key: String) -> bool:
	if archmage_skill_config.is_empty():
		return false
	var config: Dictionary = archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return false
	return float(archmage_skill_cooldowns.get(skill_key, 0.0)) <= 0.0


func _use_archmage_skill(skill_key: String) -> void:
	var config: Dictionary = archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return
	if skill_key == "chain_dagger" and archmage_chain_dagger_active:
		return

	var gauge_max := maxf(float(archmage_skill_config.get("gauge_max", 100.0)), 1.0)
	if ultimate_charge + 0.001 < gauge_max:
		return

	var empowered := false
	if skill_key != "harmony" and _archmage_has_all_element_orbs():
		empowered = true
		archmage_element_orbs.clear()
		_refresh_archmage_orbit_visuals()

	ultimate_charge = 0.0
	ultimate_flash_timer = 0.28
	archmage_skill_cooldowns[skill_key] = maxf(float(config.get("cooldown", 0.0)), 0.0)
	attack_pose_timer = 0.36
	_restart_stage1_animation("attack")

	match skill_key:
		"combustion":
			_cast_archmage_combustion(config, empowered)
			_collect_archmage_element("fire")
		"ice_bolt":
			_cast_archmage_ice_bolt(config, empowered)
			_collect_archmage_element("water")
		"earth_spikes":
			_cast_archmage_earth_spikes(config, empowered)
			_collect_archmage_element("earth")
		"holy_power":
			_cast_archmage_holy_power(config, empowered)
			_collect_archmage_element("holy")
		"chain_dagger":
			_cast_archmage_chain_dagger(config, empowered)
			_collect_archmage_element("electric")
		"harmony":
			_cast_archmage_harmony(config)
		"storm":
			_cast_archmage_storm(config, empowered)
			_collect_archmage_element("wind")

	ultimate_used.emit(
		String(config.get("id", skill_key)),
		String(config.get("name", skill_key))
	)
	queue_redraw()


func _skill_damage_multiplier(empowered: bool) -> float:
	return (
		maxf(float(archmage_skill_config.get("empowered_damage_multiplier", 1.50)), 1.0)
		if empowered
		else 1.0
	)


func _cast_archmage_combustion(config: Dictionary, empowered: bool) -> void:
	archmage_casting_sequence = true
	var facing := Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(target):
		facing = global_position.direction_to(target.global_position)
	if facing.length_squared() <= 0.0:
		facing = Vector2.RIGHT
	var orb_position := global_position + facing.normalized() * 76.0
	var charge_fx := _spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect2",
		"fire", 1, 7, 18.0, true, orb_position, Vector2(0.88, 0.88)
	)
	var duration := maxf(float(config.get("charge_duration", 0.90)), 0.05)
	var tick_interval := maxf(float(config.get("charge_tick_interval", 0.18)), 0.05)
	var radius := maxf(float(config.get("charge_radius", 95.0)), 1.0)
	var tick_damage := maxi(1, int(round(
		float(attack_damage)
		* maxf(float(config.get("charge_tick_damage_ratio", 0.22)), 0.0)
		* _skill_damage_multiplier(empowered)
	)))
	var elapsed := 0.0
	while elapsed < duration and is_inside_tree() and current_hp > 0:
		_damage_monsters_in_radius(orb_position, radius, tick_damage)
		await get_tree().create_timer(tick_interval).timeout
		elapsed += tick_interval
	if is_instance_valid(charge_fx):
		charge_fx.queue_free()
	if not is_inside_tree() or current_hp <= 0:
		archmage_casting_sequence = false
		return

	var thrust_direction := facing.normalized()
	var nearest := _find_nearest_monster_from_point(orb_position)
	if is_instance_valid(nearest):
		thrust_direction = orb_position.direction_to(nearest.global_position)
	var thrust_range := maxf(float(config.get("thrust_range", 280.0)), 1.0)
	var thrust_end := orb_position + thrust_direction * thrust_range
	var thrust_fx := _spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect2",
		"fire", 8, 5, 24.0, false, orb_position, Vector2(0.74, 0.74)
	)
	if is_instance_valid(thrust_fx):
		thrust_fx.rotation = thrust_direction.angle()
		var tween := thrust_fx.create_tween()
		tween.tween_property(thrust_fx, "global_position", thrust_end, 0.22)
	var thrust_damage := maxi(1, int(round(
		float(attack_damage)
		* maxf(float(config.get("thrust_damage_ratio", 1.60)), 0.0)
		* _skill_damage_multiplier(empowered)
	)))
	_damage_monsters_in_corridor(
		orb_position,
		thrust_end,
		maxf(float(config.get("thrust_half_width", 92.0)), 1.0),
		thrust_damage
	)
	archmage_casting_sequence = false


func _cast_archmage_ice_bolt(config: Dictionary, empowered: bool) -> void:
	var current_target := _find_farthest_monster_from_point(global_position)
	if not is_instance_valid(current_target):
		return
	var direction := global_position.direction_to(current_target.global_position)
	var projectile := ARCHMAGE_SKILL_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 58.0
	projectile.call(
		"setup", "ice_bolt", direction,
		maxi(1, int(round(float(attack_damage) * float(config.get("damage_ratio", 1.15)) * _skill_damage_multiplier(empowered)))),
		float(config.get("projectile_speed", 1050.0)),
		float(config.get("projectile_range", 850.0)),
		config, self, empowered, current_target
	)


func resolve_archmage_ice_bolt_hit(
	_hit_target: Node2D,
	hit_position: Vector2,
	empowered: bool
) -> void:
	_resolve_archmage_ice_pillars(hit_position, empowered)


func _resolve_archmage_ice_pillars(hit_position: Vector2, empowered: bool) -> void:
	var config: Dictionary = archmage_skill_config.get("ice_bolt", {})
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect4",
		"ice", 7, 1, 18.0, false, hit_position, Vector2(0.72, 0.72)
	)
	var count := maxi(int(config.get("pillar_count", 6)), 1)
	var spawn_radius := maxf(float(config.get("pillar_spawn_radius", 210.0)), 1.0)
	var hit_radius := maxf(float(config.get("pillar_hit_radius", 72.0)), 1.0)
	var pillar_damage := maxi(1, int(round(
		float(attack_damage)
		* float(config.get("pillar_damage_ratio", 0.85))
		* _skill_damage_multiplier(empowered)
	)))
	for index in range(count):
		var angle := randf_range(0.0, TAU)
		var position := hit_position + Vector2.from_angle(angle) * randf_range(25.0, spawn_radius)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect4",
			"ice", 1, 6, 20.0, false, position, Vector2(0.70, 0.70)
		)
		_damage_monsters_in_radius(position, hit_radius, pillar_damage)
		await get_tree().create_timer(0.045).timeout


func _cast_archmage_earth_spikes(config: Dictionary, empowered: bool) -> void:
	archmage_casting_sequence = true
	var direction := Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	var count := maxi(int(config.get("spike_count", 7)), 1)
	var spacing := maxf(float(config.get("spike_spacing", 88.0)), 1.0)
	var radius := maxf(float(config.get("spike_radius", 70.0)), 1.0)
	var spike_damage := maxi(1, int(round(
		float(attack_damage) * float(config.get("damage_ratio", 1.20)) * _skill_damage_multiplier(empowered)
	)))
	var hit_ids: Dictionary = {}
	for index in range(count):
		if not is_inside_tree() or current_hp <= 0:
			break
		var position := global_position + direction.normalized() * spacing * float(index + 1)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect1",
			"earth", 1, 11, 22.0, false, position, Vector2(0.72, 0.72)
		)
		_damage_monsters_in_radius_once(position, radius, spike_damage, hit_ids)
		await get_tree().create_timer(maxf(float(config.get("spike_delay", 0.07)), 0.02)).timeout
	archmage_casting_sequence = false


func _cast_archmage_holy_power(config: Dictionary, empowered: bool) -> void:
	archmage_casting_sequence = true
	var count := maxi(int(config.get("burst_count", 7)), 1)
	var spawn_radius := maxf(float(config.get("burst_spawn_radius", 330.0)), 1.0)
	var hit_radius := maxf(float(config.get("burst_hit_radius", 86.0)), 1.0)
	var base_damage := maxi(1, int(round(
		float(attack_damage) * float(config.get("damage_ratio", 0.90)) * _skill_damage_multiplier(empowered)
	)))
	for index in range(count):
		if not is_inside_tree() or current_hp <= 0:
			break
		var angle := randf_range(0.0, TAU)
		var position := global_position + Vector2.from_angle(angle) * randf_range(30.0, spawn_radius)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect3",
			"holy", 1, 5, 20.0, false, position, Vector2(0.94, 0.94)
		)
		for node in _get_monster_nodes_near(position, hit_radius):
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var monster := node as Node2D
			if monster == null or not monster.has_method("take_damage"):
				continue
			if position.distance_to(monster.global_position) > hit_radius:
				continue
			var dealt := base_damage
			if bool(monster.get_meta("undead", false)) or bool(monster.get_meta("is_undead", false)):
				dealt = maxi(1, int(round(float(dealt) * float(config.get("undead_damage_multiplier", 1.70)))))
			monster.call("take_damage", dealt)
			monster.set_meta("gunner_slow_multiplier", clampf(float(config.get("slow_multiplier", 0.60)), 0.0, 1.0))
			monster.set_meta("gunner_slow_until", Time.get_ticks_msec() + int(maxf(float(config.get("slow_duration", 2.0)), 0.0) * 1000.0))
		await get_tree().create_timer(maxf(float(config.get("burst_delay", 0.09)), 0.02)).timeout
	archmage_casting_sequence = false


func _cast_archmage_chain_dagger(config: Dictionary, empowered: bool) -> void:
	var current_target := target
	if not is_instance_valid(current_target):
		current_target = _find_nearest_monster()
	if not is_instance_valid(current_target):
		return
	archmage_chain_dagger_active = true
	var direction := global_position.direction_to(current_target.global_position)
	var projectile := ARCHMAGE_SKILL_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.add_to_group("archmage_chain_dagger_projectile")
	projectile.global_position = global_position + direction * 58.0
	projectile.call(
		"setup", "chain_dagger", direction,
		maxi(1, int(round(float(attack_damage) * float(config.get("damage_ratio", 1.0))))),
		float(config.get("projectile_speed", 1200.0)),
		float(config.get("projectile_range", 900.0)),
		config, self, empowered, current_target
	)


func notify_archmage_chain_dagger_finished() -> void:
	archmage_chain_dagger_active = false


func _cast_archmage_harmony(config: Dictionary) -> void:
	for key in ["combustion", "ice_bolt", "earth_spikes", "holy_power", "chain_dagger", "storm"]:
		archmage_skill_cooldowns[key] = 0.0
	_add_archmage_gauge(maxf(float(config.get("gauge_refund", 50.0)), 0.0))
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect7",
		"orb", 8, 5, 16.0, false, global_position, Vector2(0.82, 0.82)
	)


func _cast_archmage_storm(config: Dictionary, empowered: bool) -> void:
	for index in range(8):
		var direction := Vector2.from_angle(TAU * float(index) / 8.0)
		var projectile := ARCHMAGE_SKILL_PROJECTILE_SCENE.instantiate() as Area2D
		get_parent().add_child(projectile)
		projectile.global_position = global_position + direction * 56.0
		projectile.call(
			"setup", "storm", direction,
			maxi(1, int(round(float(attack_damage) * float(config.get("damage_ratio", 0.75))))),
			float(config.get("projectile_speed", 900.0)),
			float(config.get("projectile_range", 950.0)),
			config, self, empowered, null
		)


func _collect_archmage_element(element: String) -> void:
	if element.is_empty():
		return
	archmage_element_orbs[element] = true
	_refresh_archmage_orbit_visuals()


func _archmage_has_all_element_orbs() -> bool:
	for element in ["fire", "water", "wind", "electric", "earth", "holy"]:
		if not bool(archmage_element_orbs.get(element, false)):
			return false
	return true


func _refresh_archmage_orbit_visuals() -> void:
	for raw_sprite in archmage_orbit_sprites.values():
		if is_instance_valid(raw_sprite):
			raw_sprite.queue_free()
	archmage_orbit_sprites.clear()
	if hero_archetype != "archmage_elementalist":
		return
	var frame_map := {
		"fire": 1,
		"water": 2,
		"wind": 3,
		"electric": 4,
		"earth": 5,
		"holy": 7,
	}
	for raw_element in archmage_element_orbs.keys():
		var element := String(raw_element)
		if not bool(archmage_element_orbs.get(element, false)):
			continue
		var frame_index := int(frame_map.get(element, 0))
		if frame_index <= 0:
			continue
		var texture := _load_stage1_texture(
			"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_%02d.png" % frame_index
		)
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(0.20, 0.20)
		sprite.z_index = 8
		add_child(sprite)
		archmage_orbit_sprites[element] = sprite
	_update_archmage_orbit_positions()


func _update_archmage_orbit_positions() -> void:
	var count := archmage_orbit_sprites.size()
	if count <= 0:
		return
	var index := 0
	for raw_key in archmage_orbit_sprites.keys():
		var sprite = archmage_orbit_sprites[raw_key]
		if not is_instance_valid(sprite):
			continue
		var angle := archmage_orbit_angle + TAU * float(index) / float(count)
		sprite.position = Vector2.from_angle(angle) * 64.0 + Vector2(0.0, -8.0)
		index += 1


func _spawn_archmage_fx(
	dir: String,
	prefix: String,
	start: int,
	count: int,
	fps: float,
	looped: bool,
	world_position: Vector2,
	fx_scale: Vector2
) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 7
	fx.global_position = world_position
	fx.scale = fx_scale

	var cache_key := "%s|%s|%d|%d|%.3f|%s" % [
		dir,
		prefix,
		start,
		count,
		fps,
		str(looped),
	]
	var cached = _archmage_fx_frames_cache.get(cache_key)
	var frames: SpriteFrames
	if cached is SpriteFrames:
		frames = cached
	else:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("fx")
		frames.set_animation_speed("fx", fps)
		frames.set_animation_loop("fx", looped)
		for index in range(start, start + count):
			var texture := _load_stage1_texture("%s/%s_%02d.png" % [dir, prefix, index])
			if texture != null:
				frames.add_frame("fx", texture)
		_archmage_fx_frames_cache[cache_key] = frames

	if frames.get_frame_count("fx") <= 0:
		return null
	fx.sprite_frames = frames
	get_parent().add_child(fx)
	if not looped:
		fx.animation_finished.connect(fx.queue_free)
	fx.play("fx")
	return fx


func _damage_monsters_in_radius(origin: Vector2, radius: float, damage: int) -> void:
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if origin.distance_squared_to(monster.global_position) <= radius_sq:
			monster.call("take_damage", damage)

func _damage_monsters_in_radius_once(
	origin: Vector2,
	radius: float,
	damage: int,
	hit_ids: Dictionary
) -> void:
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var iid := monster.get_instance_id()
		if hit_ids.has(iid):
			continue
		if origin.distance_squared_to(monster.global_position) <= radius_sq:
			hit_ids[iid] = true
			monster.call("take_damage", damage)

func _damage_monsters_in_corridor(
	start: Vector2,
	end: Vector2,
	half_width: float,
	damage: int
) -> void:
	var segment := end - start
	var length_sq := maxf(segment.length_squared(), 0.001)
	var min_point := Vector2(
		minf(start.x, end.x) - half_width,
		minf(start.y, end.y) - half_width
	)
	var max_point := Vector2(
		maxf(start.x, end.x) + half_width,
		maxf(start.y, end.y) + half_width
	)
	var query_rect := Rect2(min_point, max_point - min_point)
	var half_width_sq := half_width * half_width

	for node in _get_monster_nodes_in_rect(query_rect):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var t := clampf((monster.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var closest := start + segment * t
		if monster.global_position.distance_squared_to(closest) <= half_width_sq:
			monster.call("take_damage", damage)

func _find_farthest_monster_from_point(origin: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := -1.0
	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := origin.distance_squared_to(monster.global_position)
		if distance > best_distance:
			best_distance = distance
			best = monster
	return best


func _find_nearest_monster_from_point(origin: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := origin.distance_squared_to(monster.global_position)
		if distance < best_distance:
			best_distance = distance
			best = monster
	return best


func heal_direct(amount: int) -> int:
	if amount <= 0 or current_hp <= 0 or is_dying:
		return 0
	var previous_hp := current_hp
	current_hp = mini(current_hp + amount, max_hp)
	var recovered := current_hp - previous_hp
	if recovered > 0:
		health_changed.emit(current_hp, max_hp)
		queue_redraw()
	return recovered


func _get_common_attack_interval(base_interval: float) -> float:
	return maxf(
		base_interval / (1.0 + maxf(common_attack_speed_bonus, 0.0)),
		0.06
	)


func _update_channel_skill(delta: float) -> void:
	if channel_skill_config.is_empty() or is_dying or current_hp <= 0:
		return

	if channeling:
		channel_duration_timer = maxf(channel_duration_timer - delta, 0.0)
		channel_tick_timer = maxf(channel_tick_timer - delta, 0.0)

		if channel_tick_timer <= 0.0:
			_apply_channel_damage()
			channel_tick_timer = maxf(
				float(channel_skill_config.get("tick_interval", 0.25)),
				0.05
			)

		if channel_duration_timer <= 0.0:
			_end_channel_skill()
		return

	channel_cooldown_timer = maxf(channel_cooldown_timer - delta, 0.0)

func _should_cast_channel_skill() -> bool:
	var radius := maxf(
		float(channel_skill_config.get("radius", 210.0)),
		0.0
	)
	var required_count := maxi(
		int(channel_skill_config.get("enemy_count_trigger", 4)),
		1
	)
	var close_radius := maxf(
		float(channel_skill_config.get("close_danger_radius", 135.0)),
		0.0
	)
	var close_required := maxi(
		int(channel_skill_config.get("close_danger_count", 2)),
		1
	)
	var force_count := maxi(
		int(channel_skill_config.get("force_enemy_count", 5)),
		required_count
	)
	if radius <= 0.0:
		return false

	var nearby := 0
	var very_close := 0

	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var distance := global_position.distance_to(
			monster.global_position
		)
		if distance > radius:
			continue

		nearby += 1
		if distance <= close_radius:
			very_close += 1

	return (
		nearby >= force_count
		or (
			nearby >= required_count
			and very_close >= close_required
		)
	)

func _use_channel_as_charged_skill() -> void:
	if channel_skill_config.is_empty():
		return
	if channel_cooldown_timer > 0.0 or channeling:
		return

	ultimate_charge = 0.0
	ultimate_flash_timer = 0.28
	_activate_channel_skill()

	var skill_id := String(
		channel_skill_config.get("id", "arcane_field")
	)
	var skill_name := String(
		channel_skill_config.get("name", "비전 집중")
	)
	ultimate_used.emit(skill_id, skill_name)
	queue_redraw()

func _activate_channel_skill() -> void:
	channeling = true
	channel_duration_timer = maxf(
		float(channel_skill_config.get("duration", 2.5)),
		0.05
	)
	channel_tick_timer = 0.0
	channel_cooldown_timer = maxf(
		float(channel_skill_config.get("cooldown", 16.0)),
		0.0
	)
	velocity = Vector2.ZERO

	# 3스 채널링 중에는 평타 발사/공격 모션이 끼어들지 않도록 잠근다.
	attack_timer = maxf(
		attack_timer,
		channel_duration_timer + 0.05
	)
	attack_pose_timer = 0.0

	channel_hid_hero_sprite = hero_sprite.visible
	if channel_hid_hero_sprite:
		hero_sprite.visible = false

	if channel_effect.sprite_frames != null:
		channel_effect.visible = true
		channel_effect.play(&"channel")

	_apply_channel_damage()
	channel_tick_timer = maxf(
		float(channel_skill_config.get("tick_interval", 0.25)),
		0.05
	)
	queue_redraw()

func _apply_channel_damage() -> void:
	var radius := maxf(
		float(channel_skill_config.get("radius", 210.0)),
		0.0
	)
	var damage := maxi(
		int(channel_skill_config.get("tick_damage", 14)),
		1
	)
	if radius <= 0.0:
		return

	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if not node.has_method("take_damage"):
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > radius:
			continue

		monster.call("take_damage", damage)

func _end_channel_skill() -> void:
	channeling = false
	channel_duration_timer = 0.0
	channel_tick_timer = 0.0
	channel_effect.visible = false

	if channel_hid_hero_sprite and hero_sprite.sprite_frames != null:
		hero_sprite.visible = true
		_play_stage1_animation("idle", 1.0)
	channel_hid_hero_sprite = false

	queue_redraw()

func _update_shield_skill(delta: float) -> void:
	if shield_skill_config.is_empty() or is_dying or current_hp <= 0:
		return

	if shield_duration_timer > 0.0:
		shield_duration_timer = maxf(shield_duration_timer - delta, 0.0)
		if shield_duration_timer <= 0.0:
			_end_shield()
		return

	shield_cooldown_timer = maxf(shield_cooldown_timer - delta, 0.0)
	if shield_cooldown_timer > 0.0:
		return

	if _should_cast_shield():
		_activate_shield()

func _should_cast_shield() -> bool:
	var hp_trigger_ratio := clampf(
		float(shield_skill_config.get("hp_trigger_ratio", 0.75)),
		0.0,
		1.0
	)
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	if hp_ratio <= hp_trigger_ratio:
		return true

	var danger_radius := maxf(
		float(shield_skill_config.get("danger_radius", 300.0)),
		0.0
	)
	var danger_count := maxi(
		int(shield_skill_config.get("danger_count", 3)),
		1
	)
	if danger_radius <= 0.0:
		return false

	var nearby := 0
	for node in _get_monster_nodes_near(global_position, danger_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > danger_radius:
			continue
		nearby += 1
		if nearby >= danger_count:
			return true

	return false

func _activate_shield() -> void:
	var configured_hp := maxf(
		float(shield_skill_config.get("shield_hp", 0.0)),
		0.0
	)
	if configured_hp <= 0.0:
		var hp_ratio := maxf(
			float(shield_skill_config.get("shield_hp_ratio", 0.30)),
			0.0
		)
		configured_hp = float(max_hp) * hp_ratio

	if configured_hp <= 0.0:
		return

	shield_max_hp = configured_hp
	shield_hp = configured_hp
	shield_duration_timer = maxf(
		float(shield_skill_config.get("duration", 8.0)),
		0.01
	)
	shield_cooldown_timer = maxf(
		float(shield_skill_config.get("cooldown", 18.0)),
		0.0
	)

	if shield_effect.sprite_frames != null:
		shield_effect.visible = true
		shield_effect.play(&"shield")

	queue_redraw()

func _end_shield() -> void:
	shield_duration_timer = 0.0
	shield_hp = 0.0
	shield_max_hp = 0.0
	shield_effect.visible = false
	queue_redraw()

func _update_ultimate(delta: float) -> void:
	if ultimate_config.is_empty() or is_dying or current_hp <= 0:
		return

	ultimate_cooldown_timer = maxf(
		ultimate_cooldown_timer - delta,
		0.0
	)

	var passive_charge := maxf(
		float(ultimate_config.get("charge_per_second", 0.0)),
		0.0
	)
	if passive_charge > 0.0:
		_add_ultimate_charge(passive_charge * delta)

	_try_use_charged_skill()

func _add_ultimate_charge(amount: float) -> void:
	if amount <= 0.0 or ultimate_config.is_empty() or is_dying:
		return

	var charge_max := maxf(
		float(ultimate_config.get("charge_max", 100.0)),
		1.0
	)
	ultimate_charge = minf(ultimate_charge + amount, charge_max)
	queue_redraw()

func _try_use_charged_skill() -> void:
	if ultimate_config.is_empty() or is_dying or current_hp <= 0:
		return
	if channeling:
		return

	var charge_max := maxf(
		float(ultimate_config.get("charge_max", 100.0)),
		1.0
	)
	if ultimate_charge + 0.001 < charge_max:
		return

	if channel_cooldown_timer <= 0.0 and _should_cast_channel_skill():
		_use_channel_as_charged_skill()
		return

	if ultimate_cooldown_timer <= 0.0:
		_use_ultimate()
		return

func _use_ultimate() -> void:
	if ultimate_config.is_empty() or is_dying or current_hp <= 0:
		return
	if ultimate_cooldown_timer > 0.0:
		return

	var ultimate_type := String(ultimate_config.get("type", ""))
	var ultimate_id := String(ultimate_config.get("id", "ultimate"))
	var ultimate_name := String(
		ultimate_config.get("name", "필살기")
	)

	ultimate_charge = 0.0
	ultimate_flash_timer = 0.28
	ultimate_cooldown_timer = maxf(
		float(ultimate_config.get("cooldown", 14.0)),
		0.0
	)

	match ultimate_type:
		"area_burst":
			_use_area_burst_ultimate()
		"piercing_projectile":
			_use_piercing_projectile_ultimate()
		_:
			push_warning(
				"Unknown Hero ultimate type: %s" % ultimate_type
			)

	ultimate_used.emit(ultimate_id, ultimate_name)
	queue_redraw()

func _use_piercing_projectile_ultimate() -> void:
	var shot_direction := _find_best_piercing_direction()
	if shot_direction.length_squared() <= 0.0:
		if hero_sprite.visible and hero_sprite.flip_h:
			shot_direction = Vector2.LEFT
		else:
			shot_direction = Vector2.RIGHT

	var damage := maxi(
		int(ultimate_config.get("damage", attack_damage * 3)),
		1
	)
	var speed := maxf(
		float(ultimate_config.get("projectile_speed", 950.0)),
		1.0
	)
	var max_range := maxf(
		float(ultimate_config.get("projectile_range", 900.0)),
		1.0
	)

	attack_pose_timer = 0.45
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")

	var projectile := ULTIMATE_PIERCING_PROJECTILE_SCENE.instantiate() as Area2D
	get_parent().add_child(projectile)
	projectile.global_position = global_position + shot_direction * 54.0
	projectile.call(
		"setup",
		shot_direction,
		damage,
		speed,
		max_range
	)

func _find_best_piercing_direction() -> Vector2:
	var max_range := maxf(
		float(ultimate_config.get("projectile_range", 900.0)),
		1.0
	)
	var corridor_half_width := maxf(
		float(ultimate_config.get("aim_corridor_half_width", 72.0)),
		1.0
	)

	var monsters: Array[Node2D] = []
	for node in _get_monster_nodes_near(global_position, max_range):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := global_position.distance_to(
			monster.global_position
		)
		if distance <= 0.0 or distance > max_range:
			continue
		monsters.append(monster)

	if monsters.is_empty():
		return Vector2.ZERO

	var best_direction := global_position.direction_to(
		monsters[0].global_position
	)
	var best_score := -INF

	for candidate in monsters:
		var candidate_direction := global_position.direction_to(
			candidate.global_position
		)
		if candidate_direction.length_squared() <= 0.0:
			continue

		var score := 0.0
		for target_monster in monsters:
			var offset := (
				target_monster.global_position
				- global_position
			)
			var forward := offset.dot(candidate_direction)
			if forward < 0.0 or forward > max_range:
				continue

			var perpendicular := absf(
				offset.cross(candidate_direction)
			)
			if perpendicular > corridor_half_width:
				continue

			score += 1.0
			score += (
				1.0
				- clampf(forward / max_range, 0.0, 1.0)
			) * 0.12

		if score > best_score:
			best_score = score
			best_direction = candidate_direction

	return best_direction.normalized()

func _use_area_burst_ultimate() -> void:
	var radius := maxf(
		float(ultimate_config.get("radius", 0.0)),
		0.0
	)
	var damage := maxi(
		int(ultimate_config.get("damage", 0)),
		0
	)
	if radius <= 0.0 or damage <= 0:
		return

	var targets: Array = _get_monster_nodes_near(global_position, radius)
	for node in targets:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > radius:
			continue
		if monster.has_method("take_damage"):
			monster.call("take_damage", damage)

func collect_heal_item(base_amount: int) -> int:
	if base_amount <= 0 or current_hp <= 0 or is_dying:
		return 0

	var heal_amount := maxi(
		int(round(float(base_amount) * maxf(heal_item_multiplier, 0.0))),
		1
	)
	var previous_hp := current_hp
	current_hp = mini(current_hp + heal_amount, max_hp)
	var recovered := current_hp - previous_hp
	if recovered > 0:
		health_changed.emit(current_hp, max_hp)
		queue_redraw()
	return recovered

func gain_exp(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return

	var gained_exp := maxi(
		1,
		int(round(float(amount) * maxf(exp_gain_multiplier, 0.0)))
	)
	current_exp += gained_exp

	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		_level_up()

	progression_changed.emit(level, current_exp, exp_to_next_level)

func record_offensive_event(monster_type: String, monster_role: String = "") -> void:
	var role := monster_role
	if role.is_empty():
		role = MONSTER_CATALOG.get_role(monster_type)

	offensive_memory_events.append({
		"time": ai_memory_clock,
		"type": monster_type,
		"role": role,
	})
	_prune_offensive_memory()

func _prune_offensive_memory() -> void:
	if offensive_memory_events.is_empty():
		return

	var cutoff := ai_memory_clock - OFFENSE_MEMORY_WINDOW
	while not offensive_memory_events.is_empty():
		var event: Dictionary = offensive_memory_events[0]
		if float(event.get("time", 0.0)) >= cutoff:
			break
		offensive_memory_events.pop_front()

func _build_recent_offense_memory() -> Dictionary:
	_prune_offensive_memory()

	var type_weights := {}
	var role_weights := {}
	var total_weight := 0.0

	for raw_event in offensive_memory_events:
		var event: Dictionary = raw_event
		var age := maxf(ai_memory_clock - float(event.get("time", ai_memory_clock)), 0.0)
		var freshness := 1.0 - clampf(age / OFFENSE_MEMORY_WINDOW, 0.0, 1.0)
		var weight := lerpf(OFFENSE_MEMORY_MIN_WEIGHT, 1.0, freshness)

		var monster_type := String(event.get("type", "slime"))
		var role := String(event.get("role", MONSTER_CATALOG.get_role(monster_type)))
		type_weights[monster_type] = float(type_weights.get(monster_type, 0.0)) + weight
		role_weights[role] = float(role_weights.get(role, 0.0)) + weight
		total_weight += weight

	return {
		"window_seconds": OFFENSE_MEMORY_WINDOW,
		"event_count": offensive_memory_events.size(),
		"total_weight": total_weight,
		"type_weights": type_weights,
		"role_weights": role_weights,
	}

func get_skill_cooldown_hud() -> Array:
	var skills: Array = []

	match hero_archetype:
		"ranged_kiter":
			_append_skill_cooldown_hud(
				skills,
				ultimate_config,
				ultimate_cooldown_timer,
				"res://assets/art/heroes/stage1_mage/frames/effect_01/frame_01.png"
			)
			_append_skill_cooldown_hud(
				skills,
				shield_skill_config,
				shield_cooldown_timer,
				"res://assets/art/heroes/stage1_mage/frames/effect_02/frame_01.png"
			)
			_append_skill_cooldown_hud(
				skills,
				channel_skill_config,
				channel_cooldown_timer,
				"res://assets/art/heroes/stage1_mage/frames/effect_03/frame_01.png"
			)
		"rogue_combo":
			_append_skill_cooldown_hud(
				skills,
				rogue_slash_config,
				rogue_slash_cooldown_timer,
				"res://assets/art/heroes/stage2_rogue/frames/effect_01/frame_01.png"
			)
			_append_skill_cooldown_hud(
				skills,
				ultimate_config,
				ultimate_cooldown_timer,
				"res://assets/art/heroes/stage2_rogue/frames/effect_03/frame_01.png"
			)
		"sword_shield":
			_append_skill_cooldown_hud(
				skills,
				fighter_charge_config,
				fighter_charge_cooldown_timer,
				"res://assets/art/heroes/stage3_fighter/frames/effect5/ground_effect_01.png"
			)
		"archmage_elementalist":
			_append_archmage_skill_hud(skills, "combustion", "res://assets/art/heroes/stage5_archmage/frames/effect2/fire_08.png")
			_append_archmage_skill_hud(skills, "ice_bolt", "res://assets/art/heroes/stage5_archmage/frames/effect4/ice_08.png")
			_append_archmage_skill_hud(skills, "earth_spikes", "res://assets/art/heroes/stage5_archmage/frames/effect1/earth_01.png")
			_append_archmage_skill_hud(skills, "holy_power", "res://assets/art/heroes/stage5_archmage/frames/effect3/holy_01.png")
			_append_archmage_skill_hud(skills, "chain_dagger", "res://assets/art/heroes/stage5_archmage/frames/effect5/light_08.png")
			_append_archmage_skill_hud(skills, "harmony", "res://assets/art/heroes/stage5_archmage/frames/effect7/orb_08.png")
			_append_archmage_skill_hud(skills, "storm", "res://assets/art/heroes/stage5_archmage/frames/effect8/wind_01.png")
		"pistol_gunner":
			_append_gunner_cooldown_hud(
				skills,
				"gunner_backstep",
				"백스텝",
				float(gunner_config.get("backstep_cooldown", 0.0)),
				gunner_backstep_cooldown,
				"res://assets/art/heroes/stage4_gunner/frames/walk_01.png"
			)
			_append_gunner_cooldown_hud(
				skills,
				"gunner_cylinder",
				"실린더타격",
				float(gunner_config.get("cylinder_cooldown", 0.0)),
				gunner_cylinder_cooldown,
				"res://assets/art/heroes/stage4_gunner/frames/effect/effect_explosion_01.png"
			)
			_append_gunner_cooldown_hud(
				skills,
				"gunner_deadeye",
				"데드아이",
				float(gunner_config.get("deadeye_cooldown", 0.0)),
				gunner_deadeye_cooldown,
				"res://assets/art/heroes/stage4_gunner/frames/effect/effect_projectile_01.png"
			)

	return skills


func _append_skill_cooldown_hud(
	skills: Array,
	config: Dictionary,
	remaining: float,
	icon_path: String
) -> void:
	if config.is_empty():
		return
	var cooldown_total := maxf(float(config.get("cooldown", 0.0)), 0.0)
	if cooldown_total <= 0.0:
		return
	skills.append({
		"id": String(config.get("id", "skill")),
		"name": String(config.get("name", "기술")),
		"cooldown_total": cooldown_total,
		"cooldown_remaining": maxf(remaining, 0.0),
		"icon_path": icon_path,
	})


func _append_archmage_skill_hud(
	skills: Array,
	skill_key: String,
	icon_path: String
) -> void:
	var config: Dictionary = archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return
	var cooldown_total := maxf(float(config.get("cooldown", 0.0)), 0.0)
	if cooldown_total <= 0.0:
		return
	skills.append({
		"id": String(config.get("id", skill_key)),
		"name": String(config.get("name", skill_key)),
		"cooldown_total": cooldown_total,
		"cooldown_remaining": maxf(float(archmage_skill_cooldowns.get(skill_key, 0.0)), 0.0),
		"icon_path": icon_path,
	})


func _append_gunner_cooldown_hud(
	skills: Array,
	skill_id: String,
	skill_name: String,
	cooldown_total: float,
	remaining: float,
	icon_path: String
) -> void:
	if cooldown_total <= 0.0:
		return
	skills.append({
		"id": skill_id,
		"name": skill_name,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": maxf(remaining, 0.0),
		"icon_path": icon_path,
	})


func get_recent_offense_summary() -> String:
	var memory := _build_recent_offense_memory()
	var event_count := int(memory.get("event_count", 0))
	if event_count <= 0:
		return "최근 공세 기록 없음"

	var type_weights: Dictionary = memory.get("type_weights", {})
	var total_weight := maxf(float(memory.get("total_weight", 0.0)), 0.001)
	var dominant_type := ""
	var dominant_weight := -1.0

	for raw_type in type_weights.keys():
		var monster_type := String(raw_type)
		var weight := float(type_weights.get(monster_type, 0.0))
		if weight > dominant_weight:
			dominant_weight = weight
			dominant_type = monster_type

	var dominant_name := MONSTER_CATALOG.get_name(dominant_type)
	var dominant_ratio := maxf(dominant_weight, 0.0) / total_weight

	return "최근 %.0f초: %s %.0f%% · 소환 %d회" % [
		OFFENSE_MEMORY_WINDOW,
		dominant_name,
		dominant_ratio * 100.0,
		event_count,
	]

func record_status_effect_event(status_id: String) -> void:
	if status_id.is_empty():
		return

	status_effect_events.append({
		"time": ai_memory_clock,
		"status": status_id,
	})
	_prune_status_memory()

func _prune_status_memory() -> void:
	if status_effect_events.is_empty():
		return

	var cutoff := ai_memory_clock - STATUS_MEMORY_WINDOW
	while not status_effect_events.is_empty():
		var event: Dictionary = status_effect_events[0]
		if float(event.get("time", 0.0)) >= cutoff:
			break
		status_effect_events.pop_front()

func _build_recent_status_memory() -> Dictionary:
	_prune_status_memory()

	var status_weights := {}
	var status_counts := {}
	var total_weight := 0.0

	for raw_event in status_effect_events:
		var event: Dictionary = raw_event
		var age := maxf(
			ai_memory_clock - float(event.get("time", ai_memory_clock)),
			0.0
		)
		var freshness := 1.0 - clampf(
			age / STATUS_MEMORY_WINDOW,
			0.0,
			1.0
		)
		var weight := lerpf(
			STATUS_MEMORY_MIN_WEIGHT,
			1.0,
			freshness
		)

		var status_id := String(event.get("status", ""))
		if status_id.is_empty():
			continue

		status_weights[status_id] = (
			float(status_weights.get(status_id, 0.0)) + weight
		)
		status_counts[status_id] = int(status_counts.get(status_id, 0)) + 1
		total_weight += weight

	return {
		"window_seconds": STATUS_MEMORY_WINDOW,
		"event_count": status_effect_events.size(),
		"total_weight": total_weight,
		"status_weights": status_weights,
		"status_counts": status_counts,
	}

func get_recent_status_summary() -> String:
	var memory := _build_recent_status_memory()
	var event_count := int(memory.get("event_count", 0))
	if event_count <= 0:
		return "최근 상태이상 기록 없음"

	var weights: Dictionary = memory.get("status_weights", {})
	var dominant_status := ""
	var dominant_weight := -1.0

	for raw_status in weights.keys():
		var status_id := String(raw_status)
		var weight := float(weights.get(status_id, 0.0))
		if weight > dominant_weight:
			dominant_weight = weight
			dominant_status = status_id

	return "최근 %.0f초: %s %d회" % [
		STATUS_MEMORY_WINDOW,
		STATUS_EFFECT_CATALOG.get_name(dominant_status),
		event_count,
	]

func get_status_resistance(status_id: String) -> float:
	return clampf(
		float(status_resistances.get(status_id, 0.0)),
		0.0,
		0.85
	)

func _add_status_resistance(
	status_id: String,
	amount: float,
	max_value: float = 0.85
) -> void:
	if status_id.is_empty():
		return

	var current := float(status_resistances.get(status_id, 0.0))
	status_resistances[status_id] = clampf(
		current + amount,
		0.0,
		max_value
	)

func _level_up() -> void:
	level += 1
	exp_to_next_level = _required_exp_for_level(level)
	level_flash_timer = 0.45
	_apply_level_growth()

	var candidates: Array = AUGMENT_CATALOG.roll_candidates(
		3,
		build_counts,
		augment_pool_ids
	)
	if candidates.is_empty():
		health_changed.emit(current_hp, max_hp)
		leveled_up.emit(level)
		augment_selected.emit(
			level,
			candidates,
			"증강 완료",
			"모든 Hero 증강이 최대 중첩에 도달",
			get_build_summary()
		)
		queue_redraw()
		return

	var ai_context: Dictionary = _get_ai_decision_context()
	var chosen: Dictionary = BUILD_AI.choose_candidate(
		candidates,
		ai_context,
		build_counts,
		ai_settings
	)
	_apply_augment(chosen)

	health_changed.emit(current_hp, max_hp)
	leveled_up.emit(level)
	augment_selected.emit(
		level,
		candidates,
		String(chosen.get("name", "알 수 없는 증강")),
		String(chosen.get("decision_reason", "기본 판단")),
		get_build_summary()
	)
	queue_redraw()

func _apply_level_growth() -> void:
	if level_growth_config.is_empty():
		return

	var hp_gain := maxi(
		int(level_growth_config.get("max_hp_per_level", 0)),
		0
	)
	if hp_gain > 0:
		max_hp += hp_gain

	var damage_gain := maxi(
		int(
			level_growth_config.get(
				"attack_damage_per_level",
				0
			)
		),
		0
	)
	if damage_gain > 0:
		attack_damage += damage_gain

	var heal_ratio := clampf(
		float(
			level_growth_config.get(
				"heal_ratio_on_level",
				0.0
			)
		),
		0.0,
		1.0
	)
	if heal_ratio > 0.0 and current_hp > 0:
		current_hp = mini(
			current_hp
			+ maxi(
				int(round(float(max_hp) * heal_ratio)),
				1
			),
			max_hp
		)

func _refresh_ai_observation() -> void:
	var interval := maxf(float(ai_settings.get("observation_interval", 4.0)), 0.25)
	ai_observed_context = _build_ai_context().duplicate(true)
	ai_observed_context_time = ai_memory_clock
	ai_observation_timer = interval

func _get_ai_decision_context() -> Dictionary:
	if ai_observed_context.is_empty():
		_refresh_ai_observation()

	var context := ai_observed_context.duplicate(true)
	context["observation_age"] = maxf(ai_memory_clock - ai_observed_context_time, 0.0)
	context["observation_interval"] = maxf(
		float(ai_settings.get("observation_interval", 4.0)),
		0.25
	)
	return context

func get_ai_observation_summary() -> String:
	var interval := maxf(float(ai_settings.get("observation_interval", 4.0)), 0.25)
	var age := maxf(ai_memory_clock - ai_observed_context_time, 0.0)
	return "관측 주기 %.1f초 · 현재 판단 정보 %.1f초 전" % [interval, age]

func _build_ai_context() -> Dictionary:
	var nearby_count: int = 0
	var total_count: int = 0
	var nearest_distance: float = 9999.0
	var type_counts: Dictionary = {}
	var role_counts: Dictionary = {}

	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var monster := node as Node2D
		if monster == null:
			continue

		var monster_hp = monster.get("current_hp")
		if monster_hp != null and int(monster_hp) <= 0:
			continue

		total_count += 1
		var distance: float = global_position.distance_to(monster.global_position)
		nearest_distance = minf(nearest_distance, distance)

		if distance <= ai_sense_radius:
			nearby_count += 1

		var type_value = monster.get("monster_type")
		if type_value != null:
			var monster_type: String = String(type_value)
			type_counts[monster_type] = int(type_counts.get(monster_type, 0)) + 1

		var role_value = monster.get("monster_role")
		if role_value != null:
			var monster_role: String = String(role_value)
			role_counts[monster_role] = int(role_counts.get(monster_role, 0)) + 1

	if total_count == 0:
		nearest_distance = 0.0

	var recent_memory := _build_recent_offense_memory()
	var recent_status_memory := _build_recent_status_memory()
	var gunner_ammo_ratio := 1.0
	var gunner_reload_state := 0.0
	var gunner_surround_pressure := 0.0
	var gunner_deadeye_cluster_score := 0.0
	if hero_archetype == "pistol_gunner":
		gunner_ammo_ratio = float(gunner_ammo) / float(maxi(gunner_magazine_size, 1))
		gunner_reload_state = 1.0 if gunner_reloading else 0.0
		gunner_surround_pressure = _gunner_surround_pressure()
		gunner_deadeye_cluster_score = float(
			_gunner_deadeye_best_direction().get("score", 0.0)
		)

	return {
		"nearby_count": nearby_count,
		"total_count": total_count,
		"nearest_distance": nearest_distance,
		"hp_ratio": float(current_hp) / float(maxi(max_hp, 1)),
		"level": level,
		"type_counts": type_counts,
		"role_counts": role_counts,
		"recent_event_count": int(recent_memory.get("event_count", 0)),
		"recent_total_weight": float(recent_memory.get("total_weight", 0.0)),
		"recent_type_weights": recent_memory.get("type_weights", {}),
		"recent_role_weights": recent_memory.get("role_weights", {}),
		"recent_window_seconds": float(recent_memory.get("window_seconds", OFFENSE_MEMORY_WINDOW)),
		"recent_status_event_count": int(recent_status_memory.get("event_count", 0)),
		"recent_status_total_weight": float(recent_status_memory.get("total_weight", 0.0)),
		"recent_status_weights": recent_status_memory.get("status_weights", {}),
		"recent_status_counts": recent_status_memory.get("status_counts", {}),
		"recent_status_window_seconds": float(
			recent_status_memory.get("window_seconds", STATUS_MEMORY_WINDOW)
		),
		"gunner_ammo_ratio": gunner_ammo_ratio,
		"gunner_ammo_empty_pressure": 1.0 - gunner_ammo_ratio,
		"gunner_reload_state": gunner_reload_state,
		"gunner_surround_pressure": gunner_surround_pressure,
		"gunner_deadeye_cluster_score": gunner_deadeye_cluster_score,
	}

func _apply_augment(augment: Dictionary) -> void:
	var augment_id: String = String(augment.get("id", ""))
	var current_stack: int = int(build_counts.get(augment_id, 0))
	var max_stack := int(augment.get("max_stack", 0))

	if not augment_id.is_empty() and max_stack > 0 and current_stack >= max_stack:
		return

	for raw_effect in augment.get("effects", []):
		var effect: Dictionary = raw_effect
		_apply_augment_effect(effect)

	if not augment_id.is_empty():
		build_counts[augment_id] = current_stack + 1

func _apply_augment_effect(effect: Dictionary) -> void:
	var op := String(effect.get("op", ""))
	var target := String(effect.get("target", ""))

	match op:
		"add_stat":
			if target.is_empty():
				return

			var current_value = get(target)
			var next_value: float = float(current_value) + float(effect.get("value", 0.0))

			if effect.has("min"):
				next_value = maxf(next_value, float(effect.get("min", next_value)))
			if effect.has("max"):
				next_value = minf(next_value, float(effect.get("max", next_value)))

			if typeof(current_value) == TYPE_INT:
				set(target, int(round(next_value)))
			else:
				set(target, next_value)

		"multiply_stat":
			if target.is_empty():
				return

			var current_value = get(target)
			var next_value: float = float(current_value) * float(effect.get("value", 1.0))

			if effect.has("min"):
				next_value = maxf(next_value, float(effect.get("min", next_value)))
			if effect.has("max"):
				next_value = minf(next_value, float(effect.get("max", next_value)))

			if typeof(current_value) == TYPE_INT:
				set(target, int(round(next_value)))
			else:
				set(target, next_value)

		"advance_projectile_fan":
			projectile_count_bonus = mini(projectile_count_bonus + 1, 4)

		"advance_common_attack_speed":
			common_attack_speed_bonus = minf(
				common_attack_speed_bonus + 0.02,
				0.40
			)

		"advance_fighter_slash_mastery":
			fighter_slash_mastery_stacks = mini(
				fighter_slash_mastery_stacks + 1,
				2
			)

		"advance_fighter_courage":
			# Base charge is always 3 hits. Courage only unlocks extra-chain chance.
			if fighter_courage_bonus <= 0.0:
				fighter_courage_bonus = 0.15
			else:
				fighter_courage_bonus = minf(
					fighter_courage_bonus + 0.03,
					0.36
				)

		"advance_fighter_charge_recovery":
			# Victory Breath: first stack heals 8 on charge kill, then +2 per stack.
			if fighter_charge_kill_heal <= 0.0:
				fighter_charge_kill_heal = 8.0
			else:
				fighter_charge_kill_heal = minf(
					fighter_charge_kill_heal + 2.0,
					26.0
				)

		"gunner_fast_reload":
			gunner_config["reload_seconds"] = maxf(
				float(gunner_config.get("reload_seconds", 2.4)) * 0.92,
				1.55
			)

		"gunner_expand_magazine":
			gunner_magazine_size = mini(gunner_magazine_size + 1, 18)
			gunner_ammo = mini(gunner_ammo + 1, gunner_magazine_size)
			gunner_config["magazine_size"] = gunner_magazine_size

		"gunner_tighten_spread":
			gunner_config["random_shot_angle_degrees"] = maxf(
				float(gunner_config.get("random_shot_angle_degrees", 28.0)) - 3.6,
				10.0
			)

		"gunner_ricochet":
			gunner_ricochet_stacks = mini(gunner_ricochet_stacks + 1, 5)

		"gunner_headshot_chance":
			gunner_config["headshot_chance"] = minf(
				float(gunner_config.get("headshot_chance", 0.10)) + 0.03,
				0.34
			)

		"gunner_headshot_damage":
			gunner_config["headshot_multiplier"] = minf(
				float(gunner_config.get("headshot_multiplier", 1.20)) + 0.05,
				1.50
			)

		"gunner_quickdraw_chance":
			gunner_config["quickdraw_chance"] = minf(
				float(gunner_config.get("quickdraw_chance", 0.03)) + 0.01,
				0.10
			)

		"gunner_tactical_retreat":
			gunner_config["backstep_cooldown"] = maxf(
				float(gunner_config.get("backstep_cooldown", 7.0)) - 0.5,
				4.0
			)
			gunner_config["backstep_distance"] = minf(
				float(gunner_config.get("backstep_distance", 260.0)) + 10.0,
				320.0
			)

		"gunner_afterimage_shot":
			gunner_afterimage_shot_stacks = mini(gunner_afterimage_shot_stacks + 1, 3)

		"gunner_cylinder_control":
			gunner_config["cylinder_knockback"] = minf(
				float(gunner_config.get("cylinder_knockback", 145.0)) + 15.0,
				220.0
			)
			gunner_config["cylinder_slow_duration"] = minf(
				float(gunner_config.get("cylinder_slow_duration", 2.0)) + 0.30,
				3.50
			)

		"gunner_cylinder_damage":
			var cylinder_ratio := float(gunner_config.get("cylinder_damage_ratio", 0.0))
			gunner_config["cylinder_damage_ratio"] = (
				0.80 if cylinder_ratio <= 0.0 else minf(cylinder_ratio + 0.20, 1.60)
			)

		"gunner_deadeye_focus":
			gunner_config["deadeye_shot_interval"] = maxf(
				float(gunner_config.get("deadeye_shot_interval", 0.08)) * 0.93,
				0.052
			)

		"gunner_deadeye_storm":
			gunner_deadeye_shot_multiplier = minf(gunner_deadeye_shot_multiplier + 0.25, 3.0)

		"gunner_low_hp_backstep":
			gunner_low_hp_backstep_bonus = minf(gunner_low_hp_backstep_bonus + 0.08, 0.40)

		"gunner_reload_cover":
			gunner_reload_move_speed_bonus = minf(gunner_reload_move_speed_bonus + 0.06, 0.30)

		"gunner_powder_acceleration":
			if gunner_powder_bonus_per_ammo <= 0.0:
				gunner_powder_bonus_per_ammo = 0.03
			else:
				gunner_powder_bonus_per_ammo = minf(
					gunner_powder_bonus_per_ammo + 0.01,
					0.06
				)

		"heal":
			current_hp = mini(
				current_hp + int(effect.get("value", 0)),
				max_hp
			)

		"add_status_resistance":
			_add_status_resistance(
				String(effect.get("status", "")),
				float(effect.get("value", 0.0)),
				float(effect.get("max", 0.85))
			)

		_:
			push_warning("Unknown Hero augment effect op: %s" % op)

func apply_slow(multiplier: float, duration: float) -> void:
	if current_hp <= 0:
		return

	record_status_effect_event("slow")

	var resistance := get_status_resistance("slow")
	var raw_multiplier := clampf(multiplier, 0.30, 1.0)
	var effective_multiplier := lerpf(
		raw_multiplier,
		1.0,
		resistance
	)
	var effective_duration := maxf(
		duration * (1.0 - resistance),
		0.05
	)

	move_multiplier = minf(move_multiplier, effective_multiplier)
	slow_timer = maxf(slow_timer, effective_duration)
	queue_redraw()

func get_build_summary() -> String:
	if build_counts.is_empty():
		return "아직 선택 없음"

	var parts: PackedStringArray = []
	for augment in AUGMENT_CATALOG.AUGMENTS:
		var augment_id: String = String(augment.get("id", ""))
		var stacks: int = int(build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue

		var label: String = String(augment.get("name", augment_id))
		if stacks > 1:
			label += " x%d" % stacks
		parts.append(label)

	return " · ".join(parts)

func _physics_process_fighter(delta: float) -> void:
	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()

	ai_observation_timer = maxf(ai_observation_timer - delta, 0.0)
	if ai_observation_timer <= 0.0:
		_refresh_ai_observation()

	attack_timer = maxf(attack_timer - delta, 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	ultimate_flash_timer = maxf(ultimate_flash_timer - delta, 0.0)
	_update_invulnerability(delta)
	_update_fighter_guard(delta)
	fighter_charge_cooldown_timer = maxf(fighter_charge_cooldown_timer - delta, 0.0)
	if fighter_charge_active:
		_update_fighter_charge(delta)
		return

	if _update_fighter_slash_combo(delta):
		velocity = Vector2.ZERO
		_update_fighter_pose_visual(delta)
		return

	if hit_flash_timer > 0.0:
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		queue_redraw()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)

	if (
		not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or retarget_timer <= 0.0
	):
		target = _find_nearest_monster()
		retarget_timer = 0.12

	var guard_move_scale := 1.0
	if fighter_guard_active:
		guard_move_scale = clampf(
			float(ultimate_config.get("move_speed_multiplier", 0.62))
			+ fighter_guard_move_multiplier_bonus,
			0.25,
			1.0
		)

	if not is_instance_valid(target):
		_fighter_move_without_monsters(guard_move_scale)
		_update_fighter_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_melee_spacing_direction(
		target,
		distance,
		0.90
	)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	if move_direction.length_squared() > 0.01:
		velocity = (
			move_direction
			* move_speed
			* move_multiplier
			* guard_move_scale
		)
		move_and_slide()
		_clamp_to_battlefield()
	else:
		velocity = Vector2.ZERO

	if (
		fighter_charge_cooldown_timer <= 0.0
		and _fighter_should_start_charge()
	):
		_start_fighter_charge()
		return

	if distance <= attack_range and attack_timer <= 0.0:
		_fighter_basic_attack(target)

	_update_fighter_pose_visual(delta)

func _fighter_should_start_charge() -> bool:
	if fighter_charge_config.is_empty() or fighter_guard_active:
		return false
	var radius := maxf(float(fighter_charge_config.get("trigger_radius", 245.0)), 1.0)
	var required := maxi(int(fighter_charge_config.get("trigger_enemy_count", 4)), 1)
	var nearby := 0
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) <= radius:
			nearby += 1
			if nearby >= required:
				return true
	return false

func _start_fighter_charge() -> void:
	var charge_target := _find_fighter_charge_target()
	if not is_instance_valid(charge_target):
		return
	fighter_charge_chain_count = 0
	_begin_fighter_charge_dash(charge_target)

func _find_fighter_charge_target(exclude: Node = null) -> Node2D:
	var max_distance := maxf(float(fighter_charge_config.get("max_target_distance", 560.0)), 1.0)
	var farthest: Node2D = null
	var farthest_distance := -1.0
	for node in _get_monster_nodes_near(global_position, max_distance):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node == exclude:
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := global_position.distance_to(monster.global_position)
		if distance <= max_distance and distance > farthest_distance:
			farthest = monster
			farthest_distance = distance
	return farthest

func _begin_fighter_charge_dash(charge_target: Node2D) -> void:
	if not is_instance_valid(charge_target):
		_finish_fighter_charge()
		return

	fighter_charge_active = true
	fighter_charge_target = charge_target
	fighter_charge_start = global_position
	var direction := global_position.direction_to(charge_target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	var stop_distance := maxf(float(fighter_charge_config.get("stop_distance", 46.0)), 0.0)
	fighter_charge_end = charge_target.global_position - direction * stop_distance
	var distance := fighter_charge_start.distance_to(fighter_charge_end)
	var dash_speed := maxf(float(fighter_charge_config.get("dash_speed", 1450.0)), 1.0)
	fighter_charge_duration = maxf(distance / dash_speed, 0.06)
	fighter_charge_elapsed = 0.0
	fighter_charge_afterimage_timer = 0.0
	velocity = Vector2.ZERO
	_face_attack_direction(direction.x)
	_restart_stage1_animation("attack", 1.65)
	_play_fighter_attack_effect("thrust", direction)
	_spawn_fighter_afterimage(0.62)

func _update_fighter_charge(delta: float) -> void:
	if not fighter_charge_active:
		return

	fighter_charge_elapsed = minf(
		fighter_charge_elapsed + delta,
		fighter_charge_duration
	)
	var t := clampf(
		fighter_charge_elapsed / maxf(fighter_charge_duration, 0.001),
		0.0,
		1.0
	)
	var eased_t := 1.0 - pow(1.0 - t, 2.5)
	global_position = fighter_charge_start.lerp(fighter_charge_end, eased_t)
	_clamp_to_battlefield()

	fighter_charge_afterimage_timer -= delta
	if fighter_charge_afterimage_timer <= 0.0:
		_spawn_fighter_afterimage(0.48)
		fighter_charge_afterimage_timer = maxf(
			float(fighter_charge_config.get("afterimage_interval", 0.035)),
			0.015
		)

	if t >= 1.0:
		_complete_fighter_charge_dash()

func _complete_fighter_charge_dash() -> void:
	var direction := fighter_charge_start.direction_to(global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT

	var dash_damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* float(fighter_charge_config.get("dash_damage_ratio", 1.20))
		))
	)
	if is_instance_valid(fighter_charge_target):
		_fighter_charge_damage_target(fighter_charge_target, dash_damage)

	var impact_damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* float(fighter_charge_config.get("impact_damage_ratio", 1.70))
		))
	)
	var radius := maxf(float(fighter_charge_config.get("impact_radius", 175.0)), 1.0)
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) <= radius:
			_fighter_charge_damage_target(monster, impact_damage)

	_play_fighter_charge_impact_effect()
	fighter_charge_chain_count += 1

	var base_chains := clampi(
		int(fighter_charge_config.get("max_chains", 3)),
		1,
		3
	)
	var courage_max_chains := clampi(
		int(fighter_charge_config.get("courage_max_chains", 6)),
		base_chains,
		6
	)
	var should_continue := fighter_charge_chain_count < base_chains
	if (
		not should_continue
		and fighter_courage_bonus > 0.0
		and fighter_charge_chain_count < courage_max_chains
	):
		should_continue = randf() <= fighter_courage_bonus

	if should_continue:
		var next_target := _find_fighter_charge_target(fighter_charge_target)
		if is_instance_valid(next_target):
			_begin_fighter_charge_dash(next_target)
			return

	_finish_fighter_charge()

func _fighter_charge_damage_target(monster: Node2D, damage: int) -> void:
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		return
	if not monster.has_method("take_damage"):
		return

	var hp_before_value = monster.get("current_hp")
	var hp_before := int(hp_before_value) if hp_before_value != null else -1
	monster.call("take_damage", maxi(damage, 1))

	if fighter_charge_kill_heal <= 0.0 or hp_before <= 0:
		return
	var hp_after_value = monster.get("current_hp")
	if hp_after_value == null or int(hp_after_value) > 0:
		return

	var heal_amount := maxi(int(round(fighter_charge_kill_heal)), 0)
	if heal_amount <= 0 or current_hp <= 0:
		return

	var previous_hp := current_hp
	current_hp = mini(current_hp + heal_amount, max_hp)
	if current_hp > previous_hp:
		health_changed.emit(current_hp, max_hp)
		queue_redraw()

func _finish_fighter_charge() -> void:
	fighter_charge_active = false
	fighter_charge_target = null
	fighter_charge_elapsed = 0.0
	fighter_charge_duration = 0.0
	fighter_charge_cooldown_timer = maxf(
		float(fighter_charge_config.get("cooldown", 17.0)),
		0.0
	)
	attack_pose_timer = 0.24
	velocity = Vector2.ZERO

func _spawn_fighter_afterimage(alpha: float) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(hero_sprite.animation):
		return
	var frame_texture := hero_sprite.sprite_frames.get_frame_texture(
		hero_sprite.animation,
		hero_sprite.frame
	)
	if frame_texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = frame_texture
	ghost.centered = hero_sprite.centered
	ghost.flip_h = hero_sprite.flip_h
	ghost.flip_v = hero_sprite.flip_v
	ghost.offset = hero_sprite.offset
	ghost.scale = hero_sprite.scale
	ghost.rotation = hero_sprite.rotation
	ghost.global_position = global_position
	ghost.z_index = hero_sprite.z_index - 1
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.05, 0.85))
	get_parent().add_child(ghost)

	var fade_time := maxf(
		float(fighter_charge_config.get("afterimage_fade_time", 0.30)),
		0.05
	)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, fade_time)
	tween.finished.connect(Callable(ghost, "queue_free"))

func _play_fighter_charge_impact_effect() -> void:
	if channel_effect.sprite_frames == null:
		return
	if not channel_effect.sprite_frames.has_animation("charge_impact"):
		return
	channel_effect.visible = true
	channel_effect.stop()
	channel_effect.animation = "charge_impact"
	channel_effect.frame = 0
	channel_effect.rotation = 0.0
	channel_effect.position = Vector2(0, 34)
	channel_effect.play("charge_impact")

func _fighter_move_without_monsters(speed_scale: float) -> void:
	if is_instance_valid(heal_item_target):
		var heal_direction := _apply_heal_item_steering(Vector2.ZERO, 0.016)
		if heal_direction.length_squared() > 0.01:
			velocity = (
				heal_direction
				* move_speed
				* 0.90
				* move_multiplier
				* speed_scale
			)
			move_and_slide()
			_clamp_to_battlefield()
			return

	if is_instance_valid(chest_target):
		var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			velocity = (
				chest_direction
				* move_speed
				* 0.72
				* move_multiplier
				* speed_scale
			)
			move_and_slide()
			_clamp_to_battlefield()
			if global_position.distance_to(chest_target.global_position) <= 105.0 and attack_timer <= 0.0:
				chest_target.call("take_damage", attack_damage)
				attack_timer = _get_common_attack_interval(attack_cooldown)
			return

	var nearest_exp_orb := _find_nearest_exp_orb()
	if is_instance_valid(nearest_exp_orb):
		var exp_direction := global_position.direction_to(nearest_exp_orb.global_position)
		velocity = (
			exp_direction
			* move_speed
			* 0.90
			* move_multiplier
			* speed_scale
		)
		move_and_slide()
		_clamp_to_battlefield()
		return

	if wander_timer <= 0.0 or position.distance_to(wander_target) <= WANDER_REACHED_DISTANCE:
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	velocity = (
		direction
		* move_speed
		* 0.72
		* move_multiplier
		* speed_scale
	)
	move_and_slide()
	_clamp_to_battlefield()

func _update_fighter_pose_visual(delta: float) -> void:
	if hero_archetype != "sword_shield" or not hero_sprite.visible or is_dying:
		return
	if hit_pose_timer > 0.0 or attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)
	if velocity.length() > 4.0:
		_play_stage1_animation("move", 1.0)
	else:
		_play_stage1_animation("idle", 1.0)

func _fighter_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var direction := global_position.direction_to(current_target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.42
	_face_attack_direction(direction.x)
	_restart_fighter_attack_animation(false)

	if _fighter_should_use_slash():
		_fighter_apply_slash(direction, false)
		_play_fighter_attack_effect("slash", direction, false)
		if fighter_slash_mastery_stacks > 0:
			fighter_slash_bonus_hits_remaining = fighter_slash_mastery_stacks
			fighter_slash_combo_direction = direction
			fighter_slash_combo_swing_index = 1
			fighter_slash_combo_timer = _get_common_attack_interval(0.18)
	else:
		_fighter_apply_thrust(direction)
		_play_fighter_attack_effect("thrust", direction, false)
	_damage_treasure_chests(
		global_position + direction * 85.0,
		145.0,
		attack_damage
	)


func _update_fighter_slash_combo(delta: float) -> bool:
	if fighter_slash_bonus_hits_remaining <= 0:
		return false

	fighter_slash_combo_timer = maxf(fighter_slash_combo_timer - delta, 0.0)
	if fighter_slash_combo_timer > 0.0:
		return true

	fighter_slash_combo_swing_index += 1
	var reverse_frames := fighter_slash_combo_swing_index % 2 == 0
	var direction := fighter_slash_combo_direction
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	attack_pose_timer = 0.24
	_face_attack_direction(direction.x)
	_restart_fighter_attack_animation(reverse_frames)
	_fighter_apply_slash(direction, true)
	_play_fighter_attack_effect("slash", direction, reverse_frames)

	fighter_slash_bonus_hits_remaining -= 1
	if fighter_slash_bonus_hits_remaining > 0:
		fighter_slash_combo_timer = _get_common_attack_interval(0.18)
	else:
		fighter_slash_combo_timer = 0.0
		fighter_slash_combo_direction = Vector2.ZERO
	return true


func _restart_fighter_attack_animation(reverse_frames: bool) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation("attack"):
		return

	hero_sprite.stop()
	hero_sprite.animation = &"attack"
	hero_sprite.speed_scale = 1.0
	if reverse_frames:
		var frame_count := hero_sprite.sprite_frames.get_frame_count(&"attack")
		hero_sprite.frame = maxi(frame_count - 1, 0)
		hero_sprite.frame_progress = 0.0
		hero_sprite.play_backwards(&"attack")
	else:
		hero_sprite.frame = 0
		hero_sprite.frame_progress = 0.0
		hero_sprite.play(&"attack")


func _fighter_should_use_slash() -> bool:
	var trigger_count := maxi(
		int(fighter_basic_config.get("slash_enemy_trigger", 2)),
		1
	)
	var radius := maxf(
		float(fighter_basic_config.get("slash_reach", 135.0))
		+ fighter_slash_half_width_bonus,
		1.0
	)
	var nearby := 0
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) <= radius:
			nearby += 1
			if nearby >= trigger_count:
				return true
	return false

func _fighter_apply_slash(direction: Vector2, bonus_hit: bool = false) -> int:
	var reach := maxf(float(fighter_basic_config.get("slash_reach", 135.0)), 1.0)
	var half_width := maxf(
		float(fighter_basic_config.get("slash_half_width", 88.0))
		+ fighter_slash_half_width_bonus,
		1.0
	)
	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* float(fighter_basic_config.get("slash_damage_ratio", 1.0))
			* fighter_basic_damage_multiplier
		))
	)
	var side := Vector2(-direction.y, direction.x)
	var bonus_kills := 0

	for node in _get_monster_nodes_near(global_position, reach + half_width):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := monster.global_position - global_position
		var forward := offset.dot(direction)
		var lateral := absf(offset.dot(side))
		if forward < -24.0 or forward > reach or lateral > half_width:
			continue
		if not monster.has_method("take_damage"):
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before := int(hp_before_value) if hp_before_value != null else -1
		monster.call("take_damage", damage)
		if not bonus_hit or hp_before <= 0:
			continue
		if not is_instance_valid(monster):
			bonus_kills += 1
			continue
		var hp_after_value = monster.get("current_hp")
		if hp_after_value != null and int(hp_after_value) <= 0:
			bonus_kills += 1

	if bonus_kills > 0 and current_hp > 0:
		var previous_hp := current_hp
		current_hp = mini(current_hp + bonus_kills * 10, max_hp)
		if current_hp > previous_hp:
			health_changed.emit(current_hp, max_hp)
			queue_redraw()

	return bonus_kills


func _fighter_apply_thrust(direction: Vector2) -> void:
	var length := maxf(
		float(fighter_basic_config.get("thrust_length", 190.0))
		+ fighter_thrust_length_bonus,
		1.0
	)
	var half_width := maxf(
		float(fighter_basic_config.get("thrust_half_width", 34.0)),
		1.0
	)
	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* (
				float(fighter_basic_config.get("thrust_damage_ratio", 1.05))
				+ fighter_thrust_damage_bonus
			)
			* fighter_basic_damage_multiplier
		))
	)
	var side := Vector2(-direction.y, direction.x)

	for node in _get_monster_nodes_near(global_position, length + half_width):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := monster.global_position - global_position
		var forward := offset.dot(direction)
		var lateral := absf(offset.dot(side))
		if forward < 0.0 or forward > length or lateral > half_width:
			continue
		if monster.has_method("take_damage"):
			monster.call("take_damage", damage)

func _update_fighter_guard(delta: float) -> void:
	if fighter_guard_active:
		fighter_guard_duration_timer = maxf(
			fighter_guard_duration_timer - delta,
			0.0
		)
		if fighter_guard_duration_timer <= 0.0:
			_end_fighter_guard()
		return

	var charge_max := maxf(float(ultimate_config.get("charge_max", 100.0)), 1.0)
	var charge_seconds := maxf(fighter_guard_charge_seconds, 1.0)
	ultimate_charge = minf(
		ultimate_charge + (charge_max / charge_seconds) * delta,
		charge_max
	)
	if ultimate_charge + 0.001 >= charge_max and _fighter_can_activate_guard():
		_start_fighter_guard()
	queue_redraw()

func _fighter_can_activate_guard() -> bool:
	var radius := maxf(
		float(ultimate_config.get("activation_enemy_radius", 320.0)),
		1.0
	)
	var required := maxi(
		int(ultimate_config.get("activation_enemy_count", 1)),
		1
	)
	var nearby := 0
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) <= radius:
			nearby += 1
			if nearby >= required:
				return true
	return false


func _start_fighter_guard() -> void:
	if fighter_guard_active:
		return

	fighter_guard_active = true
	fighter_guard_duration_timer = maxf(
		float(ultimate_config.get("duration", 10.0)),
		0.1
	)
	fighter_guard_stored_damage = 0.0
	ultimate_charge = 0.0

	var shield_ratio := maxf(
		float(ultimate_config.get("shield_hp_ratio", 0.60))
		+ fighter_guard_shield_ratio_bonus,
		0.0
	)
	shield_max_hp = float(max_hp) * shield_ratio
	shield_hp = shield_max_hp

	if shield_effect.sprite_frames != null and shield_effect.sprite_frames.has_animation("guard_aura"):
		shield_effect.visible = true
		shield_effect.play("guard_aura")

	ultimate_used.emit(
		String(ultimate_config.get("id", "shield_guard")),
		String(ultimate_config.get("name", "막기"))
	)
	queue_redraw()

func _end_fighter_guard() -> void:
	if not fighter_guard_active:
		return

	fighter_guard_active = false
	fighter_guard_duration_timer = 0.0
	shield_effect.visible = false

	var release_ratio := maxf(
		float(ultimate_config.get("stored_damage_release_ratio", 0.50))
		+ fighter_guard_release_ratio_bonus,
		0.0
	)
	var release_damage := maxi(
		int(round(fighter_guard_stored_damage * release_ratio)),
		0
	)
	var release_radius := maxf(
		float(ultimate_config.get("release_radius", 250.0)),
		0.0
	)

	if release_damage > 0 and release_radius > 0.0:
		for node in _get_monster_nodes_near(global_position, release_radius):
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var monster := node as Node2D
			if monster == null:
				continue
			if global_position.distance_to(monster.global_position) > release_radius:
				continue
			if monster.has_method("take_damage"):
				monster.call("take_damage", release_damage)

	_play_fighter_guard_release_effect()

	fighter_guard_stored_damage = 0.0
	shield_hp = 0.0
	shield_max_hp = 0.0
	queue_redraw()

func _fighter_reflect_damage(raw_damage: float, source: Node) -> void:
	if fighter_reflect_ratio <= 0.0:
		return
	var reflected := maxi(
		1,
		int(round(raw_damage * fighter_reflect_ratio))
	)

	if (
		is_instance_valid(source)
		and source.is_in_group("monsters")
		and source.has_method("take_damage")
	):
		source.call("take_damage", reflected)
		return

	var reflect_radius := maxf(
		float(ultimate_config.get("reflect_radius", 175.0)),
		1.0
	)
	var nearest: Node2D = null
	var nearest_distance := INF
	for node in _get_monster_nodes_near(global_position, reflect_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance := global_position.distance_to(monster.global_position)
		if distance <= reflect_radius and distance < nearest_distance:
			nearest = monster
			nearest_distance = distance
	if is_instance_valid(nearest) and nearest.has_method("take_damage"):
		nearest.call("take_damage", reflected)

func _play_fighter_attack_effect(
	animation_name: String,
	direction: Vector2,
	reverse_frames: bool = false
) -> void:
	if rogue_attack_effect.sprite_frames == null:
		return
	if not rogue_attack_effect.sprite_frames.has_animation(animation_name):
		return

	rogue_attack_effect.visible = true
	rogue_attack_effect.stop()
	rogue_attack_effect.animation = animation_name
	rogue_attack_effect.rotation = direction.angle()
	if reverse_frames:
		var frame_count := rogue_attack_effect.sprite_frames.get_frame_count(animation_name)
		rogue_attack_effect.frame = maxi(frame_count - 1, 0)
		rogue_attack_effect.frame_progress = 0.0
		rogue_attack_effect.play_backwards(animation_name)
	else:
		rogue_attack_effect.frame = 0
		rogue_attack_effect.frame_progress = 0.0
		rogue_attack_effect.play(animation_name)


func _play_fighter_guard_release_effect() -> void:
	if channel_effect.sprite_frames == null:
		return
	if not channel_effect.sprite_frames.has_animation("guard_release"):
		return

	channel_effect.visible = true
	channel_effect.stop()
	channel_effect.animation = "guard_release"
	channel_effect.frame = 0
	channel_effect.rotation = 0.0
	channel_effect.play("guard_release")

func _apply_stage3_fighter_effect_visuals() -> void:
	if hero_archetype != "sword_shield":
		return

	rogue_attack_effect.visible = false
	channel_effect.visible = false
	shield_effect.visible = false

	var attack_frames := SpriteFrames.new()
	if attack_frames.has_animation("default"):
		attack_frames.remove_animation("default")
	_add_prefixed_effect_animation(
		attack_frames,
		"slash",
		STAGE3_SLASH_EFFECT_DIR,
		"hero_effect_slash",
		6,
		18.0,
		false
	)
	_add_prefixed_effect_animation(
		attack_frames,
		"thrust",
		STAGE3_THRUST_EFFECT_DIR,
		"hero_effect_thrust",
		6,
		18.0,
		false
	)
	rogue_attack_effect.sprite_frames = attack_frames
	rogue_attack_effect.scale = Vector2(0.74, 0.74)
	rogue_attack_effect.position = Vector2.ZERO
	rogue_attack_effect.z_index = 2

	var release_frames := SpriteFrames.new()
	if release_frames.has_animation("default"):
		release_frames.remove_animation("default")
	_add_prefixed_effect_animation(
		release_frames,
		"guard_release",
		STAGE3_BLOCK_EFFECT_DIR,
		"hero_effect_block",
		6,
		15.0,
		false
	)
	_add_prefixed_effect_animation(
		release_frames,
		"charge_impact",
		STAGE3_CHARGE_EFFECT_DIR,
		"ground_effect",
		8,
		20.0,
		false
	)
	channel_effect.sprite_frames = release_frames
	channel_effect.scale = Vector2(0.76, 0.76)
	channel_effect.position = Vector2.ZERO
	channel_effect.z_index = 3

	var aura_frames := SpriteFrames.new()
	if aura_frames.has_animation("default"):
		aura_frames.remove_animation("default")
	_add_prefixed_effect_animation(
		aura_frames,
		"guard_aura",
		STAGE3_AURA_EFFECT_DIR,
		"aura",
		8,
		10.0,
		true
	)
	shield_effect.sprite_frames = aura_frames
	shield_effect.scale = Vector2(0.60, 0.60)
	shield_effect.position = Vector2.ZERO
	shield_effect.z_index = 3


func _apply_stage4_gunner_effect_visuals() -> void:
	if hero_archetype != "pistol_gunner":
		return

	rogue_attack_effect.visible = false
	rogue_attack_effect.sprite_frames = null
	rogue_attack_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"muzzle")
	frames.set_animation_loop(&"muzzle", false)
	frames.set_animation_speed(&"muzzle", 28.0)

	var dust_frames := SpriteFrames.new()
	if dust_frames.has_animation(&"default"):
		dust_frames.remove_animation(&"default")
	dust_frames.add_animation(&"cylinder_dust")
	dust_frames.set_animation_loop(&"cylinder_dust", false)
	dust_frames.set_animation_speed(&"cylinder_dust", 20.0)

	for index in range(1, 8):
		var path := "res://assets/art/heroes/stage4_gunner/frames/effect/effect_explosion_%02d.png" % index
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Stage 4 muzzle frame load failed: %s" % path)
			continue
		frames.add_frame(&"muzzle", texture)

	for index in range(1, 9):
		var dust_path := "%s/ground_effect_%02d.png" % [STAGE3_CHARGE_EFFECT_DIR, index]
		var dust_texture := _load_stage1_texture(dust_path)
		if dust_texture == null:
			push_warning("Cylinder dust frame load failed: %s" % dust_path)
			continue
		dust_frames.add_frame(&"cylinder_dust", dust_texture)

	if frames.get_frame_count(&"muzzle") > 0:
		rogue_attack_effect.sprite_frames = frames
		rogue_attack_effect.scale = Vector2(0.30, 0.30)
		rogue_attack_effect.z_index = 4

	if dust_frames.get_frame_count(&"cylinder_dust") > 0:
		channel_effect.visible = false
		channel_effect.sprite_frames = dust_frames
		channel_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		channel_effect.scale = Vector2(0.92, 0.92)
		channel_effect.position = Vector2.ZERO
		channel_effect.z_index = 2
		channel_effect.modulate = Color(0.76, 0.68, 0.55, 0.88)


func _play_gunner_muzzle_flash(direction: Vector2) -> void:
	if rogue_attack_effect.sprite_frames == null:
		return
	if not rogue_attack_effect.sprite_frames.has_animation(&"muzzle"):
		return
	var dir := direction.normalized()
	if dir.length_squared() <= 0.0:
		dir = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	rogue_attack_effect.position = dir * 48.0 + Vector2(0.0, -6.0)
	rogue_attack_effect.rotation = dir.angle()
	rogue_attack_effect.visible = true
	rogue_attack_effect.stop()
	rogue_attack_effect.animation = &"muzzle"
	rogue_attack_effect.frame = 0
	rogue_attack_effect.frame_progress = 0.0
	rogue_attack_effect.play(&"muzzle")


func _play_gunner_cylinder_dust() -> void:
	if channel_effect.sprite_frames == null:
		return
	if not channel_effect.sprite_frames.has_animation(&"cylinder_dust"):
		return
	channel_effect.visible = true
	channel_effect.stop()
	channel_effect.position = Vector2.ZERO
	channel_effect.rotation = randf_range(-0.10, 0.10)
	channel_effect.modulate = Color(0.76, 0.68, 0.55, 0.88)
	channel_effect.animation = &"cylinder_dust"
	channel_effect.frame = 0
	channel_effect.frame_progress = 0.0
	channel_effect.play(&"cylinder_dust")


func _add_prefixed_effect_animation(
	frames: SpriteFrames,
	animation_name: String,
	base_dir: String,
	file_prefix: String,
	frame_count: int,
	fps: float,
	loop_animation: bool
) -> bool:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)

	for index in range(1, frame_count + 1):
		var path := "%s/%s_%02d.png" % [
			base_dir,
			file_prefix,
			index,
		]
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning("Stage 3 fighter effect frame load failed: %s" % path)
			return false
		frames.add_frame(animation_name, texture)

	return true

func _required_exp_for_level(target_level: int) -> int:
	return 50 + maxi(target_level - 1, 0) * 25

func take_damage(amount: int, source: Node = null) -> bool:
	if (
		amount <= 0
		or current_hp <= 0
		or is_dying
		or invulnerability_timer > 0.0
	):
		return false

	var raw_damage := float(amount)
	var remaining_damage := raw_damage
	var absorbed_damage := 0

	if hero_archetype == "sword_shield" and fighter_guard_active:
		fighter_guard_stored_damage += raw_damage
		var damage_reduction := clampf(
			float(ultimate_config.get("damage_reduction", 0.30))
			+ fighter_guard_damage_reduction_bonus,
			0.0,
			0.75
		)
		remaining_damage *= 1.0 - damage_reduction
		if fighter_reflect_ratio > 0.0:
			_fighter_reflect_damage(raw_damage, source)

	if shield_hp > 0.0:
		absorbed_damage = mini(
			int(ceil(remaining_damage)),
			int(ceil(shield_hp))
		)
		var absorbed := minf(shield_hp, remaining_damage)
		shield_hp = maxf(shield_hp - absorbed, 0.0)
		remaining_damage = maxf(remaining_damage - absorbed, 0.0)
		if shield_hp <= 0.0:
			if hero_archetype == "sword_shield" and fighter_guard_active:
				shield_hp = 0.0
			else:
				_end_shield()

	var previous_hp := current_hp
	current_hp = maxi(current_hp - int(ceil(remaining_damage)), 0)
	var applied_damage := previous_hp - current_hp
	var total_hit := absorbed_damage + applied_damage
	if total_hit <= 0:
		return false

	DAMAGE_NUMBERS.show(self, total_hit)

	hit_flash_timer = 0.12
	hit_pose_timer = 0.23
	_restart_stage1_animation("hit")

	if current_hp > 0 and applied_damage > 0:
		_add_ultimate_charge(
			float(applied_damage)
			* maxf(
				float(ultimate_config.get("charge_per_damage", 0.0)),
				0.0
			)
		)

	health_changed.emit(current_hp, max_hp)
	queue_redraw()

	if current_hp <= 0:
		_begin_death_sequence()
	else:
		invulnerability_timer = invulnerability_duration
		if hero_archetype == "pistol_gunner" and _gunner_should_backstep_on_hit():
			_start_gunner_backstep()
		_refresh_invulnerability_visual()

	return true

func _update_invulnerability(delta: float) -> void:
	if invulnerability_timer <= 0.0:
		if modulate.a < 1.0 and not is_dying:
			modulate.a = 1.0
		return

	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)
	_refresh_invulnerability_visual()

func _refresh_invulnerability_visual() -> void:
	if is_dying or invulnerability_timer <= 0.0:
		modulate.a = 1.0
		return

	var blink_phase := int(
		floor(invulnerability_timer / INVULNERABILITY_BLINK_INTERVAL)
	)
	modulate.a = 0.35 if blink_phase % 2 == 0 else 1.0

func _begin_death_sequence() -> void:
	if is_dying:
		return

	is_dying = true
	invulnerability_timer = 0.0
	modulate.a = 1.0
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0

	if hero_sprite.visible:
		if (
			hero_sprite.sprite_frames != null
			and hero_sprite.sprite_frames.has_animation("death")
		):
			_restart_stage1_animation("death", 1.0)
		else:
			_restart_stage1_animation("hit", 0.85)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(hero_sprite, "modulate:a", 0.0, 0.48)
		tween.tween_property(hero_sprite, "rotation", 0.18, 0.48)

	await get_tree().create_timer(0.52).timeout
	if not is_inside_tree():
		return

	died.emit()
	queue_free()

func _draw() -> void:
	if ultimate_flash_timer > 0.0:
		var flash_ratio := clampf(
			ultimate_flash_timer / 0.28,
			0.0,
			1.0
		)
		draw_circle(
			Vector2.ZERO,
			80.0 + (1.0 - flash_ratio) * 55.0,
			Color(1.0, 0.78, 0.18, flash_ratio * 0.72),
			false,
			8.0
		)

	if level_flash_timer > 0.0:
		draw_circle(Vector2.ZERO, 58.0, Color(1.0, 0.86, 0.25, 0.35), false, 7.0)

	if not hero_sprite.visible:
		var body_color := Color(0.35, 0.68, 1.0)
		if hit_flash_timer > 0.0:
			body_color = Color(1.0, 1.0, 1.0)
		draw_circle(Vector2.ZERO, 34.0, body_color)
		draw_circle(Vector2(0, -4), 21.0, Color(0.82, 0.9, 1.0))
		draw_line(Vector2(22, 13), Vector2(44, -12), Color(0.82, 0.72, 0.48), 7.0)
		draw_circle(Vector2(49, -17), 8.0, Color(0.95, 0.86, 0.32))

	var bar_width := 92.0
	if hero_archetype == "pistol_gunner":
		var gap := 2.0
		var cell_width := (bar_width - gap * float(gunner_magazine_size - 1)) / float(gunner_magazine_size)
		var displayed_cells := gunner_ammo
		if gunner_reloading:
			var reload_duration := maxf(float(gunner_config.get("reload_seconds", 2.4)), 0.1)
			var reload_progress := clampf(1.0 - gunner_reload_timer / reload_duration, 0.0, 1.0)
			displayed_cells = clampi(int(floor(reload_progress * float(gunner_magazine_size))), 0, gunner_magazine_size)
		for index in range(gunner_magazine_size):
			var x := -bar_width / 2.0 + float(index) * (cell_width + gap)
			draw_rect(Rect2(x, -79.0, cell_width, 8.0), Color(0.12, 0.12, 0.14), true)
			if index < displayed_cells:
				draw_rect(Rect2(x, -79.0, cell_width, 8.0), Color(1.0, 0.77, 0.16), true)
	else:
		var ultimate_max := maxf(float(ultimate_config.get("charge_max", 100.0)), 1.0)
		var ultimate_ratio := clampf(ultimate_charge / ultimate_max, 0.0, 1.0)
		draw_rect(Rect2(-bar_width / 2.0, -79.0, bar_width, 8.0), Color(0.12, 0.12, 0.14), true)
		draw_rect(Rect2(-bar_width / 2.0, -79.0, bar_width * ultimate_ratio, 8.0), Color(1.0, 0.77, 0.16), true)

	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(Rect2(-bar_width / 2.0, -64.0, bar_width, 10.0), Color(0.12, 0.12, 0.14), true)
	draw_rect(Rect2(-bar_width / 2.0, -64.0, bar_width * hp_ratio, 10.0), Color(0.95, 0.38, 0.32), true)

	if shield_max_hp > 0.0 and shield_hp > 0.0:
		var shield_ratio := clampf(
			shield_hp / maxf(shield_max_hp, 1.0),
			0.0,
			1.0
		)
		draw_rect(
			Rect2(-bar_width / 2.0, -49.0, bar_width, 8.0),
			Color(0.10, 0.12, 0.18),
			true
		)
		draw_rect(
			Rect2(
				-bar_width / 2.0,
				-49.0,
				bar_width * shield_ratio,
				8.0
			),
			Color(0.20, 0.65, 1.0),
			true
		)
