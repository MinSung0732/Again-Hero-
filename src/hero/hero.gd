extends CharacterBody2D

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)
signal augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal ultimate_used(ultimate_id: String, ultimate_name: String)
signal conditional_skill_unlocked(skill_id: String, skill_name: String, payload: Dictionary)

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
const HERO_WORLD_QUERY_RUNTIME := preload("res://src/hero/hero_world_query_runtime.gd")
const HERO_SUMMONER_RUNTIME := preload("res://src/hero/hero_summoner_runtime.gd")
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
const STAGE6_FRAME_DIR := "res://assets/art/heroes/stage6_berserker/frames"
const STAGE7_FRAME_DIR := "res://assets/art/heroes/stage7_alchemist/frames"
const STAGE8_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames"
const STAGE9_FRAME_DIR := "res://assets/art/heroes/stage9_prist/frames"
const SUMMONER_GATEKEEPER_SCENE := preload("res://src/hero/SummonerGatekeeper.tscn")
const SUMMONER_SCOUT_SCENE := preload("res://src/hero/SummonerScout.tscn")
const SUMMONER_HOUND_SCENE := preload("res://src/hero/SummonerHound.tscn")
const SUMMONER_WATCHER_SCENE := preload("res://src/hero/SummonerWatcher.tscn")
const SUMMONER_OPEN_GATE_SCENE := preload("res://src/hero/SummonerOpenGate.tscn")
const SUMMONER_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/summoner_basic_attack_pixabay.mp3"
const PURIFIER_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/purifier_basic_attack_pixabay.mp3"
const PURIFIER_SHIELD_CREATE_AUDIO_PATH := "res://assets/audio/sfx/purifier_shield_create_pixabay.mp3"
const PURIFIER_SHIELD_BREAK_AUDIO_PATH := "res://assets/audio/sfx/purifier_shield_break_pixabay.mp3"
const PURIFIER_CROWN_AUDIO_PATH := "res://assets/audio/sfx/purifier_crown_buff_pixabay.mp3"
const SUMMONER_POOL_HEADROOM := 4
const ALCHEMIST_VIAL_SCENE := preload("res://src/hero/AlchemistVial.tscn")
const ALCHEMIST_POISON_POOL_SCENE := preload("res://src/hero/AlchemistPoisonPool.tscn")
const ALCHEMY_MATERIAL_SCENE := preload("res://src/hero/AlchemyMaterial.tscn")
const ALCHEMIST_MIXTURE_FIELD_SCENE := preload("res://src/hero/AlchemistMixtureField.tscn")
const ALCHEMIST_CAULDRON_SCENE := preload("res://src/hero/AlchemistCauldron.tscn")
const HEAL_ITEM_SCENE := preload("res://src/battle/HealItem.tscn")

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
const RANGED_BOUNDARY_SOFT_MARGIN := 360.0
const RANGED_BOUNDARY_HARD_MARGIN := 155.0
const OFFENSE_MEMORY_WINDOW := 20.0
const OFFENSE_MEMORY_MIN_WEIGHT := 0.25
const STATUS_MEMORY_WINDOW := 20.0
const STATUS_MEMORY_MIN_WEIGHT := 0.25
const INVULNERABILITY_BLINK_INTERVAL := 0.07
const HERO_BASE_ATTACK_GROWTH_PER_LEVEL := 0.02
const HERO_ATTACK_MILESTONE_INTERVAL := 10
const HERO_ATTACK_MILESTONE_BONUS := 0.05
const HERO_ANIMATION_DUPLICATE_RESTART_GUARD_MSEC := 70

static var _archmage_fx_frames_cache: Dictionary = {}
static var _purifier_protection_frames_cache: SpriteFrames
static var _purifier_crown_frames_cache: SpriteFrames

# Stage 9 standalone frames have small per-frame X drift in their authored
# transparent canvas. Cache a body/root correction once when the visual is built
# so animation playback never scans pixels or allocates arrays per frame.
var stage9_frame_anchor_offsets: Dictionary = {}
var stage9_body_center_offset_x: float = 16.0

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
var base_attack_damage_for_level_growth: float = 34.0
var passive_attack_growth_accumulator: float = 0.0

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
var gunner_reload_redraw_timer: float = 0.0
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

var berserker_config: Dictionary = {}
var berserker_revive_used: bool = false
var berserker_reviving: bool = false
var berserker_saved_collision_layer: int = 0
var berserker_saved_collision_mask: int = 0
var berserker_madness_active: bool = false
var berserker_skill1_cooldown: float = 0.0
var berserker_skill1_active: bool = false
var berserker_skill1_wave_index: int = 0
var berserker_skill1_wave_timer: float = 0.0
var berserker_skill1_direction: Vector2 = Vector2.RIGHT
var berserker_skill2_cooldown: float = 0.0
var berserker_skill3_cooldown: float = 0.0
var berserker_skill3_active: bool = false
var berserker_skill4_cooldown: float = 0.0
var berserker_blood_art_eighth_stacks: int = 0
var berserker_double_edged_heal_multiplier: float = 1.0
var berserker_missing_hp_bonus_override: float = -1.0
var berserker_killing_urge_bonus: float = 0.0
var berserker_blood_art_cooldown_reduction: float = 0.0
var berserker_skill_global_cooldown: float = 0.0

var archmage_element_config: Dictionary = {}
var archmage_last_element: String = ""
var archmage_skill_config: Dictionary = {}
var archmage_skill_cooldowns: Dictionary = {}
var archmage_element_orbs: Dictionary = {}
var archmage_orbit_sprites: Dictionary = {}
var archmage_orbit_angle: float = 0.0
var archmage_chain_dagger_active: bool = false
var archmage_chain_dagger_active_count: int = 0
var archmage_chain_multithrow_stacks: int = 0
var archmage_casting_sequence: bool = false
var archmage_casting_sequence_count: int = 0
var archmage_multicast_stacks: int = 0
var archmage_multicast_active: bool = false
var archmage_blink_stacks: int = 0
var archmage_blink_cooldown_timer: float = 0.0
var archmage_cooldown_reduction: float = 0.0
var archmage_mana_overflow_stacks: int = 0
var archmage_element_cycle_stacks: int = 0

var alchemist_config: Dictionary = {}
var alchemist_gas_max: float = 200.0
var alchemist_gas: float = 200.0
var alchemist_runtime_ready: bool = false
var alchemist_material_spawn_timer: float = 0.0
var alchemist_throw_timer: float = 0.0
var alchemist_throw_index: int = 0
var alchemist_throw_positions: Array[Vector2] = []
var alchemist_direct_chest_target: Node2D = null
var alchemist_vial_pool: Array[Node2D] = []
var alchemist_poison_pool: Array[Node2D] = []
var alchemist_material_pool: Array[Node2D] = []
var alchemist_bonus_materials: Array[Node2D] = []
var alchemist_mixture_field_config: Dictionary = {}
var alchemist_mystery_cauldron_config: Dictionary = {}
var alchemist_cauldrons: Array[Node2D] = []
var alchemist_mystery_cauldron_cooldown: float = 0.0
var alchemist_mixture_field: Node2D = null
var alchemist_mixture_field_cooldown: float = 0.0
var alchemist_mixture_heal_timer: float = 0.0
var alchemist_field_run_active: bool = false
var alchemist_field_run_enter_timer: float = 0.0
var alchemist_field_run_exit_timer: float = 0.0
var alchemist_emergency_config: Dictionary = {}
var alchemist_emergency_cooldown: float = 0.0
var alchemist_emergency_trapped_timer: float = 0.0
var alchemist_philosopher_config: Dictionary = {}
var alchemist_materials_collected: int = 0
var alchemist_philosopher_used: bool = false
var alchemist_philosopher_channeling: bool = false
var alchemist_philosopher_channel_timer: float = 0.0
var alchemist_philosopher_test_timer: float = 0.0
var alchemist_transformed: bool = false
var alchemist_gas_regen_timer: float = 0.0
var alchemist_poison_trail_timer: float = 0.0
var alchemist_poison_trail_last_position: Vector2 = Vector2.ZERO
var alchemist_poison_trail_has_position: bool = false
var alchemist_equivalent_exchange_active: bool = false
var alchemist_equivalent_exchange_paid_hp: int = 0
var alchemist_equivalent_exchange_damage_reduction_timer: float = 0.0

var summoner_config: Dictionary = {}
var summoner_gatekeeper_config: Dictionary = {}
var summoner_scout_config: Dictionary = {}
var summoner_hound_config: Dictionary = {}
var summoner_watcher_config: Dictionary = {}
var summoner_open_gate_config: Dictionary = {}
var summoner_full_slot_shield_config: Dictionary = {}
var summoner_full_slot_shield_cooldown: float = 0.0
var summoner_slot_base: int = 5
var summoner_slot_bonus: int = 0
var summoner_gatekeeper_pool: Array[Node2D] = []
var summoner_scout_pool: Array[Node2D] = []
var summoner_hound_pool: Array[Node2D] = []
var summoner_watcher_pool: Array[Node2D] = []
var summoner_open_gate_pool: Array[Node2D] = []
var summoner_active_regular_count: int = 0
var summoner_active_gatekeepers: int = 0
var summoner_active_scouts: int = 0
var summoner_active_hounds: int = 0
var summoner_active_watchers: int = 0
var summoner_gatekeeper_cooldown: float = 0.0
var summoner_scout_cooldown: float = 0.0
var summoner_hound_cooldown: float = 0.0
var summoner_watcher_cooldown: float = 0.0
var summoner_open_gate_cooldown: float = 0.0
var summoner_total_summons: int = 0
var summoner_open_gate_unlocked: bool = false
var conditional_skill_unlocks: Dictionary = {}
var summoner_cast_interval: float = 1.0
var summoner_cast_lock_timer: float = 0.0
var summoner_cast_pending: bool = false
var summoner_scout_cast_pending: bool = false
var summoner_hound_cast_pending: bool = false
var summoner_watcher_cast_pending: bool = false
var summoner_open_gate_cast_pending: bool = false
var summoner_ai_config: Dictionary = {}
var summoner_ai_personality: String = "balanced"
var summoner_ai_choice_counts: Dictionary = {}
var summoner_ai_last_choice: String = ""
var summoner_runtime_ready: bool = false
var summoner_basic_effect: AnimatedSprite2D = null
var summoner_basic_audio: AudioStreamPlayer = null
var purifier_basic_audio: AudioStreamPlayer = null
var purifier_shield_create_audio: AudioStreamPlayer = null
var purifier_shield_break_audio: AudioStreamPlayer = null
var purifier_crown_audio: AudioStreamPlayer = null
var purifier_protection_effect: AnimatedSprite2D = null
var purifier_crown_effect: AnimatedSprite2D = null

var ultimate_config: Dictionary = {}
var purifier_gauge_config: Dictionary = {}
var purifier_protection_config: Dictionary = {}
var purifier_crown_config: Dictionary = {}
var purifier_protection_cooldown: float = 0.0
var purifier_protection_active: bool = false
var purifier_protection_duration_timer: float = 0.0
var purifier_protection_tick_timer: float = 0.0
var purifier_protection_break_triggered: bool = false
var purifier_crown_cooldown: float = 0.0
var purifier_crown_stacks: int = 0
var purifier_crown_duration_timer: float = 0.0
var purifier_crown_heal_timer: float = 0.0
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

# World-query cache state lives outside this giant facade. Keep these method
# names stable because hero projectiles and skills already call them.
var _world_query_runtime: RefCounted
var _movement_monster_scratch: Array = []


func _get_world_query_runtime() -> RefCounted:
	if _world_query_runtime == null:
		_world_query_runtime = HERO_WORLD_QUERY_RUNTIME.new(self)
	return _world_query_runtime


func _get_monster_nodes_cached() -> Array:
	var result = _get_world_query_runtime().call(
		"get_monster_nodes_cached"
	)
	return result if result is Array else []


func _get_aux_group_nodes_cached(group_name: StringName) -> Array:
	var result = _get_world_query_runtime().call(
		"get_aux_group_nodes_cached",
		group_name
	)
	return result if result is Array else []


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	var result = _get_world_query_runtime().call(
		"get_monster_nodes_near",
		origin,
		radius
	)
	return result if result is Array else []


func _get_monster_nodes_in_rect(world_rect: Rect2) -> Array:
	var result = _get_world_query_runtime().call(
		"get_monster_nodes_in_rect",
		world_rect
	)
	return result if result is Array else []


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
var hero_animation_last_restart_name: StringName = &""
var hero_animation_last_restart_msec: int = -1000000
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
var magnet_item_target: Node2D
var magnet_item_retarget_timer: float = 0.0
var magnet_item_steering_direction: Vector2 = Vector2.ZERO
var exp_orb_target: Node2D
var exp_orb_retarget_until_msec: int = 0

@onready var follow_camera: Camera2D = $Camera2D
@onready var hero_sprite: AnimatedSprite2D = $HeroSprite
@onready var shield_effect: AnimatedSprite2D = $ShieldEffect
@onready var channel_effect: AnimatedSprite2D = $ChannelEffect
@onready var rogue_attack_effect: AnimatedSprite2D = $RogueAttackEffect
@onready var level_up_effect: AnimatedSprite2D = $LevelUpEffect
@onready var level_up_audio: AudioStreamPlayer = $LevelUpAudio
@onready var alchemist_emergency_audio: AudioStreamPlayer = $AlchemistEmergencyAudio
@onready var alchemist_philosopher_audio: AudioStreamPlayer = $AlchemistPhilosopherAudio

func configure_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return

	# configure_profile() is the authoritative start of a fresh battle run.
	# Clear all run-only progression before applying the selected hero profile
	# so retries can never inherit augments that bypass resource conditions.
	build_counts.clear()
	conditional_skill_unlocks.clear()
	current_exp = 0
	status_resistances.clear()
	offensive_memory_events.clear()
	status_effect_events.clear()
	ai_observed_context.clear()
	ai_observed_context_time = 0.0

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
	magnet_item_target = null
	magnet_item_retarget_timer = 0.0
	magnet_item_steering_direction = Vector2.ZERO
	exp_orb_target = null
	exp_orb_retarget_until_msec = 0
	var profile_fighter_basic = profile.get("fighter_basic", {})
	fighter_basic_config = (
		profile_fighter_basic.duplicate(true)
		if typeof(profile_fighter_basic) == TYPE_DICTIONARY
		else {}
	)
	var profile_berserker = profile.get("berserker", {})
	berserker_config = (
		profile_berserker.duplicate(true)
		if typeof(profile_berserker) == TYPE_DICTIONARY
		else {}
	)
	berserker_revive_used = false
	berserker_reviving = false
	berserker_saved_collision_layer = collision_layer
	berserker_saved_collision_mask = collision_mask
	berserker_madness_active = false
	berserker_skill1_cooldown = 0.0
	berserker_skill1_active = false
	berserker_skill1_wave_index = 0
	berserker_skill1_wave_timer = 0.0
	berserker_skill1_direction = Vector2.RIGHT
	berserker_skill2_cooldown = 0.0
	berserker_skill3_cooldown = 0.0
	berserker_skill3_active = false
	berserker_skill4_cooldown = 0.0
	berserker_blood_art_eighth_stacks = 0
	berserker_double_edged_heal_multiplier = 1.0
	berserker_missing_hp_bonus_override = -1.0
	berserker_killing_urge_bonus = 0.0
	berserker_blood_art_cooldown_reduction = 0.0
	berserker_skill_global_cooldown = 0.0

	var profile_alchemist = profile.get("alchemist", {})
	alchemist_config = (
		profile_alchemist.duplicate(true)
		if typeof(profile_alchemist) == TYPE_DICTIONARY
		else {}
	)
	alchemist_gas_max = maxf(float(alchemist_config.get("gas_max", 200.0)), 1.0)
	alchemist_gas = alchemist_gas_max
	alchemist_runtime_ready = false
	alchemist_material_spawn_timer = 0.0
	alchemist_throw_timer = 0.0
	alchemist_throw_index = 0
	alchemist_throw_positions.clear()
	alchemist_direct_chest_target = null
	alchemist_vial_pool.clear()
	alchemist_poison_pool.clear()
	alchemist_material_pool.clear()
	alchemist_bonus_materials.clear()
	alchemist_cauldrons.clear()
	alchemist_mystery_cauldron_cooldown = 0.0
	var raw_mixture_field = alchemist_config.get("mixture_field", {})
	alchemist_mixture_field_config = (
		raw_mixture_field.duplicate(true)
		if typeof(raw_mixture_field) == TYPE_DICTIONARY
		else {}
	)
	var raw_mystery_cauldron = alchemist_config.get("mystery_cauldron", {})
	alchemist_mystery_cauldron_config = (
		raw_mystery_cauldron.duplicate(true)
		if typeof(raw_mystery_cauldron) == TYPE_DICTIONARY
		else {}
	)
	alchemist_mixture_field = null
	alchemist_mixture_field_cooldown = 0.0
	alchemist_mixture_heal_timer = 0.0
	alchemist_field_run_active = false
	alchemist_field_run_enter_timer = 0.0
	alchemist_field_run_exit_timer = 0.0
	var raw_emergency = alchemist_config.get("emergency_escape", {})
	alchemist_emergency_config = (
		raw_emergency.duplicate(true)
		if typeof(raw_emergency) == TYPE_DICTIONARY
		else {}
	)
	alchemist_emergency_cooldown = 0.0
	alchemist_emergency_trapped_timer = 0.0
	var raw_philosopher = alchemist_config.get("philosopher_stone", {})
	alchemist_philosopher_config = (
		raw_philosopher.duplicate(true)
		if typeof(raw_philosopher) == TYPE_DICTIONARY
		else {}
	)
	# Philosopher-stone progress is strictly per battle run.
	alchemist_materials_collected = 0
	alchemist_philosopher_used = false
	alchemist_philosopher_channeling = false
	alchemist_philosopher_channel_timer = 0.0
	alchemist_philosopher_test_timer = (
		maxf(
			float(alchemist_philosopher_config.get("test_delay_seconds", 5.0)),
			0.0
		)
		if bool(alchemist_philosopher_config.get("test_mode", false))
		else 0.0
	)
	alchemist_transformed = false
	alchemist_gas_regen_timer = 0.0
	alchemist_poison_trail_timer = 0.0
	alchemist_poison_trail_last_position = Vector2.ZERO
	alchemist_poison_trail_has_position = false
	alchemist_equivalent_exchange_active = false
	alchemist_equivalent_exchange_paid_hp = 0
	alchemist_equivalent_exchange_damage_reduction_timer = 0.0

	var profile_summoner = profile.get("summoner", {})
	summoner_config = (
		profile_summoner.duplicate(true)
		if typeof(profile_summoner) == TYPE_DICTIONARY
		else {}
	)
	var raw_summoner_ai = summoner_config.get("ai", {})
	summoner_ai_config = (
		raw_summoner_ai.duplicate(true)
		if typeof(raw_summoner_ai) == TYPE_DICTIONARY
		else {}
	)
	summoner_ai_choice_counts.clear()
	summoner_ai_last_choice = ""
	summoner_ai_personality = _roll_summoner_ai_personality()
	var raw_gatekeeper = summoner_config.get("gatekeeper", {})
	summoner_gatekeeper_config = (
		raw_gatekeeper.duplicate(true)
		if typeof(raw_gatekeeper) == TYPE_DICTIONARY
		else {}
	)
	var raw_scout = summoner_config.get("scout", {})
	summoner_scout_config = (
		raw_scout.duplicate(true)
		if typeof(raw_scout) == TYPE_DICTIONARY
		else {}
	)
	var raw_hound = summoner_config.get("hound", {})
	summoner_hound_config = (
		raw_hound.duplicate(true)
		if typeof(raw_hound) == TYPE_DICTIONARY
		else {}
	)
	var raw_watcher = summoner_config.get("watcher", {})
	summoner_watcher_config = (
		raw_watcher.duplicate(true)
		if typeof(raw_watcher) == TYPE_DICTIONARY
		else {}
	)
	var raw_open_gate = summoner_config.get("open_gate", {})
	summoner_open_gate_config = (
		raw_open_gate.duplicate(true)
		if typeof(raw_open_gate) == TYPE_DICTIONARY
		else {}
	)
	var raw_full_slot_shield = summoner_config.get("full_slot_shield", {})
	summoner_full_slot_shield_config = (
		raw_full_slot_shield.duplicate(true)
		if typeof(raw_full_slot_shield) == TYPE_DICTIONARY
		else {}
	)
	summoner_full_slot_shield_cooldown = maxf(
		float(summoner_full_slot_shield_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_slot_base = maxi(
		int(summoner_config.get("base_slot_count", 5)),
		1
	)
	summoner_slot_bonus = 0
	summoner_gatekeeper_pool.clear()
	summoner_scout_pool.clear()
	summoner_hound_pool.clear()
	summoner_watcher_pool.clear()
	summoner_open_gate_pool.clear()
	summoner_active_regular_count = 0
	summoner_active_gatekeepers = 0
	summoner_active_scouts = 0
	summoner_active_hounds = 0
	summoner_active_watchers = 0
	summoner_gatekeeper_cooldown = maxf(
		float(summoner_gatekeeper_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_scout_cooldown = maxf(
		float(summoner_scout_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_hound_cooldown = maxf(
		float(summoner_hound_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_watcher_cooldown = maxf(
		float(summoner_watcher_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_open_gate_cooldown = maxf(
		float(summoner_open_gate_config.get("initial_cooldown", 0.0)),
		0.0
	)
	summoner_total_summons = 0
	summoner_open_gate_unlocked = (
		_get_summoner_open_gate_required_summons() <= 0
	)
	if summoner_open_gate_unlocked and not summoner_open_gate_config.is_empty():
		conditional_skill_unlocks[
			String(summoner_open_gate_config.get("id", "summoner_open_gate"))
		] = true
	summoner_cast_interval = maxf(
		float(summoner_config.get("cast_interval", 1.0)),
		0.0
	)
	summoner_cast_lock_timer = 0.0
	summoner_cast_pending = not summoner_gatekeeper_config.is_empty()
	summoner_scout_cast_pending = not summoner_scout_config.is_empty()
	summoner_hound_cast_pending = not summoner_hound_config.is_empty()
	summoner_watcher_cast_pending = not summoner_watcher_config.is_empty()
	summoner_open_gate_cast_pending = (
		not summoner_open_gate_config.is_empty()
		and summoner_open_gate_unlocked
	)
	summoner_runtime_ready = false
	summoner_basic_effect = null
	summoner_basic_audio = null

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
	gunner_reload_redraw_timer = 0.0
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
	archmage_chain_dagger_active_count = 0
	archmage_chain_multithrow_stacks = 0
	archmage_casting_sequence = false
	archmage_casting_sequence_count = 0
	archmage_multicast_stacks = 0
	archmage_multicast_active = false
	archmage_blink_stacks = 0
	archmage_blink_cooldown_timer = 0.0
	archmage_cooldown_reduction = 0.0
	archmage_mana_overflow_stacks = 0
	archmage_element_cycle_stacks = 0
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
	var raw_purifier_gauge = profile.get("purifier_gauge", {})
	purifier_gauge_config = (
		raw_purifier_gauge.duplicate(true)
		if typeof(raw_purifier_gauge) == TYPE_DICTIONARY
		else {}
	)
	var raw_purifier_protection = purifier_gauge_config.get("protection", {})
	purifier_protection_config = (
		raw_purifier_protection.duplicate(true)
		if typeof(raw_purifier_protection) == TYPE_DICTIONARY
		else {}
	)
	var raw_purifier_crown = profile.get("purifier_crown", {})
	purifier_crown_config = (
		raw_purifier_crown.duplicate(true)
		if typeof(raw_purifier_crown) == TYPE_DICTIONARY
		else {}
	)
	purifier_protection_cooldown = 0.0
	purifier_protection_active = false
	purifier_protection_duration_timer = 0.0
	purifier_protection_tick_timer = 0.0
	purifier_protection_break_triggered = false
	purifier_crown_cooldown = maxf(
		float(purifier_crown_config.get("initial_cooldown", 0.0)),
		0.0
	)
	purifier_crown_stacks = 0
	purifier_crown_duration_timer = 0.0
	purifier_crown_heal_timer = 0.0
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
	base_attack_damage_for_level_growth = maxf(
		float(attack_damage),
		1.0
	)
	passive_attack_growth_accumulator = 0.0
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
	_ensure_purifier_skill_runtime()
	var stage9_anchor_callback := Callable(self, "_on_hero_sprite_frame_or_animation_changed")
	if not hero_sprite.frame_changed.is_connected(stage9_anchor_callback):
		hero_sprite.frame_changed.connect(stage9_anchor_callback)
	if not hero_sprite.animation_changed.is_connected(stage9_anchor_callback):
		hero_sprite.animation_changed.connect(stage9_anchor_callback)
	_apply_stage1_shield_visual()
	_apply_stage1_channel_visual()
	_apply_stage2_rogue_effect_visuals()
	_apply_stage3_fighter_effect_visuals()
	_apply_stage4_gunner_effect_visuals()
	_apply_stage6_berserker_effect_visuals()
	_apply_level_up_effect_visual()
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
	if (
		not level_up_effect.animation_finished.is_connected(
			Callable(self, "_on_level_up_effect_animation_finished")
		)
	):
		level_up_effect.animation_finished.connect(
			Callable(self, "_on_level_up_effect_animation_finished")
		)
	current_hp = max_hp
	exp_to_next_level = _required_exp_for_level(level)
	strafe_sign = -1.0 if randf() < 0.5 else 1.0
	_pick_new_wander_target()
	_refresh_ai_observation()
	health_changed.emit(current_hp, max_hp)
	progression_changed.emit(level, current_exp, exp_to_next_level)
	queue_redraw()

func _apply_level_up_effect_visual() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("level_up")
	frames.set_animation_speed("level_up", 13.5)
	frames.set_animation_loop("level_up", false)

	for frame_index: int in range(1, 7):
		var texture := _load_stage1_texture(
			"res://assets/art/effects/levelup/frames/levelup_%02d.png"
			% frame_index
		)
		if texture != null:
			frames.add_frame("level_up", texture)

	level_up_effect.sprite_frames = frames
	level_up_effect.animation = &"level_up"
	level_up_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	level_up_effect.centered = false
	level_up_effect.offset = Vector2(-192.0, -410.0)
	level_up_effect.scale = Vector2(0.42, 0.42)
	level_up_effect.position = Vector2(0.0, 44.0)
	level_up_effect.z_index = 6
	level_up_effect.visible = false


func _play_level_up_feedback() -> void:
	if (
		level_up_effect.sprite_frames != null
		and level_up_effect.sprite_frames.has_animation("level_up")
		and level_up_effect.sprite_frames.get_frame_count("level_up") > 0
	):
		level_up_effect.stop()
		level_up_effect.frame = 0
		level_up_effect.frame_progress = 0.0
		level_up_effect.visible = true
		level_up_effect.play(&"level_up")

	if is_instance_valid(level_up_audio):
		level_up_audio.stop()
		level_up_audio.play()


func _on_level_up_effect_animation_finished() -> void:
	level_up_effect.visible = false


func _attach_status_effect_visual(effect_type: String) -> void:
	var effect := COMBAT_STATUS_EFFECT_VISUAL.new()
	add_child(effect)
	effect.setup(self, effect_type)


func _physics_process(delta: float) -> void:
	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	_update_hero_hit_flash(delta)
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

	if hero_archetype == "berserker_madness":
		_physics_process_berserker(delta)
		return

	if hero_archetype == "alchemist_chemical":
		_physics_process_alchemist(delta)
		return

	if hero_archetype == "summoner_gatekeeper":
		_physics_process_summoner(delta)
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
	_update_purifier_gauge(delta)
	_update_shield_skill(delta)
	_update_channel_skill(delta)
	if hero_archetype == "archmage_elementalist":
		_update_archmage_skill_runtime(delta)

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
	_update_magnet_item_goal(delta)

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
	move_direction = _apply_magnet_item_steering(move_direction, delta)
	if hero_archetype == "archmage_elementalist":
		move_direction = _apply_archmage_boundary_steering(move_direction)
	else:
		move_direction = _apply_ranged_boundary_escape(move_direction)
	velocity = (
		move_direction
		* move_speed
		* move_multiplier
		* _get_purifier_move_speed_multiplier()
	)
	move_and_slide()
	_clamp_to_battlefield()

	if distance <= attack_range and attack_timer <= 0.0:
		_fire_projectile(target)

	_update_stage1_pose_visual(delta)



func _get_summoner_level_slot_bonus() -> int:
	return HERO_SUMMONER_RUNTIME.get_level_slot_bonus(level)


func _get_summoner_slot_capacity() -> int:
	return HERO_SUMMONER_RUNTIME.get_slot_capacity(
		summoner_slot_base,
		summoner_slot_bonus,
		level
	)


func _get_active_summon_count() -> int:
	return summoner_active_regular_count


func _get_active_summoner_watcher_count() -> int:
	return summoner_active_watchers


func _adjust_summoner_active_count(
	summon_kind: StringName,
	delta: int
) -> void:
	if delta == 0:
		return
	match summon_kind:
		&"gatekeeper":
			summoner_active_gatekeepers = maxi(
				summoner_active_gatekeepers + delta,
				0
			)
		&"scout":
			summoner_active_scouts = maxi(
				summoner_active_scouts + delta,
				0
			)
		&"hound":
			summoner_active_hounds = maxi(
				summoner_active_hounds + delta,
				0
			)
		&"watcher":
			summoner_active_watchers = maxi(
				summoner_active_watchers + delta,
				0
			)
		_:
			return
	summoner_active_regular_count = (
		summoner_active_gatekeepers
		+ summoner_active_scouts
		+ summoner_active_hounds
		+ summoner_active_watchers
	)


func _get_summoner_watcher_max_active() -> int:
	return HERO_SUMMONER_RUNTIME.get_watcher_max_active(
		summoner_watcher_config,
		_get_summoner_augment_stacks("summoner_watcher_network")
	)


func _get_next_summoner_watcher_follow_slot() -> int:
	return HERO_SUMMONER_RUNTIME.get_next_watcher_follow_slot(
		summoner_watcher_pool,
		_get_summoner_watcher_max_active()
	)


func _set_summon_registry_active(
	summon: Node2D,
	is_active: bool
) -> void:
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("set_hero_summon_active")
	):
		battle.call(
			"set_hero_summon_active",
			summon,
			is_active
		)


func _ensure_summoner_pool_capacity() -> void:
	if hero_archetype != "summoner_gatekeeper":
		return
	var world_parent := get_parent()
	if not is_instance_valid(world_parent):
		return

	var pool_size := (
		_get_summoner_slot_capacity()
		+ SUMMONER_POOL_HEADROOM
	)
	HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		summoner_gatekeeper_pool,
		SUMMONER_GATEKEEPER_SCENE,
		pool_size,
		Callable(
			self,
			"_on_summoner_gatekeeper_released"
		)
	)
	HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		summoner_scout_pool,
		SUMMONER_SCOUT_SCENE,
		pool_size,
		Callable(
			self,
			"_on_summoner_scout_released"
		)
	)
	HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		summoner_hound_pool,
		SUMMONER_HOUND_SCENE,
		pool_size,
		Callable(
			self,
			"_on_summoner_hound_released"
		)
	)

	HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		summoner_watcher_pool,
		SUMMONER_WATCHER_SCENE,
		_get_summoner_watcher_max_active(),
		Callable(
			self,
			"_on_summoner_watcher_released"
		)
	)

	var open_gate_pool_size := maxi(
		int(
			summoner_open_gate_config.get(
				"pool_size",
				1
			)
		),
		0
	)
	HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		summoner_open_gate_pool,
		SUMMONER_OPEN_GATE_SCENE,
		open_gate_pool_size,
		Callable(
			self,
			"_on_summoner_open_gate_released"
		),
		&"prepare_pool",
		summoner_open_gate_config
	)


func _ensure_summoner_runtime() -> void:
	if summoner_runtime_ready or hero_archetype != "summoner_gatekeeper":
		return
	var world_parent := get_parent()
	if not is_instance_valid(world_parent):
		return

	_ensure_summoner_pool_capacity()

	summoner_basic_effect = AnimatedSprite2D.new()
	var effect_frames := SpriteFrames.new()
	if effect_frames.has_animation(&"default"):
		effect_frames.remove_animation(&"default")
	effect_frames.add_animation(&"cast")
	effect_frames.set_animation_loop(&"cast", false)
	effect_frames.set_animation_speed(&"cast", 10.0)
	var effect_dir := String(
		summoner_config.get(
			"basic_effect_dir",
			"%s/effect2" % STAGE8_FRAME_DIR
		)
	)
	for frame_index in range(1, 3):
		var texture := _load_stage1_texture(
			"%s/summon_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			effect_frames.add_frame(&"cast", texture)
	summoner_basic_effect.sprite_frames = effect_frames
	summoner_basic_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	summoner_basic_effect.scale = Vector2(0.46, 0.46)
	summoner_basic_effect.position = Vector2(0.0, -18.0)
	summoner_basic_effect.z_index = 7
	summoner_basic_effect.visible = false
	summoner_basic_effect.animation_finished.connect(
		Callable(self, "_on_summoner_basic_effect_finished")
	)
	world_parent.add_child(summoner_basic_effect)

	summoner_basic_audio = AudioStreamPlayer.new()
	summoner_basic_audio.bus = &"SFX"
	summoner_basic_audio.volume_db = -10.0
	var audio_path := String(
		summoner_config.get(
			"basic_attack_audio_path",
			SUMMONER_BASIC_ATTACK_AUDIO_PATH
		)
	)
	if ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream is AudioStream:
			summoner_basic_audio.stream = stream
	add_child(summoner_basic_audio)

	summoner_runtime_ready = (
		HERO_SUMMONER_RUNTIME.are_runtime_pools_ready(
			summoner_gatekeeper_pool,
			summoner_scout_config,
			summoner_scout_pool,
			summoner_hound_config,
			summoner_hound_pool,
			summoner_watcher_config,
			summoner_watcher_pool,
			summoner_open_gate_config,
			summoner_open_gate_pool
		)
	)
	if summoner_runtime_ready:
		# Keep explicit requests alive until a pooled summon is actually acquired.
		summoner_cast_pending = not summoner_gatekeeper_config.is_empty()
		summoner_scout_cast_pending = not summoner_scout_config.is_empty()
		summoner_hound_cast_pending = not summoner_hound_config.is_empty()
		summoner_watcher_cast_pending = not summoner_watcher_config.is_empty()
		summoner_open_gate_cast_pending = (
			not summoner_open_gate_config.is_empty()
			and summoner_open_gate_unlocked
		)
	queue_redraw()


func _physics_process_summoner(delta: float) -> void:
	_ensure_summoner_runtime()

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
	summoner_gatekeeper_cooldown = maxf(
		summoner_gatekeeper_cooldown - delta,
		0.0
	)
	summoner_scout_cooldown = maxf(
		summoner_scout_cooldown - delta,
		0.0
	)
	summoner_hound_cooldown = maxf(
		summoner_hound_cooldown - delta,
		0.0
	)
	summoner_watcher_cooldown = maxf(
		summoner_watcher_cooldown - delta,
		0.0
	)
	summoner_open_gate_cooldown = maxf(
		summoner_open_gate_cooldown - delta,
		0.0
	)
	summoner_cast_lock_timer = maxf(
		summoner_cast_lock_timer - delta,
		0.0
	)
	_update_summoner_full_slot_shield(delta)
	_update_invulnerability(delta)

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if summoner_open_gate_unlocked and summoner_open_gate_cooldown <= 0.0:
		summoner_open_gate_cast_pending = true

	if _get_active_summon_count() < _get_summoner_slot_capacity():
		if summoner_gatekeeper_cooldown <= 0.0:
			summoner_cast_pending = true
		if summoner_scout_cooldown <= 0.0:
			summoner_scout_cast_pending = true
		if summoner_hound_cooldown <= 0.0:
			summoner_hound_cast_pending = true
		if (
			summoner_watcher_cooldown <= 0.0
			and _get_active_summoner_watcher_count()
			< _get_summoner_watcher_max_active()
		):
			summoner_watcher_cast_pending = true

	if summoner_cast_lock_timer <= 0.0:
		var selected_summon := _choose_summoner_ai_cast()
		var summon_casted := _try_cast_summoner_ai_choice(selected_summon)
		if summon_casted:
			summoner_ai_last_choice = selected_summon
			summoner_ai_choice_counts[selected_summon] = (
				int(summoner_ai_choice_counts.get(selected_summon, 0)) + 1
			)
			summoner_cast_lock_timer = summoner_cast_interval

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)
	_update_magnet_item_goal(delta)

	if (
		not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or retarget_timer <= 0.0
	):
		target = _find_nearest_monster()
		retarget_timer = 0.12

	if not is_instance_valid(target):
		_move_summoner_without_monsters_near_open_gate()
		_update_summoner_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_move_direction(target, distance)
	move_direction = _apply_summoner_open_gate_tether(move_direction)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	move_direction = _apply_magnet_item_steering(move_direction, delta)
	move_direction = _apply_ranged_boundary_escape(move_direction)
	velocity = move_direction * move_speed * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

	if distance <= attack_range and attack_timer <= 0.0:
		_summoner_basic_attack(target)

	_update_summoner_pose_visual(delta)


func _roll_summoner_ai_personality() -> String:
	return HERO_SUMMONER_RUNTIME.roll_ai_personality(
		summoner_ai_config
	)


func _get_summoner_target_hp_ratio() -> float:
	return HERO_SUMMONER_RUNTIME.get_target_hp_ratio(target)


func _score_summoner_ai_candidate(
	skill_id: String,
	nearby_count: int
) -> float:
	var hero_hp_ratio := clampf(
		float(current_hp) / float(maxi(max_hp, 1)),
		0.0,
		1.0
	)
	var gatekeepers := summoner_active_gatekeepers
	var scouts := summoner_active_scouts
	var hounds := summoner_active_hounds
	var watchers := summoner_active_watchers
	return HERO_SUMMONER_RUNTIME.score_ai_candidate(
		skill_id,
		nearby_count,
		hero_hp_ratio,
		is_instance_valid(target),
		_get_summoner_target_hp_ratio(),
		gatekeepers,
		scouts,
		hounds,
		watchers,
		_get_active_summon_count(),
		int(summoner_ai_choice_counts.get(skill_id, 0)),
		summoner_ai_last_choice,
		summoner_ai_personality,
		float(
			summoner_ai_config.get(
				"random_score_span",
				8.0
			)
		)
	)


func _choose_summoner_ai_cast() -> String:
	var shared_slot_available := (
		_get_active_summon_count() < _get_summoner_slot_capacity()
	)
	var gatekeeper_available := (
		shared_slot_available
		and summoner_cast_pending
		and summoner_gatekeeper_cooldown <= 0.0
	)
	var scout_available := (
		shared_slot_available
		and summoner_scout_cast_pending
		and summoner_scout_cooldown <= 0.0
	)
	var hound_available := (
		shared_slot_available
		and summoner_hound_cast_pending
		and summoner_hound_cooldown <= 0.0
	)
	var watcher_available := (
		shared_slot_available
		and summoner_watcher_cast_pending
		and summoner_watcher_cooldown <= 0.0
		and _get_active_summoner_watcher_count() < _get_summoner_watcher_max_active()
	)
	var open_gate_available := (
		summoner_open_gate_cast_pending
		and summoner_open_gate_unlocked
		and summoner_open_gate_cooldown <= 0.0
		and not is_instance_valid(_get_active_summoner_open_gate())
	)
	if not (
		gatekeeper_available
		or scout_available
		or hound_available
		or watcher_available
		or open_gate_available
	):
		return ""

	var nearby := _get_monster_nodes_near(
		global_position,
		maxf(float(summoner_ai_config.get("observation_radius", 760.0)), 1.0)
	)
	var nearby_count := nearby.size()
	var gatekeeper_weight := 0.0
	var scout_weight := 0.0
	var hound_weight := 0.0
	var watcher_weight := 0.0
	var open_gate_weight := 0.0
	var total_weight := 0.0

	if gatekeeper_available:
		gatekeeper_weight = pow(
			maxf(_score_summoner_ai_candidate("gatekeeper", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += gatekeeper_weight
	if scout_available:
		scout_weight = pow(
			maxf(_score_summoner_ai_candidate("scout", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += scout_weight
	if hound_available:
		hound_weight = pow(
			maxf(_score_summoner_ai_candidate("hound", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += hound_weight
	if watcher_available:
		watcher_weight = pow(
			maxf(_score_summoner_ai_candidate("watcher", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += watcher_weight
	if open_gate_available:
		open_gate_weight = pow(
			maxf(_score_summoner_ai_candidate("open_gate", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += open_gate_weight

	var roll := randf() * total_weight
	if gatekeeper_available:
		roll -= gatekeeper_weight
		if roll <= 0.0:
			return "gatekeeper"
	if scout_available:
		roll -= scout_weight
		if roll <= 0.0:
			return "scout"
	if hound_available:
		roll -= hound_weight
		if roll <= 0.0:
			return "hound"
	if watcher_available:
		roll -= watcher_weight
		if roll <= 0.0:
			return "watcher"
	if open_gate_available:
		roll -= open_gate_weight
		if roll <= 0.0:
			return "open_gate"

	if open_gate_available:
		return "open_gate"
	if watcher_available:
		return "watcher"
	if hound_available:
		return "hound"
	if scout_available:
		return "scout"
	return "gatekeeper"


func _try_cast_summoner_ai_choice(skill_id: String) -> bool:
	match skill_id:
		"gatekeeper":
			if _try_cast_summoner_gatekeeper():
				summoner_cast_pending = false
				return true
		"scout":
			if _try_cast_summoner_scout():
				summoner_scout_cast_pending = false
				return true
		"hound":
			if _try_cast_summoner_hound():
				summoner_hound_cast_pending = false
				return true
		"watcher":
			if _try_cast_summoner_watcher():
				summoner_watcher_cast_pending = false
				return true
		"open_gate":
			if _try_cast_summoner_open_gate():
				summoner_open_gate_cast_pending = false
				return true
	return false


func _get_active_summoner_open_gate() -> Node2D:
	for open_gate in summoner_open_gate_pool:
		if is_instance_valid(open_gate) and bool(open_gate.get("active")):
			return open_gate
	return null


func _apply_summoner_open_gate_tether(move_direction: Vector2) -> Vector2:
	var open_gate := _get_active_summoner_open_gate()
	if not is_instance_valid(open_gate):
		return move_direction

	var preference_radius := maxf(
		float(summoner_open_gate_config.get("hero_tether_radius", 650.0)),
		1.0
	)
	var influence_radius := maxf(
		float(summoner_open_gate_config.get("hero_tether_hard_radius", 950.0)),
		preference_radius + 1.0
	)
	var distance := global_position.distance_to(open_gate.global_position)
	if distance <= preference_radius:
		return move_direction

	# Gate proximity is only a soft tactical preference. It must never behave
	# like an invisible wall or override a useful combat target.
	var return_direction := global_position.direction_to(open_gate.global_position)
	var distance_factor := clampf(
		(distance - preference_radius) / (influence_radius - preference_radius),
		0.0,
		1.0
	)
	var max_strength := clampf(
		float(summoner_open_gate_config.get("hero_tether_max_strength", 0.28)),
		0.0,
		0.45
	)
	var strength := distance_factor * max_strength
	var blended := move_direction.lerp(return_direction, strength)
	return blended.normalized() if blended.length_squared() > 0.001 else move_direction


func _move_summoner_without_monsters_near_open_gate() -> void:
	# With no combat target, keep the normal wander behaviour. The open gate
	# influences combat positioning but never cages the hero around the portal.
	_move_without_monsters()


func _get_summoner_augment_stacks(augment_id: String) -> int:
	return HERO_SUMMONER_RUNTIME.get_augment_stacks(
		build_counts,
		augment_id
	)


func get_summoner_runtime_attack_speed_multiplier() -> float:
	return HERO_SUMMONER_RUNTIME.get_runtime_attack_speed_multiplier(
		shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_runtime_move_speed_multiplier() -> float:
	return HERO_SUMMONER_RUNTIME.get_runtime_move_speed_multiplier(
		shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_runtime_speed_multipliers() -> Dictionary:
	return HERO_SUMMONER_RUNTIME.get_runtime_speed_multipliers(
		shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_scout_attack_speed_multiplier() -> float:
	return HERO_SUMMONER_RUNTIME.get_scout_swarm_attack_speed_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		summoner_active_scouts
	)


func get_summoner_scout_damage_multiplier() -> float:
	return HERO_SUMMONER_RUNTIME.get_scout_swarm_damage_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		summoner_active_scouts
	)


func get_summoner_scout_move_speed_multiplier() -> float:
	return HERO_SUMMONER_RUNTIME.get_scout_swarm_move_speed_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		summoner_active_scouts
	)


func get_summoner_scout_swarm_multipliers() -> Dictionary:
	return HERO_SUMMONER_RUNTIME.get_scout_swarm_multipliers(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		summoner_active_scouts
	)


func _extend_regular_summon_durations(seconds: float) -> void:
	HERO_SUMMONER_RUNTIME.extend_regular_summon_durations(
		seconds,
		summoner_gatekeeper_pool,
		summoner_scout_pool,
		summoner_hound_pool,
		summoner_watcher_pool
	)


func _update_summoner_full_slot_shield(delta: float) -> void:
	if summoner_full_slot_shield_config.is_empty():
		return

	summoner_full_slot_shield_cooldown = maxf(
		summoner_full_slot_shield_cooldown - delta,
		0.0
	)

	if shield_duration_timer > 0.0:
		shield_duration_timer = maxf(shield_duration_timer - delta, 0.0)
		if shield_duration_timer <= 0.0 and shield_hp > 0.0:
			_end_shield()

	if summoner_full_slot_shield_cooldown > 0.0:
		return
	if _get_active_summon_count() < _get_summoner_slot_capacity():
		return

	var shield_fortify_stacks := _get_summoner_augment_stacks("summoner_shield_fortify")
	var shield_ratio := clampf(
		float(summoner_full_slot_shield_config.get("shield_hp_ratio", 0.15))
		+ float(shield_fortify_stacks) * 0.014,
		0.0,
		1.0
	)
	var refreshed_shield := float(max_hp) * shield_ratio
	if refreshed_shield <= 0.0:
		return

	# Refresh-type passive: replace remaining shield amount and duration.
	shield_max_hp = refreshed_shield
	shield_hp = refreshed_shield
	shield_duration_timer = maxf(
		float(summoner_full_slot_shield_config.get("duration", 8.0))
		+ float(shield_fortify_stacks) * 0.4,
		0.0
	)
	summoner_full_slot_shield_cooldown = maxf(
		float(summoner_full_slot_shield_config.get("cooldown", 40.0)),
		0.0
	)
	queue_redraw()


func _refresh_regular_summon_pending_after_release(
	summon: Node2D
) -> void:
	_set_summon_registry_active(summon, false)
	var pending_mask := HERO_SUMMONER_RUNTIME.get_release_pending_mask(
		summoner_gatekeeper_cooldown,
		summoner_scout_cooldown,
		summoner_hound_cooldown,
		summoner_watcher_cooldown,
		_get_active_summoner_watcher_count(),
		_get_summoner_watcher_max_active()
	)
	if (
		pending_mask
		& HERO_SUMMONER_RUNTIME.PENDING_GATEKEEPER
	):
		summoner_cast_pending = true
	if pending_mask & HERO_SUMMONER_RUNTIME.PENDING_SCOUT:
		summoner_scout_cast_pending = true
	if pending_mask & HERO_SUMMONER_RUNTIME.PENDING_HOUND:
		summoner_hound_cast_pending = true
	if pending_mask & HERO_SUMMONER_RUNTIME.PENDING_WATCHER:
		summoner_watcher_cast_pending = true
	queue_redraw()


func _try_cast_summoner_gatekeeper() -> bool:
	if summoner_gatekeeper_config.is_empty():
		return false
	if summoner_gatekeeper_cooldown > 0.0:
		return false
	if _get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			summoner_gatekeeper_pool
		)
	)
	if summon_to_use == null:
		return false

	var runtime_config := (
		HERO_SUMMONER_RUNTIME.build_gatekeeper_runtime_config(
			summoner_gatekeeper_config,
			attack_damage,
			_get_summoner_augment_stacks(
				"summoner_gatekeeper_fortress"
			),
			_get_summoner_augment_stacks(
				"summoner_gatekeeper_barrage"
			)
		)
	)
	if not HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		global_position,
		self,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"gatekeeper", 1)
	_set_summon_registry_active(summon_to_use, true)
	summoner_gatekeeper_cooldown = maxf(
		float(summoner_gatekeeper_config.get("cooldown", 10.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	queue_redraw()
	return true


func _on_summoner_gatekeeper_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"gatekeeper", -1)
	_refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_scout() -> bool:
	if summoner_scout_config.is_empty():
		return false
	if summoner_scout_cooldown > 0.0:
		return false
	if _get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			summoner_scout_pool
		)
	)
	if summon_to_use == null:
		_ensure_summoner_pool_capacity()
		summon_to_use = (
			HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
				summoner_scout_pool
			)
		)
	if summon_to_use == null:
		return false

	var runtime_config := (
		HERO_SUMMONER_RUNTIME.build_scout_runtime_config(
			summoner_scout_config,
			attack_damage,
			_get_summoner_augment_stacks(
				"summoner_scout_reinforcement"
			)
		)
	)
	if not HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		global_position,
		self,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"scout", 1)
	_set_summon_registry_active(summon_to_use, true)
	summoner_scout_cooldown = maxf(
		float(summoner_scout_config.get("cooldown", 20.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	queue_redraw()
	return true


func _on_summoner_scout_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"scout", -1)
	_refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_hound() -> bool:
	if summoner_hound_config.is_empty():
		return false
	if summoner_hound_cooldown > 0.0:
		return false
	if _get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			summoner_hound_pool
		)
	)
	if summon_to_use == null:
		_ensure_summoner_pool_capacity()
		summon_to_use = (
			HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
				summoner_hound_pool
			)
		)
	if summon_to_use == null:
		return false

	var runtime_config := (
		HERO_SUMMONER_RUNTIME.build_hound_runtime_config(
			summoner_hound_config,
			attack_damage,
			_get_summoner_augment_stacks(
				"summoner_hound_frenzy"
			),
			_get_summoner_augment_stacks(
				"summoner_hound_blood_track"
			)
		)
	)
	if not HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		global_position,
		self,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"hound", 1)
	_set_summon_registry_active(summon_to_use, true)
	summoner_hound_cooldown = maxf(
		float(summoner_hound_config.get("cooldown", 30.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	queue_redraw()
	return true


func _on_summoner_hound_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"hound", -1)
	_refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_watcher() -> bool:
	if summoner_watcher_config.is_empty():
		return false
	if summoner_watcher_cooldown > 0.0:
		return false
	if _get_active_summon_count() >= _get_summoner_slot_capacity():
		return false
	if (
		_get_active_summoner_watcher_count()
		>= _get_summoner_watcher_max_active()
	):
		return false

	var follow_slot := _get_next_summoner_watcher_follow_slot()
	if follow_slot < 0:
		return false

	var summon_to_use := (
		HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			summoner_watcher_pool
		)
	)
	if summon_to_use == null:
		return false

	var runtime_config := (
		HERO_SUMMONER_RUNTIME.build_watcher_runtime_config(
			summoner_watcher_config,
			attack_damage,
			_get_summoner_augment_stacks(
				"summoner_watcher_focus"
			),
			_get_summoner_augment_stacks(
				"summoner_watcher_network"
			),
			follow_slot
		)
	)
	if not HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		global_position,
		self,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"watcher", 1)
	_set_summon_registry_active(summon_to_use, true)
	summoner_watcher_cooldown = maxf(
		float(summoner_watcher_config.get("cooldown", 7.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	queue_redraw()
	return true


func _on_summoner_watcher_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"watcher", -1)
	_refresh_regular_summon_pending_after_release(_summon)


func _get_summoner_open_gate_required_summons() -> int:
	return HERO_SUMMONER_RUNTIME.get_open_gate_required_summons(
		summoner_open_gate_config
	)


func _record_summoner_spawn_for_open_gate_unlock() -> void:
	if summoner_open_gate_config.is_empty() or summoner_open_gate_unlocked:
		return
	summoner_total_summons += 1
	var required := _get_summoner_open_gate_required_summons()
	if not HERO_SUMMONER_RUNTIME.has_reached_open_gate_unlock(
		summoner_open_gate_config,
		summoner_open_gate_unlocked,
		summoner_total_summons
	):
		return

	summoner_open_gate_unlocked = true
	summoner_open_gate_cast_pending = true
	_unlock_conditional_skill(
		String(summoner_open_gate_config.get("id", "summoner_open_gate")),
		String(summoner_open_gate_config.get("name", "이계의 문 - 개방")),
		"summon_count",
		summoner_total_summons,
		required,
		{
			"hero_id": hero_id,
			"archetype": hero_archetype,
			"source": "summoner_spawn_count",
			"cutscene_texture_path": String(
				summoner_open_gate_config.get("cutscene_texture_path", "")
			),
			"cutscene_hold_seconds": float(
				summoner_open_gate_config.get("cutscene_hold_seconds", 1.05)
			),
		}
	)


func _try_cast_summoner_open_gate() -> bool:
	if summoner_open_gate_config.is_empty():
		return false
	if not summoner_open_gate_unlocked:
		return false
	if summoner_open_gate_cooldown > 0.0:
		return false

	var gate_to_use := (
		HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			summoner_open_gate_pool
		)
	)
	if gate_to_use == null:
		return false

	if not HERO_SUMMONER_RUNTIME.activate_summon(
		gate_to_use,
		global_position,
		self,
		summoner_open_gate_config.duplicate(true)
	):
		return false
	_set_summon_registry_active(gate_to_use, true)
	summoner_open_gate_cooldown = maxf(
		float(summoner_open_gate_config.get("cooldown", 100.0)),
		0.0
	)
	queue_redraw()
	return true


func _on_summoner_open_gate_released(_open_gate: Node2D) -> void:
	_set_summon_registry_active(_open_gate, false)
	if summoner_open_gate_cooldown <= 0.0:
		summoner_open_gate_cast_pending = true
	queue_redraw()


func _summoner_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.38
	_face_attack_direction(
		current_target.global_position.x - global_position.x
	)
	_apply_stage8_sprite_anchor()
	_restart_stage1_animation("attack", 1.0)

	if is_instance_valid(summoner_basic_effect):
		# effect2 summon_01~02 is impact feedback for this hitscan attack.
		# Keep it in world space at the monster's feet/root instead of on caster.
		summoner_basic_effect.global_position = current_target.global_position
		summoner_basic_effect.flip_h = false
		summoner_basic_effect.stop()
		summoner_basic_effect.frame = 0
		summoner_basic_effect.visible = true
		summoner_basic_effect.play(&"cast")
	if (
		is_instance_valid(summoner_basic_audio)
		and summoner_basic_audio.stream != null
	):
		summoner_basic_audio.stop()
		summoner_basic_audio.play()

	# Hitscan: damage is decided immediately; the summon_01~02 frames are
	# feedback only, keeping combat state easy to make server-authoritative.
	if current_target.has_method("take_damage"):
		current_target.call("take_damage", maxi(attack_damage, 1))


func _on_summoner_basic_effect_finished() -> void:
	if is_instance_valid(summoner_basic_effect):
		summoner_basic_effect.visible = false


func _update_summoner_pose_visual(delta: float) -> void:
	if not hero_sprite.visible or is_dying:
		return
	if hit_pose_timer > 0.0 or attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)
	_apply_stage8_sprite_anchor()
	if velocity.length() > 4.0:
		var movement_ratio := velocity.length() / maxf(move_speed, 1.0)
		_play_stage1_animation(
			"move",
			clampf(movement_ratio, 0.72, 1.35)
		)
	else:
		_play_stage1_animation("idle", 1.0)



func _physics_process_alchemist(delta: float) -> void:
	_ensure_alchemist_runtime()

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
	_update_invulnerability(delta)
	alchemist_equivalent_exchange_damage_reduction_timer = maxf(
		alchemist_equivalent_exchange_damage_reduction_timer - delta,
		0.0
	)
	_update_alchemist_material_spawning(delta)
	_collect_nearby_alchemy_materials()
	alchemist_mixture_field_cooldown = maxf(alchemist_mixture_field_cooldown - delta, 0.0)
	alchemist_mystery_cauldron_cooldown = maxf(
		alchemist_mystery_cauldron_cooldown - delta,
		0.0
	)
	alchemist_emergency_cooldown = maxf(
		alchemist_emergency_cooldown - delta,
		0.0
	)
	_update_alchemist_philosopher_gas_regen(delta)
	if (
		bool(alchemist_philosopher_config.get("test_mode", false))
		and not alchemist_philosopher_used
		and not alchemist_philosopher_channeling
		and not alchemist_transformed
	):
		alchemist_philosopher_test_timer = maxf(
			alchemist_philosopher_test_timer - delta,
			0.0
		)

	if _update_alchemist_philosopher_channel(delta):
		return
	if _try_start_alchemist_philosopher_stone():
		return

	# A pre-transformation vial burst may already be queued. Once the stone
	# is active, basic vial attacks are permanently disabled for this run.
	if not alchemist_transformed:
		_update_alchemist_throw_sequence(delta)

	_update_alchemist_mixture_field_hero_effects(delta)
	_update_alchemist_field_locomotion_state(delta)
	if _update_alchemist_emergency_escape(delta):
		_update_alchemist_pose_visual(delta)
		return
	_try_cast_alchemist_mixture_field()
	_try_cast_alchemist_mystery_cauldron()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if alchemist_transformed:
		_move_alchemist_philosopher_form(delta)
		_update_alchemist_pose_visual(delta)
		return

	var alchemist_move_speed := move_speed * _get_alchemist_field_speed_multiplier()
	var basic_gas_cost := maxf(float(alchemist_config.get("basic_gas_cost", 10.0)), 0.0)
	if alchemist_gas + 0.001 < basic_gas_cost:
		var material_target := _find_nearest_active_alchemy_material()
		if is_instance_valid(material_target):
			var material_direction := global_position.direction_to(material_target.global_position)
			var recovery_direction := material_direction
			var nearest_threat := _find_nearest_monster()
			if is_instance_valid(nearest_threat):
				var threat_distance := global_position.distance_to(nearest_threat.global_position)
				if threat_distance < kite_distance:
					var escape_direction := _choose_move_direction(
						nearest_threat,
						threat_distance
					)
					if escape_direction.length_squared() > 0.01:
						recovery_direction = (
							material_direction * 0.55
							+ escape_direction * 1.25
						).normalized()
			recovery_direction = _apply_ranged_boundary_escape(recovery_direction)
			velocity = recovery_direction * alchemist_move_speed * move_multiplier
			move_and_slide()
			_clamp_to_battlefield()
			_update_alchemist_pose_visual(delta)
			return

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)
	_update_magnet_item_goal(delta)

	if not is_instance_valid(target) or target.is_queued_for_deletion() or retarget_timer <= 0.0:
		target = _find_nearest_monster()
		retarget_timer = 0.12

	if not is_instance_valid(target):
		_move_without_monsters()
		_update_alchemist_pose_visual(delta)
		return

	var distance := global_position.distance_to(target.global_position)
	var move_direction := _choose_move_direction(target, distance)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	move_direction = _apply_magnet_item_steering(move_direction, delta)
	move_direction = _apply_ranged_boundary_escape(move_direction)
	velocity = move_direction * alchemist_move_speed * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

	if (
		distance <= attack_range
		and attack_timer <= 0.0
		and alchemist_throw_index >= alchemist_throw_positions.size()
	):
		_start_alchemist_basic_attack(_get_alchemist_chest_attack_target())

	_update_alchemist_pose_visual(delta)

func _ensure_alchemist_runtime() -> void:
	if alchemist_runtime_ready or hero_archetype != "alchemist_chemical":
		return
	var world_parent := get_parent()
	if not is_instance_valid(world_parent):
		return

	# Base attack can reach 6 vials with Chemical Support. Keep enough pooled
	# projectiles for overlapping volleys so bonus vials are never dropped.
	for _index in range(16):
		var vial := ALCHEMIST_VIAL_SCENE.instantiate() as Node2D
		if vial == null:
			continue
		world_parent.add_child(vial)
		vial.connect("landed", Callable(self, "_on_alchemist_vial_landed"))
		alchemist_vial_pool.append(vial)

	for _index in range(28):
		var poison := ALCHEMIST_POISON_POOL_SCENE.instantiate() as Node2D
		if poison == null:
			continue
		world_parent.add_child(poison)
		poison.connect("damage_tick", Callable(self, "_on_alchemist_poison_tick"))
		alchemist_poison_pool.append(poison)

	var max_materials := clampi(int(alchemist_config.get("material_max_count", 10)), 1, 10)
	for _index in range(max_materials):
		var material := ALCHEMY_MATERIAL_SCENE.instantiate() as Node2D
		if material == null:
			continue
		world_parent.add_child(material)
		alchemist_material_pool.append(material)

	var cauldron_count: int = clampi(
		int(alchemist_mystery_cauldron_config.get("max_active", 2)) + 3,
		1,
		5
	)
	for _index in range(cauldron_count):
		var cauldron := ALCHEMIST_CAULDRON_SCENE.instantiate() as Node2D
		if cauldron == null:
			continue
		world_parent.add_child(cauldron)
		cauldron.connect(
			"mix_completed",
			Callable(self, "_on_alchemist_cauldron_completed")
		)
		alchemist_cauldrons.append(cauldron)

	alchemist_mixture_field = ALCHEMIST_MIXTURE_FIELD_SCENE.instantiate() as Node2D
	if is_instance_valid(alchemist_mixture_field):
		world_parent.add_child(alchemist_mixture_field)
		alchemist_mixture_field.connect(
			"field_tick",
			Callable(self, "_on_alchemist_mixture_field_tick")
		)

	alchemist_runtime_ready = true
	alchemist_material_spawn_timer = 0.0
	var initial_count := clampi(
		int(alchemist_config.get("initial_material_count", 6)),
		0,
		alchemist_material_pool.size()
	)
	for _index in range(initial_count):
		_spawn_one_alchemy_material()


func _update_alchemist_material_spawning(delta: float) -> void:
	if not alchemist_runtime_ready:
		return
	alchemist_material_spawn_timer = maxf(alchemist_material_spawn_timer - delta, 0.0)
	if alchemist_material_spawn_timer > 0.0:
		return

	var active_count := _count_active_alchemy_materials()
	var max_count := mini(
		clampi(int(alchemist_config.get("material_max_count", 10)), 1, 10),
		alchemist_material_pool.size()
	)
	if active_count >= max_count:
		alchemist_material_spawn_timer = 0.75
		return

	_spawn_one_alchemy_material()
	var gas_ratio := alchemist_gas / maxf(alchemist_gas_max, 1.0)
	if gas_ratio <= 0.001 and active_count < 3:
		alchemist_material_spawn_timer = maxf(
			float(alchemist_config.get("empty_spawn_interval", 0.8)),
			0.25
		)
	elif gas_ratio <= 0.30:
		alchemist_material_spawn_timer = maxf(
			float(alchemist_config.get("low_gas_spawn_interval", 2.0)),
			0.5
		)
	else:
		alchemist_material_spawn_timer = maxf(
			float(alchemist_config.get("material_spawn_interval", 4.0)),
			0.75
		)


func _count_active_alchemy_materials() -> int:
	var count := 0
	for material in alchemist_material_pool:
		if is_instance_valid(material) and bool(material.get("active")):
			count += 1
	return count


func _spawn_one_alchemy_material() -> void:
	var material_to_spawn: Node2D = null
	for material in alchemist_material_pool:
		if is_instance_valid(material) and not bool(material.get("active")):
			material_to_spawn = material
			break
	if material_to_spawn == null:
		return

	var max_radius := maxf(float(alchemist_config.get("material_spawn_radius", 1500.0)), 100.0)
	var min_radius := clampf(
		float(alchemist_config.get("material_spawn_min_radius", 480.0)),
		0.0,
		max_radius
	)
	var angle := randf() * TAU
	var radius_sq := lerpf(min_radius * min_radius, max_radius * max_radius, randf())
	var radius := sqrt(maxf(radius_sq, 0.0))
	var spawn_position := global_position + Vector2.from_angle(angle) * radius
	var margin := 72.0
	spawn_position.x = clampf(spawn_position.x, margin, battlefield_size.x - margin)
	spawn_position.y = clampf(spawn_position.y, margin, battlefield_size.y - margin)
	material_to_spawn.call(
		"activate",
		spawn_position,
		maxf(float(alchemist_config.get("gas_per_material", 20.0)), 0.0)
	)


func _collect_nearby_alchemy_materials() -> void:
	var pickup_radius := maxf(float(alchemist_config.get("material_pickup_radius", 72.0)), 1.0)
	var pickup_radius_sq := pickup_radius * pickup_radius
	_collect_alchemy_material_list(alchemist_material_pool, pickup_radius_sq)
	_collect_alchemy_material_list(alchemist_bonus_materials, pickup_radius_sq)

	var valid_bonus: Array[Node2D] = []
	for material in alchemist_bonus_materials:
		if is_instance_valid(material) and not material.is_queued_for_deletion():
			valid_bonus.append(material)
	alchemist_bonus_materials = valid_bonus


func _collect_alchemy_material_list(
	materials: Array[Node2D],
	pickup_radius_sq: float
) -> void:
	for material in materials:
		if not is_instance_valid(material) or not bool(material.get("active")):
			continue
		if bool(material.get("in_flight")):
			continue
		if global_position.distance_squared_to(material.global_position) > pickup_radius_sq:
			continue
		var gas_value := float(material.get("gas_value"))
		material.call("deactivate")
		var required_materials := maxi(
			int(alchemist_philosopher_config.get("required_materials", 20)),
			1
		)
		alchemist_materials_collected = mini(
			alchemist_materials_collected + 1,
			required_materials
		)
		_check_alchemist_philosopher_unlock()
		_add_alchemist_gas(gas_value)


func _find_nearest_active_alchemy_material() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF
	for materials in [alchemist_material_pool, alchemist_bonus_materials]:
		for material in materials:
			if not is_instance_valid(material) or not bool(material.get("active")):
				continue
			if bool(material.get("in_flight")):
				continue
			var distance_sq := global_position.distance_squared_to(material.global_position)
			if distance_sq < nearest_distance_sq:
				nearest_distance_sq = distance_sq
				nearest = material
	return nearest


func _add_alchemist_gas(amount: float) -> void:
	if amount <= 0.0:
		return
	alchemist_gas = minf(alchemist_gas + amount, alchemist_gas_max)
	queue_redraw()


func _consume_alchemist_gas(amount: float) -> bool:
	var cost := maxf(amount, 0.0)
	if alchemist_gas + 0.001 < cost:
		return false
	alchemist_gas = maxf(alchemist_gas - cost, 0.0)
	queue_redraw()
	return true


func _get_alchemist_augment_stacks(augment_id: String) -> int:
	return maxi(int(build_counts.get(augment_id, 0)), 0)


func _get_alchemist_compressed_range_multiplier() -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_compressed_gas")
	return maxf(1.0 - 0.10 * float(stacks), 0.50)


func _get_alchemist_compressed_damage_multiplier() -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_compressed_gas")
	return 1.0 + 0.088 * float(stacks)


func _get_alchemist_speed_gap_damage_multiplier(monster: Node) -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_quick_decision")
	if stacks <= 0 or not is_instance_valid(monster):
		return 1.0
	var monster_speed_value = monster.get("move_speed")
	if monster_speed_value == null:
		return 1.0
	var speed_gap := absf(move_speed - float(monster_speed_value))
	var gap_steps := int(floor(speed_gap / 20.0))
	return 1.0 + float(gap_steps * stacks) * 0.01


func _get_alchemist_equivalent_exchange_data(stacks: int) -> Dictionary:
	match clampi(stacks, 1, 5):
		1:
			return {"hp_cost_ratio": 0.03, "damage_multiplier": 1.20, "range_multiplier": 1.00, "material_refund_chance": 0.0, "damage_reduction": 0.0}
		2:
			return {"hp_cost_ratio": 0.025, "damage_multiplier": 1.35, "range_multiplier": 1.00, "material_refund_chance": 0.20, "damage_reduction": 0.0}
		3:
			return {"hp_cost_ratio": 0.02, "damage_multiplier": 1.50, "range_multiplier": 1.15, "material_refund_chance": 0.35, "damage_reduction": 0.0}
		4:
			return {"hp_cost_ratio": 0.015, "damage_multiplier": 1.70, "range_multiplier": 1.25, "material_refund_chance": 0.50, "damage_reduction": 0.10}
		_:
			return {"hp_cost_ratio": 0.01, "damage_multiplier": 2.00, "range_multiplier": 1.35, "material_refund_chance": 0.70, "damage_reduction": 0.20}


func _get_alchemist_equivalent_damage_multiplier() -> float:
	if not alchemist_equivalent_exchange_active:
		return 1.0
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return 1.0
	return float(_get_alchemist_equivalent_exchange_data(stacks).get("damage_multiplier", 1.0))


func _get_alchemist_equivalent_range_multiplier() -> float:
	if not alchemist_equivalent_exchange_active:
		return 1.0
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return 1.0
	return float(_get_alchemist_equivalent_exchange_data(stacks).get("range_multiplier", 1.0))


func _try_pay_alchemist_equivalent_exchange(required_materials: int) -> bool:
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return false
	if alchemist_materials_collected >= required_materials:
		return true
	if current_hp <= int(ceil(float(max_hp) * 0.20)):
		return false

	var missing := maxi(required_materials - alchemist_materials_collected, 0)
	if missing <= 0:
		return true
	var data := _get_alchemist_equivalent_exchange_data(stacks)
	var hp_cost := maxi(
		1,
		int(ceil(
			float(current_hp)
			* float(data.get("hp_cost_ratio", 0.03))
			* float(missing)
		))
	)
	alchemist_equivalent_exchange_paid_hp = mini(hp_cost, current_hp - 1)
	current_hp = maxi(current_hp - alchemist_equivalent_exchange_paid_hp, 1)
	alchemist_materials_collected = required_materials
	alchemist_equivalent_exchange_active = true
	if float(data.get("damage_reduction", 0.0)) > 0.0:
		alchemist_equivalent_exchange_damage_reduction_timer = 3.0
	health_changed.emit(current_hp, max_hp)
	queue_redraw()
	return true


func _on_alchemist_equivalent_exchange_kill() -> void:
	if not alchemist_equivalent_exchange_active:
		return
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return
	var data := _get_alchemist_equivalent_exchange_data(stacks)
	var refund_chance := float(data.get("material_refund_chance", 0.0))
	if refund_chance > 0.0 and randf() < refund_chance:
		var required := maxi(
			int(alchemist_philosopher_config.get("required_materials", 20)),
			1
		)
		alchemist_materials_collected = mini(alchemist_materials_collected + 1, required)
	if stacks >= 5 and alchemist_equivalent_exchange_paid_hp > 0:
		var heal_amount := int(round(float(alchemist_equivalent_exchange_paid_hp) * 0.50))
		current_hp = mini(current_hp + maxi(heal_amount, 1), max_hp)
		alchemist_equivalent_exchange_paid_hp = 0
		health_changed.emit(current_hp, max_hp)


func _deal_alchemist_dot_damage(monster: Node, base_damage: int) -> void:
	if not is_instance_valid(monster) or not monster.has_method("take_damage"):
		return
	var before_hp_value = monster.get("current_hp")
	var before_hp := int(before_hp_value) if before_hp_value != null else -1
	var multiplier := (
		_get_alchemist_compressed_damage_multiplier()
		* _get_alchemist_speed_gap_damage_multiplier(monster)
	)
	var final_damage := maxi(1, int(round(float(base_damage) * multiplier)))
	monster.call("take_damage", final_damage)
	if before_hp > 0:
		var after_hp_value = monster.get("current_hp")
		if after_hp_value != null and int(after_hp_value) <= 0:
			_on_alchemist_equivalent_exchange_kill()


func _get_alchemist_mystery_cauldron_cooldown_total() -> float:
	var base := _get_alchemist_effective_cooldown(
		alchemist_mystery_cauldron_config,
		20.0
	)
	var stacks := _get_alchemist_augment_stacks("alchemist_quick_preparation")
	return base * maxf(1.0 - 0.10 * float(stacks), 0.10)


func _get_alchemist_effective_cooldown(
	config: Dictionary,
	fallback: float
) -> float:
	var base_cooldown := maxf(float(config.get("cooldown", fallback)), 0.0)
	if not alchemist_transformed:
		return base_cooldown
	return (
		base_cooldown
		* clampf(
			float(alchemist_philosopher_config.get(
				"skill_cooldown_multiplier",
				0.70
			)),
			0.05,
			1.0
		)
	)


func _check_alchemist_philosopher_unlock() -> void:
	if alchemist_philosopher_config.is_empty():
		return
	var required := maxi(
		int(alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	if alchemist_materials_collected < required:
		return
	_unlock_conditional_skill(
		String(alchemist_philosopher_config.get(
			"id",
			"alchemist_philosopher_stone"
		)),
		String(alchemist_philosopher_config.get("name", "현자의 돌")),
		"material_count",
		alchemist_materials_collected,
		required,
		{
			"hero_id": hero_id,
			"archetype": hero_archetype,
			"source": "alchemist_material_collection",
		}
	)


func _unlock_conditional_skill(
	skill_id: String,
	skill_name: String,
	condition_type: String,
	current_value: int,
	required_value: int,
	extra_payload: Dictionary = {}
) -> void:
	if skill_id.is_empty() or bool(conditional_skill_unlocks.get(skill_id, false)):
		return

	conditional_skill_unlocks[skill_id] = true
	var payload := extra_payload.duplicate(true)
	payload["condition_type"] = condition_type
	payload["current_value"] = current_value
	payload["required_value"] = required_value
	payload["skill_id"] = skill_id
	payload["skill_name"] = skill_name
	conditional_skill_unlocked.emit(skill_id, skill_name, payload)


func is_conditional_skill_unlocked(skill_id: String) -> bool:
	return bool(conditional_skill_unlocks.get(skill_id, false))


func get_conditional_skill_unlock_state() -> Dictionary:
	return conditional_skill_unlocks.duplicate(true)


func _try_start_alchemist_philosopher_stone() -> bool:
	if (
		alchemist_philosopher_config.is_empty()
		or alchemist_philosopher_used
		or alchemist_philosopher_channeling
		or alchemist_transformed
	):
		return false

	var required_materials := maxi(
		int(alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var test_ready := (
		bool(alchemist_philosopher_config.get("test_mode", false))
		and alchemist_philosopher_test_timer <= 0.0
	)
	# Philosopher's Stone is a strict collection milestone. Equivalent Exchange
	# may substitute materials for normal alchemy, but it must never synthesize
	# the 20/20 Stone progress or trigger the transformation early.
	if not test_ready and alchemist_materials_collected < required_materials:
		return false

	var gas_cost := maxf(
		float(alchemist_philosopher_config.get("gas_cost", 100.0)),
		0.0
	)
	if alchemist_gas + 0.001 < gas_cost:
		return false
	if not _consume_alchemist_gas(gas_cost):
		return false

	alchemist_philosopher_used = true
	alchemist_philosopher_channeling = true
	var fps := maxf(
		float(alchemist_philosopher_config.get("channel_fps", 8.0)),
		1.0
	)
	alchemist_philosopher_channel_timer = 12.0 / fps
	velocity = Vector2.ZERO
	alchemist_throw_positions.clear()
	alchemist_throw_index = 0
	alchemist_throw_timer = 0.0
	alchemist_direct_chest_target = null

	if is_instance_valid(hero_sprite):
		hero_sprite.visible = false
		channel_hid_hero_sprite = true
	if (
		is_instance_valid(channel_effect)
		and channel_effect.sprite_frames != null
		and channel_effect.sprite_frames.has_animation("philosopher_stone")
	):
		channel_effect.stop()
		channel_effect.frame = 0
		channel_effect.frame_progress = 0.0
		channel_effect.visible = true
		channel_effect.play(&"philosopher_stone")
	return true


func _update_alchemist_philosopher_channel(delta: float) -> bool:
	if not alchemist_philosopher_channeling:
		return false

	velocity = Vector2.ZERO
	alchemist_philosopher_channel_timer = maxf(
		alchemist_philosopher_channel_timer - delta,
		0.0
	)
	if alchemist_philosopher_channel_timer > 0.0:
		return true

	alchemist_philosopher_channeling = false
	if is_instance_valid(channel_effect):
		channel_effect.stop()
		channel_effect.visible = false
	if channel_hid_hero_sprite and is_instance_valid(hero_sprite) and not is_dying:
		hero_sprite.visible = true
	channel_hid_hero_sprite = false
	_activate_alchemist_philosopher_form()
	return true


func _activate_alchemist_philosopher_form() -> void:
	if alchemist_transformed:
		return
	alchemist_transformed = true

	var hp_multiplier := maxf(
		float(alchemist_philosopher_config.get("hp_multiplier", 1.50)),
		1.0
	)
	var attack_multiplier := maxf(
		float(alchemist_philosopher_config.get("attack_multiplier", 1.50)),
		1.0
	)
	var speed_multiplier := maxf(
		float(alchemist_philosopher_config.get("move_speed_multiplier", 1.22)),
		1.0
	)
	max_hp = maxi(1, int(round(float(max_hp) * hp_multiplier)))
	current_hp = clampi(
		int(round(float(current_hp) * hp_multiplier)),
		1,
		max_hp
	)
	attack_damage = maxi(
		1,
		int(round(float(attack_damage) * attack_multiplier))
	)
	base_attack_damage_for_level_growth *= attack_multiplier
	move_speed *= speed_multiplier

	var cooldown_multiplier := clampf(
		float(alchemist_philosopher_config.get(
			"skill_cooldown_multiplier",
			0.70
		)),
		0.05,
		1.0
	)
	alchemist_mixture_field_cooldown *= cooldown_multiplier
	alchemist_mystery_cauldron_cooldown *= cooldown_multiplier
	alchemist_emergency_cooldown *= cooldown_multiplier

	alchemist_gas_regen_timer = maxf(
		float(alchemist_philosopher_config.get("gas_regen_interval", 5.0)),
		0.1
	)
	alchemist_poison_trail_timer = 0.0
	alchemist_poison_trail_last_position = global_position
	alchemist_poison_trail_has_position = true
	target = null
	attack_timer = 0.0
	attack_pose_timer = 0.0

	health_changed.emit(current_hp, max_hp)
	queue_redraw()
	if is_instance_valid(alchemist_philosopher_audio):
		alchemist_philosopher_audio.stop()
		alchemist_philosopher_audio.play()


func _update_alchemist_philosopher_gas_regen(delta: float) -> void:
	if not alchemist_transformed:
		return
	alchemist_gas_regen_timer -= delta
	if alchemist_gas_regen_timer > 0.0:
		return

	var interval := maxf(
		float(alchemist_philosopher_config.get("gas_regen_interval", 5.0)),
		0.1
	)
	var amount := maxf(
		float(alchemist_philosopher_config.get("gas_regen_amount", 10.0)),
		0.0
	)
	_add_alchemist_gas(amount)
	alchemist_gas_regen_timer += interval


func _move_alchemist_philosopher_form(delta: float) -> void:
	if (
		wander_timer <= 0.0
		or global_position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE * WANDER_REACHED_DISTANCE
	):
		_pick_new_wander_target()

	var desired := global_position.direction_to(wander_target)
	var sense_radius := maxf(ai_sense_radius, 520.0)
	var repulsion := Vector2.ZERO
	var sense_radius_sq := sense_radius * sense_radius
	for node in _get_monster_nodes_near(global_position, sense_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := global_position - monster.global_position
		var distance_sq := offset.length_squared()
		if distance_sq <= 0.01 or distance_sq > sense_radius_sq:
			continue
		var distance := sqrt(distance_sq)
		var pressure := 1.0 - clampf(distance / sense_radius, 0.0, 1.0)
		repulsion += offset / distance * (0.35 + pressure * pressure * 2.4)

	if repulsion.length_squared() > 0.01:
		desired = desired * 0.55 + repulsion * 1.55

	var soft_margin := 330.0
	var inward := Vector2.ZERO
	var left_space := global_position.x - FIELD_MARGIN
	var right_space := battlefield_size.x - FIELD_MARGIN - global_position.x
	var top_space := global_position.y - FIELD_MARGIN
	var bottom_space := battlefield_size.y - FIELD_MARGIN - global_position.y
	if left_space < soft_margin:
		inward.x += 1.0 - clampf(left_space / soft_margin, 0.0, 1.0)
	if right_space < soft_margin:
		inward.x -= 1.0 - clampf(right_space / soft_margin, 0.0, 1.0)
	if top_space < soft_margin:
		inward.y += 1.0 - clampf(top_space / soft_margin, 0.0, 1.0)
	if bottom_space < soft_margin:
		inward.y -= 1.0 - clampf(bottom_space / soft_margin, 0.0, 1.0)
	if inward.length_squared() > 0.01:
		desired += inward.normalized() * 2.2

	if desired.length_squared() <= 0.01:
		desired = global_position.direction_to(battlefield_size * 0.5)
	if desired.length_squared() <= 0.01:
		desired = Vector2.RIGHT
	desired = _apply_ranged_boundary_escape(desired, 360.0, 155.0)

	var speed := (
		move_speed
		* _get_alchemist_field_speed_multiplier()
		* move_multiplier
	)
	velocity = desired.normalized() * speed
	move_and_slide()
	_clamp_to_battlefield()
	_update_alchemist_poison_trail(delta)


func _update_alchemist_poison_trail(delta: float) -> void:
	if not alchemist_transformed:
		return

	alchemist_poison_trail_timer = maxf(
		alchemist_poison_trail_timer - delta,
		0.0
	)
	if alchemist_poison_trail_timer > 0.0 or velocity.length_squared() <= 16.0:
		return

	var min_spacing := maxf(
		float(alchemist_philosopher_config.get("trail_min_spacing", 36.0)),
		1.0
	)
	if (
		alchemist_poison_trail_has_position
		and global_position.distance_squared_to(alchemist_poison_trail_last_position)
		< min_spacing * min_spacing
	):
		return

	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(float(alchemist_philosopher_config.get(
				"trail_tick_damage_ratio",
				0.18
			)), 0.0)
			* maxf(float(alchemist_philosopher_config.get(
				"poison_damage_multiplier",
				1.50
			)), 0.0)
			* _get_alchemist_equivalent_damage_multiplier()
		))
	)
	for poison_node in alchemist_poison_pool:
		if not is_instance_valid(poison_node):
			continue
		if not bool(poison_node.call("is_available")):
			continue
		poison_node.call(
			"activate",
			global_position,
			maxf(float(alchemist_philosopher_config.get(
				"trail_duration",
				2.0
			)), 0.1),
			maxf(
				float(alchemist_philosopher_config.get(
					"trail_radius",
					115.0
				))
				* _get_alchemist_compressed_range_multiplier()
				* _get_alchemist_equivalent_range_multiplier(),
				1.0
			),
			maxf(float(alchemist_philosopher_config.get(
				"trail_tick_interval",
				0.30
			)), 0.03),
			damage,
			_get_alchemist_compressed_range_multiplier()
		)
		alchemist_poison_trail_last_position = global_position
		alchemist_poison_trail_has_position = true
		alchemist_poison_trail_timer = maxf(
			float(alchemist_philosopher_config.get(
				"trail_spawn_interval",
				0.22
			)),
			0.05
		)
		return


func _is_alchemist_inside_mixture_field() -> bool:
	return (
		is_instance_valid(alchemist_mixture_field)
		and bool(alchemist_mixture_field.get("active"))
		and bool(alchemist_mixture_field.call("contains_world_point", global_position))
	)


func _get_alchemist_field_speed_multiplier() -> float:
	if not _is_alchemist_inside_mixture_field():
		return 1.0
	return maxf(
		float(alchemist_mixture_field_config.get("hero_move_speed_multiplier", 1.30)),
		1.0
	)


func _is_alchemist_inside_mixture_field_with_margin(margin: float) -> bool:
	if not is_instance_valid(alchemist_mixture_field):
		return false
	if not bool(alchemist_mixture_field.get("active")):
		return false

	var field_radius := maxf(float(alchemist_mixture_field.get("radius")) + margin, 1.0)
	return (
		alchemist_mixture_field.global_position.distance_squared_to(global_position)
		<= field_radius * field_radius
	)


func _update_alchemist_field_locomotion_state(delta: float) -> void:
	var enter_delay := maxf(
		float(alchemist_mixture_field_config.get("run_enter_delay", 0.08)),
		0.0
	)
	var exit_delay := maxf(
		float(alchemist_mixture_field_config.get("run_exit_delay", 0.12)),
		0.0
	)
	var exit_margin := maxf(
		float(alchemist_mixture_field_config.get("run_exit_margin", 24.0)),
		0.0
	)

	if not alchemist_field_run_active:
		alchemist_field_run_exit_timer = 0.0
		if not _is_alchemist_inside_mixture_field():
			alchemist_field_run_enter_timer = 0.0
			return

		alchemist_field_run_enter_timer += delta
		if alchemist_field_run_enter_timer >= enter_delay:
			alchemist_field_run_active = true
			alchemist_field_run_enter_timer = 0.0
		return

	alchemist_field_run_enter_timer = 0.0
	if _is_alchemist_inside_mixture_field_with_margin(exit_margin):
		alchemist_field_run_exit_timer = 0.0
		return

	alchemist_field_run_exit_timer += delta
	if alchemist_field_run_exit_timer >= exit_delay:
		alchemist_field_run_active = false
		alchemist_field_run_exit_timer = 0.0


func _update_alchemist_mixture_field_hero_effects(delta: float) -> void:
	if not _is_alchemist_inside_mixture_field():
		alchemist_mixture_heal_timer = 0.0
		return

	alchemist_mixture_heal_timer = maxf(alchemist_mixture_heal_timer - delta, 0.0)
	if alchemist_mixture_heal_timer > 0.0:
		return

	var heal_ratio := maxf(
		float(alchemist_mixture_field_config.get("heal_max_hp_ratio", 0.01)),
		0.0
	)
	if heal_ratio > 0.0:
		heal_direct(maxi(1, int(round(float(max_hp) * heal_ratio))))
	alchemist_mixture_heal_timer = maxf(
		float(alchemist_mixture_field_config.get("heal_interval", 1.0)),
		0.1
	)


func _try_cast_alchemist_mixture_field() -> void:
	if alchemist_mixture_field_config.is_empty():
		return
	if alchemist_mixture_field_cooldown > 0.0:
		return
	if not is_instance_valid(alchemist_mixture_field):
		return
	if bool(alchemist_mixture_field.get("active")):
		return

	var gas_cost := maxf(
		float(alchemist_mixture_field_config.get("gas_cost", 30.0)),
		0.0
	)
	if alchemist_gas + 0.001 < gas_cost:
		return

	var radius := maxf(
		float(alchemist_mixture_field_config.get("radius", 660.0))
		* _get_alchemist_compressed_range_multiplier(),
		1.0
	)
	var required_enemies := maxi(
		int(alchemist_mixture_field_config.get("enemy_count_trigger", 2)),
		1
	)
	var nearby_enemies := 0
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_squared_to(monster.global_position) > radius_sq:
			continue
		nearby_enemies += 1
		if nearby_enemies >= required_enemies:
			break
	if nearby_enemies < required_enemies:
		return

	if not _consume_alchemist_gas(gas_cost):
		return

	alchemist_mixture_field_cooldown = _get_alchemist_effective_cooldown(
		alchemist_mixture_field_config,
		20.0
	)
	alchemist_mixture_heal_timer = 0.0
	alchemist_mixture_field.call(
		"activate",
		global_position,
		radius,
		maxf(float(alchemist_mixture_field_config.get("duration", 8.0)), 0.1),
		maxf(float(alchemist_mixture_field_config.get("tick_interval", 0.50)), 0.05)
	)


func _count_active_alchemist_cauldrons() -> int:
	var count: int = 0
	for cauldron in alchemist_cauldrons:
		if is_instance_valid(cauldron) and bool(cauldron.get("active")):
			count += 1
	return count


func _try_cast_alchemist_mystery_cauldron() -> void:
	if alchemist_mystery_cauldron_config.is_empty():
		return
	if alchemist_mystery_cauldron_cooldown > 0.0:
		return

	var quick_prep_stacks := _get_alchemist_augment_stacks("alchemist_quick_preparation")
	var max_active: int = clampi(
		int(alchemist_mystery_cauldron_config.get("max_active", 2))
		+ quick_prep_stacks,
		1,
		alchemist_cauldrons.size()
	)
	if _count_active_alchemist_cauldrons() >= max_active:
		return

	var cauldron_to_use: Node2D = null
	for cauldron in alchemist_cauldrons:
		if is_instance_valid(cauldron) and not bool(cauldron.get("active")):
			cauldron_to_use = cauldron
			break
	if cauldron_to_use == null:
		return

	var angle: float = randf() * TAU
	var placement_radius: float = randf_range(90.0, 145.0)
	var placement: Vector2 = (
		global_position
		+ Vector2.from_angle(angle) * placement_radius
	)
	var margin: float = 96.0
	placement.x = clampf(placement.x, margin, battlefield_size.x - margin)
	placement.y = clampf(placement.y, margin, battlefield_size.y - margin)

	var min_mix: float = maxf(
		float(alchemist_mystery_cauldron_config.get("mix_time_min", 8.0)),
		0.1
	)
	var max_mix: float = maxf(
		float(alchemist_mystery_cauldron_config.get("mix_time_max", 10.0)),
		min_mix
	)
	var mix_duration: float = randf_range(min_mix, max_mix)
	cauldron_to_use.call("activate", placement, mix_duration)
	alchemist_mystery_cauldron_cooldown = (
		_get_alchemist_mystery_cauldron_cooldown_total()
	)


func set_alchemist_cauldron_runtime_paused(paused: bool) -> void:
	if hero_archetype != "alchemist_chemical":
		return
	for cauldron in alchemist_cauldrons:
		if not is_instance_valid(cauldron):
			continue
		if paused:
			cauldron.set_process(false)
		elif bool(cauldron.get("active")):
			cauldron.set_process(true)


func _on_alchemist_cauldron_completed(
	cauldron: Node2D,
	origin: Vector2
) -> void:
	if not is_instance_valid(cauldron):
		return

	var success_mother_stacks := _get_alchemist_augment_stacks(
		"alchemist_failure_mother_success"
	)
	var chance_shift := 0.0
	if success_mother_stacks > 0:
		chance_shift = 0.10 + 0.025 * float(success_mother_stacks - 1)
	var great_chance: float = clampf(
		float(alchemist_mystery_cauldron_config.get("great_success_chance", 0.20))
		+ chance_shift,
		0.0,
		1.0
	)
	var fail_chance: float = clampf(
		float(alchemist_mystery_cauldron_config.get("failure_chance", 0.20))
		- chance_shift,
		0.0,
		1.0 - great_chance
	)
	var roll: float = randf()

	if roll < great_chance:
		if _get_alchemist_augment_stacks("alchemist_quick_preparation") >= 3:
			alchemist_mystery_cauldron_cooldown = 0.0
		cauldron.call("play_result_sound", "great_success")
		await _execute_alchemist_cauldron_great_success(origin)
		await get_tree().create_timer(0.50).timeout
	elif roll < great_chance + fail_chance:
		# Failure should feel instantaneous: hide/deactivate the cauldron
		# immediately, but let its child AudioStreamPlayer finish the boom.
		cauldron.call("play_result_sound", "failure")
		cauldron.call("deactivate")
		_execute_alchemist_cauldron_failure(origin)
		return
	else:
		cauldron.call("play_result_sound", "success")
		_execute_alchemist_cauldron_success(origin)
		await get_tree().create_timer(0.65).timeout

	if is_instance_valid(cauldron):
		cauldron.call("deactivate")


func _execute_alchemist_cauldron_great_success(origin: Vector2) -> void:
	var batch_count: int = maxi(
		int(alchemist_mystery_cauldron_config.get("great_success_batches", 5)),
		1
	)
	var batch_interval: float = maxf(
		float(
			alchemist_mystery_cauldron_config.get(
				"great_success_batch_interval",
				0.32
			)
		),
		0.05
	)
	for batch_index in range(batch_count):
		var vial_min: int = maxi(
			int(
				alchemist_mystery_cauldron_config.get(
					"great_success_vials_min",
					4
				)
			),
			1
		)
		var vial_max: int = maxi(
			int(
				alchemist_mystery_cauldron_config.get(
					"great_success_vials_max",
					5
				)
			),
			vial_min
		)
		var vial_count: int = randi_range(vial_min, vial_max)
		for vial_index in range(vial_count):
			_spawn_alchemist_mystery_vial(origin)
		if batch_index + 1 < batch_count:
			await get_tree().create_timer(batch_interval).timeout


func _spawn_alchemist_mystery_vial(origin: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var vial := ALCHEMIST_VIAL_SCENE.instantiate() as Node2D
	if vial == null:
		return
	parent.add_child(vial)
	# Great success can throw 20+ vials in bursts. Keep the base-attack asset,
	# but attenuate only these temporary mystery vials so their throw SFX stack
	# does not overpower the cauldron result or combat mix.
	var mystery_throw_audio := vial.get_node_or_null("ThrowAudio") as AudioStreamPlayer
	if is_instance_valid(mystery_throw_audio):
		mystery_throw_audio.volume_db = -24.0
	vial.connect(
		"landed",
		Callable(self, "_on_alchemist_mystery_vial_landed")
	)
	var throw_radius: float = maxf(
		float(
			alchemist_mystery_cauldron_config.get(
				"great_success_throw_radius",
				285.0
			)
		),
		60.0
	)
	var angle: float = randf() * TAU
	var radius: float = sqrt(randf()) * throw_radius
	var landing: Vector2 = origin + Vector2.from_angle(angle) * radius
	var margin: float = 64.0
	landing.x = clampf(landing.x, margin, battlefield_size.x - margin)
	landing.y = clampf(landing.y, margin, battlefield_size.y - margin)
	vial.call(
		"launch",
		origin + Vector2(0.0, -24.0),
		landing,
		0.42,
		105.0,
		null,
		true
	)


func _on_alchemist_mystery_vial_landed(
	landing_position: Vector2,
	_direct_target: Node
) -> void:
	var radius: float = maxf(
		float(
			alchemist_mystery_cauldron_config.get(
				"great_success_hit_radius",
				105.0
			)
		),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(attack_damage)
			* maxf(
				float(
					alchemist_mystery_cauldron_config.get(
						"great_success_damage_ratio",
						0.45
					)
				),
				0.0
			)
		)),
		1
	)
	_damage_monsters_in_radius(landing_position, radius, damage)


func _execute_alchemist_cauldron_success(origin: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return

	var material_count: int = maxi(
		int(alchemist_mystery_cauldron_config.get("success_material_count", 7)),
		0
	)
	var lifetime: float = maxf(
		float(
			alchemist_mystery_cauldron_config.get(
				"success_drop_duration",
				10.0
			)
		),
		0.1
	)
	for index in range(material_count):
		var material := ALCHEMY_MATERIAL_SCENE.instantiate() as Node2D
		if material == null:
			continue
		parent.add_child(material)
		var material_angle: float = (
			TAU * float(index) / float(maxi(material_count, 1))
			+ randf_range(-0.24, 0.24)
		)
		var material_radius: float = randf_range(78.0, 170.0)
		var position: Vector2 = (
			origin
			+ Vector2.from_angle(material_angle) * material_radius
		)
		position.x = clampf(position.x, 64.0, battlefield_size.x - 64.0)
		position.y = clampf(position.y, 64.0, battlefield_size.y - 64.0)
		material.call(
			"activate",
			origin,
			maxf(float(alchemist_config.get("gas_per_material", 20.0)), 0.0),
			lifetime,
			true
		)
		material.call(
			"launch_from_cauldron",
			origin + Vector2(0.0, -18.0),
			position,
			randf_range(0.36, 0.50),
			randf_range(52.0, 78.0)
		)
		alchemist_bonus_materials.append(material)

	var heal_count: int = maxi(
		int(
			alchemist_mystery_cauldron_config.get(
				"success_heal_item_count",
				3
			)
		),
		0
	)
	for index in range(heal_count):
		var item := HEAL_ITEM_SCENE.instantiate() as Node2D
		if item == null:
			continue
		parent.add_child(item)
		var heal_angle: float = (
			TAU * float(index) / float(maxi(heal_count, 1))
			+ 0.35
		)
		var heal_position: Vector2 = (
			origin
			+ Vector2.from_angle(heal_angle) * randf_range(105.0, 165.0)
		)
		heal_position.x = clampf(
			heal_position.x,
			64.0,
			battlefield_size.x - 64.0
		)
		heal_position.y = clampf(
			heal_position.y,
			64.0,
			battlefield_size.y - 64.0
		)
		item.global_position = heal_position
		if item.has_method("set_temporary_lifetime"):
			item.call("set_temporary_lifetime", lifetime)


func _execute_alchemist_cauldron_failure(origin: Vector2) -> void:
	var fail_fx := _spawn_archmage_fx(
		"%s/effect3" % STAGE7_FRAME_DIR,
		"effect",
		8,
		4,
		14.0,
		false,
		origin,
		Vector2(0.52, 0.52)
	)
	if is_instance_valid(fail_fx):
		fail_fx.z_index = 9


func _on_alchemist_mixture_field_tick(origin: Vector2, radius: float) -> void:
	if current_hp <= 0:
		return

	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(
				float(alchemist_mixture_field_config.get("tick_damage_ratio", 0.20)),
				0.0
			)
		))
	)
	var slow_multiplier := clampf(
		float(alchemist_mixture_field_config.get("slow_multiplier", 0.80)),
		0.1,
		1.0
	)
	var slow_until := Time.get_ticks_msec() + int(round(
		maxf(
			float(alchemist_mixture_field_config.get("slow_refresh_seconds", 0.75)),
			0.05
		) * 1000.0
	))
	var radius_sq := radius * radius

	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or origin.distance_squared_to(monster.global_position) > radius_sq:
			continue
		_deal_alchemist_dot_damage(monster, damage)
		# Existing monster movement code reads these shared external-slow meta keys.
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(monster.get_meta("gunner_slow_multiplier", 1.0))
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)


func _update_alchemist_emergency_escape(delta: float) -> bool:
	if alchemist_emergency_config.is_empty():
		alchemist_emergency_trapped_timer = 0.0
		return false
	if alchemist_emergency_cooldown > 0.0 or alchemist_gas > 0.001:
		alchemist_emergency_trapped_timer = 0.0
		return false

	var trigger_radius := clampf(
		float(alchemist_emergency_config.get("trigger_radius", 230.0)),
		200.0,
		240.0
	)
	var min_enemies := maxi(
		int(alchemist_emergency_config.get("min_enemy_count", 4)),
		2
	)
	var nearby := _get_monster_nodes_near(global_position, trigger_radius)
	var threats: Array[Node2D] = []
	var radius_sq := trigger_radius * trigger_radius
	for node in nearby:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if global_position.distance_squared_to(monster.global_position) <= radius_sq:
			threats.append(monster)

	if threats.size() < min_enemies:
		alchemist_emergency_trapped_timer = 0.0
		return false

	var escape_info := _find_alchemist_escape_direction(threats, trigger_radius)
	var blocked_ratio := float(escape_info.get("blocked_ratio", 0.0))
	var required_blocked_ratio := clampf(
		float(alchemist_emergency_config.get("blocked_direction_ratio", 0.75)),
		0.50,
		1.0
	)
	if blocked_ratio + 0.001 < required_blocked_ratio:
		alchemist_emergency_trapped_timer = 0.0
		return false

	alchemist_emergency_trapped_timer += delta
	var trapped_duration := clampf(
		float(alchemist_emergency_config.get("trapped_duration", 0.40)),
		0.30,
		0.50
	)
	if alchemist_emergency_trapped_timer < trapped_duration:
		return false

	alchemist_emergency_trapped_timer = 0.0
	var escape_direction: Vector2 = escape_info.get("direction", Vector2.RIGHT)
	_cast_alchemist_emergency_escape(threats, escape_direction)
	return true


func _find_alchemist_escape_direction(
	threats: Array[Node2D],
	trigger_radius: float
) -> Dictionary:
	const SAMPLE_COUNT := 12
	var best_direction := Vector2.RIGHT
	var best_score := -INF
	var blocked_count := 0
	var block_distance := minf(trigger_radius, 185.0)

	for sample_index in range(SAMPLE_COUNT):
		var direction := Vector2.from_angle(
			TAU * float(sample_index) / float(SAMPLE_COUNT)
		)
		var blocked := false
		var score := 0.0
		for monster in threats:
			if not is_instance_valid(monster):
				continue
			var offset := monster.global_position - global_position
			var distance := maxf(offset.length(), 1.0)
			var toward := direction.dot(offset / distance)
			if distance <= block_distance and toward > 0.45:
				blocked = true
			if toward > 0.0:
				score -= toward * (1.0 - clampf(distance / trigger_radius, 0.0, 1.0))
			else:
				score += (-toward) * 0.18

		var probe := global_position + direction * 150.0
		var margin := 72.0
		if (
			probe.x < margin
			or probe.y < margin
			or probe.x > battlefield_size.x - margin
			or probe.y > battlefield_size.y - margin
		):
			blocked = true
			score -= 2.0

		if blocked:
			blocked_count += 1
		else:
			score += 1.25
		if score > best_score:
			best_score = score
			best_direction = direction

	return {
		"direction": best_direction,
		"blocked_ratio": float(blocked_count) / float(SAMPLE_COUNT),
	}


func _cast_alchemist_emergency_escape(
	threats: Array[Node2D],
	escape_direction: Vector2
) -> void:
	alchemist_emergency_cooldown = maxf(
		_get_alchemist_effective_cooldown(
			alchemist_emergency_config,
			10.0
		),
		0.1
	)
	if escape_direction.length_squared() <= 0.01:
		escape_direction = Vector2.RIGHT
	escape_direction = escape_direction.normalized()

	var effect_radius := maxf(
		float(alchemist_emergency_config.get("effect_radius", 245.0)),
		1.0
	)
	var knockback := maxf(
		float(alchemist_emergency_config.get("knockback_distance", 185.0)),
		0.0
	)
	var damage_ratio := maxf(
		float(alchemist_emergency_config.get("damage_ratio", 0.35)),
		0.0
	)
	var slow_multiplier := clampf(
		float(alchemist_emergency_config.get("slow_multiplier", 0.85)),
		0.1,
		1.0
	)
	var slow_duration := maxf(
		float(alchemist_emergency_config.get("slow_duration", 2.0)),
		0.05
	)
	var effect_radius_sq := effect_radius * effect_radius
	var enemy_damage := maxi(1, int(round(float(attack_damage) * damage_ratio)))
	var slow_until := Time.get_ticks_msec() + int(round(slow_duration * 1000.0))

	for monster in threats:
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(monster.global_position) > effect_radius_sq:
			continue
		var radial := global_position.direction_to(monster.global_position)
		if radial.length_squared() <= 0.01:
			radial = -escape_direction
		var lane_dot := radial.dot(escape_direction)
		var push_direction := radial
		if lane_dot > 0.15:
			var side := Vector2(-escape_direction.y, escape_direction.x)
			var side_sign := 1.0 if side.dot(radial) >= 0.0 else -1.0
			push_direction = (
				radial * 0.55
				+ side * side_sign * 0.85
				- escape_direction * 0.30
			).normalized()
		monster.global_position += push_direction * knockback
		if monster.has_method("take_damage"):
			monster.call("take_damage", enemy_damage)
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(monster.get_meta("gunner_slow_multiplier", 1.0))
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)

	var fx := _spawn_archmage_fx(
		"%s/effect8" % STAGE7_FRAME_DIR,
		"effect",
		1,
		7,
		16.0,
		false,
		global_position,
		Vector2(0.50, 0.50)
	)
	if is_instance_valid(fx):
		fx.z_index = 10

	if is_instance_valid(alchemist_emergency_audio):
		alchemist_emergency_audio.stop()
		alchemist_emergency_audio.play()

	_apply_alchemist_emergency_self_damage()
	_flash_alchemist_emergency_red()


func _apply_alchemist_emergency_self_damage() -> void:
	if current_hp <= 0 or is_dying:
		return
	var self_ratio := clampf(
		float(alchemist_emergency_config.get("self_damage_current_hp_ratio", 0.02)),
		0.0,
		1.0
	)
	var minimum_damage := maxi(
		int(alchemist_emergency_config.get("self_damage_min", 100)),
		1
	)
	var self_damage := maxi(
		minimum_damage,
		int(ceil(float(current_hp) * self_ratio))
	)
	var previous_hp := current_hp
	current_hp = maxi(current_hp - self_damage, 0)
	var applied := previous_hp - current_hp
	if applied > 0:
		DAMAGE_NUMBERS.show(self, applied)
		health_changed.emit(current_hp, max_hp)
		queue_redraw()
	if current_hp <= 0:
		_begin_death_sequence()


func _flash_alchemist_emergency_red() -> void:
	if not is_instance_valid(hero_sprite):
		return
	var tween := create_tween()
	hero_sprite.modulate = Color(1.0, 0.22, 0.22, 1.0)
	tween.tween_property(hero_sprite, "modulate", Color.WHITE, 0.18)


func _get_alchemist_chest_attack_target() -> Node2D:
	if (
		not is_instance_valid(chest_target)
		or chest_target.is_queued_for_deletion()
	):
		return null

	var max_distance := maxf(attack_range, 1.0)
	var chest_distance_sq := global_position.distance_squared_to(chest_target.global_position)
	if chest_distance_sq > max_distance * max_distance:
		return null

	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return chest_target

	var monster_distance_sq := global_position.distance_squared_to(target.global_position)
	return chest_target if chest_distance_sq <= monster_distance_sq else null


func _start_alchemist_basic_attack(direct_chest_target: Node2D = null) -> void:
	var gas_cost := maxf(float(alchemist_config.get("basic_gas_cost", 10.0)), 0.0)
	if not _consume_alchemist_gas(gas_cost):
		return

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.52
	_restart_stage1_animation("attack", 1.0)

	alchemist_throw_positions.clear()
	alchemist_direct_chest_target = (
		direct_chest_target
		if is_instance_valid(direct_chest_target)
		else null
	)
	var throw_radius := maxf(float(alchemist_config.get("basic_throw_radius", 400.0)), 1.0)
	var vial_count := maxi(
		int(alchemist_config.get("basic_vial_count", 3))
		+ _get_alchemist_augment_stacks("alchemist_chemical_support"),
		1
	)
	for index in range(vial_count):
		var landing_position := Vector2.ZERO
		if index == 0 and is_instance_valid(alchemist_direct_chest_target):
			landing_position = alchemist_direct_chest_target.global_position
		else:
			var angle := randf() * TAU
			var radius := sqrt(randf()) * throw_radius
			landing_position = global_position + Vector2.from_angle(angle) * radius
			var margin := 64.0
			landing_position.x = clampf(landing_position.x, margin, battlefield_size.x - margin)
			landing_position.y = clampf(landing_position.y, margin, battlefield_size.y - margin)
		alchemist_throw_positions.append(landing_position)

	if is_instance_valid(alchemist_direct_chest_target):
		_face_attack_direction(
			alchemist_direct_chest_target.global_position.x - global_position.x
		)
	alchemist_throw_index = 0
	alchemist_throw_timer = 0.0


func _update_alchemist_throw_sequence(delta: float) -> void:
	if alchemist_throw_index >= alchemist_throw_positions.size():
		return
	alchemist_throw_timer = maxf(alchemist_throw_timer - delta, 0.0)
	if alchemist_throw_timer > 0.0:
		return

	var landing_position: Vector2 = alchemist_throw_positions[alchemist_throw_index]
	var direct_target: Node2D = null
	if alchemist_throw_index == 0 and is_instance_valid(alchemist_direct_chest_target):
		direct_target = alchemist_direct_chest_target
	if not _launch_alchemist_vial(landing_position, direct_target):
		# Retry on the next physics tick instead of silently losing a Chemical
		# Support bonus vial when every pooled projectile is still in flight.
		alchemist_throw_timer = 0.01
		return
	if alchemist_throw_index == 0:
		alchemist_direct_chest_target = null
	alchemist_throw_index += 1
	alchemist_throw_timer = maxf(
		float(alchemist_config.get("vial_throw_interval", 0.19)),
		0.01
	)


func _launch_alchemist_vial(
	landing_position: Vector2,
	direct_target: Node2D = null
) -> bool:
	for vial in alchemist_vial_pool:
		if not is_instance_valid(vial):
			continue
		if not bool(vial.call("is_available")):
			continue
		vial.call(
			"launch",
			global_position,
			landing_position,
			maxf(float(alchemist_config.get("vial_flight_duration", 0.46)), 0.08),
			maxf(float(alchemist_config.get("vial_arc_height", 120.0)), 0.0),
			direct_target
		)
		return true
	return false


func _on_alchemist_vial_landed(
	landing_position: Vector2,
	direct_target: Node
) -> void:
	if (
		is_instance_valid(direct_target)
		and not direct_target.is_queued_for_deletion()
		and direct_target.is_in_group("treasure_chests")
		and direct_target.has_method("take_damage")
	):
		direct_target.call("take_damage", maxi(attack_damage, 1))

	var tick_damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(float(alchemist_config.get("poison_tick_damage_ratio", 0.18)), 0.0)
		))
	)
	for poison in alchemist_poison_pool:
		if not is_instance_valid(poison):
			continue
		if not bool(poison.call("is_available")):
			continue
		poison.call(
			"activate",
			landing_position,
			maxf(float(alchemist_config.get("poison_duration", 4.0)), 0.1),
			maxf(
				float(alchemist_config.get("poison_radius", 275.0))
				* _get_alchemist_compressed_range_multiplier(),
				1.0
			),
			maxf(float(alchemist_config.get("poison_tick_interval", 0.27)), 0.03),
			tick_damage,
			_get_alchemist_compressed_range_multiplier()
		)
		return


func _on_alchemist_poison_tick(origin: Vector2, radius: float, damage: int) -> void:
	if current_hp <= 0:
		return
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if origin.distance_squared_to(monster.global_position) > radius_sq:
			continue
		_deal_alchemist_dot_damage(monster, damage)


func _update_alchemist_pose_visual(delta: float) -> void:
	if hero_archetype != "alchemist_chemical" or not hero_sprite.visible or is_dying:
		return
	if hit_pose_timer > 0.0 or attack_pose_timer > 0.0:
		return
	_update_facing_from_horizontal(velocity.x, delta)
	var speed := velocity.length()
	if speed > 4.0:
		var movement_ratio := speed / maxf(move_speed, 1.0)
		var locomotion_animation := (
			"move"
			if alchemist_transformed
			else ("run" if alchemist_field_run_active else "move")
		)
		_play_stage1_animation(
			locomotion_animation,
			clampf(movement_ratio, 0.80, 1.45)
		)
	else:
		_play_stage1_animation("idle", 1.0)


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
		gunner_reload_redraw_timer = maxf(
			gunner_reload_redraw_timer - delta,
			0.0
		)
		if gunner_reload_redraw_timer <= 0.0:
			gunner_reload_redraw_timer = 0.08
			queue_redraw()
		if gunner_cylinder_decision_timer <= 0.0:
			gunner_cylinder_decision_timer = 0.35
			if _gunner_should_use_cylinder():
				_use_gunner_cylinder_strike()
		if gunner_reload_timer <= 0.0:
			_finish_gunner_reload()

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)
	_update_magnet_item_goal(delta)
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
	move_direction = _apply_magnet_item_steering(move_direction, delta)
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
	return _apply_ranged_boundary_escape(base_direction, 440.0, 165.0)


func _apply_gunner_boundary_steering(base_direction: Vector2) -> Vector2:
	return _apply_ranged_boundary_escape(base_direction, 360.0, 155.0)


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
	var projectile := _acquire_projectile(
		GUNNER_PROJECTILE_SCENE,
		"gunner_projectile"
	)
	if projectile == null:
		return
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
	var projectile := _acquire_projectile(
		GUNNER_PROJECTILE_SCENE,
		"gunner_projectile"
	)
	if projectile == null:
		return
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
	gunner_reload_redraw_timer = 0.0
	attack_timer = maxf(attack_timer, gunner_reload_timer)
	queue_redraw()


func _finish_gunner_reload() -> void:
	gunner_reloading = false
	gunner_reload_timer = 0.0
	gunner_reload_redraw_timer = 0.0
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
		if (
			monster == null
			or global_position.distance_squared_to(monster.global_position)
			> radius * radius
		):
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
		_play_gunner_deadeye_flame(gunner_deadeye_direction)
		_spawn_gunner_bullet(gunner_deadeye_direction, true)
		gunner_deadeye_shots_left -= 1
		gunner_deadeye_shot_timer = maxf(float(gunner_config.get("deadeye_shot_interval", 0.08)), 0.03)
	if gunner_deadeye_shots_left <= 0:
		gunner_deadeye_active = false
		_play_gunner_deadeye_smoke(gunner_deadeye_direction)
		_start_gunner_reload()


func _count_monsters_near(
	origin: Vector2,
	radius: float,
	stop_after: int = 0
) -> int:
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("count_monsters_near")
	):
		return int(
			battle.call(
				"count_monsters_near",
				origin,
				radius,
				stop_after
			)
		)

	var count := 0
	var radius_sq := radius * radius
	for node in _get_monster_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if (
			monster != null
			and origin.distance_squared_to(monster.global_position)
			<= radius_sq
		):
			count += 1
			if stop_after > 0 and count >= stop_after:
				return count
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
	_update_magnet_item_goal(delta)

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
	move_direction = _apply_magnet_item_steering(move_direction, delta)
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

	# Stage 2 rogue deals +200% bonus damage to treasure chests
	# (300% total) so the fast combo can realistically break them.
	_damage_treasure_chests(
		corridor_end,
		aoe_radius,
		maxi(1, damage * 3)
	)
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
	heal_direct(heal_amount)

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
	if radius <= 0.0:
		return false
	return _count_monsters_near(
		global_position,
		radius,
		required
	) >= required

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
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius * radius
		):
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


func _apply_stage6_berserker_effect_visuals() -> void:
	if hero_archetype != "berserker_madness":
		return

	channel_effect.visible = false
	channel_effect.sprite_frames = null
	channel_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("madness")
	frames.set_animation_speed("madness", 1.0)
	frames.set_animation_loop("madness", true)

	var texture := _load_stage1_texture(
		"%s/effect7/special_08.png" % STAGE6_FRAME_DIR
	)
	if texture == null:
		return

	frames.add_frame("madness", texture)
	channel_effect.sprite_frames = frames
	channel_effect.animation = &"madness"
	channel_effect.position = Vector2(0.0, -126.0)
	channel_effect.scale = Vector2(0.48, 0.48)
	channel_effect.z_index = 9
	channel_effect.modulate = Color.WHITE


func _apply_alchemist_philosopher_effect_visuals() -> void:
	if hero_archetype != "alchemist_chemical":
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("philosopher_stone")
	frames.set_animation_speed(
		"philosopher_stone",
		maxf(
			float(alchemist_philosopher_config.get("channel_fps", 8.0)),
			1.0
		)
	)
	frames.set_animation_loop("philosopher_stone", false)

	for index in range(1, 9):
		var brew := _load_stage1_texture(
			"%s/effect7/brew_%02d.png" % [STAGE7_FRAME_DIR, index]
		)
		if brew != null:
			frames.add_frame("philosopher_stone", brew)
	for index in range(1, 5):
		var cast := _load_stage1_texture(
			"%s/effect7/cast_%02d.png" % [STAGE7_FRAME_DIR, index]
		)
		if cast != null:
			frames.add_frame("philosopher_stone", cast)

	channel_effect.stop()
	channel_effect.sprite_frames = frames
	channel_effect.animation = &"philosopher_stone"
	channel_effect.visible = false
	channel_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# effect7 manifest anchor is (192,336) in a 512x384 frame.
	channel_effect.offset = Vector2(64.0, -144.0)
	channel_effect.position = Vector2.ZERO
	channel_effect.scale = Vector2(0.50, 0.50)
	channel_effect.z_index = 10
	channel_effect.modulate = Color.WHITE


func _apply_profile_visual() -> void:
	hero_sprite.visible = false
	hero_sprite.sprite_frames = null
	hero_sprite.modulate = Color.WHITE
	hero_sprite.rotation = 0.0
	hero_sprite.offset = Vector2.ZERO
	hero_sprite.z_index = 1
	hero_sprite.show_behind_parent = false
	hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if hero_archetype == "cleric_purifier":
		var purifier_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE9_FRAME_DIR
		)
		var purifier_frames := SpriteFrames.new()
		if purifier_frames.has_animation("default"):
			purifier_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			purifier_frames, "idle", purifier_dir, "idle", 4, 6.0, true
		):
			return
		_add_named_sequence_animation(
			purifier_frames, "move", purifier_dir, "walk", 6, 9.0, true
		)
		_add_named_sequence_animation(
			purifier_frames, "attack", purifier_dir, "attack", 4, 8.0, false
		)
		_add_named_sequence_animation(
			purifier_frames, "hit", purifier_dir, "hit", 3, 12.0, false
		)
		_add_named_sequence_animation(
			purifier_frames, "death", purifier_dir, "death", 4, 8.0, false
		)
		hero_sprite.sprite_frames = purifier_frames
		hero_sprite.visible = true
		# Stage 9 draw order: HeroSprite < crown effect < Hero._draw() bars.
		hero_sprite.z_index = -2
		hero_sprite.show_behind_parent = true
		_build_stage9_frame_anchor_cache()
		_apply_normalized_hero_visual_scale()
		_apply_stage9_sprite_anchor()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_archetype == "summoner_gatekeeper":
		var summoner_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE8_FRAME_DIR
		)
		var summoner_frames := SpriteFrames.new()
		if summoner_frames.has_animation("default"):
			summoner_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			summoner_frames, "idle", summoner_dir, "idle", 4, 6.0, true
		):
			return
		_add_named_sequence_animation(
			summoner_frames, "move", summoner_dir, "walk", 6, 9.0, true
		)
		_add_named_sequence_animation(
			summoner_frames, "attack", summoner_dir, "atk", 6, 12.0, false
		)
		_add_named_sequence_animation(
			summoner_frames, "hit", summoner_dir, "hit", 3, 12.0, false
		)
		_add_named_sequence_animation(
			summoner_frames, "death", summoner_dir, "dead", 4, 8.0, false
		)
		hero_sprite.sprite_frames = summoner_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		_apply_stage8_sprite_anchor()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

	if hero_archetype == "alchemist_chemical":
		var alchemist_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE7_FRAME_DIR
		)
		var alchemist_frames := SpriteFrames.new()
		if alchemist_frames.has_animation("default"):
			alchemist_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			alchemist_frames, "idle", alchemist_dir, "idle", 4, 6.0, true
		):
			return
		_add_named_sequence_animation(
			alchemist_frames, "move", alchemist_dir, "walk", 6, 9.0, true
		)
		_add_named_sequence_animation(
			alchemist_frames, "run", alchemist_dir, "run", 6, 11.0, true
		)
		alchemist_frames.add_animation("attack")
		alchemist_frames.set_animation_speed("attack", 7.0)
		alchemist_frames.set_animation_loop("attack", false)
		for attack_frame_index in [1, 2, 5]:
			var attack_texture := _load_stage1_texture(
				"%s/atk_%02d.png" % [alchemist_dir, attack_frame_index]
			)
			if attack_texture == null:
				push_warning(
					"Stage 7 attack frame load failed: %s/atk_%02d.png"
					% [alchemist_dir, attack_frame_index]
				)
				return
			alchemist_frames.add_frame("attack", attack_texture)
		_add_named_sequence_animation(
			alchemist_frames, "hit", alchemist_dir, "hit", 2, 12.0, false
		)
		_add_named_sequence_animation(
			alchemist_frames, "death", alchemist_dir, "dead", 4, 8.0, false
		)
		hero_sprite.sprite_frames = alchemist_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		_apply_stage7_sprite_anchor()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		_apply_alchemist_philosopher_effect_visuals()
		return

	if hero_archetype == "berserker_madness":
		var berserker_dir := (
			sprite_frame_dir
			if not sprite_frame_dir.is_empty()
			else STAGE6_FRAME_DIR
		)
		var berserker_frames := SpriteFrames.new()
		if berserker_frames.has_animation("default"):
			berserker_frames.remove_animation("default")
		if not _add_named_sequence_animation(
			berserker_frames, "idle", berserker_dir, "idle", 4, 6.0, true
		):
			return
		_add_named_sequence_animation(
			berserker_frames, "move", berserker_dir, "walk", 6, 9.0, true
		)
		berserker_frames.add_animation("attack")
		berserker_frames.set_animation_speed("attack", 10.0)
		berserker_frames.set_animation_loop("attack", false)
		for attack_frame_index in [1, 5, 2, 6]:
			var attack_texture := _load_stage1_texture(
				"%s/atk_%02d.png" % [
					berserker_dir,
					attack_frame_index,
				]
			)
			if attack_texture == null:
				push_warning(
					"Stage 6 attack frame load failed: %s/atk_%02d.png"
					% [berserker_dir, attack_frame_index]
				)
				return
			berserker_frames.add_frame("attack", attack_texture)

		for dash_animation_data in [
			["dash_start", 1],
			["dash_finish", 2],
		]:
			var dash_animation_name: String = String(
				dash_animation_data[0]
			)
			var dash_frame_index: int = int(
				dash_animation_data[1]
			)
			var dash_texture := _load_stage1_texture(
				"%s/atk_%02d.png" % [
					berserker_dir,
					dash_frame_index,
				]
			)
			if dash_texture == null:
				push_warning(
					"Stage 6 dash frame load failed: %s/atk_%02d.png"
					% [berserker_dir, dash_frame_index]
				)
				return
			berserker_frames.add_animation(dash_animation_name)
			berserker_frames.set_animation_speed(
				dash_animation_name,
				1.0
			)
			berserker_frames.set_animation_loop(
				dash_animation_name,
				true
			)
			berserker_frames.add_frame(
				dash_animation_name,
				dash_texture
			)

		_add_named_sequence_animation(
			berserker_frames, "hit", berserker_dir, "hit", 3, 13.0, false
		)
		_add_named_sequence_animation(
			berserker_frames, "death", berserker_dir, "dead", 4, 8.0, false
		)
		hero_sprite.sprite_frames = berserker_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

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
	# Non-Stage-1 heroes can already have their own ChannelEffect configured
	# by _apply_profile_visual(). Do not erase those frames here.
	if hero_id != "ranged_rookie":
		return

	channel_effect.visible = false
	channel_effect.sprite_frames = null
	channel_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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

func _hero_animation_priority(animation_name: StringName) -> int:
	match animation_name:
		&"death":
			return 100
		&"hit":
			return 80
		&"dash_start", &"dash_finish":
			return 70
		&"attack":
			return 60
		&"run", &"move":
			return 20
		&"idle":
			return 10
		_:
			return 40


func _is_current_hero_animation_protected(requested_animation: StringName) -> bool:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return false

	var current_animation: StringName = hero_sprite.animation
	if current_animation == &"" or current_animation == requested_animation:
		return false

	var current_priority := _hero_animation_priority(current_animation)
	var requested_priority := _hero_animation_priority(requested_animation)
	if current_priority <= requested_priority:
		return false

	match current_animation:
		&"death":
			return is_dying or berserker_reviving or hero_sprite.is_playing()
		&"hit":
			return hit_pose_timer > 0.0 or hero_sprite.is_playing()
		&"attack":
			return attack_pose_timer > 0.0 or hero_sprite.is_playing()
		&"dash_start", &"dash_finish":
			return (
				berserker_skill3_active
				or fighter_charge_active
				or hero_sprite.is_playing()
			)
		_:
			if hero_sprite.sprite_frames.has_animation(current_animation):
				return (
					not hero_sprite.sprite_frames.get_animation_loop(current_animation)
					and hero_sprite.is_playing()
				)
	return false


func _play_stage1_animation(animation_name: String, speed_scale: float = 1.0) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(animation_name):
		return

	var requested_animation := StringName(animation_name)
	if _is_current_hero_animation_protected(requested_animation):
		return

	hero_sprite.speed_scale = speed_scale
	if hero_sprite.animation != requested_animation:
		hero_sprite.play(requested_animation)


func _restart_stage1_animation(animation_name: String, speed_scale: float = 1.0) -> void:
	if not hero_sprite.visible or hero_sprite.sprite_frames == null:
		return
	if not hero_sprite.sprite_frames.has_animation(animation_name):
		return

	var requested_animation := StringName(animation_name)
	if _is_current_hero_animation_protected(requested_animation):
		return

	var now_msec := Time.get_ticks_msec()
	if (
		hero_sprite.animation == requested_animation
		and hero_sprite.is_playing()
		and hero_animation_last_restart_name == requested_animation
		and now_msec - hero_animation_last_restart_msec
			< HERO_ANIMATION_DUPLICATE_RESTART_GUARD_MSEC
	):
		# Combat logic is not blocked; only suppress duplicate visual restarts
		# that arrive almost simultaneously and make frame 0 vibrate.
		hero_sprite.speed_scale = speed_scale
		return

	hero_animation_last_restart_name = requested_animation
	hero_animation_last_restart_msec = now_msec
	hero_sprite.stop()
	hero_sprite.animation = requested_animation
	hero_sprite.frame = 0
	hero_sprite.frame_progress = 0.0
	hero_sprite.speed_scale = speed_scale
	hero_sprite.play(requested_animation)

func _update_stage1_pose_visual(delta: float) -> void:
	if (
		hero_id not in ["ranged_rookie", "archmage_hero", "purifier_hero"]
		or not hero_sprite.visible
		or is_dying
	):
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

func _apply_stage7_sprite_anchor() -> void:
	if hero_archetype != "alchemist_chemical" or not is_instance_valid(hero_sprite):
		return
	# Stage 7 standalone frames are 512x256 with the shared body/root anchor.
	# Keep the authored X compensation, but render the body lower so the
	# oversized pixel frame clears the resource/HP bars above the hero.
	hero_sprite.offset = Vector2(
		-104.0 if hero_sprite.flip_h else 104.0,
		48.0
	)


func _stage9_frame_anchor_key(animation_name: StringName, frame_index: int) -> String:
	return "%s:%d" % [String(animation_name), frame_index]


func _find_stage9_body_anchor_x(texture: Texture2D) -> float:
	if texture == null:
		return 0.0
	var image := texture.get_image()
	if image == null or image.is_empty():
		return float(texture.get_width()) * 0.5
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return float(texture.get_width()) * 0.5

	# Sample the lower-middle body band and use the widest opaque horizontal
	# run. Thin staff/veil pixels then cannot drag the anchor away from the
	# torso/robe root the way a full bounding-box center can.
	var y_start := used_rect.position.y + int(round(float(used_rect.size.y) * 0.48))
	var y_end := used_rect.position.y + int(round(float(used_rect.size.y) * 0.90))
	var y_step := maxi(1, int(round(float(used_rect.size.y) / 14.0)))
	var x_start := used_rect.position.x
	var x_end := used_rect.position.x + used_rect.size.x
	var best_run_start := x_start
	var best_run_length := 0

	for y in range(y_start, y_end + 1, y_step):
		var run_start := -1
		for x in range(x_start, x_end):
			var opaque := image.get_pixel(x, y).a > 0.20
			if opaque and run_start < 0:
				run_start = x
			elif not opaque and run_start >= 0:
				var run_length := x - run_start
				if run_length > best_run_length:
					best_run_length = run_length
					best_run_start = run_start
				run_start = -1
		if run_start >= 0:
			var run_length := x_end - run_start
			if run_length > best_run_length:
				best_run_length = run_length
				best_run_start = run_start

	if best_run_length <= 0:
		return float(used_rect.position.x) + float(used_rect.size.x) * 0.5
	return float(best_run_start) + float(best_run_length) * 0.5


func _build_stage9_frame_anchor_cache() -> void:
	stage9_frame_anchor_offsets.clear()
	if (
		hero_archetype != "cleric_purifier"
		or not is_instance_valid(hero_sprite)
		or hero_sprite.sprite_frames == null
		or not hero_sprite.sprite_frames.has_animation(&"idle")
		or hero_sprite.sprite_frames.get_frame_count(&"idle") <= 0
	):
		return

	var reference_texture := hero_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if reference_texture == null:
		return
	var reference_anchor_local := (
		_find_stage9_body_anchor_x(reference_texture)
		- float(reference_texture.get_width()) * 0.5
	)
	# Move the actual torso/robe root, not the transparent frame canvas, onto
	# the gameplay root. The HP/resource bars are centered on this same X=0.
	stage9_body_center_offset_x = -reference_anchor_local

	for animation_name in hero_sprite.sprite_frames.get_animation_names():
		var frame_count := hero_sprite.sprite_frames.get_frame_count(animation_name)
		for frame_index in range(frame_count):
			var texture := hero_sprite.sprite_frames.get_frame_texture(
				animation_name,
				frame_index
			)
			if texture == null:
				continue
			var anchor_local := (
				_find_stage9_body_anchor_x(texture)
				- float(texture.get_width()) * 0.5
			)
			stage9_frame_anchor_offsets[
				_stage9_frame_anchor_key(animation_name, frame_index)
			] = reference_anchor_local - anchor_local


func _on_hero_sprite_frame_or_animation_changed() -> void:
	if hero_archetype == "cleric_purifier":
		_apply_stage9_sprite_anchor()


func _apply_stage9_sprite_anchor() -> void:
	if hero_archetype != "cleric_purifier" or not is_instance_valid(hero_sprite):
		return
	var correction_x := float(
		stage9_frame_anchor_offsets.get(
			_stage9_frame_anchor_key(hero_sprite.animation, hero_sprite.frame),
			0.0
		)
	)
	var facing_sign := -1.0 if hero_sprite.flip_h else 1.0
	# Preserve the tuned Stage 9 global placement, but cancel authored
	# frame-to-frame body drift around the same gameplay/root position.
	hero_sprite.offset = Vector2(
		(stage9_body_center_offset_x + correction_x) * facing_sign,
		-24.0
	)
	# effect3/effect4 are authored around the hero root, so keep them centered
	# on X=0 instead of inheriting the sprite frame's transparent-canvas offset.
	if is_instance_valid(purifier_protection_effect):
		purifier_protection_effect.offset.x = 0.0
	if is_instance_valid(purifier_crown_effect):
		purifier_crown_effect.offset.x = 0.0


func _apply_stage8_sprite_anchor() -> void:
	if hero_archetype != "summoner_gatekeeper" or not is_instance_valid(hero_sprite):
		return
	# Stage 8 frames use a 512x288 cell and the authored body/foot anchor is
	# (180,257). AnimatedSprite2D centers at (256,144), so compensate by the
	# center-to-anchor delta. Mirror only X when the hero faces left.
	hero_sprite.offset = Vector2(
		-76.0 if hero_sprite.flip_h else 76.0,
		-84.0
	)


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
	_apply_stage7_sprite_anchor()
	_apply_stage9_sprite_anchor()
	facing_candidate_sign = 0
	facing_candidate_timer = 0.0

func _face_attack_direction(horizontal_direction: float) -> void:
	if not hero_sprite.visible or absf(horizontal_direction) <= 0.001:
		return

	hero_sprite.flip_h = horizontal_direction < 0.0
	_apply_stage7_sprite_anchor()
	_apply_stage9_sprite_anchor()
	facing_candidate_sign = 0
	facing_candidate_timer = 0.0

func _apply_camera_limits() -> void:
	if not is_instance_valid(follow_camera):
		return

	follow_camera.limit_left = 0
	follow_camera.limit_top = 0
	follow_camera.limit_right = int(battlefield_size.x)
	follow_camera.limit_bottom = int(battlefield_size.y)
	# Pixel-art characters shimmer when the camera follows on sub-pixel
	# positions. Keep the physics coordinates continuous, but make the
	# shared Hero camera follow directly so rendered sprites stay stable.
	follow_camera.position_smoothing_enabled = false

func _move_without_monsters() -> void:
	var current_move_speed := move_speed * _get_purifier_move_speed_multiplier()
	if hero_archetype == "alchemist_chemical":
		current_move_speed *= _get_alchemist_field_speed_multiplier()

	if is_instance_valid(heal_item_target):
		var heal_direction := _apply_heal_item_steering(Vector2.ZERO, 0.016)
		if heal_direction.length_squared() > 0.01:
			heal_direction = _apply_ranged_boundary_escape(heal_direction)
			velocity = heal_direction * current_move_speed * 0.90 * move_multiplier
			move_and_slide()
			_clamp_to_battlefield()
			return

	if is_instance_valid(magnet_item_target):
		var magnet_direction := _apply_magnet_item_steering(
			Vector2.ZERO,
			0.016
		)
		if magnet_direction.length_squared() > 0.01:
			magnet_direction = _apply_ranged_boundary_escape(magnet_direction)
			velocity = (
				magnet_direction
				* current_move_speed
				* 0.82
				* move_multiplier
			)
			move_and_slide()
			_clamp_to_battlefield()
			return

	if is_instance_valid(chest_target):
		if hero_archetype == "alchemist_chemical":
			var chest_distance_sq := global_position.distance_squared_to(
				chest_target.global_position
			)
			var alchemist_attack_range := maxf(attack_range, 1.0)
			if chest_distance_sq > alchemist_attack_range * alchemist_attack_range:
				var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
				if chest_direction.length_squared() > 0.01:
					chest_direction = _apply_ranged_boundary_escape(chest_direction)
					velocity = chest_direction * current_move_speed * 0.72 * move_multiplier
					move_and_slide()
					_clamp_to_battlefield()
			else:
				velocity = Vector2.ZERO
				if (
					attack_timer <= 0.0
					and alchemist_throw_index >= alchemist_throw_positions.size()
				):
					_start_alchemist_basic_attack(chest_target)
			return

		var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			chest_direction = _apply_ranged_boundary_escape(chest_direction)
			velocity = chest_direction * current_move_speed * 0.72 * move_multiplier
			move_and_slide()
			_clamp_to_battlefield()
			if (
				global_position.distance_squared_to(chest_target.global_position)
				<= 90.0 * 90.0
				and attack_timer <= 0.0
			):
				chest_target.call("take_damage", attack_damage)
				attack_timer = _get_common_attack_interval(attack_cooldown)
			return

	var nearest_exp_orb := _find_nearest_exp_orb()
	if is_instance_valid(nearest_exp_orb):
		var exp_direction := global_position.direction_to(nearest_exp_orb.global_position)
		exp_direction = _apply_ranged_boundary_escape(exp_direction)
		velocity = exp_direction * current_move_speed * 0.90 * move_multiplier
		move_and_slide()
		_clamp_to_battlefield()
		return

	if (
		wander_timer <= 0.0
		or position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE * WANDER_REACHED_DISTANCE
	):
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	direction = _apply_ranged_boundary_escape(direction)
	velocity = direction * current_move_speed * 0.72 * move_multiplier
	move_and_slide()
	_clamp_to_battlefield()

func _find_nearest_exp_orb() -> Node2D:
	var now_msec := Time.get_ticks_msec()
	if (
		now_msec < exp_orb_retarget_until_msec
		and is_instance_valid(exp_orb_target)
		and not exp_orb_target.is_queued_for_deletion()
		and exp_orb_target.is_in_group("exp_orbs")
	):
		return exp_orb_target

	exp_orb_retarget_until_msec = now_msec + 120
	exp_orb_target = null
	var nearest_distance := INF

	for node in _get_aux_group_nodes_cached(&"exp_orbs"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var orb := node as Node2D
		if orb == null:
			continue

		var distance := global_position.distance_squared_to(
			orb.global_position
		)
		if distance < nearest_distance:
			nearest_distance = distance
			exp_orb_target = orb

	return exp_orb_target


func _pick_new_wander_target() -> void:
	var candidate := Vector2(battlefield_size.x * 0.5, battlefield_size.y * 0.5)

	for _attempt in range(6):
		candidate = Vector2(
			randf_range(FIELD_MARGIN, battlefield_size.x - FIELD_MARGIN),
			randf_range(FIELD_MARGIN, battlefield_size.y - FIELD_MARGIN)
		)
		if (
			position.distance_squared_to(candidate)
			>= WANDER_MIN_TARGET_DISTANCE * WANDER_MIN_TARGET_DISTANCE
		):
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
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("fill_monsters_near")
	):
		battle.call(
			"fill_monsters_near",
			global_position,
			kite_distance,
			_movement_monster_scratch
		)
	else:
		_movement_monster_scratch.clear()
		_movement_monster_scratch.append_array(
			_get_monster_nodes_cached()
		)

	for node in _movement_monster_scratch:
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
			var retreat_strafe_scale := _get_combat_strafe_scale(to_target)
			retreat = (
				away * 0.86
				+ retreat_tangent * 0.30 * retreat_strafe_scale
			)
		return retreat.normalized()

	# Inside the firing band, stand and shoot most of the time.
	# Brief side-step bursts make the hero reposition without tracing circles.
	if combat_strafe_burst_timer <= 0.0:
		return Vector2.ZERO

	var strafe_scale := _get_combat_strafe_scale(to_target)
	if strafe_scale <= 0.05:
		return Vector2.ZERO
	var tangent := Vector2(-to_target.y, to_target.x) * strafe_sign
	var reposition := away * 0.38 + tangent * 0.62 * strafe_scale
	return reposition.normalized()


func _get_combat_strafe_scale(to_target: Vector2) -> float:
	if hero_archetype != "alchemist_chemical":
		return 1.0

	# When the target is almost directly above/below, tangential strafing is
	# almost pure left/right movement. Suppress it smoothly so the alchemist
	# does not ping-pong horizontally while visually travelling vertically.
	var horizontal_alignment := absf(to_target.x)
	return clampf((horizontal_alignment - 0.12) / 0.28, 0.0, 1.0)


func _is_ranged_ai_archetype() -> bool:
	match hero_archetype:
		"ranged_kiter", "pistol_gunner", "archmage_elementalist", "alchemist_chemical", "summoner_gatekeeper", "cleric_purifier":
			return true
		_:
			return false


func _apply_ranged_boundary_escape(
	base_direction: Vector2,
	soft_margin: float = RANGED_BOUNDARY_SOFT_MARGIN,
	hard_margin: float = RANGED_BOUNDARY_HARD_MARGIN
) -> Vector2:
	var base := (
		base_direction.normalized()
		if base_direction.length_squared() > 0.01
		else Vector2.ZERO
	)
	if not _is_ranged_ai_archetype():
		return base

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
		return base

	var center_direction := global_position.direction_to(battlefield_size * 0.5)
	var near_horizontal_edge := minf(left_space, right_space) < hard_margin
	var near_vertical_edge := minf(top_space, bottom_space) < hard_margin

	# A corner is a hard escape state. Combat avoidance can otherwise point
	# directly into both clamped axes forever, leaving ranged heroes stationary.
	if near_horizontal_edge and near_vertical_edge:
		var corner_escape := inward.normalized() * 2.8 + center_direction * 1.8
		if corner_escape.length_squared() > 0.01:
			return corner_escape.normalized()

	# On a hard edge, guarantee a meaningful inward component even when the
	# current combat/loot steering is zero or points outside the battlefield.
	if near_horizontal_edge or near_vertical_edge:
		var hard_escape := inward.normalized() * 2.7 + base * 0.35
		if hard_escape.length_squared() > 0.01:
			return hard_escape.normalized()

	if base.length_squared() <= 0.01:
		return inward.normalized()

	var pressure := clampf(inward.length(), 0.0, 1.35)
	var inward_weight := lerpf(0.55, 1.75, clampf(pressure, 0.0, 1.0))
	var desired := base + inward.normalized() * inward_weight
	if desired.length_squared() <= 0.01:
		return center_direction.normalized()
	return desired.normalized()


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

	var hp_ratio: float = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	if hp_ratio >= 0.60:
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return

	# Low-HP heroes commit to a valid potion instead of periodically
	# retargeting and oscillating around it.
	if (
		hp_ratio <= 0.40
		and is_instance_valid(heal_item_target)
		and not heal_item_target.is_queued_for_deletion()
	):
		return

	if (
		heal_item_retarget_timer > 0.0
		and is_instance_valid(heal_item_target)
		and not heal_item_target.is_queued_for_deletion()
	):
		return

	heal_item_retarget_timer = randf_range(0.22, 0.38)
	heal_item_target = null

	var desire: float = _heal_item_desire_for_hp(hp_ratio)
	desire *= maxf(float(ai_settings.get("heal_item_desire", 1.0)), 0.0)
	if desire <= 0.0:
		return

	var risk_tolerance: float = clampf(
		float(ai_settings.get("heal_risk_tolerance", 0.50)),
		0.0,
		1.0
	)
	var critical_factor: float = clampf((0.45 - hp_ratio) / 0.35, 0.0, 1.0)
	var best_score: float = -INF
	for node in _get_aux_group_nodes_cached(&"heal_items"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var item := node as Node2D
		if item == null:
			continue

		var distance: float = global_position.distance_to(item.global_position)
		# Moderate HP only justifies a nearby detour. Critical HP may cross
		# the field to secure healing.
		if hp_ratio > 0.40 and distance > 520.0:
			continue

		var path_midpoint: Vector2 = global_position.lerp(item.global_position, 0.5)
		var path_danger: float = _estimate_monster_danger(path_midpoint, 260.0)
		var item_danger: float = _estimate_monster_danger(item.global_position, 220.0)
		var distance_penalty: float = clampf(distance / 1050.0, 0.0, 2.2)
		var danger_scale: float = lerpf(1.0, 0.22, critical_factor)
		var danger_penalty: float = (
			(path_danger * 0.70 + item_danger)
			* lerpf(1.30, 0.50, risk_tolerance)
			* danger_scale
		)
		var score: float = desire * lerpf(4.2, 7.2, critical_factor)
		score -= distance_penalty
		score -= danger_penalty

		if score > best_score and score > 0.05:
			best_score = score
			heal_item_target = item

	if not is_instance_valid(heal_item_target):
		heal_item_steering_direction = Vector2.ZERO


func _heal_item_desire_for_hp(hp_ratio: float) -> float:
	if hp_ratio >= 0.60:
		return 0.0
	if hp_ratio >= 0.45:
		return lerpf(0.20, 0.48, (0.60 - hp_ratio) / 0.15)
	if hp_ratio >= 0.30:
		return lerpf(0.62, 0.88, (0.45 - hp_ratio) / 0.15)
	if hp_ratio >= 0.15:
		return lerpf(1.00, 1.18, (0.30 - hp_ratio) / 0.15)
	return 1.30


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
	for node in _get_aux_group_nodes_cached(&"treasure_chests"):
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
	if (
		is_instance_valid(heal_item_target)
		and max_hp > 0
		and float(current_hp) / float(max_hp) <= 0.45
	):
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

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


func _is_world_position_visible(world_position: Vector2) -> bool:
	if not is_instance_valid(follow_camera):
		return false
	var viewport_size := get_viewport_rect().size
	var zoom := follow_camera.zoom
	var half_width := viewport_size.x * 0.5 / maxf(zoom.x, 0.01)
	var half_height := viewport_size.y * 0.5 / maxf(zoom.y, 0.01)
	var offset := world_position - global_position
	var margin := 52.0
	return (
		absf(offset.x) <= half_width + margin
		and absf(offset.y) <= half_height + margin
	)


func _update_magnet_item_goal(delta: float) -> void:
	magnet_item_retarget_timer = maxf(
		magnet_item_retarget_timer - delta,
		0.0
	)
	if (
		is_instance_valid(magnet_item_target)
		and not magnet_item_target.is_queued_for_deletion()
		and _is_world_position_visible(
			magnet_item_target.global_position
		)
		and magnet_item_retarget_timer > 0.0
	):
		return

	magnet_item_target = null
	magnet_item_retarget_timer = 0.30
	var best_distance := INF
	for node in _get_aux_group_nodes_cached(&"magnet_items"):
		if (
			not is_instance_valid(node)
			or node.is_queued_for_deletion()
		):
			continue
		var item := node as Node2D
		if (
			item == null
			or not _is_world_position_visible(item.global_position)
		):
			continue
		var distance_sq := global_position.distance_squared_to(
			item.global_position
		)
		if distance_sq < best_distance:
			best_distance = distance_sq
			magnet_item_target = item

	if not is_instance_valid(magnet_item_target):
		magnet_item_steering_direction = Vector2.ZERO


func _apply_magnet_item_steering(
	base_direction: Vector2,
	delta: float
) -> Vector2:
	if (
		is_instance_valid(heal_item_target)
		and max_hp > 0
		and float(current_hp) / float(max_hp) <= 0.45
	):
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	if (
		not is_instance_valid(magnet_item_target)
		or magnet_item_target.is_queued_for_deletion()
		or not _is_world_position_visible(
			magnet_item_target.global_position
		)
	):
		magnet_item_target = null
		magnet_item_steering_direction = Vector2.ZERO
		return (
			base_direction.normalized()
			if base_direction.length_squared() > 0.01
			else Vector2.ZERO
		)

	var distance := global_position.distance_to(
		magnet_item_target.global_position
	)
	var item_direction := global_position.direction_to(
		magnet_item_target.global_position
	)

	# Visible magnets are tempting, but combat movement remains dominant.
	var magnet_weight := lerpf(
		0.24,
		0.38,
		clampf(1.0 - distance / 720.0, 0.0, 1.0)
	)
	var local_danger := _estimate_monster_danger(
		global_position,
		210.0
	)
	magnet_weight /= 1.0 + local_danger * 0.22

	var desired := (
		base_direction
		+ item_direction * magnet_weight
	)
	if desired.length_squared() <= 0.01:
		desired = item_direction
	desired = desired.normalized()

	if magnet_item_steering_direction.length_squared() <= 0.01:
		magnet_item_steering_direction = desired
	else:
		magnet_item_steering_direction = (
			magnet_item_steering_direction.lerp(
				desired,
				clampf(delta * 3.2, 0.0, 1.0)
			).normalized()
		)
	return magnet_item_steering_direction


func _damage_treasure_chests(origin: Vector2, radius: float, damage: int) -> void:
	for node in _get_aux_group_nodes_cached(&"treasure_chests"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if (
			chest == null
			or origin.distance_squared_to(chest.global_position)
			> radius * radius
		):
			continue
		if chest.has_method("take_damage"):
			chest.call("take_damage", maxi(damage, 1))


func _apply_heal_item_steering(base_direction: Vector2, delta: float) -> Vector2:
	if not is_instance_valid(heal_item_target) or heal_item_target.is_queued_for_deletion():
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	var hp_ratio: float = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	var desire: float = _heal_item_desire_for_hp(hp_ratio)
	desire *= maxf(float(ai_settings.get("heal_item_desire", 1.0)), 0.0)
	var risk_tolerance: float = clampf(
		float(ai_settings.get("heal_risk_tolerance", 0.50)),
		0.0,
		1.0
	)
	var detour_weight: float = maxf(
		float(ai_settings.get("heal_detour_weight", 1.0)),
		0.0
	)

	var heal_direction: Vector2 = global_position.direction_to(
		heal_item_target.global_position
	)
	if heal_direction.length_squared() <= 0.01:
		return Vector2.ZERO

	var distance_to_heal: float = global_position.distance_to(
		heal_item_target.global_position
	)
	var avoidance: Vector2 = _get_crowd_avoidance_direction(240.0)
	var local_danger: float = _estimate_monster_danger(global_position, 210.0)
	var critical_factor: float = clampf((0.50 - hp_ratio) / 0.20, 0.0, 1.0)

	# Human-like potion behavior:
	# from far away, drift toward the potion while still fighting / avoiding;
	# once close enough, progressively commit so the hero actually finishes
	# the pickup instead of circling just outside the collection radius.
	var close_commit: float = clampf(
		(220.0 - distance_to_heal) / 150.0,
		0.0,
		1.0
	)
	var heal_weight: float = clampf(
		desire
		* lerpf(1.10, 1.75, critical_factor)
		* lerpf(1.0, 1.65, close_commit),
		0.0,
		2.60
	)
	var combat_weight: float = lerpf(
		maxf(0.38, 1.0 - heal_weight * 0.45),
		0.16,
		close_commit * lerpf(0.55, 1.0, critical_factor)
	)
	var avoidance_weight: float = (
		(0.55 + local_danger * 0.28)
		* lerpf(1.12, 0.68, risk_tolerance)
		* detour_weight
		* lerpf(1.0, 0.35, critical_factor)
		* lerpf(1.0, 0.18, close_commit)
	)

	var desired: Vector2 = (
		base_direction * combat_weight
		+ heal_direction * heal_weight
	)
	if avoidance.length_squared() > 0.01:
		desired += avoidance * avoidance_weight

	# Inside the final approach, keep a small amount of natural movement but
	# bias strongly enough toward the potion to cross the pickup threshold.
	if distance_to_heal <= 95.0:
		desired = (
			desired * 0.28
			+ heal_direction * 1.45
		)

	if desired.length_squared() <= 0.01:
		desired = heal_direction
	desired = desired.normalized()

	if heal_item_steering_direction.length_squared() <= 0.01:
		heal_item_steering_direction = desired
	else:
		var turn_speed: float = lerpf(
			4.2,
			8.5,
			maxf(critical_factor, close_commit)
		)
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

func _acquire_projectile(scene: PackedScene, pool_key: String) -> Area2D:
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("acquire_projectile"):
		var pooled = parent.call("acquire_projectile", scene, pool_key)
		if pooled is Area2D:
			return pooled as Area2D

	var projectile := scene.instantiate() as Area2D
	if projectile != null and is_instance_valid(parent):
		parent.add_child(projectile)
	return projectile


func _ensure_purifier_basic_audio() -> void:
	if hero_archetype != "cleric_purifier":
		return
	if is_instance_valid(purifier_basic_audio):
		return

	purifier_basic_audio = AudioStreamPlayer.new()
	purifier_basic_audio.bus = &"SFX"
	purifier_basic_audio.volume_db = -13.0
	# The source is a broader elemental projectile sound. A slightly higher
	# pitch keeps the purifier version brighter and distinct from Stage 8.
	purifier_basic_audio.pitch_scale = 1.12
	if ResourceLoader.exists(PURIFIER_BASIC_ATTACK_AUDIO_PATH):
		var stream = load(PURIFIER_BASIC_ATTACK_AUDIO_PATH)
		if stream is AudioStream:
			purifier_basic_audio.stream = stream
	add_child(purifier_basic_audio)


func _play_purifier_basic_audio() -> void:
	_ensure_purifier_basic_audio()
	if (
		is_instance_valid(purifier_basic_audio)
		and purifier_basic_audio.stream != null
	):
		# One player per hero; restarting avoids overlapping a long tail every
		# 1.35s while keeping allocation-free repeated basic attacks.
		purifier_basic_audio.stop()
		purifier_basic_audio.play()


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
	if hero_archetype == "cleric_purifier":
		_play_purifier_basic_audio()

	var projectile_count := 1 + clampi(projectile_count_bonus, 0, 4)
	var spread_step := deg_to_rad(12.0)
	var center_index := float(projectile_count - 1) * 0.5
	for index in range(projectile_count):
		var angle_offset := (float(index) - center_index) * spread_step
		var projectile_direction := shot_direction.rotated(angle_offset).normalized()
		var projectile := _acquire_projectile(
			PROJECTILE_SCENE,
			"hero_basic_projectile"
		)
		if projectile == null:
			continue
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
	var projectile := _acquire_projectile(
		ARCHMAGE_PROJECTILE_SCENE,
		"archmage_projectile"
	)
	if projectile == null:
		return
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

	if archmage_blink_stacks > 0:
		archmage_blink_cooldown_timer = maxf(
			archmage_blink_cooldown_timer - delta,
			0.0
		)
		if (
			archmage_blink_cooldown_timer <= 0.0
			and _archmage_is_surrounded_for_blink()
		):
			_cast_archmage_blink()

	_add_archmage_gauge(
		maxf(float(archmage_skill_config.get("gauge_per_second", 3.0)), 0.0) * delta
	)
	archmage_orbit_angle = fmod(archmage_orbit_angle + delta * 1.9, TAU)
	_update_archmage_orbit_positions()

	if archmage_casting_sequence or archmage_multicast_active:
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
	_cast_archmage_skill_internal(skill_key, true, true)


func _cast_archmage_skill_internal(
	skill_key: String,
	consume_gauge: bool,
	trigger_multicast: bool
) -> bool:
	var config: Dictionary = archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return false
	if skill_key == "chain_dagger" and archmage_chain_dagger_active:
		return false

	if consume_gauge:
		var gauge_max := maxf(
			float(archmage_skill_config.get("gauge_max", 100.0)),
			1.0
		)
		if ultimate_charge + 0.001 < gauge_max:
			return false

	var empowered := false
	if skill_key != "harmony" and _archmage_has_all_element_orbs():
		empowered = true
		archmage_element_orbs.clear()
		_refresh_archmage_orbit_visuals()

	if consume_gauge:
		ultimate_charge = 0.0
	ultimate_flash_timer = 0.28

	var cooldown_multiplier := maxf(
		1.0 - archmage_cooldown_reduction,
		0.10
	)
	archmage_skill_cooldowns[skill_key] = (
		maxf(float(config.get("cooldown", 0.0)), 0.0)
		* cooldown_multiplier
	)
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
		_:
			return false

	if archmage_mana_overflow_stacks > 0:
		var gauge_per_stack := 4.0 if consume_gauge else 1.0
		_add_archmage_gauge(
			gauge_per_stack * float(archmage_mana_overflow_stacks)
		)

	ultimate_used.emit(
		String(config.get("id", skill_key)),
		String(config.get("name", skill_key))
	)
	queue_redraw()

	if (
		trigger_multicast
		and archmage_multicast_stacks > 0
		and not archmage_multicast_active
	):
		_start_archmage_multicast(skill_key)

	return true


func _start_archmage_multicast(origin_skill: String) -> void:
	var candidates: Array[String] = []
	for key in [
		"combustion",
		"ice_bolt",
		"earth_spikes",
		"holy_power",
		"chain_dagger",
		"storm",
	]:
		if key == origin_skill:
			continue
		if not archmage_skill_config.has(key):
			continue
		if key == "chain_dagger" and archmage_chain_dagger_active:
			continue
		candidates.append(key)

	if candidates.is_empty():
		return

	candidates.shuffle()
	archmage_multicast_active = true
	var wanted := mini(archmage_multicast_stacks, candidates.size())
	var casted := 0

	while casted < wanted and not candidates.is_empty():
		await get_tree().create_timer(0.30).timeout
		if not is_inside_tree() or current_hp <= 0:
			break

		var extra_skill := String(candidates.pop_back())
		if _cast_archmage_skill_internal(extra_skill, false, false):
			casted += 1

	archmage_multicast_active = false

func _skill_damage_multiplier(empowered: bool) -> float:
	return (
		maxf(float(archmage_skill_config.get("empowered_damage_multiplier", 1.50)), 1.0)
		if empowered
		else 1.0
	)


func _begin_archmage_casting_sequence() -> void:
	archmage_casting_sequence_count += 1
	archmage_casting_sequence = true


func _end_archmage_casting_sequence() -> void:
	archmage_casting_sequence_count = maxi(
		archmage_casting_sequence_count - 1,
		0
	)
	archmage_casting_sequence = archmage_casting_sequence_count > 0


func _cast_archmage_combustion(config: Dictionary, empowered: bool) -> void:
	_begin_archmage_casting_sequence()
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
		_recycle_archmage_fx(charge_fx)
	if not is_inside_tree() or current_hp <= 0:
		_end_archmage_casting_sequence()
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
	_end_archmage_casting_sequence()


func _cast_archmage_ice_bolt(config: Dictionary, empowered: bool) -> void:
	var current_target := _find_farthest_monster_from_point(global_position)
	if not is_instance_valid(current_target):
		return
	var direction := global_position.direction_to(current_target.global_position)
	var projectile := _acquire_projectile(
		ARCHMAGE_SKILL_PROJECTILE_SCENE,
		"archmage_skill_projectile"
	)
	if projectile == null:
		return
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
	var config: Dictionary = archmage_skill_config.get(
		"ice_bolt",
		{}
	)
	var impact_radius := maxf(
		float(config.get("impact_radius", 125.0)),
		1.0
	)
	var impact_damage := maxi(
		1,
		int(
			round(
				float(attack_damage)
				* float(config.get("impact_damage_ratio", 1.50))
				* _skill_damage_multiplier(empowered)
			)
		)
	)
	_damage_monsters_in_radius(
		hit_position,
		impact_radius,
		impact_damage
	)
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
	_begin_archmage_casting_sequence()
	var direction := Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	var count: int = maxi(int(config.get("spike_count", 7)), 1)
	var spacing: float = maxf(float(config.get("spike_spacing", 88.0)), 1.0)
	var radius: float = maxf(float(config.get("spike_radius", 70.0)), 1.0)
	var spike_damage: int = maxi(1, int(round(
		float(attack_damage) * float(config.get("damage_ratio", 1.20)) * _skill_damage_multiplier(empowered)
	)))
	var spike_delay: float = maxf(float(config.get("spike_delay", 0.07)), 0.02)
	var cast_origin: Vector2 = global_position
	var hit_ids: Dictionary = {}

	for index in range(count):
		if not is_inside_tree() or current_hp <= 0:
			break
		var position: Vector2 = cast_origin + direction * spacing * float(index + 1)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect1",
			"earth", 1, 11, 22.0, false, position, Vector2(0.72, 0.72)
		)
		_damage_monsters_in_radius_once(position, radius, spike_damage, hit_ids)
		await get_tree().create_timer(spike_delay).timeout

	if is_inside_tree() and current_hp > 0:
		var original_distance: float = spacing * float(count)
		var branch_distance: float = original_distance * clampf(
			float(config.get("branch_distance_ratio", 0.50)),
			0.0,
			2.0
		)
		if branch_distance > 0.0:
			var endpoint: Vector2 = cast_origin + direction * original_distance
			var branch_count: int = maxi(int(ceil(branch_distance / spacing)), 1)
			var left_direction: Vector2 = direction.rotated(PI * 0.5)
			var right_direction: Vector2 = direction.rotated(-PI * 0.5)

			for branch_index in range(branch_count):
				if not is_inside_tree() or current_hp <= 0:
					break
				var progress: float = float(branch_index + 1) / float(branch_count)
				var left_position: Vector2 = (
					endpoint + left_direction * branch_distance * progress
				)
				var right_position: Vector2 = (
					endpoint + right_direction * branch_distance * progress
				)

				_spawn_archmage_fx(
					"res://assets/art/heroes/stage5_archmage/frames/effect1",
					"earth", 1, 11, 22.0, false,
					left_position, Vector2(0.72, 0.72)
				)
				_damage_monsters_in_radius_once(
					left_position,
					radius,
					spike_damage,
					hit_ids
				)

				_spawn_archmage_fx(
					"res://assets/art/heroes/stage5_archmage/frames/effect1",
					"earth", 1, 11, 22.0, false,
					right_position, Vector2(0.72, 0.72)
				)
				_damage_monsters_in_radius_once(
					right_position,
					radius,
					spike_damage,
					hit_ids
				)
				await get_tree().create_timer(spike_delay).timeout

	_end_archmage_casting_sequence()

func _find_archmage_holy_cluster_target(config: Dictionary) -> Node2D:
	var search_radius: float = maxf(
		float(config.get("cluster_search_radius", 850.0)),
		1.0
	)
	var cluster_radius: float = maxf(
		float(config.get("cluster_score_radius", 190.0)),
		1.0
	)
	var best: Node2D = null
	var best_count: int = -1
	var best_distance_sq: float = INF

	for node in _get_monster_nodes_near(global_position, search_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var distance_sq: float = global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > search_radius * search_radius:
			continue

		var nearby_count: int = _count_monsters_near(
			monster.global_position,
			cluster_radius
		)
		if nearby_count > best_count:
			best = monster
			best_count = nearby_count
			best_distance_sq = distance_sq
		elif nearby_count == best_count and distance_sq < best_distance_sq:
			best = monster
			best_distance_sq = distance_sq

	return best


func _cast_archmage_holy_power(config: Dictionary, empowered: bool) -> void:
	_begin_archmage_casting_sequence()

	var cluster_target: Node2D = _find_archmage_holy_cluster_target(config)
	if not is_instance_valid(cluster_target):
		_end_archmage_casting_sequence()
		return

	var cast_center: Vector2 = cluster_target.global_position
	var count: int = maxi(int(config.get("burst_count", 7)), 1)
	var spawn_radius: float = maxf(
		float(config.get("burst_spawn_radius", 210.0)),
		1.0
	)
	var hit_radius: float = maxf(
		float(config.get("burst_hit_radius", 86.0)),
		1.0
	)
	var base_damage: int = maxi(1, int(round(
		float(attack_damage)
		* float(config.get("damage_ratio", 0.90))
		* _skill_damage_multiplier(empowered)
	)))

	for index in range(count):
		if not is_inside_tree() or current_hp <= 0:
			break

		var angle: float = randf_range(0.0, TAU)
		var position: Vector2 = (
			cast_center
			+ Vector2.from_angle(angle) * randf_range(0.0, spawn_radius)
		)
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
			if position.distance_squared_to(monster.global_position) > hit_radius * hit_radius:
				continue

			var dealt: int = base_damage
			if bool(monster.get_meta("undead", false)) or bool(
				monster.get_meta("is_undead", false)
			):
				dealt = maxi(
					1,
					int(round(
						float(dealt)
						* float(config.get("undead_damage_multiplier", 1.70))
					))
				)

			monster.call("take_damage", dealt)
			monster.set_meta(
				"gunner_slow_multiplier",
				clampf(
					float(config.get("slow_multiplier", 0.60)),
					0.0,
					1.0
				)
			)
			monster.set_meta(
				"gunner_slow_until",
				Time.get_ticks_msec()
				+ int(
					maxf(
						float(config.get("slow_duration", 2.0)),
						0.0
					) * 1000.0
				)
			)

		await get_tree().create_timer(
			maxf(float(config.get("burst_delay", 0.09)), 0.02)
		).timeout

	_end_archmage_casting_sequence()

func _get_archmage_chain_dagger_targets(
	max_count: int,
	search_radius: float
) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	var radius_sq := search_radius * search_radius
	for node in _get_monster_nodes_near(global_position, search_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		candidates.append(monster)

	if candidates.is_empty():
		return []

	var result: Array[Node2D] = []
	if (
		is_instance_valid(target)
		and target.is_in_group("monsters")
		and global_position.distance_squared_to(target.global_position)
		<= radius_sq
	):
		result.append(target)

	while result.size() < max_count and result.size() < candidates.size():
		var best: Node2D = null
		var best_score := -INF
		for candidate in candidates:
			if candidate in result:
				continue
			var direction := global_position.direction_to(
				candidate.global_position
			)
			if direction.length_squared() <= 0.001:
				continue

			var min_angle := PI
			if not result.is_empty():
				for chosen in result:
					var chosen_direction := global_position.direction_to(
						chosen.global_position
					)
					min_angle = minf(
						min_angle,
						absf(direction.angle_to(chosen_direction))
					)

			var distance_ratio := clampf(
				global_position.distance_to(candidate.global_position)
				/ maxf(search_radius, 1.0),
				0.0,
				1.0
			)
			# Prefer a wide fan first, then slightly favor nearer targets.
			var score := min_angle * 3.0 + (1.0 - distance_ratio) * 0.35
			if score > best_score:
				best_score = score
				best = candidate

		if not is_instance_valid(best):
			break
		result.append(best)

	if result.is_empty():
		result.append(candidates[0])
	return result


func _cast_archmage_chain_dagger(config: Dictionary, empowered: bool) -> void:
	var projectile_range := maxf(
		float(config.get("projectile_range", 900.0)),
		1.0
	)
	var projectile_count := 1 + archmage_chain_multithrow_stacks
	var targets := _get_archmage_chain_dagger_targets(
		projectile_count,
		projectile_range
	)
	if targets.is_empty():
		return

	archmage_chain_dagger_active_count += targets.size()
	archmage_chain_dagger_active = (
		archmage_chain_dagger_active_count > 0
	)

	for current_target in targets:
		if not is_instance_valid(current_target):
			notify_archmage_chain_dagger_finished()
			continue
		var direction := global_position.direction_to(
			current_target.global_position
		)
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT

		var projectile := (
			ARCHMAGE_SKILL_PROJECTILE_SCENE.instantiate()
			as Area2D
		)
		get_parent().add_child(projectile)
		projectile.add_to_group(
			"archmage_chain_dagger_projectile"
		)
		projectile.global_position = (
			global_position + direction.normalized() * 58.0
		)
		projectile.call(
			"setup",
			"chain_dagger",
			direction,
			maxi(
				1,
				int(
					round(
						float(attack_damage)
						* float(config.get("damage_ratio", 1.0))
					)
				)
			),
			float(config.get("projectile_speed", 700.0)),
			projectile_range,
			config,
			self,
			empowered,
			current_target
		)


func notify_archmage_chain_dagger_finished() -> void:
	archmage_chain_dagger_active_count = maxi(
		archmage_chain_dagger_active_count - 1,
		0
	)
	archmage_chain_dagger_active = (
		archmage_chain_dagger_active_count > 0
	)


func _archmage_is_surrounded_for_blink() -> bool:
	if archmage_blink_stacks <= 0:
		return false
	return _count_monsters_near(
		global_position,
		230.0,
		5
	) >= 5


func _archmage_blink_cooldown() -> float:
	return maxf(
		30.0 - float(maxi(archmage_blink_stacks - 1, 0)) * 3.0,
		18.0
	)


func _cast_archmage_blink() -> void:
	if archmage_blink_stacks <= 0:
		return

	var start_position := global_position
	var repulsion := Vector2.ZERO
	for node in _get_monster_nodes_near(global_position, 460.0):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := global_position - monster.global_position
		var distance_sq := offset.length_squared()
		if distance_sq <= 0.001:
			continue
		repulsion += offset.normalized() / maxf(
			sqrt(distance_sq),
			1.0
		)

	var preferred := (
		repulsion.normalized()
		if repulsion.length_squared() > 0.001
		else Vector2.RIGHT
	)
	var best_position := start_position
	var best_score := INF
	var blink_distance := 700.0

	for index in range(20):
		var direction := Vector2.from_angle(
			TAU * float(index) / 20.0
		)
		var raw_target := start_position + direction * blink_distance
		var candidate := Vector2(
			clampf(
				raw_target.x,
				FIELD_MARGIN,
				battlefield_size.x - FIELD_MARGIN
			),
			clampf(
				raw_target.y,
				FIELD_MARGIN,
				battlefield_size.y - FIELD_MARGIN
			)
		)
		var actual_distance := start_position.distance_to(candidate)
		if actual_distance < 120.0:
			continue

		var nearby_count := _count_monsters_near(
			candidate,
			320.0
		)
		var alignment_penalty := (
			1.0 - direction.dot(preferred)
		) * 2.5
		var distance_loss := (
			blink_distance - actual_distance
		) / blink_distance
		var score := (
			float(nearby_count) * 100.0
			+ alignment_penalty
			+ distance_loss * 12.0
		)
		if score < best_score:
			best_score = score
			best_position = candidate

	if best_position == start_position:
		return

	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect8",
		"wind",
		1,
		9,
		24.0,
		false,
		start_position,
		Vector2(0.86, 0.86)
	)
	global_position = best_position
	velocity = Vector2.ZERO
	_clamp_to_battlefield()
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect8",
		"wind",
		1,
		9,
		24.0,
		false,
		global_position,
		Vector2(0.86, 0.86)
	)
	archmage_blink_cooldown_timer = _archmage_blink_cooldown()


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
		var projectile := _acquire_projectile(
			ARCHMAGE_SKILL_PROJECTILE_SCENE,
			"archmage_skill_projectile"
		)
		if projectile == null:
			continue
		projectile.global_position = global_position + direction * 56.0
		projectile.call(
			"setup", "storm", direction,
			maxi(1, int(round(float(attack_damage) * float(config.get("damage_ratio", 0.75))))),
			float(config.get("projectile_speed", 350.0)),
			float(config.get("projectile_range", 950.0)),
			config, self, empowered, null
		)


func _collect_archmage_element(element: String) -> void:
	if element.is_empty():
		return

	var already_owned := bool(
		archmage_element_orbs.get(element, false)
	)
	archmage_element_orbs[element] = true

	if (
		already_owned
		and archmage_element_cycle_stacks > 0
		and randf() <= 0.25 * float(archmage_element_cycle_stacks)
	):
		var missing: Array[String] = []
		for candidate in [
			"fire",
			"water",
			"wind",
			"electric",
			"earth",
			"holy",
		]:
			if not bool(archmage_element_orbs.get(candidate, false)):
				missing.append(candidate)
		if not missing.is_empty():
			archmage_element_orbs[
				String(missing.pick_random())
			] = true

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
			var texture := _load_stage1_texture(
				"%s/%s_%02d.png" % [dir, prefix, index]
			)
			if texture != null:
				frames.add_frame("fx", texture)
		_archmage_fx_frames_cache[cache_key] = frames

	if frames.get_frame_count("fx") <= 0:
		return null

	var parent := get_parent()
	if not is_instance_valid(parent):
		return null

	var fx: AnimatedSprite2D = null
	if parent.has_method("acquire_transient_fx"):
		fx = parent.call(
			"acquire_transient_fx",
			"archmage_cast_fx",
			"animated_sprite"
		) as AnimatedSprite2D
	if fx == null:
		fx = AnimatedSprite2D.new()
		parent.add_child(fx)

	fx.stop()
	fx.sprite_frames = frames
	fx.animation = &"fx"
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 7
	fx.global_position = world_position
	fx.scale = fx_scale
	fx.rotation = 0.0
	fx.modulate = Color.WHITE
	fx.frame = 0
	fx.frame_progress = 0.0
	fx.visible = true

	if not looped:
		if parent.has_method("recycle_transient_fx"):
			fx.animation_finished.connect(
				Callable(parent, "recycle_transient_fx").bind(
					fx,
					"archmage_cast_fx"
				),
				Object.CONNECT_ONE_SHOT
			)
		else:
			fx.animation_finished.connect(
				Callable(fx, "queue_free"),
				Object.CONNECT_ONE_SHOT
			)

	fx.play(&"fx")
	return fx


func _recycle_archmage_fx(fx: AnimatedSprite2D) -> void:
	if not is_instance_valid(fx):
		return
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_transient_fx"):
		parent.call("recycle_transient_fx", fx, "archmage_cast_fx")
	else:
		fx.queue_free()


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
	var adjusted_amount: int = amount
	if hero_archetype == "berserker_madness":
		adjusted_amount = maxi(
			int(round(
				float(amount)
				* berserker_double_edged_heal_multiplier
			)),
			1
		)
	var previous_hp := current_hp
	current_hp = mini(current_hp + adjusted_amount, max_hp)
	var recovered := current_hp - previous_hp
	if recovered > 0:
		DAMAGE_NUMBERS.show_heal(self, recovered)
		health_changed.emit(current_hp, max_hp)
		queue_redraw()
	return recovered


func _get_common_attack_interval(base_interval: float) -> float:
	return maxf(
		base_interval / (1.0 + maxf(common_attack_speed_bonus, 0.0)),
		0.06
	)


func get_runtime_info_stats() -> Dictionary:
	# 전투 정보창 전용 값. 프로필 원본이 아니라 레벨업/Run 증강이
	# 반영된 현재 런타임 스탯을 반환한다.
	# 향후 용사 도감은 HeroProfiles 원본 데이터를 직접 사용한다.
	return {
		"max_hp": max_hp,
		"attack_damage": attack_damage,
		"move_speed": move_speed * _get_purifier_move_speed_multiplier(),
		"attack_interval": _get_common_attack_interval(attack_cooldown),
		"attack_range": attack_range,
		"projectile_speed": projectile_speed,
		"exp_pickup_radius": exp_pickup_radius,
	}


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

	var nearby := _count_monsters_near(
		global_position,
		radius,
		force_count
	)
	if nearby >= force_count:
		return true
	if nearby < required_count or close_radius <= 0.0:
		return false

	return _count_monsters_near(
		global_position,
		close_radius,
		close_required
	) >= close_required

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
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius * radius
		):
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

	return _count_monsters_near(
		global_position,
		danger_radius,
		danger_count
	) >= danger_count

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

func _build_purifier_effect_frames(
	effect_dir: String,
	start_first: int,
	start_last: int,
	sustain_first: int,
	sustain_last: int,
	end_first: int,
	end_last: int
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"start")
	frames.set_animation_loop(&"start", false)
	frames.set_animation_speed(&"start", 10.0)
	for frame_index in range(start_first, start_last + 1):
		var texture := _load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"start", texture)

	frames.add_animation(&"sustain")
	frames.set_animation_loop(&"sustain", true)
	frames.set_animation_speed(&"sustain", 7.0)
	for frame_index in range(sustain_first, sustain_last + 1):
		var texture := _load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"sustain", texture)

	frames.add_animation(&"end")
	frames.set_animation_loop(&"end", false)
	frames.set_animation_speed(&"end", 10.0)
	for frame_index in range(end_first, end_last + 1):
		var texture := _load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"end", texture)
	return frames


func _create_purifier_audio_player(
	audio_path: String,
	volume_db: float,
	pitch_scale: float = 1.0
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	if ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream is AudioStream:
			player.stream = stream
	add_child(player)
	return player


func _ensure_purifier_skill_runtime() -> void:
	if hero_archetype != "cleric_purifier":
		return

	if not is_instance_valid(purifier_protection_effect):
		if _purifier_protection_frames_cache == null:
			var effect_dir := String(
				purifier_protection_config.get(
					"effect_dir",
					"%s/effect4" % STAGE9_FRAME_DIR
				)
			)
			_purifier_protection_frames_cache = _build_purifier_effect_frames(
				effect_dir, 23, 24, 24, 26, 27, 28
			)
		purifier_protection_effect = AnimatedSprite2D.new()
		purifier_protection_effect.sprite_frames = _purifier_protection_frames_cache
		purifier_protection_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		purifier_protection_effect.scale = hero_sprite.scale
		# Divine Protection should stay readable without covering the hero body.
		# self_modulate keeps the effect at a consistent 50% opacity.
		purifier_protection_effect.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		purifier_protection_effect.offset = Vector2(16.0, -24.0)
		purifier_protection_effect.z_index = 8
		purifier_protection_effect.visible = false
		purifier_protection_effect.animation_finished.connect(
			Callable(self, "_on_purifier_protection_effect_finished")
		)
		add_child(purifier_protection_effect)

	if not is_instance_valid(purifier_crown_effect):
		if _purifier_crown_frames_cache == null:
			var effect_dir := String(
				purifier_crown_config.get(
					"effect_dir",
					"%s/effect3" % STAGE9_FRAME_DIR
				)
			)
			_purifier_crown_frames_cache = _build_purifier_effect_frames(
				effect_dir, 17, 18, 19, 20, 21, 22
			)
		purifier_crown_effect = AnimatedSprite2D.new()
		purifier_crown_effect.sprite_frames = _purifier_crown_frames_cache
		purifier_crown_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# The raw effect3 crown is visually larger than the Stage 9 head.
		# Keep it compact and attached to the same horizontal visual anchor as
		# the animated hero frames so it does not drift a few pixels per frame.
		purifier_crown_effect.scale = hero_sprite.scale * 0.78
		# Center the crown on the gameplay/root X, then place it directly above
		# the head. Demon Castle Y-sort normalizes HeroSprite to z=0 after _ready().
		# Keep the crown on that same behind-parent layer: HeroSprite is an earlier
		# child, so Crown draws over the body, while Hero._draw() bars stay on top.
		purifier_crown_effect.offset = Vector2(0.0, -24.0)
		purifier_crown_effect.position = Vector2(0.0, -36.0)
		purifier_crown_effect.show_behind_parent = true
		purifier_crown_effect.z_index = 0
		purifier_crown_effect.visible = false
		purifier_crown_effect.animation_finished.connect(
			Callable(self, "_on_purifier_crown_effect_finished")
		)
		add_child(purifier_crown_effect)

	if not is_instance_valid(purifier_shield_create_audio):
		purifier_shield_create_audio = _create_purifier_audio_player(
			String(purifier_protection_config.get(
				"create_audio_path",
				PURIFIER_SHIELD_CREATE_AUDIO_PATH
			)),
			-12.0,
			1.08
		)
	if not is_instance_valid(purifier_shield_break_audio):
		purifier_shield_break_audio = _create_purifier_audio_player(
			String(purifier_protection_config.get(
				"break_audio_path",
				PURIFIER_SHIELD_BREAK_AUDIO_PATH
			)),
			-11.0,
			0.82
		)
	if not is_instance_valid(purifier_crown_audio):
		purifier_crown_audio = _create_purifier_audio_player(
			String(purifier_crown_config.get(
				"audio_path",
				PURIFIER_CROWN_AUDIO_PATH
			)),
			-13.0,
			1.12
		)


func _play_purifier_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _on_purifier_protection_effect_finished() -> void:
	if not is_instance_valid(purifier_protection_effect):
		return
	if purifier_protection_effect.animation == &"start":
		if purifier_protection_active:
			purifier_protection_effect.play(&"sustain")
		else:
			purifier_protection_effect.visible = false
	elif purifier_protection_effect.animation == &"end":
		purifier_protection_effect.visible = false


func _on_purifier_crown_effect_finished() -> void:
	if not is_instance_valid(purifier_crown_effect):
		return
	if purifier_crown_effect.animation == &"start":
		if purifier_crown_stacks > 0:
			purifier_crown_effect.play(&"sustain")
		else:
			purifier_crown_effect.visible = false
	elif purifier_crown_effect.animation == &"end":
		purifier_crown_effect.visible = false


func _play_purifier_effect(effect: AnimatedSprite2D, animation_name: StringName) -> void:
	if (
		not is_instance_valid(effect)
		or effect.sprite_frames == null
		or not effect.sprite_frames.has_animation(animation_name)
		or effect.sprite_frames.get_frame_count(animation_name) <= 0
	):
		return
	effect.visible = true
	effect.stop()
	effect.animation = animation_name
	effect.frame = 0
	effect.frame_progress = 0.0
	effect.play(animation_name)


func _get_purifier_skill_cooldown_multiplier() -> float:
	if hero_archetype != "cleric_purifier" or purifier_crown_stacks <= 0:
		return 1.0
	return maxf(
		1.0
		- float(purifier_crown_config.get("cooldown_reduction_per_stack", 0.04))
		* float(purifier_crown_stacks),
		0.20
	)


func _get_purifier_move_speed_multiplier() -> float:
	if hero_archetype != "cleric_purifier" or purifier_crown_stacks <= 0:
		return 1.0
	return 1.0 + maxf(
		float(purifier_crown_config.get("move_speed_per_stack", 0.02)),
		0.0
	) * float(purifier_crown_stacks)


func _is_purifier_undead_target(target_node: Node) -> bool:
	if not is_instance_valid(target_node):
		return false
	if (
		bool(target_node.get_meta("undead", false))
		or bool(target_node.get_meta("is_undead", false))
		or target_node.is_in_group("undead")
	):
		return true
	var monster_type_value = target_node.get("monster_type")
	if monster_type_value == null:
		return false
	var monster_type := String(monster_type_value).to_lower()
	return (
		"undead" in monster_type
		or "skeleton" in monster_type
		or "zombie" in monster_type
		or "ghoul" in monster_type
	)


func get_purifier_holy_damage_multiplier(target_node: Node = null) -> float:
	if hero_archetype != "cleric_purifier":
		return 1.0
	var multiplier := (
		1.0
		+ maxf(
			float(purifier_crown_config.get("holy_damage_per_stack", 0.05)),
			0.0
		) * float(purifier_crown_stacks)
	)
	if shield_hp > 0.0:
		multiplier *= maxf(
			float(purifier_protection_config.get("holy_damage_multiplier", 1.15)),
			0.0
		)
	if _is_purifier_undead_target(target_node):
		multiplier *= (
			1.0
			+ maxf(
				float(purifier_crown_config.get("undead_damage_per_stack", 0.10)),
				0.0
			) * float(purifier_crown_stacks)
		)
	return multiplier


func notify_monster_kill(_monster_type: String = "") -> void:
	if hero_archetype != "cleric_purifier" or is_dying or current_hp <= 0:
		return
	_add_purifier_gauge(
		maxf(float(purifier_gauge_config.get("charge_per_kill", 2.0)), 0.0)
	)
	_try_activate_purifier_protection()


func _add_purifier_shield_layer() -> void:
	var layer_amount := maxf(
		float(max_hp)
		* maxf(
			float(purifier_protection_config.get("shield_hp_ratio_per_tick", 0.01)),
			0.0
		),
		1.0
	)
	shield_max_hp += layer_amount
	shield_hp += layer_amount
	queue_redraw()


func _try_activate_purifier_protection() -> void:
	if (
		hero_archetype != "cleric_purifier"
		or purifier_protection_config.is_empty()
		or purifier_protection_active
		or purifier_protection_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return
	var gauge_max := maxf(
		float(purifier_gauge_config.get("charge_max", 100.0)),
		1.0
	)
	if ultimate_charge + 0.001 < gauge_max:
		return

	ultimate_charge = 0.0
	purifier_protection_active = true
	purifier_protection_break_triggered = false
	purifier_protection_duration_timer = maxf(
		float(purifier_protection_config.get("duration", 20.0)),
		0.1
	)
	purifier_protection_tick_timer = maxf(
		float(purifier_protection_config.get("shield_tick_interval", 1.0)),
		0.05
	)
	purifier_protection_cooldown = (
		maxf(float(purifier_protection_config.get("cooldown", 30.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	shield_hp = 0.0
	shield_max_hp = 0.0
	_add_purifier_shield_layer()
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(purifier_protection_effect, &"start")
	_play_purifier_audio(purifier_shield_create_audio)
	queue_redraw()


func _trigger_purifier_protection_break_pulse() -> void:
	var radius := maxf(
		float(purifier_protection_config.get("break_radius", 240.0)),
		0.0
	)
	if radius <= 0.0:
		return
	var knockback := maxf(
		float(purifier_protection_config.get("break_knockback", 135.0)),
		0.0
	)
	var slow_multiplier := clampf(
		float(purifier_protection_config.get("break_slow_multiplier", 0.70)),
		0.1,
		1.0
	)
	var slow_until := Time.get_ticks_msec() + int(round(
		maxf(
			float(purifier_protection_config.get("break_slow_duration", 1.5)),
			0.05
		) * 1000.0
	))
	var radius_sq := radius * radius
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if (
			monster == null
			or global_position.distance_squared_to(monster.global_position) > radius_sq
		):
			continue
		var push_direction := global_position.direction_to(monster.global_position)
		if push_direction.length_squared() <= 0.001:
			push_direction = Vector2.RIGHT
		monster.global_position += push_direction.normalized() * knockback
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(
			monster.get_meta("gunner_slow_multiplier", 1.0)
		)
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)


func _end_purifier_protection(broken: bool) -> void:
	if not purifier_protection_active and shield_hp <= 0.0:
		return
	if broken and not purifier_protection_break_triggered:
		purifier_protection_break_triggered = true
		_trigger_purifier_protection_break_pulse()
	purifier_protection_active = false
	purifier_protection_duration_timer = 0.0
	purifier_protection_tick_timer = 0.0
	shield_hp = 0.0
	shield_max_hp = 0.0
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(purifier_protection_effect, &"end")
	_play_purifier_audio(purifier_shield_break_audio)
	queue_redraw()


func _cast_purifier_crown() -> void:
	if (
		hero_archetype != "cleric_purifier"
		or purifier_crown_config.is_empty()
		or purifier_crown_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return
	var max_stacks := maxi(
		int(purifier_crown_config.get("max_stacks", 5)),
		1
	)
	purifier_crown_stacks = mini(purifier_crown_stacks + 1, max_stacks)
	purifier_crown_duration_timer = maxf(
		float(purifier_crown_config.get("duration", 60.0)),
		0.1
	)
	if purifier_crown_heal_timer <= 0.0:
		purifier_crown_heal_timer = maxf(
			float(purifier_crown_config.get("heal_interval", 5.0)),
			0.1
		)
	purifier_crown_cooldown = (
		maxf(float(purifier_crown_config.get("cooldown", 20.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(purifier_crown_effect, &"start")
	_play_purifier_audio(purifier_crown_audio)
	queue_redraw()


func _expire_purifier_crown() -> void:
	if purifier_crown_stacks <= 0:
		return
	purifier_crown_stacks = 0
	purifier_crown_duration_timer = 0.0
	purifier_crown_heal_timer = 0.0
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(purifier_crown_effect, &"end")
	queue_redraw()


func _update_purifier_gauge(delta: float) -> void:
	if (
		hero_archetype != "cleric_purifier"
		or purifier_gauge_config.is_empty()
		or is_dying
		or current_hp <= 0
	):
		return

	purifier_protection_cooldown = maxf(
		purifier_protection_cooldown - delta,
		0.0
	)
	purifier_crown_cooldown = maxf(purifier_crown_cooldown - delta, 0.0)

	if purifier_protection_active:
		purifier_protection_duration_timer = maxf(
			purifier_protection_duration_timer - delta,
			0.0
		)
		purifier_protection_tick_timer -= delta
		if purifier_protection_duration_timer <= 0.0:
			_end_purifier_protection(false)
		else:
			var tick_interval := maxf(
				float(purifier_protection_config.get("shield_tick_interval", 1.0)),
				0.05
			)
			while purifier_protection_tick_timer <= 0.0:
				_add_purifier_shield_layer()
				purifier_protection_tick_timer += tick_interval

	if purifier_crown_stacks > 0:
		purifier_crown_duration_timer = maxf(
			purifier_crown_duration_timer - delta,
			0.0
		)
		purifier_crown_heal_timer -= delta
		if purifier_crown_duration_timer <= 0.0:
			_expire_purifier_crown()
		elif purifier_crown_heal_timer <= 0.0:
			heal_direct(
				maxi(
					int(purifier_crown_config.get("heal_per_stack", 20))
					* purifier_crown_stacks,
					1
				)
			)
			purifier_crown_heal_timer += maxf(
				float(purifier_crown_config.get("heal_interval", 5.0)),
				0.1
			)

	if purifier_crown_cooldown <= 0.0:
		_cast_purifier_crown()
	_try_activate_purifier_protection()


func _add_purifier_gauge(amount: float) -> void:
	if (
		amount <= 0.0
		or hero_archetype != "cleric_purifier"
		or purifier_gauge_config.is_empty()
		or is_dying
	):
		return
	var gauge_max := maxf(
		float(purifier_gauge_config.get("charge_max", 100.0)),
		1.0
	)
	ultimate_charge = minf(ultimate_charge + amount, gauge_max)
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

	var projectile := _acquire_projectile(
		ULTIMATE_PIERCING_PROJECTILE_SCENE,
		"ultimate_piercing_projectile"
	)
	if projectile == null:
		return
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
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius * radius
		):
			continue
		if monster.has_method("take_damage"):
			monster.call("take_damage", damage)

func collect_heal_item(base_amount: int) -> int:
	if base_amount <= 0 or current_hp <= 0 or is_dying:
		return 0

	var missing_hp: int = maxi(max_hp - current_hp, 0)
	var missing_hp_bonus: int = maxi(
		int(round(float(missing_hp) * 0.10)),
		0
	)
	var raw_heal_amount: int = base_amount + missing_hp_bonus
	var heal_amount: int = maxi(
		int(round(
			float(raw_heal_amount)
			* maxf(heal_item_multiplier, 0.0)
		)),
		1
	)
	return heal_direct(heal_amount)

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
		"cleric_purifier":
			_append_skill_cooldown_hud(
				skills,
				purifier_crown_config,
				purifier_crown_cooldown,
				"res://assets/art/heroes/stage9_prist/frames/effect3/effect_19.png",
				maxf(
					float(purifier_crown_config.get("cooldown", 20.0)),
					0.0
				) * _get_purifier_skill_cooldown_multiplier()
			)
		"summoner_gatekeeper":
			_append_skill_cooldown_hud(
				skills,
				summoner_gatekeeper_config,
				summoner_gatekeeper_cooldown,
				"res://assets/art/heroes/stage8_summoner/frames/effect1/birth_04.png",
				maxf(
					float(summoner_gatekeeper_config.get("cooldown", 10.0)),
					0.0
				)
			)
			_append_skill_cooldown_hud(
				skills,
				summoner_scout_config,
				summoner_scout_cooldown,
				"res://assets/art/heroes/stage8_summoner/frames/effect2/summon_04.png",
				maxf(
					float(summoner_scout_config.get("cooldown", 20.0)),
					0.0
				)
			)
			_append_skill_cooldown_hud(
				skills,
				summoner_hound_config,
				summoner_hound_cooldown,
				"res://assets/art/heroes/stage8_summoner/frames/effect3/summon_03.png",
				maxf(
					float(summoner_hound_config.get("cooldown", 30.0)),
					0.0
				)
			)
			_append_skill_cooldown_hud(
				skills,
				summoner_watcher_config,
				summoner_watcher_cooldown,
				"res://assets/art/heroes/stage8_summoner/frames/effect4/idle_01.png",
				maxf(
					float(summoner_watcher_config.get("cooldown", 7.0)),
					0.0
				)
			)
			_append_summoner_open_gate_hud(skills)
		"alchemist_chemical":
			_append_skill_cooldown_hud(
				skills,
				alchemist_mixture_field_config,
				alchemist_mixture_field_cooldown,
				"res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_13.png",
				_get_alchemist_effective_cooldown(
					alchemist_mixture_field_config,
					20.0
				)
			)
			_append_skill_cooldown_hud(
				skills,
				alchemist_mystery_cauldron_config,
				alchemist_mystery_cauldron_cooldown,
				"res://assets/art/heroes/stage7_alchemist/frames/effect6/cauldron_04.png",
				_get_alchemist_mystery_cauldron_cooldown_total()
			)
			_append_skill_cooldown_hud(
				skills,
				alchemist_emergency_config,
				alchemist_emergency_cooldown,
				"res://assets/art/heroes/stage7_alchemist/frames/effect8/effect_04.png",
				_get_alchemist_effective_cooldown(
					alchemist_emergency_config,
					10.0
				)
			)
			_append_alchemist_philosopher_hud(skills)
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
				"res://assets/art/heroes/stage4_gunner/frames/effect/effect_projectile_05.png"
			)
		"berserker_madness":
			_append_berserker_skill_cooldown_hud(
				skills,
				Dictionary(berserker_config.get("skill_1", {})),
				berserker_skill1_cooldown,
				"res://assets/art/heroes/stage6_berserker/frames/effect4/heavy_slash_01.png"
			)
			_append_berserker_skill_cooldown_hud(
				skills,
				Dictionary(berserker_config.get("skill_2", {})),
				berserker_skill2_cooldown,
				"res://assets/art/heroes/stage6_berserker/frames/effect3/ground_slam_07.png"
			)
			_append_berserker_skill_cooldown_hud(
				skills,
				Dictionary(berserker_config.get("skill_3", {})),
				berserker_skill3_cooldown,
				"res://assets/art/heroes/stage6_berserker/frames/effect5/hit_effect_01.png"
			)
			_append_berserker_skill_cooldown_hud(
				skills,
				Dictionary(berserker_config.get("skill_4", {})),
				berserker_skill4_cooldown,
				"res://assets/art/heroes/stage6_berserker/frames/effect8/spin_slash_01.png"
			)

	return skills


func _skill_hud_description(config: Dictionary) -> String:
	var explicit := String(config.get("description", "")).strip_edges()
	if not explicit.is_empty():
		return explicit

	var skill_id := String(config.get("id", ""))
	match skill_id:
		"arcane_piercer":
			return "전방으로 강력한 마력 관통포를 발사해 일직선상의 적을 공격합니다."
		"arcane_barrier":
			return "마력 장벽을 전개해 일정 시간 피해를 흡수합니다."
		"arcane_field":
			return "제자리에서 비전 집중을 채널링해 전투 능력을 보조합니다."
		"blade_storm":
			return "주변 적을 빠르게 연속 베어 다수의 적을 압박합니다."
		"shadow_assassination":
			return "급습 후 연속 암살 공격으로 단일 대상을 집중 타격합니다."
		"shield_charge":
			return "방패를 앞세워 돌진하며 경로의 적을 밀어내고 피해를 줍니다."
		"archmage_combustion":
			return "화염구를 남겨 지속 피해를 준 뒤 연소 돌진으로 마무리합니다."
		"archmage_ice_bolt":
			return "먼 적에게 얼음 투사체를 발사하고 적중 지점 주변에 얼음기둥을 생성합니다."
		"archmage_earth_spikes":
			return "전방 직선 경로에 땅의 가시를 연속 생성해 적을 관통 공격합니다."
		"archmage_holy_power":
			return "주변 위치에 신성 폭발을 연속 발생시키고 피격 적을 둔화합니다."
		"archmage_chain_dagger":
			return "체인대거가 적 사이를 연속 도탄하며 갈수록 강한 피해를 줍니다."
		"archmage_harmony":
			return "모든 원소를 조율해 다른 대마법 기술의 재사용 대기시간을 초기화합니다."
		"archmage_storm":
			return "8방향으로 폭풍 투사체를 발사해 적을 관통하고 속박합니다."
		"blood_sword_first":
			return "혈기를 소모해 점점 커지는 검기 파동을 연속 발사합니다."
		"blood_sword_second":
			return "갈라지는 혈흔 공격을 전개하고 혈흔 접촉으로 체력을 회복합니다."
		"blood_sword_third":
			return "빠르게 돌진하며 혈구를 생성하고 회수한 혈구만큼 체력을 회복합니다."
		"blood_sword_fourth":
			return "주변을 크게 베어 적에게 피해를 주고 바깥으로 밀어냅니다."
		_:
			return "용사가 전투 상황과 사용 조건에 맞춰 자동으로 사용하는 기술입니다."


func _skill_hud_resource_text(config: Dictionary) -> String:
	if config.has("gas_cost"):
		return "화학가스 %.0f" % maxf(float(config.get("gas_cost", 0.0)), 0.0)
	if config.has("hp_cost_ratio"):
		return "현재 HP %.0f%%" % (
			maxf(float(config.get("hp_cost_ratio", 0.0)), 0.0) * 100.0
		)
	return ""


func _append_skill_cooldown_hud(
	skills: Array,
	config: Dictionary,
	remaining: float,
	icon_path: String,
	cooldown_override: float = -1.0
) -> void:
	if config.is_empty():
		return
	var cooldown_total := (
		maxf(cooldown_override, 0.0)
		if cooldown_override >= 0.0
		else maxf(float(config.get("cooldown", 0.0)), 0.0)
	)
	if cooldown_total <= 0.0:
		return
	var current_remaining := maxf(remaining, 0.0)
	skills.append({
		"id": String(config.get("id", "skill")),
		"name": String(config.get("name", "기술")),
		"description": _skill_hud_description(config),
		"resource_text": _skill_hud_resource_text(config),
		"status_text": (
			"재사용 대기 중"
			if current_remaining > 0.01
			else "사용 가능"
		),
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
		"icon_path": icon_path,
	})


func _append_summoner_open_gate_hud(skills: Array) -> void:
	if summoner_open_gate_config.is_empty():
		return
	var required := maxi(_get_summoner_open_gate_required_summons(), 1)
	var cooldown_total := maxf(
		float(summoner_open_gate_config.get("cooldown", 100.0)),
		0.0
	)
	var cooldown_remaining := maxf(summoner_open_gate_cooldown, 0.0)
	var status := "사용 조건 대기"
	if summoner_open_gate_unlocked:
		status = (
			"재사용 대기 중"
			if cooldown_remaining > 0.01
			else "사용 가능"
		)
	skills.append({
		"id": String(summoner_open_gate_config.get("id", "summoner_open_gate")),
		"name": String(summoner_open_gate_config.get("name", "이계의 문 - 개방")),
		"description": _skill_hud_description(summoner_open_gate_config),
		"progress_text": (
			"누적 소환 %d / %d"
			% [mini(summoner_total_summons, required), required]
		),
		"status_text": status,
		"available": summoner_open_gate_unlocked and cooldown_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": (
			cooldown_remaining
			if summoner_open_gate_unlocked
			else cooldown_total
		),
		"icon_path": "res://assets/art/heroes/stage8_summoner/frames/effect5/effect_06.png",
	})


func _append_alchemist_philosopher_hud(skills: Array) -> void:
	if alchemist_philosopher_config.is_empty():
		return
	var required := maxi(
		int(alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var gas_cost := maxf(
		float(alchemist_philosopher_config.get("gas_cost", 100.0)),
		0.0
	)
	var ready := (
		not alchemist_philosopher_used
		and not alchemist_philosopher_channeling
		and not alchemist_transformed
		and alchemist_materials_collected >= required
		and alchemist_gas + 0.001 >= gas_cost
	)
	var status := "사용 조건 대기"
	if alchemist_philosopher_channeling:
		status = "채널링 중"
	elif alchemist_transformed:
		status = "사용 완료 · 현자의 돌 활성화"
	elif alchemist_philosopher_used:
		status = "사용 완료"
	elif ready:
		status = "사용 가능"

	skills.append({
		"id": String(alchemist_philosopher_config.get(
			"id",
			"alchemist_philosopher_stone"
		)),
		"name": String(alchemist_philosopher_config.get(
			"name",
			"현자의 돌"
		)),
		"description": _skill_hud_description(alchemist_philosopher_config),
		"resource_text": "화학가스 %.0f · 전투당 1회" % gas_cost,
		"progress_text": "연금술 재료 %d / %d · 현재 가스 %.0f / %.0f" % [
			mini(alchemist_materials_collected, required),
			required,
			alchemist_gas,
			alchemist_gas_max,
		],
		"status_text": status,
		"available": ready,
		"cooldown_total": 0.0,
		"cooldown_remaining": 0.0,
		"icon_path": "res://assets/art/heroes/stage7_alchemist/frames/effect7/cast_04.png",
	})


func _append_berserker_skill_cooldown_hud(
	skills: Array,
	config: Dictionary,
	remaining: float,
	icon_path: String
) -> void:
	if config.is_empty():
		return
	var cooldown_total: float = _get_berserker_skill_cooldown(
		config,
		0.0
	)
	if cooldown_total <= 0.0:
		return
	var current_remaining := maxf(remaining, 0.0)
	skills.append({
		"id": String(config.get("id", "skill")),
		"name": String(config.get("name", "기술")),
		"description": _skill_hud_description(config),
		"resource_text": _skill_hud_resource_text(config),
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
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
	var current_remaining := maxf(
		float(archmage_skill_cooldowns.get(skill_key, 0.0)),
		0.0
	)
	skills.append({
		"id": String(config.get("id", skill_key)),
		"name": String(config.get("name", skill_key)),
		"description": _skill_hud_description(config),
		"resource_text": _skill_hud_resource_text(config),
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
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
	var current_remaining := maxf(remaining, 0.0)
	skills.append({
		"id": skill_id,
		"name": skill_name,
		"description": (
			"위험한 순간 뒤로 빠르게 이동해 거리를 벌립니다."
			if skill_id == "gunner_backstep"
			else (
				"재장전 중 실린더를 타격해 주변 적을 공격하고 제어합니다."
				if skill_id == "gunner_cylinder"
				else (
					"집중 상태에 들어가 강력한 연속 사격을 가합니다."
					if skill_id == "gunner_deadeye"
					else "권총의 용사가 전투 상황에 맞춰 자동으로 사용하는 전용 기술입니다."
				)
			)
		),
		"resource_text": "",
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
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

func _get_summoner_augment_ai_settings() -> Dictionary:
	if hero_archetype != "summoner_gatekeeper":
		return ai_settings.duplicate(true)
	return HERO_SUMMONER_RUNTIME.build_augment_ai_settings(
		ai_settings,
		summoner_ai_choice_counts,
		_get_active_summon_count(),
		_get_summoner_slot_capacity()
	)


func _level_up() -> void:
	level += 1
	exp_to_next_level = _required_exp_for_level(level)
	level_flash_timer = 0.45
	_play_level_up_feedback()
	_apply_level_growth()
	if hero_archetype == "summoner_gatekeeper" and level % 5 == 0:
		# Stage 8 gains one shared summon slot every five levels. Expand the
		# fixed pools only at the milestone instead of instantiating during combat.
		_ensure_summoner_pool_capacity()

	var candidates: Array = AUGMENT_CATALOG.roll_candidates(
		3,
		_get_augment_roll_build_counts(),
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
	var augment_ai_settings := (
		_get_summoner_augment_ai_settings()
		if hero_archetype == "summoner_gatekeeper"
		else ai_settings
	)
	var chosen: Dictionary = BUILD_AI.choose_candidate(
		candidates,
		ai_context,
		build_counts,
		augment_ai_settings
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
	# Every hero gets a small additive damage floor independent of augment rolls.
	# It is based on the profile's starting attack damage, never current damage,
	# so it cannot snowball exponentially with damage augments.
	var passive_growth_ratio := maxf(
		float(
			level_growth_config.get(
				"base_attack_growth_ratio",
				HERO_BASE_ATTACK_GROWTH_PER_LEVEL
			)
		),
		0.0
	)
	var milestone_interval := maxi(
		int(
			level_growth_config.get(
				"attack_milestone_interval",
				HERO_ATTACK_MILESTONE_INTERVAL
			)
		),
		0
	)
	var milestone_bonus := maxf(
		float(
			level_growth_config.get(
				"attack_milestone_bonus",
				HERO_ATTACK_MILESTONE_BONUS
			)
		),
		0.0
	)

	var passive_damage_gain := (
		base_attack_damage_for_level_growth
		* passive_growth_ratio
	)
	if (
		milestone_interval > 0
		and level % milestone_interval == 0
	):
		passive_damage_gain += (
			base_attack_damage_for_level_growth
			* milestone_bonus
		)

	passive_attack_growth_accumulator += passive_damage_gain
	var whole_passive_gain := floori(
		passive_attack_growth_accumulator + 0.0001
	)
	if whole_passive_gain > 0:
		attack_damage += whole_passive_gain
		passive_attack_growth_accumulator = maxf(
			passive_attack_growth_accumulator
			- float(whole_passive_gain),
			0.0
		)

	# Existing per-profile level growth remains additive on top.
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
		heal_direct(
			maxi(
				int(round(float(max_hp) * heal_ratio)),
				1
			)
		)

func _refresh_ai_observation() -> void:
	var interval := maxf(
		float(ai_settings.get("observation_interval", 4.0)),
		0.25
	)
	# _build_ai_context() already returns a fresh snapshot.
	# Avoid a redundant deep copy of all nested AI memory dictionaries.
	ai_observed_context = _build_ai_context()
	ai_observed_context_time = ai_memory_clock
	ai_observation_timer = interval

func _get_ai_decision_context() -> Dictionary:
	if ai_observed_context.is_empty():
		_refresh_ai_observation()

	# The build AI only reads nested context dictionaries. We only need a
	# shallow copy so observation_age/interval can be added without mutating
	# the stored snapshot.
	var context := ai_observed_context.duplicate()
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
	var nearest_distance_sq: float = INF
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
		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		nearest_distance_sq = minf(nearest_distance_sq, distance_sq)

		if distance_sq <= ai_sense_radius * ai_sense_radius:
			nearby_count += 1

		var type_value = monster.get("monster_type")
		if type_value != null:
			var monster_type: String = String(type_value)
			type_counts[monster_type] = int(type_counts.get(monster_type, 0)) + 1

		var role_value = monster.get("monster_role")
		if role_value != null:
			var monster_role: String = String(role_value)
			role_counts[monster_role] = int(role_counts.get(monster_role, 0)) + 1

	var nearest_distance := (
		sqrt(nearest_distance_sq)
		if total_count > 0
		else 0.0
	)

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
		"berserker_gauge_ratio": (
			ultimate_charge
			/ maxf(
				float(berserker_config.get("gauge_max", 100.0)),
				1.0
			)
			if hero_archetype == "berserker_madness"
			else 0.0
		),
		"berserker_madness_active": (
			1.0
			if (
				hero_archetype == "berserker_madness"
				and berserker_madness_active
			)
			else 0.0
		),
	}

func _get_augment_roll_build_counts() -> Dictionary:
	if (
		hero_archetype != "alchemist_chemical"
		or int(build_counts.get("pursuit", 0)) < 3
	):
		return build_counts

	# Only the alchemist caps Agile Footwork at 3 stacks. The catalog stays
	# unchanged so every other hero keeps the shared augment's normal limit.
	var roll_counts := build_counts.duplicate()
	var pursuit_augment := AUGMENT_CATALOG.get_augment("pursuit")
	roll_counts["pursuit"] = maxi(
		3,
		int(pursuit_augment.get("max_stack", 3))
	)
	return roll_counts


func _get_effective_augment_max_stack(
	augment_id: String,
	catalog_max_stack: int
) -> int:
	return AUGMENT_CATALOG.get_effective_max_stack(
		augment_id,
		hero_archetype,
		catalog_max_stack
	)


func _apply_augment(augment: Dictionary) -> void:
	var augment_id: String = String(augment.get("id", ""))
	var current_stack: int = int(build_counts.get(augment_id, 0))
	var max_stack := _get_effective_augment_max_stack(
		augment_id,
		int(augment.get("max_stack", 0))
	)

	if not augment_id.is_empty() and max_stack > 0 and current_stack >= max_stack:
		return

	for raw_effect in augment.get("effects", []):
		var effect: Dictionary = raw_effect
		_apply_augment_effect(effect)

	if not augment_id.is_empty():
		build_counts[augment_id] = current_stack + 1
		if (
			hero_archetype == "summoner_gatekeeper"
			and augment_id == "summoner_watcher_network"
		):
			_ensure_summoner_pool_capacity()

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

		"alchemist_equivalent_exchange", "alchemist_chemical_support", "alchemist_failure_mother_success", "alchemist_quick_decision", "alchemist_compressed_gas", "alchemist_quick_preparation", "summoner_runtime_augment":
			# Alchemist augments are read from build_counts at the authoritative
			# combat decision points, so no mutable duplicate stat is required.
			pass

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

		"archmage_multicast":
			archmage_multicast_stacks = mini(
				archmage_multicast_stacks + 1,
				3
			)

		"archmage_emergency_escape":
			archmage_blink_stacks = mini(
				archmage_blink_stacks + 1,
				5
			)

		"archmage_fast_cast":
			archmage_cooldown_reduction = minf(
				archmage_cooldown_reduction + 0.05,
				0.25
			)

		"archmage_mana_overflow":
			archmage_mana_overflow_stacks = mini(
				archmage_mana_overflow_stacks + 1,
				5
			)

		"archmage_element_resonance":
			archmage_skill_config["empowered_damage_multiplier"] = minf(
				float(
					archmage_skill_config.get(
						"empowered_damage_multiplier",
						1.50
					)
				) + 0.10,
				1.80
			)
			for skill_key in ["chain_dagger", "storm"]:
				var skill_config: Dictionary = archmage_skill_config.get(
					skill_key,
					{}
				)
				if skill_config.is_empty():
					continue
				skill_config["empowered_damage_multiplier"] = minf(
					float(
						skill_config.get(
							"empowered_damage_multiplier",
							1.50
						)
					) + 0.10,
					1.80
				)

		"archmage_element_cycle":
			archmage_element_cycle_stacks = mini(
				archmage_element_cycle_stacks + 1,
				3
			)

		"archmage_chain_multithrow":
			archmage_chain_multithrow_stacks = mini(
				archmage_chain_multithrow_stacks + 1,
				3
			)

		"archmage_chain_persistence":
			var chain_config: Dictionary = archmage_skill_config.get(
				"chain_dagger",
				{}
			)
			if not chain_config.is_empty():
				chain_config["chain_duration_bonus"] = minf(
					float(
						chain_config.get(
							"chain_duration_bonus",
							0.0
						)
					) + 0.35,
					1.05
				)

		"berserker_unconscious":
			berserker_config["madness_drain_per_second"] = maxf(
				float(
					berserker_config.get(
						"madness_drain_per_second",
						10.0
					)
				) - 0.5,
				0.0
			)

		"berserker_different_dream":
			if not berserker_madness_active:
				_start_berserker_madness()
			var gauge_max: float = maxf(
				float(berserker_config.get("gauge_max", 100.0)),
				1.0
			)
			ultimate_charge = gauge_max
			queue_redraw()

		"berserker_blood_art_eighth":
			berserker_blood_art_eighth_stacks = mini(
				berserker_blood_art_eighth_stacks + 1,
				4
			)

		"berserker_double_edged_sword":
			berserker_missing_hp_bonus_override = 0.015
			berserker_double_edged_heal_multiplier = minf(
				berserker_double_edged_heal_multiplier + 0.03,
				1.15
			)

		"berserker_blood_overflow":
			var skill2_value = berserker_config.get("skill_2", {})
			if typeof(skill2_value) == TYPE_DICTIONARY:
				var skill2_config: Dictionary = skill2_value
				skill2_config["blood_duration"] = minf(
					float(skill2_config.get("blood_duration", 2.0)) + 0.25,
					3.0
				)
				berserker_config["skill_2"] = skill2_config

		"berserker_blood_orb_devour":
			var skill3_value = berserker_config.get("skill_3", {})
			if typeof(skill3_value) == TYPE_DICTIONARY:
				var skill3_config: Dictionary = skill3_value
				skill3_config["heal_per_orb"] = mini(
					int(skill3_config.get("heal_per_orb", 70)) + 10,
					120
				)
				berserker_config["skill_3"] = skill3_config

		"berserker_killing_urge":
			berserker_killing_urge_bonus = minf(
				berserker_killing_urge_bonus + 0.20,
				1.0
			)

		"berserker_blood_art_mastery":
			berserker_blood_art_cooldown_reduction = minf(
				berserker_blood_art_cooldown_reduction + 0.03,
				0.15
			)

		"berserker_frenzied_leap":
			berserker_config["madness_target_radius"] = minf(
				float(
					berserker_config.get(
						"madness_target_radius",
						375.0
					)
				) + 20.0,
				475.0
			)

		"berserker_undying_madman":
			berserker_config["revive_hp_ratio"] = minf(
				float(
					berserker_config.get(
						"revive_hp_ratio",
						0.50
					)
				) + 0.05,
				0.70
			)

		"heal":
			heal_direct(int(effect.get("value", 0)))

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

func _physics_process_berserker(delta: float) -> void:
	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()

	ai_observation_timer = maxf(ai_observation_timer - delta, 0.0)
	if ai_observation_timer <= 0.0:
		_refresh_ai_observation()

	attack_timer = maxf(attack_timer - delta, 0.0)
	berserker_skill1_cooldown = maxf(
		berserker_skill1_cooldown - delta,
		0.0
	)
	berserker_skill2_cooldown = maxf(
		berserker_skill2_cooldown - delta,
		0.0
	)
	berserker_skill3_cooldown = maxf(
		berserker_skill3_cooldown - delta,
		0.0
	)
	berserker_skill4_cooldown = maxf(
		berserker_skill4_cooldown - delta,
		0.0
	)
	berserker_skill_global_cooldown = maxf(
		berserker_skill_global_cooldown - delta,
		0.0
	)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	ultimate_flash_timer = maxf(ultimate_flash_timer - delta, 0.0)
	_update_invulnerability(delta)
	_update_berserker_madness(delta)
	_update_berserker_hp_visual()

	if level_flash_timer > 0.0:
		level_flash_timer = maxf(level_flash_timer - delta, 0.0)
		queue_redraw()

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
			queue_redraw()

	if berserker_reviving:
		velocity = Vector2.ZERO
		return

	if berserker_skill3_active:
		velocity = Vector2.ZERO
		return

	if _update_berserker_skill1(delta):
		velocity = Vector2.ZERO
		_update_berserker_pose_visual(delta)
		return

	_update_heal_item_goal(delta)
	_update_chest_goal(delta)
	_update_magnet_item_goal(delta)

	if (
		not is_instance_valid(target)
		or target.is_queued_for_deletion()
		or retarget_timer <= 0.0
	):
		target = _find_nearest_monster()
		retarget_timer = 0.12

	if not is_instance_valid(target):
		_fighter_move_without_monsters(1.0)
		_update_berserker_pose_visual(delta)
		return

	var distance: float = global_position.distance_to(target.global_position)
	var move_direction: Vector2 = _choose_melee_spacing_direction(
		target,
		distance,
		0.88
	)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	move_direction = _apply_magnet_item_steering(move_direction, delta)

	if move_direction.length_squared() > 0.01:
		velocity = move_direction * move_speed * move_multiplier
		move_and_slide()
		_clamp_to_battlefield()
	else:
		velocity = Vector2.ZERO

	var attack_trigger_range: float = attack_range
	if berserker_madness_active:
		attack_trigger_range = maxf(
			float(berserker_config.get("madness_target_radius", 375.0)),
			attack_range
		)
	var used_contextual_skill: bool = _try_use_berserker_contextual_skill(
		target,
		distance
	)
	if (
		not used_contextual_skill
		and distance <= attack_trigger_range
		and attack_timer <= 0.0
	):
		_berserker_basic_attack(target)

	_update_berserker_pose_visual(delta)


func _try_use_berserker_contextual_skill(
	current_target: Node2D,
	distance: float
) -> bool:
	if (
		berserker_skill_global_cooldown > 0.0
		or not is_instance_valid(current_target)
	):
		return false

	var hp_ratio: float = clampf(
		float(current_hp) / float(maxi(max_hp, 1)),
		0.0,
		1.0
	)
	var close_count: int = _count_monsters_near(
		global_position,
		245.0,
		6
	)
	var recovery_count: int = _count_monsters_near(
		global_position,
		330.0,
		6
	)
	var skill1_value = berserker_config.get("skill_1", {})
	var skill1_range: float = attack_range
	if typeof(skill1_value) == TYPE_DICTIONARY:
		var skill1_config: Dictionary = skill1_value
		skill1_range = maxf(
			float(skill1_config.get("base_range", 300.0)),
			attack_range
		)

	# 3식은 저체력 회복/재배치용. 적이 충분할 때만 사용한다.
	if (
		berserker_skill3_cooldown <= 0.0
		and distance <= 500.0
		and recovery_count >= 2
		and (
			hp_ratio <= 0.62
			or recovery_count >= 5
		)
	):
		_start_berserker_skill3(current_target)
		return true

	# 4식은 실제 포위 압력이 있을 때 밀어내기 용도로 보존한다.
	var spin_required: int = 2 if berserker_madness_active else 3
	if (
		berserker_skill4_cooldown <= 0.0
		and close_count >= spin_required
		and hp_ratio >= 0.22
	):
		_start_berserker_skill4()
		return true

	# 2식은 적 밀집 또는 체력 회복 가치가 있을 때 우선한다.
	if (
		berserker_skill2_cooldown <= 0.0
		and distance <= 320.0
		and hp_ratio >= 0.26
		and (
			recovery_count >= 4
			or (
				hp_ratio <= 0.58
				and recovery_count >= 2
			)
		)
	):
		_start_berserker_skill2(current_target)
		return true

	# 1식은 중거리에서 평타가 닿지 않을 때 주력 견제기로 사용한다.
	if (
		berserker_skill1_cooldown <= 0.0
		and distance <= skill1_range
		and distance > maxf(attack_range * 0.90, 130.0)
		and hp_ratio >= 0.30
	):
		_start_berserker_skill1(current_target)
		return true

	return false


func _get_berserker_skill_cooldown(
	skill_config: Dictionary,
	fallback: float
) -> float:
	var base_cooldown: float = maxf(
		float(skill_config.get("cooldown", fallback)),
		0.0
	)
	return base_cooldown * (
		1.0 - clampf(
			berserker_blood_art_cooldown_reduction,
			0.0,
			0.15
		)
	)


func _pay_berserker_skill_hp_cost(hp_cost_ratio: float) -> void:
	var ratio: float = clampf(hp_cost_ratio, 0.0, 0.95)
	var cost_base: float = float(current_hp)
	if berserker_blood_art_eighth_stacks > 0:
		cost_base = float(max_hp)
	var hp_cost: int = maxi(
		int(round(cost_base * ratio)),
		1
	)
	current_hp = maxi(current_hp - hp_cost, 1)
	health_changed.emit(current_hp, max_hp)


func _berserker_blood_art_eighth_heal_on_hit() -> void:
	if berserker_blood_art_eighth_stacks <= 0:
		return
	var missing_hp: int = maxi(max_hp - current_hp, 0)
	if missing_hp <= 0:
		return
	var heal_ratio: float = (
		0.005
		+ 0.003
		* float(berserker_blood_art_eighth_stacks - 1)
	)
	var heal_amount: int = maxi(
		int(round(float(missing_hp) * heal_ratio)),
		1
	)
	heal_direct(heal_amount)


func notify_berserker_blood_art_hit() -> void:
	_berserker_blood_art_eighth_heal_on_hit()


func _start_berserker_skill1(current_target: Node2D) -> void:
	if berserker_skill1_active or not is_instance_valid(current_target):
		return

	var skill_config_value = berserker_config.get("skill_1", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.05)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	berserker_skill1_direction = global_position.direction_to(
		current_target.global_position
	)
	if berserker_skill1_direction.length_squared() <= 0.0:
		berserker_skill1_direction = (
			Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
		)
	berserker_skill1_direction = berserker_skill1_direction.normalized()

	berserker_skill1_active = true
	berserker_skill1_wave_index = 0
	berserker_skill1_wave_timer = 0.0
	berserker_skill1_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		15.0
	)
	berserker_skill_global_cooldown = maxf(
		berserker_skill_global_cooldown,
		2.40
	)
	attack_timer = maxf(attack_timer, 2.35)
	attack_pose_timer = 0.0
	_face_attack_direction(berserker_skill1_direction.x)
	queue_redraw()


func _update_berserker_skill1(delta: float) -> bool:
	if not berserker_skill1_active:
		return false

	var skill_config_value = berserker_config.get("skill_1", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		berserker_skill1_active = false
		return false
	var skill_config: Dictionary = skill_config_value

	berserker_skill1_wave_timer = maxf(
		berserker_skill1_wave_timer - delta,
		0.0
	)
	if berserker_skill1_wave_timer > 0.0:
		return true

	var wave_count: int = maxi(
		int(skill_config.get("wave_count", 3)),
		1
	)
	if berserker_skill1_wave_index >= wave_count:
		berserker_skill1_active = false
		return false

	_berserker_emit_skill1_wave(
		berserker_skill1_wave_index,
		skill_config
	)
	berserker_skill1_wave_index += 1
	if berserker_skill1_wave_index >= wave_count:
		berserker_skill1_active = false
		return false

	berserker_skill1_wave_timer = maxf(
		float(skill_config.get("wave_interval", 0.75)),
		0.05
	)
	return true


func _berserker_emit_skill1_wave(
	wave_index: int,
	skill_config: Dictionary
) -> void:
	var direction: Vector2 = berserker_skill1_direction
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	_face_attack_direction(direction.x)
	_restart_stage1_animation("attack")
	attack_pose_timer = 0.46

	var growth: float = maxf(
		float(skill_config.get("size_growth_per_wave", 0.25)),
		0.0
	)
	var scale_multiplier: float = 1.0 + growth * float(wave_index)
	var projectile_range: float = (
		maxf(float(skill_config.get("base_range", 560.0)), 1.0)
		* scale_multiplier
	)
	var half_width: float = (
		maxf(float(skill_config.get("base_half_width", 64.0)), 1.0)
		* scale_multiplier
	)
	var projectile_speed_value: float = maxf(
		float(skill_config.get("projectile_speed", 760.0)),
		1.0
	)

	var repeat_values = skill_config.get(
		"repeat_hit_multipliers",
		[1.0, 0.80, 0.60]
	)
	var repeat_multiplier: float = 1.0
	if typeof(repeat_values) == TYPE_ARRAY:
		var repeat_array: Array = repeat_values
		if wave_index >= 0 and wave_index < repeat_array.size():
			repeat_multiplier = float(repeat_array[wave_index])

	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 1.10))
			* repeat_multiplier
		)),
		1
	)

	var back_direction: Vector2 = -direction
	var blood_recoil_fx: AnimatedSprite2D = _spawn_archmage_fx(
		"%s/effect2" % STAGE6_FRAME_DIR,
		"blood_effect",
		1,
		10,
		30.0,
		false,
		global_position + back_direction * 38.0,
		Vector2(
			0.84 * scale_multiplier,
			0.84 * scale_multiplier
		)
	)
	if is_instance_valid(blood_recoil_fx):
		blood_recoil_fx.flip_h = back_direction.x < 0.0
		blood_recoil_fx.rotation = (
			back_direction.angle()
			if back_direction.x >= 0.0
			else back_direction.angle() - PI
		)
		blood_recoil_fx.modulate = Color(1.0, 0.72, 0.72, 0.95)
		blood_recoil_fx.z_index = 7
		var recoil_fade := blood_recoil_fx.create_tween()
		recoil_fade.tween_property(
			blood_recoil_fx,
			"modulate:a",
			0.0,
			0.24
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var projectile_config: Dictionary = {
		"hit_radius": half_width,
		"visual_scale": 0.936 * scale_multiplier,
	}
	var projectile := _acquire_projectile(
		ARCHMAGE_SKILL_PROJECTILE_SCENE,
		"berserker_wave_projectile"
	)
	if projectile == null:
		return

	projectile.global_position = global_position + direction * 54.0
	projectile.call(
		"setup",
		"berserker_wave",
		direction,
		damage,
		projectile_speed_value,
		projectile_range,
		projectile_config,
		self,
		false,
		null
	)


func _start_berserker_skill2(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var skill_config_value = berserker_config.get("skill_2", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.07)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	berserker_skill2_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		19.0
	)
	berserker_skill_global_cooldown = maxf(
		berserker_skill_global_cooldown,
		1.35
	)
	attack_timer = maxf(attack_timer, 0.72)
	attack_pose_timer = 0.58
	_face_attack_direction(
		global_position.direction_to(current_target.global_position).x
	)
	_restart_stage1_animation("attack")

	var slam_fx: AnimatedSprite2D = _spawn_archmage_fx(
		"%s/effect3" % STAGE6_FRAME_DIR,
		"ground_slam",
		1,
		11,
		20.0,
		false,
		global_position,
		Vector2(0.92, 0.92)
	)
	if is_instance_valid(slam_fx):
		slam_fx.z_index = 6

	var wave_count: int = maxi(
		int(skill_config.get("wave_count", 4)),
		1
	)
	var base_offset: float = randf_range(-0.22, 0.22)
	for wave_index in range(wave_count):
		var angle: float = (
			TAU * float(wave_index) / float(wave_count)
			+ base_offset
			+ randf_range(-0.16, 0.16)
		)
		var wave_direction: Vector2 = Vector2.RIGHT.rotated(angle)
		_run_berserker_skill2_wave(
			global_position,
			wave_direction,
			skill_config
		)

	queue_redraw()


func _run_berserker_skill2_wave(
	start_position: Vector2,
	start_direction: Vector2,
	skill_config: Dictionary
) -> void:
	var world_points: Array[Vector2] = []
	world_points.append(start_position)
	var blood_visuals: Array[AnimatedSprite2D] = []

	var hit_ids: Dictionary = {}
	var current_position: Vector2 = start_position
	var current_direction: Vector2 = start_direction.normalized()
	var cell_length: float = maxf(
		float(skill_config.get("cell_length", 72.0)),
		8.0
	)
	var cell_count: int = maxi(
		int(skill_config.get("cell_count", 6)),
		1
	)
	var branch_angle: float = deg_to_rad(
		maxf(float(skill_config.get("branch_angle_degrees", 68.0)), 0.0)
	)
	var branch_min_angle: float = deg_to_rad(
		clampf(
			float(skill_config.get("branch_min_angle_degrees", 28.0)),
			0.0,
			rad_to_deg(branch_angle)
		)
	)
	var turn_sign: float = -1.0 if randf() < 0.5 else 1.0
	var wave_speed: float = maxf(
		float(skill_config.get("wave_speed", 620.0)),
		1.0
	)
	var half_width: float = maxf(
		float(skill_config.get("path_half_width", 30.0)),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 0.85))
		)),
		1
	)

	for cell_index in range(cell_count):
		if not is_inside_tree():
			return

		var turn_amount: float = randf_range(
			branch_min_angle,
			branch_angle
		)
		if randf() < 0.22:
			turn_sign *= -1.0
		var turn: float = turn_amount * turn_sign
		current_direction = current_direction.rotated(turn).normalized()
		turn_sign *= -1.0
		var next_position: Vector2 = (
			current_position + current_direction * cell_length
		)
		next_position = Vector2(
			clampf(
				next_position.x,
				FIELD_MARGIN,
				battlefield_size.x - FIELD_MARGIN
			),
			clampf(
				next_position.y,
				FIELD_MARGIN,
				battlefield_size.y - FIELD_MARGIN
			)
		)

		_damage_berserker_skill2_segment(
			current_position,
			next_position,
			half_width,
			damage,
			hit_ids
		)

		var segment: Vector2 = next_position - current_position
		var blood_position: Vector2 = current_position.lerp(
			next_position,
			0.5
		)
		var blood_scale_x: float = maxf(
			segment.length() / 128.0,
			0.42
		)
		var blood_scale_y: float = maxf(
			half_width / 46.0,
			0.46
		)
		var blood_fx: AnimatedSprite2D = _spawn_archmage_fx(
			"%s/effect3" % STAGE6_FRAME_DIR,
			"ground_slam",
			7,
			1,
			1.0,
			true,
			blood_position,
			Vector2(blood_scale_x, blood_scale_y)
		)
		if is_instance_valid(blood_fx):
			blood_fx.rotation = segment.angle()
			blood_fx.z_index = 4
			blood_fx.modulate = Color.WHITE
			blood_visuals.append(blood_fx)

		world_points.append(next_position)
		current_position = next_position

		var step_time: float = cell_length / wave_speed
		await get_tree().create_timer(
			maxf(step_time, 0.03)
		).timeout

	var blood_duration: float = maxf(
		float(skill_config.get("blood_duration", 2.0)),
		0.0
	)
	var tick_interval: float = maxf(
		float(skill_config.get("heal_tick_interval", 0.15)),
		0.05
	)
	var heal_per_touch: int = maxi(
		int(skill_config.get("heal_per_touch_tick", 10)),
		1
	)
	var elapsed: float = 0.0
	while elapsed < blood_duration and is_inside_tree():
		_heal_berserker_from_blood_path(
			world_points,
			half_width,
			heal_per_touch
		)
		await get_tree().create_timer(tick_interval).timeout
		elapsed += tick_interval

	for blood_fx in blood_visuals:
		if not is_instance_valid(blood_fx):
			continue
		var fade_position: Vector2 = blood_fx.global_position
		var fade_rotation: float = blood_fx.rotation
		var fade_scale: Vector2 = blood_fx.scale
		_recycle_archmage_fx(blood_fx)

		var fade_fx: AnimatedSprite2D = _spawn_archmage_fx(
			"%s/effect3" % STAGE6_FRAME_DIR,
			"ground_slam",
			8,
			4,
			12.0,
			false,
			fade_position,
			fade_scale
		)
		if is_instance_valid(fade_fx):
			fade_fx.rotation = fade_rotation
			fade_fx.z_index = 4


func _damage_berserker_skill2_segment(
	from_position: Vector2,
	to_position: Vector2,
	half_width: float,
	damage: int,
	hit_ids: Dictionary
) -> void:
	var segment: Vector2 = to_position - from_position
	var length_sq: float = maxf(segment.length_squared(), 0.001)
	var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
	var search_radius: float = segment.length() * 0.5 + half_width + 20.0

	for node in _get_monster_nodes_near(midpoint, search_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue

		var iid: int = monster.get_instance_id()
		if hit_ids.has(iid):
			continue

		var t: float = clampf(
			(monster.global_position - from_position).dot(segment)
			/ length_sq,
			0.0,
			1.0
		)
		var closest: Vector2 = from_position + segment * t
		if (
			monster.global_position.distance_squared_to(closest)
			> half_width * half_width
		):
			continue

		hit_ids[iid] = true
		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		monster.call("take_damage", damage)
		_berserker_blood_art_eighth_heal_on_hit()

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()


func _heal_berserker_from_blood_path(
	world_points: Array[Vector2],
	half_width: float,
	heal_per_touch: int
) -> void:
	if current_hp <= 0 or is_dying or world_points.size() < 2:
		return

	var healed_ids: Dictionary = {}
	for segment_index in range(world_points.size() - 1):
		var from_position: Vector2 = world_points[segment_index]
		var to_position: Vector2 = world_points[segment_index + 1]
		var segment: Vector2 = to_position - from_position
		var length_sq: float = maxf(segment.length_squared(), 0.001)
		var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
		var search_radius: float = (
			segment.length() * 0.5 + half_width + 20.0
		)

		for node in _get_monster_nodes_near(midpoint, search_radius):
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			var monster := node as Node2D
			if monster == null:
				continue
			var iid: int = monster.get_instance_id()
			if healed_ids.has(iid):
				continue

			var t: float = clampf(
				(monster.global_position - from_position).dot(segment)
				/ length_sq,
				0.0,
				1.0
			)
			var closest: Vector2 = from_position + segment * t
			if (
				monster.global_position.distance_squared_to(closest)
				> half_width * half_width
			):
				continue

			healed_ids[iid] = true
			heal_direct(heal_per_touch)


func _start_berserker_skill3(current_target: Node2D) -> void:
	if berserker_skill3_active or not is_instance_valid(current_target):
		return

	var skill_config_value = berserker_config.get("skill_3", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.05)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	var dash_direction: Vector2 = global_position.direction_to(
		current_target.global_position
	)
	if dash_direction.length_squared() <= 0.0:
		dash_direction = (
			Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
		)
	dash_direction = dash_direction.normalized()
	_face_attack_direction(dash_direction.x)

	berserker_skill3_active = true
	berserker_skill3_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		30.0
	)
	berserker_skill_global_cooldown = maxf(
		berserker_skill_global_cooldown,
		1.75
	)
	attack_timer = maxf(attack_timer, 1.55)
	attack_pose_timer = 1.55
	_execute_berserker_skill3(
		dash_direction,
		skill_config
	)
	queue_redraw()


func _execute_berserker_skill3(
	dash_direction: Vector2,
	skill_config: Dictionary
) -> void:
	var start_position: Vector2 = global_position
	var dash_distance: float = maxf(
		float(skill_config.get("dash_distance", 500.0)),
		1.0
	)
	var destination: Vector2 = (
		start_position + dash_direction * dash_distance
	)
	destination = Vector2(
		clampf(
			destination.x,
			FIELD_MARGIN,
			battlefield_size.x - FIELD_MARGIN
		),
		clampf(
			destination.y,
			FIELD_MARGIN,
			battlefield_size.y - FIELD_MARGIN
		)
	)

	var saved_collision_layer: int = collision_layer
	var saved_collision_mask: int = collision_mask
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_restart_stage1_animation("dash_start")

	_spawn_berserker_blood_dash_trail(
		start_position,
		destination
	)

	var dash_duration: float = maxf(
		float(skill_config.get("dash_duration", 0.20)),
		0.05
	)
	var dash_tween := create_tween()
	dash_tween.tween_property(
		self,
		"global_position",
		destination,
		dash_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await dash_tween.finished

	if not is_inside_tree() or is_dying:
		return

	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	global_position = destination
	velocity = Vector2.ZERO
	_restart_stage1_animation("dash_finish")

	var orb_radius: float = maxf(
		float(skill_config.get("blood_orb_radius", 330.0)),
		1.0
	)
	var orb_radius_sq: float = orb_radius * orb_radius
	var orb_count: int = 0
	for node in _get_monster_nodes_near(global_position, orb_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			> orb_radius_sq
		):
			continue
		_spawn_berserker_blood_orb(
			monster.global_position,
			skill_config
		)
		_berserker_blood_art_eighth_heal_on_hit()
		orb_count += 1

	var pickup_duration: float = maxf(
		float(skill_config.get("orb_pickup_duration", 0.42)),
		0.08
	)
	if orb_count > 0:
		await get_tree().create_timer(
			pickup_duration + 0.10
		).timeout
	else:
		await get_tree().create_timer(0.16).timeout

	if not is_inside_tree():
		return
	berserker_skill3_active = false
	attack_pose_timer = 0.0
	_play_stage1_animation("idle", 1.0)


func _spawn_berserker_blood_orb(
	start_position: Vector2,
	skill_config: Dictionary
) -> void:
	var orb_scale: float = maxf(
		float(skill_config.get("orb_visual_scale", 1.18)),
		0.1
	)
	var orb_fx: AnimatedSprite2D = _spawn_archmage_fx(
		"%s/effect5" % STAGE6_FRAME_DIR,
		"hit_effect",
		1,
		9,
		18.0,
		true,
		start_position,
		Vector2(orb_scale * 0.82, orb_scale * 0.82)
	)
	if not is_instance_valid(orb_fx):
		return

	orb_fx.z_index = 12
	orb_fx.modulate = Color(1.0, 0.45, 0.45, 1.0)

	var pickup_duration: float = maxf(
		float(skill_config.get("orb_pickup_duration", 0.55)),
		0.08
	)
	var destination: Vector2 = global_position + Vector2(0.0, -12.0)

	var orb_tween := orb_fx.create_tween()
	orb_tween.set_parallel(false)

	orb_tween.tween_property(
		orb_fx,
		"scale",
		Vector2(orb_scale * 1.12, orb_scale * 1.12),
		0.08
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	orb_tween.tween_property(
		orb_fx,
		"global_position",
		destination,
		pickup_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	orb_tween.parallel().tween_property(
		orb_fx,
		"scale",
		Vector2(0.18, 0.18),
		pickup_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	orb_tween.parallel().tween_property(
		orb_fx,
		"modulate:a",
		0.78,
		pickup_duration * 0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	orb_tween.finished.connect(
		Callable(self, "_finish_berserker_blood_orb").bind(
			orb_fx,
			maxi(int(skill_config.get("heal_per_orb", 70)), 1)
		),
		Object.CONNECT_ONE_SHOT
	)


func _finish_berserker_blood_orb(
	orb_fx: AnimatedSprite2D,
	heal_amount: int
) -> void:
	if is_instance_valid(orb_fx):
		_recycle_archmage_fx(orb_fx)
	if current_hp > 0 and not is_dying:
		heal_direct(heal_amount)


func _start_berserker_skill4() -> void:
	var skill_config_value = berserker_config.get("skill_4", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.04)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	berserker_skill4_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		8.0
	)
	berserker_skill_global_cooldown = maxf(
		berserker_skill_global_cooldown,
		1.15
	)
	attack_timer = maxf(attack_timer, 0.72)
	attack_pose_timer = 0.72
	_restart_stage1_animation("attack")

	var radius: float = maxf(
		float(skill_config.get("radius", 245.0)),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 0.65))
		)),
		1
	)
	var knockback_distance: float = maxf(
		float(skill_config.get("knockback_distance", 150.0)),
		0.0
	)
	var effect_scale: float = maxf(
		float(skill_config.get("effect_scale", 1.05)),
		0.1
	)

	var spin_fx: AnimatedSprite2D = _spawn_archmage_fx(
		"%s/effect8" % STAGE6_FRAME_DIR,
		"spin_slash",
		1,
		10,
		22.0,
		false,
		global_position,
		Vector2(effect_scale, effect_scale)
	)
	if is_instance_valid(spin_fx):
		spin_fx.z_index = 8

	var radius_sq: float = radius * radius
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		monster.call("take_damage", damage)
		_berserker_blood_art_eighth_heal_on_hit()

		if (
			is_instance_valid(monster)
			and knockback_distance > 0.0
		):
			var knockback_direction: Vector2 = global_position.direction_to(
				monster.global_position
			)
			if knockback_direction.length_squared() <= 0.0:
				knockback_direction = Vector2.RIGHT
			var knockback_target: Vector2 = (
				monster.global_position
				+ knockback_direction.normalized() * knockback_distance
			)
			monster.global_position = Vector2(
				clampf(
					knockback_target.x,
					FIELD_MARGIN,
					battlefield_size.x - FIELD_MARGIN
				),
				clampf(
					knockback_target.y,
					FIELD_MARGIN,
					battlefield_size.y - FIELD_MARGIN
				)
			)

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()

	queue_redraw()


func notify_berserker_skill_kill() -> void:
	if berserker_madness_active:
		if (
			berserker_killing_urge_bonus > 0.0
			and int(
				build_counts.get(
					"berserker_different_dream",
					0
				)
			) <= 0
		):
			var gauge_max: float = maxf(
				float(berserker_config.get("gauge_max", 100.0)),
				1.0
			)
			ultimate_charge = minf(
				ultimate_charge + berserker_killing_urge_bonus,
				gauge_max
			)
			queue_redraw()
		return

	_add_berserker_gauge(
		maxf(
			float(berserker_config.get("gauge_per_kill", 1.0)),
			0.0
		)
	)


func _update_berserker_pose_visual(delta: float) -> void:
	if (
		hero_archetype != "berserker_madness"
		or not hero_sprite.visible
		or is_dying
		or berserker_reviving
	):
		return
	if hit_pose_timer > 0.0 or attack_pose_timer > 0.0:
		return

	_update_facing_from_horizontal(velocity.x, delta)
	if velocity.length() > 4.0:
		_play_stage1_animation("move", 1.0)
	else:
		_play_stage1_animation("idle", 1.0)


func _get_berserker_effective_attack_damage() -> int:
	if max_hp <= 0:
		return maxi(attack_damage, 1)

	var missing_ratio: float = clampf(
		float(max_hp - current_hp) / float(max_hp),
		0.0,
		1.0
	)
	var missing_percent: float = missing_ratio * 100.0
	var bonus_per_percent: float = maxf(
		float(
			berserker_config.get(
				"missing_hp_attack_bonus_per_percent",
				0.02
			)
		),
		0.0
	)
	if berserker_missing_hp_bonus_override >= 0.0:
		bonus_per_percent = berserker_missing_hp_bonus_override
	var passive_bonus: float = (
		base_attack_damage_for_level_growth
		* missing_percent
		* bonus_per_percent
	)
	return maxi(
		int(round(float(attack_damage) + passive_bonus)),
		1
	)


func _berserker_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var direction: Vector2 = global_position.direction_to(
		current_target.global_position
	)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	if berserker_madness_active:
		var blink_target: Node2D = _find_berserker_madness_target()
		if is_instance_valid(blink_target):
			_berserker_madness_blink_to(blink_target)
			direction = global_position.direction_to(
				blink_target.global_position
			)
			if direction.length_squared() <= 0.0:
				direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
			direction = direction.normalized()

	var attack_interval: float = _get_common_attack_interval(
		attack_cooldown
	)
	if berserker_madness_active:
		var madness_speed_multiplier: float = maxf(
			float(
				berserker_config.get(
					"madness_attack_speed_multiplier",
					1.50
				)
			),
			0.1
		)
		var different_dream_stacks: int = int(
			build_counts.get(
				"berserker_different_dream",
				0
			)
		)
		if different_dream_stacks > 0:
			madness_speed_multiplier = (
				1.0 + 0.40 * float(different_dream_stacks)
			)
		attack_interval /= madness_speed_multiplier
	attack_timer = maxf(attack_interval, 0.06)
	attack_pose_timer = 0.52
	_face_attack_direction(direction.x)
	_restart_stage1_animation("attack")

	if berserker_madness_active:
		var slash_fx: AnimatedSprite2D = _spawn_archmage_fx(
			"%s/effect1" % STAGE6_FRAME_DIR,
			"basic_slash",
			1,
			13,
			24.0,
			false,
			global_position + direction * 82.0,
			Vector2(1.08, 1.08)
		)
		if is_instance_valid(slash_fx):
			slash_fx.flip_h = direction.x < 0.0
			slash_fx.rotation = direction.angle() if direction.x >= 0.0 else direction.angle() - PI
			slash_fx.z_index = 8

	var reach: float = maxf(
		float(berserker_config.get("basic_reach", 190.0)),
		1.0
	)
	var half_width: float = maxf(
		float(berserker_config.get("basic_half_width", 118.0)),
		1.0
	)
	var damage: int = _get_berserker_effective_attack_damage()
	var side: Vector2 = Vector2(-direction.y, direction.x)

	for node in _get_monster_nodes_near(
		global_position,
		reach + half_width
	):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue

		var offset: Vector2 = monster.global_position - global_position
		var forward: float = offset.dot(direction)
		var lateral: float = absf(offset.dot(side))
		if forward < -32.0 or forward > reach or lateral > half_width:
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		monster.call("take_damage", damage)

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()

	_damage_treasure_chests(
		global_position + direction * (reach * 0.55),
		maxf(half_width, 80.0),
		damage
	)


func _add_berserker_gauge(amount: float) -> void:
	if (
		amount <= 0.0
		or hero_archetype != "berserker_madness"
		or berserker_madness_active
		or int(
			build_counts.get(
				"berserker_different_dream",
				0
			)
		) > 0
	):
		return
	var gauge_max: float = maxf(
		float(berserker_config.get("gauge_max", 100.0)),
		1.0
	)
	ultimate_charge = minf(ultimate_charge + amount, gauge_max)
	if ultimate_charge + 0.001 >= gauge_max:
		_start_berserker_madness()
	queue_redraw()


func _start_berserker_madness() -> void:
	if berserker_madness_active or berserker_reviving or is_dying:
		return
	berserker_madness_active = true
	var gauge_max: float = maxf(
		float(berserker_config.get("gauge_max", 100.0)),
		1.0
	)
	ultimate_charge = gauge_max
	if channel_effect.sprite_frames != null:
		channel_effect.visible = true
		channel_effect.play(&"madness")
	queue_redraw()


func _end_berserker_madness() -> void:
	berserker_madness_active = false
	ultimate_charge = 0.0
	if (
		channel_effect.sprite_frames != null
		and channel_effect.animation == &"madness"
	):
		channel_effect.visible = false
	queue_redraw()


func _update_berserker_madness(delta: float) -> void:
	if hero_archetype != "berserker_madness":
		return
	if not berserker_madness_active:
		return

	if int(
		build_counts.get(
			"berserker_different_dream",
			0
		)
	) > 0:
		ultimate_charge = maxf(
			float(berserker_config.get("gauge_max", 100.0)),
			1.0
		)
		queue_redraw()
		return

	var drain_per_second: float = maxf(
		float(
			berserker_config.get(
				"madness_drain_per_second",
				10.0
			)
		),
		0.0
	)
	ultimate_charge = maxf(
		ultimate_charge - drain_per_second * delta,
		0.0
	)
	if ultimate_charge <= 0.001:
		_end_berserker_madness()
	else:
		queue_redraw()


func _find_berserker_madness_target() -> Node2D:
	var radius: float = maxf(
		float(berserker_config.get("madness_target_radius", 375.0)),
		1.0
	)
	var radius_sq: float = radius * radius
	var farthest: Node2D = null
	var farthest_distance_sq: float = -1.0
	for node in _get_monster_nodes_near(global_position, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq: float = global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > radius_sq or distance_sq <= farthest_distance_sq:
			continue
		farthest = monster
		farthest_distance_sq = distance_sq
	return farthest


func _berserker_madness_blink_to(blink_target: Node2D) -> void:
	if not is_instance_valid(blink_target):
		return

	var start_position: Vector2 = global_position
	var direction: Vector2 = start_position.direction_to(
		blink_target.global_position
	)
	if direction.length_squared() <= 0.0:
		return

	var stop_distance: float = 48.0
	var destination: Vector2 = (
		blink_target.global_position
		- direction.normalized() * stop_distance
	)
	destination = Vector2(
		clampf(
			destination.x,
			FIELD_MARGIN,
			battlefield_size.x - FIELD_MARGIN
		),
		clampf(
			destination.y,
			FIELD_MARGIN,
			battlefield_size.y - FIELD_MARGIN
		)
	)

	_spawn_berserker_blood_dash_trail(
		start_position,
		destination
	)
	global_position = destination
	velocity = Vector2.ZERO


func _spawn_berserker_blood_dash_trail(
	start_position: Vector2,
	end_position: Vector2
) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return

	var parent_2d := parent as Node2D
	var trail := Line2D.new()
	parent.add_child(trail)
	trail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trail.z_index = 6
	trail.width = 30.0
	trail.default_color = Color(0.82, 0.05, 0.03, 0.82)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.joint_mode = Line2D.LINE_JOINT_ROUND

	if parent_2d != null:
		trail.add_point(parent_2d.to_local(start_position))
		trail.add_point(parent_2d.to_local(end_position))
	else:
		trail.add_point(start_position)
		trail.add_point(end_position)

	var trail_tween := trail.create_tween()
	trail_tween.set_parallel(true)
	trail_tween.tween_property(
		trail,
		"modulate:a",
		0.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	trail_tween.tween_property(
		trail,
		"width",
		6.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	trail_tween.finished.connect(
		Callable(trail, "queue_free"),
		Object.CONNECT_ONE_SHOT
	)

	var segment: Vector2 = end_position - start_position
	var segment_length: float = segment.length()
	if segment_length <= 1.0:
		return

	var effect_count: int = clampi(
		int(ceil(segment_length / 68.0)) + 1,
		3,
		8
	)
	var effect_direction: Vector2 = segment.normalized()
	for index in range(effect_count):
		var progress: float = (
			float(index)
			/ float(maxi(effect_count - 1, 1))
		)
		var effect_position: Vector2 = start_position.lerp(
			end_position,
			progress
		)
		var blood_fx: AnimatedSprite2D = _spawn_archmage_fx(
			"%s/effect2" % STAGE6_FRAME_DIR,
			"blood_effect",
			1,
			10,
			28.0,
			false,
			effect_position,
			Vector2(0.82, 0.82)
		)
		if not is_instance_valid(blood_fx):
			continue
		blood_fx.rotation = effect_direction.angle()
		blood_fx.modulate = Color(1.0, 0.72, 0.72, 0.92)
		blood_fx.z_index = 7
		var fade_tween := blood_fx.create_tween()
		fade_tween.tween_property(
			blood_fx,
			"modulate:a",
			0.0,
			0.30
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_berserker_hp_visual() -> void:
	if hero_archetype != "berserker_madness" or not hero_sprite.visible:
		return
	var hp_ratio: float = clampf(
		float(current_hp) / float(maxi(max_hp, 1)),
		0.0,
		1.0
	)
	var missing_ratio: float = 1.0 - hp_ratio
	hero_sprite.modulate = Color(
		1.0,
		lerpf(1.0, 0.36, missing_ratio),
		lerpf(1.0, 0.36, missing_ratio),
		1.0
	)


func _begin_berserker_revive() -> void:
	if berserker_revive_used or berserker_reviving:
		return

	berserker_revive_used = true
	berserker_reviving = true
	berserker_saved_collision_layer = collision_layer
	berserker_saved_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	invulnerability_timer = 0.0
	modulate.a = 0.45
	_restart_stage1_animation("death", 0.72)
	queue_redraw()

	var revive_delay: float = maxf(
		float(berserker_config.get("revive_delay", 3.0)),
		0.1
	)
	await get_tree().create_timer(revive_delay).timeout
	if not is_inside_tree() or is_dying:
		return

	var revive_ratio: float = clampf(
		float(berserker_config.get("revive_hp_ratio", 0.50)),
		0.01,
		1.0
	)
	current_hp = maxi(int(round(float(max_hp) * revive_ratio)), 1)
	collision_layer = berserker_saved_collision_layer
	collision_mask = berserker_saved_collision_mask
	berserker_reviving = false
	modulate.a = 1.0
	hit_pose_timer = 0.0
	attack_pose_timer = 0.0
	_restart_stage1_animation("idle")
	_update_berserker_hp_visual()
	health_changed.emit(current_hp, max_hp)
	queue_redraw()


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
	_update_magnet_item_goal(delta)

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
	move_direction = _apply_magnet_item_steering(move_direction, delta)
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
	var radius := maxf(
		float(fighter_charge_config.get("trigger_radius", 245.0)),
		1.0
	)
	var required := maxi(
		int(fighter_charge_config.get("trigger_enemy_count", 4)),
		1
	)
	return _count_monsters_near(
		global_position,
		radius,
		required
	) >= required

func _start_fighter_charge() -> void:
	var charge_target := _find_fighter_charge_target()
	if not is_instance_valid(charge_target):
		return
	fighter_charge_chain_count = 0
	_begin_fighter_charge_dash(charge_target)

func _find_fighter_charge_target(exclude: Node = null) -> Node2D:
	var max_distance := maxf(float(fighter_charge_config.get("max_target_distance", 560.0)), 1.0)
	var max_distance_sq := max_distance * max_distance
	var farthest: Node2D = null
	var farthest_distance_sq := -1.0
	for node in _get_monster_nodes_near(global_position, max_distance):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node == exclude:
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		if (
			distance_sq <= max_distance_sq
			and distance_sq > farthest_distance_sq
		):
			farthest = monster
			farthest_distance_sq = distance_sq
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
		if (
			global_position.distance_squared_to(monster.global_position)
			<= radius * radius
		):
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

	heal_direct(heal_amount)

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

	if is_instance_valid(magnet_item_target):
		var magnet_direction := _apply_magnet_item_steering(
			Vector2.ZERO,
			0.016
		)
		if magnet_direction.length_squared() > 0.01:
			velocity = (
				magnet_direction
				* move_speed
				* 0.82
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
			if (
				global_position.distance_squared_to(chest_target.global_position)
				<= 105.0 * 105.0
				and attack_timer <= 0.0
			):
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

	if (
		wander_timer <= 0.0
		or position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE * WANDER_REACHED_DISTANCE
	):
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
		if (
			global_position.distance_squared_to(monster.global_position)
			<= radius * radius
		):
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
		heal_direct(bonus_kills * 10)

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
		if (
			global_position.distance_squared_to(monster.global_position)
			<= radius * radius
		):
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
			if (
				global_position.distance_squared_to(monster.global_position)
				> release_radius * release_radius
			):
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

	frames.add_animation(&"deadeye_flame")
	frames.set_animation_loop(&"deadeye_flame", true)
	frames.set_animation_speed(&"deadeye_flame", 28.0)
	for index in range(5, 7):
		var flame_path := "res://assets/art/heroes/stage4_gunner/frames/effect/effect_projectile_%02d.png" % index
		var flame_texture := _load_stage1_texture(flame_path)
		if flame_texture == null:
			push_warning("Stage 4 deadeye flame frame load failed: %s" % flame_path)
			continue
		frames.add_frame(&"deadeye_flame", flame_texture)

	frames.add_animation(&"deadeye_smoke")
	frames.set_animation_loop(&"deadeye_smoke", false)
	frames.set_animation_speed(&"deadeye_smoke", 20.0)
	for index in range(7, 13):
		var smoke_path := "res://assets/art/heroes/stage4_gunner/frames/effect/effect_projectile_%02d.png" % index
		var smoke_texture := _load_stage1_texture(smoke_path)
		if smoke_texture == null:
			push_warning("Stage 4 deadeye smoke frame load failed: %s" % smoke_path)
			continue
		frames.add_frame(&"deadeye_smoke", smoke_texture)

	var dust_frames := SpriteFrames.new()
	if dust_frames.has_animation(&"default"):
		dust_frames.remove_animation(&"default")
	dust_frames.add_animation(&"cylinder_dust")
	dust_frames.set_animation_loop(&"cylinder_dust", false)
	dust_frames.set_animation_speed(&"cylinder_dust", 20.0)

	for index in range(1, 9):
		var dust_path := "%s/ground_effect_%02d.png" % [STAGE3_CHARGE_EFFECT_DIR, index]
		var dust_texture := _load_stage1_texture(dust_path)
		if dust_texture == null:
			push_warning("Cylinder dust frame load failed: %s" % dust_path)
			continue
		dust_frames.add_frame(&"cylinder_dust", dust_texture)

	if (
		frames.get_frame_count(&"deadeye_flame") > 0
		or frames.get_frame_count(&"deadeye_smoke") > 0
	):
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


func _set_gunner_muzzle_transform(direction: Vector2) -> void:
	var dir := direction.normalized()
	if dir.length_squared() <= 0.0:
		dir = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	rogue_attack_effect.position = dir * 48.0 + Vector2(0.0, -6.0)
	rogue_attack_effect.rotation = dir.angle()


func _play_gunner_deadeye_flame(direction: Vector2) -> void:
	if rogue_attack_effect.sprite_frames == null:
		return
	if not rogue_attack_effect.sprite_frames.has_animation(&"deadeye_flame"):
		return
	if rogue_attack_effect.sprite_frames.get_frame_count(&"deadeye_flame") <= 0:
		return

	_set_gunner_muzzle_transform(direction)
	rogue_attack_effect.visible = true

	# Deadeye muzzle flame must pop on every single shot.
	rogue_attack_effect.stop()
	rogue_attack_effect.animation = &"deadeye_flame"
	rogue_attack_effect.frame = 0
	rogue_attack_effect.frame_progress = 0.0
	rogue_attack_effect.play(&"deadeye_flame")


func _play_gunner_deadeye_smoke(direction: Vector2) -> void:
	if rogue_attack_effect.sprite_frames == null:
		return
	if not rogue_attack_effect.sprite_frames.has_animation(&"deadeye_smoke"):
		rogue_attack_effect.visible = false
		return
	if rogue_attack_effect.sprite_frames.get_frame_count(&"deadeye_smoke") <= 0:
		rogue_attack_effect.visible = false
		return

	_set_gunner_muzzle_transform(direction)
	rogue_attack_effect.visible = true
	rogue_attack_effect.stop()
	rogue_attack_effect.animation = &"deadeye_smoke"
	rogue_attack_effect.frame = 0
	rogue_attack_effect.frame_progress = 0.0
	rogue_attack_effect.play(&"deadeye_smoke")


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
	if (
		hero_archetype == "alchemist_chemical"
		and alchemist_equivalent_exchange_damage_reduction_timer > 0.0
	):
		var exchange_stacks := _get_alchemist_augment_stacks(
			"alchemist_equivalent_exchange"
		)
		if exchange_stacks >= 4:
			var exchange_data := _get_alchemist_equivalent_exchange_data(exchange_stacks)
			raw_damage *= 1.0 - clampf(
				float(exchange_data.get("damage_reduction", 0.0)),
				0.0,
				0.90
			)
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
			elif hero_archetype == "cleric_purifier" and purifier_protection_active:
				_end_purifier_protection(true)
			else:
				if hero_archetype == "summoner_gatekeeper":
					var resonance_stacks := _get_summoner_augment_stacks("summoner_shield_resonance")
					_extend_regular_summon_durations(float(resonance_stacks) * 0.6)
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
		if (
			hero_archetype == "berserker_madness"
			and not berserker_revive_used
			and not berserker_reviving
		):
			_begin_berserker_revive()
		else:
			_begin_death_sequence()
	else:
		invulnerability_timer = invulnerability_duration
		if hero_archetype == "pistol_gunner" and _gunner_should_backstep_on_hit():
			_start_gunner_backstep()
		_refresh_invulnerability_visual()

	return true

func _update_hero_hit_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	if hit_flash_timer <= 0.0:
		queue_redraw()


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


	# The fallback debug body is only for a genuinely missing/unavailable
	# hero visual. During channeling the real sprite is intentionally hidden
	# behind ChannelEffect, so drawing the placeholder here leaks a fake body
	# through the 12-frame philosopher-stone animation.
	if not hero_sprite.visible and not channel_hid_hero_sprite:
		var body_color := Color(0.35, 0.68, 1.0)
		if hit_flash_timer > 0.0:
			body_color = Color(1.0, 1.0, 1.0)
		draw_circle(Vector2.ZERO, 34.0, body_color)
		draw_circle(Vector2(0, -4), 21.0, Color(0.82, 0.9, 1.0))
		draw_line(Vector2(22, 13), Vector2(44, -12), Color(0.82, 0.72, 0.48), 7.0)
		draw_circle(Vector2(49, -17), 8.0, Color(0.95, 0.86, 0.32))

	var bar_width := 92.0
	var bar_x_offset := 0.0
	var resource_bar_y := -79.0
	var hp_bar_y := -64.0
	var shield_bar_y := -49.0
	if hero_archetype == "summoner_gatekeeper":
		# Stage 8 uses a feet/root anchor. Its body is taller above the node,
		# so the shared -64 HP bar crosses the torso. Lift both summon slots
		# and HP bar together while keeping their original 15px spacing.
		resource_bar_y = -128.0
		hp_bar_y = -113.0
		shield_bar_y = -98.0
	elif hero_archetype == "cleric_purifier":
		# Stage 9's hood/head reaches into the shared bar area even after the
		# sprite anchor correction. Keep the hero root and sprite position as-is
		# and lift only the UI bars, preserving their 15px vertical spacing.
		# Keep the bars centered on the gameplay root. The purifier sprite itself
		# carries the Stage 9-specific horizontal visual compensation.
		bar_x_offset = 0.0
		resource_bar_y = -100.0
		hp_bar_y = -85.0
		shield_bar_y = -70.0
	var bar_left_x := -bar_width / 2.0 + bar_x_offset
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
			draw_rect(Rect2(x, resource_bar_y, cell_width, 8.0), Color(0.12, 0.12, 0.14), true)
			if index < displayed_cells:
				draw_rect(Rect2(x, resource_bar_y, cell_width, 8.0), Color(1.0, 0.77, 0.16), true)
	elif hero_archetype == "summoner_gatekeeper":
		var slot_count := _get_summoner_slot_capacity()
		var active_summons := _get_active_summon_count()
		var gap := 2.0
		var cell_width := (
			bar_width - gap * float(slot_count - 1)
		) / float(slot_count)
		for index in range(slot_count):
			var x := -bar_width / 2.0 + float(index) * (cell_width + gap)
			draw_rect(
				Rect2(x, resource_bar_y, cell_width, 8.0),
				Color(0.12, 0.12, 0.14),
				true
			)
			if index < active_summons:
				draw_rect(
					Rect2(x, resource_bar_y, cell_width, 8.0),
					Color(0.55, 0.40, 0.95),
					true
				)
	elif hero_archetype == "alchemist_chemical":
		var gas_ratio := clampf(alchemist_gas / maxf(alchemist_gas_max, 1.0), 0.0, 1.0)
		draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0), Color(0.12, 0.12, 0.14), true)
		draw_rect(
			Rect2(-bar_width / 2.0, -79.0, bar_width * gas_ratio, 8.0),
			Color(0.68, 0.28, 0.92),
			true
		)
	elif hero_archetype == "cleric_purifier":
		var purifier_max := maxf(
			float(purifier_gauge_config.get("charge_max", 100.0)),
			1.0
		)
		var purifier_ratio := clampf(
			ultimate_charge / purifier_max,
			0.0,
			1.0
		)
		draw_rect(
			Rect2(bar_left_x, resource_bar_y, bar_width, 8.0),
			Color(0.12, 0.12, 0.14),
			true
		)
		draw_rect(
			Rect2(bar_left_x, resource_bar_y, bar_width * purifier_ratio, 8.0),
			Color(1.0, 0.77, 0.16),
			true
		)
	elif hero_archetype == "berserker_madness":
		var madness_max: float = maxf(
			float(berserker_config.get("gauge_max", 100.0)),
			1.0
		)
		var madness_ratio: float = clampf(
			ultimate_charge / madness_max,
			0.0,
			1.0
		)
		draw_rect(
			Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0),
			Color(0.12, 0.12, 0.14),
			true
		)
		draw_rect(
			Rect2(
				-bar_width / 2.0,
				resource_bar_y,
				bar_width * madness_ratio,
				8.0
			),
			Color(1.0, 0.30, 0.08),
			true
		)
	else:
		var ultimate_max := maxf(float(ultimate_config.get("charge_max", 100.0)), 1.0)
		var ultimate_ratio := clampf(ultimate_charge / ultimate_max, 0.0, 1.0)
		draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0), Color(0.12, 0.12, 0.14), true)
		draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width * ultimate_ratio, 8.0), Color(1.0, 0.77, 0.16), true)

	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	draw_rect(
		Rect2(bar_left_x, hp_bar_y, bar_width, 10.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	draw_rect(
		Rect2(
			bar_left_x,
			hp_bar_y,
			bar_width * hp_ratio,
			10.0
		),
		Color(0.95, 0.38, 0.32),
		true
	)

	if shield_max_hp > 0.0 and shield_hp > 0.0:
		var shield_ratio := clampf(
			shield_hp / maxf(shield_max_hp, 1.0),
			0.0,
			1.0
		)
		draw_rect(
			Rect2(bar_left_x, shield_bar_y, bar_width, 8.0),
			Color(0.10, 0.12, 0.18),
			true
		)
		draw_rect(
			Rect2(
				bar_left_x,
				shield_bar_y,
				bar_width * shield_ratio,
				8.0
			),
			Color(0.20, 0.65, 1.0),
			true
		)
