"""Test actual finale guards with mock spawn/finish, plus real encounter controller."""
from pathlib import Path
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(output),'--script','tests/hero_encounters_smoke.gd'],check=True)
source = (repo/'src/battle/battle.gd').read_text()
for relative in ['src/hero_mode/hero_control_spawn_budget.gd','src/data/hero_control_spawn_catalog.gd']:
    (output/relative).write_bytes((repo/relative).read_bytes())
def method(name):
    start = source.index('func '+name+'(')
    end = source.find('\nfunc ',start+1)
    return source[start:end if end >= 0 else len(source)]+ '\n\n'
base = '''extends Node2D
const HERO_SURVIVAL := preload("res://src/data/hero_mode_catalog.gd")
const CONTROL_SPAWNS := preload("res://src/hero_mode/hero_control_spawn_budget.gd")
class MONSTER_CATALOG:
    const MONSTERS := {"orc":{},"slime":{}}
    static func get_scene(_id: String) -> bool: return true
class TRANSCENDENCE_DATA:
    static func is_transcendent(_id: String) -> bool: return false
var transcendence := {}
var block_species := false
var block_population := false
func is_population_full() -> bool: return block_population
func _monster_population_limit_reached(_id: String,_elite: bool = false) -> bool: return block_species
func _clamp_monster_spawn_outside_solid_top_wall(point: Vector2) -> Vector2: return point
func get_stationary_spawn_position(_id: String,_hero: Vector2,point: Vector2) -> Vector2: return point
var hero_control_spawns = CONTROL_SPAWNS.new()
var hero_control_roster: Array = HERO_SURVIVAL.roster_for(1,"easy")
var online_match_mode := false
var online_match_rules := {}
var hero_player_mode := true
var practice_mode := false
var tutorial_mode := false
var battle_over := false
var hero_final_boss_spawned := false
var _hero_boss_spawn_pending := false
var run_metrics := preload("res://tests/hero_encounters_smoke.gd").Metrics.new()
var hero: Node2D
var current_stage_data := {"number":1}
var current_hero_profile := {"display_name":"mock"}
var campaign_difficulty := "easy"
var active_monsters := {}
var max_command := 100.0
var finish_count := 0
var won := false
func _finish_battle(_text: String, victory: bool, _hero_outcome: StringName = &"") -> void:
    if battle_over: return
    battle_over = true; won = victory; finish_count += 1
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point
func _get_demon_level_monster_hp_multiplier(_clock: float) -> float: return 10.0
func _get_demon_level_monster_damage_multiplier(_clock: float) -> float: return 1.7
func _grant_run_research_reward(_won: bool) -> String: return ""
func _apply_special_monster_modifiers(_node: Node,_id: String,_data: Dictionary) -> void: pass
'''
spawn_prefix = method('_spawn_monster').split('\tvar monster := scene.instantiate()')[0]
factory = '\tvar actor = preload("res://tests/hero_encounters_smoke.gd").Actor.new(); add_child(actor); return actor\n\n'
(output/'tests/hero_finale_harness.gd').write_text(base.replace('    ','\t')+spawn_prefix+factory+method('_is_reserved_hero_boss_request')+method('hero_spawn_candidate')+method('get_population_limit')+method('_on_run_time_up')+method('spawn_hero_encounter')+method('_finish_hero_boss_victory')+method('finish_hero_boss_timeout'))

# Compile and exercise the actual difficulty-selector binding with a save stub.
lobby = (repo/'src/ui/hero_lobby_view.gd').read_text()
start = lobby.index('\tvar difficulty := OptionButton.new()')
end = lobby.index('\tbody.add_child(difficulty)',start)+len('\tbody.add_child(difficulty)')
selector = lobby[start:end]
(output/'tests/hero_difficulty_harness.gd').write_text('extends RefCounted\nclass STORE extends RefCounted:\n\tconst UNLOCK_DATA := preload("res://src/data/mode_unlock_catalog.gd")\n\tstatic func can_start(_stage: String,value: String) -> bool: return UNLOCK_DATA.difficulty_available(value)\n\tstatic var selected := "easy"\n\tstatic var fail := false\n\tstatic func selected_battle_stage() -> String: return "stage_1"\n\tstatic func hard_stage_unlocked(_id: String) -> bool: return true\n\tstatic func difficulty() -> String: return selected\n\tstatic func set_difficulty(value: String) -> bool:\n\t\tif fail or not can_start("stage_1",value): return false\n\t\tselected = value; return true\nclass Lobby extends RefCounted:\n\tfunc _refresh_stage_card() -> void: pass\nvar lobby := Lobby.new()\nfunc build(body: VBoxContainer) -> void:\n'+selector+'\n')
