extends Node2D

signal stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal hero_leveled_up(new_level: int)
signal hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal command_changed(current_value: float, max_value: float)
signal summon_result(monster_type: String, success: bool, message: String)
signal demon_progression_changed(level: int, current_exp: float, exp_to_next_level: float)
signal demon_augment_ready(candidates: Array, rerolls_left: int, demon_level: int)
signal demon_augment_applied(augment_name: String, build_summary: String)
signal demon_ultimate_changed(current_value: float, max_value: float, ready: bool)
signal demon_ultimate_cooldowns_changed(cooldowns: Dictionary)
signal demon_ultimate_used(skill_id: String, skill_name: String, message: String)
signal stage_event_triggered(event_type: String, event_name: String, message: String)
signal mutation_choice_ready(event_data: Dictionary, candidates: Array)
signal mutation_selected(event_type: String, mutation_name: String)
signal mutation_spawn_result(success: bool, message: String)
signal run_time_changed(elapsed_seconds: float, remaining_seconds: float)
signal battle_finished(message: String, player_won: bool)

const HERO_SCENE := preload("res://src/hero/Hero.tscn")
const EXP_ORB_SCENE := preload("res://src/battle/ExpOrb.tscn")
const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const HERO_AI_PROFILES := preload("res://src/data/hero_ai_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const DEMON_ULTIMATES := preload("res://src/data/demon_ultimate_catalog.gd")
const RESEARCH_CATALOG := preload("res://src/data/research_catalog.gd")
const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const RUN_METRICS := preload("res://src/systems/run_metrics.gd")
const STAGE_DIRECTOR := preload("res://src/systems/stage_director.gd")
const MUTATION_DIRECTOR := preload("res://src/systems/mutation_director.gd")
const FLOW_PAUSE_MANAGER := preload("res://src/systems/flow_pause_manager.gd")

const DEFAULT_MAP_SIZE := Vector2(3200, 3200)
const AUTO_SPAWN_MIN_DISTANCE := 560.0
const AUTO_SPAWN_MAX_DISTANCE := 720.0

const BASE_MAX_COMMAND := 100.0
const START_COMMAND := 0.0
const BASE_COMMAND_REGEN_PER_SECOND := 3.0
const MANUAL_SPAWN_MARGIN := 70.0
const MANUAL_SPAWN_HERO_MIN_DISTANCE := 220.0
const MANUAL_SPAWN_WARNING_DURATION := 0.70
const DEMON_BASE_EXP_TO_NEXT := 15.0
const DEMON_EXP_GROWTH_PER_LEVEL := 4.0
const BASE_DEMON_REROLLS := 3
const DEMON_LEVEL_MONSTER_HP_GROWTH := 1.05
const DEMON_LEVEL_MONSTER_DAMAGE_GROWTH := 1.05
const DEMON_LEVEL_MONSTER_SPEED_GROWTH := 1.02
const DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER := 1.25


var hero: Node2D
var current_stage_id: String = "stage_1"
var current_stage_data: Dictionary = {}
var current_hero_profile: Dictionary = {}
var current_map_size: Vector2 = DEFAULT_MAP_SIZE
var run_time_limit_seconds: float = 0.0
var run_time_emit_timer: float = 0.0
var manual_spawn_warning_timer: float = 0.0
var run_metrics = RUN_METRICS.new()
var stage_director = STAGE_DIRECTOR.new()
var mutation_director = MUTATION_DIRECTOR.new()
var flow_pause_manager = FLOW_PAUSE_MANAGER.new()

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

var monsters_alive: int = 0
var battle_over: bool = false
var external_pause: bool = false

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
var last_hero_hp_for_ultimate: int = 0
var demon_ultimate_spawn_queue: Array[Dictionary] = []
var demon_ultimate_spawn_timer: float = 0.0
var demon_ultimate_spawn_interval: float = 0.04
var demon_ultimate_spawn_batch_size: int = 2
var demon_ultimate_cooldowns: Dictionary = {}
var demon_ultimate_cooldown_emit_timer: float = 0.0

var summon_cost_multiplier: float = 1.0
var demon_exp_gain_multiplier: float = 1.0
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

var monster_summon_costs: Dictionary = {}
var permanent_research_levels: Dictionary = {}

var allowed_monster_ids: Array = []
var loadout_restriction_enabled: bool = false

func _ready() -> void:
	queue_redraw()
	_start_battle()

func _process(delta: float) -> void:
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
		_process_demon_ultimate_spawn_queue(delta)
		_update_demon_ultimate_cooldowns(delta)

		if demon_ultimate_charge < DEMON_ULTIMATES.CHARGE_MAX:
			demon_ultimate_charge = minf(
				demon_ultimate_charge
				+ DEMON_ULTIMATES.PASSIVE_CHARGE_PER_SECOND * delta,
				DEMON_ULTIMATES.CHARGE_MAX
			)
			demon_ultimate_emit_timer -= delta
			if demon_ultimate_emit_timer <= 0.0:
				demon_ultimate_emit_timer = 0.10
				_emit_demon_ultimate_changed()

	if not flow_pause_manager.is_paused(
		FLOW_PAUSE_MANAGER.DOMAIN_RUN_TIMER
	):
		run_metrics.tick(delta)

		if not flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_STAGE_EVENTS
		):
			_process_stage_director_events()

		run_time_emit_timer -= delta
		if run_time_emit_timer <= 0.0:
			run_time_emit_timer = 0.25
			run_time_changed.emit(
				run_metrics.elapsed_seconds,
				run_metrics.get_remaining_seconds()
			)

		if run_metrics.is_time_up():
			_on_run_time_up()
			return

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

func _start_battle() -> void:
	battle_over = false
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
	last_hero_hp_for_ultimate = 0
	demon_ultimate_spawn_queue.clear()
	demon_ultimate_spawn_timer = 0.0
	demon_ultimate_spawn_interval = 0.04
	demon_ultimate_spawn_batch_size = 2
	demon_ultimate_cooldowns.clear()
	for skill_id in DEMON_ULTIMATES.get_ordered_ids():
		demon_ultimate_cooldowns[String(skill_id)] = 0.0
	demon_ultimate_cooldown_emit_timer = 0.0

	summon_cost_multiplier = 1.0
	demon_exp_gain_multiplier = 1.0
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
	mutation_director.reset()
	monster_summon_costs.clear()

	_apply_permanent_research()

	var progress_state: Dictionary = STAGE_PROGRESS.load_state()
	current_stage_id = String(progress_state.get("current_stage_id", "stage_1"))
	current_stage_data = STAGE_CATALOG.get_stage(current_stage_id)

	if current_stage_data.is_empty():
		current_stage_id = "stage_1"
		current_stage_data = STAGE_CATALOG.get_stage(current_stage_id)
		STAGE_PROGRESS.set_current_stage(current_stage_id)

	current_map_size = Vector2(
		float(current_stage_data.get("map_width", int(DEFAULT_MAP_SIZE.x))),
		float(current_stage_data.get("map_height", int(DEFAULT_MAP_SIZE.y)))
	)
	run_time_limit_seconds = maxf(
		float(current_stage_data.get("run_duration_seconds", 360.0)),
		60.0
	)
	stage_director.reset(current_stage_data)

	var hero_id: String = String(current_stage_data.get("hero_id", "ranged_rookie"))
	current_hero_profile = HERO_PROFILES.get_profile(hero_id)

	var hero_ai_profile_id := String(
		current_stage_data.get("hero_ai_profile_id", "")
	)
	var hero_ai_settings := HERO_AI_PROFILES.get_profile(hero_ai_profile_id)
	if not hero_ai_settings.is_empty():
		current_hero_profile["ai_settings"] = hero_ai_settings

	hero = HERO_SCENE.instantiate() as Node2D
	if hero.has_method("configure_profile"):
		hero.call("configure_profile", current_hero_profile)
	if hero.has_method("configure_battlefield"):
		hero.call("configure_battlefield", current_map_size)
	hero.set("level", int(current_stage_data.get("hero_level_start", 1)))

	add_child(hero)
	hero.position = current_map_size * 0.5
	last_hero_hp_for_ultimate = int(hero.get("current_hp"))

	run_metrics.reset(
		run_time_limit_seconds,
		int(hero.get("current_hp")),
		int(hero.get("max_hp"))
	)
	hero.connect("health_changed", Callable(self, "_on_hero_health_changed"))
	hero.connect("progression_changed", Callable(self, "_on_hero_progression_changed"))
	hero.connect("leveled_up", Callable(self, "_on_hero_leveled_up"))
	hero.connect("augment_selected", Callable(self, "_on_hero_augment_selected"))
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

	monster_damage_multiplier *= 1.0 + 0.01 * power_level
	monster_hp_multiplier *= 1.0 + 0.01 * vitality_level
	monster_speed_multiplier *= 1.0 + 0.0035 * mobility_level
	monster_attack_speed_multiplier *= (
		1.0 / (1.0 + 0.005 * attack_speed_level)
	)
	summon_cost_multiplier *= maxf(0.80, 1.0 - 0.01 * summon_level)
	command_regen_per_second += 0.15 * cycle_level
	max_command += 5.0 * reservoir_level
	demon_exp_gain_multiplier += 0.03 * experiment_level
	demon_reroll_max += notebook_level
	demon_rerolls_left = demon_reroll_max

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

func try_summon(monster_type: String) -> bool:
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

func try_summon_at_position(monster_type: String, spawn_position: Vector2) -> bool:
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

func _can_attempt_summon(monster_type: String) -> bool:
	if battle_over:
		summon_result.emit(monster_type, false, "전투가 종료되어 소환할 수 없습니다.")
		return false

	if external_pause:
		summon_result.emit(monster_type, false, "스테이지 메뉴를 닫은 뒤 소환해 주세요.")
		return false

	if demon_augment_selection_active:
		summon_result.emit(monster_type, false, "마왕 증강을 먼저 선택해 주세요.")
		return false

	if loadout_restriction_enabled and monster_type not in allowed_monster_ids:
		summon_result.emit(
			monster_type,
			false,
			"현재 팀에 편성되지 않은 몬스터입니다."
		)
		return false

	if get_monster_cost(monster_type) <= 0.0:
		summon_result.emit(monster_type, false, "알 수 없는 몬스터입니다.")
		return false

	return true

func _perform_summon(monster_type: String, spawn_position: Vector2, cost: float, manual: bool) -> bool:
	command_power = maxf(command_power - cost, 0.0)

	_spawn_monster(monster_type, spawn_position, cost, false)
	_spawn_extra_normal_summon_monsters(monster_type, spawn_position)
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
	var mode_text := "수동 배치" if manual else "소환"
	summon_result.emit(
		monster_type,
		true,
		"%s %s! 지휘력 %.1f 소모 · 마왕 EXP +%.1f" % [
			_get_monster_name(monster_type),
			mode_text,
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
	spawn_position: Vector2
) -> String:
	if not _is_spawn_position_inside_bounds(spawn_position):
		return "배치 불가\n전장 안쪽을 터치"

	if not _is_spawn_position_far_enough_from_hero(spawn_position):
		return "용사와 너무 가까움"

	var cost := get_monster_cost(monster_type)
	if cost <= 0.0:
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

func _is_spawn_position_inside_bounds(spawn_position: Vector2) -> bool:
	return (
		spawn_position.x >= MANUAL_SPAWN_MARGIN
		and spawn_position.x <= current_map_size.x - MANUAL_SPAWN_MARGIN
		and spawn_position.y >= MANUAL_SPAWN_MARGIN
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
		clampf(spawn_position.x, MANUAL_SPAWN_MARGIN, current_map_size.x - MANUAL_SPAWN_MARGIN),
		clampf(spawn_position.y, MANUAL_SPAWN_MARGIN, current_map_size.y - MANUAL_SPAWN_MARGIN)
	)

func get_monster_cost(monster_type: String) -> float:
	var base_cost: float = MONSTER_CATALOG.get_base_cost(monster_type)
	if base_cost <= 0.0:
		return 0.0

	var monster_cost_multiplier := _get_monster_augment_multiplier(
		monster_type,
		"cost"
	)
	return snappedf(
		base_cost * summon_cost_multiplier * monster_cost_multiplier,
		0.1
	)

func _get_auto_spawn_position() -> Vector2:
	var origin := current_map_size * 0.5
	if is_instance_valid(hero):
		origin = hero.position

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(AUTO_SPAWN_MIN_DISTANCE, AUTO_SPAWN_MAX_DISTANCE)
	var candidate := origin + Vector2.from_angle(angle) * distance

	return Vector2(
		clampf(candidate.x, MANUAL_SPAWN_MARGIN, current_map_size.x - MANUAL_SPAWN_MARGIN),
		clampf(candidate.y, MANUAL_SPAWN_MARGIN, current_map_size.y - MANUAL_SPAWN_MARGIN)
	)

func _spawn_monster(
	monster_type: String,
	spawn_position: Vector2,
	summon_cost: float = 0.0,
	split_child: bool = false,
	spawn_modifiers: Dictionary = {}
):
	var scene := MONSTER_CATALOG.get_scene(monster_type)
	if scene == null:
		push_warning("Unknown monster id: %s" % monster_type)
		return null

	var monster := scene.instantiate() as Node2D

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
				* monster_attack_speed_multiplier
				* _get_monster_augment_multiplier(
					monster_type,
					"attack_cooldown"
				)
			)
		)

	if monster_type == "bomb_rat":
		var fuse_value = monster.get("self_destruct_fuse")
		if fuse_value != null:
			monster.set(
				"self_destruct_fuse",
				maxf(
					0.10,
					float(fuse_value) * monster_attack_speed_multiplier
				)
			)

	var damage_value = monster.get("attack_damage")
	if damage_value != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(
				1.0,
				float(damage_value)
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_type, "damage")
			)
		)

	if monster_type == "bomb_rat":
		var explosion_damage_value = monster.get("explosion_damage")
		if explosion_damage_value != null:
			monster.set(
				"explosion_damage",
				maxi(
					1,
					int(round(
						float(explosion_damage_value)
						* monster_damage_multiplier
					))
				)
			)

	if monster_type == "spider":
		var slow_duration_value = monster.get("slow_duration")
		if slow_duration_value != null:
			monster.set(
				"slow_duration",
				float(slow_duration_value) * spider_slow_duration_multiplier
			)

	var max_hp_value = monster.get("max_hp")
	if max_hp_value != null:
		var level_base_hp := (
			float(max_hp_value)
			* monster_hp_multiplier
			* _get_monster_augment_multiplier(monster_type, "hp")
		)
		if monster_type == "orc":
			level_base_hp *= orc_hp_multiplier
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
	)
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

	add_child(monster)
	monster.position = spawn_position
	monster.set_meta("split_child", split_child)
	monster.set_meta(
		"spawn_source",
		"augment" if split_child else "normal"
	)
	_apply_special_augments_to_monster(monster, monster_type)
	monster.connect("died", Callable(self, "_on_monster_died").bind(monster))

	monster_summon_costs[monster.get_instance_id()] = summon_cost
	monsters_alive += 1
	return monster

func _get_demon_level_monster_hp_multiplier() -> float:
	var growth_steps := maxi(demon_level - 1, 0)
	return pow(DEMON_LEVEL_MONSTER_HP_GROWTH, float(growth_steps))

func _get_demon_level_monster_damage_multiplier() -> float:
	var growth_steps := maxi(demon_level - 1, 0)
	return pow(DEMON_LEVEL_MONSTER_DAMAGE_GROWTH, float(growth_steps))

func _get_demon_level_monster_speed_multiplier() -> float:
	var growth_steps := maxi(demon_level - 1, 0)
	return minf(
		pow(DEMON_LEVEL_MONSTER_SPEED_GROWTH, float(growth_steps)),
		DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER
	)

func _apply_demon_level_scaling_to_monster(
	monster: Node,
	preserve_hp_ratio: bool
) -> void:
	if not is_instance_valid(monster):
		return

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
				float(base_hp_value) * _get_demon_level_monster_hp_multiplier()
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
	)
	if base_damage_value != null:
		monster.set(
			"attack_damage",
			maxi(
				1,
				int(round(
					float(base_damage_value)
					* _get_demon_level_monster_damage_multiplier()
				))
			)
		)

	var base_speed_value = monster.get_meta(
		"demon_level_base_move_speed",
		null
	)
	if base_speed_value != null:
		monster.set(
			"move_speed",
			float(base_speed_value) * _get_demon_level_monster_speed_multiplier()
		)

	if preserve_hp_ratio and monster.has_method("queue_redraw"):
		monster.call("queue_redraw")

func _refresh_alive_monsters_for_demon_level() -> void:
	for node in get_tree().get_nodes_in_group("monsters"):
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

	if last_hero_hp_for_ultimate > current_hp:
		var dealt_damage := last_hero_hp_for_ultimate - current_hp
		_add_demon_ultimate_charge(
			float(dealt_damage)
			* DEMON_ULTIMATES.HERO_DAMAGE_CHARGE_MULTIPLIER
		)
	last_hero_hp_for_ultimate = current_hp

	stats_changed.emit(current_hp, max_hp_value, monsters_alive)

func _on_hero_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	progression_changed.emit(level, current_exp, exp_to_next_level)

func _on_hero_leveled_up(new_level: int) -> void:
	hero_leveled_up.emit(new_level)

func _on_hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String) -> void:
	run_metrics.record_hero_augment(level, chosen_name, reason)
	hero_augment_selected.emit(level, candidates, chosen_name, reason, build_summary)

func _on_monster_died(monster: Node) -> void:
	if battle_over:
		return

	var drop_position := Vector2.ZERO
	var monster_type := "slime"
	var is_split_child := false
	var allow_special_death_split := false
	var death_type := "normal"
	var reward := 0
	var instance_id := 0

	if is_instance_valid(monster):
		var monster_node := monster as Node2D
		if monster_node != null:
			drop_position = monster_node.global_position

		instance_id = monster.get_instance_id()
		monster_type = String(monster.get("monster_type"))
		is_split_child = bool(monster.get_meta("split_child", false))
		allow_special_death_split = bool(
			monster.get_meta("allow_special_death_split", false)
		)
		death_type = String(monster.get_meta("death_type", "normal"))
		reward = int(monster.get("exp_reward"))

	if reward > 0:
		_spawn_exp_orb(drop_position, reward)

	run_metrics.record_monster_death(monster_type)

	var original_cost: float = float(monster_summon_costs.get(instance_id, 0.0))
	monster_summon_costs.erase(instance_id)

	if death_refund_ratio > 0.0 and original_cost > 0.0:
		command_power = minf(
			command_power + original_cost * death_refund_ratio,
			max_command
		)
		command_changed.emit(command_power, max_command)

	if (
		monster_type == "slime"
		and not is_split_child
		and slime_split_chance > 0.0
		and randf() <= slime_split_chance
	):
		var offset := Vector2.from_angle(randf_range(0.0, TAU)) * 42.0
		_spawn_monster(
			"slime",
			_clamp_manual_spawn_position(drop_position + offset),
			0.0,
			true
		)

	_process_special_death_spawn(
		monster_type,
		drop_position,
		is_split_child,
		allow_special_death_split,
		death_type
	)

	monsters_alive = maxi(monsters_alive - 1, 0)
	_emit_stats()

func _process_special_death_spawn(
	monster_type: String,
	drop_position: Vector2,
	is_split_child: bool,
	allow_special_death_split: bool,
	death_type: String
) -> void:
	var can_split := not is_split_child or allow_special_death_split

	if monster_type == "slime" and can_split:
		var slime_config: Dictionary = _get_special_augment_config(
			"slime"
		).get("slime_residual_mucus", {})
		var count := maxi(int(slime_config.get("count", 0)), 0)
		for index in range(count):
			var angle := TAU * float(index + 1) / float(count + 1)
			var offset := Vector2.from_angle(angle) * 34.0
			_spawn_monster(
				"slime",
				_clamp_manual_spawn_position(drop_position + offset),
				0.0,
				true,
				{
					"hp_multiplier": float(
						slime_config.get("hp_multiplier", 0.50)
					),
					"damage_multiplier": float(
						slime_config.get("damage_multiplier", 0.50)
					),
				}
			)

	if (
		monster_type == "bomb_rat"
		and can_split
		and death_type != "self_destruct"
	):
		var rat_config: Dictionary = _get_special_augment_config(
			"bomb_rat"
		).get("bomb_rat_litter", {})
		var rat_count := maxi(int(rat_config.get("count", 0)), 0)
		for index in range(rat_count):
			var angle := TAU * float(index + 1) / float(rat_count + 1)
			var offset := Vector2.from_angle(angle) * 38.0
			_spawn_monster(
				"bomb_rat",
				_clamp_manual_spawn_position(drop_position + offset),
				0.0,
				true,
				{
					"hp_multiplier": float(
						rat_config.get("hp_multiplier", 0.50)
					),
				}
			)

func _spawn_exp_orb(drop_position: Vector2, exp_value: int) -> void:
	if exp_value <= 0:
		return

	var orb := EXP_ORB_SCENE.instantiate() as Node2D
	add_child(orb)
	orb.global_position = drop_position
	orb.call("setup", exp_value)

func _emit_demon_ultimate_changed() -> void:
	var charge_max := maxf(DEMON_ULTIMATES.CHARGE_MAX, 1.0)
	demon_ultimate_changed.emit(
		demon_ultimate_charge,
		charge_max,
		demon_ultimate_charge + 0.001 >= charge_max
	)

func _emit_demon_ultimate_cooldowns() -> void:
	demon_ultimate_cooldowns_changed.emit(
		demon_ultimate_cooldowns.duplicate(true)
	)

func _update_demon_ultimate_cooldowns(delta: float) -> void:
	var changed := false
	for raw_id in DEMON_ULTIMATES.get_ordered_ids():
		var skill_id := String(raw_id)
		var remaining := maxf(
			float(demon_ultimate_cooldowns.get(skill_id, 0.0)) - delta,
			0.0
		)
		if absf(
			remaining - float(demon_ultimate_cooldowns.get(skill_id, 0.0))
		) > 0.0001:
			demon_ultimate_cooldowns[skill_id] = remaining
			changed = true

	if not changed:
		return

	demon_ultimate_cooldown_emit_timer -= delta
	if demon_ultimate_cooldown_emit_timer <= 0.0:
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

func try_use_demon_ultimate(
	skill_id: String,
	direction: String = ""
) -> bool:
	if battle_over or external_pause or demon_augment_selection_active:
		return false
	if demon_ultimate_charge + 0.001 < DEMON_ULTIMATES.CHARGE_MAX:
		return false
	if float(demon_ultimate_cooldowns.get(skill_id, 0.0)) > 0.001:
		return false

	var skill := DEMON_ULTIMATES.get_skill(skill_id)
	if skill.is_empty() or not bool(skill.get("implemented", false)):
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

	demon_ultimate_charge = 0.0
	demon_ultimate_cooldowns[skill_id] = maxf(
		float(skill.get("cooldown", 0.0)),
		0.0
	)
	_emit_demon_ultimate_changed()
	_emit_demon_ultimate_cooldowns()

	var skill_name := String(skill.get("name", "마왕 필살기"))
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

func _use_demon_encirclement(skill: Dictionary) -> bool:
	if not is_instance_valid(hero):
		return false
	if not demon_ultimate_spawn_queue.is_empty():
		return false

	var pool: Array[String] = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			pool.append(monster_id)

	if pool.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if MONSTER_CATALOG.MONSTERS.has(fallback_id):
				pool.append(fallback_id)
			if pool.size() >= 3:
				break

	if pool.is_empty():
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

	var pool: Array[String] = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			pool.append(monster_id)

	if pool.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if MONSTER_CATALOG.MONSTERS.has(fallback_id):
				pool.append(fallback_id)
			if pool.size() >= 3:
				break

	if pool.is_empty():
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

	var pool: Array[String] = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			pool.append(monster_id)

	if pool.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if MONSTER_CATALOG.MONSTERS.has(fallback_id):
				pool.append(fallback_id)
			if pool.size() >= 3:
				break

	if pool.is_empty():
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
			_spawn_monster(monster_id, spawn_position, 0.0, false)

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
	if not spawn_special_monster(monster_id, event):
		push_warning(
			"Stage event monster not found: %s" % monster_id
		)
		return

	_emit_stage_event_announcement(event, monster_id)

func _open_mutation_choice(event: Dictionary) -> void:
	if mutation_director.is_active():
		return

	var candidates: Array = []
	for raw_id in allowed_monster_ids:
		var monster_id := String(raw_id)
		if MONSTER_CATALOG.MONSTERS.has(monster_id):
			candidates.append(monster_id)

	if candidates.is_empty():
		for raw_id in MONSTER_CATALOG.ORDER:
			var fallback_id := String(raw_id)
			if not MONSTER_CATALOG.MONSTERS.has(fallback_id):
				continue
			candidates.append(fallback_id)
			if candidates.size() >= 3:
				break

	if not mutation_director.begin(event, candidates):
		return

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
	var event := mutation_director.get_event()
	mutation_director.reset()
	flow_pause_manager.release_pause(PAUSE_REASON_MUTATION_CHOICE)
	_sync_combat_pause_state()

	if event.is_empty():
		event = {
			"type": "elite",
			"name_prefix": "돌연변이",
			"spawn_distance": 260.0,
			"hp_multiplier": 2.2,
			"damage_multiplier": 1.45,
			"speed_multiplier": 1.10,
			"exp_multiplier": 1.5,
			"visual_scale": 1.15,
		}
	else:
		event["spawn_distance"] = minf(
			float(event.get("spawn_distance", 260.0)),
			260.0
		)

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
		return

	_emit_stage_event_announcement(event, monster_id)
	mutation_selected.emit(event_type, mutation_name)
	mutation_spawn_result.emit(true, "%s 소환 완료" % mutation_name)

func spawn_special_monster(
	monster_id: String,
	special_data: Dictionary
) -> bool:
	if not is_instance_valid(hero):
		return false
	if not MONSTER_CATALOG.MONSTERS.has(monster_id):
		return false

	var spawn_position := _get_stage_event_spawn_position(
		float(special_data.get("spawn_distance", 720.0))
	)
	var monster = _spawn_monster(
		monster_id,
		spawn_position,
		0.0,
		false
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
	)
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

	if monster_id == "bomb_rat":
		var explosion_damage_value = monster.get("explosion_damage")
		if explosion_damage_value != null:
			monster.set(
				"explosion_damage",
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

func _get_stage_event_spawn_position(
	spawn_distance: float = 720.0
) -> Vector2:
	if not is_instance_valid(hero):
		return current_map_size * 0.5

	var angle := randf_range(0.0, TAU)
	var candidate := (
		hero.position
		+ Vector2.from_angle(angle) * maxf(spawn_distance, 1.0)
	)
	return Vector2(
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

func _gain_demon_exp(amount: float) -> void:
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
	if battle_over or demon_augment_selection_active or demon_pending_augments <= 0:
		return

	demon_active_augment_level = (
		demon_pending_augment_levels[0]
		if not demon_pending_augment_levels.is_empty()
		else demon_level
	)
	demon_augment_candidates = _roll_demon_augment_candidates(false)
	if demon_augment_candidates.is_empty():
		demon_pending_augments = maxi(demon_pending_augments - 1, 0)
		if not demon_pending_augment_levels.is_empty():
			demon_pending_augment_levels.pop_front()
		demon_active_augment_level = 0
		_open_next_demon_augment_if_needed()
		return

	demon_augment_selection_active = true
	flow_pause_manager.request_pause(
		PAUSE_REASON_DEMON_AUGMENT,
		FULL_MODAL_PAUSE_DOMAINS
	)
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
		demon_last_candidate_ids.append(String(candidate.get("id", "")))

	return candidates

func reroll_demon_augments() -> bool:
	if not demon_augment_selection_active or demon_rerolls_left <= 0:
		return false

	demon_rerolls_left -= 1
	demon_augment_candidates = _roll_demon_augment_candidates(true)
	demon_augment_ready.emit(
		demon_augment_candidates,
		demon_rerolls_left,
		demon_active_augment_level
	)
	return true

func choose_demon_augment(augment_id: String) -> bool:
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
		if augment_id in demon_special_augments:
			return false
		demon_special_augments.append(augment_id)
		_refresh_alive_monsters_for_augments()
	else:
		var current_stack := int(demon_build_counts.get(augment_id, 0))
		var max_stack := int(augment.get("max_stack", 0))
		if max_stack > 0 and current_stack >= max_stack:
			return false

		_apply_demon_augment(augment)
		demon_build_counts[augment_id] = current_stack + 1
		_refresh_alive_monsters_for_augments()

	demon_pending_augments = maxi(demon_pending_augments - 1, 0)
	if not demon_pending_augment_levels.is_empty():
		demon_pending_augment_levels.pop_front()
	demon_active_augment_level = 0
	demon_augment_selection_active = false
	demon_augment_candidates.clear()
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

func _get_monster_augment_multiplier(
	monster_id: String,
	stat: String
) -> float:
	var modifiers: Dictionary = monster_augment_modifiers.get(monster_id, {})
	return maxf(float(modifiers.get(stat, 1.0)), 0.01)

func _get_special_augment_config(
	monster_id: String
) -> Dictionary:
	var result: Dictionary = {}
	for augment_id in demon_special_augments:
		var augment := DEMON_AUGMENTS.get_augment(String(augment_id))
		if String(augment.get("monster_id", "")) != monster_id:
			continue
		var effect_type := String(augment.get("effect_type", ""))
		if effect_type.is_empty():
			continue
		result[effect_type] = Dictionary(
			augment.get("effect_values", {})
		).duplicate(true)
	return result

func _apply_special_augments_to_monster(
	monster: Node,
	monster_id: String
) -> void:
	if not is_instance_valid(monster):
		return
	var configs := _get_special_augment_config(monster_id)
	monster.set_meta("special_augment_configs", configs)
	if monster.has_method("configure_special_augments"):
		monster.call("configure_special_augments", configs)

func _refresh_alive_monsters_for_augments() -> void:
	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster_id := String(node.get("monster_type"))
		_apply_normal_augments_to_existing_monster(node, monster_id)
		_apply_special_augments_to_monster(node, monster_id)

func _apply_normal_augments_to_existing_monster(
	monster: Node,
	monster_id: String
) -> void:
	var raw_speed = monster.get_meta("augment_raw_move_speed", null)
	if raw_speed != null:
		monster.set_meta(
			"demon_level_base_move_speed",
			float(raw_speed)
			* monster_speed_multiplier
			* _get_monster_augment_multiplier(monster_id, "speed")
		)

	var raw_damage = monster.get_meta("augment_raw_attack_damage", null)
	if raw_damage != null:
		monster.set_meta(
			"demon_level_base_attack_damage",
			maxf(
				float(raw_damage)
				* monster_damage_multiplier
				* _get_monster_augment_multiplier(monster_id, "damage"),
				1.0
			)
		)

	var raw_hp = monster.get_meta("augment_raw_max_hp", null)
	if raw_hp != null:
		var base_hp := (
			float(raw_hp)
			* monster_hp_multiplier
			* _get_monster_augment_multiplier(monster_id, "hp")
		)
		if monster_id == "orc":
			base_hp *= orc_hp_multiplier
		monster.set_meta(
			"demon_level_base_max_hp",
			maxf(base_hp, 1.0)
		)

	var raw_cooldown = monster.get_meta(
		"augment_raw_attack_cooldown",
		null
	)
	if raw_cooldown != null:
		monster.set(
			"attack_cooldown",
			maxf(
				0.10,
				float(raw_cooldown)
				* monster_attack_speed_multiplier
				* _get_monster_augment_multiplier(
					monster_id,
					"attack_cooldown"
				)
			)
		)

	if monster_id == "bomb_rat":
		var raw_fuse = monster.get_meta(
			"augment_raw_self_destruct_fuse",
			null
		)
		if raw_fuse != null:
			monster.set(
				"self_destruct_fuse",
				maxf(
					0.10,
					float(raw_fuse)
					* monster_attack_speed_multiplier
					* _get_monster_augment_multiplier(
						monster_id,
						"attack_cooldown"
					)
				)
			)
		var raw_explosion = monster.get_meta(
			"augment_raw_explosion_damage",
			null
		)
		if raw_explosion != null:
			monster.set(
				"explosion_damage",
				maxi(
					1,
					int(round(
						float(raw_explosion)
						* monster_damage_multiplier
						* _get_monster_augment_multiplier(
							monster_id,
							"damage"
						)
					))
				)
			)

	_apply_demon_level_scaling_to_monster(monster, true)

func _spawn_extra_normal_summon_monsters(
	monster_type: String,
	spawn_position: Vector2
) -> void:
	if monster_type != "slime":
		return
	var config: Dictionary = _get_special_augment_config("slime").get(
		"slime_cell_division",
		{}
	)
	var extra_count := maxi(int(config.get("extra_count", 0)), 0)
	for index in range(extra_count):
		var angle := TAU * float(index + 1) / float(extra_count + 1)
		var offset := Vector2.from_angle(angle) * 36.0
		var extra_slime = _spawn_monster(
			"slime",
			_clamp_manual_spawn_position(spawn_position + offset),
			0.0,
			true
		)
		if is_instance_valid(extra_slime):
			extra_slime.set_meta("allow_special_death_split", true)

func _sync_combat_pause_state() -> void:
	var should_enable := (
		not battle_over
		and not flow_pause_manager.is_paused(
			FLOW_PAUSE_MANAGER.DOMAIN_COMBAT
		)
	)
	_set_combat_physics_enabled(should_enable)

func _set_combat_physics_enabled(enabled: bool) -> void:
	if is_instance_valid(hero):
		hero.set_physics_process(enabled)

	for group_name in ["monsters", "exp_orbs", "hero_projectiles", "monster_projectiles"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if is_instance_valid(node):
				node.set_physics_process(enabled)

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
	var level_line := "[DEBUG] 마왕 Lv.%d · 레벨배율 HP x%.3f / ATK x%.3f / SPD x%.3f (cap x%.2f)" % [
		demon_level,
		_get_demon_level_monster_hp_multiplier(),
		_get_demon_level_monster_damage_multiplier(),
		_get_demon_level_monster_speed_multiplier(),
		DEMON_LEVEL_MONSTER_SPEED_MAX_MULTIPLIER,
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
	for node in get_tree().get_nodes_in_group("monsters"):
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
	if battle_over:
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
	var clear_result: Dictionary = STAGE_PROGRESS.complete_stage(
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
	var granted_reward: int = int(clear_result.get("reward", 0))
	if granted_reward > 0:
		result_text += "\n최초 클리어 보상 · 연구 포인트 +%d" % granted_reward

	result_text += _grant_run_research_reward()
	_finish_battle(result_text, true)

func _on_run_time_up() -> void:
	if battle_over:
		return

	var hero_name := String(current_hero_profile.get("display_name", "용사"))
	var result_text := "시간 초과!\n%s가 제한시간을 버텨냈습니다." % hero_name
	result_text += _grant_run_research_reward()
	_finish_battle(result_text, false)

func _grant_run_research_reward() -> String:
	var breakdown: Dictionary = run_metrics.get_research_reward_breakdown()
	var requested := int(breakdown.get("total", 0))
	if requested <= 0:
		return ""

	var grant_result: Dictionary = STAGE_PROGRESS.add_research_points(requested)
	var granted := int(grant_result.get("granted", 0))
	if granted <= 0:
		return "\nRun 연구 보상 저장 실패"

	return (
		"\nRun 연구 +%d · 기본 %d / 피해 %d / 시간 %d / 관찰 %d"
		% [
			granted,
			int(breakdown.get("base", 0)),
			int(breakdown.get("damage", 0)),
			int(breakdown.get("time", 0)),
			int(breakdown.get("observation", 0)),
		]
	)

func get_run_analysis_summary() -> String:
	return run_metrics.get_result_summary()

func _finish_battle(message: String, player_won: bool) -> void:
	battle_over = true
	demon_augment_selection_active = false
	flow_pause_manager.reset()
	_sync_combat_pause_state()
	battle_finished.emit(message, player_won)

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

func get_snapshot() -> Dictionary:
	var hp := 0
	var max_hp_value := 0
	var level := 1
	var current_exp := 0
	var exp_to_next_level := 50
	var build_summary := "아직 선택 없음"

	if is_instance_valid(hero):
		hp = int(hero.get("current_hp"))
		max_hp_value = int(hero.get("max_hp"))
		level = int(hero.get("level"))
		current_exp = int(hero.get("current_exp"))
		exp_to_next_level = int(hero.get("exp_to_next_level"))
		if hero.has_method("get_build_summary"):
			build_summary = String(hero.call("get_build_summary"))

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
		"hero_recent_offense": (
			String(hero.call("get_recent_offense_summary"))
			if is_instance_valid(hero) and hero.has_method("get_recent_offense_summary")
			else "최근 공세 기록 없음"
		),
		"monsters_left": monsters_alive,
		"command_power": command_power,
		"command_max": max_command,
		"demon_level": demon_level,
		"demon_exp": demon_exp,
		"demon_exp_to_next": demon_exp_to_next_level,
		"demon_ultimate_charge": demon_ultimate_charge,
		"demon_ultimate_max": DEMON_ULTIMATES.CHARGE_MAX,
		"demon_ultimate_ready": (
			demon_ultimate_charge + 0.001 >= DEMON_ULTIMATES.CHARGE_MAX
		),
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
	draw_rect(Rect2(Vector2.ZERO, current_map_size), Color(0.075, 0.085, 0.105), true)

	var grid_spacing := 320.0
	var grid_color := Color(0.105, 0.12, 0.145)
	var x := grid_spacing
	while x < current_map_size.x:
		draw_line(Vector2(x, 0), Vector2(x, current_map_size.y), grid_color, 2.0)
		x += grid_spacing

	var y := grid_spacing
	while y < current_map_size.y:
		draw_line(Vector2(0, y), Vector2(current_map_size.x, y), grid_color, 2.0)
		y += grid_spacing

	draw_rect(Rect2(Vector2.ZERO, current_map_size), Color(0.34, 0.39, 0.48), false, 8.0)

	var center := current_map_size * 0.5
	draw_circle(center, 92.0, Color(0.1, 0.12, 0.15), false, 3.0)
	draw_line(center + Vector2(0, -110), center + Vector2(0, 110), Color(0.15, 0.18, 0.22), 2.0)
	draw_line(center + Vector2(-110, 0), center + Vector2(110, 0), Color(0.15, 0.18, 0.22), 2.0)

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
