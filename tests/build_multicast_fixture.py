"""Real multicast timer/reset slice and source helpers; skill execution is a spy."""
from pathlib import Path
import argparse,re,shutil
from multicast_source import without_multicast_guards
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--baseline-file',type=Path,required=True);a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
before=a.baseline_file.read_text();after=(ROOT/'src/hero/hero.gd').read_text()
def function(s,name):
 m=re.search(r'^func '+name+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
names=re.findall(r'^func ([^(]+)\(',before,re.M)
for name in names:assert function(before,name)==without_multicast_guards(function(after,name)),name
print('Original Hero function comparison:',len(names))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Multicast lifetime fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','tests/multicast_lifetime_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
header='''extends Node2D
var current_hp := 100
var archmage_multicast_stacks := 2
var archmage_multicast_active := false
var archmage_multicast_revision := 0
var archmage_multicast_candidates: Array[String] = []
var archmage_chain_dagger_active := false
var archmage_skill_config := {"combustion":{},"ice_bolt":{},"earth_spikes":{},"holy_power":{},"chain_dagger":{},"storm":{}}
var calls: Array = []
var callback: Callable
var fail_skills: Array = []
func _cast_archmage_skill_internal(key: String, consume: bool, recursive: bool) -> bool:
    calls.append([key,consume,recursive,Time.get_ticks_msec()])
    if callback.is_valid(): callback.call()
    return not fail_skills.has(key)
'''
constant=re.search(r'^const ARCHMAGE_OFFENSIVE_SKILL_KEYS:.*?\n\]',before,re.M|re.S).group(0)+'\n'
for label,source in [('before',before),('after',after)]:
 reset=function(source,'configure_profile')
 reset=reset[reset.index('\tarchmage_multicast_stacks = 0'):reset.index('\tarchmage_blink_stacks = 0')]
 methods=['_start_archmage_multicast','_capture_delayed_skill_source','_is_delayed_skill_life_current','_is_delayed_skill_source_current']+(['_cancel_archmage_multicast'] if label=='after' else [])
 (out/'tests'/('multi_'+label+'.gd')).write_text(header.replace('    ','\t')+constant+'func reset_profile_slice():\n'+reset+'\n'+''.join(function(source,n) for n in methods))
