"""Extract real ice/earth/damage/casting methods; query, FX and audio are spies."""
from pathlib import Path
import argparse, re, shutil
from delayed_skill_source import without_delayed_skill_guards
ROOT = Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--baseline-file',type=Path,required=True);a=p.parse_args()
out=a.target.resolve()
if out==ROOT or ROOT in out.parents: raise SystemExit('Use an external temporary fixture')
before=a.baseline_file.read_text();after=(ROOT/'src/hero/hero.gd').read_text()
def function(s,name):
 m=re.search(r'^func '+name+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
names=re.findall(r'^func ([^(]+)\(',before,re.M)
for name in names:
 assert function(before,name)==without_delayed_skill_guards(function(after,name)),name
print('Exact original method comparison:',len(names))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Delayed Hero skills fixture"\n')
for path in ['src/systems/battle_target_reference.gd','src/systems/battle_entity_registry.gd','tests/delayed_hero_skill_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
header='''extends Node2D
const BATTLE_TARGET_REFERENCE := preload("res://src/systems/battle_target_reference.gd")
var archmage_skill_config := {"ice_bolt": {"pillar_count": 3, "pillar_spawn_radius": 50.0, "pillar_hit_radius": 100.0}}
var attack_damage := 100
var current_hp := 100
var target: Node2D
var hero_sprite := Sprite2D.new()
var archmage_casting_sequence_count := 0
var archmage_casting_sequence := false
var _combat_monster_scratch: Array = []
var candidates: Array = []
var effects: Array = []
var audio := 0
class Policy:
    static func is_detectable(node: Node) -> bool:
        return is_instance_valid(node) and not node.is_queued_for_deletion() and node.current_hp > 0
const HERO_TARGET_POLICY = Policy
func _init(): add_child(hero_sprite)
func _skill_damage_multiplier(empowered: bool) -> float: return 1.5 if empowered else 1.0
func _spawn_archmage_fx(_path, kind, first, last, fps, loop, position, scale):
    effects.append([kind, first, last, fps, loop, position, scale])
func _play_archmage_earth_spike_audio(): audio += 1
func _fill_monster_nodes_near(_position, _radius, result):
    result.clear()
    result.append_array(candidates)
'''
methods=['_resolve_archmage_ice_pillars','_cast_archmage_earth_spikes','_damage_monsters_in_radius','_damage_monsters_in_radius_once','_begin_archmage_casting_sequence','_end_archmage_casting_sequence']
for label,source in [('before',before),('after',after)]:
 extra=['_capture_delayed_skill_source','_is_delayed_skill_life_current','_is_delayed_skill_source_current'] if label=='after' else []
 (out/'tests'/('actor_'+label+'.gd')).write_text(header.replace('    ', '\t')+''.join(function(source,n) for n in methods+extra))
