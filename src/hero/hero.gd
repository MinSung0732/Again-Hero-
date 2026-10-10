extends CharacterBody2D

const HERO_ACTION_INTENT := preload("res://src/hero/hero_action_intent.gd")
const HERO_ACTION_PORT := preload("res://src/hero/hero_action_port.gd")
var action_intent = HERO_ACTION_INTENT.new()

const TIMED_EVENT_BUFFER := preload("res://src/systems/timed_event_buffer.gd")

const LOCAL_GRID_MOVEMENT := preload("res://src/monsters/monster_runtime_common.gd")

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

signal died
signal health_changed(current_hp: int, max_hp_value: int)
signal status_applied(status_id: String)
signal status_action_applied(status_id: String)
const STATUS_ACTION_SCOPE := preload("res://src/systems/status_action_scope.gd")
var petrify_status_action: RefCounted
signal accepted_damage_hit(source: Node)
signal combat_damage_received(hp_damage: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal leveled_up(new_level: int)
signal augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal ultimate_used(ultimate_id: String, ultimate_name: String)
signal conditional_skill_unlocked(skill_id: String, skill_name: String, payload: Dictionary)

const MEDUSA_BEHAVIOR := preload("res://src/data/medusa_behavior_catalog.gd")
const SUCCUBUS_BEHAVIOR := preload("res://src/data/succubus_behavior_catalog.gd")
const BURN_RUNTIME := preload("res://src/systems/burn_runtime.gd")
const DAMAGE_POISON_TRACKER := preload("res://src/systems/damage_poison_tracker.gd")
const AUGMENT_CATALOG := preload("res://src/data/hero_augment_catalog.gd")
const BUILD_AI := preload("res://src/ai/hero_build_ai.gd")
const PROJECTILE_SCENE := preload("res://src/hero/HeroProjectile.tscn")
const PROJECTILE_VOLLEY := preload("res://src/hero/projectile_volley.gd")
const GUNNER_PROJECTILE_SCENE := preload("res://src/hero/GunnerProjectile.tscn")
const ARCHMAGE_PROJECTILE_SCENE := preload("res://src/hero/ArchmageProjectile.tscn")
const ARCHMAGE_SKILL_PROJECTILE_SCENE := preload("res://src/hero/ArchmageSkillProjectile.tscn")
const SAGE_PROJECTILE_SCENE := preload("res://src/hero/SageProjectile.tscn")
const SAGE_ICE_PILLAR_SCENE := preload("res://src/hero/SageIcePillar.tscn")
const SAGE_RADIANCE_ORB_SCENE := preload("res://src/hero/SageRadianceOrb.tscn")
const SAGE_STARLIGHT_METEOR_SCENE := preload("res://src/hero/SageStarlightMeteor.tscn")
const SAGE_ANNIHILATION_POINT_SCENE := preload("res://src/hero/SageAnnihilationPoint.tscn")
const SAGE_BLACKSPOT_EXPLOSION_SCENE := preload("res://src/hero/SageBlackSpotExplosion.tscn")
const ULTIMATE_PIERCING_PROJECTILE_SCENE := preload(
	"res://src/hero/UltimatePiercingProjectile.tscn"
)
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const STATUS_EFFECT_CATALOG := preload("res://src/data/status_effect_catalog.gd")
const DAMAGE_NUMBERS := preload("res://src/ui/damage_number_spawner.gd")
const COMBAT_STATUS_EFFECT_VISUAL := preload("res://src/ui/combat_status_effect_visual.gd")
const HERO_WORLD_QUERY_RUNTIME := preload("res://src/hero/hero_world_query_runtime.gd")
const HERO_SUMMONER_RUNTIME := preload("res://src/hero/hero_summoner_runtime.gd")
const HERO_FIGHTER_RUNTIME := preload("res://src/hero/hero_fighter_runtime.gd")
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
const ARCHMAGE_OFFENSIVE_SKILL_KEYS: Array[String] = [
	"combustion",
	"ice_bolt",
	"earth_spikes",
	"holy_power",
	"chain_dagger",
	"storm",
]
const ARCHMAGE_SKILL_KEYS: Array[String] = [
	"combustion",
	"ice_bolt",
	"earth_spikes",
	"holy_power",
	"chain_dagger",
	"harmony",
	"storm",
]
const ARCHMAGE_DEFAULT_BASIC_ELEMENTS: Array[String] = [
	"earth",
	"fire",
	"ice",
	"light",
	"wind",
	"holy",
]
const ARCHMAGE_ORB_ELEMENTS: Array[String] = [
	"fire",
	"water",
	"wind",
	"electric",
	"earth",
	"holy",
]
const ARCHMAGE_ORB_FRAME_INDEX := {
	"fire": 1,
	"water": 2,
	"wind": 3,
	"electric": 4,
	"earth": 5,
	"holy": 7,
}
const STAGE6_FRAME_DIR := "res://assets/art/heroes/stage6_berserker/frames"
const STAGE7_FRAME_DIR := "res://assets/art/heroes/stage7_alchemist/frames"
const STAGE8_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames"
const STAGE9_FRAME_DIR := "res://assets/art/heroes/stage9_prist/frames"
const STAGE10_FRAME_DIR := "res://assets/art/heroes/stage10_sage/frames"
const CONTEXT_AUDIO := preload("res://src/data/contextual_audio_catalog.gd")
const STAGE1_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_basic_attack_pixabay.mp3"
const STAGE1_BARRIER_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_barrier_pixabay.mp3"
const STAGE1_ARCANE_FIELD_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_arcane_field_pixabay.mp3"
const STAGE1_ARCANE_PIERCER_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_arcane_piercer_clean.wav"
const STAGE1_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"mage_hit.wav"
const STAGE1_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_death_pixabay.mp3"
const STAGE1_LEVEL_UP_AUDIO_PATH := "res://assets/audio/sfx/level_up_rise07_cc0.mp3"
const STAGE2_COMBO_SLASH_AUDIO_PATH := "res://assets/audio/sfx/contextual/rogue_combo_short.wav"
const STAGE2_BLADE_STORM_AUDIO_PATH := "res://assets/audio/sfx/contextual/rogue_storm_short.wav"
const STAGE2_ASSASSINATION_START_AUDIO_PATH := "res://assets/audio/sfx/stage2_rogue_assassination_start_pixabay.mp3"
const STAGE2_ASSASSINATION_HIT_AUDIO_PATH := "res://assets/audio/sfx/contextual/rogue_assassination_short.wav"
const STAGE2_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"rogue_hit.wav"
const STAGE2_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage2_rogue_death_pixabay.mp3"
const STAGE3_SLASH_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_slash_pixabay.mp3"
const STAGE3_THRUST_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_thrust_pixabay.mp3"
const STAGE3_GUARD_START_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_guard_start_pixabay.mp3"
const STAGE3_GUARD_RELEASE_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_guard_release_pixabay.mp3"
const STAGE3_CHARGE_IMPACT_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_charge_impact_clean.wav"
const STAGE3_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"fighter_hit.wav"
const STAGE3_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_death_pixabay.mp3"
const STAGE4_GUNSHOT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"gunner_shot.wav"
const STAGE4_RELOAD_AUDIO_PATH := "res://assets/audio/sfx/stage4_gunner_reload_pixabay.mp3"
# Keep only the final cylinder-spin ("drrrrk") section of the source reload.
const STAGE4_RELOAD_AUDIO_START_OFFSET := 2.58
const STAGE4_BACKSTEP_AUDIO_PATH := "res://assets/audio/sfx/stage4_gunner_backstep_pixabay.mp3"
const STAGE4_CYLINDER_AUDIO_PATH := "res://assets/audio/sfx/stage4_gunner_cylinder_clean.wav"
const STAGE4_DEADEYE_START_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"deadeye_cock.wav"
const STAGE4_DEADEYE_SHOT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"deadeye_shot.wav"
const STAGE4_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"gunner_hit.wav"
const STAGE4_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage4_gunner_death_pixabay.mp3"
const STAGE5_BASIC_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_basic_pixabay.mp3"
const STAGE5_COMBUSTION_CHARGE_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_combustion_charge_pixabay.mp3"
const STAGE5_COMBUSTION_RELEASE_AUDIO_PATH := "res://assets/audio/sfx/bulgasal/archmage_fire_burst.wav"
const STAGE5_ICE_BOLT_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_ice_crystal_launch.wav"
const STAGE5_ICE_IMPACT_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_ice_crystal_impact.wav"
const STAGE5_EARTH_SPIKE_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_earth_spike_clean.wav"
const STAGE5_HOLY_BURST_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_holy_burst_pixabay.mp3"
const STAGE5_CHAIN_LAUNCH_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_chain_launch_pixabay.mp3"
const STAGE5_CHAIN_HIT_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_chain_hit_pixabay.mp3"
const STAGE5_HARMONY_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_harmony_pixabay.mp3"
const STAGE5_STORM_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_storm_pixabay.mp3"
const STAGE5_BLINK_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_blink_pixabay.mp3"
const STAGE5_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"archmage_hit.wav"
const STAGE5_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage5_archmage_death_pixabay.mp3"
const STAGE6_BASIC_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_basic_slash_pixabay.mp3"
const STAGE6_SKILL1_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_blood_wave_pixabay.mp3"
const STAGE6_SKILL2_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_ground_slam_clean.wav"
const STAGE6_SKILL3_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_dash_pixabay.mp3"
const STAGE6_SKILL4_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_spin_slash_pixabay.mp3"
const STAGE6_MADNESS_ROAR_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"berserker_roar.wav"
const STAGE6_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"berserker_hit.wav"
const STAGE6_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage6_berserker_death_pixabay.mp3"

# Hero SFX loudness defaults are anchored to the established Stage 7-10 mix.
# Source loudness and repetition density may justify a quieter per-asset value,
# but new hero SFX should start from these bands instead of arbitrary numbers.
const HERO_SFX_DB_PRIMARY_ATTACK := -12.0
const HERO_SFX_DB_REGULAR_SKILL := -12.0
const HERO_SFX_DB_HEAVY_SKILL := -9.0
const HERO_SFX_DB_HIT := -20.0
const HERO_SFX_DB_DEATH := -12.0
const HERO_SFX_DB_SECONDARY_REPEAT := -26.0
const HERO_SFX_DB_TINY_REPEAT := -32.0

const SAGE_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_basic_attack_pixabay.mp3"
const SAGE_THIRD_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_third_attack_pixabay.mp3"
const SAGE_PHASE_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_phase_pixabay.mp3"
const SAGE_ICE_PILLAR_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_ice_pillar_pixabay.mp3"
const SAGE_RADIANCE_CREATE_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_radiance_create_pixabay.mp3"
const SAGE_CONDENSATION_STACK_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_condensation_stack_pixabay.mp3"
const SAGE_CONDENSATION_RELEASE_AUDIO_PATH := "res://assets/audio/sfx/sage_astra_condensation_release_pixabay.mp3"
const SAGE_CONDENSATION_SLOT_ANGLES: Array[float] = [
	-90.0, 0.0, 90.0, 180.0, -60.0, 60.0, 120.0, -150.0
]
const SAGE_SFX_REFERENCE_DB := -10.0
const SUMMONER_GATEKEEPER_SCENE := preload("res://src/hero/SummonerGatekeeper.tscn")
const SUMMONER_SCOUT_SCENE := preload("res://src/hero/SummonerScout.tscn")
const SUMMONER_HOUND_SCENE := preload("res://src/hero/SummonerHound.tscn")
const SUMMONER_WATCHER_SCENE := preload("res://src/hero/SummonerWatcher.tscn")
const SUMMONER_OPEN_GATE_SCENE := preload("res://src/hero/SummonerOpenGate.tscn")
const SUMMONER_AUDIO := preload("res://src/data/summoner_audio_catalog.gd")
const SUMMONER_BASIC_ATTACK_AUDIO_PATH := SUMMONER_AUDIO.BASIC
const PURIFIER_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/purifier_basic_attack_pixabay.mp3"
const PURIFIER_SHIELD_CREATE_AUDIO_PATH := "res://assets/audio/sfx/purifier_shield_create_pixabay.mp3"
const PURIFIER_SHIELD_BREAK_AUDIO_PATH := "res://assets/audio/sfx/purifier_shield_break_pixabay.mp3"
const PURIFIER_CROWN_AUDIO_PATH := "res://assets/audio/sfx/purifier_crown_buff_pixabay.mp3"
const PURIFIER_ORB_CREATE_AUDIO_PATH := "res://assets/audio/sfx/purifier_orb_create_pixabay.mp3"
const PURIFIER_ORB_EXPLOSION_AUDIO_PATH := "res://assets/audio/sfx/purifier_orb_explosion_pixabay.mp3"
const PURIFIER_CLEANSING_AUDIO_PATH := "res://assets/audio/sfx/purifier_cleansing_pixabay.mp3"
const PURIFIER_GUNGNIR_CHARGE_AUDIO_PATH := "res://assets/audio/sfx/purifier_gungnir_charge_pixabay.mp3"
const PURIFIER_GUNGNIR_FLIGHT_AUDIO_PATH := "res://assets/audio/sfx/purifier_gungnir_flight_pixabay.mp3"
const PURIFIER_GUNGNIR_EXPLOSION_AUDIO_PATH := "res://assets/audio/sfx/purifier_gungnir_explosion_pixabay.mp3"
const PURIFIER_ORB_SCENE := preload("res://src/hero/PurifierOrb.tscn")
const PURIFIER_ORB_LINK_SCENE := preload("res://src/hero/PurifierOrbLink.tscn")
const PURIFIER_CLEANSING_FX_SCENE := preload("res://src/hero/PurifierCleansingFx.tscn")
const PURIFIER_GUNGNIR_SCENE := preload("res://src/hero/PurifierGungnir.tscn")
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
# Demon Castle hard-boundary layer. Astra phase may ignore monsters/decor,
# but must still collide with structural arena boundaries such as the top wall.
const SAGE_PHASE_BOUNDARY_COLLISION_MASK := 1 << 3
const HERO_DECOR_COLLISION_LAYER := 1 << 2
const OBSTACLE_STUCK_TRIGGER_SECONDS := 0.30
const OBSTACLE_ESCAPE_SECONDS := 0.65
const OBSTACLE_MIN_INTENDED_SPEED := 36.0
const OBSTACLE_STUCK_PROGRESS_RATIO := 0.26
const RANGED_PRESSURE_RADIUS := 850.0
const RANGED_PRESSURE_TRIGGER_COUNT := 4
const RANGED_PRESSURE_REFRESH_SECONDS := 0.20

static var _archmage_fx_frames_cache: Dictionary = {}
static var _purifier_protection_frames_cache: SpriteFrames
static var _purifier_crown_frames_cache: SpriteFrames
static var _sage_afterimage_frames_cache: SpriteFrames
static var _sage_condensation_frames_cache: SpriteFrames

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
var sprite_frame_dir: String = ""
var ground_shadow_config: Dictionary = {}
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
var rogue_query_candidates: Array = []
var rogue_combo_candidates: Array = []
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
const BATTLE_TARGET_REFERENCE := preload("res://src/systems/battle_target_reference.gd")
var fighter_charge_reference = BATTLE_TARGET_REFERENCE.new()
var fighter_charge_target: Node2D
var fighter_charge_start: Vector2 = Vector2.ZERO
var fighter_charge_end: Vector2 = Vector2.ZERO
var fighter_charge_duration: float = 0.0
var fighter_charge_elapsed: float = 0.0
var fighter_charge_chain_count: int = 0
var fighter_charge_afterimage_timer: float = 0.0
var fighter_charge_target_candidates: Array = []
var fighter_charge_impact_candidates: Array = []
var fighter_combat_candidates: Array = []
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
var gunner_deadeye_monster_offsets: Array[Vector2] = []
var gunner_deadeye_analysis_direction: Vector2 = Vector2.RIGHT
var gunner_deadeye_analysis_score: float = 0.0
var gunner_deadeye_analysis_hits: int = 0
var gunner_escape_monster_positions: Array[Vector2] = []
var gunner_query_candidates: Array = []
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
var berserker_query_candidates: Array = []

var archmage_element_config: Dictionary = {}
var archmage_basic_elements: Array[String] = []
var archmage_last_element: String = ""
var archmage_skill_config: Dictionary = {}
var archmage_skill_cooldowns: Dictionary = {}
var archmage_element_orbs: Dictionary = {}
var archmage_orbit_sprites: Dictionary = {}
var archmage_orbit_order: Array[String] = []
var archmage_orbit_angle: float = 0.0
var archmage_chain_dagger_active: bool = false
var archmage_chain_dagger_active_count: int = 0
var archmage_chain_multithrow_stacks: int = 0
var archmage_chain_target_candidates: Array[Node2D] = []
var archmage_chain_target_results: Array[Node2D] = []
var archmage_query_candidates: Array = []
var archmage_casting_sequence: bool = false
var archmage_casting_sequence_count: int = 0
var archmage_multicast_stacks: int = 0
var archmage_multicast_active: bool = false
var archmage_multicast_candidates: Array[String] = []
var archmage_blink_stacks: int = 0
var archmage_blink_cooldown_timer: float = 0.0
var archmage_cooldown_reduction: float = 0.0
var archmage_mana_overflow_stacks: int = 0
var archmage_element_cycle_stacks: int = 0

var sage_config: Dictionary = {}
var sage_attack_serial: int = 0
var sage_phase_cooldown_timer: float = 25.0
var sage_phase_remaining: float = 0.0
var sage_phase_active: bool = false
var sage_phase_entry_position := Vector2.ZERO
var sage_saved_collision_mask: int = -1
var sage_afterimage_timer: float = 0.0
var sage_afterimage_pool: Array[AnimatedSprite2D] = []
var sage_afterimage_index: int = 0
var sage_post_phase_shield_timer: float = 0.0
var sage_gauge_redraw_timer: float = 0.0
var sage_skill1_cooldown_timer: float = 0.0
var sage_skill2_cooldown_timer: float = 0.0
var sage_skill3_cooldown_timer: float = 0.0
var sage_skill4_cooldown_timer: float = 0.0
var sage_skill5_cooldown_timer: float = 0.0
var sage_radiance_launch_remaining: int = 0
var sage_radiance_launch_timer: float = 0.0
var sage_radiance_target_cursor: int = 0
var sage_condensation_stacks: int = 0
var sage_condensation_completion_count: int = 0
var sage_condensation_skill_damage_buff_timer: float = 0.0
var sage_condensation_visuals: Array[AnimatedSprite2D] = []
var sage_condensation_free_slots: Array[int] = []
var sage_condensation_unlock_pending: bool = false
var sage_condensation_unlock_effect_timer: float = 0.0
var sage_starlight_remaining: float = 0.0
var sage_starlight_volley_timer: float = 0.0
var sage_starlight_aura: Sprite2D
var sage_basic_audio: AudioStreamPlayer
var sage_third_audio: AudioStreamPlayer
var sage_phase_audio: AudioStreamPlayer
var sage_ice_pillar_audio: AudioStreamPlayer
var sage_radiance_create_audio: AudioStreamPlayer
var sage_condensation_stack_audio: AudioStreamPlayer
var sage_condensation_release_audio: AudioStreamPlayer

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
var alchemist_mystery_vial_pool: Array[Node2D] = []
var alchemist_poison_pool: Array[Node2D] = []
var alchemist_material_pool: Array[Node2D] = []
var alchemist_bonus_material_pool: Array[Node2D] = []
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
var alchemist_emergency_threats: Array[Node2D] = []
var alchemist_movement_query_candidates: Array = []
var alchemist_damage_query_candidates: Array = []
var alchemist_emergency_query_candidates: Array = []
var alchemist_emergency_escape_direction: Vector2 = Vector2.RIGHT
var alchemist_philosopher_config: Dictionary = {}
var alchemist_materials_collected: int = 0
var alchemist_philosopher_used: bool = false
var alchemist_philosopher_channeling: bool = false
var alchemist_philosopher_channel_timer: float = 0.0
var alchemist_philosopher_test_timer: float = 0.0
var alchemist_philosopher_unlock_pending: bool = false
var alchemist_philosopher_unlock_timer: float = 0.0
var alchemist_philosopher_unlock_grace_timer: float = 0.0
var alchemist_philosopher_unlock_effect: AnimatedSprite2D
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
var summoner_ai_query_candidates: Array = []
var summoner_runtime_ready: bool = false
var summoner_basic_effect: AnimatedSprite2D = null
var summoner_basic_audio: AudioStreamPlayer = null
var summoner_basic_audio_next_ms := 0
var stage1_basic_audio: AudioStreamPlayer = null
var stage1_barrier_audio: AudioStreamPlayer = null
var stage1_arcane_field_audio: AudioStreamPlayer = null
var stage1_arcane_piercer_audio: AudioStreamPlayer = null
var contextual_hit_next_ms := 0
var fighter_block_audio: AudioStreamPlayer
var magic_block_audio: AudioStreamPlayer
var stage1_hit_audio: AudioStreamPlayer = null
var stage1_death_audio: AudioStreamPlayer = null
var stage1_level_up_audio: AudioStreamPlayer = null
var rogue_combo_audio_pool: Array[AudioStreamPlayer] = []
var rogue_combo_audio_cursor: int = 0
var rogue_combo_audio_next_ms := 0
var rogue_assassination_audio_next_ms := 0
var rogue_blade_storm_audio: AudioStreamPlayer = null
var rogue_assassination_start_audio: AudioStreamPlayer = null
var rogue_assassination_hit_audio_pool: Array[AudioStreamPlayer] = []
var rogue_assassination_hit_audio_cursor: int = 0
var rogue_hit_audio: AudioStreamPlayer = null
var rogue_death_audio: AudioStreamPlayer = null
var fighter_slash_audio_pool: Array[AudioStreamPlayer] = []
var fighter_slash_audio_cursor: int = 0
var fighter_thrust_audio_pool: Array[AudioStreamPlayer] = []
var fighter_thrust_audio_cursor: int = 0
var fighter_guard_start_audio: AudioStreamPlayer = null
var fighter_guard_release_audio: AudioStreamPlayer = null
var fighter_charge_impact_audio_pool: Array[AudioStreamPlayer] = []
var fighter_charge_impact_audio_cursor: int = 0
var fighter_hit_audio: AudioStreamPlayer = null
var fighter_death_audio: AudioStreamPlayer = null
var gunner_shot_audio_pool: Array[AudioStreamPlayer] = []
var gunner_shot_audio_cursor: int = 0
var gunner_deadeye_shot_audio_pool: Array[AudioStreamPlayer] = []
var gunner_deadeye_shot_audio_cursor: int = 0
var gunner_reload_audio: AudioStreamPlayer = null
var gunner_backstep_audio: AudioStreamPlayer = null
var gunner_cylinder_audio: AudioStreamPlayer = null
var gunner_deadeye_start_audio: AudioStreamPlayer = null
var gunner_hit_audio: AudioStreamPlayer = null
var gunner_death_audio: AudioStreamPlayer = null
var archmage_basic_audio_pool: Array[AudioStreamPlayer] = []
var archmage_basic_audio_cursor: int = 0
var archmage_combustion_charge_audio: AudioStreamPlayer = null
var archmage_combustion_release_audio: AudioStreamPlayer = null
var archmage_ice_bolt_audio: AudioStreamPlayer = null
var archmage_ice_impact_audio: AudioStreamPlayer = null
var archmage_earth_audio_pool: Array[AudioStreamPlayer] = []
var archmage_earth_audio_cursor: int = 0
var archmage_holy_audio_pool: Array[AudioStreamPlayer] = []
var archmage_holy_audio_cursor: int = 0
var archmage_chain_launch_audio: AudioStreamPlayer = null
var archmage_chain_hit_audio_pool: Array[AudioStreamPlayer] = []
var archmage_chain_hit_audio_cursor: int = 0
var archmage_harmony_audio: AudioStreamPlayer = null
var archmage_storm_audio: AudioStreamPlayer = null
var archmage_blink_audio: AudioStreamPlayer = null
var archmage_hit_audio: AudioStreamPlayer = null
var archmage_death_audio: AudioStreamPlayer = null
var berserker_basic_audio_pool: Array[AudioStreamPlayer] = []
var berserker_basic_audio_cursor: int = 0
var berserker_skill1_audio_pool: Array[AudioStreamPlayer] = []
var berserker_skill1_audio_cursor: int = 0
var berserker_skill2_audio: AudioStreamPlayer = null
var berserker_skill3_audio: AudioStreamPlayer = null
var berserker_skill4_audio: AudioStreamPlayer = null
var berserker_madness_roar_audio: AudioStreamPlayer = null
var berserker_hit_audio: AudioStreamPlayer = null
var berserker_death_audio: AudioStreamPlayer = null
var purifier_basic_audio: AudioStreamPlayer = null
var purifier_shield_create_audio: AudioStreamPlayer = null
var purifier_shield_break_audio: AudioStreamPlayer = null
var purifier_crown_audio: AudioStreamPlayer = null
var purifier_orb_create_audio: AudioStreamPlayer = null
var purifier_orb_explosion_audio: AudioStreamPlayer = null
var purifier_cleansing_audio: AudioStreamPlayer = null
var purifier_gungnir_charge_audio: AudioStreamPlayer = null
var purifier_gungnir_flight_audio: AudioStreamPlayer = null
var purifier_gungnir_explosion_audio: AudioStreamPlayer = null
var purifier_protection_effect: AnimatedSprite2D = null
var purifier_crown_effect: AnimatedSprite2D = null

var ultimate_config: Dictionary = {}
var purifier_gauge_config: Dictionary = {}
var purifier_protection_config: Dictionary = {}
var purifier_crown_config: Dictionary = {}
var purifier_orb_config: Dictionary = {}
var purifier_orb_cooldown: float = 0.0
var purifier_orbs: Array[Node2D] = []
var purifier_orb_links: Dictionary = {}
var purifier_orb_install_serial: int = 0
var purifier_orb_chain_active: bool = false
var purifier_orb_chain_queue: Array[Node2D] = []
var purifier_orb_chain_timer: float = 0.0
var purifier_orb_chain_step: int = 0
var purifier_orb_chain_speed_multiplier: float = 1.0
var purifier_cleansing_config: Dictionary = {}
var purifier_cleansing_cooldown: float = 0.0
var purifier_cleansing_stacks: int = 0
var purifier_gungnir_config: Dictionary = {}
var purifier_gungnir_cooldown: float = 0.0
var purifier_gungnir_casting: bool = false
var purifier_gungnir_direction: Vector2 = Vector2.RIGHT
var purifier_gungnir_instance: Node2D = null
var purifier_protection_cooldown: float = 0.0
var purifier_protection_active: bool = false
var purifier_protection_duration_timer: float = 0.0
var purifier_protection_tick_timer: float = 0.0
var purifier_protection_break_triggered: bool = false
var purifier_crown_cooldown: float = 0.0
var purifier_crown_stacks: int = 0
var purifier_crown_duration_timer: float = 0.0
var purifier_crown_heal_timer: float = 0.0
var purifier_protection_break_count: int = 0
var purifier_broken_sanctuary_timer: float = 0.0
var purifier_prism_launch_queue: Array[Dictionary] = []
var purifier_prism_launch_timer: float = 0.0
var purifier_prism_active: Array[Dictionary] = []
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
var _combat_monster_scratch: Array = []


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


func _fill_monster_nodes_near(
	origin: Vector2,
	radius: float,
	result: Array
) -> void:
	_get_world_query_runtime().call(
		"fill_monster_nodes_near",
		origin,
		radius,
		result
	)


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	var result = _get_world_query_runtime().call(
		"get_monster_nodes_near",
		origin,
		radius
	)
	return result if result is Array else []


func _fill_monster_nodes_in_rect(
	world_rect: Rect2,
	result: Array
) -> void:
	_get_world_query_runtime().call(
		"fill_monster_nodes_in_rect",
		world_rect,
		result
	)


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
var silence_timer := 0.0
var imposed_skill_cooldown := 0.0
var paralysis_timer := 0.0
var paralysis_ratio := 0.0
var is_dying: bool = false
var slow_timer: float = 0.0
var poison_timer: float = 0.0
var poison_tick_timer: float = 0.0
var poison_tick_interval: float = 0.50
var poison_damage_remaining: int = 0
var poison_ticks_remaining: int = 0
var poison_flash_timer: float = 0.0
var poison_flash_active: bool = false
var poison_flash_restore_color: Color = Color.WHITE
var poison_source: Node
var bleed_timer: float = 0.0
var bleed_elapsed: float = 0.0
var bleed_tick_timer: float = 0.0
var bleed_total_damage: int = 0
var bleed_damage_applied: int = 0
var bleed_duration: float = 0.0
var bleed_source: Node
var possession_immunity_timer: float = 0.0
var burn_runtime = BURN_RUNTIME.new()
var damage_poison_tracker = DAMAGE_POISON_TRACKER.new()
var healing_reduction_timer := 0.0
var healing_reduction_ratio := 0.0
var damage_taken_increase_timer := 0.0
var damage_taken_increase_ratio := 0.0
var medusa_hit_stacks := 0
var medusa_stone_threshold := int(MEDUSA_BEHAVIOR.STONE.initial_stacks)
var petrify_timer := 0.0
var petrify_anchor := Vector2.ZERO
var petrify_release_slow := 1.0
var petrify_release_slow_duration := 0.0
var petrify_restore_tint := Color.WHITE
var charm_stacks := 0
var charm_timer := 0.0
var charm_immunity_timer := 0.0
var charm_source: WeakRef
var charm_cooldown_properties: Array = []
var stun_timer: float = 0.0
var stun_sprite_speed: float = 1.0
var fear_timer: float = 0.0
var fear_source: Node2D
var fear_origin: Vector2 = Vector2.ZERO
var fear_speed_multiplier: float = 1.0
var move_multiplier: float = 1.0
var strafe_sign: float = 1.0
var combat_strafe_burst_timer: float = 0.0
var combat_strafe_cooldown_timer: float = 0.0
var ranged_pressure_refresh_timer: float = 0.0
var ranged_pressure_count: int = 0
var ranged_pressure_center: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var obstacle_stuck_timer: float = 0.0
var obstacle_escape_timer: float = 0.0
var obstacle_escape_direction: Vector2 = Vector2.ZERO
var obstacle_escape_side: float = 1.0
var facing_candidate_sign: int = 0
var facing_candidate_timer: float = 0.0

var ai_memory_clock: float = 0.0
var offensive_memory_events = TIMED_EVENT_BUFFER.new()
var status_effect_events = TIMED_EVENT_BUFFER.new()
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

var status_overlay: Node2D
@onready var follow_camera: Camera2D = $Camera2D
@onready var ground_shadow: Sprite2D = $GroundShadow
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
	silence_timer = 0.0
	set_meta("silence_active",false)
	imposed_skill_cooldown = 0.0
	paralysis_timer = 0.0
	paralysis_ratio = 0.0
	_clear_bleed()
	_clear_burn()
	_clear_stun()
	_clear_medusa_statuses()
	_clear_charm()
	_clear_received_modifiers()
	set_meta("dullahan_soul_stacks", 0)
	possession_immunity_timer = 0.0
	fear_timer = 0.0
	fear_source = null
	fear_origin = Vector2.ZERO
	fear_speed_multiplier = 1.0
	set_meta("fear_active", false)
	_movement_monster_scratch.clear()
	_combat_monster_scratch.clear()
	ranged_pressure_refresh_timer = 0.0
	ranged_pressure_count = 0
	ranged_pressure_center = Vector2.ZERO
	ai_observed_context.clear()
	ai_observed_context_time = 0.0

	hero_id = String(profile.get("id", hero_id))
	hero_display_name = String(profile.get("display_name", hero_display_name))
	hero_archetype = String(profile.get("archetype", hero_archetype))
	sprite_frame_dir = String(profile.get("sprite_frame_dir", ""))
	var profile_ground_shadow = profile.get("ground_shadow", {})
	ground_shadow_config = (
		profile_ground_shadow.duplicate(true)
		if typeof(profile_ground_shadow) == TYPE_DICTIONARY
		else {}
	)
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
	fighter_charge_target_candidates.clear()
	fighter_charge_impact_candidates.clear()
	fighter_combat_candidates.clear()
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
	obstacle_stuck_timer = 0.0
	obstacle_escape_timer = 0.0
	obstacle_escape_direction = Vector2.ZERO
	obstacle_escape_side = 1.0 if randf() >= 0.5 else -1.0
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
	berserker_query_candidates.clear()

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
	alchemist_mystery_vial_pool.clear()
	alchemist_poison_pool.clear()
	alchemist_material_pool.clear()
	alchemist_bonus_material_pool.clear()
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
	alchemist_emergency_threats.clear()
	alchemist_movement_query_candidates.clear()
	alchemist_damage_query_candidates.clear()
	alchemist_emergency_query_candidates.clear()
	alchemist_emergency_escape_direction = Vector2.RIGHT
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
	alchemist_philosopher_unlock_pending = false
	alchemist_philosopher_unlock_timer = 0.0
	alchemist_philosopher_unlock_grace_timer = 0.0
	if is_instance_valid(alchemist_philosopher_unlock_effect):
		alchemist_philosopher_unlock_effect.stop()
		alchemist_philosopher_unlock_effect.visible = false
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
	summoner_ai_query_candidates.clear()
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
	gunner_deadeye_monster_offsets.clear()
	gunner_deadeye_analysis_direction = Vector2.RIGHT
	gunner_deadeye_analysis_score = 0.0
	gunner_deadeye_analysis_hits = 0
	gunner_escape_monster_positions.clear()
	gunner_query_candidates.clear()
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
	_configure_archmage_basic_elements()
	archmage_last_element = ""
	var profile_archmage_skills = profile.get("archmage_skills", {})
	archmage_skill_config = (
		profile_archmage_skills.duplicate(true)
		if typeof(profile_archmage_skills) == TYPE_DICTIONARY
		else {}
	)
	archmage_skill_cooldowns.clear()
	for skill_key in ARCHMAGE_SKILL_KEYS:
		archmage_skill_cooldowns[skill_key] = 0.0
	archmage_element_orbs.clear()
	archmage_orbit_order.clear()
	for raw_sprite in archmage_orbit_sprites.values():
		if is_instance_valid(raw_sprite):
			raw_sprite.queue_free()
	archmage_orbit_sprites.clear()
	archmage_orbit_angle = 0.0
	archmage_chain_dagger_active = false
	archmage_chain_dagger_active_count = 0
	archmage_chain_multithrow_stacks = 0
	archmage_chain_target_candidates.clear()
	archmage_chain_target_results.clear()
	archmage_query_candidates.clear()
	archmage_casting_sequence = false
	archmage_casting_sequence_count = 0
	archmage_multicast_stacks = 0
	archmage_multicast_active = false
	archmage_multicast_candidates.clear()
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
	rogue_query_candidates.clear()
	rogue_combo_candidates.clear()
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
	_clear_purifier_orb_runtime()
	var raw_purifier_orb = profile.get("purifier_orb", {})
	purifier_orb_config = (
		raw_purifier_orb.duplicate(true)
		if typeof(raw_purifier_orb) == TYPE_DICTIONARY
		else {}
	)
	purifier_orb_cooldown = maxf(
		float(purifier_orb_config.get("initial_cooldown", 0.0)),
		0.0
	)
	purifier_orb_install_serial = 0
	purifier_orb_chain_active = false
	purifier_orb_chain_queue.clear()
	purifier_orb_chain_timer = 0.0
	purifier_orb_chain_step = 0
	purifier_orb_chain_speed_multiplier = 1.0
	var raw_purifier_cleansing = profile.get("purifier_cleansing", {})
	purifier_cleansing_config = (
		raw_purifier_cleansing.duplicate(true)
		if typeof(raw_purifier_cleansing) == TYPE_DICTIONARY
		else {}
	)
	purifier_cleansing_cooldown = maxf(
		float(purifier_cleansing_config.get("initial_cooldown", 0.0)),
		0.0
	)
	purifier_cleansing_stacks = 0
	var raw_purifier_gungnir = profile.get("purifier_gungnir", {})
	purifier_gungnir_config = (
		raw_purifier_gungnir.duplicate(true)
		if typeof(raw_purifier_gungnir) == TYPE_DICTIONARY
		else {}
	)
	purifier_gungnir_cooldown = maxf(
		float(purifier_gungnir_config.get("initial_cooldown", 0.0)),
		0.0
	)
	purifier_gungnir_casting = false
	purifier_gungnir_direction = Vector2.RIGHT
	purifier_gungnir_instance = null
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
	purifier_protection_break_count = 0
	purifier_broken_sanctuary_timer = 0.0
	purifier_prism_launch_queue.clear()
	purifier_prism_launch_timer = 0.0
	purifier_prism_active.clear()
	fighter_guard_charge_seconds = maxf(
		float(ultimate_config.get("charge_seconds", fighter_guard_charge_seconds)),
		1.0
	)
	if sage_saved_collision_mask >= 0:
		collision_mask = sage_saved_collision_mask
	var raw_sage = profile.get("sage", {})
	sage_config = (
		raw_sage.duplicate(true)
		if typeof(raw_sage) == TYPE_DICTIONARY
		else {}
	)
	sage_attack_serial = 0
	sage_phase_active = false
	sage_phase_remaining = 0.0
	sage_saved_collision_mask = -1
	sage_afterimage_timer = 0.0
	sage_afterimage_index = 0
	sage_post_phase_shield_timer = 0.0
	sage_gauge_redraw_timer = 0.0
	sage_phase_cooldown_timer = maxf(
		float(sage_config.get("phase_interval", 25.0)),
		0.1
	)
	var sage_skill1_value = sage_config.get("skill_1", {})
	var sage_skill1_config: Dictionary = (
		sage_skill1_value if typeof(sage_skill1_value) == TYPE_DICTIONARY else {}
	)
	sage_skill1_cooldown_timer = maxf(
		float(sage_skill1_config.get("initial_cooldown", 0.0)),
		0.0
	)
	var sage_skill2_value = sage_config.get("skill_2", {})
	var sage_skill2_config: Dictionary = (
		sage_skill2_value if typeof(sage_skill2_value) == TYPE_DICTIONARY else {}
	)
	sage_skill2_cooldown_timer = maxf(
		float(sage_skill2_config.get("initial_cooldown", 0.0)),
		0.0
	)
	var sage_skill3_value = sage_config.get("skill_3", {})
	var sage_skill3_config: Dictionary = (
		sage_skill3_value if typeof(sage_skill3_value) == TYPE_DICTIONARY else {}
	)
	sage_skill3_cooldown_timer = maxf(
		float(sage_skill3_config.get("initial_cooldown", 0.0)),
		0.0
	)
	var sage_skill4_value = sage_config.get("skill_4", {})
	var sage_skill4_config: Dictionary = (
		sage_skill4_value if typeof(sage_skill4_value) == TYPE_DICTIONARY else {}
	)
	sage_skill4_cooldown_timer = maxf(
		float(sage_skill4_config.get("initial_cooldown", 0.0)),
		0.0
	)
	var sage_skill5_value = sage_config.get("skill_5", {})
	var sage_skill5_config: Dictionary = (
		sage_skill5_value if typeof(sage_skill5_value) == TYPE_DICTIONARY else {}
	)
	sage_skill5_cooldown_timer = maxf(
		float(sage_skill5_config.get("initial_cooldown", 0.0)),
		0.0
	)
	sage_radiance_launch_remaining = 0
	sage_radiance_launch_timer = 0.0
	sage_radiance_target_cursor = 0
	sage_condensation_stacks = 0
	sage_condensation_completion_count = 0
	sage_condensation_skill_damage_buff_timer = 0.0
	sage_condensation_unlock_pending = false
	sage_condensation_unlock_effect_timer = 0.0
	sage_starlight_remaining = 0.0
	sage_starlight_volley_timer = 0.0
	_reset_sage_condensation_slots()
	_set_sage_starlight_aura_active(false)
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
	status_overlay = Node2D.new()
	status_overlay.name = "CombatStatusOverlay"
	status_overlay.z_as_relative = false
	status_overlay.z_index = 100
	add_child(status_overlay)
	status_overlay.draw.connect(_draw_combat_status_overlay)
	add_to_group("hero")
	_attach_status_effect_visual("slow")
	_attach_status_effect_visual("fear")
	_attach_status_effect_visual("stun")
	_attach_status_effect_visual("poison")
	_apply_camera_limits()
	_apply_profile_visual()
	_apply_ground_shadow_profile()
	_ensure_purifier_skill_runtime()
	_ensure_sage_runtime()
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
	_prepare_contextual_damage_audio()
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

func get_combat_feet_position() -> Vector2:
	# Profile-authored shadow offset is the shared floor contact point.
	return ground_shadow.global_position if is_instance_valid(ground_shadow) else global_position

func _apply_ground_shadow_profile() -> void:
	if not is_instance_valid(ground_shadow):
		return
	if ground_shadow_config.is_empty():
		return

	var enabled := bool(ground_shadow_config.get("enabled", true))
	ground_shadow.visible = enabled
	if not enabled:
		return

	var display_size := Vector2(84.0, 28.0)
	var raw_size = ground_shadow_config.get("size", display_size)
	if typeof(raw_size) == TYPE_VECTOR2:
		display_size = raw_size

	var offset := Vector2(0.0, 43.0)
	var raw_offset = ground_shadow_config.get("offset", offset)
	if typeof(raw_offset) == TYPE_VECTOR2:
		offset = raw_offset
	else:
		offset.x = float(ground_shadow_config.get("offset_x", offset.x))
		offset.y = float(ground_shadow_config.get("offset_y", offset.y))

	var shadow_opacity := clampf(
		float(ground_shadow_config.get("opacity", 0.52)),
		0.0,
		1.0
	)
	ground_shadow.position = offset
	if ground_shadow.has_method("configure"):
		ground_shadow.call("configure", display_size, shadow_opacity)
	else:
		ground_shadow.set("display_size", display_size)
		ground_shadow.set("opacity", shadow_opacity)


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
		level_up_effect.sprite_frames == null
		or not level_up_effect.sprite_frames.has_animation("level_up")
		or level_up_effect.sprite_frames.get_frame_count("level_up") <= 0
	):
		_apply_level_up_effect_visual()

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

	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"level_up")
	elif is_instance_valid(level_up_audio):
		level_up_audio.stop()
		level_up_audio.play()


func _on_level_up_effect_animation_finished() -> void:
	level_up_effect.visible = false


func _attach_status_effect_visual(effect_type: String) -> void:
	var effect := COMBAT_STATUS_EFFECT_VISUAL.new()
	add_child(effect)
	effect.setup(self, effect_type)


func _physics_process(delta: float) -> void:
	silence_timer = maxf(silence_timer-delta,0.0)
	set_meta("silence_active", silence_timer > 0.0)
	imposed_skill_cooldown = maxf(imposed_skill_cooldown-delta,0.0)
	paralysis_timer = maxf(paralysis_timer-delta,0.0)
	if paralysis_timer <= 0.0:
		paralysis_ratio = 0.0
	var immobilized := petrify_timer > 0.0
	var anchor := global_position
	_physics_process_actions(delta)
	if immobilized and current_hp > 0 and not is_dying:
		global_position = anchor
		velocity = Vector2.ZERO
	# Covers practice adapters, forced movement and early-return skill paths.
	_clamp_to_battlefield()

func _physics_process_actions(delta: float) -> void:
	# Discard stale intent even when death/status/skill gates return early.
	action_intent.clear()
	# Drop cached targets before any archetype, skill or movement decision.
	if is_instance_valid(target) and not HERO_TARGET_POLICY.is_detectable(target):
		target = null
		retarget_timer = 0.0
	if fighter_charge_active and not HERO_TARGET_POLICY.is_detectable(fighter_charge_target):
		_finish_fighter_charge()
	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	_update_hero_hit_flash(delta)
	_update_poison(delta)
	_update_bleed(delta)
	_update_damage_poison(delta)
	burn_runtime.update(self,delta)
	set_meta("burn_active",burn_runtime.remaining > 0.0)
	_tick_petrify(delta)
	_tick_received_modifiers(delta)
	possession_immunity_timer = maxf(possession_immunity_timer - delta, 0.0)
	var charm_was_active := _tick_charm_timers(delta)
	if current_hp <= 0 or is_dying:
		velocity = Vector2.ZERO
		return
	if _tick_stun_state(delta):
		return
	if _tick_fear_state(delta):
		return
	if charm_was_active:
		_tick_charm_state(delta)
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	attack_pose_timer = maxf(attack_pose_timer - delta, 0.0)
	hit_pose_timer = maxf(hit_pose_timer - delta, 0.0)
	ultimate_flash_timer = maxf(ultimate_flash_timer - delta, 0.0)
	_update_invulnerability(delta)
	_update_ultimate(delta)
	_update_purifier_gauge(delta)
	_update_sage_runtime(delta)
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

	if purifier_gungnir_casting:
		velocity = Vector2.ZERO
		_update_stage1_pose_visual(delta)
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
	_prepare_ranged_ai_intent(delta, distance)
	HERO_ACTION_PORT.execute_ranged(self, action_intent)
	_update_stage1_pose_visual(delta)

func _execute_ai_movement(movement: Vector2) -> void:
	action_intent.prepare_movement(movement)
	HERO_ACTION_PORT.execute_movement(self, action_intent)

func _execute_ai_basic_attack(method: int, current_target: Node2D) -> void:
	action_intent.prepare_basic_attack(method)
	HERO_ACTION_PORT.execute_basic_attack(self, action_intent, current_target)

func _prepare_ranged_ai_intent(delta: float, distance: float) -> void:
	var move_direction := _choose_move_direction(target, distance)
	move_direction = _apply_heal_item_steering(move_direction, delta)
	move_direction = _apply_chest_steering(move_direction, delta)
	move_direction = _apply_magnet_item_steering(move_direction, delta)
	if hero_archetype == "archmage_elementalist":
		move_direction = _apply_archmage_boundary_steering(move_direction)
	else:
		move_direction = _apply_ranged_boundary_escape(move_direction)
	var movement_velocity := (
		move_direction
		* move_speed
		* _get_effective_move_multiplier()
		* _get_purifier_move_speed_multiplier()
	)
	action_intent.prepare_ranged(movement_velocity, distance)


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
	summoner_basic_audio.volume_db = SUMMONER_AUDIO.BASIC_DB
	summoner_basic_audio.max_polyphony = 1
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
	_execute_ai_movement(move_direction * move_speed * _get_effective_move_multiplier())

	if distance <= attack_range and attack_timer <= 0.0:
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.SUMMONER, target)

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

	_fill_monster_nodes_near(
		global_position,
		maxf(float(summoner_ai_config.get("observation_radius", 760.0)), 1.0),
		summoner_ai_query_candidates
	)
	var nearby_count := summoner_ai_query_candidates.size()
	summoner_ai_query_candidates.clear()
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return false
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
		and not summoner_basic_audio.playing
		and Time.get_ticks_msec() >= summoner_basic_audio_next_ms
	):
		summoner_basic_audio_next_ms = Time.get_ticks_msec()+SUMMONER_AUDIO.BASIC_INTERVAL_MS
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
	alchemist_philosopher_unlock_grace_timer = maxf(
		alchemist_philosopher_unlock_grace_timer - delta,
		0.0
	)
	if _update_alchemist_philosopher_unlock_sequence(delta):
		return
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
			_execute_ai_movement(recovery_direction * alchemist_move_speed * _get_effective_move_multiplier())
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
	_execute_ai_movement(move_direction * alchemist_move_speed * _get_effective_move_multiplier())

	if (
		distance <= attack_range
		and attack_timer <= 0.0
		and alchemist_throw_index >= alchemist_throw_positions.size()
	):
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.ALCHEMIST, _get_alchemist_chest_attack_target())

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

	_ensure_alchemist_philosopher_unlock_effect()
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

	# This runs every physics tick. Compact the temporary-drop list in place
	# instead of allocating and replacing a fresh Array every frame.
	for index in range(alchemist_bonus_materials.size() - 1, -1, -1):
		var material := alchemist_bonus_materials[index]
		if (
			not is_instance_valid(material)
			or material.is_queued_for_deletion()
			or not bool(material.get("active"))
		):
			alchemist_bonus_materials.remove_at(index)


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
		current_hp = mini(current_hp + _get_reduced_healing(maxi(heal_amount, 1)), max_hp)
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

	var skill_id := String(alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	if (
		alchemist_philosopher_unlock_pending
		or is_conditional_skill_unlocked(skill_id)
	):
		return

	alchemist_philosopher_unlock_pending = true
	alchemist_philosopher_unlock_timer = maxf(
		float(alchemist_philosopher_config.get(
			"unlock_effect_seconds",
			0.55
		)),
		0.1
	)
	velocity = Vector2.ZERO
	_play_alchemist_philosopher_unlock_effect()


func _update_alchemist_philosopher_unlock_sequence(delta: float) -> bool:
	if not alchemist_philosopher_unlock_pending:
		return false

	velocity = Vector2.ZERO
	alchemist_philosopher_unlock_timer = maxf(
		alchemist_philosopher_unlock_timer - delta,
		0.0
	)
	if alchemist_philosopher_unlock_timer > 0.0:
		return true

	alchemist_philosopher_unlock_pending = false
	if is_instance_valid(alchemist_philosopher_unlock_effect):
		alchemist_philosopher_unlock_effect.stop()
		alchemist_philosopher_unlock_effect.visible = false

	var required := maxi(
		int(alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var skill_id := String(alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	_unlock_conditional_skill(
		skill_id,
		String(alchemist_philosopher_config.get("name", "현자의 돌")),
		"material_count",
		alchemist_materials_collected,
		required,
		{
			"hero_id": hero_id,
			"archetype": hero_archetype,
			"source": "alchemist_material_collection",
			"cutscene_texture_path": String(
				alchemist_philosopher_config.get(
					"cutscene_texture_path",
					"res://assets/art/heroes/stage7_alchemist/cutscene/stage7_hero_cutscene.png"
				)
			),
			"cutscene_hold_seconds": float(
				alchemist_philosopher_config.get(
					"cutscene_hold_seconds",
					1.20
				)
			),
		}
	)
	# The unlock signal starts the modal cutscene synchronously. Keep a small
	# post-cutscene grace so the Stone does not auto-channel on the same frame.
	alchemist_philosopher_unlock_grace_timer = 0.18
	return true


func _ensure_alchemist_philosopher_unlock_effect() -> void:
	if is_instance_valid(alchemist_philosopher_unlock_effect):
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("unlock")
	frames.set_animation_speed(
		"unlock",
		maxf(
			float(alchemist_philosopher_config.get(
				"unlock_effect_fps",
				9.0
			)),
			1.0
		)
	)
	frames.set_animation_loop("unlock", false)

	for index in range(1, 5):
		var texture := _load_stage1_texture(
			"%s/effect7/cast_%02d.png" % [STAGE7_FRAME_DIR, index]
		)
		if texture != null:
			frames.add_frame("unlock", texture)

	if frames.get_frame_count("unlock") <= 0:
		return

	var effect := AnimatedSprite2D.new()
	effect.name = "AlchemistPhilosopherUnlockEffect"
	effect.sprite_frames = frames
	effect.animation = &"unlock"
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Same effect7 anchor correction as the Stone channel effect.
	effect.offset = Vector2(64.0, -144.0)
	effect.position = Vector2.ZERO
	effect.scale = Vector2.ONE * maxf(
		float(alchemist_philosopher_config.get(
			"unlock_effect_scale",
			0.58
		)),
		0.05
	)
	effect.z_index = 11
	effect.modulate = Color(1.0, 0.92, 0.66, 1.0)
	effect.visible = false
	add_child(effect)
	alchemist_philosopher_unlock_effect = effect


func _play_alchemist_philosopher_unlock_effect() -> void:
	_ensure_alchemist_philosopher_unlock_effect()
	if not is_instance_valid(alchemist_philosopher_unlock_effect):
		return

	alchemist_philosopher_unlock_effect.stop()
	alchemist_philosopher_unlock_effect.visible = true
	alchemist_philosopher_unlock_effect.frame = 0
	alchemist_philosopher_unlock_effect.frame_progress = 0.0
	alchemist_philosopher_unlock_effect.play(&"unlock")


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
	if silence_timer > 0.0:
		return false
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
	var skill_id := String(alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	# Philosopher's Stone is a strict collection milestone. Equivalent Exchange
	# may substitute materials for normal alchemy, but it must never synthesize
	# the 20/20 Stone progress or trigger the transformation early.
	if not test_ready:
		if alchemist_materials_collected < required_materials:
			return false
		if (
			alchemist_philosopher_unlock_pending
			or alchemist_philosopher_unlock_grace_timer > 0.0
			or not is_conditional_skill_unlocked(skill_id)
		):
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
	_fill_monster_nodes_near(
		global_position,
		sense_radius,
		alchemist_movement_query_candidates
	)
	for node in alchemist_movement_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	alchemist_movement_query_candidates.clear()

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
		* _get_effective_move_multiplier()
	)
	velocity = desired.normalized() * speed
	_move_and_slide_with_obstacle_escape()
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
	if silence_timer > 0.0:
		return
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
	var nearby_enemies := _count_monsters_near(
		global_position,
		radius,
		required_enemies
	)
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
	if silence_timer > 0.0:
		return
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


func _acquire_alchemist_mystery_vial() -> Node2D:
	for vial in alchemist_mystery_vial_pool:
		if (
			is_instance_valid(vial)
			and vial.has_method("is_available")
			and bool(vial.call("is_available"))
		):
			return vial

	var parent := get_parent()
	if not is_instance_valid(parent):
		return null
	var vial := ALCHEMIST_VIAL_SCENE.instantiate() as Node2D
	if vial == null:
		return null
	parent.add_child(vial)
	# Great-success vials keep their quieter throw mix for every reuse.
	var mystery_throw_audio := vial.get_node_or_null("ThrowAudio") as AudioStreamPlayer
	if is_instance_valid(mystery_throw_audio):
		mystery_throw_audio.volume_db = -24.0
	vial.connect(
		"landed",
		Callable(self, "_on_alchemist_mystery_vial_landed")
	)
	alchemist_mystery_vial_pool.append(vial)
	return vial


func _spawn_alchemist_mystery_vial(origin: Vector2) -> void:
	if charm_timer > 0.0:
		return
	var vial := _acquire_alchemist_mystery_vial()
	if vial == null:
		return
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
		false
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


func _acquire_alchemist_bonus_material() -> Node2D:
	for material in alchemist_bonus_material_pool:
		if is_instance_valid(material) and not bool(material.get("active")):
			return material

	var parent := get_parent()
	if not is_instance_valid(parent):
		return null
	var material := ALCHEMY_MATERIAL_SCENE.instantiate() as Node2D
	if material == null:
		return null
	parent.add_child(material)
	if material.has_method("set_temporary_reuse_enabled"):
		material.call("set_temporary_reuse_enabled", true)
	alchemist_bonus_material_pool.append(material)
	return material


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
		var material := _acquire_alchemist_bonus_material()
		if material == null:
			continue
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
		if not alchemist_bonus_materials.has(material):
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
	_fill_monster_nodes_near(
		origin,
		radius,
		alchemist_damage_query_candidates
	)

	for node in alchemist_damage_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	alchemist_damage_query_candidates.clear()


func _update_alchemist_emergency_escape(delta: float) -> bool:
	if alchemist_emergency_config.is_empty():
		alchemist_emergency_trapped_timer = 0.0
		alchemist_emergency_threats.clear()
		return false
	if alchemist_emergency_cooldown > 0.0 or alchemist_gas > 0.001:
		alchemist_emergency_trapped_timer = 0.0
		alchemist_emergency_threats.clear()
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
	_fill_monster_nodes_near(
		global_position,
		trigger_radius,
		alchemist_emergency_query_candidates
	)
	alchemist_emergency_threats.clear()
	var radius_sq := trigger_radius * trigger_radius
	for node in alchemist_emergency_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if global_position.distance_squared_to(monster.global_position) <= radius_sq:
			alchemist_emergency_threats.append(monster)
	alchemist_emergency_query_candidates.clear()

	if alchemist_emergency_threats.size() < min_enemies:
		alchemist_emergency_trapped_timer = 0.0
		return false

	var blocked_ratio := _update_alchemist_escape_direction(
		alchemist_emergency_threats,
		trigger_radius
	)
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
	_cast_alchemist_emergency_escape(
		alchemist_emergency_threats,
		alchemist_emergency_escape_direction
	)
	alchemist_emergency_threats.clear()
	return true


func _update_alchemist_escape_direction(
	threats: Array[Node2D],
	trigger_radius: float
) -> float:
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

	alchemist_emergency_escape_direction = best_direction
	return float(blocked_count) / float(SAMPLE_COUNT)


func _cast_alchemist_emergency_escape(
	threats: Array[Node2D],
	escape_direction: Vector2
) -> void:
	if silence_timer > 0.0:
		return
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
		LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
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
		vial.set("warning_radius",maxf(float(alchemist_config.get("poison_radius",275.0))*_get_alchemist_compressed_range_multiplier(),1.0))
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
	_fill_monster_nodes_near(
		origin,
		radius,
		alchemist_damage_query_candidates
	)
	for node in alchemist_damage_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if origin.distance_squared_to(monster.global_position) > radius_sq:
			continue
		_deal_alchemist_dot_damage(monster, damage)
	alchemist_damage_query_candidates.clear()


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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
	_execute_ai_movement(move_direction * move_speed * _get_effective_move_multiplier() * gunner_speed_scale)

	if _gunner_should_start_deadeye():
		_start_gunner_deadeye()
		return

	if not gunner_reloading and distance <= attack_range and attack_timer <= 0.0:
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.GUNNER, target)

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
	_play_gunner_basic_shot_audio()
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
	_play_gunner_reload_audio()
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
	_play_gunner_backstep_audio()
	gunner_backstep_cooldown = maxf(float(gunner_config.get("backstep_cooldown", 7.0)), 0.1)
	invulnerability_timer = maxf(invulnerability_timer, float(gunner_config.get("backstep_invulnerability", 0.75)))
	var escape_direction := _find_gunner_escape_direction()
	var start_position := global_position
	var distance := maxf(float(gunner_config.get("backstep_distance", 260.0)), 0.0)
	_spawn_gunner_afterimage(start_position, 0.95, 0.66, 1.12)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.25, 0.84, 0.58, 1.10)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.50, 0.72, 0.50, 1.08)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.75, 0.60, 0.44, 1.06)
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

	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var ghost: Sprite2D = null
	if parent.has_method("acquire_transient_fx"):
		ghost = parent.call(
			"acquire_transient_fx",
			"gunner_afterimage",
			"sprite"
		) as Sprite2D
	if ghost == null:
		ghost = Sprite2D.new()
		parent.add_child(ghost)

	ghost.visible = true
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

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, maxf(fade_time, 0.05))
	tween.tween_property(
		ghost,
		"scale",
		ghost.scale * 1.04,
		maxf(fade_time, 0.05)
	)
	if parent.has_method("recycle_transient_fx"):
		tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				ghost,
				"gunner_afterimage"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		tween.finished.connect(
			Callable(ghost, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)


func _find_gunner_escape_direction() -> Vector2:
	var best := Vector2.RIGHT
	var best_score := INF
	var sample_count := 32
	var dash_distance := maxf(float(gunner_config.get("backstep_distance", 260.0)), 1.0)
	var threat_radius := maxf(dash_distance + 360.0, 560.0)
	var repulsion := Vector2.ZERO
	gunner_escape_monster_positions.clear()
	_fill_monster_nodes_near(
		global_position,
		threat_radius,
		gunner_query_candidates
	)

	for node in gunner_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var monster_position := monster.global_position
		gunner_escape_monster_positions.append(monster_position)

		var offset := monster_position - global_position
		var distance := offset.length()
		if distance <= 0.001 or distance > threat_radius:
			continue
		var proximity := 1.0 - clampf(distance / threat_radius, 0.0, 1.0)
		repulsion -= offset.normalized() * (0.35 + proximity * proximity * 2.65)

	gunner_query_candidates.clear()
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

		for monster_position in gunner_escape_monster_positions:
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
	_play_gunner_cylinder_audio()
	gunner_cylinder_cooldown = maxf(float(gunner_config.get("cylinder_cooldown", 10.0)), 0.1)
	_play_gunner_cylinder_dust()
	var radius := maxf(float(gunner_config.get("cylinder_radius", 190.0)), 1.0)
	var knockback := maxf(float(gunner_config.get("cylinder_knockback", 145.0)), 0.0)
	var slow_multiplier := clampf(float(gunner_config.get("cylinder_slow_multiplier", 0.50)), 0.1, 1.0)
	var slow_duration := maxf(float(gunner_config.get("cylinder_slow_duration", 2.0)), 0.1)
	var radius_sq := radius * radius
	_fill_monster_nodes_near(
		global_position,
		radius,
		gunner_query_candidates
	)
	for node in gunner_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		var dir := global_position.direction_to(monster.global_position)
		if dir.length_squared() <= 0.0:
			dir = Vector2.RIGHT
		monster.global_position += dir.normalized() * knockback
		LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
		var damage_ratio := maxf(float(gunner_config.get("cylinder_damage_ratio", 0.0)), 0.0)
		if damage_ratio > 0.0 and monster.has_method("take_damage"):
			monster.call("take_damage", maxi(1, int(round(float(attack_damage) * damage_ratio))))
		monster.set_meta("gunner_slow_multiplier", slow_multiplier)
		monster.set_meta("gunner_slow_until", Time.get_ticks_msec() + int(slow_duration * 1000.0))
	gunner_query_candidates.clear()


func _update_gunner_deadeye_aim_analysis() -> void:
	var sample_count := maxi(
		int(gunner_config.get("deadeye_cluster_samples", 36)),
		8
	)
	var max_range := maxf(
		float(gunner_config.get("deadeye_cluster_range", 620.0)),
		1.0
	)
	var half_width := maxf(
		float(gunner_config.get("deadeye_corridor_half_width", 105.0)),
		1.0
	)
	var best_direction := (
		Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	)
	var best_score := 0.0
	var best_hits := 0
	gunner_deadeye_monster_offsets.clear()

	for node in _get_monster_nodes_cached():
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var offset := monster.global_position - global_position
		if offset.length_squared() <= max_range * max_range:
			gunner_deadeye_monster_offsets.append(offset)

	for index in range(sample_count):
		var direction := Vector2.from_angle(
			TAU * float(index) / float(sample_count)
		)
		var side := Vector2(-direction.y, direction.x)
		var score := 0.0
		var hits := 0
		for offset in gunner_deadeye_monster_offsets:
			var forward := offset.dot(direction)
			if forward <= 0.0 or forward > max_range:
				continue
			var lateral := absf(offset.dot(side))
			if lateral > half_width:
				continue
			hits += 1
			var distance_weight := (
				1.0
				- clampf(forward / max_range, 0.0, 1.0) * 0.35
			)
			var center_weight := (
				1.0
				- clampf(lateral / half_width, 0.0, 1.0) * 0.45
			)
			score += maxf(distance_weight * center_weight, 0.1)
		if score > best_score:
			best_score = score
			best_hits = hits
			best_direction = direction

	gunner_deadeye_analysis_direction = best_direction.normalized()
	gunner_deadeye_analysis_score = best_score
	gunner_deadeye_analysis_hits = best_hits


func _gunner_should_start_deadeye() -> bool:
	if silence_timer > 0.0:
		return false
	if gunner_reloading or gunner_deadeye_cooldown > 0.0:
		return false
	var min_ammo := maxi(int(gunner_config.get("deadeye_min_ammo", 3)), 1)
	if gunner_ammo < min_ammo:
		return false

	_update_gunner_deadeye_aim_analysis()
	var score := gunner_deadeye_analysis_score
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
	if silence_timer > 0.0:
		return
	if gunner_ammo <= 0:
		return
	var aim_direction := gunner_deadeye_analysis_direction
	if aim_direction.length_squared() <= 0.0:
		aim_direction = Vector2.LEFT if hero_sprite.flip_h else Vector2.RIGHT
	gunner_deadeye_cooldown = maxf(float(gunner_config.get("deadeye_cooldown", 20.0)), 0.1)
	gunner_deadeye_active = true
	_play_gunner_deadeye_start_audio()
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
	velocity = deadeye_move_direction * move_speed * _get_effective_move_multiplier() * speed_bonus
	_move_and_slide_with_obstacle_escape()
	_clamp_to_battlefield()
	gunner_deadeye_shot_timer = maxf(gunner_deadeye_shot_timer - delta, 0.0)
	if gunner_deadeye_shot_timer <= 0.0 and gunner_deadeye_shots_left > 0:
		_play_gunner_deadeye_shot_audio()
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
		if not HERO_TARGET_POLICY.is_detectable(node):
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
		rogue_slash_cooldown_timer - delta * get_paralysis_attack_multiplier(),
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
		_execute_ai_movement(
			move_direction
			* move_speed
			* _get_effective_move_multiplier()
			* speed_scale
		)
	else:
		velocity = Vector2.ZERO

	if (
		not rogue_slash_active
		and distance <= attack_range
		and attack_timer <= 0.0
	):
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.ROGUE_COMBO, target)

	_update_rogue_pose_visual(delta)

func _rogue_compare_registration_order(a: Node, b: Node) -> bool:
	return int(a.get_meta("query_registration_order", a.get_instance_id())) < int(b.get_meta("query_registration_order", b.get_instance_id()))


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

	var corridor_bounds := Rect2(lunge_start, Vector2.ZERO).expand(corridor_end).grow(aoe_radius)
	var battle := get_parent()
	if is_instance_valid(battle) and battle.has_method("fill_local_monsters_in_rect"):
		battle.call("fill_local_monsters_in_rect", corridor_bounds, rogue_combo_candidates)
		HERO_TARGET_POLICY.filter_detectable(rogue_combo_candidates)
	else:
		_fill_monster_nodes_in_rect(corridor_bounds, rogue_combo_candidates)
	rogue_combo_candidates.sort_custom(_rogue_compare_registration_order)
	for node in rogue_combo_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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

	rogue_combo_candidates.clear()
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
	_play_rogue_combo_audio(rogue_combo_index)

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
	LOCAL_GRID_MOVEMENT.notify_forced_position_change(current_target)

func _rogue_should_use_slash() -> bool:
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return
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

	_play_rogue_blade_storm_audio()
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
	var radius_sq := radius * radius
	_fill_monster_nodes_near(
		global_position,
		radius,
		rogue_query_candidates
	)

	for node in rogue_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		if monster.has_method("take_damage"):
			_rogue_damage_target(
				monster,
				damage,
				0.50
			)
	rogue_query_candidates.clear()

	if shield_effect.sprite_frames != null:
		shield_effect.visible = true
		shield_effect.stop()
		shield_effect.animation = &"slash"
		shield_effect.frame = 0
		shield_effect.play(&"slash")

func _rogue_can_start_assassination() -> bool:
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return
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
	_play_rogue_assassination_start_audio()
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
	var assassination_aoe_radius_sq := (
		assassination_aoe_radius * assassination_aoe_radius
	)
	_fill_monster_nodes_near(
		current_target.global_position,
		assassination_aoe_radius,
		rogue_query_candidates
	)

	for node in rogue_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if monster.get_instance_id() == main_target_id:
			continue
		if (
			current_target.global_position.distance_squared_to(
				monster.global_position
			)
			> assassination_aoe_radius_sq
		):
			continue

		_rogue_damage_target(
			monster,
			secondary_damage,
			secondary_lifesteal
		)
	rogue_query_candidates.clear()

	attack_pose_timer = 0.20
	_restart_stage1_animation("attack", 1.35)
	_play_rogue_effect(
		channel_effect,
		"assassinate",
		-approach_direction
	)
	_play_rogue_assassination_hit_audio()

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
	var radius_sq := radius * radius
	_fill_monster_nodes_near(
		global_position,
		radius,
		rogue_query_candidates
	)

	for node in rogue_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > radius_sq:
			continue
		var distance := sqrt(distance_sq)

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

	rogue_query_candidates.clear()
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

	if hero_archetype == "grand_sage_astra":
		var sage_dir := sprite_frame_dir if not sprite_frame_dir.is_empty() else STAGE10_FRAME_DIR
		var sage_frames := SpriteFrames.new()
		if sage_frames.has_animation("default"):
			sage_frames.remove_animation("default")
		if not _add_named_sequence_animation(sage_frames, "idle", sage_dir, "idle", 4, 5.5, true):
			return
		_add_named_sequence_animation(sage_frames, "move", sage_dir, "walk", 6, 8.0, true)
		_add_named_sequence_animation(sage_frames, "attack", sage_dir, "atk", 6, 10.0, false)
		_add_named_sequence_animation(sage_frames, "hit", sage_dir, "hit", 3, 12.0, false)
		_add_named_sequence_animation(sage_frames, "death", sage_dir, "dead", 4, 8.0, false)
		hero_sprite.sprite_frames = sage_frames
		hero_sprite.visible = true
		_apply_normalized_hero_visual_scale()
		hero_sprite.speed_scale = 1.0
		hero_sprite.play("idle")
		return

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

	if not _add_named_sequence_animation(
		rogue_frames, "idle", frame_dir, "idle", 4, 6.0, true
	):
		return
	_add_named_sequence_animation(
		rogue_frames, "move", frame_dir, "walk", 6, 11.0, true
	)
	_add_named_sequence_animation(
		rogue_frames, "attack", frame_dir, "attack", 6, 18.0, false
	)
	_add_named_sequence_animation(
		rogue_frames, "hit", frame_dir, "hit", 3, 14.0, false
	)
	_add_named_sequence_animation(
		rogue_frames, "death", frame_dir, "dead", 4, 10.0, false
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

func _load_stage1_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var prepared := PresentationWarmup.get_texture(path)
	if prepared != null:
		return prepared

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
			# Looping dash poses are held by skill state, not playback forever.
			return (
				berserker_skill3_active
				or fighter_charge_active
				or (
					not hero_sprite.sprite_frames.get_animation_loop(current_animation)
					and hero_sprite.is_playing()
				)
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
		hero_id not in ["ranged_rookie", "archmage_hero", "purifier_hero", "sage_astra"]
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


func set_camera_view_locked(locked: bool) -> void:
	if not is_instance_valid(follow_camera):
		return

	if locked:
		follow_camera.top_level = false
		follow_camera.position = Vector2.ZERO
	else:
		var current_center := follow_camera.global_position if not follow_camera.top_level else follow_camera.get_screen_center_position()
		follow_camera.top_level = true
		follow_camera.global_position = _clamp_manual_camera_center(
			current_center
		)
	follow_camera.force_update_scroll()


func center_camera_on_hero() -> void:
	if not is_instance_valid(follow_camera):
		return
	if follow_camera.top_level:
		follow_camera.global_position = _clamp_manual_camera_center(global_position)
	else:
		follow_camera.position = Vector2.ZERO
	follow_camera.force_update_scroll()

func pan_camera_by_screen_delta(screen_delta: Vector2) -> void:
	if (
		not is_instance_valid(follow_camera)
		or not follow_camera.top_level
		or screen_delta.length_squared() <= 0.001
	):
		return

	var zoom := follow_camera.zoom
	var world_delta := Vector2(
		screen_delta.x / maxf(absf(zoom.x), 0.01),
		screen_delta.y / maxf(absf(zoom.y), 0.01)
	)
	follow_camera.global_position = _clamp_manual_camera_center(
		follow_camera.global_position - world_delta
	)
	follow_camera.force_update_scroll()


func _clamp_manual_camera_center(center: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var zoom := follow_camera.zoom
	var half_view := Vector2(
		viewport_size.x * 0.5 / maxf(absf(zoom.x), 0.01),
		viewport_size.y * 0.5 / maxf(absf(zoom.y), 0.01)
	)
	var min_x := float(follow_camera.limit_left) + half_view.x
	var max_x := float(follow_camera.limit_right) - half_view.x
	var min_y := float(follow_camera.limit_top) + half_view.y
	var max_y := float(follow_camera.limit_bottom) - half_view.y

	if min_x > max_x:
		center.x = (
			float(follow_camera.limit_left + follow_camera.limit_right) * 0.5
		)
	else:
		center.x = clampf(center.x, min_x, max_x)

	if min_y > max_y:
		center.y = (
			float(follow_camera.limit_top + follow_camera.limit_bottom) * 0.5
		)
	else:
		center.y = clampf(center.y, min_y, max_y)
	return center

func _move_without_monsters() -> void:
	var current_move_speed := move_speed * _get_purifier_move_speed_multiplier()
	if hero_archetype == "alchemist_chemical":
		current_move_speed *= _get_alchemist_field_speed_multiplier()

	if is_instance_valid(heal_item_target):
		var heal_direction := _apply_heal_item_steering(Vector2.ZERO, 0.016)
		if heal_direction.length_squared() > 0.01:
			heal_direction = _apply_ranged_boundary_escape(heal_direction)
			_execute_ai_movement(heal_direction * current_move_speed * 0.90 * _get_effective_move_multiplier())
			return

	if is_instance_valid(magnet_item_target):
		var magnet_direction := _apply_magnet_item_steering(
			Vector2.ZERO,
			0.016
		)
		if magnet_direction.length_squared() > 0.01:
			magnet_direction = _apply_ranged_boundary_escape(magnet_direction)
			_execute_ai_movement(
				magnet_direction
				* current_move_speed
				* 0.82
				* _get_effective_move_multiplier()
			)
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
					_execute_ai_movement(chest_direction * current_move_speed * 0.72 * _get_effective_move_multiplier())
			else:
				velocity = Vector2.ZERO
				if (
					attack_timer <= 0.0
					and alchemist_throw_index >= alchemist_throw_positions.size()
				):
					_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.ALCHEMIST, chest_target)
			return

		var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			chest_direction = _apply_ranged_boundary_escape(chest_direction)
			_execute_ai_movement(chest_direction * current_move_speed * 0.72 * _get_effective_move_multiplier())
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
		_execute_ai_movement(exp_direction * current_move_speed * 0.90 * _get_effective_move_multiplier())
		return

	if (
		wander_timer <= 0.0
		or position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE * WANDER_REACHED_DISTANCE
	):
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	direction = _apply_ranged_boundary_escape(direction)
	_execute_ai_movement(direction * current_move_speed * 0.72 * _get_effective_move_multiplier())

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
	_update_ranged_pressure_cache(delta)
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
		if _has_ranged_pressure():
			combat_strafe_burst_timer = randf_range(0.55, 0.90)
			combat_strafe_cooldown_timer = randf_range(0.16, 0.34)
		else:
			combat_strafe_burst_timer = randf_range(0.22, 0.38)
			combat_strafe_cooldown_timer = randf_range(0.75, 1.30)


func _update_ranged_pressure_cache(delta: float) -> void:
	ranged_pressure_refresh_timer = maxf(
		ranged_pressure_refresh_timer - delta,
		0.0
	)
	if ranged_pressure_refresh_timer > 0.0:
		return

	ranged_pressure_refresh_timer = RANGED_PRESSURE_REFRESH_SECONDS
	ranged_pressure_count = 0
	ranged_pressure_center = Vector2.ZERO

	if not _is_ranged_ai_archetype():
		return

	_fill_monster_nodes_near(
		global_position,
		RANGED_PRESSURE_RADIUS,
		_combat_monster_scratch
	)
	for node in _combat_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var current_hp_value = monster.get("current_hp")
		if current_hp_value != null and int(current_hp_value) <= 0:
			continue
		if String(monster.get("monster_role")) != "ranged":
			continue
		# Spatial queries return broad-phase buckets; apply the sensing radius.
		if global_position.distance_squared_to(monster.global_position) > RANGED_PRESSURE_RADIUS * RANGED_PRESSURE_RADIUS:
			continue
		ranged_pressure_count += 1
		ranged_pressure_center += monster.global_position

	if ranged_pressure_count > 0:
		ranged_pressure_center /= float(ranged_pressure_count)
	_combat_monster_scratch.clear()


func _has_ranged_pressure() -> bool:
	return (
		_is_ranged_ai_archetype()
		and ranged_pressure_count >= RANGED_PRESSURE_TRIGGER_COUNT
	)


func _get_ranged_pressure_strafe_direction() -> Vector2:
	if not _has_ranged_pressure():
		return Vector2.ZERO

	var away := ranged_pressure_center.direction_to(global_position)
	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT

	var tangent := Vector2(-away.y, away.x) * strafe_sign
	var overload := clampf(
		float(ranged_pressure_count - RANGED_PRESSURE_TRIGGER_COUNT) / 6.0,
		0.0,
		1.0
	)
	var desired := (
		tangent * lerpf(0.92, 1.05, overload)
		+ away * lerpf(0.28, 0.44, overload)
	)
	return (
		desired.normalized()
		if desired.length_squared() > 0.001
		else tangent.normalized()
	)


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
		if not HERO_TARGET_POLICY.is_detectable(node):
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

	# A stationary turret will never close the range itself. Pressure strafing
	# must not keep us outside our own firing range indefinitely.
	if is_instance_valid(nearest_target) and nearest_distance > attack_range:
		var target_speed = nearest_target.get("move_speed")
		if target_speed != null and float(target_speed) <= 0.0:
			return global_position.direction_to(nearest_target.global_position)

	var pressure_direction := _get_ranged_pressure_strafe_direction()
	if pressure_direction.length_squared() > 0.01:
		return pressure_direction

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
		"ranged_kiter", "pistol_gunner", "archmage_elementalist", "alchemist_chemical", "summoner_gatekeeper", "cleric_purifier", "grand_sage_astra":
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


func _move_and_slide_with_obstacle_escape() -> void:
	if petrify_timer > 0.0:
		velocity = Vector2.ZERO
		return
	var intended_velocity := velocity
	var intended_speed := intended_velocity.length()
	var delta := maxf(float(get_physics_process_delta_time()), 0.001)

	obstacle_escape_timer = maxf(
		obstacle_escape_timer - delta,
		0.0
	)
	if (
		obstacle_escape_timer > 0.0
		and intended_speed >= OBSTACLE_MIN_INTENDED_SPEED
		and obstacle_escape_direction.length_squared() > 0.01
	):
		# Keep most of the temporary tangent escape, but retain some of the
		# original AI intent so the detour naturally bends back toward its goal.
		var intended_direction := intended_velocity / intended_speed
		var blended_direction := (
			obstacle_escape_direction * 0.88
			+ intended_direction * 0.32
		)
		if blended_direction.length_squared() > 0.01:
			velocity = blended_direction.normalized() * intended_speed

	var movement_start := global_position
	move_and_slide()
	var moved_distance := global_position.distance_to(movement_start)

	if intended_speed < OBSTACLE_MIN_INTENDED_SPEED:
		obstacle_stuck_timer = 0.0
		return

	var intended_direction := intended_velocity / intended_speed
	var decor_normal := _get_blocking_decor_normal(
		intended_direction
	)
	if decor_normal.length_squared() <= 0.01:
		obstacle_stuck_timer = 0.0
		return

	var expected_distance := intended_speed * delta
	var minimum_progress := maxf(
		expected_distance * OBSTACLE_STUCK_PROGRESS_RATIO,
		1.25
	)
	if moved_distance > minimum_progress:
		obstacle_stuck_timer = 0.0
		return

	obstacle_stuck_timer += delta
	if obstacle_stuck_timer < OBSTACLE_STUCK_TRIGGER_SECONDS:
		return

	_start_obstacle_escape(decor_normal, intended_direction)
	obstacle_stuck_timer = 0.0


func _get_blocking_decor_normal(
	intended_direction: Vector2
) -> Vector2:
	var best_normal := Vector2.ZERO
	var best_block_score := 0.0
	var collision_count := get_slide_collision_count()
	for collision_index in range(collision_count):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider := collision.get_collider() as CollisionObject2D
		if collider == null:
			continue
		if (
			int(collider.collision_layer)
			& HERO_DECOR_COLLISION_LAYER
		) == 0:
			continue

		var normal := collision.get_normal()
		if normal.length_squared() <= 0.01:
			continue
		normal = normal.normalized()
		var block_score := maxf(
			-intended_direction.dot(normal),
			0.0
		)
		if block_score > best_block_score:
			best_block_score = block_score
			best_normal = normal

	return best_normal


func _start_obstacle_escape(
	blocking_normal: Vector2,
	intended_direction: Vector2
) -> void:
	var safe_normal := blocking_normal.normalized()
	if safe_normal.length_squared() <= 0.01:
		return

	var tangent := Vector2(-safe_normal.y, safe_normal.x)
	var center_direction := global_position.direction_to(
		battlefield_size * 0.5
	)
	var candidate_a := (
		tangent * 0.88
		+ safe_normal * 0.48
		+ intended_direction * 0.18
	).normalized()
	var candidate_b := (
		-tangent * 0.88
		+ safe_normal * 0.48
		+ intended_direction * 0.18
	).normalized()

	# Prefer the side that does not drag the hero toward the outer map edge.
	# If both are similarly good, alternate sides between stuck incidents so a
	# concave prop/corner cannot trap the AI in the same failed choice forever.
	var score_a := candidate_a.dot(center_direction) * 0.72
	var score_b := candidate_b.dot(center_direction) * 0.72
	score_a += candidate_a.dot(intended_direction) * 0.28
	score_b += candidate_b.dot(intended_direction) * 0.28

	if absf(score_a - score_b) <= 0.08:
		obstacle_escape_direction = (
			candidate_a
			if obstacle_escape_side >= 0.0
			else candidate_b
		)
		obstacle_escape_side *= -1.0
	elif score_a > score_b:
		obstacle_escape_direction = candidate_a
	else:
		obstacle_escape_direction = candidate_b

	obstacle_escape_timer = OBSTACLE_ESCAPE_SECONDS
	# Also break the current combat strafe choice. Otherwise a ranged hero can
	# immediately request the exact same blocked lateral direction again.
	strafe_sign *= -1.0
	combat_strafe_burst_timer = 0.0
	combat_strafe_cooldown_timer = minf(
		combat_strafe_cooldown_timer,
		0.16
	)


func _get_battlefield_movement_bounds() -> Rect2:
	var minimum := Vector2.ONE * FIELD_MARGIN
	var battle := get_parent()
	if is_instance_valid(battle) and battle.get("y_sort_enabled") == true:
		var field := battle.get_node_or_null("Stage1Battlefield")
		if field != null:
			collision_mask |= SAGE_PHASE_BOUNDARY_COLLISION_MASK
			minimum.y = field.TOP_WALL_COLLISION_BOTTOM + field.TOP_WALL_COLLISION_HEIGHT * 0.5 + FIELD_MARGIN
	return Rect2(minimum, battlefield_size - Vector2.ONE * FIELD_MARGIN - minimum)


func _clamp_to_battlefield() -> void:
	if petrify_timer > 0.0:
		global_position = petrify_anchor
		velocity = Vector2.ZERO
	var minimum := _get_battlefield_movement_bounds().position
	var clamped_position := position
	var hit_edge := false

	if clamped_position.x < minimum.x or clamped_position.x > battlefield_size.x - FIELD_MARGIN:
		hit_edge = true
	if clamped_position.y < minimum.y or clamped_position.y > battlefield_size.y - FIELD_MARGIN:
		hit_edge = true

	clamped_position.x = clampf(clamped_position.x, minimum.x, battlefield_size.x - FIELD_MARGIN)
	clamped_position.y = clampf(clamped_position.y, minimum.y, battlefield_size.y - FIELD_MARGIN)
	position = clamped_position
	if petrify_timer > 0.0:
		petrify_anchor = global_position

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
	_fill_monster_nodes_near(
		at_position,
		safe_radius,
		_movement_monster_scratch
	)
	for node in _movement_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := at_position.distance_squared_to(monster.global_position)
		if distance_sq >= safe_radius_sq:
			continue
		var distance := sqrt(distance_sq)
		danger += 1.0 - clampf(distance / safe_radius, 0.0, 1.0)
	_movement_monster_scratch.clear()
	return danger

func _get_crowd_avoidance_direction(radius: float = 230.0) -> Vector2:
	var avoidance := Vector2.ZERO
	var safe_radius := maxf(radius, 1.0)
	var safe_radius_sq := safe_radius * safe_radius
	_fill_monster_nodes_near(
		global_position,
		safe_radius,
		_movement_monster_scratch
	)
	for node in _movement_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	_movement_monster_scratch.clear()
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
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("get_nearest_hostile_target_for_hero")
	):
		var registered_target = battle.call(
			"get_nearest_hostile_target_for_hero",
			global_position
		)
		if registered_target is Node2D:
			return registered_target as Node2D

	# Compatibility fallback for isolated scenes/tests without Battle.
	var nearest: Node2D = null
	var nearest_distance := INF
	for group_name in ["monsters", "treasure_chests"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not HERO_TARGET_POLICY.is_detectable(node):
				continue
			var combat_target := node as Node2D
			if combat_target == null:
				continue
			var hp_value = combat_target.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			var distance := global_position.distance_squared_to(
				combat_target.global_position
			)
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
	if hero_archetype == "grand_sage_astra":
		_fire_sage_projectile(current_target)
		return

	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.34
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")
	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"basic")
	if hero_archetype == "cleric_purifier":
		_play_purifier_basic_audio()

	var projectile_count := 1 + clampi(projectile_count_bonus, 0, 4)
	var volley := PROJECTILE_VOLLEY.new() if projectile_count > 1 else null
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
			projectile_splash_damage_ratio,
			volley
		)

	_add_ultimate_charge(
		float(ultimate_config.get("charge_on_attack", 0.0))
	)


func _get_sage_augment_stacks(augment_id: String) -> int:
	if hero_archetype != "grand_sage_astra":
		return 0
	return maxi(int(build_counts.get(augment_id, 0)), 0)


func _consume_one_sage_condensation_stack() -> bool:
	if sage_condensation_stacks <= 0:
		return false
	sage_condensation_stacks -= 1
	for slot_index in range(sage_condensation_visuals.size()):
		if slot_index in sage_condensation_free_slots:
			continue
		var sprite := sage_condensation_visuals[slot_index]
		if is_instance_valid(sprite):
			sprite.stop()
			sprite.visible = false
		sage_condensation_free_slots.append(slot_index)
		break
	queue_redraw()
	return true


func _apply_sage_mana_conversion(incoming_damage: float) -> float:
	var augment_stacks := _get_sage_augment_stacks("sage_mana_conversion")
	if augment_stacks <= 0 or sage_condensation_stacks <= 0:
		return incoming_damage
	var projected_hp := maxf(float(current_hp) - incoming_damage, 0.0)
	if projected_hp / float(maxi(max_hp, 1)) > 0.50:
		return incoming_damage
	var absorbed := minf(
		incoming_damage,
		float(max_hp) * 0.03 * float(augment_stacks)
	)
	if absorbed <= 0.0 or not _consume_one_sage_condensation_stack():
		return incoming_damage
	return maxf(incoming_damage - absorbed, 0.0)


func _ensure_sage_runtime() -> void:
	if hero_archetype != "grand_sage_astra":
		return
	if not is_instance_valid(sage_basic_audio):
		sage_basic_audio = _create_sage_audio_player(SAGE_BASIC_ATTACK_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 1.08)
	if not is_instance_valid(sage_third_audio):
		sage_third_audio = _create_sage_audio_player(SAGE_THIRD_ATTACK_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 0.92)
	if not is_instance_valid(sage_phase_audio):
		sage_phase_audio = _create_sage_audio_player(SAGE_PHASE_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 1.02)
	if not is_instance_valid(sage_ice_pillar_audio):
		sage_ice_pillar_audio = _create_sage_audio_player(SAGE_ICE_PILLAR_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 0.90)
	if not is_instance_valid(sage_radiance_create_audio):
		sage_radiance_create_audio = _create_sage_audio_player(SAGE_RADIANCE_CREATE_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 1.04)
	if not is_instance_valid(sage_condensation_stack_audio):
		sage_condensation_stack_audio = _create_sage_audio_player(SAGE_CONDENSATION_STACK_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 1.18)
	if not is_instance_valid(sage_condensation_release_audio):
		sage_condensation_release_audio = _create_sage_audio_player(SAGE_CONDENSATION_RELEASE_AUDIO_PATH, SAGE_SFX_REFERENCE_DB, 0.96)
	_ensure_sage_condensation_visuals()
	_ensure_sage_starlight_aura()
	if not sage_afterimage_pool.is_empty():
		return
	if _sage_afterimage_frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"trail")
		frames.set_animation_loop(&"trail", false)
		frames.set_animation_speed(&"trail", 18.0)
		for frame_index in range(1, 8):
			var texture := _load_stage1_texture("%s/effect6/dash_%02d.png" % [STAGE10_FRAME_DIR, frame_index])
			if texture != null:
				frames.add_frame(&"trail", texture)
		_sage_afterimage_frames_cache = frames
	if _sage_afterimage_frames_cache.get_frame_count(&"trail") <= 0:
		return
	var pool_size := clampi(int(sage_config.get("afterimage_pool_size", 12)), 4, 20)
	for index in range(pool_size):
		var ghost := AnimatedSprite2D.new()
		ghost.name = "SageAfterimage%02d" % index
		ghost.sprite_frames = _sage_afterimage_frames_cache
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.top_level = true
		# Keep Astra's phase trail strictly behind the hero body. Using both a
		# lower Z and show_behind_parent avoids the trail covering the sprite
		# even when the battle root uses Y-sorting.
		ghost.z_index = -1
		ghost.show_behind_parent = true
		ghost.visible = false
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.58)
		ghost.animation_finished.connect(Callable(self, "_on_sage_afterimage_finished").bind(ghost))
		add_child(ghost)
		sage_afterimage_pool.append(ghost)


func _ensure_sage_condensation_visuals() -> void:
	if not sage_condensation_visuals.is_empty():
		return

	if _sage_condensation_frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"summon")
		frames.set_animation_loop(&"summon", false)
		frames.set_animation_speed(&"summon", 12.0)
		for frame_index in range(1, 9):
			var texture := _load_stage1_texture(
				"%s/effect4/summon_%02d.png"
				% [STAGE10_FRAME_DIR, frame_index]
			)
			if texture != null:
				frames.add_frame(&"summon", texture)
		_sage_condensation_frames_cache = frames

	if _sage_condensation_frames_cache.get_frame_count(&"summon") <= 0:
		return

	var skill_value = sage_config.get("skill_3", {})
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var radius := maxf(float(skill.get("visual_radius", 82.0)), 20.0)
	var visual_scale := maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	for index in range(SAGE_CONDENSATION_SLOT_ANGLES.size()):
		var sprite := AnimatedSprite2D.new()
		sprite.name = "SageCondensation%02d" % index
		sprite.sprite_frames = _sage_condensation_frames_cache
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2.from_angle(
			deg_to_rad(SAGE_CONDENSATION_SLOT_ANGLES[index])
		) * radius
		sprite.scale = Vector2.ONE * visual_scale
		# Health/shield/resource bars are drawn by the Hero parent itself.
		# Keep condensation visuals behind the parent draw so the orbiting
		# effect can never cover Astra's HP, shield, or yellow gauge bars.
		sprite.z_index = 0
		sprite.show_behind_parent = true
		sprite.visible = false
		add_child(sprite)
		sage_condensation_visuals.append(sprite)


func _reset_sage_condensation_slots() -> void:
	sage_condensation_free_slots.clear()
	for index in range(8):
		sage_condensation_free_slots.append(index)
	for sprite in sage_condensation_visuals:
		if is_instance_valid(sprite):
			sprite.stop()
			sprite.visible = false
			sprite.modulate = Color.WHITE


func _ensure_sage_starlight_aura() -> void:
	if is_instance_valid(sage_starlight_aura):
		return

	var texture := _load_stage1_texture(
		"%s/effect7/stage10_effect2_01.png" % STAGE10_FRAME_DIR
	)
	if texture == null:
		return

	var raw_skill = sage_config.get("skill_4", {})
	var skill: Dictionary = (
		raw_skill if typeof(raw_skill) == TYPE_DICTIONARY else {}
	)
	var sprite := Sprite2D.new()
	sprite.name = "SageStarlightAura"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * maxf(
		float(skill.get("aura_visual_scale", 0.70)),
		0.05
	)
	sprite.show_behind_parent = true
	sprite.z_index = -1
	sprite.visible = false
	add_child(sprite)
	sage_starlight_aura = sprite


func _set_sage_starlight_aura_active(active: bool) -> void:
	if active:
		_ensure_sage_starlight_aura()
	if is_instance_valid(sage_starlight_aura):
		sage_starlight_aura.visible = active


func _create_stage1_audio_player(
	audio_path: String,
	volume_db: float,
	pitch_scale: float
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


func _ensure_stage1_audio_runtime() -> void:
	if hero_archetype != "ranged_kiter":
		return
	if not is_instance_valid(stage1_basic_audio):
		stage1_basic_audio = _create_stage1_audio_player(
			STAGE1_BASIC_ATTACK_AUDIO_PATH, HERO_SFX_DB_PRIMARY_ATTACK, 1.35
		)
	if not is_instance_valid(stage1_barrier_audio):
		stage1_barrier_audio = _create_stage1_audio_player(
			STAGE1_BARRIER_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL, 1.08
		)
	if not is_instance_valid(stage1_arcane_field_audio):
		stage1_arcane_field_audio = _create_stage1_audio_player(
			STAGE1_ARCANE_FIELD_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL, 0.96
		)
	if not is_instance_valid(stage1_arcane_piercer_audio):
		stage1_arcane_piercer_audio = _create_stage1_audio_player(
			STAGE1_ARCANE_PIERCER_AUDIO_PATH, HERO_SFX_DB_HEAVY_SKILL, 1.08
		)
	if not is_instance_valid(stage1_hit_audio):
		stage1_hit_audio = _create_stage1_audio_player(
			STAGE1_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)
	if not is_instance_valid(stage1_death_audio):
		stage1_death_audio = _create_stage1_audio_player(
			STAGE1_DEATH_AUDIO_PATH, HERO_SFX_DB_DEATH, 0.72
		)
	if not is_instance_valid(stage1_level_up_audio):
		stage1_level_up_audio = _create_stage1_audio_player(
			STAGE1_LEVEL_UP_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL, 1.0
		)


func _play_stage1_audio(slot: StringName) -> void:
	_ensure_stage1_audio_runtime()
	var player: AudioStreamPlayer = null
	match slot:
		&"basic":
			player = stage1_basic_audio
		&"barrier":
			player = stage1_barrier_audio
		&"arcane_field":
			player = stage1_arcane_field_audio
		&"arcane_piercer":
			player = stage1_arcane_piercer_audio
		&"hit":
			player = stage1_hit_audio
		&"death":
			player = stage1_death_audio
		&"level_up":
			player = stage1_level_up_audio
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _create_hero_sfx_player(
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


func _ensure_rogue_audio_runtime() -> void:
	if hero_archetype != "rogue_combo":
		return

	if rogue_combo_audio_pool.is_empty():
		for index in range(3):
			rogue_combo_audio_pool.append(
				_create_hero_sfx_player(
					STAGE2_COMBO_SLASH_AUDIO_PATH,
					HERO_SFX_DB_PRIMARY_ATTACK - 10.0,
					1.0
				)
			)

	if not is_instance_valid(rogue_blade_storm_audio):
		rogue_blade_storm_audio = _create_hero_sfx_player(
			STAGE2_BLADE_STORM_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL,
			1.0
		)

	if not is_instance_valid(rogue_assassination_start_audio):
		rogue_assassination_start_audio = _create_hero_sfx_player(
			STAGE2_ASSASSINATION_START_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL,
			0.82
		)

	if rogue_assassination_hit_audio_pool.is_empty():
		for index in range(3):
			rogue_assassination_hit_audio_pool.append(
				_create_hero_sfx_player(
					STAGE2_ASSASSINATION_HIT_AUDIO_PATH,
					HERO_SFX_DB_HIT - 3.0,
					1.0
				)
			)

	if not is_instance_valid(rogue_hit_audio):
		rogue_hit_audio = _create_hero_sfx_player(
			STAGE2_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(rogue_death_audio):
		rogue_death_audio = _create_hero_sfx_player(
			STAGE2_DEATH_AUDIO_PATH,
			HERO_SFX_DB_DEATH,
			0.96
		)


func _play_rogue_combo_audio(_combo_index: int) -> void:
	if Time.get_ticks_msec() < rogue_combo_audio_next_ms:
		return
	_ensure_rogue_audio_runtime()
	if rogue_combo_audio_pool.is_empty():
		return
	var player := rogue_combo_audio_pool[
		rogue_combo_audio_cursor % rogue_combo_audio_pool.size()
	]
	rogue_combo_audio_cursor = (
		rogue_combo_audio_cursor + 1
	) % rogue_combo_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	rogue_combo_audio_next_ms = Time.get_ticks_msec()+CONTEXT_AUDIO.ROGUE_ATTACK_INTERVAL_MS
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_rogue_blade_storm_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(rogue_blade_storm_audio) and rogue_blade_storm_audio.stream != null:
		rogue_blade_storm_audio.stop()
		rogue_blade_storm_audio.play()


func _play_rogue_assassination_start_audio() -> void:
	_ensure_rogue_audio_runtime()
	if (
		is_instance_valid(rogue_assassination_start_audio)
		and rogue_assassination_start_audio.stream != null
	):
		rogue_assassination_start_audio.stop()
		rogue_assassination_start_audio.play()


func _play_rogue_assassination_hit_audio() -> void:
	if Time.get_ticks_msec() < rogue_assassination_audio_next_ms:
		return
	_ensure_rogue_audio_runtime()
	if rogue_assassination_hit_audio_pool.is_empty():
		return
	var player := rogue_assassination_hit_audio_pool[
		rogue_assassination_hit_audio_cursor
		% rogue_assassination_hit_audio_pool.size()
	]
	rogue_assassination_hit_audio_cursor = (
		rogue_assassination_hit_audio_cursor + 1
	) % rogue_assassination_hit_audio_pool.size()
	rogue_assassination_audio_next_ms = Time.get_ticks_msec()+CONTEXT_AUDIO.ROGUE_ASSASSINATION_INTERVAL_MS
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_rogue_hit_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(rogue_hit_audio) and rogue_hit_audio.stream != null:
		rogue_hit_audio.stop()
		rogue_hit_audio.play()


func _play_rogue_death_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(rogue_death_audio) and rogue_death_audio.stream != null:
		rogue_death_audio.stop()
		rogue_death_audio.play()


func _ensure_fighter_audio_runtime() -> void:
	if hero_archetype != "sword_shield":
		return

	if fighter_slash_audio_pool.is_empty():
		for index in range(3):
			fighter_slash_audio_pool.append(
				_create_hero_sfx_player(
					STAGE3_SLASH_AUDIO_PATH,
					HERO_SFX_DB_PRIMARY_ATTACK - 3.0,
					0.96
				)
			)

	if fighter_thrust_audio_pool.is_empty():
		for index in range(3):
			fighter_thrust_audio_pool.append(
				_create_hero_sfx_player(
					STAGE3_THRUST_AUDIO_PATH,
					HERO_SFX_DB_PRIMARY_ATTACK - 2.0,
					1.08
				)
			)

	if not is_instance_valid(fighter_guard_start_audio):
		fighter_guard_start_audio = _create_hero_sfx_player(
			STAGE3_GUARD_START_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.72
		)

	if not is_instance_valid(fighter_guard_release_audio):
		fighter_guard_release_audio = _create_hero_sfx_player(
			STAGE3_GUARD_RELEASE_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.76
		)

	if fighter_charge_impact_audio_pool.is_empty():
		for index in range(3):
			fighter_charge_impact_audio_pool.append(
				_create_hero_sfx_player(
					STAGE3_CHARGE_IMPACT_AUDIO_PATH,
					HERO_SFX_DB_HEAVY_SKILL - 7.0,
					0.86
				)
			)

	if not is_instance_valid(fighter_hit_audio):
		fighter_hit_audio = _create_hero_sfx_player(
			STAGE3_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(fighter_death_audio):
		fighter_death_audio = _create_hero_sfx_player(
			STAGE3_DEATH_AUDIO_PATH,
			HERO_SFX_DB_DEATH,
			0.82
		)


func _play_fighter_slash_audio() -> void:
	_ensure_fighter_audio_runtime()
	if fighter_slash_audio_pool.is_empty():
		return
	var player := fighter_slash_audio_pool[
		fighter_slash_audio_cursor % fighter_slash_audio_pool.size()
	]
	fighter_slash_audio_cursor = (
		fighter_slash_audio_cursor + 1
	) % fighter_slash_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	var pitch_steps: Array[float] = [0.94, 1.00, 0.90]
	player.pitch_scale = pitch_steps[
		fighter_slash_audio_cursor % pitch_steps.size()
	]
	player.stop()
	player.play()


func _play_fighter_thrust_audio(is_charge: bool = false) -> void:
	_ensure_fighter_audio_runtime()
	if fighter_thrust_audio_pool.is_empty():
		return
	var player := fighter_thrust_audio_pool[
		fighter_thrust_audio_cursor % fighter_thrust_audio_pool.size()
	]
	fighter_thrust_audio_cursor = (
		fighter_thrust_audio_cursor + 1
	) % fighter_thrust_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 0.90 if is_charge else 1.12
	player.stop()
	player.play()


func _play_fighter_guard_start_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(fighter_guard_start_audio)
		and fighter_guard_start_audio.stream != null
	):
		fighter_guard_start_audio.stop()
		fighter_guard_start_audio.play()


func _play_fighter_guard_release_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(fighter_guard_release_audio)
		and fighter_guard_release_audio.stream != null
	):
		fighter_guard_release_audio.stop()
		fighter_guard_release_audio.play()


func _play_fighter_charge_impact_audio() -> void:
	_ensure_fighter_audio_runtime()
	if fighter_charge_impact_audio_pool.is_empty():
		return
	var player := fighter_charge_impact_audio_pool[
		fighter_charge_impact_audio_cursor
		% fighter_charge_impact_audio_pool.size()
	]
	fighter_charge_impact_audio_cursor = (
		fighter_charge_impact_audio_cursor + 1
	) % fighter_charge_impact_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_fighter_hit_audio() -> void:
	_ensure_fighter_audio_runtime()
	if is_instance_valid(fighter_hit_audio) and fighter_hit_audio.stream != null:
		fighter_hit_audio.stop()
		fighter_hit_audio.play()


func _play_fighter_death_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(fighter_death_audio)
		and fighter_death_audio.stream != null
	):
		fighter_death_audio.stop()
		fighter_death_audio.play()


func _ensure_gunner_audio_runtime() -> void:
	if hero_archetype != "pistol_gunner":
		return

	if gunner_shot_audio_pool.is_empty():
		for index in range(3):
			gunner_shot_audio_pool.append(
				_create_hero_sfx_player(
					STAGE4_GUNSHOT_AUDIO_PATH, HERO_SFX_DB_PRIMARY_ATTACK - 3.0, 1.0
				)
			)

	if gunner_deadeye_shot_audio_pool.is_empty():
		for index in range(4):
			gunner_deadeye_shot_audio_pool.append(
				_create_hero_sfx_player(
					STAGE4_DEADEYE_SHOT_AUDIO_PATH, HERO_SFX_DB_HIT - 2.0, 1.0
				)
			)

	if not is_instance_valid(gunner_reload_audio):
		gunner_reload_audio = _create_hero_sfx_player(
			STAGE4_RELOAD_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL + 1.0,
			1.0
		)

	if not is_instance_valid(gunner_backstep_audio):
		gunner_backstep_audio = _create_hero_sfx_player(
			STAGE4_BACKSTEP_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.12
		)

	if not is_instance_valid(gunner_cylinder_audio):
		gunner_cylinder_audio = _create_hero_sfx_player(
			STAGE4_CYLINDER_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 6.0,
			0.78
		)

	if not is_instance_valid(gunner_deadeye_start_audio):
		gunner_deadeye_start_audio = _create_hero_sfx_player(
			STAGE4_DEADEYE_START_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL - 3.0, 1.0
		)

	if not is_instance_valid(gunner_hit_audio):
		gunner_hit_audio = _create_hero_sfx_player(
			STAGE4_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(gunner_death_audio):
		gunner_death_audio = _create_hero_sfx_player(
			STAGE4_DEATH_AUDIO_PATH,
			HERO_SFX_DB_DEATH,
			0.92
		)


func _play_gunner_basic_shot_audio() -> void:
	_ensure_gunner_audio_runtime()
	if gunner_shot_audio_pool.is_empty():
		return
	var player := gunner_shot_audio_pool[
		gunner_shot_audio_cursor % gunner_shot_audio_pool.size()
	]
	gunner_shot_audio_cursor = (
		gunner_shot_audio_cursor + 1
	) % gunner_shot_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_gunner_deadeye_shot_audio() -> void:
	_ensure_gunner_audio_runtime()
	if gunner_deadeye_shot_audio_pool.is_empty():
		return
	var player := gunner_deadeye_shot_audio_pool[
		gunner_deadeye_shot_audio_cursor
		% gunner_deadeye_shot_audio_pool.size()
	]
	gunner_deadeye_shot_audio_cursor = (
		gunner_deadeye_shot_audio_cursor + 1
	) % gunner_deadeye_shot_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_gunner_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_gunner_reload_audio() -> void:
	_ensure_gunner_audio_runtime()
	if (
		not is_instance_valid(gunner_reload_audio)
		or gunner_reload_audio.stream == null
	):
		return
	gunner_reload_audio.stop()
	gunner_reload_audio.play(STAGE4_RELOAD_AUDIO_START_OFFSET)


func _play_gunner_backstep_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(gunner_backstep_audio)


func _play_gunner_cylinder_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(gunner_cylinder_audio)


func _play_gunner_deadeye_start_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(gunner_deadeye_start_audio)


func _play_gunner_hit_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(gunner_hit_audio)


func _play_gunner_death_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(gunner_death_audio)


func _ensure_archmage_audio_runtime() -> void:
	if hero_archetype != "archmage_elementalist":
		return

	if archmage_basic_audio_pool.is_empty():
		for index in range(3):
			archmage_basic_audio_pool.append(
				_create_hero_sfx_player(
					STAGE5_BASIC_AUDIO_PATH,
					HERO_SFX_DB_PRIMARY_ATTACK - 3.0,
					1.0
				)
			)

	if not is_instance_valid(archmage_combustion_charge_audio):
		archmage_combustion_charge_audio = _create_hero_sfx_player(
			STAGE5_COMBUSTION_CHARGE_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL,
			0.92
		)
	if not is_instance_valid(archmage_combustion_release_audio):
		archmage_combustion_release_audio = _create_hero_sfx_player(
			STAGE5_COMBUSTION_RELEASE_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 3.0,
			1.0
		)
	if not is_instance_valid(archmage_ice_bolt_audio):
		archmage_ice_bolt_audio = _create_hero_sfx_player(
			STAGE5_ICE_BOLT_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.48
		)
	if not is_instance_valid(archmage_ice_impact_audio):
		archmage_ice_impact_audio = _create_hero_sfx_player(
			STAGE5_ICE_IMPACT_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 1.0,
			0.94
		)

	if archmage_earth_audio_pool.is_empty():
		for index in range(4):
			archmage_earth_audio_pool.append(
				_create_hero_sfx_player(
					STAGE5_EARTH_SPIKE_AUDIO_PATH,
					HERO_SFX_DB_SECONDARY_REPEAT - 1.0,
					0.78
				)
			)

	if archmage_holy_audio_pool.is_empty():
		for index in range(4):
			archmage_holy_audio_pool.append(
				_create_hero_sfx_player(
					STAGE5_HOLY_BURST_AUDIO_PATH,
					HERO_SFX_DB_SECONDARY_REPEAT,
					1.20
				)
			)

	if not is_instance_valid(archmage_chain_launch_audio):
		archmage_chain_launch_audio = _create_hero_sfx_player(
			STAGE5_CHAIN_LAUNCH_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.18
		)
	if archmage_chain_hit_audio_pool.is_empty():
		for index in range(4):
			archmage_chain_hit_audio_pool.append(
				_create_hero_sfx_player(
					STAGE5_CHAIN_HIT_AUDIO_PATH,
					HERO_SFX_DB_SECONDARY_REPEAT + 2.0,
					1.30
				)
			)

	if not is_instance_valid(archmage_harmony_audio):
		archmage_harmony_audio = _create_hero_sfx_player(
			STAGE5_HARMONY_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 1.0,
			1.10
		)
	if not is_instance_valid(archmage_storm_audio):
		archmage_storm_audio = _create_hero_sfx_player(
			STAGE5_STORM_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.06
		)
	if not is_instance_valid(archmage_blink_audio):
		archmage_blink_audio = _create_hero_sfx_player(
			STAGE5_BLINK_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.18
		)
	if not is_instance_valid(archmage_hit_audio):
		archmage_hit_audio = _create_hero_sfx_player(
			STAGE5_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)
	if not is_instance_valid(archmage_death_audio):
		archmage_death_audio = _create_hero_sfx_player(
			STAGE5_DEATH_AUDIO_PATH,
			HERO_SFX_DB_DEATH,
			0.88
		)


func _play_archmage_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_archmage_basic_audio(element: String) -> void:
	_ensure_archmage_audio_runtime()
	if archmage_basic_audio_pool.is_empty():
		return
	var player := archmage_basic_audio_pool[
		archmage_basic_audio_cursor % archmage_basic_audio_pool.size()
	]
	archmage_basic_audio_cursor = (
		archmage_basic_audio_cursor + 1
	) % archmage_basic_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	var element_pitch := {
		"earth": 0.82,
		"fire": 0.96,
		"ice": 1.16,
		"light": 1.28,
		"wind": 1.08,
		"holy": 1.22,
	}
	player.pitch_scale = float(element_pitch.get(element, 1.0))
	player.stop()
	player.play()


func _play_archmage_earth_spike_audio() -> void:
	_ensure_archmage_audio_runtime()
	if archmage_earth_audio_pool.is_empty():
		return
	var player := archmage_earth_audio_pool[
		archmage_earth_audio_cursor % archmage_earth_audio_pool.size()
	]
	archmage_earth_audio_cursor = (
		archmage_earth_audio_cursor + 1
	) % archmage_earth_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 0.74 + 0.04 * float(archmage_earth_audio_cursor % 3)
		player.stop()
		player.play()


func _play_archmage_holy_burst_audio() -> void:
	_ensure_archmage_audio_runtime()
	if archmage_holy_audio_pool.is_empty():
		return
	var player := archmage_holy_audio_pool[
		archmage_holy_audio_cursor % archmage_holy_audio_pool.size()
	]
	archmage_holy_audio_cursor = (
		archmage_holy_audio_cursor + 1
	) % archmage_holy_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 1.14 + 0.04 * float(archmage_holy_audio_cursor % 4)
		player.stop()
		player.play()


func play_archmage_chain_hit_audio() -> void:
	_ensure_archmage_audio_runtime()
	if archmage_chain_hit_audio_pool.is_empty():
		return
	var player := archmage_chain_hit_audio_pool[
		archmage_chain_hit_audio_cursor % archmage_chain_hit_audio_pool.size()
	]
	archmage_chain_hit_audio_cursor = (
		archmage_chain_hit_audio_cursor + 1
	) % archmage_chain_hit_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 1.22 + 0.04 * float(archmage_chain_hit_audio_cursor % 4)
		player.stop()
		player.play()


func _play_archmage_hit_audio() -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_hit_audio)


func _play_archmage_death_audio() -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_death_audio)


func _ensure_berserker_audio_runtime() -> void:
	if hero_archetype != "berserker_madness":
		return

	if berserker_basic_audio_pool.is_empty():
		for index in range(4):
			berserker_basic_audio_pool.append(
				_create_hero_sfx_player(
					STAGE6_BASIC_AUDIO_PATH,
					HERO_SFX_DB_PRIMARY_ATTACK - 5.0,
					0.94
				)
			)

	if berserker_skill1_audio_pool.is_empty():
		for index in range(3):
			berserker_skill1_audio_pool.append(
				_create_hero_sfx_player(
					STAGE6_SKILL1_AUDIO_PATH,
					HERO_SFX_DB_REGULAR_SKILL - 3.0,
					0.82
				)
			)

	if not is_instance_valid(berserker_skill2_audio):
		berserker_skill2_audio = _create_hero_sfx_player(
			STAGE6_SKILL2_AUDIO_PATH,
			HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.72
		)
	if not is_instance_valid(berserker_skill3_audio):
		berserker_skill3_audio = _create_hero_sfx_player(
			STAGE6_SKILL3_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.18
		)
	if not is_instance_valid(berserker_skill4_audio):
		berserker_skill4_audio = _create_hero_sfx_player(
			STAGE6_SKILL4_AUDIO_PATH,
			HERO_SFX_DB_REGULAR_SKILL - 1.0,
			0.90
		)
	if not is_instance_valid(berserker_madness_roar_audio):
		berserker_madness_roar_audio = _create_hero_sfx_player(
			STAGE6_MADNESS_ROAR_AUDIO_PATH, HERO_SFX_DB_HEAVY_SKILL - 5.0, 1.0
		)
	if not is_instance_valid(berserker_hit_audio):
		berserker_hit_audio = _create_hero_sfx_player(
			STAGE6_HIT_AUDIO_PATH, CONTEXT_AUDIO.HIT_DB, 1.0
		)
	if not is_instance_valid(berserker_death_audio):
		berserker_death_audio = _create_hero_sfx_player(
			STAGE6_DEATH_AUDIO_PATH,
			HERO_SFX_DB_DEATH,
			0.82
		)


func _play_berserker_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_berserker_basic_audio() -> void:
	_ensure_berserker_audio_runtime()
	if berserker_basic_audio_pool.is_empty():
		return
	var player := berserker_basic_audio_pool[
		berserker_basic_audio_cursor % berserker_basic_audio_pool.size()
	]
	berserker_basic_audio_cursor = (
		berserker_basic_audio_cursor + 1
	) % berserker_basic_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = (
		1.02 + 0.04 * float(berserker_basic_audio_cursor % 3)
		if berserker_madness_active
		else 0.88 + 0.04 * float(berserker_basic_audio_cursor % 3)
	)
	player.stop()
	player.play()


func _play_berserker_skill1_audio(wave_index: int) -> void:
	_ensure_berserker_audio_runtime()
	if berserker_skill1_audio_pool.is_empty():
		return
	var player := berserker_skill1_audio_pool[
		berserker_skill1_audio_cursor % berserker_skill1_audio_pool.size()
	]
	berserker_skill1_audio_cursor = (
		berserker_skill1_audio_cursor + 1
	) % berserker_skill1_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 0.78 + 0.07 * float(clampi(wave_index, 0, 2))
	player.stop()
	player.play()


func _play_berserker_hit_audio() -> void:
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_hit_audio)


func _play_berserker_death_audio() -> void:
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_death_audio)


func _create_sage_audio_player(audio_path: String, volume_db: float, pitch_scale: float) -> AudioStreamPlayer:
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


func _play_sage_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _fire_sage_projectile(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return
	_ensure_sage_runtime()
	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.42
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")
	sage_attack_serial += 1
	var third_interval := maxi(int(sage_config.get("third_attack_interval", 3)), 1)
	var is_piercing := sage_attack_serial % third_interval == 0
	var shot_damage := attack_damage
	var shot_speed := maxf(float(sage_config.get("basic_projectile_speed", 800.0)), 1.0)
	var shot_range := maxf(float(sage_config.get("basic_range", 650.0)), 1.0)
	var diameter := 26.4
	var projectile_mode := 0

	if is_piercing:
		projectile_mode = 1
		var celestial_pierce_stacks := _get_sage_augment_stacks(
			"sage_celestial_pierce"
		)
		shot_damage = maxi(1, int(round(
			float(attack_damage)
			* maxf(float(sage_config.get("piercing_damage_ratio", 0.90)), 0.0)
			* (1.0 + 0.08 * float(celestial_pierce_stacks))
		)))
		shot_speed = maxf(
			float(sage_config.get("piercing_projectile_speed", 800.0)),
			1.0
		)
		shot_range = maxf(
			float(sage_config.get("piercing_range", 1200.0))
			+ 80.0 * float(celestial_pierce_stacks),
			1.0
		)
		diameter = maxf(
			float(sage_config.get("piercing_diameter", 220.0)),
			2.0
		)

	# 탄환 강화는 1·2번째 일반 평타에만 적용한다.
	# 3번째 관통 평타는 천체관통 전용 단일탄을 유지한다.
	var projectile_count := (
		1
		if is_piercing
		else 1 + clampi(projectile_count_bonus, 0, 4)
	)
	var volley := PROJECTILE_VOLLEY.new() if projectile_count > 1 else null
	var spread_step := deg_to_rad(12.0)
	var center_index := float(projectile_count - 1) * 0.5
	var pool_key := (
		"sage_piercing_projectile"
		if is_piercing
		else "sage_basic_projectile"
	)

	for index in range(projectile_count):
		var projectile_direction := shot_direction
		if not is_piercing and projectile_count > 1:
			var angle_offset := (float(index) - center_index) * spread_step
			projectile_direction = shot_direction.rotated(angle_offset).normalized()

		var projectile := _acquire_projectile(
			SAGE_PROJECTILE_SCENE,
			pool_key
		)
		if projectile == null:
			continue
		projectile.global_position = (
			global_position + projectile_direction * 54.0
		)
		projectile.call(
			"setup",
			projectile_direction,
			shot_damage,
			shot_speed,
			shot_range,
			projectile_mode,
			diameter,
			self,
			volley
		)

	if is_piercing:
		_play_sage_audio(sage_third_audio)
	else:
		_play_sage_audio(sage_basic_audio)


func _add_sage_gauge(amount: float) -> void:
	if amount <= 0.0 or hero_archetype != "grand_sage_astra" or sage_config.is_empty() or is_dying:
		return
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	ultimate_charge = minf(ultimate_charge + amount, gauge_max)
	queue_redraw()


func is_sage_skill_ready() -> bool:
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return false
	return ultimate_charge + 0.001 >= maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)


func _update_sage_runtime(delta: float) -> void:
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty() or is_dying or current_hp <= 0:
		return
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var level_steps := floori(float(maxi(level, 0)) / 5.0)
	var regen_per_second := maxf(float(sage_config.get("gauge_regen_base", 1.0)), 0.0) + float(level_steps) * maxf(float(sage_config.get("gauge_regen_per_5_levels", 1.0)), 0.0)
	if regen_per_second > 0.0 and ultimate_charge < gauge_max:
		ultimate_charge = minf(ultimate_charge + regen_per_second * delta, gauge_max)
		sage_gauge_redraw_timer -= delta
		if sage_gauge_redraw_timer <= 0.0:
			sage_gauge_redraw_timer = 0.10
			queue_redraw()
	var sage_skill_cooldown_delta := (
		delta * _get_sage_condensation_cooldown_rate()
	)
	sage_skill1_cooldown_timer = maxf(
		sage_skill1_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	sage_skill2_cooldown_timer = maxf(
		sage_skill2_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	sage_skill3_cooldown_timer = maxf(
		sage_skill3_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	sage_skill4_cooldown_timer = maxf(
		sage_skill4_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	sage_skill5_cooldown_timer = maxf(
		sage_skill5_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	sage_condensation_skill_damage_buff_timer = maxf(
		sage_condensation_skill_damage_buff_timer - delta,
		0.0
	)

	if sage_condensation_unlock_pending:
		sage_condensation_unlock_effect_timer = maxf(
			sage_condensation_unlock_effect_timer - delta,
			0.0
		)
		if sage_condensation_unlock_effect_timer <= 0.0:
			sage_condensation_unlock_pending = false
			_emit_sage_late_skill_unlock_cutscene()

	if sage_starlight_remaining > 0.0:
		sage_starlight_remaining = maxf(sage_starlight_remaining - delta, 0.0)
		sage_starlight_volley_timer -= delta
		var skill4_value = sage_config.get("skill_4", {})
		var skill4: Dictionary = (
			skill4_value if typeof(skill4_value) == TYPE_DICTIONARY else {}
		)
		var volley_interval := maxf(
			float(skill4.get("spawn_interval", 0.75)),
			0.05
		)
		while sage_starlight_remaining > 0.0 and sage_starlight_volley_timer <= 0.0:
			_launch_sage_starlight_volley(skill4)
			sage_starlight_volley_timer += volley_interval
		if sage_starlight_remaining <= 0.0:
			_set_sage_starlight_aura_active(false)

	if sage_radiance_launch_remaining > 0:
		sage_radiance_launch_timer = maxf(sage_radiance_launch_timer - delta, 0.0)
		if sage_radiance_launch_timer <= 0.0:
			_launch_sage_radiance_orb()
			sage_radiance_launch_remaining = maxi(sage_radiance_launch_remaining - 1, 0)
			var skill2_value = sage_config.get("skill_2", {})
			var skill2: Dictionary = (
				skill2_value if typeof(skill2_value) == TYPE_DICTIONARY else {}
			)
			sage_radiance_launch_timer = maxf(
				float(skill2.get("spawn_interval", 0.25)),
				0.01
			)
	elif sage_skill5_cooldown_timer <= 0.0 and _try_cast_sage_annihilation():
		pass
	elif sage_skill4_cooldown_timer <= 0.0 and _try_cast_sage_starlight():
		pass
	elif sage_skill3_cooldown_timer <= 0.0:
		if not _try_cast_sage_mana_condensation():
			if sage_skill2_cooldown_timer <= 0.0:
				if not _try_cast_sage_radiance_singularity() and sage_skill1_cooldown_timer <= 0.0:
					_try_cast_sage_ice_pillar()
			elif sage_skill1_cooldown_timer <= 0.0:
				_try_cast_sage_ice_pillar()
	elif sage_skill2_cooldown_timer <= 0.0:
		if not _try_cast_sage_radiance_singularity() and sage_skill1_cooldown_timer <= 0.0:
			_try_cast_sage_ice_pillar()
	elif sage_skill1_cooldown_timer <= 0.0:
		_try_cast_sage_ice_pillar()

	if sage_post_phase_shield_timer > 0.0:
		sage_post_phase_shield_timer = maxf(sage_post_phase_shield_timer - delta, 0.0)
		if shield_hp <= 0.0:
			sage_post_phase_shield_timer = 0.0
			shield_max_hp = 0.0
		elif sage_post_phase_shield_timer <= 0.0:
			shield_hp = 0.0
			shield_max_hp = 0.0
			queue_redraw()
	if sage_phase_active:
		sage_phase_remaining = maxf(sage_phase_remaining - delta, 0.0)
		sage_afterimage_timer = maxf(sage_afterimage_timer - delta, 0.0)
		if velocity.length_squared() > 36.0 and sage_afterimage_timer <= 0.0:
			_emit_sage_afterimage()
			sage_afterimage_timer = maxf(float(sage_config.get("afterimage_interval", 0.075)), 0.03)
		if sage_phase_remaining <= 0.0:
			_end_sage_phase()
		return
	sage_phase_cooldown_timer = maxf(sage_phase_cooldown_timer - delta, 0.0)
	if sage_phase_cooldown_timer <= 0.0:
		_start_sage_phase()


func _try_cast_sage_ice_pillar() -> void:
	if silence_timer > 0.0:
		return
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var skill_value = sage_config.get("skill_1", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return
	var gauge_cost := maxf(float(skill.get("gauge_cost", 35.0)), 0.0)
	if ultimate_charge + 0.001 < gauge_cost:
		return

	var effect_diameter := maxf(float(skill.get("effect_diameter", 250.0)), 2.0)
	var damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* maxf(float(skill.get("damage_ratio", 1.0)), 0.0)
			* _get_sage_skill_damage_multiplier()
		))
	)
	var cast_position := target.global_position
	var cast_direction := global_position.direction_to(cast_position)
	if cast_direction.length_squared() <= 0.001:
		cast_direction = Vector2.RIGHT
	var wall_direction := cast_direction.orthogonal().normalized()
	var glacier_wall_stacks := _get_sage_augment_stacks("sage_glacier_wall")
	var spawned_any := false
	for pillar_index in range(1 + glacier_wall_stacks):
		var pillar := _acquire_projectile(
			SAGE_ICE_PILLAR_SCENE,
			"sage_ice_pillar"
		)
		if pillar == null:
			continue
		var pillar_position := cast_position
		var pillar_damage := damage
		if pillar_index > 0:
			var side := -1.0 if pillar_index % 2 == 1 else 1.0
			var row := float(ceili(float(pillar_index) / 2.0))
			pillar_position += (
				wall_direction
				* side
				* row
				* effect_diameter
				* 0.72
			)
			pillar_damage = maxi(1, int(round(float(damage) * 0.65)))
		pillar_position.x = clampf(
			pillar_position.x,
			FIELD_MARGIN,
			battlefield_size.x - FIELD_MARGIN
		)
		pillar_position.y = clampf(
			pillar_position.y,
			FIELD_MARGIN,
			battlefield_size.y - FIELD_MARGIN
		)
		pillar.global_position = pillar_position
		pillar.call(
			"setup",
			pillar_damage,
			maxf(float(skill.get("duration", 4.0)), 0.1),
			effect_diameter * 0.5,
			clampf(float(skill.get("slow_multiplier", 0.80)), 0.1, 1.0),
			maxf(float(skill.get("collision_radius", 34.0)), 8.0),
			self
		)
		spawned_any = true
	if not spawned_any:
		return

	ultimate_charge = maxf(ultimate_charge - gauge_cost, 0.0)
	sage_skill1_cooldown_timer = maxf(float(skill.get("cooldown", 25.0)), 0.1)
	attack_timer = maxf(attack_timer, 0.35)
	attack_pose_timer = maxf(attack_pose_timer, 0.42)
	_face_attack_direction(target.global_position.x - global_position.x)
	_restart_stage1_animation("attack")
	_play_sage_audio(sage_ice_pillar_audio)
	queue_redraw()


func _try_cast_sage_radiance_singularity() -> bool:
	if silence_timer > 0.0:
		return false
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return false
	var skill_value = sage_config.get("skill_2", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty() or sage_radiance_launch_remaining > 0:
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 40.0)), 0.0)
	if ultimate_charge + 0.001 < gauge_cost:
		return false

	ultimate_charge = maxf(ultimate_charge - gauge_cost, 0.0)
	sage_skill2_cooldown_timer = maxf(float(skill.get("cooldown", 45.0)), 0.1)
	sage_radiance_launch_remaining = maxi(
		int(skill.get("orb_count", 10))
		+ _get_sage_augment_stacks("sage_radiance_split") * 2,
		1
	)
	sage_radiance_launch_timer = 0.0
	attack_timer = maxf(attack_timer, 0.35)
	attack_pose_timer = maxf(attack_pose_timer, 0.42)
	_restart_stage1_animation("attack")
	_play_sage_audio(sage_radiance_create_audio)
	queue_redraw()
	return true


func _launch_sage_radiance_orb() -> void:
	var skill_value = sage_config.get("skill_2", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return

	var direction := Vector2.from_angle(randf_range(0.0, TAU))
	var min_distance := maxf(float(skill.get("travel_distance_min", 180.0)), 1.0)
	var max_distance := maxf(
		float(skill.get("travel_distance_max", attack_range)),
		min_distance
	)
	var travel_distance := randf_range(min_distance, max_distance)
	var destination := global_position + direction * travel_distance
	var tracked_target: Node2D = null
	if _get_sage_augment_stacks("sage_radiance_split") > 0:
		var monster_nodes := _get_monster_nodes_cached()
		var monster_count := monster_nodes.size()
		for offset in range(monster_count):
			var candidate_index := (
				sage_radiance_target_cursor + offset
			) % maxi(monster_count, 1)
			var candidate := monster_nodes[candidate_index] as Node2D
			if (
				not is_instance_valid(candidate)
				or candidate.is_queued_for_deletion()
			):
				continue
			var hp_value = candidate.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			tracked_target = candidate
			destination = candidate.global_position
			sage_radiance_target_cursor = (
				candidate_index + 1
			) % maxi(monster_count, 1)
			break
	destination.x = clampf(
		destination.x,
		FIELD_MARGIN,
		battlefield_size.x - FIELD_MARGIN
	)
	destination.y = clampf(
		destination.y,
		FIELD_MARGIN,
		battlefield_size.y - FIELD_MARGIN
	)

	var size_min := clampf(float(skill.get("orb_scale_min", 0.50)), 0.05, 4.0)
	var size_max := maxf(float(skill.get("orb_scale_max", 1.0)), size_min)
	var orb_scale := randf_range(size_min, size_max)
	var size_ratio := (
		clampf((orb_scale - size_min) / maxf(size_max - size_min, 0.001), 0.0, 1.0)
	)
	var diameter := lerpf(
		maxf(float(skill.get("explosion_diameter_min", 100.0)), 2.0),
		maxf(float(skill.get("explosion_diameter_max", 250.0)), 2.0),
		size_ratio
	)
	var damage_ratio := lerpf(
		maxf(float(skill.get("damage_ratio_min", 0.50)), 0.0),
		maxf(float(skill.get("damage_ratio_max", 1.0)), 0.0),
		size_ratio
	)
	var orb_damage := maxi(1, int(round(float(attack_damage) * damage_ratio * _get_sage_skill_damage_multiplier())))

	var orb := _acquire_projectile(SAGE_RADIANCE_ORB_SCENE, "sage_radiance_orb")
	if orb == null:
		return
	orb.global_position = global_position
	orb.call(
		"setup",
		destination,
		maxf(float(skill.get("projectile_speed", 350.0)), 1.0),
		maxf(float(skill.get("arrival_delay", 1.0)), 0.0),
		diameter * 0.5,
		orb_damage,
		clampf(float(skill.get("slow_multiplier", 0.85)), 0.1, 1.0),
		maxf(float(skill.get("slow_duration", 2.0)), 0.0),
		orb_scale,
		self,
		tracked_target
	)


func _try_cast_sage_annihilation() -> bool:
	if silence_timer > 0.0:
		return false
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return false
	if not is_conditional_skill_unlocked("sage_skill_5"):
		return false

	var skill_value = sage_config.get("skill_5", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 100.0)), 0.0)
	if ultimate_charge + 0.001 < gauge_cost:
		return false

	var point := _acquire_projectile(
		SAGE_ANNIHILATION_POINT_SCENE,
		"sage_annihilation_point"
	)
	if point == null:
		return false

	var damage := maxi(
		int(round(
			float(attack_damage)
			* maxf(float(skill.get("damage_ratio", 0.70)), 0.0)
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	point.global_position = global_position
	point.call(
		"setup",
		self,
		maxf(
			float(skill.get("duration", 15.0))
			+ 0.6 * float(_get_sage_augment_stacks("sage_event_horizon")),
			0.1
		),
		maxf(
			float(skill.get("effect_diameter", 400.0))
			* 0.5
			* (1.0 + 0.12 * float(_get_sage_augment_stacks("sage_event_horizon"))),
			1.0
		),
		damage,
		maxf(float(skill.get("pull_interval", 0.10)), 0.05),
		maxf(
			float(skill.get("pull_step", 10.0))
			* (1.0 + 0.08 * float(_get_sage_augment_stacks("sage_event_horizon"))),
			0.0
		),
		maxf(float(skill.get("damage_interval", 0.50)), 0.05),
		clampf(float(skill.get("execution_hp_ratio", 0.10)), 0.0, 1.0),
		maxf(float(skill.get("visual_scale", 1.05)), 0.05),
		maxf(float(skill.get("create_fps", 10.0)), 1.0),
		maxf(float(skill.get("active_fps", 5.0)), 1.0),
		maxf(float(skill.get("disappear_fps", 10.0)), 1.0)
	)

	ultimate_charge = maxf(ultimate_charge - gauge_cost, 0.0)
	sage_skill5_cooldown_timer = maxf(
		float(skill.get("cooldown", 60.0)),
		0.1
	)
	attack_timer = maxf(attack_timer, 0.40)
	attack_pose_timer = maxf(attack_pose_timer, 0.48)
	_restart_stage1_animation("attack")
	queue_redraw()
	return true


func _try_cast_sage_starlight() -> bool:
	if silence_timer > 0.0:
		return false
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return false
	if sage_starlight_remaining > 0.0:
		return false

	var skill_value = sage_config.get("skill_4", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 70.0)), 0.0)
	if ultimate_charge + 0.001 < gauge_cost:
		return false

	_ensure_sage_runtime()
	ultimate_charge = maxf(ultimate_charge - gauge_cost, 0.0)
	sage_skill4_cooldown_timer = maxf(
		float(skill.get("cooldown", 60.0)),
		0.1
	)
	sage_starlight_remaining = maxf(
		float(skill.get("duration", 8.0)),
		0.1
	)
	sage_starlight_volley_timer = maxf(
		float(skill.get("spawn_interval", 0.75)),
		0.05
	)
	_set_sage_starlight_aura_active(true)
	_launch_sage_starlight_volley(skill)

	attack_timer = maxf(attack_timer, 0.35)
	attack_pose_timer = maxf(attack_pose_timer, 0.42)
	_restart_stage1_animation("attack")
	queue_redraw()
	return true


func _launch_sage_starlight_volley(skill: Dictionary) -> void:
	if skill.is_empty():
		return

	var meteor_count := maxi(
		int(skill.get("meteors_per_volley", 3))
		+ _get_sage_augment_stacks("sage_constellation_chain"),
		1
	)
	var spawn_radius := maxf(
		float(skill.get("spawn_diameter", 1200.0)) * 0.5,
		1.0
	)
	var impact_radius := maxf(
		float(skill.get("impact_diameter", 200.0)) * 0.5,
		1.0
	)
	var damage_ratio := maxf(float(skill.get("damage_ratio", 1.10)), 0.0)
	var hit_damage := maxi(
		int(round(
			float(attack_damage)
			* damage_ratio
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	var fall_duration := maxf(float(skill.get("fall_duration", 0.58)), 0.05)
	var fall_height := maxf(float(skill.get("fall_height", 430.0)), 40.0)
	var fall_side_offset := maxf(
		float(skill.get("fall_side_offset", 90.0)),
		0.0
	)
	var visual_scale := maxf(
		float(skill.get("meteor_visual_scale", 0.62)),
		0.05
	)
	var explosion_fps := maxf(
		float(skill.get("explosion_fps", 14.0)),
		1.0
	)

	for _index in range(meteor_count):
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * spawn_radius
		var impact_position := (
			global_position
			+ Vector2.from_angle(angle) * distance
		)
		impact_position.x = clampf(
			impact_position.x,
			FIELD_MARGIN,
			maxf(battlefield_size.x - FIELD_MARGIN, FIELD_MARGIN)
		)
		impact_position.y = clampf(
			impact_position.y,
			FIELD_MARGIN,
			maxf(battlefield_size.y - FIELD_MARGIN, FIELD_MARGIN)
		)

		var meteor := _acquire_projectile(
			SAGE_STARLIGHT_METEOR_SCENE,
			"sage_starlight_meteor"
		)
		if meteor == null:
			continue
		meteor.global_position = impact_position
		meteor.call(
			"setup",
			hit_damage,
			impact_radius,
			fall_duration,
			visual_scale,
			fall_height,
			fall_side_offset,
			explosion_fps,
			self
		)


func _try_cast_sage_mana_condensation() -> bool:
	if silence_timer > 0.0:
		return false
	if hero_archetype != "grand_sage_astra" or sage_config.is_empty():
		return false
	var skill_value = sage_config.get("skill_3", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 20.0)), 0.0)
	if ultimate_charge + 0.001 < gauge_cost:
		return false

	_ensure_sage_runtime()
	ultimate_charge = maxf(ultimate_charge - gauge_cost, 0.0)
	sage_skill3_cooldown_timer = maxf(float(skill.get("cooldown", 13.0)), 0.1)
	attack_timer = maxf(attack_timer, 0.30)
	attack_pose_timer = maxf(attack_pose_timer, 0.38)
	_restart_stage1_animation("attack")

	var max_stacks := maxi(int(skill.get("max_stacks", 8)), 1)
	if sage_condensation_stacks >= max_stacks:
		_consume_sage_condensation(skill)
	else:
		_add_sage_condensation_stack(skill)
	queue_redraw()
	return true


func _add_sage_condensation_stack(skill: Dictionary) -> void:
	if sage_condensation_free_slots.is_empty():
		return
	var pick_index := randi_range(0, sage_condensation_free_slots.size() - 1)
	var slot_index := sage_condensation_free_slots[pick_index]
	sage_condensation_free_slots.remove_at(pick_index)
	sage_condensation_stacks = mini(
		sage_condensation_stacks + 1,
		maxi(int(skill.get("max_stacks", 8)), 1)
	)

	if slot_index >= 0 and slot_index < sage_condensation_visuals.size():
		var sprite := sage_condensation_visuals[slot_index]
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
			sprite.visible = true
			sprite.stop()
			sprite.animation = &"summon"
			sprite.frame = 0
			sprite.frame_progress = 0.0
			sprite.play(&"summon")
	_play_sage_audio(sage_condensation_stack_audio)


func _consume_sage_condensation(skill: Dictionary) -> void:
	sage_condensation_stacks = 0
	_reset_sage_condensation_slots()
	sage_condensation_completion_count += 1

	var hp_multiplier := 1.0 + maxf(
		float(skill.get("permanent_hp_ratio", 0.03)),
		0.0
	)
	var attack_multiplier := 1.0 + maxf(
		float(skill.get("permanent_attack_ratio", 0.03)),
		0.0
	)
	var move_multiplier := 1.0 + maxf(
		float(skill.get("permanent_move_speed_ratio", 0.0025)),
		0.0
	)
	var attack_speed_gain := maxf(
		float(skill.get("permanent_attack_speed_ratio", 0.0025)),
		0.0
	)

	var previous_max_hp := max_hp
	max_hp = maxi(1, int(round(float(max_hp) * hp_multiplier)))
	current_hp = mini(
		max_hp,
		current_hp + maxi(max_hp - previous_max_hp, 0)
	)
	attack_damage = maxi(
		1,
		int(round(float(attack_damage) * attack_multiplier))
	)
	base_attack_damage_for_level_growth *= attack_multiplier
	move_speed *= move_multiplier
	common_attack_speed_bonus += attack_speed_gain
	sage_condensation_skill_damage_buff_timer = maxf(
		float(skill.get("skill_damage_buff_duration", 10.0)),
		0.0
	)

	_play_sage_audio(sage_condensation_release_audio)
	health_changed.emit(current_hp, max_hp)
	_try_start_sage_late_skill_unlock_sequence(skill)


func _get_sage_condensation_cooldown_reduction() -> float:
	if (
		hero_archetype != "grand_sage_astra"
		or sage_condensation_stacks <= 0
	):
		return 0.0
	var skill_value = sage_config.get("skill_3", {})
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var per_stack := maxf(
		float(skill.get("cooldown_reduction_per_stack", 0.02)),
		0.0
	)
	return clampf(
		per_stack * float(sage_condensation_stacks),
		0.0,
		0.90
	)


func _get_sage_condensation_cooldown_rate() -> float:
	var reduction := _get_sage_condensation_cooldown_reduction()
	return (
		1.0 / maxf(1.0 - reduction, 0.10)
		* (1.0 + 0.05 * float(_get_sage_augment_stacks("sage_multicast")))
	)


func _get_sage_skill_damage_multiplier() -> float:
	if hero_archetype != "grand_sage_astra":
		return 1.0

	var bonus_ratio := 0.0
	if sage_condensation_skill_damage_buff_timer > 0.0:
		var skill3_value = sage_config.get("skill_3", {})
		var skill3: Dictionary = (
			skill3_value
			if typeof(skill3_value) == TYPE_DICTIONARY
			else {}
		)
		bonus_ratio += maxf(
			float(skill3.get("skill_damage_buff_ratio", 0.30)),
			0.0
		)

	if is_conditional_skill_unlocked("sage_skill_6"):
		var skill6_value = sage_config.get("skill_6", {})
		var skill6: Dictionary = (
			skill6_value
			if typeof(skill6_value) == TYPE_DICTIONARY
			else {}
		)
		bonus_ratio += maxf(
			float(skill6.get("skill_damage_bonus_ratio", 0.10)),
			0.0
		)
	bonus_ratio += 0.08 * float(_get_sage_augment_stacks("sage_multicast"))

	return 1.0 + bonus_ratio


func _on_sage_skill_hit(hit_position: Vector2) -> void:
	if (
		hero_archetype != "grand_sage_astra"
		or is_dying
		or current_hp <= 0
		or not is_conditional_skill_unlocked("sage_skill_6")
	):
		return

	var skill_value = sage_config.get("skill_6", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return
	if randf() >= clampf(
		float(skill.get("trigger_chance", 0.50)),
		0.0,
		1.0
	):
		return

	var explosion := _acquire_projectile(
		SAGE_BLACKSPOT_EXPLOSION_SCENE,
		"sage_blackspot_explosion"
	)
	if explosion == null:
		return

	var blackspot_damage := maxi(
		int(round(
			float(attack_damage)
			* maxf(float(skill.get("damage_ratio", 0.80)), 0.0)
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	explosion.global_position = hit_position
	explosion.call(
		"setup",
		self,
		blackspot_damage,
		maxf(
			float(skill.get("explosion_diameter", 150.0)) * 0.5,
			1.0
		),
		maxf(float(skill.get("explosion_fps", 14.0)), 1.0),
		maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	)


func _on_sage_blackspot_kill() -> void:
	if (
		hero_archetype != "grand_sage_astra"
		or is_dying
		or current_hp <= 0
		or current_hp >= max_hp
	):
		return

	var skill_value = sage_config.get("skill_6", {})
	var skill: Dictionary = (
		skill_value
		if typeof(skill_value) == TYPE_DICTIONARY
		else {}
	)
	var heal_ratio := maxf(
		float(skill.get("kill_heal_current_hp_ratio", 0.005)),
		0.0
	)
	if heal_ratio <= 0.0:
		return

	var heal_amount := maxi(
		int(round(float(current_hp) * heal_ratio)),
		1
	)
	var previous_hp := current_hp
	current_hp = mini(current_hp + _get_reduced_healing(heal_amount), max_hp)
	if current_hp != previous_hp:
		health_changed.emit(current_hp, max_hp)
		queue_redraw()


func _try_start_sage_late_skill_unlock_sequence(skill: Dictionary) -> void:
	var required := maxi(int(skill.get("unlock_completion_count", 2)), 1)
	if sage_condensation_completion_count < required:
		return
	if (
		is_conditional_skill_unlocked("sage_skill_5")
		and is_conditional_skill_unlocked("sage_skill_6")
	):
		return

	conditional_skill_unlocks["sage_skill_5"] = true
	conditional_skill_unlocks["sage_skill_6"] = true
	sage_condensation_unlock_pending = true
	sage_condensation_unlock_effect_timer = maxf(
		float(skill.get("unlock_effect_seconds", 0.80)),
		0.1
	)
	_play_sage_condensation_unlock_effect(skill)


func _play_sage_condensation_unlock_effect(skill: Dictionary) -> void:
	var visual_scale := maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	for sprite in sage_condensation_visuals:
		if not is_instance_valid(sprite):
			continue
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		sprite.scale = Vector2.ONE * visual_scale * 1.18
		sprite.visible = true
		sprite.stop()
		sprite.animation = &"summon"
		sprite.frame = 0
		sprite.frame_progress = 0.0
		sprite.play(&"summon")
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(
			sprite,
			"scale",
			Vector2.ONE * visual_scale * 1.42,
			0.72
		)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.72)
		tween.chain().tween_callback(
			Callable(self, "_hide_sage_condensation_unlock_sprite").bind(
				sprite,
				visual_scale
			)
		)


func _hide_sage_condensation_unlock_sprite(
	sprite: AnimatedSprite2D,
	visual_scale: float
) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.stop()
	sprite.visible = false
	sprite.scale = Vector2.ONE * visual_scale
	sprite.modulate = Color.WHITE


func _emit_sage_late_skill_unlock_cutscene() -> void:
	var skill_value = sage_config.get("skill_3", {})
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var required := maxi(int(skill.get("unlock_completion_count", 2)), 1)
	var payload := {
		"hero_id": hero_id,
		"archetype": hero_archetype,
		"source": "sage_condensation_completions",
		"condition_type": "mana_condensation_cycles",
		"current_value": sage_condensation_completion_count,
		"required_value": required,
		"skill_id": "sage_skill_5_6",
		"skill_name": "스킬 5·6",
		"unlocked_skill_ids": ["sage_skill_5", "sage_skill_6"],
		"cutscene_texture_path": String(
			skill.get(
				"cutscene_texture_path",
				"res://assets/art/heroes/stage10_sage/cutscene/stage10_hero_cutscene.png"
			)
		),
		"cutscene_hold_seconds": float(
			skill.get("cutscene_hold_seconds", 1.20)
		),
	}
	conditional_skill_unlocked.emit(
		"sage_skill_5_6",
		"스킬 5·6",
		payload
	)


func _start_sage_phase() -> void:
	if sage_phase_active or hero_archetype != "grand_sage_astra":
		return
	_ensure_sage_runtime()
	sage_phase_entry_position = position
	sage_phase_active = true
	sage_phase_remaining = maxf(float(sage_config.get("phase_duration", 7.0)), 0.1)
	sage_afterimage_timer = 0.0
	if sage_saved_collision_mask < 0:
		sage_saved_collision_mask = collision_mask
	# Ignore monsters and decorative obstacles, but preserve hard castle
	# boundaries so phase cannot cross the upper wall and get trapped behind it.
	collision_mask = (
		sage_saved_collision_mask
		& SAGE_PHASE_BOUNDARY_COLLISION_MASK
	)
	_play_sage_audio(sage_phase_audio)


func _end_sage_phase() -> void:
	if not sage_phase_active:
		return
	sage_phase_active = false
	sage_phase_remaining = 0.0
	if sage_saved_collision_mask >= 0:
		collision_mask = sage_saved_collision_mask
	sage_saved_collision_mask = -1
	# Resolve after the physics action wrapper, including its petrify anchor lock.
	call_deferred("_resolve_sage_phase_obstacle_overlap")
	var interval := maxf(float(sage_config.get("phase_interval", 25.0)), 0.1)
	var duration := maxf(float(sage_config.get("phase_duration", 7.0)), 0.0)
	sage_phase_cooldown_timer = maxf(interval - duration, 0.1)
	var shield_ratio := maxf(float(sage_config.get("post_phase_shield_ratio", 0.10)), 0.0)
	shield_max_hp = float(max_hp) * shield_ratio
	shield_hp = shield_max_hp
	sage_post_phase_shield_timer = maxf(float(sage_config.get("post_phase_shield_duration", 3.0)), 0.0)
	queue_redraw()


func _resolve_sage_phase_obstacle_overlap() -> void:
	if hero_archetype != "grand_sage_astra" or sage_phase_active or is_dying or current_hp <= 0 or not is_inside_tree():
		return
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.disabled or body_shape.shape == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape.shape
	query.transform = body_shape.global_transform
	query.collision_mask = collision_mask & (
		HERO_DECOR_COLLISION_LAYER | SAGE_PHASE_BOUNDARY_COLLISION_MASK
	)
	query.exclude = [get_rid()]
	query.margin = 2.0
	var space := get_world_2d().direct_space_state
	if space.intersect_shape(query, 1).is_empty():
		return
	var origin := position
	var shape_offset := body_shape.global_position - global_position
	# Bounded one-shot search, only on expiry inside a prop; no frame/group scan.
	for ring in range(1, 33):
		for direction_index in range(16):
			var direction := Vector2.RIGHT.rotated(TAU * float(direction_index) / 16.0)
			var candidate := origin + direction * float(ring) * 24.0
			if not _sage_phase_landing_is_clear(candidate, query, space, shape_offset):
				continue
			var blocked_distance := float(ring - 1) * 24.0
			var clear_distance := float(ring) * 24.0
			for refinement in range(6):
				var midpoint := (blocked_distance + clear_distance) * 0.5
				if _sage_phase_landing_is_clear(origin + direction * midpoint, query, space, shape_offset):
					clear_distance = midpoint
				else:
					blocked_distance = midpoint
			_apply_sage_phase_landing(origin + direction * clear_distance)
			return
	# The phase entry is a checked fallback for unusually large/concave props.
	if _sage_phase_landing_is_clear(sage_phase_entry_position, query, space, shape_offset):
		_apply_sage_phase_landing(sage_phase_entry_position)


func _sage_phase_landing_is_clear(
	candidate: Vector2,
	query: PhysicsShapeQueryParameters2D,
	space: PhysicsDirectSpaceState2D,
	shape_offset: Vector2
) -> bool:
	if (
		candidate.x < FIELD_MARGIN or candidate.y < FIELD_MARGIN
		or candidate.x > battlefield_size.x - FIELD_MARGIN
		or candidate.y > battlefield_size.y - FIELD_MARGIN
	):
		return false
	query.transform.origin = get_parent().to_global(candidate) + shape_offset
	return space.intersect_shape(query, 1).is_empty()


func _apply_sage_phase_landing(candidate: Vector2) -> void:
	position = candidate
	velocity = Vector2.ZERO
	obstacle_stuck_timer = 0.0
	obstacle_escape_timer = 0.0
	if petrify_timer > 0.0:
		petrify_anchor = global_position


func _emit_sage_afterimage() -> void:
	if sage_afterimage_pool.is_empty() or not is_instance_valid(hero_sprite):
		return
	var ghost := sage_afterimage_pool[sage_afterimage_index]
	sage_afterimage_index = (sage_afterimage_index + 1) % sage_afterimage_pool.size()
	if not is_instance_valid(ghost):
		return
	ghost.stop()
	ghost.global_position = global_position
	ghost.global_rotation = 0.0
	ghost.scale = hero_sprite.scale
	ghost.offset = hero_sprite.offset
	ghost.flip_h = hero_sprite.flip_h
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.58)
	ghost.visible = true
	ghost.frame = 0
	ghost.play(&"trail")


func _on_sage_afterimage_finished(ghost: AnimatedSprite2D) -> void:
	if is_instance_valid(ghost):
		ghost.visible = false


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
	_play_archmage_basic_audio(element)
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


func _configure_archmage_basic_elements() -> void:
	archmage_basic_elements.clear()
	var configured = archmage_element_config.get(
		"elements",
		ARCHMAGE_DEFAULT_BASIC_ELEMENTS
	)
	if typeof(configured) == TYPE_ARRAY:
		for raw_element in configured:
			var element := String(raw_element)
			if (
				not element.is_empty()
				and element not in archmage_basic_elements
			):
				archmage_basic_elements.append(element)

	if archmage_basic_elements.is_empty():
		for element in ARCHMAGE_DEFAULT_BASIC_ELEMENTS:
			archmage_basic_elements.append(element)


func _roll_next_archmage_element() -> String:
	if archmage_basic_elements.is_empty():
		_configure_archmage_basic_elements()
	if archmage_basic_elements.is_empty():
		return "earth"

	var element_count := archmage_basic_elements.size()
	var chosen_index := 0
	if element_count > 1 and not archmage_last_element.is_empty():
		var last_index := archmage_basic_elements.find(archmage_last_element)
		if last_index >= 0:
			chosen_index = randi_range(0, element_count - 2)
			if chosen_index >= last_index:
				chosen_index += 1
		else:
			chosen_index = randi_range(0, element_count - 1)
	else:
		chosen_index = randi_range(0, element_count - 1)

	var chosen := archmage_basic_elements[chosen_index]
	archmage_last_element = chosen
	return chosen



func _update_archmage_skill_runtime(delta: float) -> void:
	for key in ARCHMAGE_SKILL_KEYS:
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
	var nearby_220 := _count_monsters_near(global_position, 220.0)
	var nearby_360 := _count_monsters_near(global_position, 360.0)
	var total_monsters := _get_monster_nodes_cached().size()

	var combustion_weight := 0.0
	var ice_bolt_weight := 0.0
	var earth_spikes_weight := 0.0
	var holy_power_weight := 0.0
	var chain_dagger_weight := 0.0
	var storm_weight := 0.0
	var harmony_weight := 0.0

	if _archmage_skill_ready("combustion"):
		combustion_weight = maxf(
			1.2 + float(nearby_220) * 0.65,
			0.05
		)
	if _archmage_skill_ready("ice_bolt") and is_instance_valid(target):
		ice_bolt_weight = maxf(2.2, 0.05)
	if _archmage_skill_ready("earth_spikes"):
		earth_spikes_weight = maxf(
			1.4 + minf(float(total_monsters) * 0.14, 2.2),
			0.05
		)
	if _archmage_skill_ready("holy_power"):
		holy_power_weight = maxf(
			1.1 + float(nearby_360) * 0.45,
			0.05
		)
	if (
		_archmage_skill_ready("chain_dagger")
		and not archmage_chain_dagger_active
		and total_monsters > 0
	):
		chain_dagger_weight = maxf(
			1.4 + minf(float(total_monsters) * 0.25, 2.6),
			0.05
		)
	if _archmage_skill_ready("storm"):
		storm_weight = maxf(
			1.0 + float(nearby_360) * 0.55,
			0.05
		)

	var cooling_count := 0
	for key in ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		if float(archmage_skill_cooldowns.get(key, 0.0)) > 0.0:
			cooling_count += 1
	if _archmage_skill_ready("harmony") and cooling_count >= 1:
		harmony_weight = maxf(
			3.0 + float(cooling_count) * 1.10,
			0.05
		)

	var total_score := (
		combustion_weight
		+ ice_bolt_weight
		+ earth_spikes_weight
		+ holy_power_weight
		+ chain_dagger_weight
		+ storm_weight
		+ harmony_weight
	)
	if total_score <= 0.0:
		return ""

	var roll := randf() * total_score
	if combustion_weight > 0.0:
		roll -= combustion_weight
		if roll <= 0.0:
			return "combustion"
	if ice_bolt_weight > 0.0:
		roll -= ice_bolt_weight
		if roll <= 0.0:
			return "ice_bolt"
	if earth_spikes_weight > 0.0:
		roll -= earth_spikes_weight
		if roll <= 0.0:
			return "earth_spikes"
	if holy_power_weight > 0.0:
		roll -= holy_power_weight
		if roll <= 0.0:
			return "holy_power"
	if chain_dagger_weight > 0.0:
		roll -= chain_dagger_weight
		if roll <= 0.0:
			return "chain_dagger"
	if storm_weight > 0.0:
		roll -= storm_weight
		if roll <= 0.0:
			return "storm"
	if harmony_weight > 0.0:
		return "harmony"

	if storm_weight > 0.0:
		return "storm"
	if chain_dagger_weight > 0.0:
		return "chain_dagger"
	if holy_power_weight > 0.0:
		return "holy_power"
	if earth_spikes_weight > 0.0:
		return "earth_spikes"
	if ice_bolt_weight > 0.0:
		return "ice_bolt"
	return "combustion"


func _archmage_skill_ready(skill_key: String) -> bool:
	if archmage_skill_config.is_empty():
		return false
	var config: Dictionary = archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return false
	return float(archmage_skill_cooldowns.get(skill_key, 0.0)) <= 0.0


func _use_archmage_skill(skill_key: String) -> void:
	if silence_timer > 0.0:
		return
	_cast_archmage_skill_internal(skill_key, true, true)


func _cast_archmage_skill_internal(
	skill_key: String,
	consume_gauge: bool,
	trigger_multicast: bool
) -> bool:
	if silence_timer > 0.0:
		return false
	if charm_timer > 0.0:
		return false
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
		archmage_orbit_order.clear()
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
	archmage_multicast_candidates.clear()
	for key in ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		if key == origin_skill:
			continue
		if not archmage_skill_config.has(key):
			continue
		if key == "chain_dagger" and archmage_chain_dagger_active:
			continue
		archmage_multicast_candidates.append(key)

	if archmage_multicast_candidates.is_empty():
		return

	archmage_multicast_candidates.shuffle()
	archmage_multicast_active = true
	var wanted := mini(
		archmage_multicast_stacks,
		archmage_multicast_candidates.size()
	)
	var casted := 0

	while (
		casted < wanted
		and not archmage_multicast_candidates.is_empty()
	):
		await get_tree().create_timer(0.30).timeout
		if not is_inside_tree() or current_hp <= 0:
			break

		var extra_skill := String(
			archmage_multicast_candidates.pop_back()
		)
		if _cast_archmage_skill_internal(extra_skill, false, false):
			casted += 1

	archmage_multicast_candidates.clear()
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
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_combustion_charge_audio)
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
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_combustion_release_audio)
	_end_archmage_casting_sequence()


func _cast_archmage_ice_bolt(config: Dictionary, empowered: bool) -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_ice_bolt_audio)
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
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_ice_impact_audio)
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


func _capture_delayed_skill_source() -> Vector3i:
	# Scalar reservation: no RefCounted locals retained by abandoned awaits.
	if not is_inside_tree() or is_queued_for_deletion() or current_hp <= 0:
		return Vector3i(-1, -1, -1)
	var scope := get_parent()
	if not is_instance_valid(scope) or scope.is_queued_for_deletion():
		return Vector3i(-1, -1, -1)
	var tracked := scope.has_method("get_battle_entity_handle") or scope.has_method("resolve_battle_entity")
	if not tracked:
		return Vector3i.ZERO
	if not scope.has_method("get_battle_entity_handle") or not scope.has_method("resolve_battle_entity"):
		return Vector3i(-1, -1, -1)
	var handle: Vector3i = scope.call("get_battle_entity_handle", self)
	if handle == Vector3i.ZERO or scope.call("resolve_battle_entity", handle) != self:
		return Vector3i(-1, -1, -1)
	return handle

func _is_delayed_skill_life_current(source_life: Vector3i, source_scope_id: int) -> bool:
	if not is_inside_tree() or is_queued_for_deletion() or source_life.x < 0:
		return false
	var scope := get_parent()
	if not is_instance_valid(scope) or scope.is_queued_for_deletion() or scope.get_instance_id() != source_scope_id:
		return false
	if source_life == Vector3i.ZERO:
		return not scope.has_method("get_battle_entity_handle") and not scope.has_method("resolve_battle_entity")
	return scope.has_method("resolve_battle_entity") and scope.call("resolve_battle_entity", source_life) == self

func _is_delayed_skill_source_current(source_life: Vector3i, source_scope_id: int) -> bool:
	return current_hp > 0 and _is_delayed_skill_life_current(source_life, source_scope_id)

func _resolve_archmage_ice_pillars(hit_position: Vector2, empowered: bool) -> void:
	var source_life := _capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := get_parent().get_instance_id()
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
		if not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		var angle := randf_range(0.0, TAU)
		var position := hit_position + Vector2.from_angle(angle) * randf_range(25.0, spawn_radius)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect4",
			"ice", 1, 6, 20.0, false, position, Vector2(0.70, 0.70)
		)
		_damage_monsters_in_radius(position, hit_radius, pillar_damage, source_life, source_scope_id)
		if not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await get_tree().create_timer(0.045).timeout


func _cast_archmage_earth_spikes(config: Dictionary, empowered: bool) -> void:
	var source_life := _capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := get_parent().get_instance_id()
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
		if not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		var position: Vector2 = cast_origin + direction * spacing * float(index + 1)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect1",
			"earth", 1, 11, 22.0, false, position, Vector2(0.72, 0.72)
		)
		_play_archmage_earth_spike_audio()
		_damage_monsters_in_radius_once(position, radius, spike_damage, hit_ids, source_life, source_scope_id)
		if not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await get_tree().create_timer(spike_delay).timeout

	if _is_delayed_skill_source_current(source_life, source_scope_id):
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
				if not _is_delayed_skill_source_current(source_life, source_scope_id):
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
				_play_archmage_earth_spike_audio()
				_damage_monsters_in_radius_once(
					left_position,
					radius,
					spike_damage,
					hit_ids,
					source_life,
					source_scope_id
				)

				if not _is_delayed_skill_source_current(source_life, source_scope_id):
					break
				_spawn_archmage_fx(
					"res://assets/art/heroes/stage5_archmage/frames/effect1",
					"earth", 1, 11, 22.0, false,
					right_position, Vector2(0.72, 0.72)
				)
				_play_archmage_earth_spike_audio()
				_damage_monsters_in_radius_once(
					right_position,
					radius,
					spike_damage,
					hit_ids,
					source_life,
					source_scope_id
				)
				if not _is_delayed_skill_source_current(source_life, source_scope_id):
					break
				await get_tree().create_timer(spike_delay).timeout

	# Old tasks must not decrement a new life's casting counter.
	if _is_delayed_skill_life_current(source_life, source_scope_id):
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
	var search_radius_sq := search_radius * search_radius
	_fill_monster_nodes_near(
		global_position,
		search_radius,
		archmage_query_candidates
	)

	for node in archmage_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var distance_sq: float = global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > search_radius_sq:
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

	archmage_query_candidates.clear()
	return best


func _cast_archmage_holy_power(config: Dictionary, empowered: bool) -> void:
	var source_life := _capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := get_parent().get_instance_id()
	var source_scope := get_parent()
	var tracked_targets := source_scope.has_method("get_battle_entity_handle")
	_begin_archmage_casting_sequence()

	var cluster_target: Node2D = _find_archmage_holy_cluster_target(config)
	if not is_instance_valid(cluster_target):
		if _is_delayed_skill_life_current(source_life, source_scope_id):
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
	var hit_radius_sq := hit_radius * hit_radius

	for index in range(count):
		if not _is_delayed_skill_source_current(source_life, source_scope_id):
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
		_play_archmage_holy_burst_audio()

		_fill_monster_nodes_near(
			position,
			hit_radius,
			archmage_query_candidates
		)
		for node in archmage_query_candidates:
			if not _is_delayed_skill_source_current(source_life, source_scope_id):
				break
			if not is_instance_valid(node):
				continue
			if not HERO_TARGET_POLICY.is_detectable(node):
				continue
			var monster := node as Node2D
			if monster == null or not monster.has_method("take_damage"):
				continue
			if position.distance_squared_to(monster.global_position) > hit_radius_sq:
				continue

			var dealt: int = base_damage
			if MONSTER_CATALOG.is_undead_node(monster):
				dealt = maxi(
					1,
					int(round(
						float(dealt)
						* float(config.get("undead_damage_multiplier", 1.70))
					))
				)

			# Capture a scalar handle only; damage callbacks may recycle this Node.
			var victim_handle := Vector3i.ZERO
			if tracked_targets:
				victim_handle = source_scope.call("get_battle_entity_handle", monster)
			monster.call("take_damage", dealt)
			if not _is_delayed_skill_source_current(source_life, source_scope_id):
				break
			if not is_instance_valid(monster) or monster.is_queued_for_deletion():
				continue
			if tracked_targets and (
				victim_handle == Vector3i.ZERO
				or source_scope.call("resolve_battle_entity", victim_handle) != monster
			):
				continue
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
		archmage_query_candidates.clear()

		if not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await get_tree().create_timer(
			maxf(float(config.get("burst_delay", 0.09)), 0.02)
		).timeout

	if _is_delayed_skill_life_current(source_life, source_scope_id):
		_end_archmage_casting_sequence()

func _get_archmage_chain_dagger_targets(
	max_count: int,
	search_radius: float
) -> Array[Node2D]:
	archmage_chain_target_candidates.clear()
	archmage_chain_target_results.clear()
	var radius_sq := search_radius * search_radius
	_fill_monster_nodes_near(
		global_position,
		search_radius,
		archmage_query_candidates
	)
	for node in archmage_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		archmage_chain_target_candidates.append(monster)
	archmage_query_candidates.clear()

	if archmage_chain_target_candidates.is_empty():
		return archmage_chain_target_results

	if (
		HERO_TARGET_POLICY.is_detectable(target)
		and target.is_in_group("monsters")
		and global_position.distance_squared_to(target.global_position)
		<= radius_sq
	):
		archmage_chain_target_results.append(target)

	while (
		archmage_chain_target_results.size() < max_count
		and archmage_chain_target_results.size()
		< archmage_chain_target_candidates.size()
	):
		var best: Node2D = null
		var best_score := -INF
		for candidate in archmage_chain_target_candidates:
			if candidate in archmage_chain_target_results:
				continue
			var direction := global_position.direction_to(
				candidate.global_position
			)
			if direction.length_squared() <= 0.001:
				continue

			var min_angle := PI
			if not archmage_chain_target_results.is_empty():
				for chosen in archmage_chain_target_results:
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
		archmage_chain_target_results.append(best)

	if archmage_chain_target_results.is_empty():
		archmage_chain_target_results.append(
			archmage_chain_target_candidates[0]
		)
	return archmage_chain_target_results


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
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_chain_launch_audio)

	for current_target in targets:
		if not is_instance_valid(current_target):
			notify_archmage_chain_dagger_finished()
			continue
		var direction := global_position.direction_to(
			current_target.global_position
		)
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT

		var projectile := _acquire_projectile(
			ARCHMAGE_SKILL_PROJECTILE_SCENE,
			"archmage_chain_dagger_projectile"
		)
		if projectile == null:
			notify_archmage_chain_dagger_finished()
			continue
		if not projectile.is_in_group(
			"archmage_chain_dagger_projectile"
		):
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
	if silence_timer > 0.0:
		return
	if archmage_blink_stacks <= 0:
		return

	var start_position := global_position
	var repulsion := Vector2.ZERO
	_fill_monster_nodes_near(
		global_position,
		460.0,
		archmage_query_candidates
	)
	for node in archmage_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	archmage_query_candidates.clear()

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

	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_blink_audio)
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
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_harmony_audio)
	for key in ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		archmage_skill_cooldowns[key] = 0.0
	_add_archmage_gauge(maxf(float(config.get("gauge_refund", 50.0)), 0.0))
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect7",
		"orb", 8, 5, 16.0, false, global_position, Vector2(0.82, 0.82)
	)


func _cast_archmage_storm(config: Dictionary, empowered: bool) -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(archmage_storm_audio)
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
	if not already_owned:
		archmage_orbit_order.append(element)

	if (
		already_owned
		and archmage_element_cycle_stacks > 0
		and randf() <= 0.25 * float(archmage_element_cycle_stacks)
	):
		var missing: Array[String] = []
		for candidate in ARCHMAGE_ORB_ELEMENTS:
			if not bool(archmage_element_orbs.get(candidate, false)):
				missing.append(candidate)
		if not missing.is_empty():
			var granted := String(missing.pick_random())
			archmage_element_orbs[granted] = true
			archmage_orbit_order.append(granted)

	_refresh_archmage_orbit_visuals()

func _archmage_has_all_element_orbs() -> bool:
	for element in ARCHMAGE_ORB_ELEMENTS:
		if not bool(archmage_element_orbs.get(element, false)):
			return false
	return true


func _refresh_archmage_orbit_visuals() -> void:
	for element in ARCHMAGE_ORB_ELEMENTS:
		var existing = archmage_orbit_sprites.get(element)
		if is_instance_valid(existing):
			existing.visible = false

	if hero_archetype != "archmage_elementalist":
		return

	for element in archmage_orbit_order:
		if not bool(archmage_element_orbs.get(element, false)):
			continue
		var frame_index := int(ARCHMAGE_ORB_FRAME_INDEX.get(element, 0))
		if frame_index <= 0:
			continue

		var sprite := archmage_orbit_sprites.get(element) as Sprite2D
		if not is_instance_valid(sprite):
			var texture := _load_stage1_texture(
				"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_%02d.png" % frame_index
			)
			if texture == null:
				continue
			sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(0.20, 0.20)
			sprite.z_index = 8
			add_child(sprite)
			archmage_orbit_sprites[element] = sprite
		sprite.visible = true

	_update_archmage_orbit_positions()


func _update_archmage_orbit_positions() -> void:
	var count := 0
	for element in archmage_orbit_order:
		if not bool(archmage_element_orbs.get(element, false)):
			continue
		var sprite := archmage_orbit_sprites.get(element) as Sprite2D
		if is_instance_valid(sprite) and sprite.visible:
			count += 1
	if count <= 0:
		return

	var index := 0
	for element in archmage_orbit_order:
		if not bool(archmage_element_orbs.get(element, false)):
			continue
		var sprite := archmage_orbit_sprites.get(element) as Sprite2D
		if not is_instance_valid(sprite) or not sprite.visible:
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


func _damage_monsters_in_radius(origin: Vector2, radius: float, damage: int, source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0) -> void:
	var radius_sq := radius * radius
	_fill_monster_nodes_near(origin, radius, _combat_monster_scratch)
	for node in _combat_monster_scratch:
		if source_scope_id != 0 and not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if origin.distance_squared_to(monster.global_position) <= radius_sq:
			monster.call("take_damage", damage)
	_combat_monster_scratch.clear()

func _damage_monsters_in_radius_once(
	origin: Vector2,
	radius: float,
	damage: int,
	hit_ids: Dictionary,
	source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0
) -> void:
	var radius_sq := radius * radius
	_fill_monster_nodes_near(origin, radius, _combat_monster_scratch)
	for node in _combat_monster_scratch:
		if source_scope_id != 0 and not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	_combat_monster_scratch.clear()

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
	_fill_monster_nodes_in_rect(query_rect, _combat_monster_scratch)

	for node in _combat_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var t := clampf((monster.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var closest := start + segment * t
		if monster.global_position.distance_squared_to(closest) <= half_width_sq:
			monster.call("take_damage", damage)
	_combat_monster_scratch.clear()

func _find_farthest_monster_from_point(origin: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := -1.0
	for node in _get_monster_nodes_cached():
		if not HERO_TARGET_POLICY.is_detectable(node):
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
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	current_hp = mini(current_hp + _get_reduced_healing(adjusted_amount), max_hp)
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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return
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
	if silence_timer > 0.0:
		return
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
	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"arcane_field")

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

	var radius_sq := radius * radius
	_fill_monster_nodes_near(
		global_position,
		radius,
		_combat_monster_scratch
	)
	for node in _combat_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		if not node.has_method("take_damage"):
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue

		monster.call("take_damage", damage)
	_combat_monster_scratch.clear()

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
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return
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
	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"barrier")

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
	if not is_instance_valid(purifier_orb_create_audio):
		purifier_orb_create_audio = _create_purifier_audio_player(
			String(purifier_orb_config.get(
				"create_audio_path",
				PURIFIER_ORB_CREATE_AUDIO_PATH
			)),
			-12.0,
			1.04
		)
	if not is_instance_valid(purifier_orb_explosion_audio):
		purifier_orb_explosion_audio = _create_purifier_audio_player(
			String(purifier_orb_config.get(
				"explosion_audio_path",
				PURIFIER_ORB_EXPLOSION_AUDIO_PATH
			)),
			-10.0,
			0.96
		)
	if not is_instance_valid(purifier_cleansing_audio):
		purifier_cleansing_audio = _create_purifier_audio_player(
			String(purifier_cleansing_config.get(
				"audio_path",
				PURIFIER_CLEANSING_AUDIO_PATH
			)),
			-12.0,
			1.18
		)
	if not is_instance_valid(purifier_gungnir_charge_audio):
		purifier_gungnir_charge_audio = _create_purifier_audio_player(
			String(purifier_gungnir_config.get(
				"charge_audio_path",
				PURIFIER_GUNGNIR_CHARGE_AUDIO_PATH
			)),
			-10.0,
			1.05
		)
	if not is_instance_valid(purifier_gungnir_flight_audio):
		purifier_gungnir_flight_audio = _create_purifier_audio_player(
			String(purifier_gungnir_config.get(
				"flight_audio_path",
				PURIFIER_GUNGNIR_FLIGHT_AUDIO_PATH
			)),
			-9.0,
			1.12
		)
	if not is_instance_valid(purifier_gungnir_explosion_audio):
		purifier_gungnir_explosion_audio = _create_purifier_audio_player(
			String(purifier_gungnir_config.get(
				"explosion_audio_path",
				PURIFIER_GUNGNIR_EXPLOSION_AUDIO_PATH
			)),
			-8.0,
			0.78
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


func _get_purifier_augment_stacks(augment_id: String) -> int:
	if hero_archetype != "cleric_purifier":
		return 0
	return maxi(int(build_counts.get(augment_id, 0)), 0)


func _get_purifier_crown_effect_multiplier() -> float:
	return (
		0.85
		if _get_purifier_augment_stacks("purifier_radiant_crown") > 0
		else 1.0
	)


func _get_purifier_crown_max_stacks() -> int:
	return maxi(
		int(purifier_crown_config.get("max_stacks", 5))
		+ _get_purifier_augment_stacks("purifier_radiant_crown"),
		1
	)


func _get_purifier_orb_damage_multiplier() -> float:
	return (
		0.50
		if _get_purifier_augment_stacks("purifier_book_of_purification") > 0
		else 1.0
	)


func _get_purifier_orb_range_multiplier() -> float:
	return (
		0.50
		if _get_purifier_augment_stacks("purifier_book_of_purification") > 0
		else 1.0
	)


func _get_purifier_orb_explosion_radius() -> float:
	return maxf(
		float(purifier_orb_config.get("explosion_radius", 137.5))
		* _get_purifier_orb_range_multiplier(),
		1.0
	)


func _get_purifier_skill_cooldown_multiplier() -> float:
	if hero_archetype != "cleric_purifier" or purifier_crown_stacks <= 0:
		return 1.0
	return maxf(
		1.0
		- float(purifier_crown_config.get("cooldown_reduction_per_stack", 0.04))
		* _get_purifier_crown_effect_multiplier()
		* float(purifier_crown_stacks),
		0.20
	)


func _get_purifier_move_speed_multiplier() -> float:
	var multiplier := 1.0
	if hero_archetype == "cleric_purifier" and purifier_crown_stacks > 0:
		multiplier *= 1.0 + maxf(
			float(purifier_crown_config.get("move_speed_per_stack", 0.02)),
			0.0
		) * _get_purifier_crown_effect_multiplier() * float(purifier_crown_stacks)
	if hero_archetype == "grand_sage_astra" and sage_phase_active:
		multiplier *= maxf(
			float(sage_config.get("phase_move_speed_multiplier", 1.40)),
			1.0
		)
	return multiplier

func _is_purifier_undead_target(target_node: Node) -> bool:
	return MONSTER_CATALOG.is_undead_node(target_node)


func get_purifier_holy_damage_multiplier(target_node: Node = null) -> float:
	if hero_archetype != "cleric_purifier":
		return 1.0
	var crown_effect_multiplier := _get_purifier_crown_effect_multiplier()
	var multiplier := (
		1.0
		+ maxf(
			float(purifier_crown_config.get("holy_damage_per_stack", 0.05)),
			0.0
		) * crown_effect_multiplier * float(purifier_crown_stacks)
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
			) * crown_effect_multiplier * float(purifier_crown_stacks)
		)
	var broken_sanctuary_stacks := _get_purifier_augment_stacks(
		"purifier_broken_sanctuary"
	)
	if broken_sanctuary_stacks > 0 and purifier_broken_sanctuary_timer > 0.0:
		multiplier *= 1.0 + 0.06 * float(broken_sanctuary_stacks)
	return multiplier

func notify_monster_kill(_monster_type: String = "") -> void:
	if is_dying or current_hp <= 0:
		return
	if hero_archetype == "grand_sage_astra":
		_add_sage_gauge(
			maxf(float(sage_config.get("gauge_per_kill", 1.0)), 0.0)
		)
		return
	if hero_archetype != "cleric_purifier":
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
	if silence_timer > 0.0:
		return
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
	_fill_monster_nodes_near(
		global_position,
		radius,
		_combat_monster_scratch
	)
	for node in _combat_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
		LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(
			monster.get_meta("gunner_slow_multiplier", 1.0)
		)
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)
	_combat_monster_scratch.clear()


func _end_purifier_protection(broken: bool) -> void:
	if not purifier_protection_active and shield_hp <= 0.0:
		return
	if broken and not purifier_protection_break_triggered:
		purifier_protection_break_triggered = true
		purifier_protection_break_count += 1
		_trigger_purifier_protection_break_pulse()
		if _get_purifier_augment_stacks("purifier_broken_sanctuary") > 0:
			purifier_broken_sanctuary_timer = 6.0
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
	if silence_timer > 0.0:
		return
	if (
		hero_archetype != "cleric_purifier"
		or purifier_crown_config.is_empty()
		or purifier_crown_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return
	var max_stacks := _get_purifier_crown_max_stacks()
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


func _clear_purifier_orb_runtime() -> void:
	for raw_link in purifier_orb_links.values():
		var link := raw_link as Node
		if is_instance_valid(link):
			link.queue_free()
	purifier_orb_links.clear()

	for orb in purifier_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	purifier_orbs.clear()
	purifier_orb_chain_queue.clear()
	purifier_orb_chain_active = false
	purifier_orb_chain_timer = 0.0
	purifier_orb_chain_step = 0

	for entry in purifier_prism_active:
		var prism_orb = entry.get("orb", null)
		if is_instance_valid(prism_orb):
			prism_orb.queue_free()
	purifier_prism_active.clear()
	purifier_prism_launch_queue.clear()
	purifier_prism_launch_timer = 0.0


func _is_purifier_orb_active(orb: Node2D) -> bool:
	return (
		is_instance_valid(orb)
		and not orb.is_queued_for_deletion()
		and orb.has_method("is_network_active")
		and bool(orb.call("is_network_active"))
	)


func _get_active_purifier_orbs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for orb in purifier_orbs:
		if _is_purifier_orb_active(orb):
			result.append(orb)
	return result


func _purifier_orb_link_key(a: Node2D, b: Node2D) -> String:
	var a_id := a.get_instance_id()
	var b_id := b.get_instance_id()
	if a_id > b_id:
		var swap := a_id
		a_id = b_id
		b_id = swap
	return "%d:%d" % [a_id, b_id]


func _refresh_purifier_orb_links() -> void:
	var active_orbs := _get_active_purifier_orbs()
	var link_distance := maxf(
		float(purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var seen_links: Dictionary = {}
	var link_effect_dir := String(
		purifier_orb_config.get(
			"link_effect_dir",
			"%s/effect5" % STAGE5_FRAME_DIR
		)
	)
	var link_vertical_scale := maxf(
		float(purifier_orb_config.get("link_vertical_scale", 0.58)),
		0.05
	)
	var pilgrims_path_stacks := _get_purifier_augment_stacks(
		"purifier_pilgrims_path"
	)
	var link_damage_ratio := (
		0.10 + 0.05 * float(pilgrims_path_stacks - 1)
		if pilgrims_path_stacks > 0
		else 0.0
	)
	var parent := get_parent()
	if not is_instance_valid(parent):
		return

	for first_index in range(active_orbs.size()):
		var first := active_orbs[first_index]
		for second_index in range(first_index + 1, active_orbs.size()):
			var second := active_orbs[second_index]
			if (
				first.global_position.distance_squared_to(second.global_position)
				> link_distance_sq
			):
				continue

			var key := _purifier_orb_link_key(first, second)
			seen_links[key] = true
			if purifier_orb_links.has(key):
				var existing_link = purifier_orb_links.get(key)
				if (
					is_instance_valid(existing_link)
					and existing_link.has_method("configure_damage")
				):
					existing_link.call(
						"configure_damage",
						self,
						link_damage_ratio,
						0.22,
						24.0
					)
				continue

			var link := PURIFIER_ORB_LINK_SCENE.instantiate() as Node2D
			if link == null:
				continue
			parent.add_child(link)
			link.call(
				"setup",
				first.global_position,
				second.global_position,
				link_effect_dir,
				link_vertical_scale,
				self,
				link_damage_ratio,
				0.22,
				24.0
			)
			purifier_orb_links[key] = link

	for raw_key in purifier_orb_links.keys():
		var key := String(raw_key)
		if seen_links.has(key):
			continue
		var stale_link = purifier_orb_links.get(key)
		if is_instance_valid(stale_link):
			stale_link.queue_free()
		purifier_orb_links.erase(key)


func _on_purifier_orb_settled(orb: Node2D) -> void:
	if not _is_purifier_orb_active(orb):
		return
	_refresh_purifier_orb_links()
	_try_start_purifier_orb_chain_from(orb)


func _on_purifier_orb_deactivated(_orb: Node2D) -> void:
	_refresh_purifier_orb_links()


func _on_purifier_orb_finished(orb: Node2D) -> void:
	purifier_orbs.erase(orb)
	purifier_orb_chain_queue.erase(orb)
	_refresh_purifier_orb_links()


func _clamp_purifier_orb_target_position(candidate: Vector2) -> Vector2:
	var throw_range := maxf(
		float(purifier_orb_config.get("throw_range", 820.0)),
		1.0
	)
	var offset := candidate - global_position
	if offset.length_squared() > throw_range * throw_range:
		offset = offset.normalized() * throw_range
		candidate = global_position + offset

	var clamped := Vector2(
		clampf(
			candidate.x,
			FIELD_MARGIN,
			maxf(battlefield_size.x - FIELD_MARGIN, FIELD_MARGIN)
		),
		clampf(
			candidate.y,
			FIELD_MARGIN,
			maxf(battlefield_size.y - FIELD_MARGIN, FIELD_MARGIN)
		)
	)
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("_clamp_manual_spawn_position")
	):
		var battle_clamped = battle.call(
			"_clamp_manual_spawn_position",
			clamped
		)
		if typeof(battle_clamped) == TYPE_VECTOR2:
			clamped = battle_clamped as Vector2
	return clamped


func _purifier_orb_connection_count(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	var link_distance := maxf(
		float(purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var count := 0
	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			<= link_distance_sq
		):
			count += 1
	return count


func _purifier_orb_resulting_component_size(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	var link_distance := maxf(
		float(purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var visited: Dictionary = {}
	var frontier: Array[Node2D] = []

	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			<= link_distance_sq
		):
			frontier.append(orb)

	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		if not _is_purifier_orb_active(current):
			continue
		var current_id := current.get_instance_id()
		if visited.has(current_id):
			continue
		visited[current_id] = true

		for candidate in active_orbs:
			if (
				not _is_purifier_orb_active(candidate)
				or visited.has(candidate.get_instance_id())
				or current.global_position.distance_squared_to(
					candidate.global_position
				) > link_distance_sq
			):
				continue
			frontier.append(candidate)

	# Include the candidate orb itself.
	return visited.size() + 1


func _purifier_orb_position_has_spacing(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> bool:
	var min_spacing := maxf(
		float(purifier_orb_config.get("min_orb_spacing", 96.0)),
		1.0
	)
	var min_spacing_sq := min_spacing * min_spacing
	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			< min_spacing_sq
		):
			return false
	return true


func _choose_purifier_orb_target_position() -> Vector2:
	var throw_range := maxf(
		float(purifier_orb_config.get("throw_range", 820.0)),
		1.0
	)
	var blast_radius := _get_purifier_orb_explosion_radius()
	var link_distance := maxf(
		float(purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var active_orbs := _get_active_purifier_orbs()
	var candidates: Array[Vector2] = []

	if is_instance_valid(target) and not target.is_queued_for_deletion():
		candidates.append(target.global_position)

	var monsters := _get_monster_nodes_near(global_position, throw_range)
	var monster_sample_count := 0
	for node in monsters:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		candidates.append(monster.global_position)
		monster_sample_count += 1
		if monster_sample_count >= 12:
			break

	for orb in active_orbs:
		var desired_direction := Vector2.ZERO
		if is_instance_valid(target):
			desired_direction = orb.global_position.direction_to(
				target.global_position
			)
		if desired_direction.length_squared() <= 0.001:
			desired_direction = global_position.direction_to(
				orb.global_position
			)
		if desired_direction.length_squared() <= 0.001:
			desired_direction = Vector2.from_angle(randf_range(0.0, TAU))

		for angle_offset in [-0.70, -0.35, 0.0, 0.35, 0.70]:
			candidates.append(
				orb.global_position
				+ desired_direction.rotated(angle_offset)
				* link_distance * 0.72
			)

	for first_index in range(active_orbs.size()):
		for second_index in range(first_index + 1, active_orbs.size()):
			var first := active_orbs[first_index]
			var second := active_orbs[second_index]
			if (
				first.global_position.distance_squared_to(second.global_position)
				<= (link_distance * 2.0) * (link_distance * 2.0)
			):
				candidates.append(
					first.global_position.lerp(second.global_position, 0.5)
				)

	var random_center := global_position
	if is_instance_valid(target):
		random_center = target.global_position
	for _sample_index in range(8):
		candidates.append(
			random_center
			+ Vector2.from_angle(randf_range(0.0, TAU))
			* randf_range(80.0, minf(blast_radius * 1.65, throw_range))
		)

	if candidates.is_empty():
		var fallback_direction := (
			Vector2.LEFT
			if hero_sprite.flip_h
			else Vector2.RIGHT
		)
		return _clamp_purifier_orb_target_position(
			global_position + fallback_direction * minf(420.0, throw_range)
		)

	var hold_chain := (
		active_orbs.size() >= 2
		and randf()
		< clampf(
			float(purifier_orb_config.get("chain_hold_chance", 0.25)),
			0.0,
			1.0
		)
	)
	var best_position := Vector2.ZERO
	var best_score := -INF
	var found := false

	for pass_index in range(2):
		var avoid_multi_link := hold_chain and pass_index == 0
		for raw_candidate in candidates:
			var candidate := _clamp_purifier_orb_target_position(raw_candidate)
			if not _purifier_orb_position_has_spacing(candidate, active_orbs):
				continue

			var link_count := _purifier_orb_connection_count(
				candidate,
				active_orbs
			)
			var resulting_component_size := (
				_purifier_orb_resulting_component_size(
					candidate,
					active_orbs
				)
			)
			if avoid_multi_link and resulting_component_size >= 3:
				continue

			var monster_count := _count_monsters_near(
				candidate,
				blast_radius
			)
			var score := float(monster_count) * 3.0
			if avoid_multi_link:
				score += (
					2.5
					if link_count == 0
					else 1.2
				)
			else:
				if resulting_component_size == 2:
					score += maxf(
						float(
							purifier_orb_config.get(
								"partial_link_score_bonus",
								4.0
							)
						),
						0.0
					)
				score += (
					float(link_count)
					* maxf(
						float(
							purifier_orb_config.get(
								"link_score_per_neighbor",
								5.0
							)
						),
						0.0
					)
				)
				if resulting_component_size >= 3:
					score += (
						maxf(
							float(
								purifier_orb_config.get(
									"chain_ready_score_bonus",
									12.0
								)
							),
							0.0
						)
						+ float(resulting_component_size - 3)
						* maxf(
							float(
								purifier_orb_config.get(
									"extra_chain_orb_score_bonus",
									5.0
								)
							),
							0.0
						)
					)

			score -= (
				global_position.distance_to(candidate)
				/ throw_range
			) * 0.30
			score += randf_range(-0.35, 0.35)

			if not found or score > best_score:
				found = true
				best_score = score
				best_position = candidate

		if found:
			break

	if found:
		return best_position

	var fallback := candidates[0]
	return _clamp_purifier_orb_target_position(fallback)


func _spawn_purifier_network_orb(destination: Vector2) -> bool:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return false

	var orb := PURIFIER_ORB_SCENE.instantiate() as Node2D
	if orb == null:
		return false

	purifier_orb_install_serial += 1
	parent.add_child(orb)
	orb.connect(
		"settled",
		Callable(self, "_on_purifier_orb_settled")
	)
	orb.connect(
		"deactivated",
		Callable(self, "_on_purifier_orb_deactivated")
	)
	orb.connect(
		"finished",
		Callable(self, "_on_purifier_orb_finished")
	)

	var start_position := global_position + Vector2(0.0, -42.0)
	orb.call(
		"setup",
		self,
		start_position,
		destination,
		maxf(
			float(purifier_orb_config.get("projectile_speed", 380.0)),
			1.0
		),
		maxf(float(purifier_orb_config.get("duration", 80.0)), 0.1),
		_get_purifier_orb_explosion_radius(),
		purifier_orb_install_serial,
		String(
			purifier_orb_config.get(
				"effect_dir",
				"%s/effect2" % STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(purifier_orb_config.get("visual_scale", 0.45)),
			0.05
		)
	)
	purifier_orbs.append(orb)
	return true


func _cast_purifier_orb() -> void:
	if silence_timer > 0.0:
		return
	if (
		hero_archetype != "cleric_purifier"
		or purifier_orb_config.is_empty()
		or purifier_orb_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return

	var book_stacks := _get_purifier_augment_stacks("purifier_book_of_purification")
	var orb_count := 1 + book_stacks
	var primary_destination := _choose_purifier_orb_target_position()
	var spacing := maxf(
		float(purifier_orb_config.get("min_orb_spacing", 96.0)) * 1.20,
		72.0
	)
	var launched := 0
	var reserved_positions: Array[Vector2] = []

	for orb_index in range(orb_count):
		var destination := primary_destination
		if orb_index > 0:
			var extra_count := maxi(orb_count - 1, 1)
			var angle := (
				TAU * float(orb_index - 1) / float(extra_count)
				+ 0.35
			)
			destination = _clamp_purifier_orb_target_position(
				primary_destination
				+ Vector2.from_angle(angle)
				* spacing
				* (1.0 + 0.12 * float(orb_index - 1))
			)

		var adjustment_index := 0
		var needs_adjustment := true
		while needs_adjustment and adjustment_index < 4:
			needs_adjustment = false
			for reserved in reserved_positions:
				if destination.distance_to(reserved) < spacing * 0.85:
					needs_adjustment = true
					break
			if needs_adjustment:
				destination = _clamp_purifier_orb_target_position(
					destination
					+ Vector2.from_angle(
						0.85 + float(adjustment_index) * 1.70
					) * spacing * 0.75
				)
				adjustment_index += 1

		reserved_positions.append(destination)
		if _spawn_purifier_network_orb(destination):
			launched += 1

	if launched <= 0:
		return

	purifier_orb_cooldown = (
		maxf(float(purifier_orb_config.get("cooldown", 10.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_orb_create_audio)

func _get_purifier_orb_component(start_orb: Node2D) -> Array[Node2D]:
	var component: Array[Node2D] = []
	if not _is_purifier_orb_active(start_orb):
		return component

	var link_distance := maxf(
		float(purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	component.append(start_orb)
	var cursor := 0

	while cursor < component.size():
		var current := component[cursor]
		cursor += 1
		for candidate in purifier_orbs:
			if (
				not _is_purifier_orb_active(candidate)
				or candidate in component
			):
				continue
			if (
				current.global_position.distance_squared_to(
					candidate.global_position
				)
				<= link_distance_sq
			):
				component.append(candidate)

	return component


func _purifier_orb_install_index(orb: Node2D) -> int:
	if (
		is_instance_valid(orb)
		and orb.has_method("get_install_index")
	):
		return int(orb.call("get_install_index"))
	return 0


func _sort_purifier_orbs_by_install_order(
	orbs: Array[Node2D]
) -> void:
	for index in range(1, orbs.size()):
		var current := orbs[index]
		var current_order := _purifier_orb_install_index(current)
		var insert_index := index - 1
		while (
			insert_index >= 0
			and _purifier_orb_install_index(orbs[insert_index])
			> current_order
		):
			orbs[insert_index + 1] = orbs[insert_index]
			insert_index -= 1
		orbs[insert_index + 1] = current


func _try_start_purifier_orb_chain_from(orb: Node2D) -> void:
	if silence_timer > 0.0:
		return
	if purifier_orb_chain_active:
		return
	var component := _get_purifier_orb_component(orb)
	if component.size() < 3:
		return
	_start_purifier_orb_chain(component)


func _try_start_any_purifier_orb_chain() -> void:
	if silence_timer > 0.0:
		return
	if purifier_orb_chain_active:
		return
	for orb in purifier_orbs:
		if not _is_purifier_orb_active(orb):
			continue
		var component := _get_purifier_orb_component(orb)
		if component.size() >= 3:
			_start_purifier_orb_chain(component)
			return


func _start_purifier_orb_chain(component: Array[Node2D]) -> void:
	if silence_timer > 0.0:
		return
	if purifier_orb_chain_active or component.size() < 3:
		return

	_sort_purifier_orbs_by_install_order(component)
	purifier_orb_chain_queue.clear()
	for orb in component:
		if not _is_purifier_orb_active(orb):
			continue
		orb.call("reserve_for_chain")
		purifier_orb_chain_queue.append(orb)

	if purifier_orb_chain_queue.size() < 3:
		purifier_orb_chain_queue.clear()
		return

	purifier_orb_chain_active = true
	purifier_orb_chain_timer = 0.0
	purifier_orb_chain_step = 0
	_advance_purifier_orb_chain()


func _get_purifier_orb_chain_interval() -> float:
	var base_interval := maxf(
		float(purifier_orb_config.get("chain_interval", 1.0)),
		0.05
	)
	return base_interval / maxf(
		purifier_orb_chain_speed_multiplier,
		0.05
	)


func set_purifier_orb_chain_speed_multiplier(multiplier: float) -> void:
	purifier_orb_chain_speed_multiplier = maxf(multiplier, 0.05)


func _update_purifier_orb_chain(delta: float) -> void:
	if not purifier_orb_chain_active:
		return
	purifier_orb_chain_timer = maxf(
		purifier_orb_chain_timer - delta,
		0.0
	)
	if purifier_orb_chain_timer <= 0.0:
		_advance_purifier_orb_chain()


func _advance_purifier_orb_chain() -> void:
	if not purifier_orb_chain_active:
		return

	var orb: Node2D = null
	while not purifier_orb_chain_queue.is_empty():
		var candidate := (
			purifier_orb_chain_queue.pop_front()
			as Node2D
		)
		if _is_purifier_orb_active(candidate):
			orb = candidate
			break

	if not is_instance_valid(orb):
		_finish_purifier_orb_chain()
		return

	_detonate_purifier_orb(orb, purifier_orb_chain_step)
	purifier_orb_chain_step += 1
	orb.call("trigger_explosion")
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_orb_explosion_audio)

	if purifier_orb_chain_queue.is_empty():
		_finish_purifier_orb_chain()
	else:
		purifier_orb_chain_timer = _get_purifier_orb_chain_interval()


func _finish_purifier_orb_chain() -> void:
	purifier_orb_chain_active = false
	purifier_orb_chain_timer = 0.0
	purifier_orb_chain_step = 0
	purifier_orb_chain_queue.clear()
	_try_start_any_purifier_orb_chain()


func _detonate_purifier_orb(
	orb: Node2D,
	chain_index: int
) -> void:
	if not is_instance_valid(orb):
		return

	var radius := _get_purifier_orb_explosion_radius()
	var radius_sq := radius * radius
	var base_ratio := maxf(
		float(purifier_orb_config.get("base_damage_ratio", 0.80)),
		0.0
	) * _get_purifier_orb_damage_multiplier()
	var growth := maxf(
		float(purifier_orb_config.get("chain_damage_growth", 0.15)),
		0.0
	)
	var chain_multiplier := 1.0 + growth * float(maxi(chain_index, 0))
	var raw_damage := maxf(
		float(attack_damage) * base_ratio * chain_multiplier,
		1.0
	)
	var chain_cleansing_stacks := _get_purifier_augment_stacks("purifier_chain_cleansing")
	var chain_cleansing_chance := (
		clampf(
			0.20 + 0.08 * float(chain_cleansing_stacks - 1),
			0.0,
			1.0
		)
		if chain_cleansing_stacks > 0
		else 0.0
	)
	var cleansing_proc_positions: Array[Vector2] = []

	for node in _get_monster_nodes_near(orb.global_position, radius):
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or not monster.has_method("take_damage")
			or orb.global_position.distance_squared_to(
				monster.global_position
			) > radius_sq
		):
			continue

		var hit_position := monster.global_position
		var holy_multiplier := get_purifier_holy_damage_multiplier(monster)
		var hit_damage := maxi(
			int(round(raw_damage * holy_multiplier)),
			1
		)
		monster.call("take_damage", hit_damage)
		if (
			chain_cleansing_chance > 0.0
			and randf() <= chain_cleansing_chance
		):
			cleansing_proc_positions.append(hit_position)

	_queue_purifier_prism_burst(
		orb.global_position,
		raw_damage,
		radius
	)

	for proc_position in cleansing_proc_positions:
		_trigger_purifier_auto_cleansing(proc_position)


func _queue_purifier_prism_burst(
	origin: Vector2,
	source_raw_damage: float,
	source_radius: float
) -> void:
	var prism_stacks := _get_purifier_augment_stacks("purifier_prism_phenomenon")
	if prism_stacks <= 0:
		return

	var queue_was_empty := purifier_prism_launch_queue.is_empty()
	for _index in range(prism_stacks):
		purifier_prism_launch_queue.append({
			"origin": origin,
			"raw_damage": maxf(source_raw_damage * 0.50, 1.0),
			"radius": maxf(source_radius * 0.50, 1.0),
		})
	if queue_was_empty:
		purifier_prism_launch_timer = 0.0


func _choose_purifier_prism_target_position(origin: Vector2) -> Vector2:
	var search_range := maxf(
		float(purifier_orb_config.get("throw_range", 820.0)) * 0.50,
		80.0
	)
	var search_range_sq := search_range * search_range
	var score_radius := maxf(_get_purifier_orb_explosion_radius(), 80.0)
	_fill_monster_nodes_near(origin, search_range, _combat_monster_scratch)

	var best_position := Vector2.ZERO
	var best_score := -INF
	var found := false
	for raw_node in _combat_monster_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if monster == null:
			continue
		var distance_sq := origin.distance_squared_to(monster.global_position)
		if distance_sq > search_range_sq:
			continue
		var nearby := _count_monsters_near(monster.global_position, score_radius)
		var score := (
			float(nearby) * 10.0
			- sqrt(distance_sq) / maxf(search_range, 1.0)
		)
		if not found or score > best_score:
			found = true
			best_score = score
			best_position = monster.global_position
	_combat_monster_scratch.clear()

	if not found:
		var direction := Vector2.RIGHT
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			direction = origin.direction_to(target.global_position)
		if direction.length_squared() <= 0.001:
			direction = Vector2.from_angle(randf_range(0.0, TAU))
		best_position = origin + direction.normalized() * minf(180.0, search_range)

	return Vector2(
		clampf(
			best_position.x,
			FIELD_MARGIN,
			maxf(battlefield_size.x - FIELD_MARGIN, FIELD_MARGIN)
		),
		clampf(
			best_position.y,
			FIELD_MARGIN,
			maxf(battlefield_size.y - FIELD_MARGIN, FIELD_MARGIN)
		)
	)


func _launch_purifier_prism_orb(job: Dictionary) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var orb := PURIFIER_ORB_SCENE.instantiate() as Node2D
	if orb == null:
		return

	var origin: Vector2 = job.get("origin", global_position)
	var destination := _choose_purifier_prism_target_position(origin)
	parent.add_child(orb)
	orb.call(
		"setup",
		self,
		origin,
		destination,
		maxf(
			float(purifier_orb_config.get("projectile_speed", 380.0)),
			1.0
		),
		3.0,
		maxf(float(job.get("radius", 1.0)), 1.0),
		-1,
		String(
			purifier_orb_config.get(
				"effect_dir",
				"%s/effect2" % STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(purifier_orb_config.get("visual_scale", 0.45)) * 0.50,
			0.05
		)
	)
	purifier_prism_active.append({
		"orb": orb,
		"timer": 2.0,
		"raw_damage": maxf(float(job.get("raw_damage", 1.0)), 1.0),
		"radius": maxf(float(job.get("radius", 1.0)), 1.0),
	})


func _detonate_purifier_prism_orb(entry: Dictionary) -> void:
	var raw_orb = entry.get("orb", null)
	if not is_instance_valid(raw_orb):
		return
	var orb := raw_orb as Node2D
	if orb == null:
		return

	var radius := maxf(float(entry.get("radius", 1.0)), 1.0)
	var radius_sq := radius * radius
	var raw_damage := maxf(float(entry.get("raw_damage", 1.0)), 1.0)
	_fill_monster_nodes_near(orb.global_position, radius, _combat_monster_scratch)
	for raw_node in _combat_monster_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.has_method("take_damage")
			or orb.global_position.distance_squared_to(monster.global_position) > radius_sq
		):
			continue
		var hit_damage := maxi(
			int(round(raw_damage * get_purifier_holy_damage_multiplier(monster))),
			1
		)
		monster.call("take_damage", hit_damage)
	_combat_monster_scratch.clear()

	if orb.has_method("trigger_explosion"):
		orb.call("trigger_explosion")
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_orb_explosion_audio)


func _update_purifier_prism(delta: float) -> void:
	if not purifier_prism_launch_queue.is_empty():
		purifier_prism_launch_timer = maxf(
			purifier_prism_launch_timer - delta,
			0.0
		)
		if purifier_prism_launch_timer <= 0.0:
			var job: Dictionary = purifier_prism_launch_queue.pop_front()
			_launch_purifier_prism_orb(job)
			purifier_prism_launch_timer = 0.32

	for index in range(purifier_prism_active.size() - 1, -1, -1):
		var entry: Dictionary = purifier_prism_active[index]
		var raw_orb = entry.get("orb", null)
		if not is_instance_valid(raw_orb) or raw_orb.is_queued_for_deletion():
			purifier_prism_active.remove_at(index)
			continue
		var timer := float(entry.get("timer", 0.0)) - delta
		entry["timer"] = timer
		if timer > 0.0:
			continue
		_detonate_purifier_prism_orb(entry)
		purifier_prism_active.remove_at(index)


func _advance_purifier_cleansing_stack() -> void:
	var max_stacks := maxi(
		int(purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	purifier_cleansing_stacks = mini(
		purifier_cleansing_stacks + 1,
		max_stacks
	)


func _try_purifier_o_lord_heal(total_damage: int) -> void:
	if silence_timer > 0.0:
		return
	var stacks := _get_purifier_augment_stacks("purifier_o_lord")
	if stacks <= 0 or total_damage <= 0:
		return
	var chance := clampf(
		0.30 + 0.03 * float(stacks - 1),
		0.0,
		1.0
	)
	if randf() <= chance:
		heal_direct(total_damage)


func _apply_purifier_cleansing_centers(centers: Array[Vector2]) -> int:
	if centers.is_empty():
		return 0
	var radius := maxf(
		float(purifier_cleansing_config.get("radius", 100.0)),
		1.0
	)
	var radius_sq := radius * radius
	var base_ratio := maxf(
		float(purifier_cleansing_config.get("base_damage_ratio", 0.80)),
		0.0
	)
	var undead_multiplier := maxf(
		float(
			purifier_cleansing_config.get(
				"undead_damage_multiplier",
				1.50
			)
		),
		0.0
	)
	var raw_damage := maxf(float(attack_damage) * base_ratio, 1.0)
	var damaged_ids: Dictionary = {}
	var total_damage := 0

	for center in centers:
		_spawn_purifier_cleansing_fx(center)
		for raw_node in _get_monster_nodes_near(center, radius):
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or not monster.has_method("take_damage"):
				continue
			var instance_id := monster.get_instance_id()
			if damaged_ids.has(instance_id):
				continue
			if center.distance_squared_to(monster.global_position) > radius_sq:
				continue
			damaged_ids[instance_id] = true
			var multiplier := get_purifier_holy_damage_multiplier(monster)
			if _is_purifier_undead_target(monster):
				multiplier *= undead_multiplier
			var hit_damage := maxi(
				int(round(raw_damage * multiplier)),
				1
			)
			monster.call("take_damage", hit_damage)
			total_damage += hit_damage

	_try_purifier_o_lord_heal(total_damage)
	return total_damage


func _trigger_purifier_auto_cleansing(center: Vector2) -> void:
	if (
		hero_archetype != "cleric_purifier"
		or purifier_cleansing_config.is_empty()
		or is_dying
		or current_hp <= 0
	):
		return
	_advance_purifier_cleansing_stack()
	var centers: Array[Vector2] = []
	centers.append(center)
	_apply_purifier_cleansing_centers(centers)
	_try_unlock_purifier_fourth_skill()
	queue_redraw()

func _get_purifier_cleansing_target_count() -> int:
	var per_target := maxi(
		int(purifier_cleansing_config.get("casts_per_extra_target", 20)),
		1
	)
	var max_targets := maxi(
		int(purifier_cleansing_config.get("max_targets", 6)),
		1
	)
	var extra_targets := floori(
		float(purifier_cleansing_stacks) / float(per_target)
	)
	return mini(1 + extra_targets, max_targets)


func _collect_purifier_cleansing_targets(
	target_count: int
) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if target_count <= 0:
		return result

	if (
		HERO_TARGET_POLICY.is_detectable(target)
		and target.is_in_group("monsters")
	):
		var hp_value = target.get("current_hp")
		if hp_value == null or int(hp_value) > 0:
			result.append(target)

	var search_radius := maxf(ai_sense_radius, attack_range)
	var candidates := _get_monster_nodes_near(global_position, search_radius)
	while result.size() < target_count:
		var best: Node2D = null
		var best_distance_sq := INF
		for raw_node in candidates:
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or monster in result:
				continue
			var hp_value = monster.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			var distance_sq := global_position.distance_squared_to(
				monster.global_position
			)
			if distance_sq < best_distance_sq:
				best_distance_sq = distance_sq
				best = monster
		if best == null:
			break
		result.append(best)

	return result


func _spawn_purifier_cleansing_fx(world_position: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var fx := PURIFIER_CLEANSING_FX_SCENE.instantiate() as Node2D
	if fx == null:
		return
	parent.add_child(fx)
	fx.call(
		"setup",
		world_position,
		String(
			purifier_cleansing_config.get(
				"effect_dir",
				"%s/effect5" % STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(purifier_cleansing_config.get("visual_scale", 1.0)),
			0.05
		),
		maxf(
			float(purifier_cleansing_config.get("effect_fps", 12.0)),
			1.0
		)
	)


func _try_unlock_purifier_fourth_skill() -> void:
	var required := maxi(
		int(purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	if purifier_cleansing_stacks < required:
		return
	var skill_id := String(
		purifier_cleansing_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	if is_conditional_skill_unlocked(skill_id):
		return
	_unlock_conditional_skill(
		skill_id,
		String(
			purifier_cleansing_config.get(
				"unlock_skill_name",
				"4스킬"
			)
		),
		"purification_cast_count",
		purifier_cleansing_stacks,
		required,
		{
			"hero_id": hero_id,
			"archetype": hero_archetype,
			"source": "purifier_cleansing_stacks",
			"cutscene_texture_path": String(
				purifier_cleansing_config.get(
					"cutscene_texture_path",
					""
				)
			),
			"cutscene_hold_seconds": float(
				purifier_cleansing_config.get(
					"cutscene_hold_seconds",
					1.05
				)
			),
		}
	)


func _cast_purifier_cleansing() -> void:
	if silence_timer > 0.0:
		return
	if (
		hero_archetype != "cleric_purifier"
		or purifier_cleansing_config.is_empty()
		or purifier_cleansing_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return

	var previous_stacks := purifier_cleansing_stacks
	_advance_purifier_cleansing_stack()

	var targets := _collect_purifier_cleansing_targets(
		_get_purifier_cleansing_target_count()
	)
	if targets.is_empty():
		purifier_cleansing_stacks = previous_stacks
		return

	var centers: Array[Vector2] = []
	for cast_target in targets:
		if is_instance_valid(cast_target):
			centers.append(cast_target.global_position)

	if centers.is_empty():
		purifier_cleansing_stacks = previous_stacks
		return

	_apply_purifier_cleansing_centers(centers)
	purifier_cleansing_cooldown = (
		maxf(float(purifier_cleansing_config.get("cooldown", 3.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_cleansing_audio)
	_try_unlock_purifier_fourth_skill()
	queue_redraw()

func _choose_purifier_gungnir_direction() -> Vector2:
	if purifier_gungnir_config.is_empty():
		return Vector2.ZERO

	var flight_distance := maxf(
		float(purifier_gungnir_config.get("flight_distance", 1500.0)),
		1.0
	)
	var capture_radius := maxf(
		float(purifier_gungnir_config.get("capture_diameter", 300.0)) * 0.5,
		1.0
	)
	var sample_count := maxi(
		int(purifier_gungnir_config.get("direction_samples", 24)),
		8
	)
	var search_radius := flight_distance + capture_radius
	_fill_monster_nodes_near(
		global_position,
		search_radius,
		_combat_monster_scratch
	)

	var best_direction := Vector2.ZERO
	var best_score := -INF
	var best_count := 0

	for sample_index in range(sample_count):
		var angle := TAU * float(sample_index) / float(sample_count)
		var candidate_direction := Vector2.from_angle(angle)
		var hit_count := 0
		var density_score := 0.0
		var distance_score := 0.0

		for raw_node in _combat_monster_scratch:
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or not monster.is_in_group("monsters"):
				continue
			var hp_value = monster.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue

			var offset := monster.global_position - global_position
			var forward := offset.dot(candidate_direction)
			if forward < 0.0 or forward > flight_distance:
				continue
			var lateral := absf(candidate_direction.cross(offset))
			if lateral > capture_radius:
				continue

			hit_count += 1
			density_score += 1.0 - clampf(
				lateral / capture_radius,
				0.0,
				1.0
			)
			distance_score += 1.0 - clampf(
				forward / flight_distance,
				0.0,
				1.0
			)

		var score := (
			float(hit_count) * 1000.0
			+ density_score * 20.0
			+ distance_score * 2.0
		)
		if hit_count > best_count or (
			hit_count == best_count and score > best_score
		):
			best_count = hit_count
			best_score = score
			best_direction = candidate_direction

	_combat_monster_scratch.clear()
	if best_count <= 0:
		return Vector2.ZERO
	return best_direction.normalized()


func _try_start_purifier_gungnir() -> bool:
	if silence_timer > 0.0:
		return false
	if (
		hero_archetype != "cleric_purifier"
		or purifier_gungnir_config.is_empty()
		or purifier_gungnir_casting
		or purifier_gungnir_cooldown > 0.0
		or is_dying
		or current_hp <= 0
	):
		return false

	var unlock_skill_id := String(
		purifier_gungnir_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	if not is_conditional_skill_unlocked(unlock_skill_id):
		return false

	var fire_direction := _choose_purifier_gungnir_direction()
	if fire_direction.length_squared() <= 0.001:
		return false

	var parent := get_parent()
	if not is_instance_valid(parent):
		return false
	var gungnir := PURIFIER_GUNGNIR_SCENE.instantiate() as Node2D
	if gungnir == null:
		return false

	parent.add_child(gungnir)
	gungnir.connect(
		"launched",
		Callable(self, "_on_purifier_gungnir_launched")
	)
	gungnir.connect(
		"impacted",
		Callable(self, "_on_purifier_gungnir_impacted")
	)
	gungnir.connect(
		"finished",
		Callable(self, "_on_purifier_gungnir_finished").bind(gungnir)
	)

	purifier_gungnir_instance = gungnir
	purifier_gungnir_direction = fire_direction
	purifier_gungnir_casting = true
	purifier_gungnir_cooldown = (
		maxf(float(purifier_gungnir_config.get("cooldown", 5.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)

	if absf(fire_direction.x) > 0.05 and is_instance_valid(hero_sprite):
		hero_sprite.flip_h = fire_direction.x < 0.0
	velocity = Vector2.ZERO
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_gungnir_charge_audio)
	gungnir.call(
		"setup",
		self,
		fire_direction,
		purifier_gungnir_config
	)
	return true


func _on_purifier_gungnir_launched() -> void:
	purifier_gungnir_casting = false
	if is_instance_valid(purifier_gungnir_charge_audio):
		purifier_gungnir_charge_audio.stop()
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_gungnir_flight_audio)


func _on_purifier_gungnir_impacted() -> void:
	if is_instance_valid(purifier_gungnir_flight_audio):
		purifier_gungnir_flight_audio.stop()
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(purifier_gungnir_explosion_audio)


func _on_purifier_gungnir_finished(instance: Node2D) -> void:
	if is_instance_valid(purifier_gungnir_charge_audio):
		purifier_gungnir_charge_audio.stop()
	if is_instance_valid(purifier_gungnir_flight_audio):
		purifier_gungnir_flight_audio.stop()
	if purifier_gungnir_instance == instance:
		purifier_gungnir_instance = null
	purifier_gungnir_casting = false


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
	purifier_orb_cooldown = maxf(purifier_orb_cooldown - delta, 0.0)
	purifier_cleansing_cooldown = maxf(
		purifier_cleansing_cooldown - delta,
		0.0
	)
	purifier_gungnir_cooldown = maxf(
		purifier_gungnir_cooldown - delta,
		0.0
	)
	purifier_broken_sanctuary_timer = maxf(
		purifier_broken_sanctuary_timer - delta,
		0.0
	)
	_update_purifier_orb_chain(delta)
	_update_purifier_prism(delta)

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
					int(round(
						float(
							int(
								purifier_crown_config.get(
									"heal_per_stack",
									20
								)
							)
						)
						* float(purifier_crown_stacks)
						* _get_purifier_crown_effect_multiplier()
					)),
					1
				)
			)
			purifier_crown_heal_timer += maxf(
				float(purifier_crown_config.get("heal_interval", 5.0)),
				0.1
			)

	if purifier_gungnir_casting:
		_try_activate_purifier_protection()
		return
	if _try_start_purifier_gungnir():
		_try_activate_purifier_protection()
		return
	if purifier_crown_cooldown <= 0.0:
		_cast_purifier_crown()
	if purifier_orb_cooldown <= 0.0:
		_cast_purifier_orb()
	if purifier_cleansing_cooldown <= 0.0:
		_cast_purifier_cleansing()
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
	if silence_timer > 0.0:
		return
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
	if silence_timer > 0.0:
		return
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
	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"arcane_piercer")

func _find_best_piercing_direction() -> Vector2:
	var max_range := maxf(
		float(ultimate_config.get("projectile_range", 900.0)),
		1.0
	)
	var corridor_half_width := maxf(
		float(ultimate_config.get("aim_corridor_half_width", 72.0)),
		1.0
	)

	var max_range_sq := max_range * max_range
	_fill_monster_nodes_near(
		global_position,
		max_range,
		_combat_monster_scratch
	)
	for index in range(_combat_monster_scratch.size() - 1, -1, -1):
		var node = _combat_monster_scratch[index]
		if not HERO_TARGET_POLICY.is_detectable(node):
			_combat_monster_scratch.remove_at(index)
			continue
		var monster := node as Node2D
		if monster == null:
			_combat_monster_scratch.remove_at(index)
			continue
		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq <= 0.0 or distance_sq > max_range_sq:
			_combat_monster_scratch.remove_at(index)

	if _combat_monster_scratch.is_empty():
		return Vector2.ZERO

	var first_monster := _combat_monster_scratch[0] as Node2D
	var best_direction := global_position.direction_to(
		first_monster.global_position
	)
	var best_score := -INF

	for raw_candidate in _combat_monster_scratch:
		var candidate := raw_candidate as Node2D
		var candidate_direction := global_position.direction_to(
			candidate.global_position
		)
		if candidate_direction.length_squared() <= 0.0:
			continue

		var score := 0.0
		for raw_target_monster in _combat_monster_scratch:
			var target_monster := raw_target_monster as Node2D
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

	var result := best_direction.normalized()
	_combat_monster_scratch.clear()
	return result

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

	var radius_sq := radius * radius
	_fill_monster_nodes_near(
		global_position,
		radius,
		_combat_monster_scratch
	)
	for node in _combat_monster_scratch:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		if monster.has_method("take_damage"):
			monster.call("take_damage", damage)
	_combat_monster_scratch.clear()

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
	offensive_memory_events.prune_before(ai_memory_clock - OFFENSE_MEMORY_WINDOW)

func _build_recent_offense_memory() -> Dictionary:
	_prune_offensive_memory()

	var type_weights := {}
	var role_weights := {}
	var total_weight := 0.0

	for event_index in range(offensive_memory_events.size()):
		var event: Dictionary = offensive_memory_events.get_event(event_index)
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
		"grand_sage_astra":
			_append_sage_skill1_hud(skills)
			_append_sage_skill2_hud(skills)
			_append_sage_skill3_hud(skills)
			_append_sage_skill4_hud(skills)
			_append_sage_skill5_hud(skills)
			_append_sage_skill6_hud(skills)
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
			_append_skill_cooldown_hud(
				skills,
				purifier_orb_config,
				purifier_orb_cooldown,
				"res://assets/art/heroes/stage9_prist/frames/effect2/effect_13.png",
				maxf(
					float(purifier_orb_config.get("cooldown", 10.0)),
					0.0
				) * _get_purifier_skill_cooldown_multiplier()
			)
			_append_purifier_cleansing_hud(skills)
			_append_purifier_gungnir_hud(skills)
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
	return preload("res://src/data/hero_skill_descriptions.gd").describe(config)

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


func _append_sage_skill1_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_1", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 25.0)), 0.0)
	var cooldown_remaining := maxf(sage_skill1_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 35.0)), 0.0)
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var cooldown_ready := cooldown_remaining <= 0.01
	var ready := cooldown_ready and has_gauge

	var status := "사용 가능"
	if not cooldown_ready:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	skills.append({
		"id": String(skill.get("id", "freezing_point_explosion")),
		"name": String(skill.get("name", "빙점폭발")),
		"description": _skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": "게이지 %.0f / %.0f" % [gauge_current, gauge_max],
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect1/ice_04.png",
	})


func _append_sage_skill2_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_2", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 45.0)), 0.0)
	var cooldown_remaining := maxf(sage_skill2_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 40.0)), 0.0)
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var launching := sage_radiance_launch_remaining > 0
	var ready := cooldown_remaining <= 0.01 and has_gauge and not launching

	var status := "사용 가능"
	if launching:
		status = "광휘구체 방출 중"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	skills.append({
		"id": String(skill.get("id", "radiance_singularity")),
		"name": String(skill.get("name", "광휘의 특이점")),
		"description": _skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": "게이지 %.0f / %.0f" % [gauge_current, gauge_max],
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect3/starburst_04.png",
	})


func _append_sage_skill3_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_3", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 13.0)), 0.0)
	var cooldown_remaining := maxf(sage_skill3_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 20.0)), 0.0)
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var cooldown_ready := cooldown_remaining <= 0.01
	var ready := cooldown_ready and has_gauge
	var max_stacks := maxi(int(skill.get("max_stacks", 8)), 1)
	var required_completions := maxi(
		int(skill.get("unlock_completion_count", 2)),
		1
	)
	var unlocked := (
		is_conditional_skill_unlocked("sage_skill_5")
		and is_conditional_skill_unlocked("sage_skill_6")
	)

	var status := "사용 가능"
	if cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"
	elif sage_condensation_stacks >= max_stacks:
		status = "8스택 소모 가능"
	if unlocked:
		status += " · 스킬 5·6 해금 완료"

	var progress := "마력응축 (%d/%d) · 완성 %d/%d" % [
		sage_condensation_stacks,
		max_stacks,
		mini(sage_condensation_completion_count, required_completions),
		required_completions,
	]
	var cooldown_reduction_percent := (
		_get_sage_condensation_cooldown_reduction() * 100.0
	)
	if cooldown_reduction_percent > 0.01:
		progress += " · 스킬 쿨감 +%.0f%%" % cooldown_reduction_percent
	if sage_condensation_skill_damage_buff_timer > 0.0:
		progress += " · 스킬피해 +30%% %.1f초" % (
			sage_condensation_skill_damage_buff_timer
		)

	skills.append({
		"id": String(skill.get("id", "mana_condensation")),
		"name": String(skill.get("name", "마력응축")),
		"description": _skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect4/summon_08.png",
	})


func _append_sage_skill4_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_4", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 60.0)), 0.0)
	var cooldown_remaining := maxf(sage_skill4_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 70.0)), 0.0)
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var active := sage_starlight_remaining > 0.0
	var ready := cooldown_remaining <= 0.01 and has_gauge and not active

	var status := "사용 가능"
	if active:
		status = "스타라이트 전개 중"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	var progress := "게이지 %.0f / %.0f" % [gauge_current, gauge_max]
	if active:
		progress += " · 남은 시간 %.1f초" % sage_starlight_remaining

	skills.append({
		"id": String(skill.get("id", "starlight")),
		"name": String(skill.get("name", "스타라이트")),
		"description": _skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect7/stage10_effect2_01.png",
	})


func _append_sage_skill5_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_5", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var unlocked := is_conditional_skill_unlocked("sage_skill_5")
	var cooldown_total := maxf(float(skill.get("cooldown", 60.0)), 0.0)
	var cooldown_remaining := maxf(sage_skill5_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 100.0)), 0.0)
	var gauge_max := maxf(float(sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var ready := unlocked and cooldown_remaining <= 0.01 and has_gauge

	var status := "사용 가능"
	if not unlocked:
		status = "해금 조건 대기"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	var progress := "게이지 %.0f / %.0f" % [gauge_current, gauge_max]
	if not unlocked:
		var skill3_value = sage_config.get("skill_3", {})
		var skill3: Dictionary = (
			skill3_value
			if typeof(skill3_value) == TYPE_DICTIONARY
			else {}
		)
		var required_completions := maxi(
			int(skill3.get("unlock_completion_count", 2)),
			1
		)
		progress = "마력응축 완성 %d/%d · 스킬 5 해금 조건" % [
			mini(sage_condensation_completion_count, required_completions),
			required_completions,
		]

	skills.append({
		"id": String(skill.get("id", "annihilation")),
		"name": String(skill.get("name", "소멸")),
		"description": _skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect8/stage10_effect3_05.png",
	})


func _append_sage_skill6_hud(skills: Array) -> void:
	var raw_skill = sage_config.get("skill_6", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var unlocked := is_conditional_skill_unlocked("sage_skill_6")
	var skill3_value = sage_config.get("skill_3", {})
	var skill3: Dictionary = (
		skill3_value
		if typeof(skill3_value) == TYPE_DICTIONARY
		else {}
	)
	var required_completions := maxi(
		int(skill3.get("unlock_completion_count", 2)),
		1
	)
	var progress := (
		"스킬 피해 +%.0f%% · 적중 시 %.0f%% 발동"
		% [
			maxf(
				float(skill.get("skill_damage_bonus_ratio", 0.10)),
				0.0
			) * 100.0,
			clampf(
				float(skill.get("trigger_chance", 0.50)),
				0.0,
				1.0
			) * 100.0,
		]
		if unlocked
		else "마력응축 완성 %d/%d · 스킬 6 해금 조건" % [
			mini(
				sage_condensation_completion_count,
				required_completions
			),
			required_completions,
		]
	)

	skills.append({
		"id": String(skill.get("id", "black_spot_explosion")),
		"name": String(skill.get("name", "흑점폭발")),
		"description": _skill_hud_description(skill),
		"resource_text": "패시브",
		"progress_text": progress,
		"status_text": "패시브 활성" if unlocked else "해금 조건 대기",
		"available": unlocked,
		"cooldown_total": 0.0,
		"cooldown_remaining": 0.0,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect9/stage10_effect4_04.png",
	})


func _append_purifier_cleansing_hud(skills: Array) -> void:
	if purifier_cleansing_config.is_empty():
		return
	var cooldown_total := (
		maxf(float(purifier_cleansing_config.get("cooldown", 3.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	var cooldown_remaining := maxf(purifier_cleansing_cooldown, 0.0)
	var max_stacks := maxi(
		int(purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	skills.append({
		"id": String(purifier_cleansing_config.get("id", "purifier_cleansing")),
		"name": String(purifier_cleansing_config.get("name", "정화")),
		"description": _skill_hud_description(purifier_cleansing_config),
		"progress_text": (
			"정화 스택 %d / %d · 대상 수 %d"
			% [
				purifier_cleansing_stacks,
				max_stacks,
				_get_purifier_cleansing_target_count(),
			]
		),
		"status_text": (
			"재사용 대기 중"
			if cooldown_remaining > 0.01
			else "사용 가능"
		),
		"available": cooldown_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage9_prist/frames/effect5/effect_30.png",
	})


func _append_purifier_gungnir_hud(skills: Array) -> void:
	if purifier_gungnir_config.is_empty():
		return
	var required := maxi(
		int(purifier_gungnir_config.get("required_cleansing_stacks", 100)),
		1
	)
	var unlock_skill_id := String(
		purifier_gungnir_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	var unlocked := is_conditional_skill_unlocked(unlock_skill_id)
	var cooldown_total := (
		maxf(float(purifier_gungnir_config.get("cooldown", 5.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	var cooldown_remaining := maxf(purifier_gungnir_cooldown, 0.0)
	var status := "해금 조건 대기"
	if unlocked:
		if purifier_gungnir_casting:
			status = "시전 중"
		elif cooldown_remaining > 0.01:
			status = "재사용 대기 중"
		else:
			status = "사용 가능"

	skills.append({
		"id": String(purifier_gungnir_config.get("id", "purifier_gungnir")),
		"name": String(purifier_gungnir_config.get("name", "궁그닐")),
		"description": _skill_hud_description(purifier_gungnir_config),
		"progress_text": (
			"정화 %d / %d · 해금 조건"
			% [mini(purifier_cleansing_stacks, required), required]
		),
		"status_text": status,
		"available": (
			unlocked
			and not purifier_gungnir_casting
			and cooldown_remaining <= 0.01
		),
		"cooldown_total": cooldown_total,
		"cooldown_remaining": (
			cooldown_remaining
			if unlocked
			else cooldown_total
		),
		"icon_path": "res://assets/art/heroes/stage9_prist/frames/effect6/frame_05.png",
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
	var skill_id := String(alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	var unlocked := is_conditional_skill_unlocked(skill_id)
	var ready := (
		unlocked
		and not alchemist_philosopher_unlock_pending
		and alchemist_philosopher_unlock_grace_timer <= 0.0
		and not alchemist_philosopher_used
		and not alchemist_philosopher_channeling
		and not alchemist_transformed
		and alchemist_materials_collected >= required
		and alchemist_gas + 0.001 >= gas_cost
	)
	var status := "해금 조건 대기"
	if alchemist_philosopher_unlock_pending:
		status = "현자의 돌 해금 중"
	elif alchemist_philosopher_channeling:
		status = "채널링 중"
	elif alchemist_transformed:
		status = "사용 완료 · 현자의 돌 활성화"
	elif alchemist_philosopher_used:
		status = "사용 완료"
	elif ready:
		status = "사용 가능"
	elif unlocked:
		status = "사용 준비 중"

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

	for raw_type in type_weights:
		var monster_type := String(raw_type)
		var weight := float(type_weights.get(monster_type, 0.0))
		if weight > dominant_weight:
			dominant_weight = weight
			dominant_type = monster_type

	var dominant_name := MONSTER_CATALOG.get_monster_name(dominant_type)
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

	var action := STATUS_ACTION_SCOPE.current(self)
	if action == null or not action.counted:
		if action != null: action.counted = true
		status_action_applied.emit(status_id)
	status_applied.emit(status_id)
	status_effect_events.append({
		"time": ai_memory_clock,
		"status": status_id,
	})
	_prune_status_memory()

func _prune_status_memory() -> void:
	status_effect_events.prune_before(ai_memory_clock - STATUS_MEMORY_WINDOW)

func _build_recent_status_memory() -> Dictionary:
	_prune_status_memory()

	var status_weights := {}
	var status_counts := {}
	var total_weight := 0.0

	for event_index in range(status_effect_events.size()):
		var event: Dictionary = status_effect_events.get_event(event_index)
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

	for raw_status in weights:
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
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	var purifier_active_orb_count := 0
	var purifier_link_count := 0
	var purifier_cleansing_progress_ratio := 0.0
	var purifier_cleansing_target_count := 1
	var purifier_crown_stack_ratio := 0.0
	var purifier_protection_breaks := 0
	var sage_condensation_ratio := 0.0
	if hero_archetype == "grand_sage_astra":
		var sage_skill3_value = sage_config.get("skill_3", {})
		var sage_skill3: Dictionary = (
			sage_skill3_value
			if typeof(sage_skill3_value) == TYPE_DICTIONARY
			else {}
		)
		sage_condensation_ratio = clampf(
			float(sage_condensation_stacks)
			/ float(maxi(int(sage_skill3.get("max_stacks", 8)), 1)),
			0.0,
			1.0
		)
	if hero_archetype == "cleric_purifier":
		for orb in purifier_orbs:
			if _is_purifier_orb_active(orb):
				purifier_active_orb_count += 1
		purifier_link_count = purifier_orb_links.size()
		purifier_cleansing_progress_ratio = clampf(
			float(purifier_cleansing_stacks)
			/ float(
				maxi(
					int(purifier_cleansing_config.get("max_stacks", 100)),
					1
				)
			),
			0.0,
			1.0
		)
		purifier_cleansing_target_count = _get_purifier_cleansing_target_count()
		purifier_crown_stack_ratio = clampf(
			float(purifier_crown_stacks)
			/ float(_get_purifier_crown_max_stacks()),
			0.0,
			1.0
		)
		purifier_protection_breaks = purifier_protection_break_count
	if hero_archetype == "pistol_gunner":
		gunner_ammo_ratio = float(gunner_ammo) / float(maxi(gunner_magazine_size, 1))
		gunner_reload_state = 1.0 if gunner_reloading else 0.0
		gunner_surround_pressure = _gunner_surround_pressure()
		_update_gunner_deadeye_aim_analysis()
		gunner_deadeye_cluster_score = gunner_deadeye_analysis_score

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
		"purifier_active_orb_count": purifier_active_orb_count,
		"purifier_link_count": purifier_link_count,
		"purifier_cleansing_progress_ratio": purifier_cleansing_progress_ratio,
		"purifier_cleansing_target_count": purifier_cleansing_target_count,
		"purifier_crown_stacks": (
			purifier_crown_stacks
			if hero_archetype == "cleric_purifier"
			else 0
		),
		"purifier_crown_stack_ratio": purifier_crown_stack_ratio,
		"purifier_protection_break_count": purifier_protection_breaks,
		"sage_condensation_ratio": sage_condensation_ratio,
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
		elif (
			hero_archetype == "cleric_purifier"
			and augment_id.begins_with("purifier_")
		):
			_on_purifier_augment_stack_changed(augment_id)


func _on_purifier_augment_stack_changed(augment_id: String) -> void:
	if hero_archetype != "cleric_purifier":
		return
	if augment_id == "purifier_pilgrims_path":
		_refresh_purifier_orb_links()
	elif augment_id == "purifier_book_of_purification":
		var effective_radius := _get_purifier_orb_explosion_radius()
		for orb in purifier_orbs:
			if not is_instance_valid(orb) or orb.is_queued_for_deletion():
				continue
			orb.set("blast_radius", effective_radius)
			orb.queue_redraw()


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

		"alchemist_equivalent_exchange", "alchemist_chemical_support", "alchemist_failure_mother_success", "alchemist_quick_decision", "alchemist_compressed_gas", "alchemist_quick_preparation", "summoner_runtime_augment", "purifier_runtime_augment", "sage_runtime_augment":
			# Runtime augments are read from build_counts at the authoritative
			# combat decision points, so no mutable duplicate stat is required.
			pass

		"advance_projectile_fan":
			projectile_count_bonus = mini(projectile_count_bonus + 1, 4)

		"grow_max_hp_ratio":
			var growth_ratio := maxf(float(effect.get("value", 0.0)), 0.0)
			if growth_ratio <= 0.0:
				return
			var previous_max_hp := maxi(max_hp, 1)
			var hp_gain := maxi(
				int(round(float(previous_max_hp) * growth_ratio)),
				1
			)
			max_hp = previous_max_hp + hp_gain
			current_hp = mini(current_hp + hp_gain, max_hp)

		"heal_max_hp_ratio":
			var heal_ratio := maxf(float(effect.get("value", 0.0)), 0.0)
			if heal_ratio <= 0.0:
				return
			current_hp = mini(
				current_hp + _get_reduced_healing(maxi(
					int(round(float(max_hp) * heal_ratio)),
					1
				)),
				max_hp
			)

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

func apply_poison(
	duration: float,
	total_current_hp_ratio: float,
	tick_interval: float = 0.50,
	source: Node = null
) -> void:
	if current_hp <= 0 or is_dying:
		return

	record_status_effect_event("poison")
	var was_active := poison_timer > 0.0 and poison_ticks_remaining > 0
	poison_timer = maxf(duration, 0.1)
	poison_tick_interval = maxf(tick_interval, 0.05)
	poison_ticks_remaining = maxi(
		int(ceil(poison_timer / poison_tick_interval)),
		1
	)
	poison_damage_remaining = maxi(
		int(round(
			float(current_hp)
			* maxf(total_current_hp_ratio, 0.0)
		)),
		1
	)
	if was_active:
		poison_tick_timer = minf(
			poison_tick_timer,
			poison_tick_interval
		)
	else:
		poison_tick_timer = poison_tick_interval
	poison_source = source if is_instance_valid(source) else null
	set_meta("poison_active", true)



func apply_bleed(duration: float = 5.0, source: Node = null, total_max_hp_ratio: float = -1.0, refresh: bool = false) -> bool:
	if current_hp <= 0 or is_dying or (bleed_timer > 0.0 and not refresh) or duration <= 0.0:
		return false
	record_status_effect_event("bleed")
	bleed_duration = duration
	bleed_timer = duration
	bleed_elapsed = 0.0
	bleed_tick_timer = minf(0.5, duration)
	bleed_total_damage = int(round(float(max_hp) * (total_max_hp_ratio if total_max_hp_ratio >= 0.0 else 0.004 * duration)))
	bleed_damage_applied = 0
	bleed_source = source if is_instance_valid(source) else null
	set_meta("bleed_active", true)
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "bleed")
	return true


func _update_bleed(delta: float) -> void:
	if bleed_timer <= 0.0:
		return
	var elapsed := minf(delta, bleed_timer)
	bleed_timer = maxf(bleed_timer - delta, 0.0)
	bleed_elapsed += elapsed
	bleed_tick_timer -= delta
	if bleed_tick_timer <= 0.0 or bleed_timer <= 0.0:
		var cumulative := int(round(float(bleed_total_damage) * minf(bleed_elapsed / bleed_duration, 1.0)))
		var damage := maxi(cumulative - bleed_damage_applied, 0)
		bleed_damage_applied = cumulative
		bleed_tick_timer = minf(0.5, bleed_timer)
		if damage > 0:
			take_status_damage(damage, bleed_source if is_instance_valid(bleed_source) else null)
	if bleed_timer <= 0.0 or current_hp <= 0:
		_clear_bleed()


func _clear_bleed() -> void:
	bleed_timer = 0.0
	bleed_elapsed = 0.0
	bleed_tick_timer = 0.0
	bleed_total_damage = 0
	bleed_damage_applied = 0
	bleed_source = null
	set_meta("bleed_active", false)


func apply_healing_reduction(duration: float, reduction: float) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0:
		return false
	healing_reduction_ratio = maxf(healing_reduction_ratio,clampf(reduction,0.0,1.0))
	healing_reduction_timer = maxf(healing_reduction_timer,duration)
	record_status_effect_event("healing_reduction")
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "healing_reduction")
	return true

func apply_damage_taken_increase(duration: float, increase: float) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0:
		return false
	damage_taken_increase_ratio = maxf(damage_taken_increase_ratio,maxf(increase,0.0))
	damage_taken_increase_timer = maxf(damage_taken_increase_timer,duration)
	record_status_effect_event("damage_taken_increase")
	return true

func _get_reduced_healing(amount: int) -> int:
	return maxi(int(round(float(amount) * (1.0 - healing_reduction_ratio))),0)

func _tick_received_modifiers(delta: float) -> void:
	healing_reduction_timer = maxf(healing_reduction_timer - delta,0.0)
	damage_taken_increase_timer = maxf(damage_taken_increase_timer - delta,0.0)
	if healing_reduction_timer <= 0.0:
		healing_reduction_ratio = 0.0
	if damage_taken_increase_timer <= 0.0:
		damage_taken_increase_ratio = 0.0

func _clear_received_modifiers() -> void:
	healing_reduction_timer = 0.0
	healing_reduction_ratio = 0.0
	damage_taken_increase_timer = 0.0
	damage_taken_increase_ratio = 0.0


func register_succubus_hit(source: Node2D) -> bool:
	if current_hp <= 0 or is_dying or charm_timer > 0.0 or charm_immunity_timer > 0.0:
		return false
	charm_stacks += 1
	if charm_stacks < int(SUCCUBUS_BEHAVIOR.CHARM.stacks):
		return false
	return apply_charm(source, float(SUCCUBUS_BEHAVIOR.CHARM.duration))

func apply_charm(source: Node2D, duration: float) -> bool:
	if current_hp <= 0 or is_dying or charm_timer > 0.0 or charm_immunity_timer > 0.0 or not is_instance_valid(source):
		return false
	charm_stacks = 0
	charm_timer = maxf(duration * (1.0 - get_status_resistance("charm")), 0.05)
	charm_source = weakref(source)
	charm_cooldown_properties = _get_external_skill_cooldown_properties()
	set_meta("charm_active", true)
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "charm")
	record_status_effect_event("charm")
	if channeling:
		_end_channel_skill()
	velocity = Vector2.ZERO
	return true

func _tick_charm_timers(delta: float) -> bool:
	charm_immunity_timer = maxf(charm_immunity_timer - delta, 0.0)
	if charm_timer <= 0.0:
		return false
	var source := charm_source.get_ref() as Node2D if charm_source != null else null
	var previous := charm_timer
	charm_timer = maxf(charm_timer - delta, 0.0)
	if charm_timer <= 0.0 or not is_instance_valid(source) or bool(source.get("dying")):
		charm_timer = 0.0
		charm_source = null
		charm_immunity_timer = maxf(float(SUCCUBUS_BEHAVIOR.CHARM.immunity) - maxf(delta - previous, 0.0), 0.0)
		set_meta("charm_active", false)
	return true

func _tick_charm_state(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
	if hero_archetype == "archmage_elementalist":
		for key in ARCHMAGE_SKILL_KEYS:
			archmage_skill_cooldowns[key] = maxf(float(archmage_skill_cooldowns.get(key, 0.0)) - delta, 0.0)
	else:
		for property_name in charm_cooldown_properties:
			var value = get(property_name)
			if value != null:
				set(property_name, maxf(float(value) - delta, 0.0))
	_update_invulnerability(delta)
	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
	# Active phase still expires while casts are sealed; recovery checks remain.
	if sage_phase_active:
		sage_phase_remaining = maxf(sage_phase_remaining - delta, 0.0)
		if sage_phase_remaining <= 0.0:
			_end_sage_phase()
	velocity = Vector2.ZERO
	var source := charm_source.get_ref() as Node2D if charm_source != null else null
	if charm_timer <= 0.0 or not HERO_TARGET_POLICY.is_detectable(source):
		return
	var offset := source.global_position - global_position
	if offset.length_squared() > 32.0 * 32.0:
		velocity = offset.normalized() * move_speed * minf(move_multiplier, float(SUCCUBUS_BEHAVIOR.CHARM.slow_multiplier)) * float(get_meta("yuki_slow_multiplier",1.0)) * _get_purifier_move_speed_multiplier()
	_move_and_slide_with_obstacle_escape()
	_clamp_to_battlefield()
	_update_stage1_pose_visual(delta)

func _clear_charm() -> void:
	charm_stacks = 0
	charm_timer = 0.0
	charm_immunity_timer = 0.0
	charm_source = null
	charm_cooldown_properties.clear()
	set_meta("charm_active", false)


func register_medusa_hit(duration: float, release_slow: float = 1.0, release_duration: float = 0.0) -> bool:
	if current_hp <= 0 or is_dying:
		return false
	medusa_hit_stacks += 1
	if medusa_hit_stacks < medusa_stone_threshold or petrify_timer > 0.0:
		return false
	if not apply_petrify(duration,release_slow,release_duration):
		return false
	medusa_hit_stacks = 0
	medusa_stone_threshold += int(MEDUSA_BEHAVIOR.STONE.threshold_growth)
	return true

func apply_petrify(duration: float, release_slow: float = 1.0, release_duration: float = 0.0) -> bool:
	if current_hp <= 0 or is_dying or petrify_timer > 0.0 or duration <= 0.0:
		return false
	petrify_status_action = STATUS_ACTION_SCOPE.current(self)
	record_status_effect_event("petrify")
	petrify_timer = maxf(duration * (1.0 - get_status_resistance("petrify")),0.05)
	petrify_anchor = global_position
	petrify_release_slow = release_slow
	petrify_release_slow_duration = release_duration
	velocity = Vector2.ZERO
	if is_instance_valid(hero_sprite):
		petrify_restore_tint = hero_sprite.self_modulate
		hero_sprite.self_modulate = petrify_restore_tint * MEDUSA_BEHAVIOR.STONE.tint
	set_meta("petrify_active",true)
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "petrify")
	return true

func _tick_petrify(delta: float) -> void:
	if petrify_timer <= 0.0:
		return
	petrify_timer = maxf(petrify_timer - delta,0.0)
	if petrify_timer <= 0.0:
		if is_instance_valid(hero_sprite):
			hero_sprite.self_modulate = petrify_restore_tint
		set_meta("petrify_active",false)
		if petrify_release_slow_duration > 0.0:
			var previous_action := STATUS_ACTION_SCOPE.begin(self,petrify_status_action)
			apply_slow(petrify_release_slow,petrify_release_slow_duration)
			STATUS_ACTION_SCOPE.finish(self,previous_action)
		petrify_status_action = null

func apply_damage_poison(duration: float, total_damage: int, source: Node, channel: int = 0) -> bool:
	if current_hp <= 0 or is_dying:
		return false
	if not damage_poison_tracker.apply(source,total_damage,duration,channel):
		return false
	record_status_effect_event("poison")
	set_meta("poison_active",true)
	return true

func _update_damage_poison(delta: float) -> void:
	if not damage_poison_tracker.entries.is_empty():
		damage_poison_tracker.tick(self,delta)
	set_meta("poison_active",poison_timer > 0.0 or not damage_poison_tracker.entries.is_empty())

func take_recorded_poison_damage(amount: int, source: Node) -> bool:
	# The stored budget already includes the original hit's mitigation.
	return _take_damage_internal(amount,source,true,false,true)

func _clear_medusa_statuses() -> void:
	petrify_status_action = null
	if petrify_timer > 0.0 and is_instance_valid(hero_sprite):
		hero_sprite.self_modulate = petrify_restore_tint
	petrify_timer = 0.0
	petrify_release_slow_duration = 0.0
	medusa_hit_stacks = 0
	medusa_stone_threshold = int(MEDUSA_BEHAVIOR.STONE.initial_stacks)
	damage_poison_tracker.clear()
	set_meta("petrify_active",false)
	set_meta("poison_active",poison_timer > 0.0)

func can_receive_possession() -> bool:
	return current_hp > 0 and not is_dying and fear_timer <= 0.0 and possession_immunity_timer <= 0.0


func apply_silence(duration: float) -> bool:
	if duration <= 0.0 or current_hp <= 0 or is_dying:
		return false
	silence_timer = maxf(silence_timer,duration*(1.0-get_status_resistance("silence")))
	set_meta("silence_active",silence_timer > 0.0)
	if silence_timer <= 0.0:
		return false
	record_status_effect_event("silence")
	return true

func apply_stun(duration: float) -> void:
	if duration <= 0.0 or current_hp <= 0 or is_dying:
		return
	record_status_effect_event("stun")
	if stun_timer <= 0.0 and is_instance_valid(hero_sprite):
		stun_sprite_speed = hero_sprite.speed_scale
		hero_sprite.speed_scale = 0.0
	stun_timer = maxf(stun_timer, maxf(duration * (1.0 - get_status_resistance("stun")), 0.05))
	velocity = Vector2.ZERO
	set_meta("stun_active", true)

func _clear_stun() -> void:
	if stun_timer > 0.0 and is_instance_valid(hero_sprite):
		hero_sprite.speed_scale = stun_sprite_speed
	stun_timer = 0.0
	set_meta("stun_active", false)

func _tick_stun_state(delta: float) -> bool:
	if stun_timer <= 0.0:
		return false
	velocity = Vector2.ZERO
	_update_invulnerability(delta)
	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0
	if fear_timer > 0.0:
		fear_timer = maxf(fear_timer - delta, 0.0)
		if fear_timer <= 0.0:
			fear_source = null
			fear_speed_multiplier = 1.0
			set_meta("fear_active", false)
	if stun_timer <= delta:
		_clear_stun()
	else:
		stun_timer -= delta
	return true


func apply_fear(
	source: Node2D,
	duration: float,
	speed_multiplier: float = 1.50
) -> void:
	if current_hp <= 0 or is_dying:
		return

	record_status_effect_event("fear")
	var resistance := get_status_resistance("fear")
	var effective_duration := maxf(
		duration * (1.0 - resistance),
		0.05
	)
	fear_timer = maxf(fear_timer, effective_duration)
	possession_immunity_timer = maxf(possession_immunity_timer, fear_timer + 3.0)
	fear_speed_multiplier = maxf(speed_multiplier, 1.0)
	fear_source = source if is_instance_valid(source) else null
	fear_origin = (
		fear_source.global_position
		if is_instance_valid(fear_source)
		else global_position - Vector2.RIGHT
	)
	set_meta("fear_active", true)
	queue_redraw()


func _get_external_skill_cooldown_properties() -> Array:
	var properties: Array = []
	match hero_archetype:
		"grand_sage_astra":
			properties = [
				&"sage_skill1_cooldown_timer",
				&"sage_skill2_cooldown_timer",
				&"sage_skill3_cooldown_timer",
				&"sage_skill4_cooldown_timer",
			]
			if is_conditional_skill_unlocked("sage_skill_5"):
				properties.append(&"sage_skill5_cooldown_timer")
		"cleric_purifier":
			properties = [
				&"purifier_crown_cooldown",
				&"purifier_orb_cooldown",
				&"purifier_cleansing_cooldown",
			]
			if is_conditional_skill_unlocked("purifier_fourth_skill"):
				properties.append(&"purifier_gungnir_cooldown")
		"summoner_gatekeeper":
			properties = [
				&"summoner_gatekeeper_cooldown",
				&"summoner_scout_cooldown",
				&"summoner_hound_cooldown",
				&"summoner_watcher_cooldown",
			]
			if summoner_open_gate_unlocked:
				properties.append(&"summoner_open_gate_cooldown")
		"alchemist_chemical":
			properties = [
				&"alchemist_mixture_field_cooldown",
				&"alchemist_mystery_cauldron_cooldown",
				&"alchemist_emergency_cooldown",
			]
		"ranged_kiter":
			properties = [
				&"ultimate_cooldown_timer",
				&"shield_cooldown_timer",
				&"channel_cooldown_timer",
			]
		"rogue_combo":
			properties = [
				&"rogue_slash_cooldown_timer",
				&"ultimate_cooldown_timer",
			]
		"sword_shield":
			properties = [&"fighter_charge_cooldown_timer"]
		"pistol_gunner":
			properties = [
				&"gunner_backstep_cooldown",
				&"gunner_cylinder_cooldown",
				&"gunner_deadeye_cooldown",
			]
		"berserker_madness":
			properties = [
				&"berserker_skill1_cooldown",
				&"berserker_skill2_cooldown",
				&"berserker_skill3_cooldown",
				&"berserker_skill4_cooldown",
			]
	return properties


func add_random_skill_cooldown_delay(seconds: float) -> bool:
	var delay := maxf(seconds, 0.0)
	if delay <= 0.0 or current_hp <= 0 or is_dying:
		return false

	if hero_archetype == "archmage_elementalist":
		var keys: Array[String] = []
		for key in ARCHMAGE_SKILL_KEYS:
			var config_value = archmage_skill_config.get(key, {})
			if (
				typeof(config_value) == TYPE_DICTIONARY
				and not Dictionary(config_value).is_empty()
			):
				keys.append(key)
		if keys.is_empty():
			return false
		var key := keys[randi() % keys.size()]
		archmage_skill_cooldowns[key] = (
			maxf(
				float(archmage_skill_cooldowns.get(key, 0.0)),
				0.0
			)
			+ delay
		)
		queue_redraw()
		return true

	var properties := _get_external_skill_cooldown_properties()
	if properties.is_empty():
		return false
	var property_name = properties[randi() % properties.size()]
	var current_value = get(property_name)
	if current_value == null:
		return false
	set(
		property_name,
		maxf(float(current_value), 0.0) + delay
	)
	queue_redraw()
	return true


func _tick_fear_skill_cooldowns(delta: float) -> void:
	if hero_archetype == "archmage_elementalist":
		for key in ARCHMAGE_SKILL_KEYS:
			archmage_skill_cooldowns[key] = maxf(
				float(archmage_skill_cooldowns.get(key, 0.0)) - delta,
				0.0
			)
		return

	for property_name in _get_external_skill_cooldown_properties():
		var current_value = get(property_name)
		if current_value == null:
			continue
		set(
			property_name,
			maxf(float(current_value) - delta, 0.0)
		)


func _tick_fear_state(delta: float) -> bool:
	if fear_timer <= 0.0:
		return false

	ai_memory_clock += delta
	_prune_offensive_memory()
	_prune_status_memory()
	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
	retarget_timer = maxf(retarget_timer - delta, 0.0)
	wander_timer = maxf(wander_timer - delta, 0.0)
	_tick_fear_skill_cooldowns(delta)
	_update_invulnerability(delta)

	if slow_timer > 0.0:
		slow_timer = maxf(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			move_multiplier = 1.0

	fear_timer = maxf(fear_timer - delta, 0.0)
	if is_instance_valid(fear_source):
		fear_origin = fear_source.global_position

	var escape_direction := fear_origin.direction_to(global_position)
	if escape_direction.length_squared() <= 0.0001:
		escape_direction = Vector2.RIGHT
	velocity = (
		escape_direction.normalized()
		* move_speed
		* _get_effective_move_multiplier()
		* fear_speed_multiplier
		* _get_purifier_move_speed_multiplier()
	)
	_move_and_slide_with_obstacle_escape()
	_clamp_to_battlefield()

	if fear_timer <= 0.0:
		fear_source = null
		fear_speed_multiplier = 1.0
		set_meta("fear_active", false)
		queue_redraw()
	return true

func _get_effective_move_multiplier() -> float:
	return move_multiplier * float(get_meta("yuki_slow_multiplier",1.0))

func apply_slow(multiplier: float, duration: float) -> void:
	if current_hp <= 0:
		return

	record_status_effect_event("slow")

	var resistance := get_status_resistance("slow")
	var raw_multiplier := clampf(multiplier, 0.01, 1.0)
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
		_execute_ai_movement(move_direction * move_speed * _get_effective_move_multiplier())
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
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.BERSERKER, target)

	_update_berserker_pose_visual(delta)


func _try_use_berserker_contextual_skill(
	current_target: Node2D,
	distance: float
) -> bool:
	if silence_timer > 0.0:
		return false
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
	if silence_timer > 0.0:
		return
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
	_play_berserker_skill1_audio(wave_index)

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
	if silence_timer > 0.0:
		return
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
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_skill2_audio)

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
	var healed_ids: Dictionary = {}
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
			heal_per_touch,
			healed_ids
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
	var half_width_sq: float = half_width * half_width
	_fill_monster_nodes_near(
		midpoint,
		search_radius,
		berserker_query_candidates
	)

	for node in berserker_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
			> half_width_sq
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
	berserker_query_candidates.clear()


func _heal_berserker_from_blood_path(
	world_points: Array[Vector2],
	half_width: float,
	heal_per_touch: int,
	healed_ids: Dictionary
) -> void:
	if current_hp <= 0 or is_dying or world_points.size() < 2:
		return

	healed_ids.clear()
	var half_width_sq: float = half_width * half_width
	for segment_index in range(world_points.size() - 1):
		var from_position: Vector2 = world_points[segment_index]
		var to_position: Vector2 = world_points[segment_index + 1]
		var segment: Vector2 = to_position - from_position
		var length_sq: float = maxf(segment.length_squared(), 0.001)
		var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
		var search_radius: float = (
			segment.length() * 0.5 + half_width + 20.0
		)
		_fill_monster_nodes_near(
			midpoint,
			search_radius,
			berserker_query_candidates
		)

		for node in berserker_query_candidates:
			if not HERO_TARGET_POLICY.is_detectable(node):
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
				> half_width_sq
			):
				continue

			healed_ids[iid] = true
			heal_direct(heal_per_touch)
		berserker_query_candidates.clear()


func _start_berserker_skill3(current_target: Node2D) -> void:
	if silence_timer > 0.0:
		return
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
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_skill3_audio)

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
	_fill_monster_nodes_near(
		global_position,
		orb_radius,
		berserker_query_candidates
	)
	for node in berserker_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	berserker_query_candidates.clear()

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
	if silence_timer > 0.0:
		return
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
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_skill4_audio)

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
	_fill_monster_nodes_near(
		global_position,
		radius,
		berserker_query_candidates
	)
	for node in berserker_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
			LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)

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
	berserker_query_candidates.clear()

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
	_play_berserker_basic_audio()

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
	_fill_monster_nodes_near(
		global_position,
		reach + half_width,
		berserker_query_candidates
	)

	for node in berserker_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	berserker_query_candidates.clear()

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
	if silence_timer > 0.0:
		return
	if berserker_madness_active or berserker_reviving or is_dying:
		return
	berserker_madness_active = true
	_ensure_berserker_audio_runtime()
	_play_berserker_player(berserker_madness_roar_audio)
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
	_fill_monster_nodes_near(
		global_position,
		radius,
		berserker_query_candidates
	)
	for node in berserker_query_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	berserker_query_candidates.clear()
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
	var trail: Line2D = null
	if parent.has_method("acquire_transient_fx"):
		trail = parent.call(
			"acquire_transient_fx",
			"berserker_blood_dash_trail",
			"line"
		) as Line2D
	if trail == null:
		trail = Line2D.new()
		parent.add_child(trail)

	trail.clear_points()
	trail.visible = true
	trail.modulate = Color.WHITE
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
	if parent.has_method("recycle_transient_fx"):
		trail_tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				trail,
				"berserker_blood_dash_trail"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
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

	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
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
		_execute_ai_movement(
			move_direction
			* move_speed
			* _get_effective_move_multiplier()
			* guard_move_scale
		)
	else:
		velocity = Vector2.ZERO

	if (
		fighter_charge_cooldown_timer <= 0.0
		and _fighter_should_start_charge()
	):
		_start_fighter_charge()
		return

	if distance <= attack_range and attack_timer <= 0.0:
		_execute_ai_basic_attack(HERO_ACTION_INTENT.AttackKind.FIGHTER, target)

	_update_fighter_pose_visual(delta)

func _fighter_should_start_charge() -> bool:
	if silence_timer > 0.0:
		return false
	if fighter_charge_config.is_empty() or fighter_guard_active:
		return false
	var trigger := HERO_FIGHTER_RUNTIME.get_charge_trigger(
		fighter_charge_config
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return _count_monsters_near(
		global_position,
		radius,
		required
	) >= required

func _start_fighter_charge() -> void:
	if silence_timer > 0.0:
		return
	var charge_target := _find_fighter_charge_target()
	if not is_instance_valid(charge_target):
		return
	fighter_charge_chain_count = 0
	_begin_fighter_charge_dash(charge_target)

func _find_fighter_charge_target(exclude: Node = null) -> Node2D:
	var max_distance := HERO_FIGHTER_RUNTIME.get_charge_max_target_distance(
		fighter_charge_config
	)
	_fill_monster_nodes_near(
		global_position,
		max_distance,
		fighter_charge_target_candidates
	)
	var charge_target := HERO_FIGHTER_RUNTIME.find_farthest_charge_target(
		fighter_charge_target_candidates,
		global_position,
		max_distance,
		exclude
	)
	fighter_charge_target_candidates.clear()
	return charge_target

func _begin_fighter_charge_dash(charge_target: Node2D) -> void:
	# Capture the life once; a reused Node must not inherit this dash.
	if not fighter_charge_reference.capture(charge_target, get_parent()):
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
	if fighter_charge_chain_count == 0:
		_play_fighter_thrust_audio(true)
	_spawn_fighter_afterimage(0.78)

func _update_fighter_charge(delta: float) -> void:
	if not fighter_charge_active:
		return
	if fighter_charge_reference.resolve(get_parent()) == null:
		_finish_fighter_charge()
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
		_spawn_fighter_afterimage(0.62)
		fighter_charge_afterimage_timer = maxf(
			float(fighter_charge_config.get("afterimage_interval", 0.035)),
			0.015
		)

	if t >= 1.0:
		_complete_fighter_charge_dash()

func _complete_fighter_charge_dash() -> void:
	# Revalidate immediately before damage, including callbacks during movement.
	var live_target := fighter_charge_reference.resolve(get_parent()) as Node2D
	if live_target == null:
		_finish_fighter_charge()
		return
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
	if is_instance_valid(live_target):
		_fighter_charge_damage_target(live_target, dash_damage)

	var impact_damage := maxi(
		1,
		int(round(
			float(attack_damage)
			* float(fighter_charge_config.get("impact_damage_ratio", 1.70))
		))
	)
	var radius := maxf(float(fighter_charge_config.get("impact_radius", 175.0)), 1.0)
	_fill_monster_nodes_near(
		global_position,
		radius,
		fighter_charge_impact_candidates
	)
	for node in fighter_charge_impact_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			global_position.distance_squared_to(monster.global_position)
			<= radius * radius
		):
			_fighter_charge_damage_target(monster, impact_damage)
	fighter_charge_impact_candidates.clear()

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
	fighter_charge_reference.clear()
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

	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var ghost: Sprite2D = null
	if parent.has_method("acquire_transient_fx"):
		ghost = parent.call(
			"acquire_transient_fx",
			"fighter_charge_afterimage",
			"sprite"
		) as Sprite2D
	if ghost == null:
		ghost = Sprite2D.new()
		parent.add_child(ghost)

	ghost.visible = true
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
	ghost.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.05, 0.92))

	var fade_time := maxf(
		float(fighter_charge_config.get("afterimage_fade_time", 0.30)),
		0.05
	)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, fade_time)
	if parent.has_method("recycle_transient_fx"):
		tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				ghost,
				"fighter_charge_afterimage"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		tween.finished.connect(
			Callable(ghost, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)

func _play_fighter_charge_impact_effect() -> void:
	_play_fighter_charge_impact_audio()
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
			_execute_ai_movement(
				heal_direction
				* move_speed
				* 0.90
				* _get_effective_move_multiplier()
				* speed_scale
			)
			return

	if is_instance_valid(magnet_item_target):
		var magnet_direction := _apply_magnet_item_steering(
			Vector2.ZERO,
			0.016
		)
		if magnet_direction.length_squared() > 0.01:
			_execute_ai_movement(
				magnet_direction
				* move_speed
				* 0.82
				* _get_effective_move_multiplier()
				* speed_scale
			)
			return

	if is_instance_valid(chest_target):
		var chest_direction := _apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			_execute_ai_movement(
				chest_direction
				* move_speed
				* 0.72
				* _get_effective_move_multiplier()
				* speed_scale
			)
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
		_execute_ai_movement(
			exp_direction
			* move_speed
			* 0.90
			* _get_effective_move_multiplier()
			* speed_scale
		)
		return

	if (
		wander_timer <= 0.0
		or position.distance_squared_to(wander_target)
		<= WANDER_REACHED_DISTANCE * WANDER_REACHED_DISTANCE
	):
		_pick_new_wander_target()

	var direction := position.direction_to(wander_target)
	_execute_ai_movement(
		direction
		* move_speed
		* 0.72
		* _get_effective_move_multiplier()
		* speed_scale
	)

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
		_play_fighter_slash_audio()
		if fighter_slash_mastery_stacks > 0:
			fighter_slash_bonus_hits_remaining = fighter_slash_mastery_stacks
			fighter_slash_combo_direction = direction
			fighter_slash_combo_swing_index = 1
			fighter_slash_combo_timer = _get_common_attack_interval(0.18)
	else:
		_fighter_apply_thrust(direction)
		_play_fighter_attack_effect("thrust", direction, false)
		_play_fighter_thrust_audio()
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
	_play_fighter_slash_audio()

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
	var trigger := HERO_FIGHTER_RUNTIME.get_slash_trigger(
		fighter_basic_config,
		fighter_slash_half_width_bonus
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return _count_monsters_near(
		global_position,
		radius,
		required
	) >= required

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

	_fill_monster_nodes_near(
		global_position,
		reach + half_width,
		fighter_combat_candidates
	)
	for node in fighter_combat_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	fighter_combat_candidates.clear()

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

	_fill_monster_nodes_near(
		global_position,
		length + half_width,
		fighter_combat_candidates
	)
	for node in fighter_combat_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
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
	fighter_combat_candidates.clear()

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
	if silence_timer > 0.0:
		return false
	if imposed_skill_cooldown > 0.0:
		return false
	var trigger := HERO_FIGHTER_RUNTIME.get_guard_trigger(
		ultimate_config
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return _count_monsters_near(
		global_position,
		radius,
		required
	) >= required


func _start_fighter_guard() -> void:
	if silence_timer > 0.0:
		return
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

	_play_fighter_guard_start_audio()
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
		_fill_monster_nodes_near(
			global_position,
			release_radius,
			fighter_combat_candidates
		)
		var release_radius_sq := release_radius * release_radius
		for node in fighter_combat_candidates:
			if not HERO_TARGET_POLICY.is_detectable(node):
				continue
			var monster := node as Node2D
			if monster == null:
				continue
			if (
				global_position.distance_squared_to(monster.global_position)
				> release_radius_sq
			):
				continue
			if monster.has_method("take_damage"):
				monster.call("take_damage", release_damage)
		fighter_combat_candidates.clear()

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
	var nearest_distance_sq := INF
	var reflect_radius_sq := reflect_radius * reflect_radius
	_fill_monster_nodes_near(
		global_position,
		reflect_radius,
		fighter_combat_candidates
	)
	for node in fighter_combat_candidates:
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := global_position.distance_squared_to(
			monster.global_position
		)
		if (
			distance_sq <= reflect_radius_sq
			and distance_sq < nearest_distance_sq
		):
			nearest = monster
			nearest_distance_sq = distance_sq
	fighter_combat_candidates.clear()
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
	_play_fighter_guard_release_audio()
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
	return _take_damage_internal(amount, source, false, true)


func take_followup_damage(amount: int, source: Node = null) -> bool:
	return _take_damage_internal(amount, source, true, true)


func take_status_damage(amount: int, source: Node = null) -> bool:
	return _take_damage_internal(amount, source, true, false)


func _take_damage_internal(
	amount: int,
	source: Node,
	ignore_invulnerability: bool,
	grant_invulnerability: bool,
	damage_already_mitigated: bool = false
) -> bool:
	if (
		amount <= 0
		or current_hp <= 0
		or is_dying
		or (
			not ignore_invulnerability
			and invulnerability_timer > 0.0
		)
	):
		return false

	# Snapshot material before a shield can break during this hit. Status ticks are not collisions.
	var physical_block := grant_invulnerability and not damage_already_mitigated and hero_archetype == "sword_shield" and fighter_guard_active
	var magical_block := grant_invulnerability and not damage_already_mitigated and shield_hp > 0.0 and hero_archetype != "sword_shield"
	var aura := 1.0
	var authority := get_parent()
	if not damage_already_mitigated and is_instance_valid(authority) and authority.has_method("get_transcendent_aura_modifier"):
		aura = float(authority.get_transcendent_aura_modifier(self,"incoming"))
		if is_instance_valid(source) and source is Node2D:
			aura *= float(authority.get_transcendent_aura_modifier(source,"outgoing"))
	var raw_damage := float(amount) if damage_already_mitigated else float(amount) * (1.0 + damage_taken_increase_ratio) * aura
	if (
		not damage_already_mitigated
		and hero_archetype == "alchemist_chemical"
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
	if not damage_already_mitigated and hero_archetype == "grand_sage_astra":
		raw_damage = _apply_sage_mana_conversion(raw_damage)
	var remaining_damage := raw_damage
	var absorbed_damage := 0

	if not damage_already_mitigated and hero_archetype == "sword_shield" and fighter_guard_active:
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

	accepted_damage_hit.emit(source)
	DAMAGE_NUMBERS.show(self, total_hit)

	hit_flash_timer = 0.12
	hit_pose_timer = 0.23
	_restart_stage1_animation("hit")
	if current_hp > 0 and grant_invulnerability:
		_play_contextual_damage_audio(physical_block, magical_block)

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

	if applied_damage > 0:
		combat_damage_received.emit(applied_damage)
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
		if grant_invulnerability:
			invulnerability_timer = invulnerability_duration
		if hero_archetype == "pistol_gunner" and _gunner_should_backstep_on_hit():
			_start_gunner_backstep()
		if grant_invulnerability:
			_refresh_invulnerability_visual()

	return true

func _prepare_contextual_damage_audio() -> void:
	if not CONTEXT_AUDIO.HITS.has(hero_archetype):
		return
	call(String(CONTEXT_AUDIO.HITS[hero_archetype].ensure))
	if hero_archetype == "sword_shield" and not is_instance_valid(fighter_block_audio):
		fighter_block_audio = _create_hero_sfx_player(CONTEXT_AUDIO.ROOT+"fighter_block.wav", CONTEXT_AUDIO.BLOCK_DB)
	elif hero_archetype in ["ranged_kiter", "archmage_elementalist"] and not is_instance_valid(magic_block_audio):
		magic_block_audio = _create_hero_sfx_player(CONTEXT_AUDIO.ROOT+"magic_block.wav", CONTEXT_AUDIO.MAGIC_BLOCK_DB)


func _play_contextual_damage_audio(physical_block: bool, magical_block: bool) -> void:
	if Time.get_ticks_msec() < contextual_hit_next_ms or not CONTEXT_AUDIO.HITS.has(hero_archetype):
		return
	var player: AudioStreamPlayer
	if physical_block:
		if not is_instance_valid(fighter_block_audio):
			fighter_block_audio = _create_hero_sfx_player(CONTEXT_AUDIO.ROOT+"fighter_block.wav", CONTEXT_AUDIO.BLOCK_DB)
		player = fighter_block_audio
	elif magical_block:
		if not is_instance_valid(magic_block_audio):
			magic_block_audio = _create_hero_sfx_player(CONTEXT_AUDIO.ROOT+"magic_block.wav", CONTEXT_AUDIO.MAGIC_BLOCK_DB)
		player = magic_block_audio
	else:
		var cue: Dictionary = CONTEXT_AUDIO.HITS[hero_archetype]
		call(String(cue.ensure))
		player = get(String(cue.player)) as AudioStreamPlayer
	if is_instance_valid(player) and player.stream != null:
		contextual_hit_next_ms = Time.get_ticks_msec()+CONTEXT_AUDIO.HIT_INTERVAL_MS
		player.stop()
		player.play()


func _update_hero_hit_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	if hit_flash_timer <= 0.0:
		queue_redraw()


func _update_poison(delta: float) -> void:
	if poison_flash_timer > 0.0:
		poison_flash_timer = maxf(poison_flash_timer - delta, 0.0)
		if poison_flash_timer <= 0.0:
			_set_poison_flash(false)

	if poison_timer <= 0.0 or poison_ticks_remaining <= 0:
		return

	poison_timer = maxf(poison_timer - delta, 0.0)
	poison_tick_timer -= delta
	while (
		poison_tick_timer <= 0.0
		and poison_ticks_remaining > 0
		and current_hp > 0
		and not is_dying
	):
		var tick_damage := maxi(
			int(ceil(
				float(poison_damage_remaining)
				/ float(poison_ticks_remaining)
			)),
			1
		)
		poison_damage_remaining = maxi(
			poison_damage_remaining - tick_damage,
			0
		)
		poison_ticks_remaining -= 1
		poison_tick_timer += poison_tick_interval
		var active_source: Node = (
			poison_source
			if is_instance_valid(poison_source)
			else null
		)
		var damage_applied := take_status_damage(
			tick_damage,
			active_source
		)
		if damage_applied and current_hp > 0:
			poison_flash_timer = 0.10
			_set_poison_flash(true)

	if poison_timer <= 0.0 or poison_ticks_remaining <= 0 or current_hp <= 0:
		poison_timer = 0.0
		poison_tick_timer = 0.0
		poison_damage_remaining = 0
		poison_ticks_remaining = 0
		poison_source = null
		set_meta("poison_active", false)


func _set_poison_flash(active: bool) -> void:
	if active and not poison_flash_active:
		poison_flash_restore_color = modulate
		poison_flash_active = true
	elif not active:
		if not poison_flash_active:
			return
		poison_flash_active = false

	var current_modulate := modulate
	if active:
		current_modulate.r = 0.72
		current_modulate.g = 0.30
		current_modulate.b = 0.92
	else:
		current_modulate.r = poison_flash_restore_color.r
		current_modulate.g = poison_flash_restore_color.g
		current_modulate.b = poison_flash_restore_color.b
	modulate = current_modulate


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
	_clear_bleed()
	_clear_burn()
	_clear_stun()
	_clear_medusa_statuses()
	_clear_charm()
	_clear_received_modifiers()
	set_meta("dullahan_soul_stacks", 0)
	possession_immunity_timer = 0.0
	fear_timer = 0.0
	fear_source = null
	fear_speed_multiplier = 1.0
	set_meta("fear_active", false)
	poison_timer = 0.0
	poison_tick_timer = 0.0
	poison_damage_remaining = 0
	poison_ticks_remaining = 0
	poison_flash_timer = 0.0
	poison_source = null
	set_meta("poison_active", false)
	_set_poison_flash(false)
	if hero_archetype == "ranged_kiter":
		_play_stage1_audio(&"death")
	elif hero_archetype == "rogue_combo":
		_play_rogue_death_audio()
	elif hero_archetype == "sword_shield":
		_play_fighter_death_audio()
	elif hero_archetype == "pistol_gunner":
		_play_gunner_death_audio()
	elif hero_archetype == "archmage_elementalist":
		_play_archmage_death_audio()
	elif hero_archetype == "berserker_madness":
		_play_berserker_death_audio()
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
	if is_instance_valid(status_overlay):
		status_overlay.queue_redraw()
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

func _draw_combat_status_overlay() -> void:
	if is_dying:
		return
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
	elif hero_archetype == "grand_sage_astra":
		# Astra can gain a temporary post-phase shield. Put that bar above the
		# yellow gauge and HP bar so it never crosses the Stage 10 sprite.
		shield_bar_y = -94.0
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
			status_overlay.draw_rect(Rect2(x, resource_bar_y, cell_width, 8.0), Color(0.12, 0.12, 0.14), true)
			if index < displayed_cells:
				status_overlay.draw_rect(Rect2(x, resource_bar_y, cell_width, 8.0), Color(1.0, 0.77, 0.16), true)
	elif hero_archetype == "summoner_gatekeeper":
		var slot_count := _get_summoner_slot_capacity()
		var active_summons := _get_active_summon_count()
		var gap := 2.0
		var cell_width := (
			bar_width - gap * float(slot_count - 1)
		) / float(slot_count)
		for index in range(slot_count):
			var x := -bar_width / 2.0 + float(index) * (cell_width + gap)
			status_overlay.draw_rect(
				Rect2(x, resource_bar_y, cell_width, 8.0),
				Color(0.12, 0.12, 0.14),
				true
			)
			if index < active_summons:
				status_overlay.draw_rect(
					Rect2(x, resource_bar_y, cell_width, 8.0),
					Color(0.55, 0.40, 0.95),
					true
				)
	elif hero_archetype == "alchemist_chemical":
		var gas_ratio := clampf(alchemist_gas / maxf(alchemist_gas_max, 1.0), 0.0, 1.0)
		status_overlay.draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0), Color(0.12, 0.12, 0.14), true)
		status_overlay.draw_rect(
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
		status_overlay.draw_rect(
			Rect2(bar_left_x, resource_bar_y, bar_width, 8.0),
			Color(0.12, 0.12, 0.14),
			true
		)
		status_overlay.draw_rect(
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
		status_overlay.draw_rect(
			Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0),
			Color(0.12, 0.12, 0.14),
			true
		)
		status_overlay.draw_rect(
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
		status_overlay.draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width, 8.0), Color(0.12, 0.12, 0.14), true)
		status_overlay.draw_rect(Rect2(-bar_width / 2.0, resource_bar_y, bar_width * ultimate_ratio, 8.0), Color(1.0, 0.77, 0.16), true)

	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	status_overlay.draw_rect(
		Rect2(bar_left_x, hp_bar_y, bar_width, 10.0),
		Color(0.12, 0.12, 0.14),
		true
	)
	status_overlay.draw_rect(
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
		status_overlay.draw_rect(
			Rect2(bar_left_x, shield_bar_y, bar_width, 8.0),
			Color(0.10, 0.12, 0.18),
			true
		)
		status_overlay.draw_rect(
			Rect2(
				bar_left_x,
				shield_bar_y,
				bar_width * shield_ratio,
				8.0
			),
			Color(0.20, 0.65, 1.0),
			true
		)

# Stronger paralysis replaces weaker; weaker applications cannot prolong it.
func apply_paralysis(ratio: float, duration: float) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0 or ratio <= 0.0:
		return false
	var strength := clampf(ratio,0.0,1.0)
	if paralysis_timer > 0.0 and strength < paralysis_ratio:
		return false
	paralysis_ratio = strength
	paralysis_timer = duration
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "paralysis")
	if strength >= 1.0:
		attack_timer = maxf(attack_timer,0.0001)
		rogue_slash_cooldown_timer = maxf(rogue_slash_cooldown_timer,0.0001)
	return true

func get_paralysis_attack_multiplier() -> float:
	return 1.0-paralysis_ratio if paralysis_timer > 0.0 else 1.0

func impose_all_skill_cooldowns(seconds: float) -> void:
	if current_hp <= 0 or is_dying or seconds <= 0.0:
		return
	imposed_skill_cooldown = maxf(imposed_skill_cooldown,seconds)
	archmage_blink_cooldown_timer = maxf(archmage_blink_cooldown_timer,seconds)
	if hero_archetype == "archmage_elementalist":
		for key in ARCHMAGE_SKILL_KEYS:
			archmage_skill_cooldowns[key] = maxf(float(archmage_skill_cooldowns.get(key,0.0)),seconds)
	else:
		for property_name in _get_external_skill_cooldown_properties():
			set(property_name,maxf(float(get(property_name)),seconds))
	queue_redraw()

func apply_burn(duration: float, total_damage: int, source: Node = null) -> bool:
	if current_hp <= 0 or is_dying or not burn_runtime.apply(duration,total_damage,source):
		return false
	set_meta("burn_active",true)
	record_status_effect_event("burn")
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self,"burn")
	return true

func _clear_burn() -> void:
	burn_runtime.clear()
	set_meta("burn_active",false)
