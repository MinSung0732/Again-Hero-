"""Extract real charge methods; registry/reference are real, visuals/queries are spies."""
from pathlib import Path
import argparse
import re
import shutil
from charge_lifetime_source import without_charge_lifetime_guards
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
p.add_argument('--baseline-file', type=Path, required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use a temporary fixture outside the checkout')
after = (ROOT/'src/hero/hero.gd').read_text()
before = a.baseline_file.read_text()
def function(s, name):
    m = re.search(r'^func '+name+r'\(', s, re.M)
    tail = s[m.start():]
    end = re.search(r'\nfunc ', tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
for name in re.findall(r'^func ([^(]+)\(', before, re.M):
    assert function(before, name) == without_charge_lifetime_guards(function(after, name)), name
print('All baseline Hero functions preserved except exact lifetime hooks')
out.mkdir(parents=True, exist_ok=True)
(out/'project.godot').write_text('[application]\nconfig/name="Charge lifetime fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','src/systems/battle_target_reference.gd','tests/charge_lifetime_smoke.gd']:
    dest = out/path
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT/path,dest)
header = '''extends Node2D
const REFERENCE := preload("res://src/systems/battle_target_reference.gd")
var fighter_charge_reference = REFERENCE.new()
var fighter_charge_target: Node2D
var fighter_charge_active := false
var fighter_charge_start := Vector2.ZERO
var fighter_charge_end := Vector2.ZERO
var fighter_charge_elapsed := 0.0
var fighter_charge_duration := 0.0
var fighter_charge_afterimage_timer := 0.0
var fighter_charge_chain_count := 0
var fighter_charge_cooldown_timer := 0.0
var fighter_charge_config := {"max_chains": 1}
var fighter_courage_bonus := 0.0
var fighter_charge_kill_heal := 0.0
var fighter_charge_impact_candidates: Array = []
var attack_damage := 100
var current_hp := 100
var attack_pose_timer := 0.0
var velocity := Vector2.ZERO
var hero_sprite = Sprite2D.new()
var candidates: Array = []
var next_target: Node2D
var impacts := 0
var afterimages := 0
var healed := 0
var on_clamp: Callable
class Policy:
    static func is_detectable(node: Node) -> bool:
        return is_instance_valid(node) and not node.is_queued_for_deletion() and node.current_hp > 0
const HERO_TARGET_POLICY = Policy
func _face_attack_direction(_x): pass
func _restart_stage1_animation(_a, _b): pass
func _play_fighter_attack_effect(_a, _b): pass
func _play_fighter_thrust_audio(_a): pass
func _spawn_fighter_afterimage(_a): afterimages += 1
func _clamp_to_battlefield():
    if on_clamp.is_valid(): on_clamp.call()
func _fill_monster_nodes_near(_p, _r, buffer): buffer.assign(candidates)
func _play_fighter_charge_impact_effect(): impacts += 1
func _find_fighter_charge_target(_exclude) -> Node2D: return next_target
func heal_direct(amount): healed += amount
func _exit_tree(): hero_sprite.free()
'''
header = header.replace("    ", "\t")
for name in ['_begin_fighter_charge_dash','_update_fighter_charge','_complete_fighter_charge_dash','_fighter_charge_damage_target','_finish_fighter_charge']:
    header += function(after,name)
(out/'tests/charge_actor.gd').write_text(header)
