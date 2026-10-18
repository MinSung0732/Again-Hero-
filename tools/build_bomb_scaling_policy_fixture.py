"""Actual giant methods and complete numeric spawn block before/after.
Scene references are null; only outer Battle services are adapters.
"""
from pathlib import Path
import argparse,re,subprocess,shutil
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);p.add_argument('--allow-changed-method',action='append',default=[],help='Explicitly audited later-phase changes');a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents:raise SystemExit('Use directory outside repo')
out.mkdir(parents=True,exist_ok=True)
def old(path):return subprocess.check_output(['git','show',a.baseline+':'+path],cwd=repo,text=True)
def method(text,name):
 m=re.search(r'^func '+re.escape(name)+r'\(',text,re.M);assert m,name
 n=re.search(r'^func ',text[m.end():],re.M)
 return text[m.start():m.end()+n.start() if n else len(text)].rstrip()+'\n'
queue=['src/data/monster_catalog.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);s=(repo/path).read_text();queue+=re.findall(r'preload\("res://([^"\n]+\.gd)"\)',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text()
count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in {'_spawn_monster','_apply_giant_monster_base_stats'} and name not in a.allow_changed_method:
  assert method(before,name)==method(after,name),name+' unexpectedly changed';count+=1
def normalize_spawn(text,legacy):
 s=method(text,'_spawn_monster')
 starts=['\tif monster_type == "bomb_rat":','\tif monster_type == "bomb_rat":'] if legacy else ['\tvar runtime_scaling :=','\tvar explosion_property:']
 for begin,end in zip(starts,['\n\tvar damage_value','\n\t_apply_monster_spawn_property_multipliers']):
  start=s.index(begin);finish=s.index(end,start);s=s[:start]+'\t# scaling binding\n'+s[finish:]
 return s
assert normalize_spawn(before,True)==normalize_spawn(after,False),'spawn edits outside two bindings'
print('Untouched Battle methods identical:',count,'; spawn differs only in two binding blocks')
header='''extends Node
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
var monster_speed_multiplier: float = 1.13
var monster_damage_multiplier: float = 1.27
var monster_hp_multiplier: float = 1.38
var monster_attack_speed_multiplier: float = 0.82
var orc_hp_multiplier: float = 1.71
var spider_slow_duration_multiplier: float = 1.19
var demon_damage_factor: float = 1.11
var trace=[]
func _get_monster_augment_multiplier(_id,stat) -> float:
 return {"hp":1.14,"damage":1.23,"speed":1.19,"attack_cooldown":0.91}.get(stat,1.0)
func _get_special_stat_multiplier(_id,_stat,_elite=false) -> float:return 0.76
func _get_monster_collection_upgrade_multiplier(_id,stat) -> float:return 1.17 if stat=="hp_per_level" else 1.29
func _get_demon_level_monster_damage_multiplier(_seconds=-1.0) -> float:return demon_damage_factor
func _apply_demon_level_scaling_to_monster(_actor,preserve):trace.append(["level",preserve])
'''
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ ', '\t',header,flags=re.M)
 for name in ['GIANT_MONSTER_STAT_MULTIPLIER','GIANT_MONSTER_HP_MULTIPLIER','GIANT_MONSTER_SIZE_MULTIPLIER']:
  s+=re.search(r'^const '+name+r'.*$',text,re.M).group()+'\n'
 names=['_apply_giant_monster_base_stats','_apply_monster_spawn_property_multipliers','_get_monster_hp_upgrade_multiplier']
 if label=='after':names+=['_apply_giant_stat_property_rules']
 for name in names:s+='\n'+method(text,name)
 spawn=method(text,'_spawn_monster')
 start=spawn.index('\tvar monster_rarity :=');end=spawn.index('\n\tmonster.set_meta(\n\t\t"monster_collection_upgrade_level"',start)
 locals=spawn[start:end]
 start=spawn.index('\tvar raw_speed_value =');end=spawn.index('\n\t# Give monsters direct access',start)
 s+='\nfunc apply_spawn_stats(monster: Node,monster_type: String,spawn_modifiers: Dictionary,split_child: bool) -> void:\n'+locals+'\n'+spawn[start:end]+'\n'
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/bomb_scaling_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BombScalingPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Catalog dependencies:',len(seen),'; scene preloads null')
