"""Extract production chest eligibility/session/creation; replace only asset factory."""
from pathlib import Path
import shutil
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_chest_budget_smoke.gd'],check=True)
source = (repo/'src/battle/battle.gd').read_text()
def method(name):
    start = source.index('func '+name+'(')
    end = source.find('\nfunc ',start+1)
    return source[start:end]+'\n'
base = '''extends Node2D
const HERO_SURVIVAL := preload("res://src/data/hero_mode_catalog.gd")
const PICKUP_PLACEMENT := preload("res://src/systems/pickup_placement.gd")
const CHEST_KILLS_REQUIRED := 50
const MAX_ACTIVE_CHESTS := 2
class Chest extends Node2D:
	signal destroyed(position, chest)
class Metrics extends RefCounted:
	var elapsed_seconds := 0.0
class Router extends RefCounted:
	func get_session_id() -> int: return 1
var battle_command_router := Router.new()
var run_metrics := Metrics.new()
var hero_player_mode := true
var online_match_mode := false
var battle_over := false
var hero_kills_toward_chest := 0
var hero_chests_spawned := 0
var hero_elite_kills_toward_chest := 0
var active_treasure_chests := {}
var current_map_size := Vector2(2400,2400)
var hero: Node2D
func _ready() -> void: hero = Node2D.new(); add_child(hero)
func _active_registry_size(registry: Dictionary) -> int: return registry.size()
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point
func _register_treasure_chest(chest: Node) -> void: active_treasure_chests[chest.get_instance_id()] = chest
func _on_treasure_chest_destroyed(_position: Vector2, _chest: Node) -> void: pass
'''
methods = ''.join(method(name) for name in ['_chest_kill_requirement','_hero_chest_eligible','_try_spawn_chest_from_kills','_spawn_chest_for_session','_spawn_random_treasure_chest'])
methods = methods.replace('TREASURE_CHEST_SCENE.instantiate()', 'Chest.new()')
(out/'tests/hero_chest_budget_harness.gd').write_text(base+methods)

shutil.copyfile(repo/"src/data/ranked_pickup_catalog.gd",out/"src/data/ranked_pickup_catalog.gd")
(out/"src/systems").mkdir(parents=True,exist_ok=True)
shutil.copyfile(repo/"src/systems/pickup_placement.gd",out/"src/systems/pickup_placement.gd")
