"""Real holy burst and source helpers, with explicit targeting/FX/audio spies."""
from pathlib import Path
import argparse, re, shutil
from delayed_skill_source import without_delayed_skill_guards
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--baseline-file',type=Path,required=True);a=p.parse_args()
out=a.target.resolve()
if out==ROOT or ROOT in out.parents: raise SystemExit('Use a temporary fixture outside checkout')
before=a.baseline_file.read_text();after=(ROOT/'src/hero/hero.gd').read_text()
def function(s,name):
 m=re.search(r'^func '+name+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
names=re.findall(r'^func ([^(]+)\(',before,re.M)
for name in names:
 assert function(before,name)==without_delayed_skill_guards(function(after,name),names=('_cast_archmage_holy_power',)),name
print('Original Hero function comparison:',len(names))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Holy power lifetime fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','src/systems/battle_target_reference.gd','tests/holy_power_lifetime_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
header='''extends Node2D
const BATTLE_TARGET_REFERENCE := preload("res://src/systems/battle_target_reference.gd")
var current_hp := 100
var attack_damage := 100
var archmage_casting_sequence_count := 0
var archmage_casting_sequence := false
var archmage_query_candidates: Array = []
var candidates: Array = []
var cluster: Node2D
var effects: Array = []
var audio := 0
class Policy:
    static func is_detectable(node: Node) -> bool:
        return is_instance_valid(node) and not node.is_queued_for_deletion() and node.current_hp > 0
class Catalog:
    static func is_undead_node(node: Node) -> bool: return node.undead
const HERO_TARGET_POLICY = Policy
const MONSTER_CATALOG = Catalog
func _skill_damage_multiplier(empowered: bool) -> float: return 1.5 if empowered else 1.0
func _find_archmage_holy_cluster_target(_config: Dictionary) -> Node2D: return cluster
func _spawn_archmage_fx(path, kind, first, last, fps, loop, position, scale):
    effects.append([path, kind, first, last, fps, loop, position, scale])
func _play_archmage_holy_burst_audio(): audio += 1
func _fill_monster_nodes_near(_position, _radius, result):
    result.clear()
    result.append_array(candidates)
'''
methods=['_cast_archmage_holy_power','_begin_archmage_casting_sequence','_end_archmage_casting_sequence','_capture_delayed_skill_source','_is_delayed_skill_life_current','_is_delayed_skill_source_current']
for label,source in [('before',before),('after',after)]:
 (out/'tests'/('holy_'+label+'.gd')).write_text(header.replace('    ','\t')+''.join(function(source,n) for n in methods))
