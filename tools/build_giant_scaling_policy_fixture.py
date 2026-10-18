"""Isolated production giant/promotion functions and exact spawn-scaling block.
Catalog scene preloads are removed; refresh/level scaling services are stubs.
"""
from pathlib import Path
import argparse,re,subprocess,shutil
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);p.add_argument('--allow-changed-method',action='append',default=[],help='Explicitly audited later-phase changes');a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents:raise SystemExit('Use directory outside repository')
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
 s=re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(s)
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text()
spawn_before=method(before,'_spawn_monster');spawn_after=method(after,'_spawn_monster')
slow_start=spawn_before.index('\tif monster_type == "spider":');slow_end=spawn_before.index('\n\tvar max_hp_value',slow_start)
slow=spawn_before[slow_start:slow_end]
if '_spawn_monster' not in a.allow_changed_method:
 assert spawn_before.replace(slow,'\t_apply_monster_spawn_property_multipliers(monster, monster_type)\n')==spawn_after,'spawn edits outside slow binding'
changed={'_spawn_monster','_apply_giant_monster_base_stats','promote_monster_to_giant'}
changed.update(a.allow_changed_method)
count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in changed:
  assert method(before,name)==method(after,name),name+' unexpectedly changed'
  count+=1
print('Untouched Battle methods identical:',count,'; explicitly allowed:',a.allow_changed_method)
header='''extends Node
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
var spider_slow_duration_multiplier: float = 1.0
var monster_spatial_grid_physics_frame=27
var trace=[]
func _apply_normal_augments_to_existing_monster(monster,id):
 trace.append([id,monster.scale,monster.get_meta_list().map(func(key):return [key,monster.get_meta(key)])])
'''
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ ', '\t',header,flags=re.M)
 for name in ['GIANT_MONSTER_STAT_MULTIPLIER','GIANT_MONSTER_HP_MULTIPLIER','GIANT_MONSTER_SIZE_MULTIPLIER']:
  s+=re.search(r'^const '+name+r'.*$',text,re.M).group()+'\n'
 if label=='before':s+=re.search(r'^const GIANT_RANGED_MONSTER_IDS := \[[\s\S]*?^\]',text,re.M).group()+'\n'
 for name in ['_apply_giant_monster_base_stats','promote_monster_to_giant']:
  s+='\n'+method(text,name)
 if label=='after':
  s+='\n'+method(text,'_apply_monster_spawn_property_multipliers')
  if 'func _apply_giant_stat_property_rules(' in text:s+='\n'+method(text,'_apply_giant_stat_property_rules')
 else:s+='\nfunc _apply_monster_spawn_property_multipliers(monster: Node, monster_type: String) -> void:\n'+slow+'\n'
 spawn=method(text,'_spawn_monster')
 begin=spawn.index('\tvar raw_speed_value =');end=spawn.index('\n\tvar speed_value =',begin)
 s+='\nfunc capture_spawn_raw(monster: Node) -> void:\n'+spawn[begin:end]+'\n'
 (out/(label+'.gd')).write_text(s)
legacy=re.search(r'\tif monster_type in (\[[\s\S]*?\]):',method(before,'_apply_giant_monster_base_stats')).group(1)
(out/'legacy.gd').write_text('extends RefCounted\nconst BASIC_IDS='+legacy+'\n')
shutil.copy2(repo/'tests/giant_scaling_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="GiantScalingPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Catalog dependencies:',len(seen),'; scene resources null')
