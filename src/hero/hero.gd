extends CharacterBody2D

const HERO_PRESENTATION := preload("res://src/data/hero_presentation_catalog.gd")
const HERO_RUNTIME_BINDINGS := preload("res://src/data/hero_runtime_binding_catalog.gd")

const COMBAT_DELAY := preload("res://src/systems/combat_delay.gd")

# Compatibility boundary: every legacy status call records into one retained buffer.
const LEGACY_STATUS_RECEIPT = preload("res://src/systems/battle_status_receipt.gd")
var legacy_status_receipt = LEGACY_STATUS_RECEIPT.new()
var legacy_status_result_complete := false

const HERO_ACTION_INTENT := preload("res://src/hero/hero_action_intent.gd")
const HERO_ACTION_PORT := preload("res://src/hero/hero_action_port.gd")
var action_intent = HERO_ACTION_INTENT.new()

const TIMED_EVENT_BUFFER := preload("res://src/systems/timed_event_buffer.gd")

const LOCAL_GRID_MOVEMENT := preload("res://src/monsters/monster_runtime_common.gd")

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")
const PICKUP_SEEK := preload("res://src/data/hero_pickup_seek_catalog.gd")

signal died
signal death_started
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
signal player_augment_requested(candidates: Array)
const PLAYER_CONTROL_POLICY := preload("res://src/hero_mode/hero_control_policy.gd")
var player_control_policy := PLAYER_CONTROL_POLICY.new()
var player_root_timer := 0.0
var player_root_multiplier := 1.0
var player_controlled := false
var player_exp_remainder := 0.0
var player_exp_requirement_scale := 1.0
var player_weapons: RefCounted
var sage_blackspot_effects: Array[Node2D] = []
var player_move_input := Vector2.ZERO
var player_input_suspended := true
var player_moved_this_frame := false
var player_augment_candidates: Array = []
func set_player_move_input(value: Vector2) -> void:
	player_move_input = value.limit_length(1.0) if value.is_finite() else Vector2.ZERO
func _player_move_velocity() -> Vector2:
	var speed := move_speed*_get_effective_move_multiplier()*_get_purifier_move_speed_multiplier()
	if hero_archetype == "alchemist_chemical": speed *= _get_alchemist_field_speed_multiplier()
	if fighter_guard_active: speed *= clampf(float(ultimate_config.get("move_speed_multiplier",0.62))+fighter_guard_move_multiplier_bonus,0.25,1.0)
	return player_move_input*speed
func reroll_player_augment() -> bool:
	if not player_controlled or current_hp <= 0 or player_weapons == null or player_augment_candidates.is_empty(): return false
	var next: Array = player_weapons.reroll(player_augment_candidates)
	if next.is_empty(): return false
	player_augment_candidates = next
	player_augment_requested.emit(next)
	return true
func choose_player_augment(id: String, held_candidates: Array = []) -> bool:
	var online_hold: bool = get_parent() != null and get_parent().get("online_match_mode") == true
	var available: Array = held_candidates if online_hold and not held_candidates.is_empty() else player_augment_candidates
	if not player_controlled or current_hp <= 0 or available.is_empty(): return false
	var chosen: Dictionary = {}
	for candidate in available:
		if String(candidate.get("id","")) == id: chosen = candidate; break
	if chosen.is_empty(): return false
	var candidates := available
	if not online_hold: player_augment_candidates = []
	if player_weapons != null:
		if not player_weapons.choose(id):
			if not online_hold: player_augment_candidates = candidates
			return false
	else: _apply_augment(chosen)
	augment_selected.emit(level,candidates,String(chosen.get("name",id)),"플레이어 선택",get_build_summary())
	while not online_hold and current_exp >= exp_to_next_level and player_augment_candidates.is_empty():
		current_exp -= exp_to_next_level
		_level_up()
	progression_changed.emit(level,current_exp,exp_to_next_level)
	return true
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
const HERO_SAGE_ARCHETYPE := preload("res://src/hero/archetypes/hero_sage_archetype.gd")
const HERO_ARCHMAGE_ARCHETYPE := preload("res://src/hero/archetypes/hero_archmage_archetype.gd")
const HERO_PURIFIER_ARCHETYPE := preload("res://src/hero/archetypes/hero_purifier_archetype.gd")
const HERO_ALCHEMIST_ARCHETYPE := preload("res://src/hero/archetypes/hero_alchemist_archetype.gd")
const HERO_SUMMONER_ARCHETYPE := preload("res://src/hero/archetypes/hero_summoner_archetype.gd")
const HERO_BERSERKER_ARCHETYPE := preload("res://src/hero/archetypes/hero_berserker_archetype.gd")
const HERO_FIGHTER_ARCHETYPE := preload("res://src/hero/archetypes/hero_fighter_archetype.gd")
const HERO_ROGUE_ARCHETYPE := preload("res://src/hero/archetypes/hero_rogue_archetype.gd")
const HERO_GUNNER_ARCHETYPE := preload("res://src/hero/archetypes/hero_gunner_archetype.gd")
const HERO_FIGHTER_RUNTIME := preload("res://src/hero/hero_fighter_runtime.gd")
const STAGE1_FRAME_DIR := HERO_PRESENTATION.STAGE1_FRAME_DIR
const STAGE2_FRAME_DIR := HERO_PRESENTATION.STAGE2_FRAME_DIR
const STAGE3_FRAME_DIR := HERO_PRESENTATION.STAGE3_FRAME_DIR
const STAGE4_FRAME_DIR := HERO_PRESENTATION.STAGE4_FRAME_DIR
const STAGE5_FRAME_DIR := HERO_PRESENTATION.STAGE5_FRAME_DIR
const ARCHMAGE_OFFENSIVE_SKILL_KEYS: Array[String] = [
	"combustion",
	"ice_bolt",
	"earth_spikes",
	"holy_power",
	"chain_dagger",
	"storm",
]
const ARCHMAGE_SKILL_KEYS: Array[String] = HERO_RUNTIME_BINDINGS.ARCHMAGE_SKILL_KEYS
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
const STAGE6_FRAME_DIR := HERO_PRESENTATION.STAGE6_FRAME_DIR
const STAGE7_FRAME_DIR := HERO_PRESENTATION.STAGE7_FRAME_DIR
const STAGE8_FRAME_DIR := HERO_PRESENTATION.STAGE8_FRAME_DIR
const STAGE9_FRAME_DIR := HERO_PRESENTATION.STAGE9_FRAME_DIR
const STAGE10_FRAME_DIR := HERO_PRESENTATION.STAGE10_FRAME_DIR
const CONTEXT_AUDIO := preload("res://src/data/contextual_audio_catalog.gd")
const STAGE1_BASIC_ATTACK_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_v4_basic.wav"
const STAGE1_BARRIER_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_v4_barrier.wav"
const STAGE1_ARCANE_FIELD_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_v4_focus.wav"
const STAGE1_ARCANE_PIERCER_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_v4_piercer.wav"
const STAGE1_HIT_AUDIO_PATH := CONTEXT_AUDIO.ROOT+"mage_hit.wav"
const STAGE1_DEATH_AUDIO_PATH := "res://assets/audio/sfx/stage1_mage_death_pixabay.mp3"
const STAGE1_LEVEL_UP_AUDIO_PATH := "res://assets/audio/sfx/level_up_rise07_cc0.mp3"
const STAGE2_COMBO_SLASH_AUDIO_PATH := "res://assets/audio/sfx/stage3_fighter_slash_pixabay.mp3"
const STAGE2_BLADE_STORM_AUDIO_PATH := "res://assets/audio/sfx/rogue_blades_v2/blade_storm.wav"
const STAGE2_ASSASSINATION_START_AUDIO_PATH := "res://assets/audio/sfx/rogue_blades_v2/assassination_start.wav"
const STAGE2_ASSASSINATION_HIT_AUDIO_PATH := "res://assets/audio/sfx/rogue_blades_v2/assassination_hit.wav"
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
const HERO_REFERENCE_SHEET_PATH := HERO_PRESENTATION.HERO_REFERENCE_SHEET_PATH
const HERO_REFERENCE_FRAME_SIZE := HERO_PRESENTATION.HERO_REFERENCE_FRAME_SIZE
const HERO_REFERENCE_RENDER_SCALE := HERO_PRESENTATION.HERO_REFERENCE_RENDER_SCALE
# Stage 1 is now built from 256x256 standalone frames, so do not fall back to
# scale=3 when the legacy sheet reference cannot provide a valid used rect.
# Keep the on-screen body height close to the old in-battle mage size instead.
const STAGE1_TARGET_VISIBLE_HEIGHT := HERO_PRESENTATION.STAGE1_TARGET_VISIBLE_HEIGHT

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
# Retained callbacks: rebuilt only when the archetype changes. Selection is
# refreshed at each legacy dispatch point, after preceding callbacks may mutate it.
var _hero_action_binding_key: String = ""
var _hero_action_binding_valid := false
var _hero_pose_tick: Callable
var _gunner_archetype_runtime: RefCounted
var _rogue_archetype_runtime: RefCounted
var _fighter_archetype_runtime: RefCounted
var _berserker_archetype_runtime: RefCounted
var _summoner_archetype_runtime: RefCounted
var _alchemist_archetype_runtime: RefCounted
var _purifier_archetype_runtime: RefCounted
var _archmage_archetype_runtime: RefCounted
var _sage_archetype_runtime: RefCounted
var _hero_action_tick: Callable
var _hero_common_runtime_tick: Callable
var _hero_boundary_steering: Callable
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
var common_attack_speed_augment_bonus: float = 0.0
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
var archmage_multicast_revision: int = 0
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
var _combat_profile: RefCounted
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
var charm_recovery_immunity := 7.0
var charm_source: WeakRef
var charm_cooldown_properties: Array = []
var stun_timer: float = 0.0
var player_control_gauge := preload("res://src/hero_mode/hero_control_gauge.gd").new()
var player_weapon_tick_done := false
var stun_sprite_speed: float = 1.0
var fear_timer: float = 0.0
var fear_immunity_timer := 0.0
var fear_recovery_immunity := 0.0
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
	player_exp_requirement_scale = float(profile.get("survival_learning",1.0))
	player_exp_remainder = 0.0
	player_move_input = Vector2.ZERO
	player_augment_candidates.clear()
	player_weapons = null
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
	player_control_policy.reset()
	player_root_timer = 0.0
	player_root_multiplier = 1.0
	_clear_medusa_statuses()
	_clear_charm()
	_clear_received_modifiers()
	set_meta("dullahan_soul_stacks", 0)
	possession_immunity_timer = 0.0
	fear_timer = 0.0
	fear_immunity_timer = 0.0
	fear_recovery_immunity = 0.0
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
	common_attack_speed_augment_bonus = 0.0
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
	_cancel_archmage_multicast()
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
	_combat_profile = get_parent().get("combat_profile")
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

	if not _play_bound_hero_audio(&"level_up") and is_instance_valid(level_up_audio):
		level_up_audio.stop()
		level_up_audio.play()

func _on_level_up_effect_animation_finished() -> void:
	level_up_effect.visible = false


func _attach_status_effect_visual(effect_type: String) -> void:
	var effect := COMBAT_STATUS_EFFECT_VISUAL.new()
	add_child(effect)
	effect.setup(self, effect_type)


func _physics_process(delta: float) -> void:
	var started: int = Time.get_ticks_usec() if _combat_profile != null and _combat_profile.enabled else 0
	_physics_process_hero(delta)
	if started: _combat_profile.record(_combat_profile.Scope.HERO,started)

func _physics_process_hero(delta: float) -> void:
	player_moved_this_frame = false
	if player_controlled:
		player_control_policy.tick(delta)
		player_root_timer = maxf(player_root_timer-delta,0.0)
	silence_timer = maxf(silence_timer-delta,0.0)
	set_meta("silence_active", silence_timer > 0.0)
	imposed_skill_cooldown = maxf(imposed_skill_cooldown-delta,0.0)
	paralysis_timer = maxf(paralysis_timer-delta,0.0)
	if paralysis_timer <= 0.0:
		paralysis_ratio = 0.0
	var immobilized := petrify_timer > 0.0
	var anchor := global_position
	player_weapon_tick_done = false
	if player_controlled: player_control_gauge.sample(self)
	_physics_process_actions(delta)
	if player_controlled and player_weapons != null and not player_weapon_tick_done and player_input_suspended and current_hp > 0 and not is_dying:
		# Existing world-space attacks keep moving/expiring during control locks.
		# Redraw after forced movement so cached local draw commands do not follow.
		player_weapons.tick(delta,false)
	if player_controlled:
		player_control_gauge.commit(self)
		if is_instance_valid(status_overlay): status_overlay.queue_redraw()
	if player_controlled and not player_input_suspended and not player_moved_this_frame and current_hp > 0 and not is_dying and not channeling and not purifier_gungnir_casting and not fighter_charge_active and not rogue_assassination_active:
		_move_and_slide_with_obstacle_escape()
	if immobilized and current_hp > 0 and not is_dying:
		global_position = anchor
		velocity = Vector2.ZERO
	# Covers practice adapters, forced movement and early-return skill paths.
	_clamp_to_battlefield()

func _physics_process_actions(delta: float) -> void:
	player_input_suspended = true
	if player_controlled and player_weapons != null and player_weapons.identity != null and berserker_reviving:
		player_weapons.identity.tick_revive(delta)
		if berserker_reviving: return
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
	player_input_suspended = false
	if player_controlled and player_weapons != null:
		_update_invulnerability(delta)
		slow_timer = maxf(slow_timer-delta,0.0)
		if slow_timer <= 0.0: move_multiplier = 1.0
		attack_pose_timer = maxf(attack_pose_timer-delta,0.0)
		hit_pose_timer = maxf(hit_pose_timer-delta,0.0)
		player_weapon_tick_done = true
		player_weapons.tick(delta)
		if alchemist_philosopher_channeling or alchemist_philosopher_unlock_pending or berserker_reviving:
			player_input_suspended = true; velocity = Vector2.ZERO; return
		velocity = _player_move_velocity()
		_move_and_slide_with_obstacle_escape()
		_refresh_hero_action_bindings()
		_hero_pose_tick.call(delta)
		return
	if not player_controlled: _update_combat_reposition(delta)

	_refresh_hero_action_bindings()
	if _hero_action_tick.is_valid():
		_hero_action_tick.call(delta)
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
	_refresh_hero_action_bindings()
	if _hero_common_runtime_tick.is_valid():
		_hero_common_runtime_tick.call(delta)

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
	_refresh_hero_action_bindings()
	move_direction = _hero_boundary_steering.call(move_direction)
	var movement_velocity := (
		move_direction
		* move_speed
		* _get_effective_move_multiplier()
		* _get_purifier_move_speed_multiplier()
	)
	action_intent.prepare_ranged(movement_velocity, distance)

func _get_summoner_slot_capacity() -> int:
	return _summoner_archetype()._get_summoner_slot_capacity()


func _get_active_summon_count() -> int:
	return summoner_active_regular_count


func _get_active_summoner_watcher_count() -> int:
	return _summoner_archetype()._get_active_summoner_watcher_count()


func _adjust_summoner_active_count(
	summon_kind: StringName,
	delta: int
) -> void:
	_summoner_archetype()._adjust_summoner_active_count(summon_kind, delta)


func _get_summoner_watcher_max_active() -> int:
	return _summoner_archetype()._get_summoner_watcher_max_active()


func _get_next_summoner_watcher_follow_slot() -> int:
	return _summoner_archetype()._get_next_summoner_watcher_follow_slot()


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
	_summoner_archetype()._ensure_summoner_pool_capacity()


func _ensure_summoner_runtime() -> void:
	_summoner_archetype()._ensure_summoner_runtime()


func _physics_process_summoner(delta: float) -> void:
	_summoner_archetype()._physics_process_summoner(delta)


func _roll_summoner_ai_personality() -> String:
	return _summoner_archetype()._roll_summoner_ai_personality()


func _get_summoner_target_hp_ratio() -> float:
	return _summoner_archetype()._get_summoner_target_hp_ratio()


func _score_summoner_ai_candidate(
	skill_id: String,
	nearby_count: int
) -> float:
	return _summoner_archetype()._score_summoner_ai_candidate(skill_id, nearby_count)


func _choose_summoner_ai_cast() -> String:
	return _summoner_archetype()._choose_summoner_ai_cast()


func _try_cast_summoner_ai_choice(skill_id: String) -> bool:
	return _summoner_archetype()._try_cast_summoner_ai_choice(skill_id)


func _get_active_summoner_open_gate() -> Node2D:
	return _summoner_archetype()._get_active_summoner_open_gate()


func _apply_summoner_open_gate_tether(move_direction: Vector2) -> Vector2:
	return _summoner_archetype()._apply_summoner_open_gate_tether(move_direction)


func _move_summoner_without_monsters_near_open_gate() -> void:
	_summoner_archetype()._move_summoner_without_monsters_near_open_gate()


func _get_summoner_augment_stacks(augment_id: String) -> int:
	return _summoner_archetype()._get_summoner_augment_stacks(augment_id)


func get_summoner_runtime_attack_speed_multiplier() -> float:
	return _summoner_archetype().get_summoner_runtime_attack_speed_multiplier()


func get_summoner_runtime_move_speed_multiplier() -> float:
	return _summoner_archetype().get_summoner_runtime_move_speed_multiplier()


func get_summoner_runtime_speed_multipliers() -> Dictionary:
	return _summoner_archetype().get_summoner_runtime_speed_multipliers()


func get_summoner_scout_attack_speed_multiplier() -> float:
	return _summoner_archetype().get_summoner_scout_attack_speed_multiplier()


func get_summoner_scout_damage_multiplier() -> float:
	return _summoner_archetype().get_summoner_scout_damage_multiplier()


func get_summoner_scout_move_speed_multiplier() -> float:
	return _summoner_archetype().get_summoner_scout_move_speed_multiplier()


func get_summoner_scout_swarm_multipliers() -> Dictionary:
	return _summoner_archetype().get_summoner_scout_swarm_multipliers()


func _extend_regular_summon_durations(seconds: float) -> void:
	HERO_SUMMONER_RUNTIME.extend_regular_summon_durations(
		seconds,
		summoner_gatekeeper_pool,
		summoner_scout_pool,
		summoner_hound_pool,
		summoner_watcher_pool
	)


func _update_summoner_full_slot_shield(delta: float) -> void:
	_summoner_archetype()._update_summoner_full_slot_shield(delta)


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
	return _summoner_archetype()._try_cast_summoner_gatekeeper()


func _on_summoner_gatekeeper_released(_summon: Node2D) -> void:
	_summoner_archetype()._on_summoner_gatekeeper_released(_summon)


func _try_cast_summoner_scout() -> bool:
	return _summoner_archetype()._try_cast_summoner_scout()


func _on_summoner_scout_released(_summon: Node2D) -> void:
	_summoner_archetype()._on_summoner_scout_released(_summon)


func _try_cast_summoner_hound() -> bool:
	return _summoner_archetype()._try_cast_summoner_hound()


func _on_summoner_hound_released(_summon: Node2D) -> void:
	_summoner_archetype()._on_summoner_hound_released(_summon)


func _try_cast_summoner_watcher() -> bool:
	return _summoner_archetype()._try_cast_summoner_watcher()


func _on_summoner_watcher_released(_summon: Node2D) -> void:
	_summoner_archetype()._on_summoner_watcher_released(_summon)


func _get_summoner_open_gate_required_summons() -> int:
	return _summoner_archetype()._get_summoner_open_gate_required_summons()


func _record_summoner_spawn_for_open_gate_unlock() -> void:
	_summoner_archetype()._record_summoner_spawn_for_open_gate_unlock()


func _try_cast_summoner_open_gate() -> bool:
	return _summoner_archetype()._try_cast_summoner_open_gate()


func _on_summoner_open_gate_released(_open_gate: Node2D) -> void:
	_summoner_archetype()._on_summoner_open_gate_released(_open_gate)


func _summoner_basic_attack(current_target: Node2D) -> void:
	_summoner_archetype()._summoner_basic_attack(current_target)


func _on_summoner_basic_effect_finished() -> void:
	_summoner_archetype()._on_summoner_basic_effect_finished()


func _update_summoner_pose_visual(delta: float) -> void:
	_summoner_archetype()._update_summoner_pose_visual(delta)



func _physics_process_alchemist(delta: float) -> void:
	_alchemist_archetype()._physics_process_alchemist(delta)

func _ensure_alchemist_runtime() -> void:
	_alchemist_archetype()._ensure_alchemist_runtime()


func _update_alchemist_material_spawning(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_material_spawning(delta)


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
	_alchemist_archetype()._add_alchemist_gas(amount)


func _consume_alchemist_gas(amount: float) -> bool:
	return _alchemist_archetype()._consume_alchemist_gas(amount)


func _get_alchemist_augment_stacks(augment_id: String) -> int:
	return _alchemist_archetype()._get_alchemist_augment_stacks(augment_id)


func _get_alchemist_compressed_range_multiplier() -> float:
	return _alchemist_archetype()._get_alchemist_compressed_range_multiplier()


func _get_alchemist_compressed_damage_multiplier() -> float:
	return _alchemist_archetype()._get_alchemist_compressed_damage_multiplier()


func _get_alchemist_speed_gap_damage_multiplier(monster: Node) -> float:
	return _alchemist_archetype()._get_alchemist_speed_gap_damage_multiplier(monster)


func _get_alchemist_equivalent_exchange_data(stacks: int) -> Dictionary:
	return _alchemist_archetype()._get_alchemist_equivalent_exchange_data(stacks)


func _get_alchemist_equivalent_damage_multiplier() -> float:
	return _alchemist_archetype()._get_alchemist_equivalent_damage_multiplier()


func _get_alchemist_equivalent_range_multiplier() -> float:
	return _alchemist_archetype()._get_alchemist_equivalent_range_multiplier()


func _try_pay_alchemist_equivalent_exchange(required_materials: int) -> bool:
	return _alchemist_archetype()._try_pay_alchemist_equivalent_exchange(required_materials)


func _on_alchemist_equivalent_exchange_kill() -> void:
	_alchemist_archetype()._on_alchemist_equivalent_exchange_kill()


func _deal_alchemist_dot_damage(monster: Node, base_damage: int) -> void:
	_alchemist_archetype()._deal_alchemist_dot_damage(monster, base_damage)


func _get_alchemist_mystery_cauldron_cooldown_total() -> float:
	return _alchemist_archetype()._get_alchemist_mystery_cauldron_cooldown_total()


func _get_alchemist_effective_cooldown(
	config: Dictionary,
	fallback: float
) -> float:
	return _alchemist_archetype()._get_alchemist_effective_cooldown(config, fallback)


func _check_alchemist_philosopher_unlock() -> void:
	_alchemist_archetype()._check_alchemist_philosopher_unlock()


func _update_alchemist_philosopher_unlock_sequence(delta: float) -> bool:
	return _alchemist_archetype()._update_alchemist_philosopher_unlock_sequence(delta)


func _ensure_alchemist_philosopher_unlock_effect() -> void:
	_alchemist_archetype()._ensure_alchemist_philosopher_unlock_effect()


func _play_alchemist_philosopher_unlock_effect() -> void:
	_alchemist_archetype()._play_alchemist_philosopher_unlock_effect()


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
	return _alchemist_archetype()._try_start_alchemist_philosopher_stone()


func _update_alchemist_philosopher_channel(delta: float) -> bool:
	return _alchemist_archetype()._update_alchemist_philosopher_channel(delta)


func _activate_alchemist_philosopher_form() -> void:
	_alchemist_archetype()._activate_alchemist_philosopher_form()


func _update_alchemist_philosopher_gas_regen(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_philosopher_gas_regen(delta)


func _move_alchemist_philosopher_form(delta: float) -> void:
	_alchemist_archetype()._move_alchemist_philosopher_form(delta)


func _update_alchemist_poison_trail(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_poison_trail(delta)


func _is_alchemist_inside_mixture_field() -> bool:
	return _alchemist_archetype()._is_alchemist_inside_mixture_field()


func _get_alchemist_field_speed_multiplier() -> float:
	return _alchemist_archetype()._get_alchemist_field_speed_multiplier()


func _is_alchemist_inside_mixture_field_with_margin(margin: float) -> bool:
	return _alchemist_archetype()._is_alchemist_inside_mixture_field_with_margin(margin)


func _update_alchemist_field_locomotion_state(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_field_locomotion_state(delta)


func _update_alchemist_mixture_field_hero_effects(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_mixture_field_hero_effects(delta)


func _try_cast_alchemist_mixture_field() -> void:
	_alchemist_archetype()._try_cast_alchemist_mixture_field()


func _count_active_alchemist_cauldrons() -> int:
	return _alchemist_archetype()._count_active_alchemist_cauldrons()


func _try_cast_alchemist_mystery_cauldron() -> void:
	_alchemist_archetype()._try_cast_alchemist_mystery_cauldron()


func set_alchemist_cauldron_runtime_paused(paused: bool) -> void:
	_alchemist_archetype().set_alchemist_cauldron_runtime_paused(paused)


func _on_alchemist_cauldron_completed(
	cauldron: Node2D,
	origin: Vector2
) -> void:
	await _alchemist_archetype()._on_alchemist_cauldron_completed(cauldron, origin)


func _execute_alchemist_cauldron_great_success(origin: Vector2) -> void:
	await _alchemist_archetype()._execute_alchemist_cauldron_great_success(origin)


func _acquire_alchemist_mystery_vial() -> Node2D:
	return _alchemist_archetype()._acquire_alchemist_mystery_vial()


func _spawn_alchemist_mystery_vial(origin: Vector2) -> void:
	_alchemist_archetype()._spawn_alchemist_mystery_vial(origin)


func _on_alchemist_mystery_vial_landed(
	landing_position: Vector2,
	_direct_target: Node
) -> void:
	_alchemist_archetype()._on_alchemist_mystery_vial_landed(landing_position, _direct_target)


func _acquire_alchemist_bonus_material() -> Node2D:
	return _alchemist_archetype()._acquire_alchemist_bonus_material()


func _execute_alchemist_cauldron_success(origin: Vector2) -> void:
	_alchemist_archetype()._execute_alchemist_cauldron_success(origin)


func _execute_alchemist_cauldron_failure(origin: Vector2) -> void:
	_alchemist_archetype()._execute_alchemist_cauldron_failure(origin)


func _on_alchemist_mixture_field_tick(origin: Vector2, radius: float) -> void:
	_alchemist_archetype()._on_alchemist_mixture_field_tick(origin, radius)


func _update_alchemist_emergency_escape(delta: float) -> bool:
	return _alchemist_archetype()._update_alchemist_emergency_escape(delta)


func _update_alchemist_escape_direction(
	threats: Array[Node2D],
	trigger_radius: float
) -> float:
	return _alchemist_archetype()._update_alchemist_escape_direction(threats, trigger_radius)


func _cast_alchemist_emergency_escape(
	threats: Array[Node2D],
	escape_direction: Vector2
) -> void:
	_alchemist_archetype()._cast_alchemist_emergency_escape(threats, escape_direction)


func _apply_alchemist_emergency_self_damage() -> void:
	_alchemist_archetype()._apply_alchemist_emergency_self_damage()


func _flash_alchemist_emergency_red() -> void:
	_alchemist_archetype()._flash_alchemist_emergency_red()


func _get_alchemist_chest_attack_target() -> Node2D:
	return _alchemist_archetype()._get_alchemist_chest_attack_target()


func _start_alchemist_basic_attack(direct_chest_target: Node2D = null) -> void:
	_alchemist_archetype()._start_alchemist_basic_attack(direct_chest_target)


func _update_alchemist_throw_sequence(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_throw_sequence(delta)


func _launch_alchemist_vial(
	landing_position: Vector2,
	direct_target: Node2D = null
) -> bool:
	return _alchemist_archetype()._launch_alchemist_vial(landing_position, direct_target)


func _on_alchemist_vial_landed(
	landing_position: Vector2,
	direct_target: Node
) -> void:
	_alchemist_archetype()._on_alchemist_vial_landed(landing_position, direct_target)


func _on_alchemist_poison_tick(origin: Vector2, radius: float, damage: int) -> void:
	_alchemist_archetype()._on_alchemist_poison_tick(origin, radius, damage)


func _update_alchemist_pose_visual(delta: float) -> void:
	_alchemist_archetype()._update_alchemist_pose_visual(delta)


func _physics_process_gunner(delta: float) -> void:
	_gunner_archetype()._physics_process_gunner(delta)


func _update_gunner_pose_visual(delta: float) -> void:
	_gunner_archetype()._update_gunner_pose_visual(delta)


func _apply_archmage_boundary_steering(base_direction: Vector2) -> Vector2:
	return _archmage_archetype()._apply_archmage_boundary_steering(base_direction)


func _apply_gunner_boundary_steering(base_direction: Vector2) -> Vector2:
	return _gunner_archetype()._apply_gunner_boundary_steering(base_direction)


func _gunner_attack(current_target: Node2D) -> void:
	_gunner_archetype()._gunner_attack(current_target)


func _spawn_gunner_bullet(direction: Vector2, is_deadeye_shot: bool = false) -> void:
	_gunner_archetype()._spawn_gunner_bullet(direction, is_deadeye_shot)


func _spawn_gunner_bullet_from(origin: Vector2, direction: Vector2) -> void:
	_gunner_archetype()._spawn_gunner_bullet_from(origin, direction)


func _refresh_gunner_empty_magazine_shield() -> void:
	_gunner_archetype()._refresh_gunner_empty_magazine_shield()


func _gunner_register_ammo_consumed(amount: int) -> void:
	_gunner_archetype()._gunner_register_ammo_consumed(amount)


func _gunner_powder_damage_multiplier() -> float:
	return _gunner_archetype()._gunner_powder_damage_multiplier()


func _start_gunner_reload() -> void:
	_gunner_archetype()._start_gunner_reload()


func _finish_gunner_reload() -> void:
	_gunner_archetype()._finish_gunner_reload()


func _gunner_surround_pressure() -> float:
	return _gunner_archetype()._gunner_surround_pressure()


func _gunner_should_backstep_on_hit() -> bool:
	return _gunner_archetype()._gunner_should_backstep_on_hit()


func _gunner_should_use_cylinder() -> bool:
	return _gunner_archetype()._gunner_should_use_cylinder()


func _start_gunner_backstep() -> void:
	_gunner_archetype()._start_gunner_backstep()


func _spawn_gunner_afterimage(
	world_position: Vector2,
	alpha: float,
	fade_time: float,
	scale_multiplier: float = 1.0
) -> void:
	_gunner_archetype()._spawn_gunner_afterimage(world_position, alpha, fade_time, scale_multiplier)


func _find_gunner_escape_direction() -> Vector2:
	return _gunner_archetype()._find_gunner_escape_direction()

func _update_gunner_collision_ignore(delta: float) -> void:
	_gunner_archetype()._update_gunner_collision_ignore(delta)


func _use_gunner_cylinder_strike() -> void:
	_gunner_archetype()._use_gunner_cylinder_strike()


func _update_gunner_deadeye_aim_analysis() -> void:
	_gunner_archetype()._update_gunner_deadeye_aim_analysis()


func _gunner_should_start_deadeye() -> bool:
	return _gunner_archetype()._gunner_should_start_deadeye()


func _start_gunner_deadeye() -> void:
	_gunner_archetype()._start_gunner_deadeye()


func _update_gunner_deadeye(delta: float) -> void:
	_gunner_archetype()._update_gunner_deadeye(delta)


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
	_rogue_archetype()._physics_process_rogue(delta)

func _rogue_compare_registration_order(a: Node, b: Node) -> bool:
	return _rogue_archetype()._rogue_compare_registration_order(a, b)


func _rogue_combo_attack(current_target: Node2D) -> void:
	_rogue_archetype()._rogue_combo_attack(current_target)

func _start_rogue_attack_collision_ignore(duration: float) -> void:
	_rogue_archetype()._start_rogue_attack_collision_ignore(duration)

func _update_rogue_attack_collision_ignore(delta: float) -> void:
	_rogue_archetype()._update_rogue_attack_collision_ignore(delta)

func _rogue_damage_target(
	current_target: Node2D,
	damage: int,
	lifesteal_efficiency: float = 1.0
) -> int:
	return _rogue_archetype()._rogue_damage_target(current_target, damage, lifesteal_efficiency)

func _apply_rogue_lifesteal(
	actual_damage: int,
	efficiency: float
) -> void:
	_rogue_archetype()._apply_rogue_lifesteal(actual_damage, efficiency)

func _rogue_apply_knockback(
	current_target: Node2D,
	direction: Vector2,
	distance: float
) -> void:
	_rogue_archetype()._rogue_apply_knockback(current_target, direction, distance)

func _rogue_should_use_slash() -> bool:
	return _rogue_archetype()._rogue_should_use_slash()

func _start_rogue_slash() -> void:
	_rogue_archetype()._start_rogue_slash()

func _update_rogue_slash(delta: float) -> void:
	_rogue_archetype()._update_rogue_slash(delta)

func _apply_rogue_slash_tick() -> void:
	_rogue_archetype()._apply_rogue_slash_tick()

func _rogue_can_start_assassination() -> bool:
	return _rogue_archetype()._rogue_can_start_assassination()

func _start_rogue_assassination() -> void:
	_rogue_archetype()._start_rogue_assassination()

func _update_rogue_assassination(delta: float) -> void:
	_rogue_archetype()._update_rogue_assassination(delta)

func _find_rogue_assassination_target() -> Node2D:
	return _rogue_archetype()._find_rogue_assassination_target()

func _end_rogue_assassination() -> void:
	_rogue_archetype()._end_rogue_assassination()

func _play_rogue_effect(
	effect_sprite: AnimatedSprite2D,
	animation_name: String,
	direction: Vector2
) -> void:
	_rogue_archetype()._play_rogue_effect(effect_sprite, animation_name, direction)

func _on_rogue_attack_effect_finished() -> void:
	_rogue_archetype()._on_rogue_attack_effect_finished()

func _update_rogue_pose_visual(delta: float) -> void:
	_rogue_archetype()._update_rogue_pose_visual(delta)

func _on_fighter_guard_release_effect_finished() -> void:
	_fighter_archetype()._on_fighter_guard_release_effect_finished()


func _apply_stage6_berserker_effect_visuals() -> void:
	_berserker_archetype()._apply_stage6_berserker_effect_visuals()


func _apply_alchemist_philosopher_effect_visuals() -> void:
	_alchemist_archetype()._apply_alchemist_philosopher_effect_visuals()


func _configure_channel_effect_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	var before_build: Dictionary = profile.get("before_build", HERO_PRESENTATION.EMPTY_PROFILE)
	for property in before_build:
		channel_effect.set(property, before_build[property])
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var animation: StringName = profile["animation"]
	frames.add_animation(animation)
	var fps := float(profile["fps"])
	if profile.has("config_property"):
		var config: Dictionary = get(profile["config_property"])
		fps = maxf(float(config.get(profile["fps_key"], fps)), float(profile["minimum_fps"]))
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, bool(profile["loop"]))
	for group in profile["frame_groups"]:
		for index in range(int(group["first"]), int(group["last"]) + 1):
			var texture := _load_stage1_texture(String(group["path_pattern"]) % index)
			if texture == null:
				if bool(group["required"]):
					return
				continue
			frames.add_frame(animation, texture)
	if bool(profile.get("stop_before_assign", false)):
		channel_effect.stop()
	channel_effect.sprite_frames = frames
	var properties: Dictionary = profile["properties"]
	for property in properties:
		channel_effect.set(property, properties[property])


func _apply_profile_visual() -> void:
	hero_sprite.visible = false
	hero_sprite.sprite_frames = null
	hero_sprite.modulate = Color.WHITE
	hero_sprite.rotation = 0.0
	hero_sprite.offset = Vector2.ZERO
	hero_sprite.z_index = 1
	hero_sprite.show_behind_parent = false
	hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var profile := HERO_PRESENTATION.get_visual_profile(hero_id, hero_archetype)
	if profile.is_empty():
		return
	var frame_dir := sprite_frame_dir if not sprite_frame_dir.is_empty() else String(profile["frame_dir"])
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for rule in profile["animations"]:
		var loaded: bool
		if rule.has("indices"):
			loaded = _add_profile_indexed_animation(frames, frame_dir, rule)
		else:
			loaded = _add_named_sequence_animation(
				frames, rule["name"], frame_dir, rule["prefix"],
				int(rule["count"]), float(rule["fps"]), bool(rule["loop"])
			)
		if not loaded and bool(rule["required"]):
			return
	hero_sprite.sprite_frames = frames
	hero_sprite.visible = true
	var sprite_properties: Dictionary = profile.get("sprite_properties", HERO_PRESENTATION.EMPTY_PROFILE)
	for property in sprite_properties:
		hero_sprite.set(property, sprite_properties[property])
	for method in profile.get("before_scale_methods", HERO_PRESENTATION.EMPTY_METHODS):
		call(method)
	_apply_normalized_hero_visual_scale()
	for method in profile.get("after_scale_methods", HERO_PRESENTATION.EMPTY_METHODS):
		call(method)
	hero_sprite.speed_scale = 1.0
	hero_sprite.play("idle")
	for method in profile.get("after_play_methods", HERO_PRESENTATION.EMPTY_METHODS):
		call(method)


func _configure_profile_animation(frames: SpriteFrames, rule: Dictionary) -> void:
	frames.add_animation(rule["name"])
	frames.set_animation_speed(rule["name"], float(rule["fps"]))
	frames.set_animation_loop(rule["name"], bool(rule["loop"]))


func _add_profile_indexed_animation(frames: SpriteFrames, frame_dir: String, rule: Dictionary) -> bool:
	var configured := not bool(rule.get("defer_configuration", false))
	if configured:
		_configure_profile_animation(frames, rule)
	for frame_index in rule["indices"]:
		var texture := _load_stage1_texture("%s/%s_%02d.png" % [frame_dir, rule["prefix"], frame_index])
		if texture == null:
			push_warning(String(rule["failure_message"]) % [frame_dir, frame_index])
			return false
		if not configured:
			_configure_profile_animation(frames, rule)
			configured = true
		frames.add_frame(rule["name"], texture)
	return true

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

	var target_height := HERO_PRESENTATION.resolve_target_height(
		hero_id, _get_stage1_reference_render_height()
	)

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

func _apply_stage2_rogue_effect_visuals() -> void:
	_rogue_archetype()._apply_stage2_rogue_effect_visuals()

func _apply_stage1_shield_visual() -> void:
	_configure_scaled_effect_profile(HERO_PRESENTATION.get_scaled_effect_profile(&"rookie_shield"))

func _apply_stage1_channel_visual() -> void:
	_configure_scaled_effect_profile(HERO_PRESENTATION.get_scaled_effect_profile(&"rookie_channel"))

func _load_stage1_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var prepared := PresentationWarmup.get_texture(path)
	if prepared != null:
		return prepared

	# Reuse imported resources across actors/pools. Raw PNGs packaged alongside
	# imports must not create another GPU texture for every projectile instance.
	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)

	return null

func _hero_animation_priority(animation_name: StringName) -> int:
	return HERO_PRESENTATION.animation_priority(animation_name)

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

	var now_msec := COMBAT_DELAY.now_msec(self)
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
	for method in HERO_PRESENTATION.get_frame_change_methods(hero_archetype):
		call(method)

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
	if player_controlled: locked = true
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
	if player_controlled: return
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
	if player_controlled:
		_execute_ai_movement(_player_move_velocity())
		return
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
	var now_msec := COMBAT_DELAY.now_msec(self)
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
	if player_controlled: player_moved_this_frame = true
	if petrify_timer > 0.0:
		velocity = Vector2.ZERO
		return
	if player_controlled and not player_input_suspended and not fighter_charge_active and not rogue_assassination_active:
		velocity = _player_move_velocity()
		move_and_slide()
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
	if hp_ratio >= PICKUP_SEEK.HEAL_CLEAR_HP_RATIO:
		heal_item_target = null
		heal_item_steering_direction = Vector2.ZERO
		return

	# Low-HP heroes commit to a valid potion instead of periodically
	# retargeting and oscillating around it.
	if (
		hp_ratio <= PICKUP_SEEK.HEAL_COMMIT_HP_RATIO
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

	heal_item_retarget_timer = randf_range(
		PICKUP_SEEK.HEAL_RETARGET_INTERVAL_MIN,
		PICKUP_SEEK.HEAL_RETARGET_INTERVAL_MAX
	)
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
	var critical_factor: float = clampf(
		(PICKUP_SEEK.HEAL_GOAL_CRITICAL_HP_RATIO - hp_ratio) / PICKUP_SEEK.HEAL_GOAL_CRITICAL_SPAN,
		0.0,
		1.0
	)
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
		if hp_ratio > PICKUP_SEEK.HEAL_COMMIT_HP_RATIO and distance > PICKUP_SEEK.HEAL_DETOUR_MAX_DISTANCE:
			continue

		var path_midpoint: Vector2 = global_position.lerp(item.global_position, 0.5)
		var path_danger: float = _estimate_monster_danger(path_midpoint, PICKUP_SEEK.HEAL_PATH_DANGER_RADIUS)
		var item_danger: float = _estimate_monster_danger(item.global_position, PICKUP_SEEK.HEAL_ITEM_DANGER_RADIUS)
		var distance_penalty: float = clampf(distance / PICKUP_SEEK.HEAL_DISTANCE_PENALTY_DIVISOR, 0.0, PICKUP_SEEK.HEAL_DISTANCE_PENALTY_CAP)
		var danger_scale: float = lerpf(PICKUP_SEEK.HEAL_DANGER_SCALE_FROM, PICKUP_SEEK.HEAL_DANGER_SCALE_TO, critical_factor)
		var danger_penalty: float = (
			(path_danger * PICKUP_SEEK.HEAL_PATH_DANGER_WEIGHT + item_danger)
			* lerpf(PICKUP_SEEK.HEAL_RISK_SCALE_FROM, PICKUP_SEEK.HEAL_RISK_SCALE_TO, risk_tolerance)
			* danger_scale
		)
		var score: float = desire * lerpf(PICKUP_SEEK.HEAL_SCORE_FROM, PICKUP_SEEK.HEAL_SCORE_TO, critical_factor)
		score -= distance_penalty
		score -= danger_penalty

		if score > best_score and score > PICKUP_SEEK.HEAL_MIN_SCORE:
			best_score = score
			heal_item_target = item

	if not is_instance_valid(heal_item_target):
		heal_item_steering_direction = Vector2.ZERO


func _heal_item_desire_for_hp(hp_ratio: float) -> float:
	return PICKUP_SEEK.heal_desire_for_hp(hp_ratio)


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
	chest_retarget_timer = PICKUP_SEEK.CHEST_RETARGET_INTERVAL
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
		and float(current_hp) / float(max_hp) <= PICKUP_SEEK.HEAL_PRIORITY_HP_RATIO
	):
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	if not is_instance_valid(chest_target) or chest_target.is_queued_for_deletion():
		chest_target = null
		chest_steering_direction = Vector2.ZERO
		return base_direction.normalized() if base_direction.length_squared() > 0.01 else Vector2.ZERO

	var distance := global_position.distance_to(chest_target.global_position)
	var chest_direction := global_position.direction_to(chest_target.global_position)
	# 상자는 행동을 취소하는 목표가 아니라 장기적인 이동 편향이다.
	var chest_weight := lerpf(
		PICKUP_SEEK.CHEST_WEIGHT_FROM,
		PICKUP_SEEK.CHEST_WEIGHT_TO,
		clampf(1.0 - distance / PICKUP_SEEK.CHEST_WEIGHT_DISTANCE, 0.0, 1.0)
	)
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
			clampf(delta * PICKUP_SEEK.CHEST_TURN_SPEED, 0.0, 1.0)
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
	magnet_item_retarget_timer = PICKUP_SEEK.MAGNET_RETARGET_INTERVAL
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
		and float(current_hp) / float(max_hp) <= PICKUP_SEEK.HEAL_PRIORITY_HP_RATIO
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
		PICKUP_SEEK.MAGNET_WEIGHT_FROM,
		PICKUP_SEEK.MAGNET_WEIGHT_TO,
		clampf(1.0 - distance / PICKUP_SEEK.MAGNET_WEIGHT_DISTANCE, 0.0, 1.0)
	)
	var local_danger := _estimate_monster_danger(
		global_position,
		PICKUP_SEEK.MAGNET_DANGER_RADIUS
	)
	magnet_weight /= 1.0 + local_danger * PICKUP_SEEK.MAGNET_DANGER_DAMPING

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
				clampf(delta * PICKUP_SEEK.MAGNET_TURN_SPEED, 0.0, 1.0)
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
	var avoidance: Vector2 = _get_crowd_avoidance_direction(PICKUP_SEEK.HEAL_STEER_CROWD_RADIUS)
	var local_danger: float = _estimate_monster_danger(global_position, PICKUP_SEEK.HEAL_STEER_DANGER_RADIUS)
	var critical_factor: float = clampf(
		(PICKUP_SEEK.HEAL_STEER_CRITICAL_HP_RATIO - hp_ratio) / PICKUP_SEEK.HEAL_STEER_CRITICAL_SPAN,
		0.0,
		1.0
	)

	# Human-like potion behavior:
	# from far away, drift toward the potion while still fighting / avoiding;
	# once close enough, progressively commit so the hero actually finishes
	# the pickup instead of circling just outside the collection radius.
	var close_commit: float = clampf(
		(PICKUP_SEEK.HEAL_CLOSE_COMMIT_DISTANCE - distance_to_heal) / PICKUP_SEEK.HEAL_CLOSE_COMMIT_SPAN,
		0.0,
		1.0
	)
	var heal_weight: float = clampf(
		desire
		* lerpf(PICKUP_SEEK.HEAL_WEIGHT_CRITICAL_FROM, PICKUP_SEEK.HEAL_WEIGHT_CRITICAL_TO, critical_factor)
		* lerpf(PICKUP_SEEK.HEAL_WEIGHT_CLOSE_FROM, PICKUP_SEEK.HEAL_WEIGHT_CLOSE_TO, close_commit),
		0.0,
		PICKUP_SEEK.HEAL_WEIGHT_CAP
	)
	var combat_weight: float = lerpf(
		maxf(PICKUP_SEEK.HEAL_COMBAT_WEIGHT_FLOOR, 1.0 - heal_weight * PICKUP_SEEK.HEAL_COMBAT_WEIGHT_REDUCTION),
		PICKUP_SEEK.HEAL_COMBAT_WEIGHT_COMMITTED,
		close_commit * lerpf(PICKUP_SEEK.HEAL_COMMIT_CRITICAL_FROM, PICKUP_SEEK.HEAL_COMMIT_CRITICAL_TO, critical_factor)
	)
	var avoidance_weight: float = (
		(PICKUP_SEEK.HEAL_AVOID_BASE + local_danger * PICKUP_SEEK.HEAL_AVOID_DANGER_WEIGHT)
		* lerpf(PICKUP_SEEK.HEAL_AVOID_RISK_FROM, PICKUP_SEEK.HEAL_AVOID_RISK_TO, risk_tolerance)
		* detour_weight
		* lerpf(PICKUP_SEEK.HEAL_AVOID_CRITICAL_FROM, PICKUP_SEEK.HEAL_AVOID_CRITICAL_TO, critical_factor)
		* lerpf(PICKUP_SEEK.HEAL_AVOID_CLOSE_FROM, PICKUP_SEEK.HEAL_AVOID_CLOSE_TO, close_commit)
	)

	var desired: Vector2 = (
		base_direction * combat_weight
		+ heal_direction * heal_weight
	)
	if avoidance.length_squared() > 0.01:
		desired += avoidance * avoidance_weight

	# Inside the final approach, keep a small amount of natural movement but
	# bias strongly enough toward the potion to cross the pickup threshold.
	if distance_to_heal <= PICKUP_SEEK.HEAL_FINAL_APPROACH_DISTANCE:
		desired = (
			desired * PICKUP_SEEK.HEAL_FINAL_APPROACH_KEEP
			+ heal_direction * PICKUP_SEEK.HEAL_FINAL_APPROACH_PULL
		)

	if desired.length_squared() <= 0.01:
		desired = heal_direction
	desired = desired.normalized()

	if heal_item_steering_direction.length_squared() <= 0.01:
		heal_item_steering_direction = desired
	else:
		var turn_speed: float = lerpf(
			PICKUP_SEEK.HEAL_TURN_SPEED_FROM,
			PICKUP_SEEK.HEAL_TURN_SPEED_TO,
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
		if bool(battle.get("online_match_mode")): return null # Never scan another match.

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
	_purifier_archetype()._ensure_purifier_basic_audio()


func _play_purifier_basic_audio() -> void:
	_purifier_archetype()._play_purifier_basic_audio()


func _fire_projectile(current_target: Node2D) -> void:
	if channeling:
		return
	if not is_instance_valid(current_target):
		return
	var override: StringName = HERO_RUNTIME_BINDINGS.PROJECTILE_OVERRIDES.get(hero_archetype, &"")
	if override != &"":
		call(override, current_target)
		return

	var shot_direction := global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	attack_timer = _get_common_attack_interval(attack_cooldown)
	attack_pose_timer = 0.34
	_face_attack_direction(shot_direction.x)
	_restart_stage1_animation("attack")
	_play_ordered_hero_audio(&"basic")

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
	return _sage_archetype()._get_sage_augment_stacks(augment_id)


func _consume_one_sage_condensation_stack() -> bool:
	return _sage_archetype()._consume_one_sage_condensation_stack()


func _apply_sage_mana_conversion(incoming_damage: float) -> float:
	return _sage_archetype()._apply_sage_mana_conversion(incoming_damage)


func _ensure_sage_runtime() -> void:
	_sage_archetype()._ensure_sage_runtime()


func _ensure_sage_condensation_visuals() -> void:
	_sage_archetype()._ensure_sage_condensation_visuals()


func _reset_sage_condensation_slots() -> void:
	_sage_archetype()._reset_sage_condensation_slots()


func _ensure_sage_starlight_aura() -> void:
	_sage_archetype()._ensure_sage_starlight_aura()


func _set_sage_starlight_aura_active(active: bool) -> void:
	_sage_archetype()._set_sage_starlight_aura_active(active)


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
			STAGE1_BASIC_ATTACK_AUDIO_PATH, HERO_SFX_DB_PRIMARY_ATTACK, 1.0
		)
	if not is_instance_valid(stage1_barrier_audio):
		stage1_barrier_audio = _create_stage1_audio_player(
			STAGE1_BARRIER_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL, 1.0
		)
	if not is_instance_valid(stage1_arcane_field_audio):
		stage1_arcane_field_audio = _create_stage1_audio_player(
			STAGE1_ARCANE_FIELD_AUDIO_PATH, HERO_SFX_DB_REGULAR_SKILL, 1.0
		)
	if not is_instance_valid(stage1_arcane_piercer_audio):
		stage1_arcane_piercer_audio = _create_stage1_audio_player(
			STAGE1_ARCANE_PIERCER_AUDIO_PATH, HERO_SFX_DB_HEAVY_SKILL, 1.0
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
	_rogue_archetype()._ensure_rogue_audio_runtime()


func _play_rogue_combo_audio(_combo_index: int) -> void:
	_rogue_archetype()._play_rogue_combo_audio(_combo_index)


func _play_rogue_blade_storm_audio() -> void:
	_rogue_archetype()._play_rogue_blade_storm_audio()


func _play_rogue_assassination_start_audio() -> void:
	_rogue_archetype()._play_rogue_assassination_start_audio()


func _play_rogue_assassination_hit_audio() -> void:
	_rogue_archetype()._play_rogue_assassination_hit_audio()


func _play_rogue_hit_audio() -> void:
	_rogue_archetype()._play_rogue_hit_audio()


func _play_rogue_death_audio() -> void:
	_rogue_archetype()._play_rogue_death_audio()


func _ensure_fighter_audio_runtime() -> void:
	_fighter_archetype()._ensure_fighter_audio_runtime()


func _play_fighter_slash_audio() -> void:
	_fighter_archetype()._play_fighter_slash_audio()


func _play_fighter_thrust_audio(is_charge: bool = false) -> void:
	_fighter_archetype()._play_fighter_thrust_audio(is_charge)


func _play_fighter_guard_start_audio() -> void:
	_fighter_archetype()._play_fighter_guard_start_audio()


func _play_fighter_guard_release_audio() -> void:
	_fighter_archetype()._play_fighter_guard_release_audio()


func _play_fighter_charge_impact_audio() -> void:
	_fighter_archetype()._play_fighter_charge_impact_audio()


func _play_fighter_hit_audio() -> void:
	_fighter_archetype()._play_fighter_hit_audio()


func _play_fighter_death_audio() -> void:
	_fighter_archetype()._play_fighter_death_audio()


func _ensure_gunner_audio_runtime() -> void:
	_gunner_archetype()._ensure_gunner_audio_runtime()


func _play_gunner_basic_shot_audio() -> void:
	_gunner_archetype()._play_gunner_basic_shot_audio()


func _play_gunner_deadeye_shot_audio() -> void:
	_gunner_archetype()._play_gunner_deadeye_shot_audio()


func _play_gunner_audio(player: AudioStreamPlayer) -> void:
	_gunner_archetype()._play_gunner_audio(player)


func _play_gunner_reload_audio() -> void:
	_gunner_archetype()._play_gunner_reload_audio()


func _play_gunner_backstep_audio() -> void:
	_gunner_archetype()._play_gunner_backstep_audio()


func _play_gunner_cylinder_audio() -> void:
	_gunner_archetype()._play_gunner_cylinder_audio()


func _play_gunner_deadeye_start_audio() -> void:
	_gunner_archetype()._play_gunner_deadeye_start_audio()


func _play_gunner_hit_audio() -> void:
	_gunner_archetype()._play_gunner_hit_audio()


func _play_gunner_death_audio() -> void:
	_gunner_archetype()._play_gunner_death_audio()


func _ensure_archmage_audio_runtime() -> void:
	_archmage_archetype()._ensure_archmage_audio_runtime()


func _play_archmage_player(player: AudioStreamPlayer) -> void:
	_archmage_archetype()._play_archmage_player(player)


func _play_archmage_basic_audio(element: String) -> void:
	_archmage_archetype()._play_archmage_basic_audio(element)


func _play_archmage_earth_spike_audio() -> void:
	_archmage_archetype()._play_archmage_earth_spike_audio()


func _play_archmage_holy_burst_audio() -> void:
	_archmage_archetype()._play_archmage_holy_burst_audio()


func play_archmage_chain_hit_audio() -> void:
	_archmage_archetype().play_archmage_chain_hit_audio()


func _play_archmage_hit_audio() -> void:
	_archmage_archetype()._play_archmage_hit_audio()


func _play_archmage_death_audio() -> void:
	_archmage_archetype()._play_archmage_death_audio()


func _ensure_berserker_audio_runtime() -> void:
	_berserker_archetype()._ensure_berserker_audio_runtime()


func _play_berserker_player(player: AudioStreamPlayer) -> void:
	_berserker_archetype()._play_berserker_player(player)


func _play_berserker_basic_audio() -> void:
	_berserker_archetype()._play_berserker_basic_audio()


func _play_berserker_skill1_audio(wave_index: int) -> void:
	_berserker_archetype()._play_berserker_skill1_audio(wave_index)


func _play_berserker_hit_audio() -> void:
	_berserker_archetype()._play_berserker_hit_audio()


func _play_berserker_death_audio() -> void:
	_berserker_archetype()._play_berserker_death_audio()


func _create_sage_audio_player(audio_path: String, volume_db: float, pitch_scale: float) -> AudioStreamPlayer:
	return _sage_archetype()._create_sage_audio_player(audio_path, volume_db, pitch_scale)


func _play_sage_audio(player: AudioStreamPlayer) -> void:
	_sage_archetype()._play_sage_audio(player)


func _fire_sage_projectile(current_target: Node2D) -> void:
	_sage_archetype()._fire_sage_projectile(current_target)


func _add_sage_gauge(amount: float) -> void:
	_sage_archetype()._add_sage_gauge(amount)


func is_sage_skill_ready() -> bool:
	return _sage_archetype().is_sage_skill_ready()


func _update_sage_runtime(delta: float) -> void:
	_sage_archetype()._update_sage_runtime(delta)


func _try_cast_sage_ice_pillar() -> void:
	_sage_archetype()._try_cast_sage_ice_pillar()


func _try_cast_sage_radiance_singularity() -> bool:
	return _sage_archetype()._try_cast_sage_radiance_singularity()


func _launch_sage_radiance_orb() -> void:
	_sage_archetype()._launch_sage_radiance_orb()


func _try_cast_sage_annihilation() -> bool:
	return _sage_archetype()._try_cast_sage_annihilation()


func _try_cast_sage_starlight() -> bool:
	return _sage_archetype()._try_cast_sage_starlight()


func _launch_sage_starlight_volley(skill: Dictionary) -> void:
	_sage_archetype()._launch_sage_starlight_volley(skill)


func _try_cast_sage_mana_condensation() -> bool:
	return _sage_archetype()._try_cast_sage_mana_condensation()


func _add_sage_condensation_stack(skill: Dictionary) -> void:
	_sage_archetype()._add_sage_condensation_stack(skill)


func _consume_sage_condensation(skill: Dictionary) -> void:
	_sage_archetype()._consume_sage_condensation(skill)


func _get_sage_condensation_cooldown_reduction() -> float:
	return _sage_archetype()._get_sage_condensation_cooldown_reduction()


func _get_sage_condensation_cooldown_rate() -> float:
	return _sage_archetype()._get_sage_condensation_cooldown_rate()


func _get_sage_skill_damage_multiplier() -> float:
	return _sage_archetype()._get_sage_skill_damage_multiplier()


func _ensure_sage_blackspot_pool() -> void:
	_sage_archetype()._ensure_sage_blackspot_pool()

func _on_sage_skill_hit(hit_position: Vector2) -> void:
	_sage_archetype()._on_sage_skill_hit(hit_position)


func _on_sage_blackspot_kill() -> void:
	_sage_archetype()._on_sage_blackspot_kill()


func _try_start_sage_late_skill_unlock_sequence(skill: Dictionary) -> void:
	_sage_archetype()._try_start_sage_late_skill_unlock_sequence(skill)


func _play_sage_condensation_unlock_effect(skill: Dictionary) -> void:
	_sage_archetype()._play_sage_condensation_unlock_effect(skill)


func _hide_sage_condensation_unlock_sprite(
	sprite: AnimatedSprite2D,
	visual_scale: float
) -> void:
	_sage_archetype()._hide_sage_condensation_unlock_sprite(sprite, visual_scale)


func _emit_sage_late_skill_unlock_cutscene() -> void:
	_sage_archetype()._emit_sage_late_skill_unlock_cutscene()


func _start_sage_phase() -> void:
	_sage_archetype()._start_sage_phase()


func _end_sage_phase() -> void:
	_sage_archetype()._end_sage_phase()


func _resolve_sage_phase_obstacle_overlap() -> void:
	_sage_archetype()._resolve_sage_phase_obstacle_overlap()


func _sage_phase_landing_is_clear(
	candidate: Vector2,
	query: PhysicsShapeQueryParameters2D,
	space: PhysicsDirectSpaceState2D,
	shape_offset: Vector2
) -> bool:
	return _sage_archetype()._sage_phase_landing_is_clear(candidate, query, space, shape_offset)


func _apply_sage_phase_landing(candidate: Vector2) -> void:
	_sage_archetype()._apply_sage_phase_landing(candidate)


func _emit_sage_afterimage() -> void:
	_sage_archetype()._emit_sage_afterimage()


func _on_sage_afterimage_finished(ghost: AnimatedSprite2D) -> void:
	_sage_archetype()._on_sage_afterimage_finished(ghost)


func _fire_archmage_projectile(current_target: Node2D) -> void:
	_archmage_archetype()._fire_archmage_projectile(current_target)


func _configure_archmage_basic_elements() -> void:
	_archmage_archetype()._configure_archmage_basic_elements()


func _roll_next_archmage_element() -> String:
	return _archmage_archetype()._roll_next_archmage_element()



func _update_archmage_skill_runtime(delta: float) -> void:
	_archmage_archetype()._update_archmage_skill_runtime(delta)

func _add_archmage_gauge(amount: float) -> void:
	_archmage_archetype()._add_archmage_gauge(amount)


func restore_archmage_gauge(amount: float) -> void:
	_archmage_archetype().restore_archmage_gauge(amount)


func _choose_archmage_skill() -> String:
	return _archmage_archetype()._choose_archmage_skill()


func _archmage_skill_ready(skill_key: String) -> bool:
	return _archmage_archetype()._archmage_skill_ready(skill_key)


func _use_archmage_skill(skill_key: String) -> void:
	_archmage_archetype()._use_archmage_skill(skill_key)


func _cast_archmage_skill_internal(
	skill_key: String,
	consume_gauge: bool,
	trigger_multicast: bool
) -> bool:
	return _archmage_archetype()._cast_archmage_skill_internal(skill_key, consume_gauge, trigger_multicast)


func _cancel_archmage_multicast() -> void:
	_archmage_archetype()._cancel_archmage_multicast()

func _start_archmage_multicast(origin_skill: String) -> void:
	await _archmage_archetype()._start_archmage_multicast(origin_skill)

func _skill_damage_multiplier(empowered: bool) -> float:
	return (
		maxf(float(archmage_skill_config.get("empowered_damage_multiplier", 1.50)), 1.0)
		if empowered
		else 1.0
	)


func _begin_archmage_casting_sequence() -> void:
	_archmage_archetype()._begin_archmage_casting_sequence()


func _end_archmage_casting_sequence() -> void:
	_archmage_archetype()._end_archmage_casting_sequence()


func _cast_archmage_combustion(config: Dictionary, empowered: bool) -> void:
	await _archmage_archetype()._cast_archmage_combustion(config, empowered)


func _cast_archmage_ice_bolt(config: Dictionary, empowered: bool) -> void:
	_archmage_archetype()._cast_archmage_ice_bolt(config, empowered)


func resolve_archmage_ice_bolt_hit(
	_hit_target: Node2D,
	hit_position: Vector2,
	empowered: bool
) -> void:
	_archmage_archetype().resolve_archmage_ice_bolt_hit(_hit_target, hit_position, empowered)


func _capture_delayed_skill_source(require_alive: bool = true) -> Vector3i:
	# Scalar reservation: no RefCounted locals retained by abandoned awaits.
	if not is_inside_tree() or is_queued_for_deletion() or (require_alive and current_hp <= 0):
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
	await _archmage_archetype()._resolve_archmage_ice_pillars(hit_position, empowered)


func _cast_archmage_earth_spikes(config: Dictionary, empowered: bool) -> void:
	await _archmage_archetype()._cast_archmage_earth_spikes(config, empowered)

func _find_archmage_holy_cluster_target(config: Dictionary) -> Node2D:
	return _archmage_archetype()._find_archmage_holy_cluster_target(config)


func _cast_archmage_holy_power(config: Dictionary, empowered: bool) -> void:
	await _archmage_archetype()._cast_archmage_holy_power(config, empowered)

func _get_archmage_chain_dagger_targets(
	max_count: int,
	search_radius: float
) -> Array[Node2D]:
	return _archmage_archetype()._get_archmage_chain_dagger_targets(max_count, search_radius)


func _cast_archmage_chain_dagger(config: Dictionary, empowered: bool) -> void:
	_archmage_archetype()._cast_archmage_chain_dagger(config, empowered)


func notify_archmage_chain_dagger_finished() -> void:
	_archmage_archetype().notify_archmage_chain_dagger_finished()


func _archmage_is_surrounded_for_blink() -> bool:
	return _archmage_archetype()._archmage_is_surrounded_for_blink()


func _archmage_blink_cooldown() -> float:
	return _archmage_archetype()._archmage_blink_cooldown()


func _cast_archmage_blink() -> void:
	_archmage_archetype()._cast_archmage_blink()


func _cast_archmage_harmony(config: Dictionary) -> void:
	_archmage_archetype()._cast_archmage_harmony(config)


func _cast_archmage_storm(config: Dictionary, empowered: bool) -> void:
	_archmage_archetype()._cast_archmage_storm(config, empowered)


func _collect_archmage_element(element: String) -> void:
	_archmage_archetype()._collect_archmage_element(element)

func _archmage_has_all_element_orbs() -> bool:
	return _archmage_archetype()._archmage_has_all_element_orbs()


func _refresh_archmage_orbit_visuals() -> void:
	_archmage_archetype()._refresh_archmage_orbit_visuals()


func _update_archmage_orbit_positions() -> void:
	_archmage_archetype()._update_archmage_orbit_positions()


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
	return _archmage_archetype()._spawn_archmage_fx(dir, prefix, start, count, fps, looped, world_position, fx_scale)


func _recycle_archmage_fx_if_current(fx: AnimatedSprite2D, revision: int, scope_id: int) -> void:
	_archmage_archetype()._recycle_archmage_fx_if_current(fx, revision, scope_id)

func _recycle_archmage_fx(fx: AnimatedSprite2D) -> void:
	_archmage_archetype()._recycle_archmage_fx(fx)


func _damage_monsters_in_radius(origin: Vector2, radius: float, damage: int, source_life: Vector3i = Vector3i.ZERO, source_scope_id: int = 0, require_alive: bool = true) -> void:
	var radius_sq := radius * radius
	_fill_monster_nodes_near(origin, radius, _combat_monster_scratch)
	for node in _combat_monster_scratch:
		if source_scope_id != 0 and (
			not _is_delayed_skill_life_current(source_life, source_scope_id)
			or (require_alive and current_hp <= 0)
		):
			break
		if not is_instance_valid(node):
			continue
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if origin.distance_squared_to(monster.global_position) <= radius_sq:
			preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "ranged" if _is_ranged_ai_archetype() else "melee", self)
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
			preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "ranged" if _is_ranged_ai_archetype() else "melee", self)
	_combat_monster_scratch.clear()

func _damage_monsters_in_corridor(
	start: Vector2,
	end: Vector2,
	half_width: float,
	damage: int,
	source_life: Vector3i = Vector3i.ZERO,
	source_scope_id: int = 0
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
		if source_scope_id != 0 and not _is_delayed_skill_source_current(source_life, source_scope_id):
			break
		if not is_instance_valid(node):
			continue
		if not HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var t := clampf((monster.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var closest := start + segment * t
		if monster.global_position.distance_squared_to(closest) <= half_width_sq:
			preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "ranged" if _is_ranged_ai_archetype() else "melee", self)
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
	_play_bound_hero_audio(&"channel")

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

		preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "ranged" if _is_ranged_ai_archetype() else "melee", self)
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

	shield_max_hp = _player_shield_amount(configured_hp)
	shield_hp = shield_max_hp
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
	_play_bound_hero_audio(&"shield")

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
	return _purifier_archetype()._build_purifier_effect_frames(effect_dir, start_first, start_last, sustain_first, sustain_last, end_first, end_last)


func _create_purifier_audio_player(
	audio_path: String,
	volume_db: float,
	pitch_scale: float = 1.0
) -> AudioStreamPlayer:
	return _purifier_archetype()._create_purifier_audio_player(audio_path, volume_db, pitch_scale)


func _ensure_purifier_skill_runtime() -> void:
	_purifier_archetype()._ensure_purifier_skill_runtime()


func _play_purifier_audio(player: AudioStreamPlayer) -> void:
	_purifier_archetype()._play_purifier_audio(player)


func _on_purifier_protection_effect_finished() -> void:
	_purifier_archetype()._on_purifier_protection_effect_finished()


func _on_purifier_crown_effect_finished() -> void:
	_purifier_archetype()._on_purifier_crown_effect_finished()


func _play_purifier_effect(effect: AnimatedSprite2D, animation_name: StringName) -> void:
	_purifier_archetype()._play_purifier_effect(effect, animation_name)


func _get_purifier_augment_stacks(augment_id: String) -> int:
	return _purifier_archetype()._get_purifier_augment_stacks(augment_id)


func _get_purifier_crown_effect_multiplier() -> float:
	return _purifier_archetype()._get_purifier_crown_effect_multiplier()


func _get_purifier_crown_max_stacks() -> int:
	return _purifier_archetype()._get_purifier_crown_max_stacks()


func _get_purifier_orb_damage_multiplier() -> float:
	return _purifier_archetype()._get_purifier_orb_damage_multiplier()


func _get_purifier_orb_range_multiplier() -> float:
	return _purifier_archetype()._get_purifier_orb_range_multiplier()


func _get_purifier_orb_explosion_radius() -> float:
	return _purifier_archetype()._get_purifier_orb_explosion_radius()


func _get_purifier_skill_cooldown_multiplier() -> float:
	return _purifier_archetype()._get_purifier_skill_cooldown_multiplier()


func _get_purifier_move_speed_multiplier() -> float:
	return _purifier_archetype()._get_purifier_move_speed_multiplier()

func _is_purifier_undead_target(target_node: Node) -> bool:
	return _purifier_archetype()._is_purifier_undead_target(target_node)


func get_purifier_holy_damage_multiplier(target_node: Node = null) -> float:
	return _purifier_archetype().get_purifier_holy_damage_multiplier(target_node)

func notify_monster_kill(_monster_type: String = "") -> void:
	if player_controlled and player_weapons != null:
		if player_weapons.identity != null and not is_dying and current_hp > 0: player_weapons.identity.notify_kill()
		return
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
	_purifier_archetype()._add_purifier_shield_layer()


func _try_activate_purifier_protection() -> void:
	_purifier_archetype()._try_activate_purifier_protection()


func _trigger_purifier_protection_break_pulse() -> void:
	_purifier_archetype()._trigger_purifier_protection_break_pulse()


func _end_purifier_protection(broken: bool) -> void:
	_purifier_archetype()._end_purifier_protection(broken)


func _cast_purifier_crown() -> void:
	_purifier_archetype()._cast_purifier_crown()


func _expire_purifier_crown() -> void:
	_purifier_archetype()._expire_purifier_crown()


func _clear_purifier_orb_runtime() -> void:
	_purifier_archetype()._clear_purifier_orb_runtime()


func _is_purifier_orb_active(orb: Node2D) -> bool:
	return _purifier_archetype()._is_purifier_orb_active(orb)


func _get_active_purifier_orbs() -> Array[Node2D]:
	return _purifier_archetype()._get_active_purifier_orbs()


func _purifier_orb_link_key(a: Node2D, b: Node2D) -> String:
	return _purifier_archetype()._purifier_orb_link_key(a, b)


func _refresh_purifier_orb_links() -> void:
	_purifier_archetype()._refresh_purifier_orb_links()


func _on_purifier_orb_settled(orb: Node2D) -> void:
	_purifier_archetype()._on_purifier_orb_settled(orb)


func _on_purifier_orb_deactivated(_orb: Node2D) -> void:
	_purifier_archetype()._on_purifier_orb_deactivated(_orb)


func _on_purifier_orb_finished(orb: Node2D) -> void:
	_purifier_archetype()._on_purifier_orb_finished(orb)


func _clamp_purifier_orb_target_position(candidate: Vector2) -> Vector2:
	return _purifier_archetype()._clamp_purifier_orb_target_position(candidate)


func _purifier_orb_connection_count(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	return _purifier_archetype()._purifier_orb_connection_count(position, active_orbs)


func _purifier_orb_resulting_component_size(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	return _purifier_archetype()._purifier_orb_resulting_component_size(position, active_orbs)


func _purifier_orb_position_has_spacing(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> bool:
	return _purifier_archetype()._purifier_orb_position_has_spacing(position, active_orbs)


func _choose_purifier_orb_target_position() -> Vector2:
	return _purifier_archetype()._choose_purifier_orb_target_position()


func _spawn_purifier_network_orb(destination: Vector2) -> bool:
	return _purifier_archetype()._spawn_purifier_network_orb(destination)


func _cast_purifier_orb() -> void:
	_purifier_archetype()._cast_purifier_orb()

func _get_purifier_orb_component(start_orb: Node2D) -> Array[Node2D]:
	return _purifier_archetype()._get_purifier_orb_component(start_orb)


func _purifier_orb_install_index(orb: Node2D) -> int:
	return _purifier_archetype()._purifier_orb_install_index(orb)


func _sort_purifier_orbs_by_install_order(
	orbs: Array[Node2D]
) -> void:
	_purifier_archetype()._sort_purifier_orbs_by_install_order(orbs)


func _try_start_purifier_orb_chain_from(orb: Node2D) -> void:
	_purifier_archetype()._try_start_purifier_orb_chain_from(orb)


func _try_start_any_purifier_orb_chain() -> void:
	_purifier_archetype()._try_start_any_purifier_orb_chain()


func _start_purifier_orb_chain(component: Array[Node2D]) -> void:
	_purifier_archetype()._start_purifier_orb_chain(component)


func _get_purifier_orb_chain_interval() -> float:
	return _purifier_archetype()._get_purifier_orb_chain_interval()


func set_purifier_orb_chain_speed_multiplier(multiplier: float) -> void:
	_purifier_archetype().set_purifier_orb_chain_speed_multiplier(multiplier)


func _update_purifier_orb_chain(delta: float) -> void:
	_purifier_archetype()._update_purifier_orb_chain(delta)


func _advance_purifier_orb_chain() -> void:
	_purifier_archetype()._advance_purifier_orb_chain()


func _finish_purifier_orb_chain() -> void:
	_purifier_archetype()._finish_purifier_orb_chain()


func _detonate_purifier_orb(
	orb: Node2D,
	chain_index: int
) -> void:
	_purifier_archetype()._detonate_purifier_orb(orb, chain_index)


func _queue_purifier_prism_burst(
	origin: Vector2,
	source_raw_damage: float,
	source_radius: float
) -> void:
	_purifier_archetype()._queue_purifier_prism_burst(origin, source_raw_damage, source_radius)


func _choose_purifier_prism_target_position(origin: Vector2) -> Vector2:
	return _purifier_archetype()._choose_purifier_prism_target_position(origin)


func _launch_purifier_prism_orb(job: Dictionary) -> void:
	_purifier_archetype()._launch_purifier_prism_orb(job)


func _detonate_purifier_prism_orb(entry: Dictionary) -> void:
	_purifier_archetype()._detonate_purifier_prism_orb(entry)


func _update_purifier_prism(delta: float) -> void:
	_purifier_archetype()._update_purifier_prism(delta)


func _advance_purifier_cleansing_stack() -> void:
	_purifier_archetype()._advance_purifier_cleansing_stack()


func _try_purifier_o_lord_heal(total_damage: int) -> void:
	_purifier_archetype()._try_purifier_o_lord_heal(total_damage)


func _apply_purifier_cleansing_centers(centers: Array[Vector2]) -> int:
	return _purifier_archetype()._apply_purifier_cleansing_centers(centers)


func _trigger_purifier_auto_cleansing(center: Vector2) -> void:
	_purifier_archetype()._trigger_purifier_auto_cleansing(center)

func _get_purifier_cleansing_target_count() -> int:
	return _purifier_archetype()._get_purifier_cleansing_target_count()


func _collect_purifier_cleansing_targets(
	target_count: int
) -> Array[Node2D]:
	return _purifier_archetype()._collect_purifier_cleansing_targets(target_count)


func _spawn_purifier_cleansing_fx(world_position: Vector2) -> void:
	_purifier_archetype()._spawn_purifier_cleansing_fx(world_position)


func _try_unlock_purifier_fourth_skill() -> void:
	_purifier_archetype()._try_unlock_purifier_fourth_skill()


func _cast_purifier_cleansing() -> void:
	_purifier_archetype()._cast_purifier_cleansing()

func _choose_purifier_gungnir_direction() -> Vector2:
	return _purifier_archetype()._choose_purifier_gungnir_direction()


func _try_start_purifier_gungnir() -> bool:
	return _purifier_archetype()._try_start_purifier_gungnir()


func _on_purifier_gungnir_launched() -> void:
	_purifier_archetype()._on_purifier_gungnir_launched()


func _on_purifier_gungnir_impacted() -> void:
	_purifier_archetype()._on_purifier_gungnir_impacted()


func _on_purifier_gungnir_finished(instance: Node2D) -> void:
	_purifier_archetype()._on_purifier_gungnir_finished(instance)


func _update_purifier_gauge(delta: float) -> void:
	_purifier_archetype()._update_purifier_gauge(delta)


func _add_purifier_gauge(amount: float) -> void:
	_purifier_archetype()._add_purifier_gauge(amount)


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
	_play_bound_hero_audio(&"piercing")

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
			preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "ranged", self)
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

	var gained_exp := 0
	if player_controlled:
		# Preserve fractional XP: many one-point orbs must not bypass the reduction.
		var scaled_exp := float(amount)*maxf(exp_gain_multiplier,0.0)*preload("res://src/data/hero_mode_catalog.gd").EXP_REWARD_RATIO+player_exp_remainder
		gained_exp = floori(scaled_exp+0.000000001)
		player_exp_remainder = maxf(0.0,scaled_exp-gained_exp)
	else:
		gained_exp = maxi(1,int(round(float(amount)*maxf(exp_gain_multiplier,0.0))))
	current_exp += gained_exp

	while current_exp >= exp_to_next_level and (not player_controlled or player_augment_candidates.is_empty() or (get_parent() != null and get_parent().get("online_match_mode") == true)):
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
	_sage_archetype()._append_sage_skill1_hud(skills)


func _append_sage_skill2_hud(skills: Array) -> void:
	_sage_archetype()._append_sage_skill2_hud(skills)


func _append_sage_skill3_hud(skills: Array) -> void:
	_sage_archetype()._append_sage_skill3_hud(skills)


func _append_sage_skill4_hud(skills: Array) -> void:
	_sage_archetype()._append_sage_skill4_hud(skills)


func _append_sage_skill5_hud(skills: Array) -> void:
	_sage_archetype()._append_sage_skill5_hud(skills)


func _append_sage_skill6_hud(skills: Array) -> void:
	_sage_archetype()._append_sage_skill6_hud(skills)


func _append_purifier_cleansing_hud(skills: Array) -> void:
	_purifier_archetype()._append_purifier_cleansing_hud(skills)


func _append_purifier_gungnir_hud(skills: Array) -> void:
	_purifier_archetype()._append_purifier_gungnir_hud(skills)


func _append_summoner_open_gate_hud(skills: Array) -> void:
	_summoner_archetype()._append_summoner_open_gate_hud(skills)


func _append_alchemist_philosopher_hud(skills: Array) -> void:
	_alchemist_archetype()._append_alchemist_philosopher_hud(skills)


func _append_berserker_skill_cooldown_hud(
	skills: Array,
	config: Dictionary,
	remaining: float,
	icon_path: String
) -> void:
	_berserker_archetype()._append_berserker_skill_cooldown_hud(skills, config, remaining, icon_path)


func _append_archmage_skill_hud(
	skills: Array,
	skill_key: String,
	icon_path: String
) -> void:
	_archmage_archetype()._append_archmage_skill_hud(skills, skill_key, icon_path)


func _append_gunner_cooldown_hud(
	skills: Array,
	skill_id: String,
	skill_name: String,
	cooldown_total: float,
	remaining: float,
	icon_path: String
) -> void:
	_gunner_archetype()._append_gunner_cooldown_hud(skills, skill_id, skill_name, cooldown_total, remaining, icon_path)


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
	return _summoner_archetype()._get_summoner_augment_ai_settings()


func _level_up() -> void:
	level += 1
	exp_to_next_level = _required_exp_for_level(level)
	level_flash_timer = 0.45
	_play_level_up_feedback()
	_apply_level_growth()
	var milestone: Dictionary = HERO_RUNTIME_BINDINGS.LEVEL_UP_BINDINGS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if milestone.has("pool_interval") and level % int(milestone["pool_interval"]) == 0:
		call(milestone["pool_method"])

	var candidates: Array = player_weapons.candidates() if player_controlled and player_weapons != null else AUGMENT_CATALOG.roll_candidates(
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

	if player_controlled:
		player_augment_candidates = candidates
		health_changed.emit(current_hp,max_hp)
		leveled_up.emit(level)
		player_augment_requested.emit(candidates)
		if (get_parent() != null and get_parent().get("online_match_mode") == true): player_augment_candidates = []
		queue_redraw()
		return

	var ai_context: Dictionary = _get_ai_decision_context()
	var ai_binding: Dictionary = HERO_RUNTIME_BINDINGS.LEVEL_UP_BINDINGS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	var augment_ai_settings: Dictionary = call(ai_binding["ai_settings_method"]) if ai_binding.has("ai_settings_method") else ai_settings
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
	return AUGMENT_CATALOG.get_roll_build_counts(build_counts, hero_archetype)


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
		_dispatch_augment_stack_hook(augment_id)

func _on_purifier_augment_stack_changed(augment_id: String) -> void:
	_purifier_archetype()._on_purifier_augment_stack_changed(augment_id)


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
			# Only cap this augment's contribution; preserve Sage permanent growth.
			var next_bonus := minf(
				common_attack_speed_augment_bonus + maxf(float(effect.get("value", 0.015)), 0.0),
				maxf(float(effect.get("max", 0.30)), 0.0)
			)
			common_attack_speed_bonus += next_bonus-common_attack_speed_augment_bonus
			common_attack_speed_augment_bonus = next_bonus

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
			gunner_low_hp_backstep_bonus = minf(gunner_low_hp_backstep_bonus + maxf(float(effect.get("value", 0.06)), 0.0), maxf(float(effect.get("max", 0.30)), 0.0))

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
				maxi(int(effect.get("max", 2)), 0)
			)

		"archmage_emergency_escape":
			archmage_blink_stacks = mini(
				archmage_blink_stacks + 1,
				5
			)

		"archmage_fast_cast":
			archmage_cooldown_reduction = minf(
				archmage_cooldown_reduction + maxf(float(effect.get("value", 0.04)), 0.0),
				maxf(float(effect.get("max", 0.20)), 0.0)
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

func apply_poison_with_result(duration: float, total_current_hp_ratio: float, receipt, tick_interval: float = 0.50, source: Node = null) -> bool:
	if receipt == null:
		apply_poison(duration, total_current_hp_ratio, tick_interval, source)
		return false
	var revision: int = receipt.begin(self, &"poison", duration, total_current_hp_ratio)
	if not supports_status_receipt():
		apply_poison(duration, total_current_hp_ratio, tick_interval, source)
		return false
	_apply_poison_status(duration, total_current_hp_ratio, tick_interval, source, receipt, revision)
	return receipt.finish(revision)

func apply_poison(
	duration: float,
	total_current_hp_ratio: float,
	tick_interval: float = 0.50,
	source: Node = null
) -> void:
	var revision: int = legacy_status_receipt.begin(self, &"poison", duration, total_current_hp_ratio)
	_apply_poison_status(duration, total_current_hp_ratio, tick_interval, source, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)

func _apply_poison_status(
	duration: float,
	total_current_hp_ratio: float,
	tick_interval: float = 0.50,
	source: Node = null,
	receipt = null,
	receipt_revision: int = 0
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
	if receipt != null:
		receipt.record_application(poison_timer, float(poison_damage_remaining) / maxi(current_hp, 1), receipt_revision)
		receipt.record_damage_budget(poison_damage_remaining, receipt_revision)



func apply_bleed_with_result(duration: float, receipt, source: Node = null, total_max_hp_ratio: float = -1.0, refresh: bool = false) -> bool:
	if receipt == null:
		apply_bleed(duration, source, total_max_hp_ratio, refresh)
		return false
	var revision: int = receipt.begin(self, &"bleed", duration, total_max_hp_ratio)
	if not supports_status_receipt():
		apply_bleed(duration, source, total_max_hp_ratio, refresh)
		return false
	_apply_bleed_status(duration, source, total_max_hp_ratio, refresh, receipt, revision)
	return receipt.finish(revision)

func apply_bleed(duration: float = 5.0, source: Node = null, total_max_hp_ratio: float = -1.0, refresh: bool = false) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"bleed", duration, total_max_hp_ratio)
	var accepted: bool = _apply_bleed_status(duration, source, total_max_hp_ratio, refresh, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_bleed_status(duration: float = 5.0, source: Node = null, total_max_hp_ratio: float = -1.0, refresh: bool = false, receipt = null, receipt_revision: int = 0) -> bool:
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
	if receipt != null:
		receipt.record_application(bleed_timer, float(bleed_total_damage) / maxi(max_hp, 1), receipt_revision)
		receipt.record_damage_budget(bleed_total_damage, receipt_revision)
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


func apply_healing_reduction_with_result(duration: float, reduction: float, receipt) -> bool:
	if receipt == null:
		apply_healing_reduction(duration, reduction)
		return false
	var revision: int = receipt.begin(self, &"healing_reduction", duration, reduction)
	if not supports_status_receipt():
		apply_healing_reduction(duration, reduction)
		return false
	_apply_healing_reduction_status(duration, reduction, receipt, revision)
	return receipt.finish(revision)

func apply_healing_reduction(duration: float, reduction: float) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"healing_reduction", duration, reduction)
	var accepted: bool = _apply_healing_reduction_status(duration, reduction, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_healing_reduction_status(duration: float, reduction: float, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0:
		return false
	healing_reduction_ratio = maxf(healing_reduction_ratio,clampf(reduction,0.0,1.0))
	healing_reduction_timer = maxf(healing_reduction_timer,duration)
	if receipt != null:
		receipt.record_application(healing_reduction_timer, healing_reduction_ratio, receipt_revision)
	record_status_effect_event("healing_reduction")
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self, "healing_reduction")
	return true

func apply_damage_taken_increase_with_result(duration: float, increase: float, receipt) -> bool:
	if receipt == null:
		apply_damage_taken_increase(duration, increase)
		return false
	var revision: int = receipt.begin(self, &"damage_taken_increase", duration, increase)
	if not supports_status_receipt():
		apply_damage_taken_increase(duration, increase)
		return false
	_apply_damage_taken_increase_status(duration, increase, receipt, revision)
	return receipt.finish(revision)

func apply_damage_taken_increase(duration: float, increase: float) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"damage_taken_increase", duration, increase)
	var accepted: bool = _apply_damage_taken_increase_status(duration, increase, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_damage_taken_increase_status(duration: float, increase: float, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0:
		return false
	damage_taken_increase_ratio = maxf(damage_taken_increase_ratio,maxf(increase,0.0))
	damage_taken_increase_timer = maxf(damage_taken_increase_timer,duration)
	if receipt != null:
		receipt.record_application(damage_taken_increase_timer, damage_taken_increase_ratio, receipt_revision)
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

func apply_charm_with_result(source: Node2D, duration: float, receipt) -> bool:
	if receipt == null:
		apply_charm(source, duration)
		return false
	var revision: int = receipt.begin(self, &"charm", duration, 1.0)
	if not supports_status_receipt():
		apply_charm(source, duration)
		return false
	_apply_charm_status(source, duration, receipt, revision)
	return receipt.finish(revision)

func apply_charm(source: Node2D, duration: float) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"charm", duration, 1.0)
	var accepted: bool = _apply_charm_status(source, duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_charm_status(source: Node2D, duration: float, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or charm_timer > 0.0 or charm_immunity_timer > 0.0 or not is_instance_valid(source):
		return false
	if player_controlled:
		duration = player_control_policy.accept(duration, get_status_resistance("charm"))
		if duration <= 0.0: return false
	charm_recovery_immunity = maxf(float(get_meta("incoming_charm_immunity",SUCCUBUS_BEHAVIOR.CHARM.immunity)),0.0)
	charm_stacks = 0
	charm_timer = maxf(duration * (1.0 - get_status_resistance("charm")), 0.05)
	charm_source = weakref(source)
	charm_cooldown_properties = _get_external_skill_cooldown_properties()
	set_meta("charm_active", true)
	if receipt != null:
		receipt.record_application(charm_timer, 1.0, receipt_revision)
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
		charm_immunity_timer = maxf(charm_recovery_immunity - maxf(delta - previous, 0.0), 0.0)
		set_meta("charm_active", false)
	return true

func _tick_charm_state(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta * get_paralysis_attack_multiplier(), 0.0)
	var dictionary_rule: Dictionary = HERO_RUNTIME_BINDINGS.DICTIONARY_COOLDOWNS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if not dictionary_rule.is_empty():
		var cooldowns: Dictionary = get(dictionary_rule["timers_property"])
		for key in dictionary_rule["keys"]:
			cooldowns[key] = maxf(float(cooldowns.get(key, 0.0)) - delta, 0.0)
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

func apply_petrify_with_result(duration: float, receipt, release_slow: float = 1.0, release_duration: float = 0.0) -> bool:
	if receipt == null:
		apply_petrify(duration, release_slow, release_duration)
		return false
	var revision: int = receipt.begin(self, &"petrify", duration, 1.0)
	if not supports_status_receipt():
		apply_petrify(duration, release_slow, release_duration)
		return false
	_apply_petrify_status(duration, release_slow, release_duration, receipt, revision)
	return receipt.finish(revision)

func apply_petrify(duration: float, release_slow: float = 1.0, release_duration: float = 0.0) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"petrify", duration, 1.0)
	var accepted: bool = _apply_petrify_status(duration, release_slow, release_duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_petrify_status(duration: float, release_slow: float = 1.0, release_duration: float = 0.0, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or petrify_timer > 0.0 or duration <= 0.0:
		return false
	if player_controlled:
		duration = player_control_policy.accept(duration, get_status_resistance("petrify"))
		if duration <= 0.0: return false
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
	if receipt != null:
		receipt.record_application(petrify_timer, 1.0, receipt_revision)
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

func apply_damage_poison_with_result(duration: float, total_damage: int, source: Node, receipt, channel: int = 0) -> bool:
	if receipt == null:
		apply_damage_poison(duration, total_damage, source, channel)
		return false
	var revision: int = receipt.begin(self, &"poison", duration, 1.0, total_damage)
	if not supports_status_receipt():
		apply_damage_poison(duration, total_damage, source, channel)
		return false
	_apply_damage_poison_status(duration, total_damage, source, channel, receipt, revision)
	return receipt.finish(revision)

func apply_damage_poison(duration: float, total_damage: int, source: Node, channel: int = 0) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"poison", duration, 1.0, total_damage)
	var accepted: bool = _apply_damage_poison_status(duration, total_damage, source, channel, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_damage_poison_status(duration: float, total_damage: int, source: Node, channel: int = 0, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying:
		return false
	if not damage_poison_tracker.apply(source,total_damage,duration,channel):
		return false
	if receipt != null:
		receipt.record_application(duration, 1.0, receipt_revision)
		receipt.record_damage_budget(total_damage, receipt_revision)
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


func supports_status_receipt() -> bool:
	# Do not bypass a derived Hero's legacy status overrides.
	return get_script().resource_path == "res://src/hero/hero.gd"

func apply_silence_with_result(duration: float, receipt) -> bool:
	if receipt == null:
		apply_silence(duration)
		return false
	var revision: int = receipt.begin(self, &"silence", duration, 1.0)
	if not supports_status_receipt():
		apply_silence(duration)
		return false
	_apply_silence_status(duration, receipt, revision)
	return receipt.finish(revision)

func apply_silence(duration: float) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"silence", duration, 1.0)
	var accepted: bool = _apply_silence_status(duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_silence_status(duration: float, receipt = null, receipt_revision: int = 0) -> bool:
	if duration <= 0.0 or current_hp <= 0 or is_dying:
		return false
	silence_timer = maxf(silence_timer,duration*(1.0-get_status_resistance("silence")))
	set_meta("silence_active",silence_timer > 0.0)
	if silence_timer <= 0.0:
		return false
	if receipt != null:
		receipt.record_application(silence_timer, 1.0, receipt_revision)
	record_status_effect_event("silence")
	return true

func apply_stun_with_result(duration: float, receipt) -> bool:
	if receipt == null:
		apply_stun(duration)
		return false
	var revision: int = receipt.begin(self, &"stun", duration, 1.0)
	if not supports_status_receipt():
		apply_stun(duration)
		return false
	_apply_stun_status(duration, receipt, revision)
	return receipt.finish(revision)

func apply_stun(duration: float) -> void:
	var revision: int = legacy_status_receipt.begin(self, &"stun", duration, 1.0)
	_apply_stun_status(duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)

func _apply_stun_status(duration: float, receipt = null, receipt_revision: int = 0) -> void:
	if duration <= 0.0 or current_hp <= 0 or is_dying:
		return
	if player_controlled:
		duration = player_control_policy.accept(duration, get_status_resistance("stun"))
		if duration <= 0.0: return
	record_status_effect_event("stun")
	if stun_timer <= 0.0 and is_instance_valid(hero_sprite):
		stun_sprite_speed = hero_sprite.speed_scale
		hero_sprite.speed_scale = 0.0
	stun_timer = maxf(stun_timer, maxf(duration * (1.0 - get_status_resistance("stun")), 0.05))
	velocity = Vector2.ZERO
	set_meta("stun_active", true)
	if receipt != null:
		receipt.record_application(stun_timer, 1.0, receipt_revision)

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


func apply_fear_with_result(source: Node2D, duration: float, receipt, speed_multiplier: float = 1.50) -> bool:
	if receipt == null:
		apply_fear(source, duration, speed_multiplier)
		return false
	var revision: int = receipt.begin(self, &"fear", duration, speed_multiplier)
	if not supports_status_receipt():
		apply_fear(source, duration, speed_multiplier)
		return false
	_apply_fear_status(source, duration, speed_multiplier, receipt, revision)
	return receipt.finish(revision)

func apply_fear(
	source: Node2D,
	duration: float,
	speed_multiplier: float = 1.50
) -> void:
	var revision: int = legacy_status_receipt.begin(self, &"fear", duration, speed_multiplier)
	_apply_fear_status(source, duration, speed_multiplier, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)

func _apply_fear_status(
	source: Node2D,
	duration: float,
	speed_multiplier: float = 1.50,
	receipt = null,
	receipt_revision: int = 0
) -> void:
	if current_hp <= 0 or is_dying or fear_immunity_timer > 0.0:
		return

	if player_controlled:
		duration = player_control_policy.accept(duration, get_status_resistance("fear"))
		if duration <= 0.0: return
	fear_recovery_immunity = maxf(fear_recovery_immunity,float(get_meta("incoming_fear_immunity",0.0)))
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
	if receipt != null:
		receipt.record_application(fear_timer, fear_speed_multiplier, receipt_revision)
	queue_redraw()


func _get_external_skill_cooldown_properties() -> Array:
	# Charm retains and clears this snapshot; never hand it the shared Catalog list.
	return _get_skill_cooldown_bindings().duplicate()

func add_random_skill_cooldown_delay(seconds: float) -> bool:
	var delay := maxf(seconds, 0.0)
	if delay <= 0.0 or current_hp <= 0 or is_dying:
		return false

	var dictionary_rule: Dictionary = HERO_RUNTIME_BINDINGS.DICTIONARY_COOLDOWNS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if not dictionary_rule.is_empty():
		var cooldowns: Dictionary = get(dictionary_rule["timers_property"])
		var skill_config: Dictionary = get(dictionary_rule["config_property"])
		var keys: Array[String] = []
		for key in dictionary_rule["keys"]:
			var config_value = skill_config.get(key, {})
			if (
				typeof(config_value) == TYPE_DICTIONARY
				and not Dictionary(config_value).is_empty()
			):
				keys.append(key)
		if keys.is_empty():
			return false
		var key := keys[randi() % keys.size()]
		cooldowns[key] = (
			maxf(
				float(cooldowns.get(key, 0.0)),
				0.0
			)
			+ delay
		)
		queue_redraw()
		return true

	var properties := _get_skill_cooldown_bindings()
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
	var dictionary_rule: Dictionary = HERO_RUNTIME_BINDINGS.DICTIONARY_COOLDOWNS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if not dictionary_rule.is_empty():
		var cooldowns: Dictionary = get(dictionary_rule["timers_property"])
		for key in dictionary_rule["keys"]:
			cooldowns[key] = maxf(
				float(cooldowns.get(key, 0.0)) - delta,
				0.0
			)
		return

	for property_name in _get_skill_cooldown_bindings():
		var current_value = get(property_name)
		if current_value == null:
			continue
		set(
			property_name,
			maxf(float(current_value) - delta, 0.0)
		)

func _tick_fear_state(delta: float) -> bool:
	fear_immunity_timer = maxf(fear_immunity_timer-delta,0.0)
	var previous_fear := fear_timer
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
		fear_immunity_timer = maxf(fear_recovery_immunity-maxf(delta-previous_fear,0.0),0.0)
		fear_recovery_immunity = 0.0
		fear_source = null
		fear_speed_multiplier = 1.0
		set_meta("fear_active", false)
		queue_redraw()
	return true

func _get_effective_move_multiplier() -> float:
	var multiplier := move_multiplier * float(get_meta("yuki_slow_multiplier",1.0))
	if player_controlled:
		multiplier = maxf(multiplier, PLAYER_CONTROL_POLICY.DATA.SLOW_SPEED_FLOOR)
		if player_root_timer > 0.0: multiplier = minf(multiplier, player_root_multiplier)
	return multiplier

func apply_slow_with_result(multiplier: float, duration: float, receipt) -> bool:
	if receipt == null:
		apply_slow(multiplier, duration)
		return false
	var revision: int = receipt.begin(self, &"slow", duration, 1.0 - multiplier)
	if not supports_status_receipt():
		apply_slow(multiplier, duration)
		return false
	_apply_slow_status(multiplier, duration, receipt, revision)
	return receipt.finish(revision)

func apply_slow(multiplier: float, duration: float) -> void:
	var revision: int = legacy_status_receipt.begin(self, &"slow", duration, 1.0 - multiplier)
	_apply_slow_status(multiplier, duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)

func _apply_slow_status(multiplier: float, duration: float, receipt = null, receipt_revision: int = 0) -> void:
	if current_hp <= 0 or duration <= 0.0:
		return
	var resistance := get_status_resistance("slow")
	var raw_multiplier := clampf(multiplier, 0.01, 1.0)
	var effective_multiplier := lerpf(raw_multiplier, 1.0, resistance)
	if player_controlled and raw_multiplier <= 0.05:
		var accepted := player_control_policy.accept(duration, resistance)
		if accepted <= 0.0: return
		player_root_timer = maxf(accepted*(1.0-resistance),0.05)
		player_root_multiplier = effective_multiplier
		record_status_effect_event("slow")
		if receipt != null:
			receipt.record_application(player_root_timer,1.0-player_root_multiplier,receipt_revision)
		queue_redraw()
		return
	var effective_duration := maxf(duration*(1.0-resistance),0.05)
	if player_controlled:
		effective_multiplier = maxf(effective_multiplier,PLAYER_CONTROL_POLICY.DATA.SLOW_SPEED_FLOOR)
	record_status_effect_event("slow")
	move_multiplier = minf(move_multiplier,effective_multiplier)
	slow_timer = maxf(slow_timer,effective_duration)
	if receipt != null:
		receipt.record_application(slow_timer,1.0-move_multiplier,receipt_revision)
	queue_redraw()

func get_build_summary() -> String:
	if player_controlled and player_weapons != null: return player_weapons.summary()
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
	_berserker_archetype()._physics_process_berserker(delta)


func _try_use_berserker_contextual_skill(
	current_target: Node2D,
	distance: float
) -> bool:
	return _berserker_archetype()._try_use_berserker_contextual_skill(current_target, distance)


func _get_berserker_skill_cooldown(
	skill_config: Dictionary,
	fallback: float
) -> float:
	return _berserker_archetype()._get_berserker_skill_cooldown(skill_config, fallback)


func _pay_berserker_skill_hp_cost(hp_cost_ratio: float) -> void:
	_berserker_archetype()._pay_berserker_skill_hp_cost(hp_cost_ratio)


func _berserker_blood_art_eighth_heal_on_hit() -> void:
	_berserker_archetype()._berserker_blood_art_eighth_heal_on_hit()


func notify_berserker_blood_art_hit() -> void:
	_berserker_archetype().notify_berserker_blood_art_hit()


func _start_berserker_skill1(current_target: Node2D) -> void:
	_berserker_archetype()._start_berserker_skill1(current_target)


func _update_berserker_skill1(delta: float) -> bool:
	return _berserker_archetype()._update_berserker_skill1(delta)


func _berserker_emit_skill1_wave(
	wave_index: int,
	skill_config: Dictionary
) -> void:
	_berserker_archetype()._berserker_emit_skill1_wave(wave_index, skill_config)


func _start_berserker_skill2(current_target: Node2D) -> void:
	_berserker_archetype()._start_berserker_skill2(current_target)


func _run_berserker_skill2_wave(
	start_position: Vector2,
	start_direction: Vector2,
	skill_config: Dictionary
) -> void:
	await _berserker_archetype()._run_berserker_skill2_wave(start_position, start_direction, skill_config)


func _damage_berserker_skill2_segment(
	from_position: Vector2,
	to_position: Vector2,
	half_width: float,
	damage: int,
	hit_ids: Dictionary
) -> void:
	_berserker_archetype()._damage_berserker_skill2_segment(from_position, to_position, half_width, damage, hit_ids)


func _heal_berserker_from_blood_path(
	world_points: Array[Vector2],
	half_width: float,
	heal_per_touch: int,
	healed_ids: Dictionary
) -> void:
	_berserker_archetype()._heal_berserker_from_blood_path(world_points, half_width, heal_per_touch, healed_ids)


func _start_berserker_skill3(current_target: Node2D) -> void:
	_berserker_archetype()._start_berserker_skill3(current_target)


func _execute_berserker_skill3(
	dash_direction: Vector2,
	skill_config: Dictionary
) -> void:
	await _berserker_archetype()._execute_berserker_skill3(dash_direction, skill_config)


func _spawn_berserker_blood_orb(
	start_position: Vector2,
	skill_config: Dictionary
) -> void:
	_berserker_archetype()._spawn_berserker_blood_orb(start_position, skill_config)


func _finish_berserker_blood_orb(
	orb_fx: AnimatedSprite2D,
	heal_amount: int
) -> void:
	_berserker_archetype()._finish_berserker_blood_orb(orb_fx, heal_amount)


func _start_berserker_skill4() -> void:
	_berserker_archetype()._start_berserker_skill4()


func notify_berserker_skill_kill() -> void:
	_berserker_archetype().notify_berserker_skill_kill()


func _update_berserker_pose_visual(delta: float) -> void:
	_berserker_archetype()._update_berserker_pose_visual(delta)


func _get_berserker_effective_attack_damage() -> int:
	return _berserker_archetype()._get_berserker_effective_attack_damage()


func _berserker_basic_attack(current_target: Node2D) -> void:
	_berserker_archetype()._berserker_basic_attack(current_target)


func _add_berserker_gauge(amount: float) -> void:
	_berserker_archetype()._add_berserker_gauge(amount)


func _start_berserker_madness() -> void:
	_berserker_archetype()._start_berserker_madness()


func _end_berserker_madness() -> void:
	_berserker_archetype()._end_berserker_madness()


func _update_berserker_madness(delta: float) -> void:
	_berserker_archetype()._update_berserker_madness(delta)


func _find_berserker_madness_target() -> Node2D:
	return _berserker_archetype()._find_berserker_madness_target()


func _berserker_madness_blink_to(blink_target: Node2D) -> void:
	_berserker_archetype()._berserker_madness_blink_to(blink_target)


func _spawn_berserker_blood_dash_trail(
	start_position: Vector2,
	end_position: Vector2
) -> void:
	_berserker_archetype()._spawn_berserker_blood_dash_trail(start_position, end_position)


func _update_berserker_hp_visual() -> void:
	_berserker_archetype()._update_berserker_hp_visual()


func _begin_berserker_revive() -> void:
	await _berserker_archetype()._begin_berserker_revive()

func _finish_berserker_revive() -> void:
	_berserker_archetype()._finish_berserker_revive()


func _physics_process_fighter(delta: float) -> void:
	_fighter_archetype()._physics_process_fighter(delta)

func _fighter_should_start_charge() -> bool:
	return _fighter_archetype()._fighter_should_start_charge()

func _start_fighter_charge() -> void:
	_fighter_archetype()._start_fighter_charge()

func _find_fighter_charge_target(exclude: Node = null) -> Node2D:
	return _fighter_archetype()._find_fighter_charge_target(exclude)

func _begin_fighter_charge_dash(charge_target: Node2D) -> void:
	_fighter_archetype()._begin_fighter_charge_dash(charge_target)

func _update_fighter_charge(delta: float) -> void:
	_fighter_archetype()._update_fighter_charge(delta)

func _complete_fighter_charge_dash() -> void:
	_fighter_archetype()._complete_fighter_charge_dash()

func _fighter_charge_damage_target(monster: Node2D, damage: int) -> void:
	_fighter_archetype()._fighter_charge_damage_target(monster, damage)

func _finish_fighter_charge() -> void:
	_fighter_archetype()._finish_fighter_charge()

func _spawn_fighter_afterimage(alpha: float) -> void:
	_fighter_archetype()._spawn_fighter_afterimage(alpha)

func _play_fighter_charge_impact_effect() -> void:
	_fighter_archetype()._play_fighter_charge_impact_effect()

func _fighter_move_without_monsters(speed_scale: float) -> void:
	_fighter_archetype()._fighter_move_without_monsters(speed_scale)

func _update_fighter_pose_visual(delta: float) -> void:
	_fighter_archetype()._update_fighter_pose_visual(delta)

func _fighter_basic_attack(current_target: Node2D) -> void:
	_fighter_archetype()._fighter_basic_attack(current_target)


func _update_fighter_slash_combo(delta: float) -> bool:
	return _fighter_archetype()._update_fighter_slash_combo(delta)


func _restart_fighter_attack_animation(reverse_frames: bool) -> void:
	_fighter_archetype()._restart_fighter_attack_animation(reverse_frames)


func _fighter_should_use_slash() -> bool:
	return _fighter_archetype()._fighter_should_use_slash()

func _fighter_apply_slash(direction: Vector2, bonus_hit: bool = false) -> int:
	return _fighter_archetype()._fighter_apply_slash(direction, bonus_hit)


func _fighter_apply_thrust(direction: Vector2) -> void:
	_fighter_archetype()._fighter_apply_thrust(direction)

func _update_fighter_guard(delta: float) -> void:
	_fighter_archetype()._update_fighter_guard(delta)

func _fighter_can_activate_guard() -> bool:
	return _fighter_archetype()._fighter_can_activate_guard()


func _start_fighter_guard() -> void:
	_fighter_archetype()._start_fighter_guard()

func _end_fighter_guard() -> void:
	_fighter_archetype()._end_fighter_guard()

func _fighter_reflect_damage(raw_damage: float, source: Node) -> void:
	_fighter_archetype()._fighter_reflect_damage(raw_damage, source)

func _play_fighter_attack_effect(
	animation_name: String,
	direction: Vector2,
	reverse_frames: bool = false
) -> void:
	_fighter_archetype()._play_fighter_attack_effect(animation_name, direction, reverse_frames)


func _play_fighter_guard_release_effect() -> void:
	_fighter_archetype()._play_fighter_guard_release_effect()

func _apply_stage3_fighter_effect_visuals() -> void:
	_fighter_archetype()._apply_stage3_fighter_effect_visuals()

func _apply_stage4_gunner_effect_visuals() -> void:
	_gunner_archetype()._apply_stage4_gunner_effect_visuals()

func _set_gunner_muzzle_transform(direction: Vector2) -> void:
	_gunner_archetype()._set_gunner_muzzle_transform(direction)


func _play_gunner_deadeye_flame(direction: Vector2) -> void:
	_gunner_archetype()._play_gunner_deadeye_flame(direction)


func _play_gunner_deadeye_smoke(direction: Vector2) -> void:
	_gunner_archetype()._play_gunner_deadeye_smoke(direction)


func _play_gunner_cylinder_dust() -> void:
	_gunner_archetype()._play_gunner_cylinder_dust()


func _required_exp_for_level(target_level: int) -> int:
	if player_controlled: return preload("res://src/data/hero_mode_catalog.gd").required_exp(target_level,player_exp_requirement_scale)
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
	if not player_controlled and not damage_already_mitigated and hero_archetype == "grand_sage_astra":
		raw_damage = _apply_sage_mana_conversion(raw_damage)
	if player_controlled and player_weapons != null and not damage_already_mitigated:
		raw_damage *= player_weapons.damage_multiplier
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
		if player_weapons != null and player_weapons.has_method("on_shield_absorbed"): player_weapons.on_shield_absorbed(absorbed)
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
		# Evading ongoing poison/burn ticks repeatedly closes the intended counter window.
		if grant_invulnerability and hero_archetype == "pistol_gunner" and _gunner_should_backstep_on_hit():
			_start_gunner_backstep()
		if grant_invulnerability:
			_refresh_invulnerability_visual()

	return true

func _prepare_contextual_damage_audio() -> void:
	if not CONTEXT_AUDIO.HITS.has(hero_archetype):
		return
	call(String(CONTEXT_AUDIO.HITS[hero_archetype].ensure))
	var rule: Dictionary = CONTEXT_AUDIO.BLOCK_PREPARATION.get(hero_archetype, CONTEXT_AUDIO.EMPTY_PROFILE)
	if not rule.is_empty() and not is_instance_valid(get(rule["player"])):
		set(rule["player"], _create_hero_sfx_player(CONTEXT_AUDIO.ROOT + String(rule["file"]), float(rule["db"])))

func _play_contextual_damage_audio(physical_block: bool, magical_block: bool) -> void:
	if COMBAT_DELAY.now_msec(self) < contextual_hit_next_ms or not CONTEXT_AUDIO.HITS.has(hero_archetype):
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
		contextual_hit_next_ms = COMBAT_DELAY.now_msec(self)+CONTEXT_AUDIO.HIT_INTERVAL_MS
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
	death_started.emit()
	_clear_bleed()
	_clear_burn()
	_clear_stun()
	_clear_medusa_statuses()
	_clear_charm()
	_clear_received_modifiers()
	set_meta("dullahan_soul_stacks", 0)
	possession_immunity_timer = 0.0
	fear_timer = 0.0
	fear_immunity_timer = 0.0
	fear_recovery_immunity = 0.0
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
	_play_bound_hero_audio(&"death")
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
	if player_controlled and player_weapons != null: player_weapons.draw()
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
	var bar_width := HERO_PRESENTATION.STATUS_BAR_WIDTH
	var layout := HERO_PRESENTATION.get_status_layout(hero_archetype)
	var bar_x_offset := layout.x
	var resource_bar_y := layout.y
	var hp_bar_y := layout.z
	var shield_bar_y := layout.w
	if player_controlled and player_weapons != null and player_weapons.identity != null:
		resource_bar_y = player_weapons.identity.status_resource_y
		hp_bar_y = player_weapons.identity.status_hp_y
		shield_bar_y = player_weapons.identity.status_shield_y
	var bar_left_x := -bar_width / 2.0 + bar_x_offset
	if player_controlled:
		player_control_gauge.draw_on(status_overlay, self, minf(resource_bar_y, minf(hp_bar_y, shield_bar_y)) - HERO_PRESENTATION.STATUS_CONTROL_GAUGE_OFFSET, bar_width)
	_draw_status_resource_bar(HERO_PRESENTATION.get_status_resource(hero_archetype), resource_bar_y, bar_width, bar_left_x)

	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	status_overlay.draw_rect(
		Rect2(bar_left_x, hp_bar_y, bar_width, HERO_PRESENTATION.STATUS_HP_HEIGHT),
		HERO_PRESENTATION.STATUS_BACKGROUND_COLOR,
		true
	)
	status_overlay.draw_rect(
		Rect2(
			bar_left_x,
			hp_bar_y,
			bar_width * hp_ratio,
			HERO_PRESENTATION.STATUS_HP_HEIGHT
		),
		HERO_PRESENTATION.STATUS_HP_COLOR,
		true
	)

	if shield_max_hp > 0.0 and shield_hp > 0.0:
		var shield_ratio := clampf(
			shield_hp / maxf(shield_max_hp, 1.0),
			0.0,
			1.0
		)
		status_overlay.draw_rect(
			Rect2(bar_left_x, shield_bar_y, bar_width, HERO_PRESENTATION.STATUS_SHIELD_HEIGHT),
			HERO_PRESENTATION.STATUS_SHIELD_BACKGROUND_COLOR,
			true
		)
		status_overlay.draw_rect(
			Rect2(
				bar_left_x,
				shield_bar_y,
				bar_width * shield_ratio,
				HERO_PRESENTATION.STATUS_SHIELD_HEIGHT
			),
			HERO_PRESENTATION.STATUS_SHIELD_COLOR,
			true
		)

# Stronger paralysis replaces weaker; weaker applications cannot prolong it.

func apply_paralysis_with_result(ratio: float, duration: float, receipt) -> bool:
	if receipt == null:
		apply_paralysis(ratio, duration)
		return false
	var revision: int = receipt.begin(self, &"paralysis", duration, ratio)
	if not supports_status_receipt():
		apply_paralysis(ratio, duration)
		return false
	_apply_paralysis_status(ratio, duration, receipt, revision)
	return receipt.finish(revision)

func apply_paralysis(ratio: float, duration: float) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"paralysis", duration, ratio)
	var accepted: bool = _apply_paralysis_status(ratio, duration, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_paralysis_status(ratio: float, duration: float, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or duration <= 0.0 or ratio <= 0.0:
		return false
	var strength := clampf(ratio,0.0,1.0)
	if paralysis_timer > 0.0 and strength < paralysis_ratio:
		return false
	paralysis_ratio = strength
	paralysis_timer = duration
	if receipt != null:
		receipt.record_application(paralysis_timer, paralysis_ratio, receipt_revision)
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
	var dictionary_rule: Dictionary = HERO_RUNTIME_BINDINGS.DICTIONARY_COOLDOWNS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if not dictionary_rule.is_empty():
		var cooldowns: Dictionary = get(dictionary_rule["timers_property"])
		for key in dictionary_rule["keys"]:
			cooldowns[key] = maxf(float(cooldowns.get(key,0.0)),seconds)
	else:
		for property_name in _get_skill_cooldown_bindings():
			set(property_name,maxf(float(get(property_name)),seconds))
	queue_redraw()

func apply_burn_with_result(duration: float, total_damage: int, receipt, source: Node = null) -> bool:
	if receipt == null:
		apply_burn(duration, total_damage, source)
		return false
	var revision: int = receipt.begin(self, &"burn", duration, 1.0, total_damage)
	if not supports_status_receipt():
		apply_burn(duration, total_damage, source)
		return false
	_apply_burn_status(duration, total_damage, source, receipt, revision)
	return receipt.finish(revision)

func apply_burn(duration: float, total_damage: int, source: Node = null) -> bool:
	var revision: int = legacy_status_receipt.begin(self, &"burn", duration, 1.0, total_damage)
	var accepted: bool = _apply_burn_status(duration, total_damage, source, legacy_status_receipt, revision)
	legacy_status_result_complete = legacy_status_receipt.finish(revision)
	return accepted

func _apply_burn_status(duration: float, total_damage: int, source: Node = null, receipt = null, receipt_revision: int = 0) -> bool:
	if current_hp <= 0 or is_dying or not burn_runtime.apply(duration,total_damage,source):
		return false
	set_meta("burn_active",true)
	if receipt != null:
		receipt.record_application(burn_runtime.remaining, 1.0, receipt_revision)
		receipt.record_damage_budget(burn_runtime.total, receipt_revision)
	record_status_effect_event("burn")
	COMBAT_STATUS_EFFECT_VISUAL.show_on(self,"burn")
	return true

func _clear_burn() -> void:
	burn_runtime.clear()
	set_meta("burn_active",false)

func _player_shield_amount(amount: float) -> float:
	return player_weapons.shield_amount(amount) if player_controlled and player_weapons != null else amount


func _configure_combat_effect_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	var before_build: Dictionary = profile["before_build"]
	for target_property in before_build:
		var target: AnimatedSprite2D = get(target_property)
		var properties: Dictionary = before_build[target_property]
		for property in properties:
			target.set(property, properties[property])
	# Temporary frame slots exist only during setup, never during frame updates.
	for batch in profile["batches"]:
		var built_frames: Array[SpriteFrames] = []
		for build in batch["builds"]:
			built_frames.append(_build_bound_effect_frames(build))
		for binding in batch["bindings"]:
			var frames := built_frames[int(binding["slot"])]
			if frames == null:
				continue
			if bool(binding["require_nonempty"]):
				var has_frames := false
				for animation in frames.get_animation_names():
					if frames.get_frame_count(animation) > 0:
						has_frames = true
						break
				if not has_frames:
					continue
			var target: AnimatedSprite2D = get(binding["target"])
			var before_assign: Dictionary = binding["before_assign"]
			for property in before_assign:
				target.set(property, before_assign[property])
			target.sprite_frames = frames
			var properties: Dictionary = binding["properties"]
			for property in properties:
				target.set(property, properties[property])


func _build_bound_effect_frames(profile: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	for rule in profile["animations"]:
		var animation: StringName = rule["name"]
		frames.add_animation(animation)
		if bool(rule["loop_first"]):
			frames.set_animation_loop(animation, bool(rule["loop"]))
		frames.set_animation_speed(animation, float(rule["fps"]))
		if not bool(rule["loop_first"]):
			frames.set_animation_loop(animation, bool(rule["loop"]))
		for index in range(int(rule["first"]), int(rule["last"]) + 1):
			var path := String(rule["path_pattern"]) % index
			var texture := _load_stage1_texture(path)
			if texture == null:
				push_warning(String(rule["warning"]) % path)
				if rule["missing"] == &"abort_effect":
					return null
				if rule["missing"] == &"stop_animation":
					break
				continue
			frames.add_frame(animation, texture)
	return frames


func _configure_scaled_effect_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	var target: AnimatedSprite2D = get(profile["target"])
	var reset_before_filter := bool(profile["reset_before_filter"])
	if reset_before_filter:
		_reset_scaled_effect_visual(target, profile["reset_properties"])
	# Some effects reset unconditionally; others must preserve another hero's effect.
	var hero_ids: Dictionary = profile["hero_ids"]
	if not hero_ids.has(hero_id):
		return
	if not reset_before_filter:
		_reset_scaled_effect_visual(target, profile["reset_properties"])
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var animation: StringName = profile["animation"]
	frames.add_animation(animation)
	frames.set_animation_speed(animation, float(profile["fps"]))
	frames.set_animation_loop(animation, bool(profile["loop"]))
	var measure_extent := bool(profile["measure_source_extent"])
	var source_extent := float(profile["source_extent"])
	for index in range(int(profile["first"]), int(profile["last"]) + 1):
		var path := String(profile["path_pattern"]) % index
		var texture := _load_stage1_texture(path)
		if texture == null:
			push_warning(String(profile["missing_warning"]) % path)
			target.sprite_frames = null
			return
		if measure_extent:
			var texture_size := texture.get_size()
			source_extent = maxf(source_extent, maxf(texture_size.x, texture_size.y))
		frames.add_frame(animation, texture)
	if measure_extent and source_extent <= 0.0:
		push_warning(String(profile["invalid_extent_warning"]))
		target.sprite_frames = null
		return
	target.sprite_frames = frames
	var uniform_scale := float(profile["target_extent"]) / source_extent
	target.scale = Vector2(uniform_scale, uniform_scale)


func _reset_scaled_effect_visual(target: AnimatedSprite2D, properties: Dictionary) -> void:
	for property in properties:
		target.set(property, properties[property])


func _draw_status_resource_bar(rule: Dictionary, bar_y: float, bar_width: float, bar_left_x: float) -> void:
	var height := HERO_PRESENTATION.STATUS_RESOURCE_HEIGHT
	if rule["kind"] == &"cells":
		var capacity: int
		if rule.has("capacity_method"):
			capacity = int(call(rule["capacity_method"]))
		else:
			capacity = int(get(rule["capacity_property"]))
		var displayed_cells := _get_status_displayed_cells(rule, capacity)
		var gap := HERO_PRESENTATION.STATUS_CELL_GAP
		var cell_width := (bar_width - gap * float(capacity - 1)) / float(capacity)
		for index in range(capacity):
			var x := -bar_width / 2.0 + float(index) * (cell_width + gap)
			status_overlay.draw_rect(Rect2(x, bar_y, cell_width, height), HERO_PRESENTATION.STATUS_BACKGROUND_COLOR, true)
			if index < displayed_cells:
				status_overlay.draw_rect(Rect2(x, bar_y, cell_width, height), rule["color"], true)
		return
	var maximum: float
	if rule.has("max_property"):
		maximum = maxf(float(get(rule["max_property"])), float(rule["minimum_max"]))
	else:
		var config: Dictionary = get(rule["config_property"])
		maximum = maxf(float(config.get(rule["max_key"], rule["default_max"])), float(rule["minimum_max"]))
	var ratio := clampf(float(get(rule["value_property"])) / maximum, 0.0, 1.0)
	var x := bar_left_x if bool(rule["use_x_offset"]) else -bar_width / 2.0
	status_overlay.draw_rect(Rect2(x, bar_y, bar_width, height), HERO_PRESENTATION.STATUS_BACKGROUND_COLOR, true)
	status_overlay.draw_rect(Rect2(x, bar_y, bar_width * ratio, height), rule["color"], true)


func _get_status_displayed_cells(rule: Dictionary, capacity: int) -> int:
	if rule.has("reload_property") and bool(get(rule["reload_property"])):
		var config: Dictionary = get(rule["config_property"])
		var duration := maxf(float(config.get(rule["duration_key"], rule["default_duration"])), float(rule["minimum_duration"]))
		var progress := clampf(1.0 - float(get(rule["timer_property"])) / duration, 0.0, 1.0)
		return clampi(int(floor(progress * float(capacity))), 0, capacity)
	if rule.has("count_method"):
		return int(call(rule["count_method"]))
	return int(get(rule["count_property"]))


func _get_skill_cooldown_bindings() -> Array:
	var profile: Dictionary = HERO_RUNTIME_BINDINGS.PROPERTY_COOLDOWNS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	if profile.is_empty():
		return HERO_RUNTIME_BINDINGS.EMPTY_PROPERTIES
	if profile.has("conditional_skill"):
		if is_conditional_skill_unlocked(profile["conditional_skill"]):
			return profile["expanded_properties"]
	elif profile.has("unlock_property") and bool(get(profile["unlock_property"])):
		return profile["expanded_properties"]
	return profile["properties"]


func _play_bound_hero_audio(event: StringName) -> bool:
	var rule := HERO_PRESENTATION.get_event_audio(hero_archetype, event)
	if rule.is_empty():
		return false
	callv(rule["method"], rule["arguments"])
	return true


func _refresh_hero_action_bindings() -> void:
	if _hero_action_binding_valid and _hero_action_binding_key == hero_archetype:
		return
	var profile: Dictionary = HERO_RUNTIME_BINDINGS.ACTION_BINDINGS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROFILE)
	_hero_pose_tick = Callable(self, profile.get("pose", HERO_RUNTIME_BINDINGS.DEFAULT_POSE_TICK))
	_hero_action_tick = Callable(self, profile["physics"]) if profile.has("physics") else Callable()
	_hero_common_runtime_tick = Callable(self, profile["common_runtime"]) if profile.has("common_runtime") else Callable()
	_hero_boundary_steering = Callable(self, HERO_RUNTIME_BINDINGS.BOUNDARY_STEERING.get(hero_archetype, HERO_RUNTIME_BINDINGS.DEFAULT_BOUNDARY_STEERING))
	_hero_action_binding_key = hero_archetype
	_hero_action_binding_valid = true


func _play_ordered_hero_audio(event: StringName) -> void:
	# Re-read archetype for each step, preserving two independent legacy checks.
	for step in HERO_PRESENTATION.ORDERED_EVENT_AUDIO.get(event, HERO_PRESENTATION.EMPTY_METHODS):
		_play_bound_hero_audio(step)


func _dispatch_augment_stack_hook(augment_id: String) -> void:
	for rule in HERO_RUNTIME_BINDINGS.AUGMENT_STACK_HOOKS.get(hero_archetype, HERO_RUNTIME_BINDINGS.EMPTY_PROPERTIES):
		if rule.has("id") and augment_id != rule["id"]:
			continue
		if rule.has("prefix") and not augment_id.begins_with(rule["prefix"]):
			continue
		if bool(rule["pass_id"]):
			call(rule["method"], augment_id)
		else:
			call(rule["method"])
		break


func _gunner_archetype():
	if _gunner_archetype_runtime == null:
		_gunner_archetype_runtime = HERO_GUNNER_ARCHETYPE.new(self)
	return _gunner_archetype_runtime


func _rogue_archetype():
	if _rogue_archetype_runtime == null:
		_rogue_archetype_runtime = HERO_ROGUE_ARCHETYPE.new(self)
	return _rogue_archetype_runtime


func _fighter_archetype():
	if _fighter_archetype_runtime == null:
		_fighter_archetype_runtime = HERO_FIGHTER_ARCHETYPE.new(self)
	return _fighter_archetype_runtime


func _berserker_archetype():
	if _berserker_archetype_runtime == null:
		_berserker_archetype_runtime = HERO_BERSERKER_ARCHETYPE.new(self)
	return _berserker_archetype_runtime


func _summoner_archetype():
	if _summoner_archetype_runtime == null:
		_summoner_archetype_runtime = HERO_SUMMONER_ARCHETYPE.new(self)
	return _summoner_archetype_runtime


func _alchemist_archetype():
	if _alchemist_archetype_runtime == null:
		_alchemist_archetype_runtime = HERO_ALCHEMIST_ARCHETYPE.new(self)
	return _alchemist_archetype_runtime


func _purifier_archetype():
	if _purifier_archetype_runtime == null:
		_purifier_archetype_runtime = HERO_PURIFIER_ARCHETYPE.new(self)
	return _purifier_archetype_runtime


func _archmage_archetype():
	if _archmage_archetype_runtime == null:
		_archmage_archetype_runtime = HERO_ARCHMAGE_ARCHETYPE.new(self)
	return _archmage_archetype_runtime


func _sage_archetype():
	if _sage_archetype_runtime == null:
		_sage_archetype_runtime = HERO_SAGE_ARCHETYPE.new(self)
	return _sage_archetype_runtime
