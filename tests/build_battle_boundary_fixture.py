"""Build an isolated Godot fixture from actual battle input and entity lifecycle functions.

Game assets and effect application are replaced with explicit spies. This checks
the real public wrappers, dispatch, candidate validation, queue and pause flow;
pool lifecycle functions are real, with a spy projectile scene. This is not a
complete battle scene or a test of real augment effects.
Usage: python3 tests/build_battle_boundary_fixture.py /tmp/again-battle-fixture
"""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
TARGET = Path(sys.argv[1]).resolve()
if TARGET == ROOT or ROOT in TARGET.parents:
    raise SystemExit("Use a separate temporary fixture directory")
TARGET.mkdir(parents=True, exist_ok=True)
(TARGET / "project.godot").write_text('[application]\nconfig/name="Battle boundary fixture"\n')
SOURCE = (ROOT / "src/battle/battle.gd").read_text()


def function(name):
    match = re.search(r"^func " + re.escape(name) + r"\(", SOURCE, re.M)
    if match is None:
        raise RuntimeError("Missing actual battle function: " + name)
    tail = SOURCE[match.start():]
    end = re.search(r"\nfunc ", tail)
    return (tail[:end.start()] if end else tail).rstrip() + "\n\n"


for name in ["src/data/battle_session_catalog.gd", "src/systems/battle_command.gd",
             "src/systems/battle_command_router.gd", "src/systems/battle_entity_registry.gd",
             "tests/battle_command_router_smoke.gd", "tests/battle_augment_boundary_smoke.gd",
             "tests/battle_mutation_boundary_smoke.gd", "tests/battle_entity_registry_smoke.gd",
             "tests/battle_entity_boundary_smoke.gd", "tests/pool_projectile_spy.gd"]:
    dest = TARGET / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, dest)

header = "extends Node2D\n" + SOURCE[SOURCE.index("const BATTLE_SESSION"):
                                        SOURCE.index("const HERO_TARGET_POLICY")]
functions = "".join(function(name) for name in [
    "try_summon", "try_summon_at_position", "try_summon_transcendent",
    "try_use_demon_ultimate", "_execute_battle_command",
    "get_battle_command_diagnostics", "set_battle_command_profiling",
    "get_demon_augment_revision", "reroll_demon_augments", "choose_demon_augment",
    "_execute_reroll_demon_augments", "_execute_choose_demon_augment",
    "_open_next_demon_augment_if_needed", "spawn_selected_mutation",
    "try_choose_mutation", "get_mutation_choice_revision",
    "_execute_selected_mutation", "_open_mutation_choice", "_activate_battle_entity",
    "_on_battle_entity_tree_exited", "get_battle_entity_handle", "resolve_battle_entity",
    "get_battle_entity_diagnostics", "acquire_projectile", "recycle_projectile",
    "_unregister_monster"])
pool_limit = re.search(r"^const MAX_PROJECTILE_POOL_PER_TYPE[^\n]+", SOURCE, re.M)
if pool_limit is None:
    raise RuntimeError("Missing actual projectile pool limit")
functions += pool_limit.group(0) + "\n"
spies = '''
class Augments:
	const TYPE_NORMAL = "normal"
	const TYPE_SPECIAL = "special"
	static func is_special_level(_level: int) -> bool:
		return false
	static func get_augment(id: String) -> Dictionary:
		if id == "fixture_a":
			return {"id": id, "name": "Fixture A", "augment_type": TYPE_NORMAL, "max_stack": 2}
		if id == "fixture_special":
			return {"id": id, "name": "Special", "augment_type": TYPE_SPECIAL}
		return {}
class PauseSpy:
	var paused := false
	func request_pause(_reason: String, _domains: Array) -> void:
		paused = true
	func release_pause(_reason: String) -> void:
		paused = false
class MetricsSpy:
	var specials := 0
	func record_special_augment_acquired() -> void:
		specials += 1
class MutationSpy:
	var active := false
	var event: Dictionary = {}
	var candidates: Array[String] = []
	func is_active() -> bool:
		return active
	func begin(next_event: Dictionary, ids: Array) -> bool:
		event = next_event.duplicate(true)
		candidates.assign(ids)
		active = not candidates.is_empty()
		return active
	func get_event() -> Dictionary:
		return event.duplicate(true)
	func get_candidates() -> Array[String]:
		return candidates.duplicate()
	func reset() -> void:
		active = false
		event.clear()
		candidates.clear()
class MutationCatalog:
	const SPECIAL_AUGMENT_EXHAUSTED_EVENT = {}
class Monsters:
	const ORDER = ["slime", "orc"]
	const MONSTERS = {"slime": {"can_be_elite": true}, "orc": {"can_be_elite": true}}
const DEMON_AUGMENTS = Augments
const MUTATION_CATALOG = MutationCatalog
const MONSTER_CATALOG = Monsters
const PAUSE_REASON_DEMON_AUGMENT = "demon_augment"
const PAUSE_REASON_MUTATION_CHOICE = "mutation_choice"
const FULL_MODAL_PAUSE_DOMAINS = ["combat", "run_timer"]
signal demon_augment_ready(candidates: Array, rerolls: int, level: int)
signal demon_augment_applied(name: String, summary: String)
signal command_changed(current: float, maximum: float)
signal mutation_choice_ready(event: Dictionary, candidates: Array)
signal mutation_selected(kind: String, name: String)
signal mutation_spawn_result(success: bool, message: String)
var flow_pause_manager = PauseSpy.new()
var run_metrics = MetricsSpy.new()
var mutation_director = MutationSpy.new()
var battle_over := false
var demon_level := 2
var demon_pending_augments := 0
var demon_pending_augment_levels: Array[int] = []
var demon_active_augment_level := 0
var demon_augment_candidates: Array = []
var demon_last_candidate_ids: Array[String] = []
var demon_augment_selection_active := false
var demon_rerolls_left := 3
var demon_build_counts: Dictionary = {}
var demon_special_augments: Array[String] = []
var command_power := 40.0
var max_command := 100.0
var applied := 0
var refreshed := 0
var rebuilds := 0
var summon_calls := 0
var skill_calls := 0
var last_position := Vector2.ZERO
var last_direction := ""
var gameplay_allowed := true
var allowed_monster_ids: Array = ["slime", "orc"]
var mutation_spawn_allowed := true
var mutation_spawns := 0
var last_mutation_event: Dictionary = {}
var announcements := 0
var reinforcement_requests := 0
var projectile_pools: Dictionary = {}
var active_monsters: Dictionary = {}
var direct_population_ids: Dictionary = {}
var monster_population_ids: Dictionary = {}
var monster_population_counts: Dictionary = {}
var population_updates := 0
func _ready() -> void:
	battle_command_router.begin_session(_execute_battle_command)
	battle_entity_registry.begin_session(battle_command_router.get_session_id())
func _queue_population_update() -> void:
	population_updates += 1
func start_offer(levels: Array) -> void:
	demon_pending_augment_levels.assign(levels)
	demon_pending_augments = levels.size()
	_open_next_demon_augment_if_needed()
func _roll_demon_augment_candidates(_reroll: bool) -> Array:
	return [DEMON_AUGMENTS.get_augment("fixture_a"), DEMON_AUGMENTS.get_augment("fixture_special")]
func _sync_combat_pause_state() -> void:
	pass
func _get_catalog_monster_display_name(id: String) -> String:
	return id
func spawn_special_monster(_id: String, event: Dictionary) -> bool:
	mutation_spawns += 1
	last_mutation_event = event.duplicate(true)
	return mutation_spawn_allowed
func _emit_stage_event_announcement(_event: Dictionary, _id: String) -> void:
	announcements += 1
func _queue_stage_event_reinforcements(_event: Dictionary) -> void:
	reinforcement_requests += 1
func _apply_demon_augment(_augment: Dictionary) -> void:
	applied += 1
func _refresh_monsters_for_selected_augment(_augment: Dictionary) -> void:
	refreshed += 1
func _rebuild_monster_augment_modifiers_from_build_counts() -> void:
	rebuilds += 1
func get_demon_build_summary() -> String:
	return "fixture"
func _execute_summon(_id: String) -> bool:
	summon_calls += 1
	return gameplay_allowed
func _execute_summon_at_position(_id: String, point: Vector2) -> bool:
	summon_calls += 1
	last_position = point
	return gameplay_allowed
func _execute_summon_transcendent() -> bool:
	summon_calls += 1
	return gameplay_allowed
func _execute_demon_ultimate(_id: String, facing: String = "") -> bool:
	skill_calls += 1
	last_direction = facing
	return gameplay_allowed
'''
(TARGET / "tests/battle_boundary_fixture.gd").write_text(header + functions + spies)
print("Fixture created:", TARGET)
