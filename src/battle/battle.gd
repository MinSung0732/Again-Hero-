extends Node2D

signal stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int)
signal progression_changed(level: int, current_exp: int, exp_to_next_level: int)
signal hero_leveled_up(new_level: int)
signal hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String)
signal command_changed(current_value: float, max_value: float)
signal summon_result(monster_type: String, success: bool, message: String)
signal battle_finished(message: String, player_won: bool)

const HERO_SCENE := preload("res://src/hero/Hero.tscn")
const SLIME_SCENE := preload("res://src/monsters/Slime.tscn")
const SPIDER_SCENE := preload("res://src/monsters/Spider.tscn")
const ORC_SCENE := preload("res://src/monsters/Orc.tscn")
const EXP_ORB_SCENE := preload("res://src/battle/ExpOrb.tscn")
const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const HERO_PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")

const DEFAULT_MAP_SIZE := Vector2(3200, 3200)
const AUTO_SPAWN_MIN_DISTANCE := 560.0
const AUTO_SPAWN_MAX_DISTANCE := 720.0

const MAX_COMMAND := 100.0
const START_COMMAND := 0.0
const COMMAND_REGEN_PER_SECOND := 3.0
const MANUAL_SPAWN_MARGIN := 70.0

const MONSTER_COSTS := {
	"slime": 3.0,
	"spider": 7.0,
	"orc": 18.0,
}

var hero: Node2D
var current_stage_id: String = "stage_1"
var current_stage_data: Dictionary = {}
var current_hero_profile: Dictionary = {}
var current_map_size: Vector2 = DEFAULT_MAP_SIZE
var monsters_alive: int = 0
var battle_over: bool = false
var command_power: float = START_COMMAND
var command_emit_timer: float = 0.0

func _ready() -> void:
	queue_redraw()
	_start_battle()

func _process(delta: float) -> void:
	if battle_over:
		return

	if command_power < MAX_COMMAND:
		command_power = minf(command_power + COMMAND_REGEN_PER_SECOND * delta, MAX_COMMAND)
		command_emit_timer -= delta

		if command_emit_timer <= 0.0 or command_power >= MAX_COMMAND:
			command_emit_timer = 0.10
			command_changed.emit(command_power, MAX_COMMAND)

func _start_battle() -> void:
	battle_over = false
	monsters_alive = 0
	command_power = START_COMMAND

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

	var hero_id: String = String(current_stage_data.get("hero_id", "ranged_rookie"))
	current_hero_profile = HERO_PROFILES.get_profile(hero_id)

	hero = HERO_SCENE.instantiate() as Node2D
	if hero.has_method("configure_profile"):
		hero.call("configure_profile", current_hero_profile)
	if hero.has_method("configure_battlefield"):
		hero.call("configure_battlefield", current_map_size)
	hero.set("level", int(current_stage_data.get("hero_level_start", 1)))

	add_child(hero)
	hero.position = current_map_size * 0.5
	hero.connect("health_changed", Callable(self, "_on_hero_health_changed"))
	hero.connect("progression_changed", Callable(self, "_on_hero_progression_changed"))
	hero.connect("leveled_up", Callable(self, "_on_hero_leveled_up"))
	hero.connect("augment_selected", Callable(self, "_on_hero_augment_selected"))
	hero.connect("died", Callable(self, "_on_hero_died"))

	_emit_stats()
	_emit_progression()
	command_changed.emit(command_power, MAX_COMMAND)

func try_summon(monster_type: String) -> bool:
	if battle_over:
		summon_result.emit(monster_type, false, "전투가 종료되어 소환할 수 없습니다.")
		return false

	var cost: float = get_monster_cost(monster_type)
	if cost <= 0.0:
		summon_result.emit(monster_type, false, "알 수 없는 몬스터입니다.")
		return false

	if command_power + 0.001 < cost:
		summon_result.emit(
			monster_type,
			false,
			"지휘력이 부족합니다. 필요 %.0f / 현재 %.0f" % [cost, command_power]
		)
		return false

	command_power = maxf(command_power - cost, 0.0)
	_spawn_monster(monster_type, _get_auto_spawn_position())
	command_changed.emit(command_power, MAX_COMMAND)
	_emit_stats()

	summon_result.emit(
		monster_type,
		true,
		"%s 소환! 지휘력 %.0f 소모" % [_get_monster_name(monster_type), cost]
	)
	return true

func try_summon_at_position(monster_type: String, spawn_position: Vector2) -> bool:
	if battle_over:
		summon_result.emit(monster_type, false, "전투가 종료되어 소환할 수 없습니다.")
		return false

	if not is_spawn_position_valid(spawn_position):
		summon_result.emit(monster_type, false, "전장 안쪽을 터치해 주세요.")
		return false

	var cost: float = get_monster_cost(monster_type)
	if cost <= 0.0:
		summon_result.emit(monster_type, false, "알 수 없는 몬스터입니다.")
		return false

	if command_power + 0.001 < cost:
		summon_result.emit(
			monster_type,
			false,
			"지휘력이 부족합니다. 필요 %.0f / 현재 %.0f" % [cost, command_power]
		)
		return false

	command_power = maxf(command_power - cost, 0.0)
	_spawn_monster(monster_type, _clamp_manual_spawn_position(spawn_position))
	command_changed.emit(command_power, MAX_COMMAND)
	_emit_stats()

	summon_result.emit(
		monster_type,
		true,
		"%s 수동 배치! 지휘력 %.0f 소모" % [_get_monster_name(monster_type), cost]
	)
	return true

func is_spawn_position_valid(spawn_position: Vector2) -> bool:
	return (
		spawn_position.x >= MANUAL_SPAWN_MARGIN
		and spawn_position.x <= current_map_size.x - MANUAL_SPAWN_MARGIN
		and spawn_position.y >= MANUAL_SPAWN_MARGIN
		and spawn_position.y <= current_map_size.y - MANUAL_SPAWN_MARGIN
	)

func _clamp_manual_spawn_position(spawn_position: Vector2) -> Vector2:
	return Vector2(
		clampf(spawn_position.x, MANUAL_SPAWN_MARGIN, current_map_size.x - MANUAL_SPAWN_MARGIN),
		clampf(spawn_position.y, MANUAL_SPAWN_MARGIN, current_map_size.y - MANUAL_SPAWN_MARGIN)
	)

func get_monster_cost(monster_type: String) -> float:
	return float(MONSTER_COSTS.get(monster_type, 0.0))

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

func _spawn_monster(monster_type: String, spawn_position: Vector2) -> void:
	var scene: PackedScene = SLIME_SCENE

	match monster_type:
		"spider":
			scene = SPIDER_SCENE
		"orc":
			scene = ORC_SCENE
		_:
			scene = SLIME_SCENE

	var monster := scene.instantiate() as Node2D
	add_child(monster)
	monster.position = spawn_position
	monster.connect("died", Callable(self, "_on_monster_died").bind(monster))
	monsters_alive += 1

func _get_monster_name(monster_type: String) -> String:
	match monster_type:
		"spider":
			return "거미"
		"orc":
			return "오크"
		_:
			return "슬라임"

func _on_hero_health_changed(current_hp: int, max_hp_value: int) -> void:
	stats_changed.emit(current_hp, max_hp_value, monsters_alive)

func _on_hero_progression_changed(level: int, current_exp: int, exp_to_next_level: int) -> void:
	progression_changed.emit(level, current_exp, exp_to_next_level)

func _on_hero_leveled_up(new_level: int) -> void:
	hero_leveled_up.emit(new_level)

func _on_hero_augment_selected(level: int, candidates: Array, chosen_name: String, reason: String, build_summary: String) -> void:
	hero_augment_selected.emit(level, candidates, chosen_name, reason, build_summary)

func _on_monster_died(monster: Node) -> void:
	if battle_over:
		return

	if is_instance_valid(monster):
		var monster_node := monster as Node2D
		if monster_node != null:
			var reward := int(monster.get("exp_reward"))
			_spawn_exp_orb(monster_node.global_position, reward)

	monsters_alive = maxi(monsters_alive - 1, 0)
	_emit_stats()

func _spawn_exp_orb(drop_position: Vector2, exp_value: int) -> void:
	if exp_value <= 0:
		return

	var orb := EXP_ORB_SCENE.instantiate() as Node2D
	add_child(orb)
	orb.global_position = drop_position
	orb.call("setup", exp_value)

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

	STAGE_PROGRESS.complete_stage(
		current_stage_id,
		stage_number,
		next_stage_id,
		next_stage_number
	)

	_finish_battle(
		"Stage %d 클리어!\n%s · %s 처치 성공." % [stage_number, stage_name, hero_name],
		true
	)

func _finish_battle(message: String, player_won: bool) -> void:
	battle_over = true

	if is_instance_valid(hero):
		hero.set_physics_process(false)

	for node in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(node):
			node.set_physics_process(false)

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
		"monsters_left": monsters_alive,
		"command_power": command_power,
		"command_max": MAX_COMMAND,
		"map_width": current_map_size.x,
		"map_height": current_map_size.y,
		"next_stage_id": String(current_stage_data.get("next_stage_id", "")),
		"battle_over": battle_over,
	}

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
