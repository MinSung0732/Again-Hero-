extends Node2D

const PERFORMANCE_PROBE := preload("res://src/systems/combat_performance_probe.gd")
const CANDIDATE_CACHE := preload("res://src/systems/spatial_candidate_cache.gd")
var combat_profile = PERFORMANCE_PROBE.new()
# Set before _ready by non-rendered authoritative rooms; gameplay is unchanged.
var combat_popup_visuals_enabled := true
var monster_candidate_cache = CANDIDATE_CACHE.new()
@export var combat_profiling_enabled := false:
	set(value):
		combat_profiling_enabled = value
		if value: combat_profile.start()
		else: combat_profile.stop()

const PICKUP_PLACEMENT := preload("res://src/systems/pickup_placement.gd")
const BATTLE_SESSION := preload("res://src/data/battle_session_catalog.gd")
const CONTROL_SPAWNS := preload("res://src/hero_mode/hero_control_spawn_budget.gd")
var hero_control_spawns = CONTROL_SPAWNS.new()
var hero_control_roster: Array = []
const HERO_SURVIVAL := preload("res://src/data/hero_mode_catalog.gd")
const BATTLE_COMMAND := preload("res://src/systems/battle_command.gd")
const BATTLE_COMMAND_ROUTER := preload("res://src/systems/battle_command_router.gd")
const BATTLE_ENTITY_REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
# Offline compatibility switch for this migration. Future network modes must
# never bypass their authority checks through this switch.
@export var command_routing_enabled := true
var battle_command_router = BATTLE_COMMAND_ROUTER.new()
var battle_entity_registry = BATTLE_ENTITY_REGISTRY.new()
var demon_augment_revision := 0
var mutation_choice_revision := 0

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")
const SPATIAL_BUCKET_POOL := preload("res://src/systems/spatial_bucket_pool.gd")

const MONSTER_LOCAL_GRID := preload("res://src/systems/monster_local_grid.gd")

signal clock_scale_changed(scale: float)
signal stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal hero_leveled_up(new_level: int)
signal hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal conditional_skill_unlocked(skill_id: String, skill_name: String, payload: Dictionary)
signal command_changed(current_value: float, max_value: float)
signal summon_result(monster_type: String, success: bool, message: String)
signal online_combat_feedback(target: Node2D,amount: int,color: Color,healing: bool,critical: bool)
signal online_cast_feedback(cue: String,point: Vector2)
signal online_transcendent_sfx(catalog_key: String, cue_id: String)
signal online_monster_sfx(cue: String)
const MONSTER_SFX := preload("res://src/data/monster_sfx_catalog.gd")
signal online_visual_entity_exited(instance_id: int)
var online_visual_projectiles := {}
signal transcendent_summoned(monster_id: String, actor: Node2D)
signal transcendent_died(monster_id: String, actor: Node2D)
signal transcendence_changed(monster_id: String, ready: bool, used: bool)
const TRANSCENDENCE_DATA := preload("res://src/data/transcendence_catalog.gd")
const TRANSCENDENCE_STORE := preload("res://src/systems/transcendence_loadout_store.gd")
var transcendent_actor: Node2D
var raw_allied_summons := 0
var raw_real_tank_summons := 0
var raw_statuses_applied := 0
var raw_allied_deaths := 0
var raw_tank_deaths := 0
var practice_mode := false
@onready var _mission_service: Node = get_node_or_null("/root/MissionProgress")
const PRACTICE_HERO := preload("res://src/hero/practice_hero.gd")
var transcendence = preload("res://src/systems/transcendence_runtime.gd").new()
signal demon_progression_changed(level: int, current_exp: float, exp_to_next_level: float)
signal demon_augment_ready(candidates: Array, rerolls_left: int, demon_level: int)
signal demon_augment_applied(augment_name: String, build_summary: String)
signal demon_ultimate_changed(current_value: float, max_value: float, ready: bool)
signal demon_ultimate_cooldowns_changed(cooldowns: Dictionary)
signal demon_ultimate_used(skill_id: String, skill_name: String, message: String)
signal stage_event_triggered(event_type: String, event_name: String, message: String)
signal mutation_choice_ready(event_data: Dictionary, candidates: Array)
signal online_elite_requested(event_data: Dictionary)
signal online_hero_kill
signal mutation_selected(event_type: String, mutation_name: String)
signal mutation_spawn_result(success: bool, message: String)
signal run_time_changed(elapsed_seconds: float, remaining_seconds: float)
signal battle_finished(message: String, player_won: bool)
# Presentation only: hero perspective, independent of the player role.
signal hero_outcome_confirmed(outcome: StringName)

const HERO_SCENE := preload("res://src/hero/Hero.tscn")
const SCORPION_SWAMP_RUNTIME := preload("res://src/systems/scorpion_swamp_runtime.gd")
const SUPPORT_BUFF_RUNTIME := preload("res://src/systems/monster_support_buff_runtime.gd")
const LIZARD_TAIL_RUNTIME := preload("res://src/systems/lizard_tail_runtime.gd")
const ANUBIS_ARMY_RUNTIME := preload("res://src/systems/anubis_army_runtime.gd")
const GOBLIN_FORMATION_RUNTIME := preload("res://src/systems/goblin_formation_runtime.gd")
const WOLF_PACK_RUNTIME := preload("res://src/systems/wolf_pack_runtime.gd")
const YUKI_RUNTIME := preload("res://src/systems/yuki_onna_runtime.gd")
const MONSTER_SUPPORT_COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const EXP_ORB_SCENE := preload("res://src/battle/ExpOrb.tscn")
const HEAL_ITEM_SCENE := preload("res://src/battle/HealItem.tscn")
const TREASURE_CHEST_SCENE := preload("res://src/battle/TreasureChest.tscn")
const MAGNET_ITEM_SCENE := preload("res://src/battle/MagnetItem.tscn")
const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const HERO_AI_PROFILES := preload("res://src/data/hero_ai_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const DEMON_ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const DEMON_SKILL_LOADOUT_STORE := preload(
	"res://src/systems/demon_skill_loadout_store.gd"
)
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const MONSTER_COLLECTION_STORE := preload(
	"res://src/systems/monster_collection_store.gd"
)
const RUN_METRICS := preload("res://src/systems/run_metrics.gd")
const STAGE_DIRECTOR := preload("res://src/systems/stage_director.gd")
const MUTATION_DIRECTOR := preload("res://src/systems/mutation_director.gd")
const MUTATION_CATALOG := preload("res://src/data/mutation_catalog.gd")
const FLOW_PAUSE_MANAGER := preload("res://src/systems/flow_pause_manager.gd")
const GROUND_SHADOW_SCRIPT := preload("res://src/battle/ground_shadow.gd")
const ELITE_MONSTER_SKILL_RUNTIME := preload(
	"res://src/systems/elite_monster_skill_runtime.gd"
)

const DEFAULT_MAP_SIZE := Vector2(3200, 3200)
const AUTO_SPAWN_MIN_DISTANCE := 560.0
const AUTO_SPAWN_MAX_DISTANCE := 720.0

const BASE_MAX_COMMAND := 100.0
const START_COMMAND := 0.0
const BASE_COMMAND_REGEN_PER_SECOND := 3.0
const MANUAL_SPAWN_MARGIN := 70.0
const CASTLE_TOP_SPAWN_MARGIN := 230.0
const MANUAL_SPAWN_HERO_MIN_DISTANCE := 220.0
const MANUAL_SPAWN_WARNING_DURATION := 0.70
const DEMON_BASE_EXP_TO_NEXT := 15.0
const DEMON_EXP_GROWTH_PER_LEVEL := 4.0
const BASE_DEMON_REROLLS := DEMON_AUGMENTS.BASE_REROLLS
const DEMON_LEVEL_MONSTER_HP_GROWTH := 1.03
const DEMON_LEVEL_MONSTER_HP_MAX_MULTIPLIER := 2.50
const DEMON_LEVEL_MONSTER_DAMAGE_GROWTH := 1.028
const DEMON_LEVEL_MONSTER_DAMAGE_MAX_MULTIPLIER := 2.35
const DEMON_LEVEL_MONSTER_EXP_GROWTH := 1.02
const DEMON_LEVEL_MONSTER_EXP_MAX_MULTIPLIER := 2.0
const DEMON_LEVEL_MONSTER_SPEED_GROWTH := 1.02
const DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER := 1.25
const GIANT_MONSTER_UNLOCK_LEVEL := 10
const GIANT_MONSTER_BASE_CHANCE := 0.10
const GIANT_MONSTER_LEVEL_STEP := 5
const GIANT_MONSTER_CHANCE_PER_STEP := 0.01
const GIANT_MONSTER_STAT_MULTIPLIER := 1.28
const GIANT_MONSTER_HP_MULTIPLIER := 1.54
const GIANT_MONSTER_SIZE_MULTIPLIER := 2.0
const HEAL_ITEM_KILLS_REQUIRED := 30
const MAX_ACTIVE_HEAL_ITEMS := 2
const CHEST_KILLS_REQUIRED := 50
const MAX_ACTIVE_CHESTS := 2
const MAGNET_KILLS_REQUIRED := 70
const MAX_ACTIVE_MAGNET_ITEMS := 2
const EXP_MAGNET_DURATION := 2.0
const CHEST_EXP_BUNDLE_MIN := 15
const CHEST_EXP_BUNDLE_MAX := 20
const CHEST_EXP_VALUE_MIN := 10
const CHEST_EXP_VALUE_MAX := 30
const MAX_EXP_ORB_POOL := 128
const MAX_PROJECTILE_POOL_PER_TYPE := 96
const MAX_TRANSIENT_FX_POOL_PER_TYPE := 48
const STAGE_REINFORCEMENT_MAX_SPAWNS_PER_FRAME := 2


var hero: Node2D
var current_stage_id: String = "stage_1"
var current_stage_data: Dictionary = {}
var current_hero_profile: Dictionary = {}
var current_map_size: Vector2 = DEFAULT_MAP_SIZE
var run_time_limit_seconds: float = 0.0
var hero_final_boss_spawned := false
var _hero_boss_spawn_pending := false
var run_time_emit_timer: float = 0.0
var manual_spawn_warning_timer: float = 0.0
var run_metrics = RUN_METRICS.new()
var _run_reward_granted := false
var _run_reward_save_failed := false
var stage_director = STAGE_DIRECTOR.new()
var mutation_director = MUTATION_DIRECTOR.new()
var flow_pause_manager = FLOW_PAUSE_MANAGER.new()
var elite_monster_skill_runtime = ELITE_MONSTER_SKILL_RUNTIME.new()

const PAUSE_REASON_EXTERNAL := "external_pause"
const PAUSE_REASON_DEMON_AUGMENT := "demon_augment"
const PAUSE_REASON_MUTATION_CHOICE := "mutation_choice"
const FULL_MODAL_PAUSE_DOMAINS := [
	FLOW_PAUSE_MANAGER.DOMAIN_COMBAT,
	FLOW_PAUSE_MANAGER.DOMAIN_RUN_TIMER,
	FLOW_PAUSE_MANAGER.DOMAIN_COMMAND_REGEN,
	FLOW_PAUSE_MANAGER.DOMAIN_STAGE_EVENTS,
	FLOW_PAUSE_MANAGER.DOMAIN_DEMON_RUNTIME,
]

var tutorial_mode := false
var monsters_alive: int = 0
const MONSTER_SPATIAL_CELL_SIZE := 256.0

var active_monsters: Dictionary = {}
var support_buff_runtime = SUPPORT_BUFF_RUNTIME.new()
var lizard_tail_runtime = LIZARD_TAIL_RUNTIME.new()
var gumiho_shared_runtime = preload("res://src/systems/gumiho_shared_runtime.gd").new()
var anubis_army_runtime = ANUBIS_ARMY_RUNTIME.new()
var goblin_formation_runtime = GOBLIN_FORMATION_RUNTIME.new()
var wolf_pack_runtime = WOLF_PACK_RUNTIME.new()
var yuki_runtime = YUKI_RUNTIME.new()
var scorpion_swamp_runtime = SCORPION_SWAMP_RUNTIME.new()
var monster_population_counts: Dictionary = {}
var monster_population_ids: Dictionary = {}
# Living units created by player summons; skill/augment children never reserve slots.
var direct_population_ids: Dictionary = {}
signal population_changed(count: int, capacity: int)
var _population_update_pending := false
var active_hero_summons: Dictionary = {}
var active_elite_skeletons: Dictionary = {}
var monster_spatial_grid: Dictionary = {}
var monster_spatial_used_cells: Array[Vector2i] = []
var monster_spatial_previous_cells: Array[Vector2i] = []
var monster_spatial_spare_buckets: Array = []
var monster_spatial_stale_ids: Array[int] = []
var monster_spatial_grid_physics_frame: int = -1
var monster_spatial_snapshot_revision := 0
var monster_query_registration_order := 0
var monster_local_grid = MONSTER_LOCAL_GRID.new()
var fusion_scratch: Array = []
var fusion_candidates: Array = []
var ghost_shared_hit_count: int = 0
var ghost_death_buff_candidates: Array = []
var exp_orb_pool: Array[Node2D] = []
var projectile_pools: Dictionary = {}
var transient_fx_pools: Dictionary = {}
var active_heal_items: Dictionary = {}
var active_treasure_chests: Dictionary = {}
var active_magnet_items: Dictionary = {}
var exp_magnet_until_msec: int = 0
var battle_over: bool = false
signal hero_chest_opened
var campaign_difficulty := "easy"
var hero_player_mode := false
var online_match_mode := false
var online_match_rules: Dictionary = {}
var hero_player_stage := "stage_1"
var hero_player_hero_id := "ranged_rookie"
var external_pause: bool = false
var clock_scale := 1.0

var max_command: float = BASE_MAX_COMMAND
var command_power: float = START_COMMAND
var command_regen_per_second: float = BASE_COMMAND_REGEN_PER_SECOND
var command_emit_timer: float = 0.0

var demon_level: int = 1
var demon_exp: float = 0.0
var demon_exp_to_next_level: float = DEMON_BASE_EXP_TO_NEXT
var demon_pending_augments: int = 0
var demon_pending_augment_levels: Array[int] = []
var demon_active_augment_level: int = 0
var demon_ultimate_charge: float = 0.0
var demon_ultimate_emit_timer: float = 0.0
var demon_ultimate_spawn_queue: Array[Dictionary] = []
var demon_ultimate_spawn_timer: float = 0.0
var demon_ultimate_spawn_interval: float = 0.04
var demon_ultimate_spawn_batch_size: int = 2
var demon_ultimate_cooldowns: Dictionary = {}
var demon_ultimate_cooldown_emit_timer: float = 0.0
var demon_ultimate_skill_ids: Array[String] = []
var demon_ultimate_cheapest_cost: float = DEMON_ULTIMATES.CHARGE_MAX

var stage_reinforcement_queue: Array[Dictionary] = []
var stage_reinforcement_queue_index: int = 0
var stage_reinforcement_timer: float = 0.0
var stage_reinforcement_interval: float = 0.12
var stage_reinforcement_batch_size: int = 2
var hero_kills_toward_heal_item: int = 0
var hero_kills_toward_chest: int = 0
var hero_chests_spawned := 0
var hero_elite_kills_toward_chest := 0
var hero_kills_toward_magnet: int = 0

var summon_cost_multiplier: float = 1.0
var demon_exp_gain_multiplier: float = 1.0
var banshee_deaths_toward_elite: int = 0
var monster_speed_multiplier: float = 1.0
var monster_damage_multiplier: float = 1.0
var monster_hp_multiplier: float = 1.0
var monster_attack_speed_multiplier: float = 1.0
var death_refund_ratio: float = 0.0
var slime_split_chance: float = 0.0
var spider_slow_duration_multiplier: float = 1.0
var orc_hp_multiplier: float = 1.0

var demon_reroll_max: int = BASE_DEMON_REROLLS
var demon_rerolls_left: int = BASE_DEMON_REROLLS
var demon_augment_selection_active: bool = false
var demon_augment_candidates: Array = []
var demon_build_counts: Dictionary = {}
var demon_last_candidate_ids: Array[String] = []
var demon_special_augments: Array[String] = []
var monster_augment_modifiers: Dictionary = {}
var special_augment_cache_ids: Array[String] = []
var special_augment_config_cache: Dictionary = {}

var monster_summon_costs: Dictionary = {}
var special_summon_counts: Dictionary = {}
var permanent_research_levels: Dictionary = {}
var monster_collection_upgrade_levels: Dictionary = {}

var allowed_monster_ids: Array = []
var loadout_restriction_enabled: bool = false

# First instances build monster SpriteFrames/status-effect caches synchronously.
# Warm them once, spread across frames, before the first real mass summon.
var _monster_spawn_resources_warmed: bool = false
var _monster_spawn_warmup_running: bool = false

func _register_heal_item(item: Node) -> void:
	if not is_instance_valid(item):
		return
	var iid := item.get_instance_id()
	active_heal_items[iid] = item
	item.tree_exited.connect(
		Callable(self, "_on_heal_item_tree_exited").bind(iid),
		Object.CONNECT_ONE_SHOT
	)


func _on_heal_item_tree_exited(instance_id: int) -> void:
	active_heal_items.erase(instance_id)


func _register_treasure_chest(chest: Node) -> void:
	if not is_instance_valid(chest):
		return
	var iid := chest.get_instance_id()
	active_treasure_chests[iid] = chest
	chest.tree_exited.connect(
		Callable(self, "_on_treasure_chest_tree_exited").bind(iid),
		Object.CONNECT_ONE_SHOT
	)


func _on_treasure_chest_tree_exited(instance_id: int) -> void:
	active_treasure_chests.erase(instance_id)

func fill_active_treasure_chests(result: Array) -> void:
	result.clear()
	for instance_id in active_treasure_chests:
		var chest = active_treasure_chests[instance_id]
		if is_instance_valid(chest) and not chest.is_queued_for_deletion(): result.append(chest)


## Battle-owned nodes resolve their hero here instead of the tree-wide group,
## which spans every online room on a match server.
func get_scoped_hero() -> Node2D:
	return hero if is_instance_valid(hero) else null


## Same-world members of a tree group. Solo battles keep the tree result as-is;
## online rooms share one SceneTree and compact out other match worlds in place.
func fill_scoped_group(group_name: StringName, result: Array) -> void:
	result.assign(get_tree().get_nodes_in_group(group_name))
	if not online_match_mode:
		return
	var world := get_viewport()
	var kept := 0
	for index in range(result.size()):
		var node = result[index]
		if is_instance_valid(node) and node.get_viewport() == world:
			result[kept] = node
			kept += 1
	result.resize(kept)


func _register_magnet_item(item: Node) -> void:
	if not is_instance_valid(item):
		return
	var iid := item.get_instance_id()
	active_magnet_items[iid] = item
	item.tree_exited.connect(
		Callable(self, "_on_magnet_item_tree_exited").bind(iid),
		Object.CONNECT_ONE_SHOT
	)


func _on_magnet_item_tree_exited(instance_id: int) -> void:
	active_magnet_items.erase(instance_id)


func _active_registry_size(registry: Dictionary) -> int:
	var stale_ids: Array = []
	for raw_id in registry:
		var node = registry.get(raw_id)
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			stale_ids.append(raw_id)
	for raw_id in stale_ids:
		registry.erase(raw_id)
	return registry.size()


func _spatial_cell_for_position(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / MONSTER_SPATIAL_CELL_SIZE),
		floori(world_position.y / MONSTER_SPATIAL_CELL_SIZE)
	)


func _rebuild_monster_spatial_grid() -> void:
	var profile_start: int = Time.get_ticks_usec() if combat_profile.enabled else 0
	# Keep cell Arrays alive and only clear buckets used by the previous
	# physics frame. This avoids rebuilding Dictionary/Array storage every
	# frame when large monster waves are active.
	monster_spatial_previous_cells.assign(monster_spatial_used_cells)
	for cell in monster_spatial_used_cells:
		var previous_bucket = monster_spatial_grid.get(cell, null)
		if typeof(previous_bucket) == TYPE_ARRAY:
			var reusable_bucket: Array = previous_bucket
			reusable_bucket.clear()

	monster_spatial_used_cells.clear()
	monster_spatial_stale_ids.clear()

	for raw_id in active_monsters:
		var node = active_monsters.get(raw_id)
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			monster_spatial_stale_ids.append(int(raw_id))
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var cell := _spatial_cell_for_position(monster.global_position)
		var raw_bucket = monster_spatial_grid.get(cell, null)
		var bucket: Array
		if typeof(raw_bucket) == TYPE_ARRAY:
			bucket = raw_bucket
		else:
			bucket = SPATIAL_BUCKET_POOL.acquire(monster_spatial_spare_buckets)
			monster_spatial_grid[cell] = bucket

		if bucket.is_empty():
			monster_spatial_used_cells.append(cell)
		bucket.append(monster)

	SPATIAL_BUCKET_POOL.retire_empty(monster_spatial_grid, monster_spatial_previous_cells, monster_spatial_spare_buckets)

	for raw_id in monster_spatial_stale_ids:
		_unregister_monster(raw_id)

	monster_spatial_grid_physics_frame = Engine.get_physics_frames()
	monster_spatial_snapshot_revision += 1
	if combat_profile.enabled: combat_profile.record(PERFORMANCE_PROBE.Scope.GRID,profile_start)


func _ensure_monster_spatial_grid() -> void:
	var physics_frame := Engine.get_physics_frames()
	if monster_spatial_grid_physics_frame != physics_frame:
		_rebuild_monster_spatial_grid()


func invalidate_monster_spatial_snapshot() -> void:
	monster_spatial_grid_physics_frame = -1


func get_monster_separation_bias(owner: Node2D, radius: float) -> Vector2:
	var profile_start := Time.get_ticks_usec() if combat_profile.enabled else 0
	_ensure_monster_spatial_grid()
	monster_local_grid.ensure(active_monsters, monster_spatial_snapshot_revision)
	var result := monster_local_grid.separation_bias(owner, radius)
	if combat_profile.enabled: combat_profile.record(PERFORMANCE_PROBE.Scope.SEPARATION,profile_start)
	return result


func count_monster_group_near(origin: Vector2, radius: float, group: StringName, excluded: Node, stop_after: int) -> int:
	_ensure_monster_spatial_grid()
	monster_local_grid.ensure(active_monsters, monster_spatial_snapshot_revision)
	return monster_local_grid.count_group_near(origin, radius, group, excluded, stop_after)


func fill_local_monsters_in_rect(world_rect: Rect2, result: Array) -> void:
	_ensure_monster_spatial_grid()
	monster_local_grid.ensure(active_monsters, monster_spatial_snapshot_revision)
	monster_local_grid.fill_rect(world_rect, result)


func fill_active_monsters(result: Array) -> void:
	result.clear()
	for raw_id in active_monsters:
		var raw_node = active_monsters.get(raw_id)
		if (
			not is_instance_valid(raw_node)
			or raw_node.is_queued_for_deletion()
		):
			continue
		var monster := raw_node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		result.append(monster)


func fill_monsters_near(
	origin: Vector2,
	radius: float,
	result: Array
) -> void:
	var profile_start: int = Time.get_ticks_usec() if combat_profile.enabled else 0
	result.clear()
	_ensure_monster_spatial_grid()

	var safe_radius := maxf(radius, 0.0)
	var min_cell := _spatial_cell_for_position(
		origin - Vector2(safe_radius, safe_radius)
	)
	var max_cell := _spatial_cell_for_position(
		origin + Vector2(safe_radius, safe_radius)
	)

	# One-cell padding prevents misses if a monster crossed a cell boundary
	# after the grid snapshot earlier in the same physics frame.
	min_cell -= Vector2i.ONE
	max_cell += Vector2i.ONE

	monster_candidate_cache.fill(monster_spatial_grid,min_cell,max_cell,monster_spatial_snapshot_revision,result)
	if combat_profile.enabled: combat_profile.record(PERFORMANCE_PROBE.Scope.QUERY,profile_start)

func query_monsters_near(origin: Vector2, radius: float) -> Array:
	var result: Array = []
	fill_monsters_near(origin, radius, result)
	return result


func count_monsters_near(
	origin: Vector2,
	radius: float,
	stop_after: int = 0
) -> int:
	_ensure_monster_spatial_grid()

	var safe_radius := maxf(radius, 0.0)
	var radius_sq := safe_radius * safe_radius
	var min_cell := _spatial_cell_for_position(
		origin - Vector2(safe_radius, safe_radius)
	)
	var max_cell := _spatial_cell_for_position(
		origin + Vector2(safe_radius, safe_radius)
	)
	min_cell -= Vector2i.ONE
	max_cell += Vector2i.ONE

	var count := 0
	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(cell_x, cell_y)
			var bucket = monster_spatial_grid.get(cell, null)
			if typeof(bucket) != TYPE_ARRAY:
				continue
			for node in bucket:
				if not HERO_TARGET_POLICY.is_detectable(node):
					continue
				var monster := node as Node2D
				if monster == null:
					continue
				if origin.distance_squared_to(monster.global_position) > radius_sq:
					continue
				count += 1
				if stop_after > 0 and count >= stop_after:
					return count
	return count


func get_nearest_hostile_target_for_hero(origin: Vector2) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF

	for raw_id in active_monsters:
		var raw_node = active_monsters.get(raw_id)
		if (
			not HERO_TARGET_POLICY.is_detectable(raw_node)
			or raw_node.is_queued_for_deletion()
		):
			continue
		var combat_target := raw_node as Node2D
		if combat_target == null:
			continue
		var hp_value = combat_target.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq := origin.distance_squared_to(
			combat_target.global_position
		)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = combat_target

	for raw_id in active_treasure_chests:
		var raw_node = active_treasure_chests.get(raw_id)
		if (
			not HERO_TARGET_POLICY.is_detectable(raw_node)
			or raw_node.is_queued_for_deletion()
		):
			continue
		var combat_target := raw_node as Node2D
		if combat_target == null:
			continue
		var hp_value = combat_target.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq := origin.distance_squared_to(
			combat_target.global_position
		)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = combat_target

	return nearest


func get_nearest_monster_target(
	origin: Vector2,
	radius: float
) -> Node2D:
	_ensure_monster_spatial_grid()

	var safe_radius := maxf(radius, 0.0)
	var nearest_distance_sq := safe_radius * safe_radius
	var nearest: Node2D = null
	var min_cell := _spatial_cell_for_position(
		origin - Vector2(safe_radius, safe_radius)
	)
	var max_cell := _spatial_cell_for_position(
		origin + Vector2(safe_radius, safe_radius)
	)
	min_cell -= Vector2i.ONE
	max_cell += Vector2i.ONE

	for cell_x in range(min_cell.x, max_cell.x + 1):
		for cell_y in range(min_cell.y, max_cell.y + 1):
			var bucket = monster_spatial_grid.get(
				Vector2i(cell_x, cell_y),
				null
			)
			if typeof(bucket) != TYPE_ARRAY:
				continue
			for raw_node in bucket:
				if (
					not HERO_TARGET_POLICY.is_detectable(raw_node)
					or raw_node.is_queued_for_deletion()
				):
					continue
				var monster := raw_node as Node2D
				if monster == null:
					continue
				var hp_value = monster.get("current_hp")
				if hp_value != null and int(hp_value) <= 0:
					continue
				var distance_sq := origin.distance_squared_to(
					monster.global_position
				)
				if distance_sq > nearest_distance_sq:
					continue
				nearest_distance_sq = distance_sq
				nearest = monster

	return nearest


func fill_monsters_in_rect(world_rect: Rect2, result: Array) -> void:
	var profile_start: int = Time.get_ticks_usec() if combat_profile.enabled else 0
	result.clear()
	_ensure_monster_spatial_grid()

	var min_cell := _spatial_cell_for_position(world_rect.position)
	var max_cell := _spatial_cell_for_position(world_rect.end)
	min_cell -= Vector2i.ONE
	max_cell += Vector2i.ONE

	monster_candidate_cache.fill(monster_spatial_grid,min_cell,max_cell,monster_spatial_snapshot_revision,result)
	if combat_profile.enabled: combat_profile.record(PERFORMANCE_PROBE.Scope.QUERY,profile_start)

func query_monsters_in_rect(world_rect: Rect2) -> Array:
	var result: Array = []
	fill_monsters_in_rect(world_rect, result)
	return result


func _ready() -> void:
	var test_mode := get_node_or_null("/root/LocalTestMode")
	practice_mode = not online_match_mode and test_mode != null and test_mode.consume_practice_request()
	if online_match_mode: _mission_service = null
	queue_redraw()
	elite_monster_skill_runtime.setup(self)
	scorpion_swamp_runtime.setup(self)
	wolf_pack_runtime.setup(self)
	goblin_formation_runtime.setup(self,MONSTER_CATALOG.MONSTERS)
	anubis_army_runtime.setup(MONSTER_CATALOG.MONSTERS)
	lizard_tail_runtime.setup(self)
	_cache_demon_ultimate_runtime_data()
	_start_battle()

func combat_delta(delta: float) -> float:
	return 0.0 if external_pause else delta * clock_scale


func set_clock_scale(value: float) -> void:
	var next_scale := clampf(value, 0.05, 1.0)
	if is_equal_approx(clock_scale, next_scale):
		return
	clock_scale = next_scale
	clock_scale_changed.emit(clock_scale)


func _process(delta: float) -> void:
	delta = combat_delta(delta)
	if not combat_profile.enabled:
		_process_battle(delta)
		return
	var started := Time.get_ticks_usec()
	_process_battle(delta)
	combat_profile.record(PERFORMANCE_PROBE.Scope.BATTLE,started)
	combat_profile.frame(delta)

func _process_battle(delta: float) -> void:
	if manual_spawn_warning_timer > 0.0:
		manual_spawn_warning_timer = maxf(
			manual_spawn_warning_timer - delta,
			0.0
		)
		queue_redraw()

	if battle_over:
		return

	if not flow_pause_manager.is_paused(
		FLOW_PAUSE_MANAGER.DOMAIN_DEMON_RUNTIME
	):
		elite_monster_skill_runtime.tick(delta)
		support_buff_runtime.tick(delta)
		wolf_pack_runtime.tick(delta)
		goblin_formation_runtime.tick(delta)
		anubis_army_runtime.tick()
		lizard_tail_runtime.tick(delta)
		yuki_runtime.tick(delta)
		scorpion_swamp_runtime.tick(delta)
		_process_demon_ultimate_spawn_queue(delta)
		_process_stage_reinforcement_queue(delta)
		_update_demon_ultimate_cooldowns(delta)

		if demon_ultimate_charge < DEMON_ULTIMATES.CHARGE_MAX:
			var previous_charge := demon_ultimate_charge
			demon_ultimate_charge = minf(
				demon_ultimate_charge
				+ DEMON_ULTIMATES.PASSIVE_CHARGE_PER_SECOND * delta,
				DEMON_ULTIMATES.CHARGE_MAX
			)
			demon_ultimate_emit_timer -= delta

			var reached_full_charge := (
				previous_charge + 0.001 < DEMON_ULTIMATES.CHARGE_MAX
				and demon_ultimate_charge + 0.001
				>= DEMON_ULTIMATES.CHARGE_MAX
			)
			if reached_full_charge:
				demon_ultimate_emit_timer = 0.10
				_emit_demon_ultimate_changed()
			elif demon_ultimate_emit_timer <= 0.0:
				demon_ultimate_emit_timer = 0.10
				_emit_demon_ultimate_changed()

	if not flow_pause_manager.is_paused(
		FLOW_PAUSE_MANAGER.DOMAIN_RUN_TIMER
	):
		run_metrics.tick(delta)

		if not flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_STAGE_EVENTS
		):
			if not practice_mode and not hero_player_mode:
				_process_stage_director_events()

		run_time_emit_timer -= delta
		if run_time_emit_timer <= 0.0:
			run_time_emit_timer = 0.25
			run_time_changed.emit(
				run_metrics.elapsed_seconds,
				run_metrics.get_remaining_seconds()
			)

		if not practice_mode and run_metrics.is_time_up():
			_on_run_time_up()
			if not hero_player_mode: return

	if (
		not flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_COMMAND_REGEN
		)
		and command_power < max_command
	):
		command_power = minf(
			command_power + command_regen_per_second * delta,
			max_command
		)
		command_emit_timer -= delta

		if command_emit_timer <= 0.0 or command_power >= max_command:
			command_emit_timer = 0.10
			command_changed.emit(command_power, max_command)

func _uses_castle_battlefield(stage_id: String) -> bool:
	if not stage_id.begins_with("stage_"):
		return false
	var stage_number := stage_id.trim_prefix("stage_").to_int()
	return stage_number >= 1 and stage_number <= 10


func _configure_castle_depth_actor(actor: Node2D, visual_node_name: String) -> void:
	if not _uses_castle_battlefield(current_stage_id) or not is_instance_valid(actor):
		return

	# Layer 3: passable-during-phase castle decor footprints.
	# Layer 4: hard castle boundaries (the upper wall) that must always block.
	if actor is CollisionObject2D:
		(actor as CollisionObject2D).collision_mask |= (1 << 2) | (1 << 3)

	# Battle.y_sort_enabled compares direct children at the same Z. Normalize
	# only the main body visual; skill/projectile FX keep their own Z layers.
	actor.z_index = 0
	var visual := actor.get_node_or_null(visual_node_name) as CanvasItem
	if is_instance_valid(visual):
		visual.z_index = 0


func _cache_demon_ultimate_runtime_data() -> void:
	demon_ultimate_skill_ids.clear()
	demon_ultimate_cheapest_cost = maxf(
		DEMON_ULTIMATES.CHARGE_MAX,
		1.0
	)
	var valid_skill_ids: Array = DEMON_ULTIMATES.get_ordered_ids()
	var selected_skill_ids: Array = online_match_rules.get("skill_ids",[]) if online_match_mode else DEMON_SKILL_LOADOUT_STORE.load_ids(valid_skill_ids,valid_skill_ids)
	for raw_id in selected_skill_ids:
		var skill_id := String(raw_id)
		demon_ultimate_skill_ids.append(skill_id)
		var skill := DEMON_ULTIMATES.get_skill(skill_id)
		if skill.is_empty() or not bool(skill.get("implemented", false)):
			continue
		var mana_cost := maxf(
			float(skill.get("mana_cost", DEMON_ULTIMATES.CHARGE_MAX)),
			0.0
		)
		demon_ultimate_cheapest_cost = minf(
			demon_ultimate_cheapest_cost,
			mana_cost
		)


func _start_battle() -> void:
	monster_candidate_cache.reset()
	if _hero_subtree_paused: process_mode = _hero_subtree_previous_mode
	_hero_subtree_paused = false
	_hero_paused_total_msec = 0
	_hero_pause_started_msec = 0
	battle_command_router.begin_session(_execute_battle_command)
	battle_entity_registry.begin_session(battle_command_router.get_session_id())
	demon_augment_revision += 1
	mutation_choice_revision += 1
	var registered_id := String(online_match_rules.get("transcendence_id","")) if online_match_mode else "" if hero_player_mode else TRANSCENDENCE_STORE.load_id()
	transcendent_actor = null
	raw_allied_summons = 0
	raw_real_tank_summons = 0
	raw_statuses_applied = 0
	raw_allied_deaths = 0
	raw_tank_deaths = 0
	transcendence.configure(registered_id, TRANSCENDENCE_DATA.get_rules(registered_id) if bool(MONSTER_CATALOG.MONSTERS.get(registered_id, {}).get("combat_enabled", true)) else {})
	transcendence_changed.emit(registered_id, false, false)
	battle_over = false
	hero_final_boss_spawned = false
	_hero_boss_spawn_pending = false
	_run_reward_granted = false
	_run_reward_save_failed = false
	elite_monster_skill_runtime.reset()
	wolf_pack_runtime.reset()
	goblin_formation_runtime.reset()
	anubis_army_runtime.reset()
	gumiho_shared_runtime.reset()
	lizard_tail_runtime.reset()
	yuki_runtime.reset()
	active_heal_items.clear()
	active_treasure_chests.clear()
	active_magnet_items.clear()
	exp_magnet_until_msec = 0
	var valid_orb_pool: Array[Node2D] = []
	for pooled_orb in exp_orb_pool:
		if is_instance_valid(pooled_orb) and not pooled_orb.is_queued_for_deletion():
			valid_orb_pool.append(pooled_orb)
	exp_orb_pool = valid_orb_pool
	active_monsters.clear()
	online_visual_projectiles.clear()
	hero_control_spawns.reset()
	hero_control_roster.clear()
	monster_query_registration_order = 0
	monster_population_counts.clear()
	monster_population_ids.clear()
	direct_population_ids.clear()
	active_hero_summons.clear()
	active_elite_skeletons.clear()
	monster_spatial_grid.clear()
	monster_spatial_previous_cells.clear()
	monster_spatial_spare_buckets.clear()
	monster_local_grid.clear()
	monster_spatial_used_cells.clear()
	monster_spatial_stale_ids.clear()
	fusion_scratch.clear()
	fusion_candidates.clear()
	ghost_shared_hit_count = 0
	ghost_death_buff_candidates.clear()
	monster_spatial_grid_physics_frame = -1
	external_pause = false
	flow_pause_manager.reset()
	monsters_alive = 0
	run_time_emit_timer = 0.0
	manual_spawn_warning_timer = 0.0

	max_command = BASE_MAX_COMMAND
	command_power = START_COMMAND
	command_regen_per_second = BASE_COMMAND_REGEN_PER_SECOND

	demon_level = 1
	demon_exp = 0.0
	demon_exp_to_next_level = _required_demon_exp_for_level(demon_level)
	demon_pending_augments = 0
	demon_pending_augment_levels.clear()
	demon_active_augment_level = 0
	demon_ultimate_charge = 0.0
	demon_ultimate_emit_timer = 0.0
	demon_ultimate_spawn_queue.clear()
	demon_ultimate_spawn_timer = 0.0
	demon_ultimate_spawn_interval = 0.04
	demon_ultimate_spawn_batch_size = 2
	demon_ultimate_cooldowns.clear()
	for skill_id in demon_ultimate_skill_ids:
		demon_ultimate_cooldowns[skill_id] = 0.0
	demon_ultimate_cooldown_emit_timer = 0.0
	stage_reinforcement_queue.clear()
	stage_reinforcement_queue_index = 0
	stage_reinforcement_timer = 0.0
	stage_reinforcement_interval = 0.12
	stage_reinforcement_batch_size = 2
	hero_kills_toward_heal_item = 0
	hero_kills_toward_chest = 0
	hero_chests_spawned = 0
	hero_elite_kills_toward_chest = 0
	hero_kills_toward_magnet = 0

	summon_cost_multiplier = 1.0
	demon_exp_gain_multiplier = 1.0
	banshee_deaths_toward_elite = 0
	monster_speed_multiplier = 1.0
	monster_damage_multiplier = 1.0
	monster_hp_multiplier = 1.0
	monster_attack_speed_multiplier = 1.0
	death_refund_ratio = 0.0
	slime_split_chance = 0.0
	spider_slow_duration_multiplier = 1.0
	orc_hp_multiplier = 1.0

	demon_reroll_max = BASE_DEMON_REROLLS
	demon_rerolls_left = BASE_DEMON_REROLLS
	demon_augment_selection_active = false
	demon_augment_candidates.clear()
	demon_build_counts.clear()
	demon_last_candidate_ids.clear()
	demon_special_augments.clear()
	monster_augment_modifiers.clear()
	special_augment_cache_ids.clear()
	special_augment_config_cache.clear()
	mutation_director.reset()
	monster_summon_costs.clear()
	special_summon_counts.clear()
	if not hero_player_mode: _load_monster_collection_upgrades()

	if not hero_player_mode: _apply_permanent_research()

	var progress_state: Dictionary = {} if online_match_mode else STAGE_PROGRESS.load_state()
	current_stage_id = "stage_1" if practice_mode else String(progress_state.get("current_stage_id", "stage_1"))
	if hero_player_mode: current_stage_id = hero_player_stage
	current_stage_data = STAGE_CATALOG.get_stage(current_stage_id)

	if current_stage_data.is_empty():
		current_stage_id = "stage_1"
		current_stage_data = STAGE_CATALOG.get_stage(current_stage_id)
		if not online_match_mode: STAGE_PROGRESS.set_current_stage(current_stage_id)

	if not practice_mode and not tutorial_mode:
		command_power = clampf(float(current_stage_data.get("opening_command",START_COMMAND)),0.0,max_command)
	current_map_size = Vector2(
		float(current_stage_data.get("map_width", int(DEFAULT_MAP_SIZE.x))),
		float(current_stage_data.get("map_height", int(DEFAULT_MAP_SIZE.y)))
	)
	# Stages 1~10 share the Demon Castle map, progressively destroyed per stage.
	# Keep actor/prop depth rules consistent across the whole castle arc.
	if hero_player_mode: hero_control_roster = HERO_SURVIVAL.roster_for(int(current_stage_data.get("number",1)),campaign_difficulty)
	var scene_ids: Array = online_match_rules.get("roster", []) if online_match_mode else HERO_SURVIVAL.entry_monster_ids(int(current_stage_data.get("number",1)),campaign_difficulty) if hero_player_mode else allowed_monster_ids
	MONSTER_CATALOG.warm_scenes(scene_ids, get_instance_id())
	if not registered_id.is_empty(): MONSTER_CATALOG.warm_scenes([registered_id], get_instance_id())
	y_sort_enabled = _uses_castle_battlefield(current_stage_id)
	var castle_battlefield := get_node_or_null("Stage1Battlefield")
	if (
		is_instance_valid(castle_battlefield)
		and castle_battlefield.has_method("configure")
	):
		castle_battlefield.call(
			"configure",
			current_stage_id,
			current_map_size
		)
	queue_redraw()
	run_time_limit_seconds = maxf(
		float(current_stage_data.get("run_duration_seconds", 360.0)),
		60.0
	)
	stage_director.reset(current_stage_data)
	if hero_player_mode:
		run_time_limit_seconds = preload("res://src/data/hero_mode_catalog.gd").DURATION
		command_power = preload("res://src/data/hero_mode_catalog.gd").STARTING_COMMAND

	var hero_id: String = hero_player_hero_id if hero_player_mode else String(current_stage_data.get("hero_id", "ranged_rookie"))
	current_hero_profile = _apply_stage_hero_balance(
		HERO_PROFILES.get_profile(hero_id),
		current_stage_data
	)

	var hero_ai_profile_id := String(
		current_stage_data.get("hero_ai_profile_id", "")
	)
	var hero_ai_settings := HERO_AI_PROFILES.get_profile(hero_ai_profile_id)
	if not hero_ai_settings.is_empty():
		current_hero_profile["ai_settings"] = hero_ai_settings
	if hero_player_mode:
		current_hero_profile = preload("res://src/data/hero_weapon_catalog.gd").profile_for_survival(current_hero_profile)
		current_hero_profile["display_name"] = String(preload("res://src/data/hero_character_catalog.gd").get_character(hero_player_hero_id).get("name","용사"))
		if not online_match_mode: preload("res://src/systems/hero_mode_store.gd").apply_growth(hero_player_hero_id,current_hero_profile)
		if not online_match_mode: current_hero_profile["survival_learning"] = HERO_SURVIVAL.pacing_value("learning",int(current_stage_data.get("number",1)),campaign_difficulty)

	if practice_mode:
		current_hero_profile = HERO_PROFILES.get_profile("ranged_rookie").duplicate(true)
		current_hero_profile["display_name"] = "연습 더미 · HP ∞"
	hero = HERO_SCENE.instantiate() as Node2D
	if hero_player_mode: hero.set("player_controlled",true)
	if practice_mode:
		hero.set_script(PRACTICE_HERO)
	if not online_match_mode and not practice_mode and not tutorial_mode:
		current_hero_profile["display_name"] = STAGE_PROGRESS.hero_display_name(hero_id, String(current_hero_profile.get("display_name", "용사")))
	if hero.has_method("configure_profile"):
		hero.call("configure_profile", current_hero_profile)
	if hero.has_method("configure_battlefield"):
		hero.call("configure_battlefield", current_map_size)
	hero.set("level", 1 if hero_player_mode else int(current_stage_data.get("hero_level_start", 1)))

	add_child(hero)
	_activate_battle_entity(hero)
	hero.position = current_map_size * 0.5
	if hero_player_mode:
		hero.set("player_weapons",preload("res://src/hero_mode/hero_weapon_runtime.gd").new())
		hero.player_weapons.install(hero,0 if online_match_mode else preload("res://src/systems/hero_mode_store.gd").augment_reroll_bonus(),current_hero_profile.get("hero_research_bonuses",{}))
	# add_child() runs Hero._ready(), which reapplies the profile visual and
	# restores HeroSprite.z_index. Normalize Demon Castle depth only after _ready()
	# so the hero participates in Battle's Y-sort just like monsters/props.
	_configure_castle_depth_actor(hero, "HeroSprite")

	run_metrics.reset(
		run_time_limit_seconds,
		int(hero.get("current_hp")),
		int(hero.get("max_hp"))
	)
	if hero.has_signal("accepted_damage_hit"):
		hero.connect("accepted_damage_hit", Callable(self, "_on_monster_hit_hero"))
	hero.connect("health_changed", Callable(self, "_on_hero_health_changed"))
	hero.connect("status_action_applied", Callable(self, "_on_enemy_status_applied"))
	hero.connect("combat_damage_received", Callable(self, "_on_hero_combat_damage_received"))
	hero.connect("progression_changed", Callable(self, "_on_hero_progression_changed"))
	hero.connect("leveled_up", Callable(self, "_on_hero_leveled_up"))
	hero.connect("augment_selected", Callable(self, "_on_hero_augment_selected"))
	hero.connect(
		"conditional_skill_unlocked",
		Callable(self, "_on_hero_conditional_skill_unlocked")
	)
	hero.connect("died", Callable(self, "_on_hero_died"))

	_emit_stats()
	_emit_progression()
	command_changed.emit(command_power, max_command)
	demon_progression_changed.emit(demon_level, demon_exp, demon_exp_to_next_level)
	_emit_demon_ultimate_changed()
	_emit_demon_ultimate_cooldowns()
	run_time_changed.emit(
		run_metrics.elapsed_seconds,
		run_metrics.get_remaining_seconds()
	)

	# Defer until Hero and battle tree are fully ready. Each monster type warms
	# within a loading-frame budget so startup stays responsive instead of moving one hitch
	# from the first summon to a single battle-start frame.
	call_deferred("_warm_monster_spawn_resources")


func prepare_spawn_resources() -> void:
	if not _monster_spawn_warmup_running:
		await _warm_monster_spawn_resources()
	while _monster_spawn_warmup_running and is_inside_tree():
		await get_tree().process_frame


func spawn_warmup_ids() -> Array:
	if online_match_mode: return []
	if hero_player_mode:
		return HERO_SURVIVAL.entry_monster_ids(int(current_stage_data.get("number",1)),campaign_difficulty)
	var ids: Array = allowed_monster_ids.duplicate()
	var registered := String(transcendence.monster_id)
	if not registered.is_empty() and registered not in ids: ids.append(registered)
	return ids


func _warm_monster_spawn_resources() -> void:
	if online_match_mode:
		_monster_spawn_resources_warmed = true
		return # Dedicated rooms do not warm unused solo presentation actors.
	if _monster_spawn_resources_warmed or _monster_spawn_warmup_running:
		return
	_monster_spawn_warmup_running = true
	var slice_start := Time.get_ticks_usec()

	for raw_id in spawn_warmup_ids():
		if not is_inside_tree() or battle_over:
			_monster_spawn_warmup_running = false
			return

		var monster_id := String(raw_id)
		var scene := MONSTER_CATALOG.get_scene(monster_id)
		if scene == null:
			continue

		var warmup := scene.instantiate() as Node2D
		if warmup == null:
			continue

		# _ready() fills the normal visual/effect caches. Disabled processing
		# prevents this temporary instance from joining combat simulation.
		warmup.process_mode = Node.PROCESS_MODE_DISABLED
		warmup.visible = false
		warmup.position = Vector2(-10000.0, -10000.0)
		add_child(warmup)

		# Keep this encounter's normal/elite cache ready, yielding by work
		# budget instead of paying two display frames for each monster type.
		if Time.get_ticks_usec() - slice_start >= PresentationWarmup.MAIN_THREAD_BUDGET_US:
			await get_tree().process_frame
			slice_start = Time.get_ticks_usec()
		_apply_elite_monster_visual(warmup, monster_id)

		remove_child(warmup)
		warmup.free()
		if Time.get_ticks_usec() - slice_start >= PresentationWarmup.MAIN_THREAD_BUDGET_US:
			await get_tree().process_frame
			slice_start = Time.get_ticks_usec()

	await _warm_transcendent_exp_drop()
	_monster_spawn_resources_warmed = true
	_monster_spawn_warmup_running = false


func _apply_stage_hero_balance(
	profile: Dictionary,
	stage_data: Dictionary
) -> Dictionary:
	if profile.is_empty():
		return {}

	var balanced := profile.duplicate(true)
	var raw_balance = stage_data.get("hero_balance", {})
	if typeof(raw_balance) != TYPE_DICTIONARY:
		return balanced
	var balance: Dictionary = raw_balance
	if balance.is_empty():
		return balanced

	if balanced.has("max_hp"):
		balanced["max_hp"] = maxi(
			1,
			int(round(
				float(balanced["max_hp"])
				* maxf(float(balance.get("hp_multiplier", 1.0)), 0.01)
			))
		)
	if balanced.has("attack_damage"):
		balanced["attack_damage"] = maxi(
			1,
			int(round(
				float(balanced["attack_damage"])
				* maxf(float(balance.get("damage_multiplier", 1.0)), 0.01)
			))
		)
	if balanced.has("move_speed"):
		balanced["move_speed"] = maxf(
			float(balanced["move_speed"])
			* maxf(float(balance.get("move_speed_multiplier", 1.0)), 0.01),
			1.0
		)
	if balanced.has("attack_cooldown"):
		balanced["attack_cooldown"] = maxf(
			float(balanced["attack_cooldown"])
			* maxf(
				float(balance.get("attack_cooldown_multiplier", 1.0)),
				0.01
			),
			0.10
		)
	balanced["stage_balance"] = balance.duplicate(true)
	return balanced


func _apply_permanent_research() -> void:
	permanent_research_levels.clear()
	for research_id in RESEARCH_CATALOG.get_ordered_ids():
		permanent_research_levels[research_id] = STAGE_PROGRESS.get_research_level(research_id)

	var power_level := int(permanent_research_levels.get("monster_power", 0))
	var vitality_level := int(permanent_research_levels.get("monster_vitality", 0))
	var mobility_level := int(permanent_research_levels.get("monster_mobility", 0))
	var attack_speed_level := int(
		permanent_research_levels.get("monster_attack_speed", 0)
	)
	var summon_level := int(
		permanent_research_levels.get("summon_efficiency", 0)
	)
	var reservoir_level := int(permanent_research_levels.get("mana_reservoir", 0))
	var cycle_level := int(permanent_research_levels.get("mana_cycle", 0))
	var notebook_level := int(permanent_research_levels.get("tactical_notebook", 0))
	var experiment_level := int(permanent_research_levels.get("rapid_experiment", 0))

	var power_points := RESEARCH_CATALOG.get_effective_level_points(
		"monster_power",
		power_level
	)
	var vitality_points := RESEARCH_CATALOG.get_effective_level_points(
		"monster_vitality",
		vitality_level
	)
	var mobility_points := RESEARCH_CATALOG.get_effective_level_points(
		"monster_mobility",
		mobility_level
	)
	var attack_speed_points := RESEARCH_CATALOG.get_effective_level_points(
		"monster_attack_speed",
		attack_speed_level
	)
	var summon_points := RESEARCH_CATALOG.get_effective_level_points(
		"summon_efficiency",
		summon_level
	)
	var cycle_points := RESEARCH_CATALOG.get_effective_level_points(
		"mana_cycle",
		cycle_level
	)
	var reservoir_points := RESEARCH_CATALOG.get_effective_level_points(
		"mana_reservoir",
		reservoir_level
	)
	var experiment_points := RESEARCH_CATALOG.get_effective_level_points(
		"rapid_experiment",
		experiment_level
	)

	monster_damage_multiplier *= 1.0 + 0.01 * power_points
	monster_hp_multiplier *= 1.0 + 0.01 * vitality_points
	monster_speed_multiplier *= 1.0 + 0.0035 * mobility_points
	monster_attack_speed_multiplier *= (
		1.0 / (1.0 + 0.005 * attack_speed_points)
	)
	summon_cost_multiplier *= maxf(0.80, 1.0 - 0.01 * summon_points)
	command_regen_per_second += 0.15 * cycle_points
	max_command += 5.0 * reservoir_points
	demon_exp_gain_multiplier += 0.03 * experiment_points
	demon_reroll_max += notebook_level
	demon_rerolls_left = demon_reroll_max


func _load_monster_collection_upgrades() -> void:
	monster_collection_upgrade_levels.clear()
	var collection_state := MONSTER_COLLECTION_STORE.load_state()
	for raw_id in MONSTER_CATALOG.ORDER:
		var monster_id := String(raw_id)
		var level := MONSTER_COLLECTION_STORE.get_upgrade_level(
			monster_id,
			collection_state
		)
		if level > 0:
			monster_collection_upgrade_levels[monster_id] = level


func _get_monster_collection_upgrade_multiplier(
	monster_id: String,
	stat_key: String
) -> float:
	var level := maxi(
		int(monster_collection_upgrade_levels.get(monster_id, 0)),
		0
	)
	if level <= 0:
		return 1.0
	var profile := MONSTER_CATALOG.get_rarity_upgrade_profile(monster_id)
	if not bool(profile.get("configured", false)):
		return 1.0
	var rate := maxf(float(profile.get(stat_key, 0.0)), 0.0)
	return 1.0 + rate * float(level)

func get_permanent_research_summary() -> String:
	var active: PackedStringArray = []
	for research_id in RESEARCH_CATALOG.get_ordered_ids():
		var level := int(permanent_research_levels.get(research_id, 0))
		if level <= 0:
			continue
		var data: Dictionary = RESEARCH_CATALOG.get_research(research_id)
		active.append("%s Lv.%d" % [String(data.get("name", research_id)), level])

	if active.is_empty():
		return "연구 없음"
	return " · ".join(active)

func set_allowed_monster_ids(monster_ids: Array) -> void:
	allowed_monster_ids.clear()

	for raw_id in monster_ids:
		var monster_id := String(raw_id)
		if monster_id.is_empty():
			continue
		if monster_id in allowed_monster_ids:
			continue
		allowed_monster_ids.append(monster_id)

	loadout_restriction_enabled = not allowed_monster_ids.is_empty()
	if is_inside_tree(): MONSTER_CATALOG.warm_scenes(allowed_monster_ids, get_instance_id())

func try_summon(monster_type: String) -> bool:
	if online_match_mode:
		return false
	if not battle_command_router.supports_local_execution():
		return false
	if not command_routing_enabled:
		return _execute_summon(monster_type)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.SUMMON_AUTO, monster_type)

func try_summon_at_position(monster_type: String, spawn_position: Vector2) -> bool:
	if not battle_command_router.supports_local_execution():
		return false
	if not command_routing_enabled:
		return _execute_summon_at_position(monster_type, spawn_position)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.SUMMON_AT, monster_type, spawn_position)

func try_summon_transcendent() -> bool:
	if online_match_mode:
		return false
	if not battle_command_router.supports_local_execution():
		return false
	if not command_routing_enabled:
		return _execute_summon_transcendent()
	return battle_command_router.submit_local(BATTLE_SESSION.Command.SUMMON_TRANSCENDENT)

func try_summon_transcendent_at_position(spawn_position: Vector2) -> bool:
	if not online_match_mode or not battle_command_router.supports_local_execution():
		return false
	return _execute_summon_transcendent(spawn_position)

func try_use_demon_ultimate(skill_id: String, direction: String = "") -> bool:
	if not battle_command_router.supports_local_execution():
		return false
	if not command_routing_enabled:
		return _execute_demon_ultimate(skill_id, direction)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.DEMON_SKILL, skill_id, Vector2.ZERO, direction)

func _execute_battle_command(request: BATTLE_COMMAND) -> bool:
	match request.kind:
		BATTLE_SESSION.Command.SUMMON_AUTO:
			return _execute_summon(request.subject_id)
		BATTLE_SESSION.Command.SUMMON_AT:
			return _execute_summon_at_position(request.subject_id, request.position)
		BATTLE_SESSION.Command.SUMMON_TRANSCENDENT:
			return _execute_summon_transcendent()
		BATTLE_SESSION.Command.DEMON_SKILL:
			return _execute_demon_ultimate(request.subject_id, request.direction)
		BATTLE_SESSION.Command.DEMON_AUGMENT_CHOOSE:
			return _execute_choose_demon_augment(request.subject_id, request.choice_revision)
		BATTLE_SESSION.Command.DEMON_AUGMENT_REROLL:
			return _execute_reroll_demon_augments(request.choice_revision)
		BATTLE_SESSION.Command.MUTATION_CHOOSE:
			return _execute_selected_mutation(request.subject_id, request.choice_revision)
	return false

func get_battle_command_diagnostics() -> Dictionary:
	return battle_command_router.snapshot()

func set_battle_command_profiling(enabled: bool) -> void:
	battle_command_router.profiling_enabled = enabled

func get_run_clock_diagnostics() -> Dictionary:
	return run_metrics.get_clock_snapshot()

func _activate_battle_entity(node: Node) -> Vector3i:
	var handle: Vector3i = battle_entity_registry.activate(node)
	if handle == Vector3i.ZERO:
		return handle
	# One connection per node, including thousands of pool activations. Binding
	# the local instance ID avoids keeping an extra Node reference in callbacks.
	var on_exit := _on_battle_entity_tree_exited.bind(node.get_instance_id())
	if not node.tree_exited.is_connected(on_exit):
		node.tree_exited.connect(on_exit)
	return handle

func _on_battle_entity_tree_exited(instance_id: int) -> void:
	battle_entity_registry.retire_instance(instance_id)
	if online_match_mode:
		online_visual_projectiles.erase(instance_id)
		online_visual_entity_exited.emit(instance_id)

func get_battle_entity_handle(node: Node) -> Vector3i:
	return battle_entity_registry.get_handle(node)

func get_last_battle_entity_handle(node: Node) -> Vector3i:
	return battle_entity_registry.get_last_handle(node)

func resolve_battle_entity(handle: Vector3i) -> Node:
	return battle_entity_registry.resolve(handle)

func get_battle_entity_diagnostics() -> Dictionary:
	return battle_entity_registry.snapshot()

func _execute_summon(monster_type: String) -> bool:
	if not _can_attempt_summon(monster_type):
		return false

	var cost: float = get_monster_cost(monster_type)
	if command_power + 0.001 < cost:
		summon_result.emit(
			monster_type,
			false,
			"지휘력이 부족합니다. 필요 %.1f / 현재 %.0f" % [cost, command_power]
		)
		return false

	return _perform_summon(monster_type, _get_auto_spawn_position(), cost, false)

func _execute_summon_at_position(monster_type: String, spawn_position: Vector2) -> bool:
	if not _can_attempt_summon(monster_type):
		return false

	var placement_error := get_manual_spawn_error(monster_type, spawn_position)
	if not placement_error.is_empty():
		summon_result.emit(monster_type, false, placement_error)
		return false

	var cost: float = get_monster_cost(monster_type)

	return _perform_summon(
		monster_type,
		_clamp_manual_spawn_position(spawn_position),
		cost,
		true
	)

func debug_unlock_transcendence(allow_without_local_mode := false) -> bool:
	if (not LocalTestMode.active and not allow_without_local_mode) or battle_over or external_pause or demon_augment_selection_active:
		return false
	var id: String = transcendence.monster_id
	if not TRANSCENDENCE_DATA.is_transcendent(id) or not bool(MONSTER_CATALOG.MONSTERS.get(id, {}).get("combat_enabled", true)):
		return false
	if not transcendence.satisfy_conditions_for_test():
		return false
	transcendence_changed.emit(id, true, false)
	return true


func _execute_summon_transcendent(manual_position: Variant = null) -> bool:
	var id: String = transcendence.monster_id
	if not _can_attempt_summon(id, true):
		return false
	if online_match_mode and (not manual_position is Vector2 or not manual_position.is_finite()):
		return false
	if manual_position is Vector2:
		var placement_error := get_manual_spawn_error(id,manual_position,true)
		if not placement_error.is_empty():
			summon_result.emit(id,false,placement_error)
			return false
	var cost: float = get_monster_cost(id)
	if command_power + 0.001 < cost:
		summon_result.emit(id, false, "초월 소환에 필요한 지휘력이 부족합니다.")
		return false
	return _perform_summon(id, _clamp_manual_spawn_position(manual_position) if manual_position is Vector2 else _get_auto_spawn_position(), cost, manual_position is Vector2)

func _can_attempt_summon(monster_type: String, transcendence_attempt: bool = false) -> bool:
	if not bool(MONSTER_CATALOG.MONSTERS.get(monster_type, {}).get("combat_enabled", true)):
		summon_result.emit(monster_type, false, "전투 능력을 준비 중인 몬스터입니다.")
		return false
	if battle_over:
		summon_result.emit(monster_type, false, "전투가 종료되어 소환할 수 없습니다.")
		return false

	if external_pause:
		summon_result.emit(monster_type, false, "스테이지 메뉴를 닫은 뒤 소환해 주세요.")
		return false

	if demon_augment_selection_active and not online_match_mode:
		summon_result.emit(monster_type, false, "마왕 증강을 먼저 선택해 주세요.")
		return false

	if TRANSCENDENCE_DATA.is_transcendent(monster_type):
		if not transcendence_attempt or monster_type != transcendence.monster_id or not transcendence.ready or transcendence.used:
			summon_result.emit(monster_type, false, "등록된 초월 몬스터의 해금 조건을 달성해야 합니다.")
			return false
	elif transcendence_attempt:
		return false
	if not transcendence_attempt and loadout_restriction_enabled and monster_type not in allowed_monster_ids:
		summon_result.emit(
			monster_type,
			false,
			"현재 팀에 편성되지 않은 몬스터입니다."
		)
		return false

	if is_population_full():
		summon_result.emit(monster_type, false, "인구수가 가득 찼습니다. 직접 소환은 최대 지휘력만큼 가능합니다.")
		return false

	if _monster_population_limit_reached(monster_type):
		summon_result.emit(monster_type, false, "최대 소환 개체 수에 도달했습니다.")
		return false

	if get_monster_cost(monster_type) <= 0.0 and not (transcendence_attempt and TRANSCENDENCE_DATA.is_transcendent(monster_type)):
		summon_result.emit(monster_type, false, "알 수 없는 몬스터입니다.")
		return false

	return true

func _perform_summon(monster_type: String, spawn_position: Vector2, cost: float, manual: bool) -> bool:
	command_power = maxf(command_power - cost, 0.0)

	var is_transcendent := TRANSCENDENCE_DATA.is_transcendent(monster_type)
	var giant_spawn := not is_transcendent and bool(MONSTER_CATALOG.MONSTERS[monster_type].get("can_be_giant", true)) and _roll_giant_monster_for_normal_summon()
	var primary_monster = _spawn_monster(
		monster_type,
		spawn_position,
		cost,
		false,
		{"giant_monster": giant_spawn, "transcendence_summon": is_transcendent, "counts_population": true}
	)
	if not is_instance_valid(primary_monster):
		command_power += cost
		return false
	if transcendence.record_command(cost):
		transcendence_changed.emit(transcendence.monster_id, true, false)
	if not is_transcendent:
		_spawn_extra_normal_summon_monsters(monster_type, spawn_position)
	if is_transcendent:
		transcendence.consume()
		transcendence_changed.emit(transcendence.monster_id, false, true)
		transcendent_summoned.emit(monster_type, primary_monster)
	var fusion_profile := MONSTER_CATALOG.get_summon_fusion_profile(monster_type)
	if not fusion_profile.is_empty() and is_instance_valid(primary_monster):
		primary_monster = _try_fuse_nearby_monsters(primary_monster, fusion_profile)
	run_metrics.record_summon(monster_type, cost)

	if is_instance_valid(hero) and hero.has_method("record_offensive_event"):
		hero.call(
			"record_offensive_event",
			monster_type,
			MONSTER_CATALOG.get_role(monster_type)
		)

	command_changed.emit(command_power, max_command)
	_emit_stats()

	var base_summon_exp := MONSTER_CATALOG.get_summon_exp(monster_type)
	var gained_exp := base_summon_exp * demon_exp_gain_multiplier
	run_metrics.record_summon_demon_exp(monster_type, gained_exp)
	var mode_text := "수동 배치" if manual else "소환"
	var giant_text := (
		" · 대형몹!"
		if (
			is_instance_valid(primary_monster)
			and bool(primary_monster.get_meta("giant_monster", false))
		)
		else ""
	)
	summon_result.emit(
		monster_type,
		true,
		"%s %s%s 지휘력 %.1f 소모 · 마왕 EXP +%.1f" % [
			_get_monster_name(monster_type),
			mode_text,
			giant_text,
			cost,
			gained_exp,
		]
	)

	_gain_demon_exp(gained_exp)
	_add_demon_ultimate_charge(
		cost * DEMON_ULTIMATES.SUMMON_COST_CHARGE_MULTIPLIER
	)
	return true

func get_manual_spawn_error(
	monster_type: String,
	spawn_position: Vector2,
	transcendence_attempt: bool = false
) -> String:
	if not _is_spawn_position_inside_bounds(spawn_position):
		return "배치 불가\n전장 안쪽을 터치"

	if not _is_spawn_position_far_enough_from_hero(spawn_position):
		return "용사와 너무 가까움"

	var cost := get_monster_cost(monster_type)
	if cost <= 0.0 and not (transcendence_attempt and TRANSCENDENCE_DATA.is_transcendent(monster_type)):
		return "배치 불가"

	if command_power + 0.001 < cost:
		return "지휘력 부족\n필요 %.1f" % cost

	return ""

func is_manual_spawn_too_close_to_hero(spawn_position: Vector2) -> bool:
	return (
		_is_spawn_position_inside_bounds(spawn_position)
		and not _is_spawn_position_far_enough_from_hero(spawn_position)
	)

func show_manual_spawn_restricted_area() -> void:
	manual_spawn_warning_timer = MANUAL_SPAWN_WARNING_DURATION
	queue_redraw()

func is_spawn_position_valid(spawn_position: Vector2) -> bool:
	return (
		_is_spawn_position_inside_bounds(spawn_position)
		and _is_spawn_position_far_enough_from_hero(spawn_position)
	)

func _get_spawn_top_margin() -> float:
	# The Demon Castle top wall occupies the upper map band. Keep monster centers
	# below it with enough clearance for their collision radius.
	return (
		CASTLE_TOP_SPAWN_MARGIN
		if _uses_castle_battlefield(current_stage_id)
		else MANUAL_SPAWN_MARGIN
	)


func _is_spawn_position_inside_bounds(spawn_position: Vector2) -> bool:
	var top_margin := _get_spawn_top_margin()
	return (
		spawn_position.x >= MANUAL_SPAWN_MARGIN
		and spawn_position.x <= current_map_size.x - MANUAL_SPAWN_MARGIN
		and spawn_position.y >= top_margin
		and spawn_position.y <= current_map_size.y - MANUAL_SPAWN_MARGIN
	)

func _is_spawn_position_far_enough_from_hero(spawn_position: Vector2) -> bool:
	if not is_instance_valid(hero):
		return true

	return (
		spawn_position.distance_to(hero.position)
		>= MANUAL_SPAWN_HERO_MIN_DISTANCE
	)

func _clamp_manual_spawn_position(spawn_position: Vector2) -> Vector2:
	return Vector2(
		clampf(
			spawn_position.x,
			MANUAL_SPAWN_MARGIN,
			current_map_size.x - MANUAL_SPAWN_MARGIN
		),
		clampf(
			spawn_position.y,
			_get_spawn_top_margin(),
			current_map_size.y - MANUAL_SPAWN_MARGIN
		)
	)


func clamp_monster_wander_position(candidate: Vector2) -> Vector2:
	return _clamp_manual_spawn_position(candidate)


func get_monster_cost(monster_type: String) -> float:
	var base_cost: float = MONSTER_CATALOG.get_base_cost(monster_type)
	if base_cost <= 0.0:
		return 0.0

	var monster_cost_multiplier := _get_monster_augment_multiplier(
		monster_type,
		"cost"
	)
	return snappedf(
		base_cost * summon_cost_multiplier * monster_cost_multiplier * _get_special_stat_multiplier(monster_type,"cost"),
		0.1
	)


func get_monster_run_detail(monster_id: String) -> Dictionary:
	if not MONSTER_CATALOG.MONSTERS.has(monster_id):
		return {}

	var base_stats := MONSTER_CATALOG.get_base_stats(monster_id)
	if base_stats.is_empty():
		return {}
	var rarity := MONSTER_CATALOG.get_rarity(monster_id)
	var rarity_combat := MONSTER_CATALOG.get_rarity_combat_profile(
		monster_id
	)
	var rarity_hp_multiplier := maxf(
		float(rarity_combat.get("hp_multiplier", 1.0)),
		0.01
	)
	var rarity_damage_multiplier := maxf(
		float(rarity_combat.get("damage_multiplier", 1.0)),
		0.01
	)
	var rarity_speed_multiplier := maxf(
		float(rarity_combat.get("move_speed_multiplier", 1.0)),
		0.01
	)
	var rarity_attack_cooldown_multiplier := maxf(
		float(rarity_combat.get("attack_cooldown_multiplier", 1.0)),
		0.01
	)
	var collection_hp_multiplier := _get_monster_collection_upgrade_multiplier(
		monster_id,
		"hp_per_level"
	)
	var collection_damage_multiplier := _get_monster_collection_upgrade_multiplier(
		monster_id,
		"damage_per_level"
	)

	var detail := {
		"monster_id": monster_id,
		"name": MONSTER_CATALOG.get_monster_name(monster_id),
		"collection_upgrade_level": int(
			monster_collection_upgrade_levels.get(monster_id, 0)
		),
		"species": MONSTER_CATALOG.get_species(monster_id),
		"species_label": MONSTER_CATALOG.get_species_label(
			MONSTER_CATALOG.get_species(monster_id)
		),
		"grade": MONSTER_CATALOG.get_grade(monster_id),
		"grade_label": MONSTER_CATALOG.get_grade_label(
			MONSTER_CATALOG.get_grade(monster_id)
		),
		"rarity": rarity,
		"attack_type": MONSTER_CATALOG.get_attack_type(monster_id),
		"attack_type_label": MONSTER_CATALOG.get_attack_type_label(
			MONSTER_CATALOG.get_attack_type(monster_id)
		),
		"cost": get_monster_cost(monster_id),
		"summon_exp": MONSTER_CATALOG.get_summon_exp(monster_id),
		"demon_level": demon_level,
		"normal_augments": [],
		"special_augments": [],
	}

	if TRANSCENDENCE_DATA.is_transcendent(monster_id):
		var count := _transcendence_growth_count(monster_id)
		if is_instance_valid(transcendent_actor) and String(transcendent_actor.monster_type) == monster_id:
			count = transcendent_actor.summon_snapshot
		var growth: Dictionary = MONSTER_CATALOG.MONSTERS[monster_id].get("summon_growth",{})
		detail.merge(base_stats, true)
		for stat in growth:
			detail[stat] = int(round(float(base_stats.get(stat,0))+count*float(growth[stat])))
		var attack_growth: Dictionary = MONSTER_CATALOG.MONSTERS[monster_id].get("attack_growth",{})
		if not attack_growth.is_empty():
			var attack_count := _transcendence_metric_count(String(attack_growth.metric))
			if is_instance_valid(transcendent_actor) and String(transcendent_actor.monster_type) == monster_id:
				attack_count = transcendent_actor.attack_snapshot
			detail["attack_snapshot"] = attack_count
			detail["attack_damage"] = int(round(float(base_stats.get("attack_damage",0))+attack_count*float(attack_growth.multiplier)))
		detail["combat_style"] = MONSTER_CATALOG.MONSTERS[monster_id].get("combat_style","")
		detail["summon_snapshot"] = count
		return detail

	if base_stats.has("max_hp"):
		var hp_value := (
			float(base_stats["max_hp"])
			* rarity_hp_multiplier
			* collection_hp_multiplier
			* monster_hp_multiplier
			* _get_monster_augment_multiplier(monster_id, "hp")
		)
		hp_value *= _get_monster_hp_upgrade_multiplier(monster_id)
		detail["max_hp"] = maxi(
			1,
			int(round(
				hp_value
				* _get_demon_level_monster_hp_multiplier() * _get_special_stat_multiplier(monster_id, "hp")
			))
		)

	if base_stats.has("attack_damage"):
		detail["attack_damage"] = maxi(
			1,
			int(round(
				float(base_stats["attack_damage"])
				* rarity_damage_multiplier
				* collection_damage_multiplier
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_id, "damage")
				* _get_demon_level_monster_damage_multiplier() * _get_special_stat_multiplier(monster_id, "damage")
			))
		)

	if base_stats.has("move_speed"):
		detail["move_speed"] = (
			float(base_stats["move_speed"])
			* rarity_speed_multiplier
			* monster_speed_multiplier
			* _get_monster_augment_multiplier(monster_id, "speed")
			* _get_demon_level_monster_speed_multiplier()
		)

	if base_stats.has("attack_cooldown"):
		detail["attack_cooldown"] = maxf(
			0.10,
			float(base_stats["attack_cooldown"])
			* rarity_attack_cooldown_multiplier
			* monster_attack_speed_multiplier
			* _get_special_stat_multiplier(monster_id, "attack_cooldown")
			* _get_monster_augment_multiplier(
				monster_id,
				"attack_cooldown"
			)
		)

	if base_stats.has("explosion_damage"):
		detail["explosion_damage"] = maxi(
			1,
			int(round(
				float(base_stats["explosion_damage"])
				* rarity_damage_multiplier
				* collection_damage_multiplier
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_id, "damage")
				* _get_demon_level_monster_damage_multiplier() * _get_special_stat_multiplier(monster_id, "damage")
			))
		)

	if base_stats.has("explosion_radius"):
		detail["explosion_radius"] = float(base_stats["explosion_radius"])

	if base_stats.has("self_destruct_fuse"):
		detail["self_destruct_fuse"] = maxf(
			0.10,
			float(base_stats["self_destruct_fuse"])
			* rarity_attack_cooldown_multiplier
			* monster_attack_speed_multiplier
		)

	var normal_augments: Array = []
	for raw_augment in DEMON_AUGMENTS.get_monster_normal_augments(
		monster_id,
		MONSTER_CATALOG.get_monster_name(monster_id)
	):
		var augment: Dictionary = raw_augment
		var augment_id := String(augment.get("id", ""))
		var level := int(demon_build_counts.get(augment_id, 0))
		if level <= 0:
			continue
		normal_augments.append({
			"name": String(augment.get("name", augment_id)),
			"level": level,
		})
	detail["normal_augments"] = normal_augments

	var special_augments: Array = []
	for augment_id in _get_selected_special_augment_ids_for_monster(monster_id):
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		special_augments.append({
			"id": augment_id,
			"name": String(augment.get("name", augment_id)),
		})
	detail["special_augments"] = special_augments

	_apply_special_runtime_preview(detail,monster_id)
	return detail


func set_elite_skeleton_alive(monster: Node, alive: bool) -> void:
	if not is_instance_valid(monster):
		return
	var instance_id := monster.get_instance_id()
	if alive:
		active_elite_skeletons[instance_id] = monster
		var cleanup := Callable(
			self,
			"_on_elite_skeleton_tree_exited"
		).bind(instance_id)
		if not monster.tree_exited.is_connected(cleanup):
			monster.tree_exited.connect(cleanup, Object.CONNECT_ONE_SHOT)
	else:
		active_elite_skeletons.erase(instance_id)


func _on_elite_skeleton_tree_exited(instance_id: int) -> void:
	active_elite_skeletons.erase(instance_id)


func has_living_elite_skeleton() -> bool:
	return not active_elite_skeletons.is_empty()


func set_hero_summon_active(
	summon: Node2D,
	is_active: bool
) -> void:
	if not is_instance_valid(summon):
		return
	var summon_id := summon.get_instance_id()
	if is_active and not summon.is_queued_for_deletion():
		active_hero_summons[summon_id] = summon
	else:
		active_hero_summons.erase(summon_id)


func get_nearest_hero_combat_target(origin: Vector2) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_sq := INF

	if is_instance_valid(hero) and not hero.is_queued_for_deletion():
		nearest = hero
		nearest_distance_sq = origin.distance_squared_to(hero.global_position)

	# Only active Stage 8 summons live in this registry. Target refresh avoids
	# scanning preallocated inactive pools (especially the large drone pool).
	for summon_id in active_hero_summons:
		var raw_summon = active_hero_summons.get(summon_id)
		if (
			not is_instance_valid(raw_summon)
			or raw_summon.is_queued_for_deletion()
		):
			continue
		var summon := raw_summon as Node2D
		if summon == null or not bool(summon.get("active")):
			continue
		if (
			summon.has_method("is_combat_targetable")
			and not bool(summon.call("is_combat_targetable"))
		):
			continue
		var distance_sq := origin.distance_squared_to(summon.global_position)
		if distance_sq >= nearest_distance_sq:
			continue
		nearest_distance_sq = distance_sq
		nearest = summon

	return nearest



func _get_auto_spawn_position() -> Vector2:
	var origin := current_map_size * 0.5
	if is_instance_valid(hero):
		origin = hero.position

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(float(current_stage_data.get("auto_spawn_min_distance",AUTO_SPAWN_MIN_DISTANCE)),float(current_stage_data.get("auto_spawn_max_distance",AUTO_SPAWN_MAX_DISTANCE)))
	var candidate := origin + Vector2.from_angle(angle) * distance
	return _clamp_manual_spawn_position(candidate)

func _get_giant_monster_summon_chance() -> float:
	if hero_player_mode: return 0.0 # Survival has scheduled elite/giant encounters.
	if demon_level < GIANT_MONSTER_UNLOCK_LEVEL:
		return 0.0
	var level_steps := floori(
		float(demon_level - GIANT_MONSTER_UNLOCK_LEVEL)
		/ float(GIANT_MONSTER_LEVEL_STEP)
	)
	return clampf(
		GIANT_MONSTER_BASE_CHANCE
		+ float(level_steps) * GIANT_MONSTER_CHANCE_PER_STEP,
		0.0,
		1.0
	)


func _roll_giant_monster_for_normal_summon() -> bool:
	var chance := _get_giant_monster_summon_chance()
	return chance > 0.0 and randf() < chance


func _apply_giant_monster_base_stats(
	monster: Node2D,
	monster_type: String
) -> void:
	if not is_instance_valid(monster):
		return

	monster.set_meta("giant_monster", true)
	monster.set_meta(
		"giant_stat_multiplier",
		GIANT_MONSTER_STAT_MULTIPLIER
	)
	monster.set_meta(
		"giant_hp_multiplier",
		GIANT_MONSTER_HP_MULTIPLIER
	)
	monster.set_meta(
		"giant_size_multiplier",
		GIANT_MONSTER_SIZE_MULTIPLIER
	)

	# Apply the giant factor before raw augment baselines are captured. This
	# makes later Demon-level/augment refreshes preserve the giant bonuses.
	var max_hp_value = monster.get("max_hp")
	if max_hp_value != null:
		monster.set(
			"max_hp",
			maxi(
				1,
				int(round(
					float(max_hp_value)
					* GIANT_MONSTER_HP_MULTIPLIER
				))
			)
		)

	var move_speed_value = monster.get("move_speed")
	if move_speed_value != null:
		monster.set(
			"move_speed",
			float(move_speed_value) * GIANT_MONSTER_STAT_MULTIPLIER
		)

	var exp_value = monster.get("exp_reward")
	if exp_value != null:
		monster.set(
			"exp_reward",
			maxi(
				1,
				int(round(
					float(exp_value)
					* GIANT_MONSTER_STAT_MULTIPLIER
				))
			)
		)

	var giant_profile := MONSTER_CATALOG.get_giant_scaling_profile(monster_type)
	if bool(giant_profile.get("basic_attack", false)):
		var damage_value = monster.get("attack_damage")
		if damage_value != null:
			monster.set(
				"attack_damage",
				maxi(
					1,
					int(round(
						float(damage_value)
						* GIANT_MONSTER_STAT_MULTIPLIER
					))
				)
			)

		var attack_range_value = monster.get("attack_range")
		if attack_range_value != null:
			var attack_range_multiplier := GIANT_MONSTER_STAT_MULTIPLIER
			if bool(giant_profile.get("ranged_attack", false)):
				attack_range_multiplier = GIANT_MONSTER_SIZE_MULTIPLIER
			monster.set(
				"attack_range",
				float(attack_range_value) * attack_range_multiplier
			)

		var attack_cooldown_value = monster.get("attack_cooldown")
		if attack_cooldown_value != null:
			monster.set(
				"attack_cooldown",
				maxf(
					0.10,
					float(attack_cooldown_value)
					/ GIANT_MONSTER_STAT_MULTIPLIER
				)
			)

	if bool(giant_profile.get("ranged_attack", false)):
		monster.set(
			"projectile_speed",
			float(monster.get("projectile_speed"))
			* GIANT_MONSTER_STAT_MULTIPLIER
		)
		monster.set(
			"projectile_range",
			float(monster.get("projectile_range"))
			* GIANT_MONSTER_SIZE_MULTIPLIER
		)
		var projectile_size_value = monster.get(
			"projectile_size_multiplier"
		)
		if projectile_size_value != null:
			monster.set(
				"projectile_size_multiplier",
				float(projectile_size_value)
				* GIANT_MONSTER_SIZE_MULTIPLIER
			)

	for raw_property in giant_profile.get("stat_properties", MONSTER_CATALOG.EMPTY_GIANT_STAT_PROPERTIES):
		var property: StringName = raw_property
		monster.set(
			property,
			float(monster.get(property)) * GIANT_MONSTER_STAT_MULTIPLIER
		)

	_apply_giant_stat_property_rules(
		monster,
		giant_profile.get("property_rules", MONSTER_CATALOG.EMPTY_GIANT_STAT_PROPERTIES)
	)

	# Scaling the CharacterBody doubles the authored visual and its child
	# CollisionShape2D together. This keeps the collision footprint matched to
	# the requested 2x body size without mutating shared Shape2D resources.
	monster.scale *= GIANT_MONSTER_SIZE_MULTIPLIER


func _apply_giant_stat_property_rules(monster: Node, rules: Array) -> void:
	for rule in rules:
		var property: StringName = rule["property"]
		var value := float(monster.get(property))
		value = value / GIANT_MONSTER_STAT_MULTIPLIER if bool(rule.get("inverse", false)) else value * GIANT_MONSTER_STAT_MULTIPLIER
		if bool(rule.get("integer", false)):
			var integer_value := int(round(value))
			if rule.has("minimum"):
				integer_value = maxi(int(rule["minimum"]), integer_value)
			monster.set(property, integer_value)
		else:
			if rule.has("minimum"):
				value = maxf(float(rule["minimum"]), value)
			monster.set(property, value)


func promote_monster_to_giant(
	monster: Node2D,
	monster_type: String
) -> bool:
	if (
		not is_instance_valid(monster)
		or monster.is_queued_for_deletion()
		or bool(monster.get_meta("giant_monster", false))
		or String(monster.get_meta("visual_variant", "")) == "elite"
	):
		return false
	if String(monster.get("monster_type")) != monster_type:
		return false

	monster.set_meta("giant_monster", true)
	monster.set_meta("giant_stat_multiplier", GIANT_MONSTER_STAT_MULTIPLIER)
	monster.set_meta("giant_hp_multiplier", GIANT_MONSTER_HP_MULTIPLIER)
	monster.set_meta("giant_size_multiplier", GIANT_MONSTER_SIZE_MULTIPLIER)

	var raw_hp = monster.get_meta("augment_raw_max_hp") if monster.has_meta("augment_raw_max_hp") else null
	if raw_hp != null:
		monster.set_meta(
			"augment_raw_max_hp",
			maxf(float(raw_hp) * GIANT_MONSTER_HP_MULTIPLIER, 1.0)
		)
	var raw_speed = monster.get_meta("augment_raw_move_speed") if monster.has_meta("augment_raw_move_speed") else null
	if raw_speed != null:
		monster.set_meta(
			"augment_raw_move_speed",
			maxf(float(raw_speed) * GIANT_MONSTER_STAT_MULTIPLIER, 1.0)
		)
	var raw_damage = monster.get_meta("augment_raw_attack_damage") if monster.has_meta("augment_raw_attack_damage") else null
	if raw_damage != null:
		monster.set_meta(
			"augment_raw_attack_damage",
			maxf(float(raw_damage) * GIANT_MONSTER_STAT_MULTIPLIER, 1.0)
		)
	var raw_cooldown = monster.get_meta("augment_raw_attack_cooldown", null)
	if raw_cooldown != null:
		monster.set_meta(
			"augment_raw_attack_cooldown",
			maxf(float(raw_cooldown) / GIANT_MONSTER_STAT_MULTIPLIER, 0.10)
		)

	var attack_range_value = monster.get("attack_range")
	if attack_range_value != null:
		var range_multiplier := GIANT_MONSTER_STAT_MULTIPLIER
		if bool(MONSTER_CATALOG.get_giant_scaling_profile(monster_type).get("ranged_attack", false)):
			range_multiplier = GIANT_MONSTER_SIZE_MULTIPLIER
		monster.set("attack_range", float(attack_range_value) * range_multiplier)

	var exp_value = monster.get("exp_reward")
	if exp_value != null:
		monster.set(
			"exp_reward",
			maxi(1, int(round(float(exp_value) * GIANT_MONSTER_STAT_MULTIPLIER)))
		)

	monster.scale *= GIANT_MONSTER_SIZE_MULTIPLIER
	_apply_normal_augments_to_existing_monster(monster, monster_type)
	monster_spatial_grid_physics_frame = -1
	if monster.has_method("queue_redraw"):
		monster.call("queue_redraw")
	return true


func hero_spawn_candidate(id: String,roster: Array,elite: bool = false) -> String:
	if not hero_player_mode: return id
	return hero_control_spawns.choose(id,roster,elite,int(current_stage_data.get("number",1)),float(run_metrics.elapsed_seconds),active_monsters.size())


func _spawn_monster(
	monster_type: String,
	spawn_position: Vector2,
	summon_cost: float = 0.0,
	split_child: bool = false,
	spawn_modifiers: Dictionary = {}
):
	var reserved_boss := _is_reserved_hero_boss_request(monster_type,spawn_modifiers)
	if online_match_mode and (active_monsters.size() >= get_population_limit() or (monster_type not in online_match_rules.get("roster",[]) and not (bool(spawn_modifiers.get("transcendence_summon",false)) and monster_type == String(online_match_rules.get("transcendence_id",""))))): return null
	# Online uses its roster and command-based population; solo survival supply pacing
	# must not block the opposing player's paid summons (notably controllers).
	var solo_hero_spawn := hero_player_mode and not online_match_mode
	if solo_hero_spawn and run_metrics.elapsed_seconds >= HERO_SURVIVAL.DURATION and not reserved_boss: return null
	if solo_hero_spawn and (active_monsters.size() >= HERO_SURVIVAL.monster_limit(int(current_stage_data.get("number",1)))+(1 if reserved_boss else 0) or not HERO_SURVIVAL.monster_allowed(monster_type,int(current_stage_data.get("number",1)),campaign_difficulty)): return null
	if solo_hero_spawn and not reserved_boss and not hero_control_spawns.allows(monster_type,bool(spawn_modifiers.get("elite_variant",false)),int(current_stage_data.get("number",1)),float(run_metrics.elapsed_seconds),active_monsters.size()): return null
	if not reserved_boss and bool(spawn_modifiers.get("counts_population", false)) and is_population_full():
		return null
	if not bool(MONSTER_CATALOG.MONSTERS.get(monster_type, {}).get("combat_enabled", true)):
		return null
	var scene := MONSTER_CATALOG.get_scene(monster_type)
	if TRANSCENDENCE_DATA.is_transcendent(monster_type):
		if not bool(spawn_modifiers.get("transcendence_summon",false)) or monster_type != transcendence.monster_id or not transcendence.ready or transcendence.used:
			return null
	if scene == null:
		push_warning("Unknown monster id: %s" % monster_type)
		return null

	if not reserved_boss and _monster_population_limit_reached(monster_type, bool(spawn_modifiers.get("elite_variant", false))):
		return null
	if bool(MONSTER_CATALOG.MONSTERS[monster_type].get("spawn_at_max_range", false)) and is_instance_valid(hero) and not bool(spawn_modifiers.get("hero_encounter_position_locked",false)):
		spawn_position = get_stationary_spawn_position(monster_type, hero.global_position, spawn_position)
	# Never instantiate a monster inside the solid upper castle wall. This is
	# also the catch-all for queued ultimates/reinforcements that precomputed
	# their positions with older/general map margins.
	spawn_position = _clamp_manual_spawn_position(spawn_position)
	var monster := scene.instantiate() as Node2D
	if monster == null:
		return null
	if bool(spawn_modifiers.get("elite_variant", false)):
		monster.set_meta("visual_variant", "elite")
	# Canonical role/grade stats must precede every spawn modifier and _ready().
	if not TRANSCENDENCE_DATA.is_transcendent(monster_type):
		MONSTER_CATALOG.apply_runtime_base_stats(monster, monster_type)
	if hero_player_mode:
		monster.set_meta("hero_survival_spawn_seconds",run_metrics.elapsed_seconds)
	var fixed_base_stats := TRANSCENDENCE_DATA.is_transcendent(monster_type) or bool(spawn_modifiers.get("fixed_base_stats", false))
	monster.set_meta("fixed_base_stats", fixed_base_stats)
	monster.set_meta("exclude_all_augments", fixed_base_stats or bool(spawn_modifiers.get("exclude_all_augments", false)))
	var monster_species := MONSTER_CATALOG.get_species(monster_type)
	monster.set_meta("monster_species", monster_species)
	monster.set_meta("noncollision_family",String(MONSTER_CATALOG.MONSTERS[monster_type].get("noncollision_family","")))
	monster.set_meta(
		"monster_family",
		MONSTER_CATALOG.get_family(monster_type)
	)
	# Compatibility flag for older runtime code. Canonical classification stays
	# in MonsterCatalog/species and should be queried through node_has_species().
	monster.set_meta("is_undead", monster_species == "undead")
	monster.set_meta(
		"monster_grade",
		MONSTER_CATALOG.get_grade(monster_type)
	)
	var monster_rarity := MONSTER_CATALOG.get_rarity(monster_type)
	var rarity_combat := MONSTER_CATALOG.get_rarity_combat_profile(
		monster_type
	)
	monster.set_meta("monster_rarity", monster_rarity)
	var rarity_hp_multiplier := maxf(
		float(rarity_combat.get("hp_multiplier", 1.0)),
		0.01
	)
	var rarity_damage_multiplier := maxf(
		float(rarity_combat.get("damage_multiplier", 1.0)),
		0.01
	)
	var rarity_speed_multiplier := maxf(
		float(rarity_combat.get("move_speed_multiplier", 1.0)),
		0.01
	)
	var rarity_attack_cooldown_multiplier := maxf(
		float(rarity_combat.get("attack_cooldown_multiplier", 1.0)),
		0.01
	)
	var collection_hp_multiplier := _get_monster_collection_upgrade_multiplier(
		monster_type,
		"hp_per_level"
	)
	var collection_damage_multiplier := _get_monster_collection_upgrade_multiplier(
		monster_type,
		"damage_per_level"
	)
	monster.set_meta(
		"monster_collection_upgrade_level",
		int(monster_collection_upgrade_levels.get(monster_type, 0))
	)
	var is_giant := bool(spawn_modifiers.get("giant_monster", false)) and bool(MONSTER_CATALOG.MONSTERS[monster_type].get("can_be_giant", true))
	if is_giant and not split_child:
		_apply_giant_monster_base_stats(monster, monster_type)
	_ensure_monster_ground_shadow(monster, monster_type)

	var raw_speed_value = monster.get("move_speed")
	if raw_speed_value != null:
		monster.set_meta("augment_raw_move_speed", float(raw_speed_value))
	var raw_attack_cooldown = monster.get("attack_cooldown")
	if raw_attack_cooldown != null:
		monster.set_meta(
			"augment_raw_attack_cooldown",
			float(raw_attack_cooldown)
		)
	var raw_damage_value = monster.get("attack_damage")
	if raw_damage_value != null:
		monster.set_meta("augment_raw_attack_damage", float(raw_damage_value))
	var raw_hp_value = monster.get("max_hp")
	if raw_hp_value != null:
		monster.set_meta("augment_raw_max_hp", float(raw_hp_value))
	var raw_fuse_value = monster.get("self_destruct_fuse")
	if raw_fuse_value != null:
		monster.set_meta(
			"augment_raw_self_destruct_fuse",
			float(raw_fuse_value)
		)
	var raw_explosion_damage = monster.get("explosion_damage")
	if raw_explosion_damage != null:
		monster.set_meta(
			"augment_raw_explosion_damage",
			float(raw_explosion_damage)
		)

	var speed_value = monster.get("move_speed")
	if speed_value != null:
		monster.set_meta(
			"demon_level_base_move_speed",
			float(speed_value)
			* rarity_speed_multiplier
			* monster_speed_multiplier
			* _get_monster_augment_multiplier(monster_type, "speed")
		)

	var attack_cooldown_value = monster.get("attack_cooldown")
	if attack_cooldown_value != null:
		monster.set(
			"attack_cooldown",
			maxf(
				0.10,
				float(attack_cooldown_value)
				* rarity_attack_cooldown_multiplier
				* monster_attack_speed_multiplier
				* _get_special_stat_multiplier(monster_type, "attack_cooldown", String(monster.get_meta("visual_variant", "")) == "elite")
				* _get_monster_augment_multiplier(
					monster_type,
					"attack_cooldown"
				)
			)
		)

	var runtime_scaling := MONSTER_CATALOG.get_runtime_scaling_profile(monster_type)
	var fuse_property: StringName = runtime_scaling.get("fuse_property", &"")
	if not fuse_property.is_empty():
		var fuse_value = monster.get(fuse_property)
		if fuse_value != null:
			monster.set(
				fuse_property,
				maxf(
					0.10,
					float(fuse_value)
					* rarity_attack_cooldown_multiplier
					* monster_attack_speed_multiplier
					* _get_monster_augment_multiplier(
						monster_type,
						"attack_cooldown"
					)
				)
			)

	var damage_value = monster.get("attack_damage")
	if damage_value != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(
				1.0,
				float(damage_value)
				* rarity_damage_multiplier
				* collection_damage_multiplier
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_type, "damage")
			)
		)

	var explosion_property: StringName = runtime_scaling.get("explosion_property", &"")
	if not explosion_property.is_empty():
		var explosion_damage_value = monster.get(explosion_property)
		if explosion_damage_value != null:
			monster.set(
				explosion_property,
				maxi(
					1,
					int(round(
						float(explosion_damage_value)
						* rarity_damage_multiplier
						* collection_damage_multiplier
						* monster_damage_multiplier
						* _get_monster_augment_multiplier(
							monster_type,
							"damage"
						)
						* _get_demon_level_monster_damage_multiplier()
					))
				)
			)

	_apply_monster_spawn_property_multipliers(monster, monster_type)

	var max_hp_value = monster.get("max_hp")
	if max_hp_value != null:
		var level_base_hp := (
			float(max_hp_value)
			* rarity_hp_multiplier
			* collection_hp_multiplier
			* monster_hp_multiplier
			* _get_monster_augment_multiplier(monster_type, "hp")
		)
		level_base_hp *= _get_monster_hp_upgrade_multiplier(monster_type)
		level_base_hp *= maxf(
			float(spawn_modifiers.get("hp_multiplier", 1.0)),
			0.01
		)
		monster.set_meta(
			"demon_level_base_max_hp",
			maxf(level_base_hp, 1.0)
		)

	var base_damage_meta = monster.get_meta(
		"demon_level_base_attack_damage",
		null
	) if monster.has_meta("demon_level_base_attack_damage") else null
	if base_damage_meta != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(
				float(base_damage_meta)
				* maxf(
					float(spawn_modifiers.get("damage_multiplier", 1.0)),
					0.01
				),
				1.0
			)
		)

	var base_speed_meta = monster.get_meta(
		"demon_level_base_move_speed",
		null
	)
	if base_speed_meta != null:
		monster.set_meta(
			"demon_level_base_move_speed",
			maxf(
				float(base_speed_meta)
				* maxf(
					float(spawn_modifiers.get("speed_multiplier", 1.0)),
					0.01
				),
				1.0
			)
		)

	var exp_value = monster.get("exp_reward")
	if exp_value != null and not split_child:
		monster.set(
			"exp_reward",
			maxi(
				1,
				int(round(
					float(exp_value)
					* maxf(
						float(spawn_modifiers.get("exp_multiplier", 1.0)),
						0.0
					)
				))
			)
		)

	var visual_scale := maxf(
		float(spawn_modifiers.get("visual_scale", 1.0)),
		0.1
	)
	if absf(visual_scale - 1.0) > 0.001:
		monster.scale *= visual_scale

	var stage_event_type := String(
		spawn_modifiers.get("stage_event_type", "")
	)
	if not stage_event_type.is_empty():
		monster.set_meta("stage_event_type", stage_event_type)
		monster.set_meta(
			"stage_event_name",
			String(spawn_modifiers.get("stage_event_name", ""))
		)

	_apply_demon_level_scaling_to_monster(monster, false)

	if split_child:
		var split_exp_value = monster.get("exp_reward")
		if split_exp_value != null:
			monster.set("exp_reward", 0)

	# Give monsters direct access to the Battle target authority before _ready().
	# Their normal combat path no longer needs SceneTree hero-group lookups.
	if monster.has_method("configure_combat_context"):
		monster.call(
			"configure_combat_context",
			hero,
			self
		)

	if monster.has_method("configure_transcendence"):
		monster.configure_transcendence(_transcendence_growth_count(monster_type),int(monster_collection_upgrade_levels.get(monster_type,0)))
		if monster.has_method("configure_attack_snapshot"):
			var attack_growth: Dictionary = MONSTER_CATALOG.MONSTERS[monster_type].get("attack_growth",{})
			monster.configure_attack_snapshot(_transcendence_metric_count(String(attack_growth.get("metric","summons"))))
		transcendent_actor = monster
	add_child(monster)
	monster.position = spawn_position
	# Keep depth normalization after the monster's _ready() for consistency.
	_configure_castle_depth_actor(monster, "Visual")
	monster.set_meta("split_child", split_child)
	monster.set_meta(
		"spawn_source",
		"augment" if split_child else "normal"
	)
	if bool(monster.get_meta("exclude_all_augments", false)):
		_apply_augment_free_base_stats(monster, monster_type)
	_apply_special_augments_to_monster(monster, monster_type)
	if not split_child and not bool(monster.get_meta("exclude_all_augments", false)) and String(monster.get_meta("visual_variant", "")) != "elite":
		_configure_summon_cadence(monster, monster_type)
		if monster.has_method("on_spawn_stats_finalized"):
			monster.call("on_spawn_stats_finalized")
	monster.connect("died", Callable(self, "_on_monster_died").bind(monster))

	var monster_instance_id := monster.get_instance_id()
	monster_summon_costs[monster_instance_id] = summon_cost
	active_monsters[monster_instance_id] = monster
	if solo_hero_spawn: hero_control_spawns.register(monster_instance_id,monster_type,bool(spawn_modifiers.get("elite_variant",false)),int(current_stage_data.get("number",1)),float(run_metrics.elapsed_seconds))
	_activate_battle_entity(monster)
	monster.set_meta("query_registration_order", monster_query_registration_order)
	monster_query_registration_order += 1
	if bool(spawn_modifiers.get("counts_population", false)):
		direct_population_ids[monster_instance_id] = true
		_queue_population_update()
	monster.set_meta("counts_population", direct_population_ids.has(monster_instance_id))
	# Stagger common target refreshes instead of waking the entire army together.
	if monster.get("hero_target_refresh_timer") != null:
		monster.set("hero_target_refresh_timer", fmod(float(monster_query_registration_order) * 0.0954915, 0.25))
	monster_population_ids[monster_instance_id] = monster_type
	monster_population_counts[monster_type] = int(monster_population_counts.get(monster_type, 0)) + 1
	anubis_army_runtime.register(monster)
	monster.tree_exited.connect(_unregister_monster.bind(monster_instance_id), CONNECT_ONE_SHOT)
	monster_spatial_grid_physics_frame = -1
	monsters_alive += 1
	if not TRANSCENDENCE_DATA.is_transcendent(monster_type):
		raw_allied_summons += 1
	var effective_role := String(monster.get("monster_role")) if monster.get("monster_role") != null else MONSTER_CATALOG.get_role(monster_type)
	if not split_child and bool(spawn_modifiers.get("counts_population",false)) and not TRANSCENDENCE_DATA.is_transcendent(monster_type) and effective_role == "tank":
		raw_real_tank_summons += 1
	if not split_child and not TRANSCENDENCE_DATA.is_transcendent(monster_type) and transcendence.record_summon(effective_role if bool(spawn_modifiers.get("counts_population", false)) else ""):
		transcendence_changed.emit(transcendence.monster_id, true, false)
	if bool(spawn_modifiers.get("counts_population", false)) or bool(spawn_modifiers.get("mission_summon", false)):
		_record_mission_action("summon", 1.0)
	return monster


func _queue_population_update() -> void:
	if _population_update_pending:
		return
	_population_update_pending = true
	_emit_population_changed.call_deferred()

func _emit_population_changed() -> void:
	_population_update_pending = false
	population_changed.emit(get_population_count(), get_population_limit())

func get_population_count() -> int:
	return direct_population_ids.size()

func get_population_limit() -> int:
	if online_match_mode: return maxi(floori(max_command), 0)
	if hero_player_mode: return HERO_SURVIVAL.monster_limit(int(current_stage_data.get("number",1)))
	return maxi(floori(max_command), 0)

func is_population_full() -> bool:
	return get_population_count() >= get_population_limit()

func _unregister_monster(instance_id: int) -> void:
	hero_control_spawns.retire(instance_id)
	anubis_army_runtime.retire(instance_id)
	battle_entity_registry.retire_instance(instance_id)
	if direct_population_ids.erase(instance_id):
		_queue_population_update()
	if monster_population_ids.has(instance_id):
		var monster_id := String(monster_population_ids[instance_id])
		monster_population_counts[monster_id] = maxi(int(monster_population_counts.get(monster_id, 0)) - 1, 0)
		monster_population_ids.erase(instance_id)
	active_monsters.erase(instance_id)

func _apply_special_runtime_preview(detail: Dictionary, monster_id: String) -> void:
	for config in _get_special_augment_config(monster_id).values():
		var stats: Dictionary = config.get("runtime_stat_multipliers",{})
		for pair in [["max_hp","hp_multiplier"],["attack_damage","damage_multiplier"],["move_speed","speed_multiplier"],["attack_cooldown","attack_speed_multiplier"]]:
			if not detail.has(pair[0]): continue
			var value := float(detail[pair[0]])
			var multiplier := maxf(float(stats.get(pair[1],1.0)),0.01)
			value = value/multiplier if pair[0] == "attack_cooldown" else value*multiplier
			detail[pair[0]] = maxi(1,int(round(value))) if pair[0] in ["max_hp","attack_damage"] else value
		detail.merge(Dictionary(config.get("stat_overrides",{})),true)
		if config.has("attack_type_override"):
			detail["attack_type"] = String(config.attack_type_override)
			detail["attack_type_label"] = MONSTER_CATALOG.get_attack_type_label(String(config.attack_type_override))
		if config.has("role_override"):
			detail["role"] = String(config.role_override)
			detail["role_label"] = MONSTER_CATALOG.get_role_label(String(config.role_override))

func _configure_summon_cadence(monster: Node, monster_id: String) -> void:
	if bool(monster.get_meta("split_child",false)) or bool(monster.get_meta("exclude_all_augments",false)) or String(monster.get_meta("visual_variant","")) == "elite":
		return
	if not monster.has_method("configure_summon_variant"):
		return
	var configs := _get_special_augment_config(monster_id)
	for effect_type in configs:
		var every := int(configs[effect_type].get("summon_every",0))
		if every <= 0: continue
		var key := monster_id+":"+String(effect_type)
		var count := int(special_summon_counts.get(key,0))+1
		special_summon_counts[key] = count
		monster.call("configure_summon_variant",effect_type,count % every == 0)

func _get_applicable_special_augment_config(monster_id: String, elite_variant: bool = false) -> Dictionary:
	var configs := _get_special_augment_config(monster_id)
	if not elite_variant:
		return configs
	var applicable := configs.duplicate(true)
	for effect_type in configs:
		if bool(configs[effect_type].get("exclude_elite", false)):
			applicable.erase(effect_type)
	return applicable

func _monster_population_limit_reached(monster_id: String, elite_variant: bool = false) -> bool:
	var configs := _get_applicable_special_augment_config(monster_id, elite_variant)
	for effect_type in configs:
		var config: Dictionary = configs[effect_type]
		var limit := int(config.get("max_population", 0))
		var population := int(monster_population_counts.get(monster_id, 0))
		if limit <= 0 or population < limit:
			continue
		if bool(config.get("exclude_elite", false)):
			population = 0
			for instance_id in active_monsters:
				var actor = active_monsters[instance_id]
				if not is_instance_valid(actor) or actor.is_queued_for_deletion():
					continue
				if String(actor.get("monster_type")) == monster_id and String(actor.get_meta("visual_variant", "")) != "elite":
					population += 1
					if population >= limit:
						break
		if population >= limit:
			return true
	return false

func _get_special_stat_multiplier(monster_id: String, key: String, elite_variant: bool = false) -> float:
	var multiplier := 1.0
	var configs := _get_special_augment_config(monster_id)
	for effect_type in configs:
		var config: Dictionary = configs[effect_type]
		if elite_variant and bool(config.get("exclude_elite", false)):
			continue
		multiplier *= float(config.get("stat_multipliers", {}).get(key, 1.0))
	return multiplier

func get_stationary_spawn_position(monster_id: String, origin: Vector2, preferred: Vector2) -> Vector2:
	var radius := float(MONSTER_CATALOG.get_base_stats(monster_id).get("attack_range", 1000.0)) * _get_special_stat_multiplier(monster_id, "range")
	var start_angle := (preferred - origin).angle()
	var best := _clamp_manual_spawn_position(origin)
	var best_distance := -1.0
	for index in range(32):
		var candidate := _clamp_manual_spawn_position(origin + Vector2.from_angle(start_angle + TAU * index / 32.0) * radius)
		var distance := origin.distance_squared_to(candidate)
		if distance > best_distance:
			best_distance = distance
			best = candidate
		if distance >= radius * radius - 1.0:
			break
	return best

func _try_fuse_nearby_monsters(primary_monster: Node2D, profile: Dictionary) -> Node2D:
	if not _is_normal_fusion_candidate(primary_monster, profile):
		return primary_monster

	var config: Dictionary = _get_special_augment_config(
		profile["monster_id"]
	).get(profile["augment_id"], MONSTER_CATALOG.EMPTY_SUMMON_FUSION)
	if config.is_empty():
		return primary_monster

	var required_count := maxi(
		int(config.get(profile["count_key"], profile["default_count"])),
		int(profile["minimum_count"])
	)
	var radius := maxf(
		float(config.get(profile["radius_key"], profile["default_radius"])),
		float(profile["minimum_radius"])
	)
	fusion_scratch.clear()
	fusion_candidates.clear()
	fill_monsters_near(
		primary_monster.global_position,
		radius,
		fusion_scratch
	)
	var radius_sq := radius * radius
	for raw_monster in fusion_scratch:
		var candidate := raw_monster as Node2D
		if not _is_normal_fusion_candidate(candidate, profile):
			continue
		if candidate.global_position.distance_squared_to(
			primary_monster.global_position
		) > radius_sq:
			continue
		fusion_candidates.append(candidate)
		if fusion_candidates.size() >= required_count:
			break

	if fusion_candidates.size() < required_count:
		fusion_scratch.clear()
		fusion_candidates.clear()
		return primary_monster

	var fusion_position := Vector2.ZERO
	var fused_summon_cost := 0.0
	var fused_counts_population := false
	for raw_candidate in fusion_candidates:
		var candidate := raw_candidate as Node2D
		if not is_instance_valid(candidate):
			continue
		fused_counts_population = fused_counts_population or direct_population_ids.has(candidate.get_instance_id())
		fusion_position += candidate.global_position
		fused_summon_cost += float(
			monster_summon_costs.get(candidate.get_instance_id(), 0.0)
		)
	fusion_position /= float(required_count)

	for raw_candidate in fusion_candidates:
		var candidate := raw_candidate as Node2D
		_consume_monster_for_fusion(candidate)
	fusion_scratch.clear()
	fusion_candidates.clear()

	var result_modifiers: Dictionary = profile["result_modifiers"].duplicate()
	result_modifiers["counts_population"] = fused_counts_population
	var fused := _spawn_monster(
		profile["monster_id"],
		_clamp_manual_spawn_position(fusion_position),
		fused_summon_cost,
		false,
		result_modifiers
	) as Node2D
	if is_instance_valid(fused):
		fused.set_meta(profile["fusion_marker"], true)
		fused.set_meta("spawn_source", profile["spawn_source"])
		return fused
	return null


func _is_normal_fusion_candidate(monster: Node2D, profile: Dictionary) -> bool:
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		return false
	if String(monster.get("monster_type")) != String(profile["monster_id"]):
		return false
	if int(monster.get("current_hp")) <= 0:
		return false
	if String(monster.get_meta("visual_variant", "")) == String(profile["excluded_visual_variant"]):
		return false
	if bool(monster.get_meta("giant_monster", false)):
		return false
	if bool(monster.get_meta(profile["fusion_marker"], false)):
		return false
	if String(monster.get_meta("spawn_source", "")) == String(profile["spawn_source"]):
		return false
	if (
		float(monster.get_meta("giant_size_multiplier", profile["default_size_multiplier"]))
		> float(profile["maximum_normal_size"])
	):
		return false
	return true


func _consume_monster_for_fusion(monster: Node2D) -> void:
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		return
	var instance_id := monster.get_instance_id()
	monster_summon_costs.erase(instance_id)
	_unregister_monster(instance_id)
	active_elite_skeletons.erase(instance_id)
	monster_spatial_grid_physics_frame = -1
	monsters_alive = maxi(monsters_alive - 1, 0)
	monster.queue_free()


func spawn_elite_slime_minion(
	spawn_position: Vector2,
	landing_position: Vector2
) -> Node2D:
	var slime := _spawn_monster(
		"slime",
		_clamp_manual_spawn_position(spawn_position),
		0.0,
		true
	) as Node2D
	if not is_instance_valid(slime):
		return null
	slime.set_meta("spawn_source", "elite_skill")
	slime.set_meta(
		"elite_arc_landing_position",
		_clamp_manual_spawn_position(landing_position)
	)
	return slime


func _ensure_monster_ground_shadow(
	monster: Node2D,
	monster_type: String
) -> void:
	if not is_instance_valid(monster):
		return
	if monster.get_node_or_null("GroundShadow") != null:
		return

	var config := MONSTER_CATALOG.get_ground_shadow_config(monster_type)
	if not bool(config.get("enabled", true)):
		return

	var collision_radius := 24.0
	var collision := monster.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if is_instance_valid(collision):
		var collision_shape := collision.shape
		if collision_shape is CircleShape2D:
			collision_radius = maxf(
				(collision_shape as CircleShape2D).radius,
				1.0
			)
		elif collision_shape is CapsuleShape2D:
			collision_radius = maxf(
				(collision_shape as CapsuleShape2D).radius,
				1.0
			)
		elif collision_shape is RectangleShape2D:
			collision_radius = maxf(
				(collision_shape as RectangleShape2D).size.x * 0.5,
				1.0
			)

	var default_size := Vector2(
		collision_radius * 2.8,
		collision_radius * 0.9
	)
	var display_size: Vector2 = config.get("size", default_size)
	var offset_y := float(
		config.get("offset_y", collision_radius * 1.2)
	)
	var opacity := clampf(float(config.get("opacity", 0.48)), 0.0, 1.0)

	var shadow := GROUND_SHADOW_SCRIPT.new() as Sprite2D
	if shadow == null:
		return
	shadow.name = "GroundShadow"
	shadow.z_index = -10
	shadow.position = Vector2(0.0, offset_y)
	shadow.set("display_size", display_size)
	shadow.set("opacity", opacity)
	monster.add_child(shadow)


func _hero_survival_multiplier(stat: String,elapsed: float) -> float:
	if online_match_mode: return HERO_SURVIVAL.monster_multiplier(stat,elapsed)
	return HERO_SURVIVAL.monster_multiplier_for_stage(stat,elapsed,int(current_stage_data.get("number",1)),campaign_difficulty)

func _get_demon_level_monster_hp_multiplier(spawn_seconds: float = -1.0) -> float:
	if hero_player_mode:
		return _hero_survival_multiplier("hp",run_metrics.elapsed_seconds if spawn_seconds < 0.0 else spawn_seconds)*(1.25 if campaign_difficulty == "hard" else 1.0)
	var growth_steps := maxi(demon_level - 1, 0)
	return minf(
		pow(DEMON_LEVEL_MONSTER_HP_GROWTH, float(growth_steps)),
		DEMON_LEVEL_MONSTER_HP_MAX_MULTIPLIER
	)

func _get_demon_level_monster_damage_multiplier(spawn_seconds: float = -1.0) -> float:
	if hero_player_mode:
		return _hero_survival_multiplier("damage",run_metrics.elapsed_seconds if spawn_seconds < 0.0 else spawn_seconds)*(1.15 if campaign_difficulty == "hard" else 1.0)
	var growth_steps := maxi(demon_level - 1, 0)
	return minf(
		pow(DEMON_LEVEL_MONSTER_DAMAGE_GROWTH, float(growth_steps)),
		DEMON_LEVEL_MONSTER_DAMAGE_MAX_MULTIPLIER
	)

func _get_demon_level_monster_exp_multiplier() -> float:
	if hero_player_mode: return 1.0
	var growth_steps := maxi(demon_level - 1, 0)
	return minf(
		pow(DEMON_LEVEL_MONSTER_EXP_GROWTH, float(growth_steps)),
		DEMON_LEVEL_MONSTER_EXP_MAX_MULTIPLIER
	)

func _get_demon_level_monster_speed_multiplier(spawn_seconds: float = -1.0) -> float:
	if hero_player_mode:
		return _hero_survival_multiplier("speed",run_metrics.elapsed_seconds if spawn_seconds < 0.0 else spawn_seconds)*(1.05 if campaign_difficulty == "hard" else 1.0)
	var growth_steps := maxi(demon_level - 1, 0)
	return minf(
		pow(DEMON_LEVEL_MONSTER_SPEED_GROWTH, float(growth_steps)),
		DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER
	)

func _apply_demon_level_scaling_to_monster(
	monster: Node,
	preserve_hp_ratio: bool
) -> void:
	if not is_instance_valid(monster) or bool(monster.get_meta("fixed_base_stats", false)):
		return

	var spawn_seconds := float(monster.get_meta("hero_survival_spawn_seconds",-1.0))
	var runtime_additions: Dictionary = monster.call("get_runtime_stat_additions") if monster.has_method("get_runtime_stat_additions") else {}
	var content_id := String(monster.get("monster_type"))
	var excluded := bool(monster.get_meta("exclude_all_augments", false))
	var hp_special := 1.0 if excluded else _get_special_stat_multiplier(content_id, "hp", String(monster.get_meta("visual_variant", "")) == "elite")
	var damage_special := 1.0 if excluded else _get_special_stat_multiplier(content_id, "damage", String(monster.get_meta("visual_variant", "")) == "elite")
	var growth := float(monster.call("get_attack_growth_multiplier")) if monster.has_method("get_attack_growth_multiplier") else 1.0
	var base_hp_value = monster.get_meta("demon_level_base_max_hp", null)
	if base_hp_value != null:
		var old_max_hp := maxi(int(monster.get("max_hp")), 1)
		var current_hp_value = monster.get("current_hp")
		var hp_ratio := 1.0
		if preserve_hp_ratio and current_hp_value != null:
			hp_ratio = clampf(
				float(current_hp_value) / float(old_max_hp),
				0.0,
				1.0
			)

		var new_max_hp := maxi(
			1,
			int(round(
				(float(base_hp_value) * _get_demon_level_monster_hp_multiplier(spawn_seconds) * hp_special
				+ float(runtime_additions.get("hp", 0.0))) * float(runtime_additions.get("hp_multiplier",1.0))
			))
		)
		monster.set("max_hp", new_max_hp)

		if preserve_hp_ratio and current_hp_value != null:
			monster.set(
				"current_hp",
				clampi(
					int(round(float(new_max_hp) * hp_ratio)),
					1,
					new_max_hp
				)
			)

	var base_damage_value = monster.get_meta(
		"demon_level_base_attack_damage",
		null
	) if monster.has_meta("demon_level_base_attack_damage") else null
	if base_damage_value != null:
		var runtime_damage := (float(base_damage_value) * _get_demon_level_monster_damage_multiplier(spawn_seconds) * damage_special * growth
			+ float(runtime_additions.get("damage",0.0))) * float(runtime_additions.get("damage_multiplier",1.0))
		MONSTER_SUPPORT_COMMON.set_unbuffed_attack_damage(monster,maxi(1,int(round(runtime_damage))))

	var base_speed_value = monster.get_meta(
		"demon_level_base_move_speed",
		null
	)
	if base_speed_value != null:
		monster.set(
			"move_speed",
			(float(base_speed_value) * _get_demon_level_monster_speed_multiplier(spawn_seconds)
			+ float(runtime_additions.get("speed", 0.0))) * float(runtime_additions.get("speed_multiplier",1.0))
		)

	if monster.has_method("get_runtime_stat_additions"):
		if not monster.has_meta("runtime_base_attack_cooldown"):
			monster.set_meta("runtime_base_attack_cooldown", float(monster.get("attack_cooldown")))
		var base_interval := maxf(float(monster.get_meta("runtime_base_attack_cooldown")), 0.01)
		monster.set("attack_cooldown", 1.0 / (1.0 / base_interval + maxf(float(runtime_additions.get("attack_rate", 0.0)), 0.0)) / maxf(float(runtime_additions.get("attack_speed_multiplier",1.0)),0.01))

	if preserve_hp_ratio and monster.has_method("queue_redraw"):
		monster.call("queue_redraw")

func refresh_monster_runtime_stats(monster: Node) -> void:
	if not is_instance_valid(monster) or int(monster.get("current_hp")) <= 0: return
	_apply_demon_level_scaling_to_monster(monster,true)

func get_goblin_formation_damage_multiplier(monster: Node2D) -> float:
	return goblin_formation_runtime.incoming_multiplier(monster)

func _get_active_monsters_snapshot() -> Array:
	var result: Array = []
	var stale_ids: Array = []
	for raw_id in active_monsters:
		var node = active_monsters.get(raw_id)
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			stale_ids.append(raw_id)
			continue
		result.append(node)
	for raw_id in stale_ids:
		_unregister_monster(raw_id)
	return result


func _refresh_alive_monsters_for_demon_level() -> void:
	for node in _get_active_monsters_snapshot():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var current_hp_value = node.get("current_hp")
		if current_hp_value != null and int(current_hp_value) <= 0:
			continue

		_apply_demon_level_scaling_to_monster(node, true)

func _get_catalog_monster_display_name(monster_id: String) -> String:
	var data = MONSTER_CATALOG.MONSTERS.get(monster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return monster_id
	return String(data.get("name", monster_id))

func _get_monster_name(monster_type: String) -> String:
	return _get_catalog_monster_display_name(monster_type)

func _on_hero_health_changed(current_hp: int, max_hp_value: int) -> void:
	run_metrics.record_hero_hp(current_hp, max_hp_value)
	stats_changed.emit(current_hp, max_hp_value, monsters_alive)

func _on_hero_combat_damage_received(hp_damage: int) -> void:
	if hp_damage <= 0:
		return
	run_metrics.record_hero_damage(hp_damage)
	if transcendence.record_damage(hp_damage):
		transcendence_changed.emit(transcendence.monster_id,true,false)
	_add_demon_ultimate_charge(float(hp_damage) * DEMON_ULTIMATES.HERO_DAMAGE_CHARGE_MULTIPLIER)

func _on_hero_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	progression_changed.emit(level, current_exp, exp_to_next_level)

func _on_hero_leveled_up(new_level: int) -> void:
	hero_leveled_up.emit(new_level)

func _on_hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String) -> void:
	run_metrics.record_hero_augment(level, chosen_name, reason)
	hero_augment_selected.emit(level, candidates, chosen_name, reason, build_summary)


func register_ghost_projectile_hit() -> void:
	ghost_shared_hit_count += 1
	if ghost_shared_hit_count < 10:
		return

	ghost_shared_hit_count -= 10
	if (
		is_instance_valid(hero)
		and hero.has_method("add_random_skill_cooldown_delay")
	):
		hero.call("add_random_skill_cooldown_delay", 0.5)

	var slow_config: Dictionary = _get_special_augment_config("ghost").get(
		"ghost_stack_slow",
		{}
	)
	if (
		not slow_config.is_empty()
		and is_instance_valid(hero)
		and hero.has_method("apply_slow")
	):
		hero.call(
			"apply_slow",
			clampf(
				float(slow_config.get("slow_multiplier", 0.70)),
				0.01,
				1.0
			),
			maxf(float(slow_config.get("duration", 2.0)), 0.05)
		)


func _apply_ghost_death_empower(dead_monster: Node, profile: Dictionary) -> void:
	var rule: Dictionary = profile.get("ally_empower", MONSTER_CATALOG.EMPTY_DEATH_REACTIONS)
	if rule.is_empty():
		return
	var config: Dictionary = _get_special_augment_config(rule["owner_id"]).get(
		rule["augment_id"], MONSTER_CATALOG.EMPTY_DEATH_REACTIONS
	)
	if config.is_empty():
		return

	ghost_death_buff_candidates.clear()
	for raw_id in active_monsters:
		var candidate = active_monsters.get(raw_id)
		if (
			not is_instance_valid(candidate)
			or candidate == dead_monster
			or candidate.is_queued_for_deletion()
		):
			continue
		var hp_value = candidate.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		ghost_death_buff_candidates.append(candidate)

	if ghost_death_buff_candidates.is_empty():
		return

	var target = ghost_death_buff_candidates[
		randi() % ghost_death_buff_candidates.size()
	]
	ghost_death_buff_candidates.clear()
	if not is_instance_valid(target):
		return

	var multiplier := maxf(
		float(config.get(rule["multiplier_key"], rule["default_multiplier"])),
		float(rule["minimum_multiplier"])
	)
	for stat_rule in rule["raw_stats"]:
		var metadata: StringName = stat_rule["metadata"]
		var raw_value = target.get_meta(metadata, null)
		if raw_value == null:
			continue
		var value := float(raw_value)
		if bool(stat_rule.get("inverse", false)):
			value /= multiplier
		else:
			value *= multiplier
		target.set_meta(metadata, maxf(value, float(stat_rule["minimum"])))

	var stack_metadata: StringName = rule["stack_metadata"]
	target.set_meta(stack_metadata, int(target.get_meta(stack_metadata, 0)) + 1)
	_apply_normal_augments_to_existing_monster(
		target,
		String(target.get("monster_type"))
	)

func _on_enemy_status_applied(_status: String) -> void:
	if battle_over:
		return
	raw_statuses_applied += 1
	if transcendence.record_status():
		transcendence_changed.emit(transcendence.monster_id,true,false)

func get_transcendent_aura_modifier(actor: Node2D, kind: String) -> float:
	var burn := preload("res://src/data/status_effect_catalog.gd").outgoing_multiplier(actor) if kind == "outgoing" else 1.0
	if kind=="outgoing" and is_instance_valid(actor) and bool(actor.get_meta("arthur_gate_active",false)): burn *= preload("res://src/data/arthur_behavior_catalog.gd").GATE_ATTACK
	if is_instance_valid(transcendent_actor) and transcendent_actor.has_method("aura_modifier"):
		return burn * float(transcendent_actor.aura_modifier(actor,kind))
	return burn

func _transcendence_growth_count(id: String) -> int:
	return _transcendence_metric_count(String(MONSTER_CATALOG.MONSTERS.get(id, {}).get("growth_metric", "summons")))

func _transcendence_metric_count(metric: String) -> int:
	match metric:
		"damage_dealt": return int(run_metrics.total_damage_dealt)
		"statuses_applied": return raw_statuses_applied
		"allies_died": return raw_allied_deaths
		"tanks_died": return raw_tank_deaths
		"real_tanks_summoned": return raw_real_tank_summons
	return raw_allied_summons

func _on_monster_hit_hero(source: Node) -> void:
	if not is_instance_valid(source): return
	var value: Variant = source.get("monster_type")
	if value == null:
		var reference: Variant = source.get_meta("combat_source", null)
		if reference is WeakRef: source = reference.get_ref()
		if not is_instance_valid(source): return
		value = source.get("monster_type")
	if value == null: return
	var id := String(value)
	if id.is_empty(): return
	_play_monster_sfx(MONSTER_SFX.cue_for(id, "attack", MONSTER_CATALOG.get_attack_type(id)))

func _play_monster_sfx(cue: String) -> void:
	if cue.is_empty(): return
	if online_match_mode: online_monster_sfx.emit(cue)
	else: GameAudio.play_battle(cue, self)

func _on_monster_died(monster: Node) -> void:
	if not battle_over and is_instance_valid(monster):
		var cue := MONSTER_SFX.cue_for(String(monster.get("monster_type")), "death", "")
		if not cue.is_empty() and (String(monster.get_meta("stage_event_type", "")) in ["elite", "giant"] or String(monster.get_meta("visual_variant", "")) == "elite"): cue += ":elite"
		_play_monster_sfx(cue)
	if hero_player_mode and is_instance_valid(monster) and bool(monster.get_meta("hero_final_boss",false)):
		_finish_hero_boss_victory.call_deferred()
	if hero_player_mode and not battle_over and is_instance_valid(monster) and String(monster.get_meta("stage_event_type","")) in ["elite","giant"]:
		hero_elite_kills_toward_chest = mini(hero_elite_kills_toward_chest+1,HERO_SURVIVAL.CHEST_ELITE_KILLS)
		if _hero_chest_eligible("elite"): _spawn_chest_for_session.call_deferred(battle_command_router.get_session_id(),"elite")
	if battle_over:
		return
	if is_instance_valid(monster) and TRANSCENDENCE_DATA.is_transcendent(String(monster.get("monster_type"))):
		if bool(monster.get_meta("transcendent_death_handled", false)):
			return
		monster.set_meta("transcendent_death_handled", true)
	if is_instance_valid(monster) and not bool(monster.get_meta("allied_death_recorded", false)):
		monster.set_meta("allied_death_recorded", true)
		anubis_army_runtime.retire(monster.get_instance_id(),true)
		raw_allied_deaths += 1
		if MONSTER_CATALOG.get_role(String(monster.get("monster_type"))) == "tank":
			raw_tank_deaths += 1
		if transcendence.record_ally_death():
			transcendence_changed.emit(transcendence.monster_id, true, false)
		if is_instance_valid(transcendent_actor) and monster != transcendent_actor:
			transcendent_actor.on_ally_death((monster as Node2D).global_position)

	var drop_position := Vector2.ZERO
	var monster_type := MONSTER_CATALOG.DEFAULT_DEATH_MONSTER_ID
	var is_split_child := false
	var allow_special_death_split := false
	var death_type := "normal"
	var reward := 0
	var transcendent_drop: Dictionary = {}
	var instance_id := 0

	if is_instance_valid(monster):
		var monster_node := monster as Node2D
		if monster_node != null:
			drop_position = monster_node.global_position

		instance_id = monster.get_instance_id()
		monster_type = String(monster.get("monster_type"))
		transcendent_drop = TRANSCENDENCE_DATA.get_death_drop(monster_type)
		is_split_child = bool(monster.get_meta("split_child", false))
		allow_special_death_split = bool(
			monster.get_meta("allow_special_death_split", false)
		)
		death_type = String(monster.get_meta("death_type", "normal"))
		reward = maxi(
			int(round(
				float(transcendent_drop.get("total_exp", monster.get("exp_reward")))
				* _get_demon_level_monster_exp_multiplier()
			)),
			0
		)

	# Ally consumption is a death, but never a hero kill or an EXP reward.
	var rewardless_death := death_type == "consumed"
	if rewardless_death:
		reward = 0

	var death_profile := MONSTER_CATALOG.get_death_reaction_profile(monster_type)
	_apply_pre_reward_death_reactions(monster, monster_type, drop_position, death_profile)

	if reward > 0:
		if transcendent_drop.is_empty():
			_spawn_exp_orb(drop_position, reward)
		else:
			_spawn_transcendent_exp_drop(drop_position, reward, transcendent_drop)

	# Passive resources are driven from the authoritative monster-death registry
	# instead of polling monster groups from Hero every frame.
	if (
		death_type != "self_destruct" and not rewardless_death
		and is_instance_valid(hero)
		and hero.has_method("notify_monster_kill")
	):
		hero.call("notify_monster_kill", monster_type)

	if not rewardless_death:
		run_metrics.record_monster_death(monster_type)

	if death_type != "self_destruct" and not rewardless_death:
		if online_match_mode: online_hero_kill.emit()
		hero_kills_toward_heal_item = mini(
			hero_kills_toward_heal_item + 1,
			HEAL_ITEM_KILLS_REQUIRED
		)
		_try_spawn_heal_item_from_kills()
		hero_kills_toward_chest = mini(
			hero_kills_toward_chest + 1,
			_chest_kill_requirement()
		)
		_try_spawn_chest_from_kills()
		hero_kills_toward_magnet = mini(
			hero_kills_toward_magnet + 1,
			MAGNET_KILLS_REQUIRED
		)
		_try_spawn_magnet_from_kills()

	var original_cost: float = float(monster_summon_costs.get(instance_id, 0.0))
	monster_summon_costs.erase(instance_id)
	_unregister_monster(instance_id)
	active_elite_skeletons.erase(instance_id)
	monster_spatial_grid_physics_frame = -1

	if death_refund_ratio > 0.0 and original_cost > 0.0:
		command_power = minf(
			command_power + original_cost * death_refund_ratio,
			max_command
		)
		command_changed.emit(command_power, max_command)

	_try_spawn_legacy_death_child(monster_type, drop_position, is_split_child, death_profile)

	_process_special_death_spawn(
		monster_type,
		drop_position,
		is_split_child,
		allow_special_death_split,
		death_type
	)

	# Visual-only cue after authoritative death rewards/registry cleanup.
	if is_instance_valid(monster) and TRANSCENDENCE_DATA.is_transcendent(monster_type):
		transcendent_died.emit(monster_type, monster as Node2D)

	monsters_alive = maxi(monsters_alive - 1, 0)
	_emit_stats()

func _apply_pre_reward_death_reactions(
	monster: Node, monster_type: String, drop_position: Vector2, profile: Dictionary
) -> void:
	if not is_instance_valid(monster):
		return
	var rule: Dictionary = profile.get("counter_elite", MONSTER_CATALOG.EMPTY_DEATH_REACTIONS)
	if not rule.is_empty() and not bool(monster.get_meta("exclude_all_augments", false)):
		var config: Dictionary = _get_special_augment_config(monster_type).get(
			rule["augment_id"], MONSTER_CATALOG.EMPTY_DEATH_REACTIONS
		)
		if not config.is_empty():
			var counter: StringName = rule["counter_property"]
			var count := int(get(counter)) + 1
			set(counter, count)
			if count >= int(config.get(rule["threshold_key"], rule["threshold_default"])):
				set(counter, 0)
				var elite = _spawn_monster(monster_type, drop_position, 0.0, false, rule["spawn_modifiers"].duplicate())
				if is_instance_valid(elite):
					_apply_special_monster_modifiers(elite, monster_type, rule["elite_modifiers"].duplicate())
	var callback: StringName = profile.get("pre_reward_method", &"")
	if not callback.is_empty() and is_instance_valid(monster):
		call(callback, monster, profile)


func _try_spawn_legacy_death_child(
	monster_type: String, drop_position: Vector2, is_split_child: bool, profile: Dictionary
) -> void:
	var rule: Dictionary = profile.get("legacy_split", MONSTER_CATALOG.EMPTY_DEATH_REACTIONS)
	if rule.is_empty() or is_split_child:
		return
	var chance := float(get(rule["chance_property"]))
	if chance > 0.0 and randf() <= chance:
		var offset := Vector2.from_angle(randf_range(0.0, TAU)) * float(rule["radius"])
		_spawn_monster(monster_type, _clamp_manual_spawn_position(drop_position + offset), 0.0, true)


func _process_special_death_spawn(
	monster_type: String,
	drop_position: Vector2,
	is_split_child: bool,
	allow_special_death_split: bool,
	death_type: String
) -> void:
	if is_split_child and not allow_special_death_split:
		return
	var rule := MONSTER_CATALOG.get_secondary_spawn_rule(monster_type, &"on_death")
	if death_type in rule.get("excluded_death_types", MONSTER_CATALOG.EMPTY_SECONDARY_SPAWN_LIST):
		return
	_spawn_secondary_monsters(monster_type, drop_position, rule)

func _chest_kill_requirement() -> int:
	return HERO_SURVIVAL.CHEST_KILLS if hero_player_mode else CHEST_KILLS_REQUIRED

func _hero_chest_eligible(source: String) -> bool:
	if online_match_mode:
		return preload("res://src/data/ranked_pickup_catalog.gd").chest_eligible(source,hero_chests_spawned,hero_kills_toward_chest,hero_elite_kills_toward_chest)
	if source != "kills" and source != "elite": return false
	if hero_chests_spawned == 0: return source == "elite"
	return hero_elite_kills_toward_chest >= HERO_SURVIVAL.CHEST_ELITE_KILLS if source == "elite" else hero_kills_toward_chest >= HERO_SURVIVAL.CHEST_KILLS

func _try_spawn_chest_from_kills() -> void:
	if hero_player_mode and not _hero_chest_eligible("kills"): return
	if hero_kills_toward_chest < _chest_kill_requirement():
		return
	if _active_registry_size(active_treasure_chests) >= MAX_ACTIVE_CHESTS:
		return

	if not hero_player_mode: hero_kills_toward_chest = 0
	_spawn_chest_for_session.call_deferred(battle_command_router.get_session_id())

func _spawn_chest_for_session(session: int, source: String = "kills") -> void:
	if battle_over or session != battle_command_router.get_session_id(): return
	if hero_player_mode and not _hero_chest_eligible(source): return
	if not _spawn_random_treasure_chest(): return
	if hero_player_mode:
		hero_chests_spawned += 1
		if source == "elite": hero_elite_kills_toward_chest = 0
		else: hero_kills_toward_chest = 0

func _spawn_random_treasure_chest() -> bool:
	if _active_registry_size(active_treasure_chests) >= MAX_ACTIVE_CHESTS:
		return false
	var margin := 180.0
	var spawn_position := Vector2(
		randf_range(margin, maxf(current_map_size.x - margin, margin)),
		randf_range(margin, maxf(current_map_size.y - margin, margin))
	)
	if hero_player_mode and is_instance_valid(hero):
		spawn_position = _clamp_manual_spawn_position(hero.global_position+Vector2.from_angle(randf()*TAU)*260.0)
	var chest := TREASURE_CHEST_SCENE.instantiate() as Node2D
	if chest == null: return false
	add_child(chest)
	chest.position = PICKUP_PLACEMENT.clamp_local(self,to_local(spawn_position))
	_register_treasure_chest(chest)
	if chest.has_signal("destroyed"):
		chest.connect(
			"destroyed",
			Callable(self, "_on_treasure_chest_destroyed").bind(chest)
		)
	return true


func _on_treasure_chest_destroyed(
	drop_position: Vector2,
	chest: Node = null
) -> void:
	GameAudio.play_battle("chest", self)
	if is_instance_valid(chest):
		active_treasure_chests.erase(chest.get_instance_id())

	if hero_player_mode:
		hero_chest_opened.emit()
		return

	var bundle_count := randi_range(CHEST_EXP_BUNDLE_MIN, CHEST_EXP_BUNDLE_MAX)
	for index in range(bundle_count):
		var angle := TAU * float(index) / float(maxi(bundle_count, 1))
		angle += randf_range(-0.22, 0.22)
		var direction := Vector2.from_angle(angle)
		var orb_position := _clamp_manual_spawn_position(
			drop_position + direction * randf_range(8.0, 20.0)
		)
		_spawn_exp_orb(
			orb_position,
			randi_range(CHEST_EXP_VALUE_MIN, CHEST_EXP_VALUE_MAX),
			direction * randf_range(220.0, 420.0)
		)


func _try_spawn_magnet_from_kills() -> void:
	if hero_kills_toward_magnet < MAGNET_KILLS_REQUIRED:
		return
	if (
		_active_registry_size(active_magnet_items)
		>= MAX_ACTIVE_MAGNET_ITEMS
	):
		# Keep the 70-kill trigger armed until a field slot opens.
		return

	hero_kills_toward_magnet = 0
	_spawn_random_magnet_item()


func _spawn_random_magnet_item() -> void:
	if (
		_active_registry_size(active_magnet_items)
		>= MAX_ACTIVE_MAGNET_ITEMS
	):
		return

	var margin := 150.0
	var min_x := margin
	var max_x := maxf(current_map_size.x - margin, min_x)
	var min_y := margin
	var max_y := maxf(current_map_size.y - margin, min_y)
	var item := MAGNET_ITEM_SCENE.instantiate() as Node2D
	add_child(item)
	item.global_position = Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)
	PICKUP_PLACEMENT.ensure_reachable(item)
	_register_magnet_item(item)


func activate_exp_magnet(duration: float = EXP_MAGNET_DURATION) -> void:
	if not is_instance_valid(hero):
		return

	var now_msec := Time.get_ticks_msec()
	var duration_msec := int(maxf(duration, 0.0) * 1000.0)
	exp_magnet_until_msec = maxi(
		exp_magnet_until_msec,
		now_msec + duration_msec
	)
	var remaining := maxf(
		float(exp_magnet_until_msec - now_msec) / 1000.0,
		0.0
	)
	for node in get_tree().get_nodes_in_group("exp_orbs"):
		if online_match_mode and is_instance_valid(node) and node.get_viewport() != get_viewport(): continue
		if (
			not is_instance_valid(node)
			or node.is_queued_for_deletion()
			or not node.has_method("activate_global_magnet")
		):
			continue
		node.call(
			"activate_global_magnet",
			hero,
			remaining
		)


func _remaining_exp_magnet_seconds() -> float:
	return maxf(
		float(exp_magnet_until_msec - Time.get_ticks_msec())
		/ 1000.0,
		0.0
	)


func _try_spawn_heal_item_from_kills() -> void:
	if hero_kills_toward_heal_item < HEAL_ITEM_KILLS_REQUIRED:
		return
	if _active_registry_size(active_heal_items) >= MAX_ACTIVE_HEAL_ITEMS:
		# Keep the trigger armed instead of consuming kills while the field is full.
		return

	hero_kills_toward_heal_item = 0
	_spawn_random_heal_item()


func _spawn_random_heal_item() -> void:
	if not is_instance_valid(hero):
		return
	if _active_registry_size(active_heal_items) >= MAX_ACTIVE_HEAL_ITEMS:
		return

	var margin := 150.0
	var min_x := margin
	var max_x := maxf(current_map_size.x - margin, min_x)
	var min_y := margin
	var max_y := maxf(current_map_size.y - margin, min_y)
	var spawn_position := Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)

	var item := HEAL_ITEM_SCENE.instantiate() as Node2D
	add_child(item)
	item.position = PICKUP_PLACEMENT.clamp_local(self,to_local(spawn_position))
	_register_heal_item(item)

func _warm_transcendent_exp_drop() -> void:
	var drop := TRANSCENDENCE_DATA.get_death_drop(transcendence.monster_id)
	if drop.is_empty():
		return
	var count := clampi(int(drop.pieces), 1, MAX_EXP_ORB_POOL)
	var value := maxi(int(drop.total_exp) / count, 1)
	while exp_orb_pool.size() < count and is_inside_tree() and not battle_over:
		var orb := EXP_ORB_SCENE.instantiate() as Node2D
		add_child(orb)
		orb.call("setup", value)
		recycle_exp_orb(orb)
		if exp_orb_pool.size() % 4 == 0:
			await get_tree().process_frame

func _spawn_transcendent_exp_drop(drop_position: Vector2, total_exp: int, drop: Dictionary) -> void:
	if total_exp <= 0:
		return
	var count := mini(clampi(int(drop.pieces), 1, MAX_EXP_ORB_POOL), total_exp)
	var portion := total_exp / count
	var remainder := total_exp % count
	for index in range(count):
		var angle := TAU * float(index) / count + randf_range(-0.15, 0.15)
		var direction := Vector2.from_angle(angle)
		var point := _clamp_manual_spawn_position(drop_position + direction * randf_range(8.0, 20.0))
		_spawn_exp_orb(point, portion + (1 if index < remainder else 0),
			direction * randf_range(float(drop.speed_min), float(drop.speed_max)), float(drop.pickup_delay))

func _spawn_exp_orb(
	drop_position: Vector2,
	exp_value: int,
	initial_velocity: Vector2 = Vector2.ZERO,
	pickup_delay: float = 0.0
) -> void:
	if exp_value <= 0:
		return

	var orb: Node2D = null
	while not exp_orb_pool.is_empty() and orb == null:
		var pooled = exp_orb_pool.pop_back()
		if is_instance_valid(pooled) and not pooled.is_queued_for_deletion():
			orb = pooled as Node2D

	if orb == null:
		orb = EXP_ORB_SCENE.instantiate() as Node2D
		add_child(orb)

	orb.position = PICKUP_PLACEMENT.clamp_local(self,to_local(drop_position))
	orb.call("setup", exp_value, initial_velocity, pickup_delay)
	var magnet_remaining := _remaining_exp_magnet_seconds()
	if (
		magnet_remaining > 0.0
		and orb.has_method("activate_global_magnet")
		and is_instance_valid(hero)
	):
		orb.call(
			"activate_global_magnet",
			hero,
			magnet_remaining
		)


func acquire_transient_fx(pool_key: String, fx_type: String) -> Node:
	if pool_key.is_empty():
		return null

	var pool = transient_fx_pools.get(pool_key, [])
	if typeof(pool) != TYPE_ARRAY:
		pool = []

	var fx: Node = null
	while not pool.is_empty() and fx == null:
		var pooled = pool.pop_back()
		if is_instance_valid(pooled) and not pooled.is_queued_for_deletion():
			fx = pooled
	transient_fx_pools[pool_key] = pool

	if fx == null:
		match fx_type:
			"animated_sprite":
				fx = AnimatedSprite2D.new()
			"sprite":
				fx = Sprite2D.new()
			"line":
				fx = Line2D.new()
			"node2d":
				fx = Node2D.new()
			_:
				return null
		add_child(fx)

	if online_match_mode:
		_activate_battle_entity(fx)
		online_visual_projectiles[fx.get_instance_id()] = fx
	if fx is CanvasItem:
		(fx as CanvasItem).visible = true
	fx.process_mode = Node.PROCESS_MODE_INHERIT
	return fx


func recycle_transient_fx(fx: Node, pool_key: String) -> void:
	if (
		not is_instance_valid(fx)
		or fx.is_queued_for_deletion()
		or pool_key.is_empty()
	):
		return

	if online_match_mode:
		online_visual_projectiles.erase(fx.get_instance_id())
		battle_entity_registry.retire_instance(fx.get_instance_id())
	if fx.has_method("deactivate_for_pool"):
		fx.call("deactivate_for_pool")
	else:
		if fx is CanvasItem:
			(fx as CanvasItem).visible = false
		fx.set_process(false)
		fx.set_physics_process(false)
		if fx is AnimatedSprite2D:
			(fx as AnimatedSprite2D).stop()
		elif fx is Sprite2D:
			var sprite := fx as Sprite2D
			sprite.texture = null
			sprite.centered = true
			sprite.flip_h = false
			sprite.flip_v = false
			sprite.offset = Vector2.ZERO
			sprite.modulate = Color.WHITE
			sprite.scale = Vector2.ONE
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
		elif fx is Line2D:
			var line := fx as Line2D
			line.clear_points()
			line.modulate = Color.WHITE
			line.scale = Vector2.ONE
			line.position = Vector2.ZERO

	var pool = transient_fx_pools.get(pool_key, [])
	if typeof(pool) != TYPE_ARRAY:
		pool = []

	if pool.size() >= MAX_TRANSIENT_FX_POOL_PER_TYPE:
		fx.queue_free()
		return

	pool.append(fx)
	transient_fx_pools[pool_key] = pool


func acquire_projectile(scene: PackedScene, pool_key: String) -> Node:
	if scene == null or pool_key.is_empty():
		return null

	var pool = projectile_pools.get(pool_key, [])
	if typeof(pool) != TYPE_ARRAY:
		pool = []

	var projectile: Node = null
	while not pool.is_empty() and projectile == null:
		var pooled = pool.pop_back()
		if is_instance_valid(pooled) and not pooled.is_queued_for_deletion():
			projectile = pooled
	projectile_pools[pool_key] = pool

	if projectile == null:
		projectile = scene.instantiate()
		add_child(projectile)

	_activate_battle_entity(projectile)
	if online_match_mode: online_visual_projectiles[projectile.get_instance_id()] = projectile
	return projectile


func recycle_projectile(projectile: Node, pool_key: String) -> void:
	if (
		not is_instance_valid(projectile)
		or projectile.is_queued_for_deletion()
		or pool_key.is_empty()
	):
		return

	# Invalidate the old life before deactivation callbacks can schedule work.
	online_visual_projectiles.erase(projectile.get_instance_id())
	battle_entity_registry.retire_instance(projectile.get_instance_id())
	if projectile.has_method("deactivate_for_pool"):
		projectile.call("deactivate_for_pool")

	var pool = projectile_pools.get(pool_key, [])
	if typeof(pool) != TYPE_ARRAY:
		pool = []

	if pool.size() >= MAX_PROJECTILE_POOL_PER_TYPE:
		projectile.queue_free()
		return

	pool.append(projectile)
	projectile_pools[pool_key] = pool


func recycle_exp_orb(orb: Node) -> void:
	if not is_instance_valid(orb) or orb.is_queued_for_deletion():
		return

	if orb.has_method("deactivate_for_pool"):
		orb.call("deactivate_for_pool")

	if exp_orb_pool.size() >= MAX_EXP_ORB_POOL:
		orb.queue_free()
		return

	exp_orb_pool.append(orb as Node2D)

func _emit_demon_ultimate_changed() -> void:
	var charge_max := maxf(DEMON_ULTIMATES.CHARGE_MAX, 1.0)
	demon_ultimate_changed.emit(
		demon_ultimate_charge,
		charge_max,
		demon_ultimate_charge + 0.001 >= demon_ultimate_cheapest_cost
	)

func _emit_demon_ultimate_cooldowns() -> void:
	demon_ultimate_cooldowns_changed.emit(
		demon_ultimate_cooldowns.duplicate(true)
	)

func _update_demon_ultimate_cooldowns(delta: float) -> void:
	var changed := false
	var reached_ready := false
	for skill_id in demon_ultimate_skill_ids:
		var previous_remaining := maxf(
			float(demon_ultimate_cooldowns.get(skill_id, 0.0)),
			0.0
		)
		var remaining := maxf(
			previous_remaining - delta,
			0.0
		)
		if absf(remaining - previous_remaining) > 0.0001:
			demon_ultimate_cooldowns[skill_id] = remaining
			changed = true
			if previous_remaining > 0.001 and remaining <= 0.001:
				reached_ready = true

	if not changed:
		return

	demon_ultimate_cooldown_emit_timer -= delta
	if reached_ready:
		demon_ultimate_cooldown_emit_timer = 0.10
		_emit_demon_ultimate_cooldowns()
	elif demon_ultimate_cooldown_emit_timer <= 0.0:
		demon_ultimate_cooldown_emit_timer = 0.10
		_emit_demon_ultimate_cooldowns()

func _add_demon_ultimate_charge(amount: float) -> void:
	if amount <= 0.0 or battle_over:
		return

	demon_ultimate_charge = minf(
		demon_ultimate_charge + amount,
		DEMON_ULTIMATES.CHARGE_MAX
	)
	_emit_demon_ultimate_changed()

func _execute_demon_ultimate(
	skill_id: String,
	direction: String = ""
) -> bool:
	if battle_over or external_pause or (demon_augment_selection_active and not online_match_mode):
		return false
	if skill_id not in demon_ultimate_skill_ids:
		return false
	if float(demon_ultimate_cooldowns.get(skill_id, 0.0)) > 0.001:
		return false

	var skill := DEMON_ULTIMATES.get_skill(skill_id)
	if skill.is_empty() or not bool(skill.get("implemented", false)):
		return false
	var mana_cost := maxf(float(skill.get("mana_cost", DEMON_ULTIMATES.CHARGE_MAX)), 0.0)
	if demon_ultimate_charge + 0.001 < mana_cost:
		return false

	var used := false
	match skill_id:
		"encirclement":
			used = _use_demon_encirclement(skill)
		"line_assault":
			used = _use_demon_line_assault(skill, direction)
		"square_siege":
			used = _use_demon_square_siege(skill)

	if not used:
		return false

	demon_ultimate_charge = maxf(demon_ultimate_charge - mana_cost, 0.0)
	_record_mission_action("mana", mana_cost)
	if transcendence.record_mana(mana_cost):
		transcendence_changed.emit(transcendence.monster_id, true, false)
	demon_ultimate_cooldowns[skill_id] = maxf(
		float(skill.get("cooldown", 0.0)),
		0.0
	)
	_emit_demon_ultimate_changed()
	_emit_demon_ultimate_cooldowns()

	var skill_name := String(skill.get("name", "마력 기술"))
	var use_message := "%s 발동! 용사 외곽에 군단을 전개했습니다." % skill_name
	if skill_id == "line_assault":
		use_message = "%s 발동! 선택한 방향에서 전선을 형성했습니다." % skill_name
	elif skill_id == "square_siege":
		use_message = "%s 발동! 용사 외곽을 사각 전선으로 봉쇄했습니다." % skill_name
	demon_ultimate_used.emit(
		skill_id,
		skill_name,
		use_message
	)
	return true

func _demon_skill_pool(skill: Dictionary) -> Array[String]:
	var pool: Array[String] = []
	var limit := float(skill.get("max_monster_cost", INF))
	var source: Array = allowed_monster_ids if not allowed_monster_ids.is_empty() else MONSTER_CATALOG.ORDER
	for raw_id in source:
		var id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(id) and MONSTER_CATALOG.get_base_cost(id) <= limit:
			pool.append(id)
			if allowed_monster_ids.is_empty() and pool.size() >= 3:
				break
	return pool

func _use_demon_encirclement(skill: Dictionary) -> bool:
	if not is_instance_valid(hero):
		return false
	if not demon_ultimate_spawn_queue.is_empty():
		return false

	var pool := _demon_skill_pool(skill)
	if pool.is_empty():
		summon_result.emit("", false, "%s코스트 이하 몬스터가 편성되어 있어야 합니다." % DEMON_ULTIMATES.format_cost(float(skill.get("max_monster_cost", 0.0))))
		return false

	var spawn_count := maxi(int(skill.get("spawn_count", 12)), 1)
	var spawn_radius := maxf(float(skill.get("spawn_radius", 700.0)), 1.0)
	demon_ultimate_spawn_batch_size = maxi(
		int(skill.get("spawn_batch_size", 2)),
		1
	)
	demon_ultimate_spawn_interval = maxf(
		float(skill.get("spawn_interval", 0.04)),
		0.01
	)
	demon_ultimate_spawn_timer = 0.0

	var angle_offset := randf_range(0.0, TAU)
	var hero_position := hero.position

	for index in range(spawn_count):
		var angle := angle_offset + TAU * float(index) / float(spawn_count)
		var candidate := hero_position + Vector2.from_angle(angle) * spawn_radius
		var spawn_position := Vector2(
			clampf(
				candidate.x,
				MANUAL_SPAWN_MARGIN,
				current_map_size.x - MANUAL_SPAWN_MARGIN
			),
			clampf(
				candidate.y,
				MANUAL_SPAWN_MARGIN,
				current_map_size.y - MANUAL_SPAWN_MARGIN
			)
		)
		demon_ultimate_spawn_queue.append({
			"monster_id": pool[index % pool.size()],
			"position": spawn_position,
		})

	return true

func _use_demon_line_assault(
	skill: Dictionary,
	direction: String
) -> bool:
	if not is_instance_valid(hero):
		return false
	if not demon_ultimate_spawn_queue.is_empty():
		return false
	if direction not in ["east", "west", "north", "south"]:
		return false

	var pool := _demon_skill_pool(skill)
	if pool.is_empty():
		summon_result.emit("", false, "%s코스트 이하 몬스터가 편성되어 있어야 합니다." % DEMON_ULTIMATES.format_cost(float(skill.get("max_monster_cost", 0.0))))
		return false

	var spawn_count := maxi(int(skill.get("spawn_count", 10)), 1)
	var spawn_distance := maxf(
		float(skill.get("spawn_distance", 700.0)),
		1.0
	)
	var line_span := maxf(float(skill.get("line_span", 720.0)), 0.0)

	demon_ultimate_spawn_batch_size = maxi(
		int(skill.get("spawn_batch_size", 2)),
		1
	)
	demon_ultimate_spawn_interval = maxf(
		float(skill.get("spawn_interval", 0.04)),
		0.01
	)
	demon_ultimate_spawn_timer = 0.0

	var hero_position := hero.position
	for index in range(spawn_count):
		var t := 0.5
		if spawn_count > 1:
			t = float(index) / float(spawn_count - 1)
		var line_offset := lerpf(-line_span * 0.5, line_span * 0.5, t)
		var candidate := hero_position

		match direction:
			"east":
				candidate = hero_position + Vector2(spawn_distance, line_offset)
			"west":
				candidate = hero_position + Vector2(-spawn_distance, line_offset)
			"north":
				candidate = hero_position + Vector2(line_offset, -spawn_distance)
			"south":
				candidate = hero_position + Vector2(line_offset, spawn_distance)

		var spawn_position := Vector2(
			clampf(
				candidate.x,
				MANUAL_SPAWN_MARGIN,
				current_map_size.x - MANUAL_SPAWN_MARGIN
			),
			clampf(
				candidate.y,
				MANUAL_SPAWN_MARGIN,
				current_map_size.y - MANUAL_SPAWN_MARGIN
			)
		)
		demon_ultimate_spawn_queue.append({
			"monster_id": pool[index % pool.size()],
			"position": spawn_position,
		})

	return true

func _use_demon_square_siege(skill: Dictionary) -> bool:
	if not is_instance_valid(hero):
		return false
	if not demon_ultimate_spawn_queue.is_empty():
		return false

	var pool := _demon_skill_pool(skill)
	if pool.is_empty():
		summon_result.emit("", false, "%s코스트 이하 몬스터가 편성되어 있어야 합니다." % DEMON_ULTIMATES.format_cost(float(skill.get("max_monster_cost", 0.0))))
		return false

	var spawn_count := maxi(int(skill.get("spawn_count", 16)), 4)
	var half_extent := maxf(float(skill.get("half_extent", 700.0)), 1.0)

	demon_ultimate_spawn_batch_size = maxi(
		int(skill.get("spawn_batch_size", 2)),
		1
	)
	demon_ultimate_spawn_interval = maxf(
		float(skill.get("spawn_interval", 0.04)),
		0.01
	)
	demon_ultimate_spawn_timer = 0.0

	var hero_position := hero.position
	var perimeter_length := half_extent * 8.0

	for index in range(spawn_count):
		var distance_on_perimeter := (
			perimeter_length
			* float(index)
			/ float(spawn_count)
		)
		var candidate := hero_position

		if distance_on_perimeter < half_extent * 2.0:
			candidate = hero_position + Vector2(
				-half_extent + distance_on_perimeter,
				-half_extent
			)
		elif distance_on_perimeter < half_extent * 4.0:
			var side_offset := distance_on_perimeter - half_extent * 2.0
			candidate = hero_position + Vector2(
				half_extent,
				-half_extent + side_offset
			)
		elif distance_on_perimeter < half_extent * 6.0:
			var side_offset := distance_on_perimeter - half_extent * 4.0
			candidate = hero_position + Vector2(
				half_extent - side_offset,
				half_extent
			)
		else:
			var side_offset := distance_on_perimeter - half_extent * 6.0
			candidate = hero_position + Vector2(
				-half_extent,
				half_extent - side_offset
			)

		var spawn_position := Vector2(
			clampf(
				candidate.x,
				MANUAL_SPAWN_MARGIN,
				current_map_size.x - MANUAL_SPAWN_MARGIN
			),
			clampf(
				candidate.y,
				MANUAL_SPAWN_MARGIN,
				current_map_size.y - MANUAL_SPAWN_MARGIN
			)
		)

		demon_ultimate_spawn_queue.append({
			"monster_id": pool[index % pool.size()],
			"position": spawn_position,
		})

	return true

func _process_demon_ultimate_spawn_queue(delta: float) -> void:
	if demon_ultimate_spawn_queue.is_empty():
		return

	demon_ultimate_spawn_timer = maxf(
		demon_ultimate_spawn_timer - delta,
		0.0
	)
	if demon_ultimate_spawn_timer > 0.0:
		return

	var spawned_this_batch := 0
	while (
		spawned_this_batch < demon_ultimate_spawn_batch_size
		and not demon_ultimate_spawn_queue.is_empty()
	):
		var entry: Dictionary = demon_ultimate_spawn_queue.pop_front()
		var monster_id := String(entry.get("monster_id", ""))
		var spawn_position: Vector2 = entry.get("position", Vector2.ZERO)

		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			_spawn_monster(monster_id, spawn_position, 0.0, false, {"mission_summon": true})

			if is_instance_valid(hero) and hero.has_method("record_offensive_event"):
				hero.call(
					"record_offensive_event",
					monster_id,
					MONSTER_CATALOG.get_role(monster_id)
				)

		spawned_this_batch += 1

	if spawned_this_batch > 0:
		_emit_stats()

	if demon_ultimate_spawn_queue.is_empty():
		demon_ultimate_spawn_timer = 0.0
	else:
		demon_ultimate_spawn_timer = demon_ultimate_spawn_interval

func _queue_stage_event_reinforcements(event: Dictionary) -> void:
	var count := maxi(int(event.get("reinforcement_count", 0)), 0)
	if count <= 0:
		return

	var pool: Array[String] = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			pool.append(monster_id)

	if pool.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if not MONSTER_CATALOG.MONSTERS.has(fallback_id):
				continue
			pool.append(fallback_id)
			if pool.size() >= 3:
				break

	if pool.is_empty():
		return

	stage_reinforcement_batch_size = clampi(
		int(event.get("reinforcement_batch_size", 2)),
		1,
		STAGE_REINFORCEMENT_MAX_SPAWNS_PER_FRAME
	)
	stage_reinforcement_interval = maxf(
		float(event.get("reinforcement_interval", 0.12)),
		0.04
	)
	# Let the elite finish its own scene/visual setup before starting the pack.
	stage_reinforcement_timer = stage_reinforcement_interval

	var spawn_min := maxf(
		float(event.get("reinforcement_spawn_min", 330.0)),
		220.0
	)
	var spawn_max := maxf(
		float(event.get("reinforcement_spawn_max", 470.0)),
		spawn_min
	)
	var center := (
		hero.position
		if is_instance_valid(hero)
		else current_map_size * 0.5
	)

	for index in range(count):
		var monster_id := pool[index % pool.size()]
		var angle := (
			TAU * float(index) / float(maxi(count, 1))
			+ randf_range(-0.18, 0.18)
		)
		var distance := randf_range(spawn_min, spawn_max)
		var candidate := center + Vector2.from_angle(angle) * distance
		var spawn_position := Vector2(
			clampf(
				candidate.x,
				MANUAL_SPAWN_MARGIN,
				current_map_size.x - MANUAL_SPAWN_MARGIN
			),
			clampf(
				candidate.y,
				MANUAL_SPAWN_MARGIN,
				current_map_size.y - MANUAL_SPAWN_MARGIN
			)
		)
		stage_reinforcement_queue.append({
			"monster_id": monster_id,
			"position": spawn_position,
		})

func _process_stage_reinforcement_queue(delta: float) -> void:
	if stage_reinforcement_queue_index >= stage_reinforcement_queue.size():
		stage_reinforcement_queue.clear()
		stage_reinforcement_queue_index = 0
		return

	stage_reinforcement_timer = maxf(
		stage_reinforcement_timer - delta,
		0.0
	)
	if stage_reinforcement_timer > 0.0:
		return

	var spawned_this_batch := 0
	while (
		spawned_this_batch < stage_reinforcement_batch_size
		and stage_reinforcement_queue_index
		< stage_reinforcement_queue.size()
	):
		var entry: Dictionary = stage_reinforcement_queue[
			stage_reinforcement_queue_index
		]
		stage_reinforcement_queue_index += 1
		var monster_id := String(entry.get("monster_id", ""))
		var spawn_position: Vector2 = entry.get(
			"position",
			Vector2.ZERO
		)

		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			_spawn_monster(
				monster_id,
				spawn_position,
				0.0,
				false
			)
			if (
				is_instance_valid(hero)
				and hero.has_method("record_offensive_event")
			):
				hero.call(
					"record_offensive_event",
					monster_id,
					MONSTER_CATALOG.get_role(monster_id)
				)

		spawned_this_batch += 1

	if spawned_this_batch > 0:
		_emit_stats()

	if stage_reinforcement_queue_index >= stage_reinforcement_queue.size():
		stage_reinforcement_queue.clear()
		stage_reinforcement_queue_index = 0
		stage_reinforcement_timer = 0.0
	else:
		stage_reinforcement_timer = stage_reinforcement_interval

func _process_stage_director_events() -> void:
	for event in stage_director.collect_due_events(
		run_metrics.elapsed_seconds
	):
		_trigger_stage_director_event(event)

func _trigger_stage_director_event(event: Dictionary) -> void:
	if not is_instance_valid(hero):
		return

	var event_type := String(event.get("type", "elite"))
	var selection_mode := String(event.get("selection_mode", ""))

	if (
		selection_mode == "team"
		and event_type in ["elite", "miniboss"]
	):
		_open_mutation_choice(event)
		return

	var monster_id := String(event.get("monster_id", ""))
	if selection_mode == "team_random":
		monster_id = _get_random_stage_event_team_monster_id()
		if monster_id.is_empty():
			push_warning("Stage event team random monster not found.")
			return
		if event_type == "boss":
			event["name"] = "%s 보스" % _get_catalog_monster_display_name(monster_id)

	if not spawn_special_monster(monster_id, event):
		push_warning(
			"Stage event monster not found: %s" % monster_id
		)
		return

	_emit_stage_event_announcement(event, monster_id)
	_queue_stage_event_reinforcements(event)

func _get_random_stage_event_team_monster_id() -> String:
	var candidates: Array[String] = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id) and bool(MONSTER_CATALOG.MONSTERS[monster_id].get("can_be_elite", true)):
			candidates.append(monster_id)

	if candidates.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if MONSTER_CATALOG.MONSTERS.has(fallback_id) and bool(MONSTER_CATALOG.MONSTERS[fallback_id].get("can_be_elite", true)):
				candidates.append(fallback_id)

	if candidates.is_empty():
		return ""

	return candidates[randi_range(0, candidates.size() - 1)]


func online_open_mutation_choice(event: Dictionary) -> void:
	if online_match_mode: _open_mutation_choice(event)

func _open_mutation_choice(event: Dictionary) -> void:
	if mutation_director.is_active():
		return

	var candidates: Array = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id) and bool(MONSTER_CATALOG.MONSTERS[monster_id].get("can_be_elite", true)):
			candidates.append(monster_id)

	if candidates.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if not MONSTER_CATALOG.MONSTERS.has(fallback_id) or not bool(MONSTER_CATALOG.MONSTERS[fallback_id].get("can_be_elite", true)):
				continue
			candidates.append(fallback_id)
			if candidates.size() >= 3:
				break

	if not mutation_director.begin(event, candidates):
		return
	mutation_choice_revision += 1

	if not online_match_mode:
		flow_pause_manager.request_pause(
			PAUSE_REASON_MUTATION_CHOICE,
			FULL_MODAL_PAUSE_DOMAINS
		)
	_sync_combat_pause_state()
	mutation_choice_ready.emit(
		mutation_director.get_event(),
		mutation_director.get_candidates()
	)

func spawn_selected_mutation(monster_id: String) -> void:
	# Preserve the existing void API for local/tutorial callers.
	try_choose_mutation(monster_id)

func get_mutation_choice_revision() -> int:
	return mutation_choice_revision

func try_choose_mutation(monster_id: String, expected_revision: int = -1) -> bool:
	if not battle_command_router.supports_local_execution():
		return false
	var revision := mutation_choice_revision if expected_revision == -1 else expected_revision
	if not command_routing_enabled:
		return _execute_selected_mutation(monster_id, revision)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.MUTATION_CHOOSE, monster_id, Vector2.ZERO, "", revision)

func _execute_selected_mutation(monster_id: String, expected_revision: int) -> bool:
	if expected_revision != mutation_choice_revision:
		return false
	if not mutation_director.is_active() or monster_id not in mutation_director.get_candidates():
		return false
	var event := mutation_director.get_event()
	mutation_director.reset()
	mutation_choice_revision += 1
	flow_pause_manager.release_pause(PAUSE_REASON_MUTATION_CHOICE)
	_sync_combat_pause_state()
	# Resume queued level rewards after this choice and its UI callbacks finish.
	call_deferred("_open_next_demon_augment_if_needed")

	return _spawn_selected_mutation(monster_id, event)

func online_hold_mutation(monster_id: String) -> Dictionary:
	if not online_match_mode or not mutation_director.is_active() or monster_id not in mutation_director.get_candidates(): return {}
	var event: Dictionary = mutation_director.get_event().duplicate(true)
	mutation_director.reset()
	mutation_choice_revision += 1
	flow_pause_manager.release_pause(PAUSE_REASON_MUTATION_CHOICE)
	_sync_combat_pause_state()
	call_deferred("_open_next_demon_augment_if_needed")
	return {"id": monster_id, "event": event}

func _spawn_selected_mutation(monster_id: String, event: Dictionary, manual_position: Variant = null) -> bool:
	if event.is_empty():
		event = {
			"type": "elite",
			"name_prefix": "돌연변이",
			"spawn_distance": 260.0,
			"hp_multiplier": 2.8,
			"damage_multiplier": 1.65,
			"speed_multiplier": 1.12,
			"attack_speed_multiplier": 1.12,
			"exp_multiplier": 1.5,
			"visual_scale": 1.5,
		}
	else:
		event["spawn_distance"] = minf(
			float(event.get("spawn_distance", 260.0)),
			260.0
		)
	if manual_position is Vector2:
		event = event.duplicate(true)
		event["online_spawn_position"] = manual_position

	var event_type := String(event.get("type", "elite"))
	var name_prefix := String(event.get("name_prefix", "돌연변이"))
	var mutation_name := "%s %s" % [
		name_prefix,
		_get_catalog_monster_display_name(monster_id),
	]
	event["name"] = mutation_name

	var spawned := spawn_special_monster(monster_id, event)
	if not spawned:
		mutation_spawn_result.emit(
			false,
			"돌연변이 소환 실패 · monster_id=%s" % monster_id
		)
		return false

	_emit_stage_event_announcement(event, monster_id)
	_queue_stage_event_reinforcements(event)
	mutation_selected.emit(event_type, mutation_name)
	mutation_spawn_result.emit(true, "%s 소환 완료" % mutation_name)
	return true

func spawn_special_monster(
	monster_id: String,
	special_data: Dictionary
) -> bool:
	if not is_instance_valid(hero):
		return false
	if not MONSTER_CATALOG.MONSTERS.has(monster_id):
		return false
	if hero_player_mode and not online_match_mode and not HERO_SURVIVAL.monster_allowed(monster_id,int(current_stage_data.get("number",1)),campaign_difficulty): return false

	if hero_player_mode and not online_match_mode:
		monster_id = hero_spawn_candidate(monster_id,hero_control_roster,true)
		if monster_id.is_empty(): return false
	if not bool(MONSTER_CATALOG.MONSTERS[monster_id].get("can_be_elite", true)):
		return false

	var spawn_position := _get_special_monster_spawn_position(monster_id, special_data)
	if online_match_mode and special_data.get("online_spawn_position", null) is Vector2:
		spawn_position = _clamp_manual_spawn_position(special_data.online_spawn_position)
		var profile := MONSTER_CATALOG.get_elite_spawn_profile(monster_id)
		if int(profile.get("position_policy", MONSTER_CATALOG.DEFAULT_ELITE_SPAWN.position_policy)) == MONSTER_CATALOG.EliteSpawnPosition.FARTHEST_ATTACK_RANGE:
			var offset: Vector2 = spawn_position - hero.position
			var attack_range := maxf(float(MONSTER_CATALOG.get_base_stats(monster_id).get("attack_range", 1.0)) - 1.0, 1.0)
			spawn_position = _clamp_manual_spawn_position(hero.position + offset.limit_length(attack_range))
	var monster = _spawn_monster(
		monster_id,
		spawn_position,
		0.0,
		false,
		{"elite_variant": true}
	)
	if not is_instance_valid(monster):
		return false

	_apply_special_monster_modifiers(
		monster,
		monster_id,
		special_data
	)
	_emit_stats()
	return true

func _apply_special_monster_modifiers(
	monster: Node,
	monster_id: String,
	special_data: Dictionary
) -> void:
	if not is_instance_valid(monster):
		return

	if not bool(MONSTER_CATALOG.MONSTERS.get(monster_id, {}).get("can_be_elite", true)):
		return

	if hero_player_mode and not online_match_mode: hero_control_spawns.register(monster.get_instance_id(),monster_id,true,int(current_stage_data.get("number",1)),float(run_metrics.elapsed_seconds))
	monster.set_meta("visual_variant", "elite")
	# Direct conversions must discard excluded effects before recalculating stats.
	# Event spawns already have filtered configs; retain their running timers.
	var previous_configs: Dictionary = monster.get_meta("special_augment_configs", {})
	for config in previous_configs.values():
		if bool(config.get("exclude_elite", false)):
			_apply_special_augments_to_monster(monster, monster_id)
			break

	var hp_multiplier := maxf(
		float(special_data.get("hp_multiplier", 1.0)),
		0.01
	)
	var damage_multiplier := maxf(
		float(special_data.get("damage_multiplier", 1.0)),
		0.01
	)
	var speed_multiplier := maxf(
		float(special_data.get("speed_multiplier", 1.0)),
		0.01
	)
	var attack_speed_multiplier := maxf(
		float(special_data.get("attack_speed_multiplier", 1.0)),
		0.01
	)
	var exp_multiplier := maxf(
		float(special_data.get("exp_multiplier", 1.0)),
		0.0
	)
	var visual_scale := maxf(
		float(special_data.get("visual_scale", 1.0)),
		0.1
	)

	var base_hp_meta = monster.get_meta(
		"demon_level_base_max_hp",
		null
	)
	if base_hp_meta != null:
		monster.set_meta(
			"demon_level_base_max_hp",
			maxf(float(base_hp_meta) * hp_multiplier, 1.0)
		)

	var base_damage_meta = monster.get_meta(
		"demon_level_base_attack_damage",
		null
	) if monster.has_meta("demon_level_base_attack_damage") else null
	if base_damage_meta != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(float(base_damage_meta) * damage_multiplier, 1.0)
		)

	var base_speed_meta = monster.get_meta(
		"demon_level_base_move_speed",
		null
	)
	if base_speed_meta != null:
		monster.set_meta(
			"demon_level_base_move_speed",
			maxf(float(base_speed_meta) * speed_multiplier, 1.0)
		)

	var attack_cooldown_value = monster.get("attack_cooldown")
	if attack_cooldown_value != null:
		monster.set(
			"attack_cooldown",
			maxf(
				0.10,
				float(attack_cooldown_value)
				/ attack_speed_multiplier
			)
		)

	var scaling_profile := MONSTER_CATALOG.get_runtime_scaling_profile(monster_id)
	var fuse_property: StringName = scaling_profile.get("fuse_property", &"")
	if not fuse_property.is_empty():
		var fuse_value = monster.get(fuse_property)
		if fuse_value != null:
			monster.set(
				fuse_property,
				maxf(
					0.10,
					float(fuse_value)
					/ attack_speed_multiplier
				)
			)

	if hero_player_mode or monster.has_method("get_runtime_stat_additions"):
		monster.set_meta("runtime_variant_stats", {"hp":hp_multiplier, "damage":damage_multiplier, "speed":speed_multiplier, "attack_speed":attack_speed_multiplier})
	if monster.has_method("get_runtime_stat_additions"):
		var base_interval := float(monster.get_meta("runtime_base_attack_cooldown", monster.get("attack_cooldown")))
		monster.set_meta("runtime_base_attack_cooldown", base_interval / attack_speed_multiplier)

	_apply_demon_level_scaling_to_monster(monster, false)

	var current_hp_value = monster.get("current_hp")
	var max_hp_value = monster.get("max_hp")
	if current_hp_value != null and max_hp_value != null:
		monster.set("current_hp", int(max_hp_value))

	var exp_value = monster.get("exp_reward")
	if exp_value != null:
		monster.set(
			"exp_reward",
			maxi(
				1,
				int(round(float(exp_value) * exp_multiplier))
			)
		)

	var explosion_property: StringName = scaling_profile.get("explosion_property", &"")
	if not explosion_property.is_empty():
		var explosion_damage_value = monster.get(explosion_property)
		if explosion_damage_value != null:
			monster.set(
				explosion_property,
				maxi(
					1,
					int(round(
						float(explosion_damage_value)
						* damage_multiplier
					))
				)
			)

	if absf(visual_scale - 1.0) > 0.001:
		monster.scale *= visual_scale

	var special_type := String(
		special_data.get("type", "special")
	)
	var special_name := String(
		special_data.get(
			"name",
			_get_catalog_monster_display_name(monster_id)
		)
	)
	monster.set_meta("stage_event_type", special_type)
	monster.set_meta("stage_event_name", special_name)
	monster.set_meta("visual_variant", "elite")
	_apply_elite_monster_visual(monster, monster_id)
	var elite_spawn_profile := MONSTER_CATALOG.get_elite_spawn_profile(monster_id)
	var alive_registration: StringName = elite_spawn_profile.get(
		"alive_registration_method", MONSTER_CATALOG.DEFAULT_ELITE_SPAWN.alive_registration_method
	)
	if not alive_registration.is_empty():
		call(alive_registration, monster, true)
	var elite_skills := MONSTER_CATALOG.get_elite_skills(monster_id)
	monster.set_meta("elite_skill_count", elite_skills.size())
	if not elite_skills.is_empty():
		elite_monster_skill_runtime.register_elite(
			monster as Node2D,
			monster_id,
			elite_skills
		)

	if monster.has_method("on_spawn_stats_finalized"):
		monster.call("on_spawn_stats_finalized")

	if monster.has_method("queue_redraw"):
		monster.call("queue_redraw")

func _apply_elite_monster_visual(
	monster: Node,
	monster_id: String
) -> void:
	var profile := MONSTER_CATALOG.get_elite_visual_profile(monster_id)
	if profile.is_empty():
		return

	if monster.has_method("apply_visual_profile"):
		monster.call("apply_visual_profile", profile)
		return

	var visual_node = monster.get_node_or_null("Visual")
	if (
		is_instance_valid(visual_node)
		and visual_node.has_method("apply_visual_profile")
	):
		visual_node.call("apply_visual_profile", profile)

func _emit_stage_event_announcement(
	event: Dictionary,
	monster_id: String
) -> void:
	var event_type := String(event.get("type", "elite"))
	var event_name := String(
		event.get("name", _get_catalog_monster_display_name(monster_id))
	)
	var message := ""
	match event_type:
		"boss":
			message = "보스 출현! %s이(가) 전장에 난입했습니다." % event_name
		"miniboss":
			message = "대돌연변이 출현! %s" % event_name
		_:
			message = "돌연변이 출현! %s" % event_name

	stage_event_triggered.emit(
		event_type,
		event_name,
		message
	)

func _get_special_monster_spawn_position(monster_id: String, special_data: Dictionary) -> Vector2:
	var profile := MONSTER_CATALOG.get_elite_spawn_profile(monster_id)
	var position_policy := int(profile.get(
		"position_policy", MONSTER_CATALOG.DEFAULT_ELITE_SPAWN.position_policy
	))
	if position_policy == MONSTER_CATALOG.EliteSpawnPosition.FARTHEST_ATTACK_RANGE:
		return _get_farthest_attack_range_spawn_position(monster_id)
	return _get_stage_event_spawn_position(float(special_data.get(
		"spawn_distance", profile.get("spawn_distance", MONSTER_CATALOG.DEFAULT_ELITE_SPAWN_DISTANCE)
	)))


func _get_stage_event_spawn_position(
	spawn_distance: float = MONSTER_CATALOG.DEFAULT_ELITE_SPAWN_DISTANCE
) -> Vector2:
	if not is_instance_valid(hero):
		return current_map_size * 0.5

	var angle := randf_range(0.0, TAU)
	var candidate := (
		hero.position
		+ Vector2.from_angle(angle) * maxf(spawn_distance, 1.0)
	)
	return _clamp_manual_spawn_position(candidate)


func _get_farthest_stage_event_spawn_position() -> Vector2:
	if not is_instance_valid(hero):
		return current_map_size * 0.5
	var left := MANUAL_SPAWN_MARGIN
	var right := current_map_size.x - MANUAL_SPAWN_MARGIN
	var top := _get_spawn_top_margin()
	var bottom := current_map_size.y - MANUAL_SPAWN_MARGIN
	var farthest := Vector2(left, top)
	var farthest_distance_sq := hero.position.distance_squared_to(farthest)
	for candidate in [
		Vector2(right, top),
		Vector2(left, bottom),
		Vector2(right, bottom),
	]:
		var distance_sq := hero.position.distance_squared_to(candidate)
		if distance_sq > farthest_distance_sq:
			farthest = candidate
			farthest_distance_sq = distance_sq
	return farthest


func _get_farthest_attack_range_spawn_position(
	monster_id: String
) -> Vector2:
	if not is_instance_valid(hero):
		return current_map_size * 0.5

	var base_stats := MONSTER_CATALOG.get_base_stats(monster_id)
	var attack_range := maxf(
		float(base_stats.get("attack_range", 1.0)),
		1.0
	)
	var farthest_map_position := _get_farthest_stage_event_spawn_position()
	var offset := farthest_map_position - hero.position
	if offset.length_squared() <= 0.001:
		return _clamp_manual_spawn_position(hero.position)

	# Keep a one-pixel safety margin so floating-point rounding cannot place
	# the stationary actor just outside its own attack check.
	var spawn_distance := minf(maxf(attack_range - 1.0, 1.0), offset.length())
	return _clamp_manual_spawn_position(
		hero.position + offset.normalized() * spawn_distance
	)

func _gain_demon_exp(amount: float) -> void:
	if tutorial_mode:
		return
	if amount <= 0.0 or battle_over:
		return

	var previous_demon_level := demon_level
	demon_exp += amount

	while demon_exp + 0.001 >= demon_exp_to_next_level:
		demon_exp -= demon_exp_to_next_level
		demon_level += 1
		demon_exp_to_next_level = _required_demon_exp_for_level(demon_level)
		demon_pending_augments += 1
		demon_pending_augment_levels.append(demon_level)

	if demon_level != previous_demon_level:
		_refresh_alive_monsters_for_demon_level()

	demon_progression_changed.emit(
		demon_level,
		demon_exp,
		demon_exp_to_next_level
	)

	_open_next_demon_augment_if_needed()

func _required_demon_exp_for_level(current_level: int) -> float:
	return DEMON_BASE_EXP_TO_NEXT + float(maxi(current_level - 1, 0)) * DEMON_EXP_GROWTH_PER_LEVEL

func _open_next_demon_augment_if_needed() -> void:
	if battle_over or demon_augment_selection_active or mutation_director.is_active() or demon_pending_augments <= 0:
		return

	demon_active_augment_level = (
		demon_pending_augment_levels[0]
		if not demon_pending_augment_levels.is_empty()
		else demon_level
	)
	demon_augment_candidates = _roll_demon_augment_candidates(false)
	if demon_augment_candidates.is_empty():
		var replace_with_elite := DEMON_AUGMENTS.is_special_level(demon_active_augment_level)
		demon_pending_augments = maxi(demon_pending_augments - 1, 0)
		if not demon_pending_augment_levels.is_empty():
			demon_pending_augment_levels.pop_front()
		demon_active_augment_level = 0
		if replace_with_elite:
			if online_match_mode: online_elite_requested.emit(MUTATION_CATALOG.SPECIAL_AUGMENT_EXHAUSTED_EVENT)
			else: _open_mutation_choice(MUTATION_CATALOG.SPECIAL_AUGMENT_EXHAUSTED_EVENT)
			if mutation_director.is_active():
				return
		_open_next_demon_augment_if_needed()
		return

	demon_augment_selection_active = true
	demon_augment_revision += 1
	if not online_match_mode:
		flow_pause_manager.request_pause(PAUSE_REASON_DEMON_AUGMENT,FULL_MODAL_PAUSE_DOMAINS)
		_sync_combat_pause_state()

	demon_augment_ready.emit(
		demon_augment_candidates,
		demon_rerolls_left,
		demon_active_augment_level
	)

func _roll_demon_augment_candidates(is_reroll: bool) -> Array:
	var exclude_ids: Array = []

	if is_reroll:
		for old_id in demon_last_candidate_ids:
			if old_id not in exclude_ids:
				exclude_ids.append(old_id)

	var candidates: Array = []
	if DEMON_AUGMENTS.is_special_level(demon_active_augment_level):
		candidates = DEMON_AUGMENTS.roll_special_candidates(
			allowed_monster_ids,
			demon_special_augments,
			exclude_ids,
			3
		)
		if candidates.is_empty() and is_reroll:
			candidates = DEMON_AUGMENTS.roll_special_candidates(
				allowed_monster_ids,
				demon_special_augments,
				[],
				3
			)
	else:
		var monster_names: Dictionary = {}
		for raw_id in allowed_monster_ids:
			var monster_id := String(raw_id)
			monster_names[monster_id] = _get_catalog_monster_display_name(
				monster_id
			)
		candidates = DEMON_AUGMENTS.roll_normal_candidates(
			allowed_monster_ids,
			monster_names,
			demon_build_counts,
			exclude_ids,
			3
		)
		if candidates.is_empty() and is_reroll:
			candidates = DEMON_AUGMENTS.roll_normal_candidates(
				allowed_monster_ids,
				monster_names,
				demon_build_counts,
				[],
				3
			)

	demon_last_candidate_ids.clear()
	for candidate in candidates:
		candidate["compare"] = DEMON_AUGMENTS.compare(candidate,int(demon_build_counts.get(String(candidate.get("id","")),0)))
		demon_last_candidate_ids.append(String(candidate.get("id", "")))

	return candidates

func get_demon_augment_revision() -> int:
	return demon_augment_revision

func reroll_demon_augments(expected_revision: int = -1) -> bool:
	if not battle_command_router.supports_local_execution():
		return false
	# Legacy callers use the current offer; UI supplies the revision it displayed.
	var revision := demon_augment_revision if expected_revision == -1 else expected_revision
	if not command_routing_enabled:
		return _execute_reroll_demon_augments(revision)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.DEMON_AUGMENT_REROLL, "", Vector2.ZERO, "", revision)

func choose_demon_augment(augment_id: String, expected_revision: int = -1) -> bool:
	if not battle_command_router.supports_local_execution():
		return false
	var revision := demon_augment_revision if expected_revision == -1 else expected_revision
	if not command_routing_enabled:
		return _execute_choose_demon_augment(augment_id, revision)
	return battle_command_router.submit_local(BATTLE_SESSION.Command.DEMON_AUGMENT_CHOOSE, augment_id, Vector2.ZERO, "", revision)

func bank_online_demon_augment() -> void:
	if not online_match_mode or not demon_augment_selection_active: return
	demon_pending_augments = maxi(0,demon_pending_augments-1)
	if not demon_pending_augment_levels.is_empty(): demon_pending_augment_levels.pop_front()
	demon_active_augment_level = 0
	demon_augment_selection_active = false
	demon_augment_candidates = []
	demon_augment_revision += 1
	_open_next_demon_augment_if_needed()

func reroll_held_demon_augment(candidates: Array, offer_level: int) -> Array:
	if not online_match_mode or demon_augment_selection_active or demon_rerolls_left <= 0 or candidates.is_empty(): return []
	var previous_level := demon_active_augment_level
	var previous_ids: Array[String] = demon_last_candidate_ids.duplicate()
	demon_active_augment_level = offer_level
	demon_last_candidate_ids.clear()
	for candidate in candidates: demon_last_candidate_ids.append(String(candidate.get("id", "")))
	var next := _roll_demon_augment_candidates(true)
	demon_active_augment_level = previous_level
	demon_last_candidate_ids = previous_ids
	if next.is_empty(): return []
	demon_rerolls_left -= 1
	return next

func choose_held_demon_augment(augment_id: String, candidates: Array, offer_level: int) -> bool:
	if not online_match_mode or demon_augment_selection_active or candidates.is_empty(): return false
	demon_pending_augments += 1
	demon_pending_augment_levels.push_front(offer_level)
	demon_active_augment_level = offer_level
	demon_augment_candidates = candidates
	demon_augment_selection_active = true
	demon_augment_revision += 1
	var accepted := _execute_choose_demon_augment(augment_id,demon_augment_revision)
	if not accepted: bank_online_demon_augment()
	return accepted

func _execute_reroll_demon_augments(expected_revision: int) -> bool:
	if expected_revision != demon_augment_revision:
		return false
	if not demon_augment_selection_active or demon_rerolls_left <= 0:
		return false

	demon_rerolls_left -= 1
	demon_augment_candidates = _roll_demon_augment_candidates(true)
	demon_augment_revision += 1
	demon_augment_ready.emit(
		demon_augment_candidates,
		demon_rerolls_left,
		demon_active_augment_level
	)
	return true

func _execute_choose_demon_augment(augment_id: String, expected_revision: int) -> bool:
	if expected_revision != demon_augment_revision:
		return false
	if not demon_augment_selection_active:
		return false

	var is_current_candidate := false
	for candidate in demon_augment_candidates:
		if String(candidate.get("id", "")) == augment_id:
			is_current_candidate = true
			break

	if not is_current_candidate:
		return false

	var augment: Dictionary = DEMON_AUGMENTS.get_augment(augment_id)
	if augment.is_empty():
		return false

	var augment_type := String(
		augment.get("augment_type", DEMON_AUGMENTS.TYPE_NORMAL)
	)
	if augment_type == DEMON_AUGMENTS.TYPE_SPECIAL:
		if not DEMON_AUGMENTS.can_acquire_special(augment_id,demon_special_augments):
			return false
		demon_special_augments.append(augment_id)
		run_metrics.record_special_augment_acquired()
		_refresh_monsters_for_selected_augment(augment)
	else:
		var current_stack := int(demon_build_counts.get(augment_id, 0))
		var max_stack := int(augment.get("max_stack", 0))
		if max_stack > 0 and current_stack >= max_stack:
			return false

		_apply_demon_augment(augment)
		demon_build_counts[augment_id] = current_stack + 1
		_rebuild_monster_augment_modifiers_from_build_counts()
		_refresh_monsters_for_selected_augment(augment)

	demon_pending_augments = maxi(demon_pending_augments - 1, 0)
	if not demon_pending_augment_levels.is_empty():
		demon_pending_augment_levels.pop_front()
	demon_active_augment_level = 0
	demon_augment_selection_active = false
	demon_augment_candidates.clear()
	demon_augment_revision += 1
	demon_last_candidate_ids.clear()
	flow_pause_manager.release_pause(PAUSE_REASON_DEMON_AUGMENT)
	_sync_combat_pause_state()

	var augment_name: String = String(augment.get("name", "마왕 증강"))
	demon_augment_applied.emit(augment_name, get_demon_build_summary())
	command_changed.emit(command_power, max_command)

	_open_next_demon_augment_if_needed()
	return true

func _apply_demon_augment(augment: Dictionary) -> void:
	for raw_effect in augment.get("effects", []):
		var effect: Dictionary = raw_effect
		_apply_demon_augment_effect(effect)

func _apply_demon_augment_effect(effect: Dictionary) -> void:
	var op := String(effect.get("op", ""))
	var target := String(effect.get("target", ""))

	match op:
		"add_runtime":
			if target.is_empty():
				return

			var current_value = get(target)
			if current_value == null:
				return

			var next_value := float(current_value) + float(effect.get("value", 0.0))
			if effect.has("min"):
				next_value = maxf(next_value, float(effect.get("min", next_value)))
			if effect.has("max"):
				next_value = minf(next_value, float(effect.get("max", next_value)))
			set(target, next_value)

		"multiply_runtime":
			if target.is_empty():
				return

			var current_value = get(target)
			if current_value == null:
				return

			var next_value := float(current_value) * float(effect.get("value", 1.0))
			if effect.has("min"):
				next_value = maxf(next_value, float(effect.get("min", next_value)))
			if effect.has("max"):
				next_value = minf(next_value, float(effect.get("max", next_value)))
			set(target, next_value)

		"add_command_capacity":
			var amount := float(effect.get("value", 0.0))
			max_command += amount
			command_power = minf(command_power + amount, max_command)

		"monster_multiplier":
			var monster_id := String(effect.get("monster_id", ""))
			var stat := String(effect.get("stat", ""))
			if monster_id.is_empty() or stat.is_empty():
				return
			var modifiers: Dictionary = monster_augment_modifiers.get(
				monster_id,
				{}
			)
			var current := float(modifiers.get(stat, 1.0))
			var next_value := current * float(effect.get("value", 1.0))
			if effect.has("min"):
				next_value = maxf(
					next_value,
					float(effect.get("min", next_value))
				)
			if effect.has("max"):
				next_value = minf(
					next_value,
					float(effect.get("max", next_value))
				)
			modifiers[stat] = next_value
			monster_augment_modifiers[monster_id] = modifiers

		_:
			push_warning("Unknown Demon augment effect op: %s" % op)

func _rebuild_monster_augment_modifiers_from_build_counts() -> void:
	monster_augment_modifiers.clear()
	for raw_augment_id in demon_build_counts.keys():
		var augment_id := String(raw_augment_id)
		var stack_count := maxi(
			int(demon_build_counts.get(augment_id, 0)),
			0
		)
		if stack_count <= 0:
			continue

		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		if augment.is_empty():
			continue
		for raw_effect in augment.get("effects", []):
			var effect: Dictionary = raw_effect
			if String(effect.get("op", "")) != "monster_multiplier":
				continue
			for _stack_index in range(stack_count):
				_apply_demon_augment_effect(effect)


func _get_monster_augment_multiplier(
	monster_id: String,
	stat: String
) -> float:
	var modifiers: Dictionary = monster_augment_modifiers.get(monster_id, {})
	return maxf(float(modifiers.get(stat, 1.0)), 0.01)

func _get_selected_special_augment_ids_for_monster(
	monster_id: String
) -> Array[String]:
	var result: Array[String] = []
	for raw_id in demon_special_augments:
		var augment_id := String(raw_id)
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		if String(augment.get("monster_id", "")) != monster_id:
			continue
		result.append(augment_id)
	return result


func _get_special_augment_config(
	monster_id: String
) -> Dictionary:
	# Also detects direct assignment by debug tools/tests and same-size changes.
	if special_augment_cache_ids != demon_special_augments:
		special_augment_cache_ids.assign(demon_special_augments)
		special_augment_config_cache.clear()
		for augment_id in demon_special_augments:
			var augment := DEMON_AUGMENTS.get_augment(augment_id)
			var owner_id := String(augment.get("monster_id", ""))
			var effect_type := String(augment.get("effect_type", ""))
			if owner_id.is_empty() or effect_type.is_empty():
				continue
			if not special_augment_config_cache.has(owner_id):
				special_augment_config_cache[owner_id] = {}
			special_augment_config_cache[owner_id][effect_type] = Dictionary(
				augment.get("effect_values", {})
			).duplicate(true)
	if not special_augment_config_cache.has(monster_id):
		special_augment_config_cache[monster_id] = {}
	# Internal read-only view. Actor configuration receives its own deep copy.
	return special_augment_config_cache[monster_id]

func _apply_special_augments_to_monster(
	monster: Node,
	monster_id: String
) -> void:
	if not is_instance_valid(monster):
		return
	var configs := {} if bool(monster.get_meta("exclude_all_augments", false)) else _get_applicable_special_augment_config(monster_id, String(monster.get_meta("visual_variant", "")) == "elite").duplicate(true)
	monster.set_meta("special_augment_configs", configs)
	if monster.has_method("configure_special_augments"):
		monster.call("configure_special_augments", configs)

func _refresh_monsters_for_selected_augment(augment: Dictionary) -> void:
	var affected_ids: Array[String] = []
	var effect_values: Dictionary = augment.get("effect_values",{})
	if bool(effect_values.get("remove_existing_on_select",false)):
		var owner_id := String(augment.get("monster_id",""))
		for actor in _get_active_monsters_snapshot():
			if is_instance_valid(actor) and String(actor.get("monster_type")) == owner_id:
				if bool(effect_values.get("exclude_elite", false)) and String(actor.get_meta("visual_variant", "")) == "elite":
					continue
				_consume_monster_for_fusion(actor as Node2D)
	if String(augment.get("augment_type", "")) == DEMON_AUGMENTS.TYPE_SPECIAL:
		var owner_id := String(augment.get("monster_id", ""))
		if not owner_id.is_empty():
			affected_ids.append(owner_id)
	else:
		for effect in augment.get("effects", []):
			var op := String(effect.get("op", ""))
			if op == "monster_multiplier":
				# Cost is consumed by summon pricing, not existing combat stats.
				if String(effect.get("stat", "")) == "cost":
					continue
				var owner_id := String(effect.get("monster_id", ""))
				if not owner_id.is_empty() and owner_id not in affected_ids:
					affected_ids.append(owner_id)
			elif op == "add_runtime" or op == "multiply_runtime":
				# Future global runtime effects keep the full-refresh fallback.
				if String(effect.get("target", "")) in [
					"command_regen_per_second", "death_refund_ratio",
					"summon_cost_multiplier", "demon_exp_gain_multiplier",
				]:
					continue
				_refresh_alive_monsters_for_augments()
				return
			elif op != "add_command_capacity":
				_refresh_alive_monsters_for_augments()
				return
	if not affected_ids.is_empty():
		_refresh_alive_monsters_for_augments(affected_ids)


func _refresh_alive_monsters_for_augments(affected_ids: Array[String] = []) -> void:
	var shared_profiles: Dictionary = {}
	for node in _get_active_monsters_snapshot():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster_id := String(node.get("monster_type"))
		if not affected_ids.is_empty() and monster_id not in affected_ids:
			continue
		if not shared_profiles.has(monster_id):
			shared_profiles[monster_id] = _get_augment_refresh_profile(monster_id)
		_apply_normal_augments_to_existing_monster(node, monster_id, shared_profiles[monster_id])
		_apply_special_augments_to_monster(node, monster_id)


func _apply_monster_spawn_property_multipliers(monster: Node, monster_type: String) -> void:
	var profile := MONSTER_CATALOG.get_runtime_scaling_profile(monster_type)
	var bindings: Dictionary = profile.get("spawn_property_multipliers", MONSTER_CATALOG.EMPTY_PROPERTY_MULTIPLIERS)
	for property in bindings:
		var value = monster.get(property)
		if value != null:
			monster.set(property, float(value) * float(get(bindings[property])))


func _get_monster_hp_upgrade_multiplier(monster_id: String) -> float:
	var profile := MONSTER_CATALOG.get_runtime_scaling_profile(monster_id)
	var property: StringName = profile.get("hp_upgrade_property", &"")
	return float(get(property)) if not property.is_empty() else 1.0


func _get_augment_refresh_profile(monster_id: String) -> Dictionary:
	return {
		"rarity": MONSTER_CATALOG.get_rarity_combat_profile(monster_id),
		"collection_hp": _get_monster_collection_upgrade_multiplier(monster_id, "hp_per_level"),
		"collection_damage": _get_monster_collection_upgrade_multiplier(monster_id, "damage_per_level"),
	}


func _apply_normal_augments_to_existing_monster(
	monster: Node,
	monster_id: String,
	shared_profile: Dictionary = {}
) -> void:
	if bool(monster.get_meta("exclude_all_augments", false)):
		return
	var runtime_variant: Dictionary = monster.get_meta("runtime_variant_stats", {})
	if shared_profile.is_empty():
		shared_profile = _get_augment_refresh_profile(monster_id)
	var rarity_combat: Dictionary = shared_profile["rarity"]
	var rarity_hp_multiplier := maxf(
		float(rarity_combat.get("hp_multiplier", 1.0)),
		0.01
	)
	var rarity_damage_multiplier := maxf(
		float(rarity_combat.get("damage_multiplier", 1.0)),
		0.01
	)
	var rarity_speed_multiplier := maxf(
		float(rarity_combat.get("move_speed_multiplier", 1.0)),
		0.01
	)
	var rarity_attack_cooldown_multiplier := maxf(
		float(rarity_combat.get("attack_cooldown_multiplier", 1.0)),
		0.01
	)
	var collection_hp_multiplier := float(shared_profile["collection_hp"])
	var collection_damage_multiplier := float(shared_profile["collection_damage"])

	var raw_speed = monster.get_meta("augment_raw_move_speed") if monster.has_meta("augment_raw_move_speed") else null
	if raw_speed != null:
		monster.set_meta(
			"demon_level_base_move_speed",
			float(raw_speed)
			* rarity_speed_multiplier
			* monster_speed_multiplier
			* _get_monster_augment_multiplier(monster_id, "speed")
			* float(runtime_variant.get("speed", 1.0))
		)

	var raw_damage = monster.get_meta("augment_raw_attack_damage") if monster.has_meta("augment_raw_attack_damage") else null
	if raw_damage != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(
				float(raw_damage)
				* rarity_damage_multiplier
				* collection_damage_multiplier
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_id, "damage")
				* float(runtime_variant.get("damage", 1.0)),
				1.0
			)
		)

	var raw_hp = monster.get_meta("augment_raw_max_hp") if monster.has_meta("augment_raw_max_hp") else null
	if raw_hp != null:
		var base_hp := (
			float(raw_hp)
			* rarity_hp_multiplier
			* collection_hp_multiplier
			* monster_hp_multiplier
			* _get_monster_augment_multiplier(monster_id, "hp")
			* float(runtime_variant.get("hp", 1.0))
		)
		base_hp *= _get_monster_hp_upgrade_multiplier(monster_id)
		monster.set_meta(
			"demon_level_base_max_hp",
			maxf(base_hp, 1.0)
		)

	var raw_cooldown = monster.get_meta("augment_raw_attack_cooldown") if monster.has_meta("augment_raw_attack_cooldown") else null
	if raw_cooldown != null:
		monster.set(
			"attack_cooldown",
			maxf(
				0.10,
				float(raw_cooldown)
				* rarity_attack_cooldown_multiplier
				* monster_attack_speed_multiplier
				* _get_special_stat_multiplier(monster_id, "attack_cooldown", String(monster.get_meta("visual_variant", "")) == "elite")
				* _get_monster_augment_multiplier(
					monster_id,
					"attack_cooldown"
				)
			)
		)

	var scaling_profile := MONSTER_CATALOG.get_runtime_scaling_profile(monster_id)
	var fuse_property: StringName = scaling_profile.get("fuse_property", &"")
	if not fuse_property.is_empty():
		var raw_fuse = monster.get_meta(
			"augment_raw_%s" % fuse_property,
			null
		)
		if raw_fuse != null:
			monster.set(
				fuse_property,
				maxf(
					0.10,
					float(raw_fuse)
					* rarity_attack_cooldown_multiplier
					* monster_attack_speed_multiplier
					* _get_monster_augment_multiplier(
						monster_id,
						"attack_cooldown"
					)
				)
			)
	var explosion_property: StringName = scaling_profile.get("explosion_property", &"")
	if not explosion_property.is_empty():
		var raw_explosion = monster.get_meta(
			"augment_raw_%s" % explosion_property,
			null
		)
		if raw_explosion != null:
			var survival_damage := _hero_survival_multiplier("damage",float(monster.get_meta("hero_survival_spawn_seconds",0.0))) if hero_player_mode else 1.0
			monster.set(
				explosion_property,
				maxi(
					1,
					int(round(
						float(raw_explosion)*survival_damage
						* rarity_damage_multiplier
						* collection_damage_multiplier
						* monster_damage_multiplier
						* _get_monster_augment_multiplier(
							monster_id,
							"damage"
						)
					))
				)
			)

	if monster.has_method("get_runtime_stat_additions"):
		monster.set_meta("runtime_base_attack_cooldown", float(monster.get("attack_cooldown")) / maxf(float(runtime_variant.get("attack_speed", 1.0)), 0.01))
	_apply_demon_level_scaling_to_monster(monster, true)


func _spawn_extra_normal_summon_monsters(
	monster_type: String,
	spawn_position: Vector2
) -> void:
	_spawn_secondary_monsters(
		monster_type, spawn_position,
		MONSTER_CATALOG.get_secondary_spawn_rule(monster_type, &"on_normal_summon")
	)


func _spawn_secondary_monsters(monster_type: String, spawn_position: Vector2, rule: Dictionary) -> void:
	if rule.is_empty():
		return
	var config: Dictionary = _get_special_augment_config(monster_type).get(
		rule["augment_id"], MONSTER_CATALOG.EMPTY_SECONDARY_SPAWN
	)
	if bool(rule.get("requires_config", false)) and config.is_empty():
		return
	if rule.has("chance_key"):
		var chance := clampf(float(config.get(rule["chance_key"], rule["chance_default"])), 0.0, 1.0)
		if randf() > chance:
			return

	var count: int
	if rule.has("min_count_key"):
		var min_count := maxi(int(config.get(rule["min_count_key"], rule["min_count_default"])), int(rule["count_minimum"]))
		var max_count := maxi(int(config.get(rule["max_count_key"], rule["max_count_default"])), min_count)
		count = randi_range(min_count, max_count)
	else:
		count = maxi(int(config.get(rule["count_key"], rule["count_default"])), int(rule["count_minimum"]))
	var radius := float(rule["radius"])
	var fixed_modifiers: Dictionary = rule.get("fixed_modifiers", MONSTER_CATALOG.EMPTY_SECONDARY_SPAWN)
	var modifier_defaults: Dictionary = rule.get("modifier_defaults", MONSTER_CATALOG.EMPTY_SECONDARY_SPAWN)
	var child_metadata: Dictionary = rule.get("child_metadata", MONSTER_CATALOG.EMPTY_SECONDARY_SPAWN)
	for index in range(count):
		var point := spawn_position
		if radius > 0.0:
			var angle := TAU * float(index + 1) / float(count + 1)
			point += Vector2.from_angle(angle) * radius
		point = _clamp_manual_spawn_position(point)
		# Each attempt owns its modifiers, as in the original spawn paths.
		var modifiers := fixed_modifiers.duplicate()
		for stat in modifier_defaults:
			modifiers[stat] = float(config.get(stat, modifier_defaults[stat]))
		var child = _spawn_monster(monster_type, point, 0.0, true, modifiers)
		if not child_metadata.is_empty() and is_instance_valid(child):
			for key in child_metadata:
				child.set_meta(key, child_metadata[key])

func combat_time_msec() -> int:
	if not hero_player_mode:
		var now := _network_pause_started_msec if _network_paused else Time.get_ticks_msec()
		return now - _network_paused_total_msec
	var now := _hero_pause_started_msec if _hero_subtree_paused else Time.get_ticks_msec()
	return now-_hero_paused_total_msec

func uses_hero_subtree_pause() -> bool:
	return hero_player_mode

func is_combat_simulation_paused() -> bool:
	return (
		battle_over
		or flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_COMBAT
		)
	)


var _hero_pause_started_msec := 0
var _hero_paused_total_msec := 0
var _hero_subtree_paused := false
var _hero_subtree_previous_mode: ProcessMode = Node.PROCESS_MODE_INHERIT

func _sync_combat_pause_state() -> void:
	var should_enable := (
		not battle_over
		and not flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_COMBAT
		)
	)
	if hero_player_mode:
		# Pause the owned simulation, including animations, timers, tweens and
		# actors activated during the modal. Do not overwrite pooled actor flags.
		var modal_paused := not should_enable and not battle_over
		if modal_paused and not _hero_subtree_paused:
			_hero_subtree_previous_mode = process_mode
			_hero_pause_started_msec = Time.get_ticks_msec()
			_hero_subtree_paused = true
			process_mode = Node.PROCESS_MODE_DISABLED
		elif not modal_paused and _hero_subtree_paused:
			_hero_paused_total_msec += Time.get_ticks_msec()-_hero_pause_started_msec
			process_mode = _hero_subtree_previous_mode
			_hero_subtree_paused = false
		if not battle_over: return
	_set_combat_physics_enabled(should_enable)

func _set_combat_physics_enabled(enabled: bool) -> void:
	if is_instance_valid(hero):
		if hero_player_mode and hero.player_weapons != null and hero.player_weapons.native_skills != null:
			hero.player_weapons.native_skills.set_paused(not enabled)
		if hero_player_mode and hero.player_weapons != null and hero.player_weapons.identity != null:
			hero.player_weapons.identity.set_paused(not enabled)
		hero.set_physics_process(enabled)
		if hero.has_method("set_alchemist_cauldron_runtime_paused"):
			hero.call(
				"set_alchemist_cauldron_runtime_paused",
				not enabled
			)

	for group_name in [
		"monsters",
		"exp_orbs",
		"heal_items",
		"hero_projectiles",
		"monster_projectiles",
		"hero_summon_projectiles",
	]:
		for node in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(node) and (not online_match_mode or node.get_viewport() == get_viewport()):
				node.set_physics_process(enabled)

	for summon_id in active_hero_summons:
		var summon = active_hero_summons.get(summon_id)
		if (
			is_instance_valid(summon)
			and bool(summon.get("active"))
		):
			summon.set_physics_process(enabled)

func get_demon_build_summary() -> String:
	if demon_build_counts.is_empty() and demon_special_augments.is_empty():
		return "아직 선택 없음"

	var names: PackedStringArray = []
	for raw_id in demon_build_counts.keys():
		var augment_id := String(raw_id)
		var stacks := int(demon_build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		names.append("%s Lv.%d" % [
			String(augment.get("name", augment_id)),
			stacks,
		])

	for raw_id in demon_special_augments:
		var augment_id := String(raw_id)
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		names.append("★ %s" % String(
			augment.get("name", augment_id)
		))

	return " · ".join(names)

func get_debug_balance_summary() -> String:
	var level_line := "[DEBUG] 마왕 Lv.%d · 레벨배율 HP x%.3f / ATK x%.3f / SPD x%.3f (cap x%.2f) · 대형몹 %.0f%%" % [
		demon_level,
		_get_demon_level_monster_hp_multiplier(),
		_get_demon_level_monster_damage_multiplier(),
		_get_demon_level_monster_speed_multiplier(),
		DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER,
		_get_giant_monster_summon_chance() * 100.0,
	]

	var augment_line := "신규소환 보정: 비용 x%.3f · SPD x%.3f · ATK x%.3f · OrcHP x%.3f · 거미둔화 x%.3f · 환급 %.0f%% · 분열 %.0f%%" % [
		summon_cost_multiplier,
		monster_speed_multiplier,
		monster_damage_multiplier,
		orc_hp_multiplier,
		spider_slow_duration_multiplier,
		death_refund_ratio * 100.0,
		slime_split_chance * 100.0,
	]

	var samples: Dictionary = {}
	for node in _get_active_monsters_snapshot():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue

		var current_hp_value = node.get("current_hp")
		if current_hp_value != null and int(current_hp_value) <= 0:
			continue

		var monster_type := String(node.get("monster_type"))
		if samples.has(monster_type):
			continue

		samples[monster_type] = "%s HP %d/%d · A%d · S%.1f" % [
			_get_catalog_monster_display_name(monster_type),
			int(node.get("current_hp")),
			int(node.get("max_hp")),
			int(node.get("attack_damage")),
			float(node.get("move_speed")),
		]

		if samples.size() >= MONSTER_CATALOG.get_ids().size():
			break

	var sample_parts: PackedStringArray = []
	for monster_id in MONSTER_CATALOG.get_ids():
		if samples.has(monster_id):
			sample_parts.append(String(samples[monster_id]))

	var sample_line := "생존 샘플: 없음"
	if not sample_parts.is_empty():
		sample_line = "생존 샘플: %s" % " | ".join(sample_parts)

	return "%s\n%s\n%s" % [level_line, augment_line, sample_line]

func _on_hero_died() -> void:
	if is_instance_valid(hero):
		battle_entity_registry.retire_instance(hero.get_instance_id())
	if online_match_mode:
		if not battle_over: _finish_battle("마왕 승리 · 용사 처치",true,&"defeat")
		return
	if practice_mode or tutorial_mode:
		return
	if battle_over:
		return
	if hero_player_mode:
		_finish_battle("용사 패배 · 군단의 포위를 뚫지 못했습니다.",false,&"defeat")
		return

	_emit_stats(0)

	var stage_number: int = int(current_stage_data.get("number", 1))
	var stage_name: String = String(current_stage_data.get("display_name", "스테이지"))
	var hero_name: String = String(current_hero_profile.get("display_name", "용사"))
	var next_stage_id: String = String(current_stage_data.get("next_stage_id", ""))
	var next_stage_data: Dictionary = STAGE_CATALOG.get_stage(next_stage_id)
	var next_stage_number := 0
	if not next_stage_data.is_empty():
		next_stage_number = int(next_stage_data.get("number", 0))

	var first_clear_reward: int = int(
		current_stage_data.get("first_clear_reward", 0)
	)
	var clear_result: Dictionary = STAGE_PROGRESS.complete_hard_stage(current_stage_id) if campaign_difficulty == "hard" else STAGE_PROGRESS.complete_stage(
		current_stage_id,
		stage_number,
		next_stage_id,
		next_stage_number,
		first_clear_reward
	)

	var result_text := "Stage %d 클리어!\n%s · %s 처치 성공." % [
		stage_number,
		stage_name,
		hero_name,
	]
	if campaign_difficulty == "hard": result_text += "\n어려움 클리어 완료" if bool(clear_result.get("success",false)) else "\n어려움 클리어 저장 실패"
	var granted_reward: int = int(clear_result.get("reward", 0))
	if granted_reward > 0:
		result_text += "\n최초 클리어 보상 · 연구 포인트 +%d" % granted_reward
	if not bool(clear_result.get("success", false)):
		result_text += "\n클리어 보상 저장 실패"
	var first_gold := int(clear_result.get("gold_reward", 0))
	if first_gold > 0:
		result_text += "\n최초 클리어 골드 +%d" % first_gold
	var all_clear_gold := int(clear_result.get("easy_all_clear_gold", 0))
	if all_clear_gold > 0:
		result_text += "\n쉬움 전체 클리어 골드 +%d" % all_clear_gold

	var campaign_reward: Dictionary = clear_result.get("campaign_reward",{})
	if not campaign_reward.is_empty():
		if bool(campaign_reward.get("unlocked",false)): result_text += "\n군단 해금 · %s\n팀편성에서 바로 사용할 수 있습니다." % String(campaign_reward.name)
		elif int(campaign_reward.get("research",0)) > 0: result_text += "\n군단 보상 · %s → 연구 포인트 +%d" % [String(campaign_reward.name),int(campaign_reward.research)]
		else: result_text += "\n군단 보상 · %s 조각 +%d" % [String(campaign_reward.name),int(campaign_reward.get("shards",0))]
	result_text += _grant_run_research_reward(true)
	_finish_battle(result_text, true, &"defeat")

func _on_run_time_up() -> void:
	if online_match_mode:
		if not battle_over: _finish_battle("용사 승리 · 제한시간 생존",false,&"victory")
		return
	if practice_mode or tutorial_mode:
		return
	if battle_over:
		return
	if hero_player_mode:
		pass # The hero director spawns a final boss; time alone never clears.
		return

	var hero_name := String(current_hero_profile.get("display_name", "용사"))
	var result_text := "시간 초과!\n%s가 제한시간을 버텨냈습니다." % hero_name
	result_text += _grant_run_research_reward(false)
	_finish_battle(result_text, false, &"victory")

func finish_abandoned_run() -> bool:
	if battle_over:
		return true
	if hero_player_mode:
		_finish_battle("용사 도전 중단",false)
		return true
	var reward_text := _grant_run_research_reward(false)
	if _run_reward_save_failed:
		return false # Stay in the current run so a failed save can be retried.
	if reward_text.is_empty() and not practice_mode and not tutorial_mode:
		reward_text = "\n기여 보상 조건: 전투 30초 이상 · 소환 비용 3 이상 · 실제 피해 발생"
	_finish_battle("전투 중단 · 기여 보상 정산"+reward_text, false)
	return true

func _grant_run_research_reward(apply_clear_multiplier: bool) -> String:
	if online_match_mode: return ""
	_run_reward_save_failed = false
	if _run_reward_granted:
		return ""
	if practice_mode or tutorial_mode:
		return ""
	var hero_level := 1
	if is_instance_valid(hero):
		hero_level = maxi(int(hero.get("level")), 1)
	var breakdown: Dictionary
	if apply_clear_multiplier:
		breakdown = run_metrics.get_research_reward_breakdown(true, demon_level, hero_level, STAGE_CATALOG.RUN_REWARD_RULES)
	else:
		breakdown = run_metrics.get_partial_reward_breakdown(demon_level, hero_level, STAGE_CATALOG.RUN_REWARD_RULES)
	var base_total := int(breakdown.get("total", 0))
	if base_total <= 0:
		return ""

	var stage_multiplier := 1.0
	if apply_clear_multiplier:
		stage_multiplier = maxf(
			float(current_stage_data.get("run_reward_multiplier", 1.0)),
			0.0
		)
	var requested := maxi(int(round(float(base_total) * stage_multiplier)), 0)
	if requested <= 0:
		return ""

	var gold_ratio := float(STAGE_CATALOG.RUN_REWARD_RULES.get("combat_gold_ratio", 0.60))
	var gold_reward := maxi(int(floor(float(requested) * gold_ratio)), 0)
	var grant_result: Dictionary = STAGE_PROGRESS.add_research_points(requested, gold_reward)
	var granted := int(grant_result.get("granted", 0))
	if granted <= 0:
		_run_reward_save_failed = true
		return "\nRun 연구 보상 저장 실패"
	_run_reward_granted = true

	if apply_clear_multiplier:
		return (
			"\nRun 연구 +%d · 산정 %d × Stage %.2f\nRun 골드 +%d · 전투 연구 보상의 60%%%s"
			% [granted, base_total, stage_multiplier, int(grant_result.get("gold_granted", 0)), _format_run_reward_detail(breakdown)]
		)
	return "\nRun 연구 +%d · 전투 기여 %.0f%% 정산\nRun 골드 +%d · 전투 연구 보상의 60%%%s" % [
		granted,
		float(breakdown.get("partial_ratio", 0.35))*100.0,
		int(grant_result.get("gold_granted", 0)),
		_format_run_reward_detail(breakdown),
	]

func _format_run_reward_detail(breakdown: Dictionary) -> String:
	var prefix := "\n아래 항목은 기여 비율 적용 전 산정입니다." if bool(breakdown.get("partial", false)) else ""
	return prefix+(
		"\n기본 +%d · 피해 +%d · 마왕Lv +%d · 용사Lv +%d"
		+ " · 소환 +%d · 신속 +%d (남은 시간 %.0f%%) · 관찰/전환 +%d"
	) % [
		int(breakdown.get("base", 0)) + int(breakdown.get("victory", 0)),
		int(breakdown.get("damage", 0)),
		int(breakdown.get("demon_level", 0)),
		int(breakdown.get("hero_level", 0)),
		int(breakdown.get("summon", 0)),
		int(breakdown.get("remaining_time", 0)),
		float(breakdown.get("clear_time_ratio", 0.0))*100.0,
		int(breakdown.get("observation", 0))
		+ int(breakdown.get("strategy", 0)),
	]

func get_run_analysis_summary() -> String:
	var lines: PackedStringArray = []
	lines.append(run_metrics.get_result_summary())
	lines.append("")
	lines.append("마왕 최종 Lv.%d" % demon_level)

	var normal_parts: PackedStringArray = []
	for raw_id in demon_build_counts.keys():
		var augment_id := String(raw_id)
		var level := int(demon_build_counts.get(augment_id, 0))
		if level <= 0:
			continue
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		normal_parts.append("%s Lv.%d" % [
			String(augment.get("name", augment_id)),
			level,
		])
	if normal_parts.is_empty():
		lines.append("일반증강: 없음")
	else:
		lines.append("일반증강: %s" % " · ".join(normal_parts))

	var special_parts: PackedStringArray = []
	for raw_id in demon_special_augments:
		var augment_id := String(raw_id)
		var augment := DEMON_AUGMENTS.get_augment(augment_id)
		special_parts.append(
			String(augment.get("name", augment_id))
		)
	if special_parts.is_empty():
		lines.append("특수증강: 없음")
	else:
		lines.append("특수증강: %s" % " · ".join(special_parts))

	return "\n".join(lines)

func _finish_battle(message: String, player_won: bool, hero_outcome: StringName = &"") -> void:
	if battle_over: return
	MONSTER_CATALOG.release_warm(get_instance_id())
	if _mission_service != null:
		_mission_service.flush()
	battle_over = true
	demon_augment_selection_active = false
	flow_pause_manager.reset()
	_sync_combat_pause_state()
	if hero_outcome != &"":
		hero_outcome_confirmed.emit(hero_outcome)
	battle_finished.emit(message, player_won)

func _record_mission_action(event: String, amount: float) -> void:
	if _mission_service != null and not hero_player_mode and not practice_mode and not tutorial_mode and not LocalTestMode.active:
		_mission_service.record(event, amount)

func _exit_tree() -> void:
	MONSTER_CATALOG.release_warm(get_instance_id())
	if is_instance_valid(_mission_service):
		_mission_service.flush()

func _emit_stats(hero_hp_override: int = -1) -> void:
	var hp := 0
	var max_hp_value := 0

	if is_instance_valid(hero):
		hp = int(hero.get("current_hp"))
		max_hp_value = int(hero.get("max_hp"))

	if hero_hp_override >= 0:
		hp = hero_hp_override

	stats_changed.emit(hp, max_hp_value, monsters_alive)

func _emit_progression() -> void:
	if not is_instance_valid(hero):
		return

	progression_changed.emit(
		int(hero.get("level")),
		int(hero.get("current_exp")),
		int(hero.get("exp_to_next_level"))
	)

func get_hero_skill_cooldown_hud() -> Array:
	if (
		not is_instance_valid(hero)
		or not hero.has_method("get_skill_cooldown_hud")
	):
		return []

	var raw_skill_cooldowns = hero.call(
		"get_skill_cooldown_hud"
	)
	return (
		raw_skill_cooldowns
		if raw_skill_cooldowns is Array
		else []
	)


func get_command_hud_state() -> Vector2:
	return Vector2(command_power, max_command)


func get_demon_ultimate_hud_state(skill_id: String = "") -> Dictionary:
	return {
		"charge": demon_ultimate_charge,
		"max": DEMON_ULTIMATES.CHARGE_MAX,
		"ready": (
			demon_ultimate_charge + 0.001
			>= demon_ultimate_cheapest_cost
		),
		"cooldown": (
			float(demon_ultimate_cooldowns.get(skill_id, 0.0))
			if not skill_id.is_empty()
			else 0.0
		),
	}


func get_demon_reroll_max() -> int:
	return demon_reroll_max


func get_hero_info_hud() -> Dictionary:
	if not is_instance_valid(hero):
		return {}

	var hp := int(hero.get("current_hp"))
	var max_hp_value := int(hero.get("max_hp"))
	var runtime_info_stats: Dictionary = {}
	if hero.has_method("get_runtime_info_stats"):
		var raw_runtime_info = hero.call("get_runtime_info_stats")
		if typeof(raw_runtime_info) == TYPE_DICTIONARY:
			runtime_info_stats = raw_runtime_info

	var hero_build_counts: Dictionary = {}
	var raw_build_counts = hero.get("build_counts")
	if typeof(raw_build_counts) == TYPE_DICTIONARY:
		hero_build_counts = Dictionary(raw_build_counts).duplicate(true)

	max_hp_value = int(
		runtime_info_stats.get("max_hp", max_hp_value)
	)
	var hero_execute_ratio := (
		float(
			Dictionary(
				current_hero_profile.get("ultimate", {})
			).get("execute_hp_ratio", 0.0)
		)
		+ float(hero.get("rogue_execute_threshold_bonus"))
	)
	var hero_slash_shield_ratio := (
		float(
			Dictionary(
				current_hero_profile.get("rogue_slash_skill", {})
			).get("shield_hp_ratio", 0.0)
		)
		+ float(hero.get("rogue_slash_shield_ratio_bonus"))
	)

	return {
		"hero_name": String(
			current_hero_profile.get("display_name", "견습 마도사")
		),
		"hero_archetype": String(
			current_hero_profile.get("archetype", "ranged_kiter")
		),
		"hero_portrait_path": String(
			current_stage_data.get("portrait_path", "")
		),
		"hero_hp": hp,
		"hero_max_hp": max_hp_value,
		"hero_level": int(hero.get("level")),
		"hero_attack_damage": int(
			runtime_info_stats.get(
				"attack_damage",
				hero.get("attack_damage")
			)
		),
		"hero_move_speed": float(
			runtime_info_stats.get(
				"move_speed",
				hero.get("move_speed")
			)
		),
		"hero_attack_cooldown": float(
			runtime_info_stats.get(
				"attack_interval",
				hero.get("attack_cooldown")
			)
		),
		"hero_attack_range": float(
			runtime_info_stats.get(
				"attack_range",
				hero.get("attack_range")
			)
		),
		"hero_projectile_speed": float(
			runtime_info_stats.get(
				"projectile_speed",
				hero.get("projectile_speed")
			)
		),
		"hero_lifesteal_ratio": float(
			hero.get("rogue_lifesteal_ratio")
		),
		"hero_execute_ratio": hero_execute_ratio,
		"hero_slash_shield_ratio": hero_slash_shield_ratio,
		"hero_build_counts": hero_build_counts,
		"hero_recent_offense": (
			String(hero.call("get_recent_offense_summary"))
			if hero.has_method("get_recent_offense_summary")
			else "최근 공세 기록 없음"
		),
		"hero_ai_observation": (
			String(hero.call("get_ai_observation_summary"))
			if hero.has_method("get_ai_observation_summary")
			else "AI 관측 정보 없음"
		),
	}


func get_snapshot() -> Dictionary:
	var hp := 0
	var max_hp_value := 0
	var level := 1
	var current_exp := 0
	var exp_to_next_level := 50
	var build_summary := "아직 선택 없음"
	var hero_build_counts: Dictionary = {}
	var hero_attack_damage := 0
	var hero_move_speed := 0.0
	var hero_attack_cooldown := 0.0
	var hero_attack_range := 0.0
	var hero_projectile_speed := 0.0
	var hero_lifesteal_ratio := 0.0
	var hero_execute_ratio := 0.0
	var hero_slash_shield_ratio := 0.0
	var hero_skill_cooldowns: Array = []

	if is_instance_valid(hero):
		hp = int(hero.get("current_hp"))
		max_hp_value = int(hero.get("max_hp"))
		level = int(hero.get("level"))
		current_exp = int(hero.get("current_exp"))
		exp_to_next_level = int(hero.get("exp_to_next_level"))

		var runtime_info_stats: Dictionary = {}
		if hero.has_method("get_runtime_info_stats"):
			var raw_runtime_info = hero.call("get_runtime_info_stats")
			if typeof(raw_runtime_info) == TYPE_DICTIONARY:
				runtime_info_stats = raw_runtime_info

		hero_attack_damage = int(
			runtime_info_stats.get("attack_damage", hero.get("attack_damage"))
		)
		hero_move_speed = float(
			runtime_info_stats.get("move_speed", hero.get("move_speed"))
		)
		hero_attack_cooldown = float(
			runtime_info_stats.get("attack_interval", hero.get("attack_cooldown"))
		)
		hero_attack_range = float(
			runtime_info_stats.get("attack_range", hero.get("attack_range"))
		)
		hero_projectile_speed = float(
			runtime_info_stats.get("projectile_speed", hero.get("projectile_speed"))
		)
		max_hp_value = int(
			runtime_info_stats.get("max_hp", max_hp_value)
		)
		hero_lifesteal_ratio = float(hero.get("rogue_lifesteal_ratio"))
		hero_execute_ratio = (
			float(
				Dictionary(
					current_hero_profile.get("ultimate", {})
				).get("execute_hp_ratio", 0.0)
			)
			+ float(hero.get("rogue_execute_threshold_bonus"))
		)
		hero_slash_shield_ratio = (
			float(
				Dictionary(
					current_hero_profile.get("rogue_slash_skill", {})
				).get("shield_hp_ratio", 0.0)
			)
			+ float(hero.get("rogue_slash_shield_ratio_bonus"))
		)
		var raw_build_counts = hero.get("build_counts")
		if typeof(raw_build_counts) == TYPE_DICTIONARY:
			hero_build_counts = Dictionary(raw_build_counts).duplicate(true)
		if hero.has_method("get_build_summary"):
			build_summary = String(hero.call("get_build_summary"))
		if hero.has_method("get_skill_cooldown_hud"):
			var raw_skill_cooldowns = hero.call("get_skill_cooldown_hud")
			if typeof(raw_skill_cooldowns) == TYPE_ARRAY:
				hero_skill_cooldowns = Array(raw_skill_cooldowns).duplicate(true)

	return {
		"stage_id": String(current_stage_data.get("id", current_stage_id)),
		"stage_number": int(current_stage_data.get("number", 1)),
		"stage_name": String(current_stage_data.get("display_name", "첫 번째 침입자")),
		"hero_id": String(current_hero_profile.get("id", "ranged_rookie")),
		"hero_name": String(current_hero_profile.get("display_name", "견습 마도사")),
		"hero_archetype": String(current_hero_profile.get("archetype", "ranged_kiter")),
		"hero_hp": hp,
		"hero_max_hp": max_hp_value,
		"hero_level": level,
		"hero_exp": current_exp,
		"hero_exp_to_next": exp_to_next_level,
		"hero_build_summary": build_summary,
		"hero_build_counts": hero_build_counts,
		"hero_attack_damage": hero_attack_damage,
		"hero_move_speed": hero_move_speed,
		"hero_attack_cooldown": hero_attack_cooldown,
		"hero_attack_range": hero_attack_range,
		"hero_projectile_speed": hero_projectile_speed,
		"hero_lifesteal_ratio": hero_lifesteal_ratio,
		"hero_execute_ratio": hero_execute_ratio,
		"hero_slash_shield_ratio": hero_slash_shield_ratio,
		"hero_skill_cooldowns": hero_skill_cooldowns,
		"hero_portrait_path": String(
			current_stage_data.get("portrait_path", "")
		),
		"hero_recent_offense": (
			String(hero.call("get_recent_offense_summary"))
			if is_instance_valid(hero) and hero.has_method("get_recent_offense_summary")
			else "최근 공세 기록 없음"
		),
		"hero_ai_observation": (
			String(hero.call("get_ai_observation_summary"))
			if is_instance_valid(hero) and hero.has_method("get_ai_observation_summary")
			else "AI 관측 정보 없음"
		),
		"monsters_left": monsters_alive,
		"command_power": command_power,
		"command_max": max_command,
		"demon_level": demon_level,
		"demon_exp": demon_exp,
		"giant_monster_chance": _get_giant_monster_summon_chance(),
		"demon_exp_to_next": demon_exp_to_next_level,
		"demon_ultimate_charge": demon_ultimate_charge,
		"demon_ultimate_max": DEMON_ULTIMATES.CHARGE_MAX,
		"demon_ultimate_ready": demon_ultimate_charge + 0.001 >= 40.0,
		"demon_ultimate_cooldowns": demon_ultimate_cooldowns.duplicate(true),
		"demon_rerolls_left": demon_rerolls_left,
		"demon_reroll_max": demon_reroll_max,
		"demon_build_summary": get_demon_build_summary(),
		"demon_build_counts": demon_build_counts.duplicate(true),
		"demon_special_augments": demon_special_augments.duplicate(),
		"demon_active_augment_level": demon_active_augment_level,
		"mutation_selection_active": mutation_director.is_active(),
		"mutation_candidates": mutation_director.get_candidates(),
		"flow_pause_requests": flow_pause_manager.get_snapshot(),
		"run_timer_paused": flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_RUN_TIMER
		),
		"stage_event_fired_ids": stage_director.get_fired_event_ids(),
		"debug_balance_summary": get_debug_balance_summary(),
		"permanent_research_summary": get_permanent_research_summary(),
		"research_points": STAGE_PROGRESS.get_research_points(),
		"map_width": current_map_size.x,
		"map_height": current_map_size.y,
		"run_elapsed_seconds": run_metrics.elapsed_seconds,
		"run_duration_seconds": run_time_limit_seconds,
		"run_remaining_seconds": run_metrics.get_remaining_seconds(),
		"run_metrics": run_metrics.get_snapshot(),
		"next_stage_id": String(current_stage_data.get("next_stage_id", "")),
		"battle_over": battle_over,
	}

var _network_pause_started_msec := 0
var _network_paused_total_msec := 0
var _network_paused := false

func set_network_pause(paused: bool) -> void:
	if paused and not _network_paused:
		_network_pause_started_msec = Time.get_ticks_msec()
	elif not paused and _network_paused:
		_network_paused_total_msec += Time.get_ticks_msec() - _network_pause_started_msec
	_network_paused = paused
	if paused:
		flow_pause_manager.request_pause("cloud_connection", FULL_MODAL_PAUSE_DOMAINS)
	else:
		flow_pause_manager.release_pause("cloud_connection")
	_sync_combat_pause_state()


func set_external_pause(paused: bool) -> void:
	external_pause = paused

	if paused:
		flow_pause_manager.request_pause(
			PAUSE_REASON_EXTERNAL,
			FULL_MODAL_PAUSE_DOMAINS
		)
	else:
		flow_pause_manager.release_pause(PAUSE_REASON_EXTERNAL)

	_sync_combat_pause_state()


func _on_hero_conditional_skill_unlocked(
	skill_id: String,
	skill_name: String,
	payload: Dictionary
) -> void:
	conditional_skill_unlocked.emit(
		skill_id,
		skill_name,
		payload.duplicate(true)
	)

func can_go_to_next_stage() -> bool:
	var next_stage_id: String = String(current_stage_data.get("next_stage_id", ""))
	if next_stage_id.is_empty():
		return false

	var next_stage_data: Dictionary = STAGE_CATALOG.get_stage(next_stage_id)
	if next_stage_data.is_empty():
		return false

	return STAGE_PROGRESS.is_stage_unlocked(int(next_stage_data.get("number", 999)))

func go_to_next_stage() -> bool:
	if not can_go_to_next_stage():
		return false

	var next_stage_id: String = String(current_stage_data.get("next_stage_id", ""))
	STAGE_PROGRESS.set_current_stage(next_stage_id)
	return true

func _draw() -> void:
	# Stages 1~10 use the Demon Castle battlefield. Only non-castle stages keep
	# the legacy debug field.
	if not _uses_castle_battlefield(current_stage_id):
		draw_rect(
			Rect2(Vector2.ZERO, current_map_size),
			Color(0.075, 0.085, 0.105),
			true
		)

		var grid_spacing := 320.0
		var grid_color := Color(0.105, 0.12, 0.145)
		var x := grid_spacing
		while x < current_map_size.x:
			draw_line(
				Vector2(x, 0),
				Vector2(x, current_map_size.y),
				grid_color,
				2.0
			)
			x += grid_spacing

		var y := grid_spacing
		while y < current_map_size.y:
			draw_line(
				Vector2(0, y),
				Vector2(current_map_size.x, y),
				grid_color,
				2.0
			)
			y += grid_spacing

		draw_rect(
			Rect2(Vector2.ZERO, current_map_size),
			Color(0.34, 0.39, 0.48),
			false,
			8.0
		)

		var center := current_map_size * 0.5
		draw_circle(
			center,
			92.0,
			Color(0.1, 0.12, 0.15),
			false,
			3.0
		)
		draw_line(
			center + Vector2(0, -110),
			center + Vector2(0, 110),
			Color(0.15, 0.18, 0.22),
			2.0
		)
		draw_line(
			center + Vector2(-110, 0),
			center + Vector2(110, 0),
			Color(0.15, 0.18, 0.22),
			2.0
		)

	if manual_spawn_warning_timer > 0.0 and is_instance_valid(hero):
		var warning_alpha := clampf(
			manual_spawn_warning_timer / MANUAL_SPAWN_WARNING_DURATION,
			0.0,
			1.0
		)
		var warning_center := hero.position
		draw_circle(
			warning_center,
			MANUAL_SPAWN_HERO_MIN_DISTANCE,
			Color(1.0, 0.18, 0.16, 0.08 * warning_alpha),
			true
		)
		draw_circle(
			warning_center,
			MANUAL_SPAWN_HERO_MIN_DISTANCE,
			Color(1.0, 0.32, 0.24, 0.78 * warning_alpha),
			false,
			6.0
		)

# First-account practice uses real summon/choice APIs, with the simulation and
# natural event timer paused. No practice action clears stages or grants rewards.
func begin_tutorial_practice() -> void:
	tutorial_mode = true
	flow_pause_manager.request_pause("tutorial_practice", [
		FLOW_PAUSE_MANAGER.DOMAIN_COMBAT,
		FLOW_PAUSE_MANAGER.DOMAIN_RUN_TIMER,
		FLOW_PAUSE_MANAGER.DOMAIN_STAGE_EVENTS,
		FLOW_PAUSE_MANAGER.DOMAIN_DEMON_RUNTIME,
	])
	_sync_combat_pause_state()

func open_tutorial_augment(special: bool) -> void:
	if not tutorial_mode or demon_augment_selection_active or battle_over:
		return
	demon_pending_augments = 1
	demon_pending_augment_levels.assign([10 if special else 2])
	_open_next_demon_augment_if_needed()

func open_tutorial_elite() -> void:
	if not tutorial_mode or mutation_director.is_active() or battle_over:
		return
	var events: Array = current_stage_data.get("event_timeline", [])
	for event in events:
		if String(event.get("type", "")) == "elite":
			_open_mutation_choice(event.duplicate(true))
			return


func _apply_augment_free_base_stats(monster: Node, monster_id: String) -> void:
	if TRANSCENDENCE_DATA.is_transcendent(monster_id):
		return # Snapshot stats and transcendence abilities have their own rules.
	if bool(monster.get_meta("fixed_base_stats", false)):
		# Skill reinforcements keep level-zero catalog stats for their lifetime.
		# Preserve spawn accounting such as split-child EXP instead of resetting it.
		var base_stats := MONSTER_CATALOG.get_base_stats(monster_id)
		for stat in base_stats:
			if stat != "exp_reward" and monster.get(stat) != null:
				var value = base_stats[stat]
				if hero_player_mode and HERO_SURVIVAL.MONSTER_SCALE_FIELDS.has(stat):
					value = float(value)*_hero_survival_multiplier(String(HERO_SURVIVAL.MONSTER_SCALE_FIELDS[stat]),float(monster.get_meta("hero_survival_spawn_seconds",0.0)))
					if stat != "move_speed": value = maxi(1,roundi(value))
				monster.set(stat, value)
		monster.set_meta("monster_collection_upgrade_level", 0)
		monster.set("current_hp", int(monster.get("max_hp")))
		return
	var rarity := MONSTER_CATALOG.get_rarity_combat_profile(monster_id)
	monster.set_meta("demon_level_base_max_hp",
		float(monster.get_meta("augment_raw_max_hp"))
		* float(rarity.get("hp_multiplier", 1.0))
		* _get_augment_free_research_multiplier("monster_vitality", 0.01)
		* _get_monster_collection_upgrade_multiplier(monster_id, "hp_per_level")
	)
	monster.set_meta("demon_level_base_attack_damage",
		float(monster.get_meta("augment_raw_attack_damage"))
		* float(rarity.get("damage_multiplier", 1.0))
		* _get_augment_free_research_multiplier("monster_power", 0.01)
		* _get_monster_collection_upgrade_multiplier(monster_id, "damage_per_level")
	)
	monster.set_meta("demon_level_base_move_speed",
		float(monster.get_meta("augment_raw_move_speed"))
		* float(rarity.get("move_speed_multiplier", 1.0))
		* _get_augment_free_research_multiplier("monster_mobility", 0.0035)
	)
	monster.set("attack_cooldown",
		float(monster.get_meta("augment_raw_attack_cooldown"))
		* float(rarity.get("attack_cooldown_multiplier", 1.0))
		/ _get_augment_free_research_multiplier("monster_attack_speed", 0.005)
	)
	_apply_demon_level_scaling_to_monster(monster, false)
	monster.set("current_hp", int(monster.get("max_hp")))


func _get_augment_free_research_multiplier(research_id: String, per_point: float) -> float:
	return 1.0 + per_point * RESEARCH_CATALOG.get_effective_level_points(
		research_id, int(permanent_research_levels.get(research_id, 0))
	)

# Reusable output; only active enemy summons, never inactive preallocated pools.
func fill_active_enemy_summons(result: Array) -> void:
	result.clear()
	for id in active_hero_summons:
		var actor: Node2D = active_hero_summons[id]
		if is_instance_valid(actor) and not actor.is_queued_for_deletion() and bool(actor.get("active")) and int(actor.get("current_hp")) > 0:
			result.append(actor)


func configure_campaign_difficulty(difficulty: String) -> void:
	if difficulty != "hard" or campaign_difficulty == "hard" or hero_player_mode or practice_mode or tutorial_mode: return
	if not STAGE_PROGRESS.is_stage_cleared(current_stage_id): return
	campaign_difficulty = "hard"
	if is_instance_valid(hero):
		hero.max_hp = roundi(hero.max_hp*1.6); hero.current_hp = hero.max_hp
		hero.attack_damage = roundi(hero.attack_damage*1.35); hero.move_speed *= 1.08
		hero.health_changed.emit(hero.current_hp,hero.max_hp)
		run_metrics.reset(run_time_limit_seconds,hero.current_hp,hero.max_hp)

func _is_reserved_hero_boss_request(_id: String,modifiers: Dictionary) -> bool:
	return hero_player_mode and not online_match_mode and _hero_boss_spawn_pending and not hero_final_boss_spawned and not battle_over and run_metrics.elapsed_seconds >= HERO_SURVIVAL.DURATION and bool(modifiers.get("hero_final_boss_spawn",false))

func spawn_hero_encounter(id: String, point: Vector2, modifiers: Dictionary) -> Node2D:
	if not hero_player_mode or battle_over or not HERO_SURVIVAL.monster_allowed(id,int(current_stage_data.get("number",1)),campaign_difficulty): return null
	var is_boss := String(modifiers.get("type","")) == "boss"
	if is_boss and (hero_final_boss_spawned or _hero_boss_spawn_pending or run_metrics.elapsed_seconds < HERO_SURVIVAL.DURATION): return null
	if not is_boss:
		id = hero_spawn_candidate(id,hero_control_roster,true)
		if id.is_empty(): return null
	point = _clamp_manual_spawn_position(point)
	if active_monsters.size() >= HERO_SURVIVAL.monster_limit(int(current_stage_data.get("number",1)))+(1 if is_boss else 0) or point.distance_squared_to(hero.position) < 180.0*180.0: return null
	_hero_boss_spawn_pending = is_boss
	var monster = _spawn_monster(id,point,0.0,false,{"elite_variant":true,"counts_population":true,"hero_encounter_position_locked":true,"hero_final_boss_spawn":is_boss})
	_hero_boss_spawn_pending = false
	if not is_instance_valid(monster): return null
	_apply_special_monster_modifiers(monster,id,modifiers)
	if is_boss:
		hero_final_boss_spawned = true
		monster.set_meta("hero_final_boss",true)
		if modifiers.has("target_hp"):
			monster.max_hp = int(modifiers.target_hp); monster.current_hp = monster.max_hp
			monster.set_meta("demon_level_base_max_hp",float(monster.max_hp)/_get_demon_level_monster_hp_multiplier(run_metrics.elapsed_seconds))
		if modifiers.has("target_damage"):
			monster.attack_damage = int(modifiers.target_damage)
			monster.set_meta("demon_level_base_attack_damage",float(monster.attack_damage)/_get_demon_level_monster_damage_multiplier(run_metrics.elapsed_seconds))
	return monster
func _finish_hero_boss_victory() -> void:
	if hero_player_mode and run_metrics.elapsed_seconds >= HERO_SURVIVAL.DURATION and not battle_over and is_instance_valid(hero) and hero.current_hp > 0:
		_finish_battle("용사 승리 · 최종 보스를 처치했습니다!",true,&"victory")

func finish_hero_boss_timeout() -> void:
	if not hero_player_mode or battle_over: return
	_finish_battle("패배 · 최종 보스 제한시간 5분을 초과했습니다.",false,&"defeat")
