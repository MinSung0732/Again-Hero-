"""Extract actual secondary-spawn methods; use controlled spawn/config adapters.
Catalog dependencies are actual data; scene preloads are null in this fixture.
"""
from pathlib import Path
import argparse,re,subprocess,shutil
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents:raise SystemExit('Use directory outside repository')
out.mkdir(parents=True,exist_ok=True)
def old(path):return subprocess.check_output(['git','show',a.baseline+':'+path],cwd=repo,text=True)
def method(text,name):
 m=re.search(r'^func '+re.escape(name)+r'\(',text,re.M);assert m,name
 n=re.search(r'^func ',text[m.end():],re.M)
 return text[m.start():m.end()+n.start() if n else len(text)].rstrip()+'\n'
queue=['src/data/monster_catalog.gd','src/data/demon_augment_catalog.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);s=(repo/path).read_text();queue+=re.findall(r'preload\("res://([^"\n]+\.gd)"\)',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text();count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in {'_process_special_death_spawn','_spawn_extra_normal_summon_monsters'}:
  assert method(before,name)==method(after,name),name+' unexpectedly changed';count+=1
print('Untouched Battle methods identical:',count,'; death reward owner and primary spawn unchanged')
header='''extends Node
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
var configs={}
var events=[]
var children=[]
var modifier_refs=[]
var attempts=0
var success_limit=-1
var mutate_modifiers=false
var mutate_config=false
var clamp_mutates_config=false
var spawn_rng=false
var current_stage_id="normal"
var current_map_size:Vector2=Vector2(1080,1920)
func _get_special_augment_config(id):
 events.append(["config",id])
 return configs.get(id,{})
func _uses_castle_battlefield(_id):return current_stage_id=="castle"
func _clamp_manual_spawn_position(point:Vector2) -> Vector2:
 events.append(["clamp",point])
 if clamp_mutates_config:change_config()
 return _fixture_actual_clamp(point)
func change_config():
 for per_monster in configs.values():
  for config in per_monster.values():
   if config.has("hp_multiplier"):config["hp_multiplier"]=float(config["hp_multiplier"])+0.1
func _spawn_monster(id,point,cost,split,modifiers={}):
 attempts+=1
 events.append(["spawn",id,point,cost,split,modifiers.duplicate(true)])
 modifier_refs.append(modifiers)
 if spawn_rng:events.append(["spawn_rng",randi()])
 if mutate_modifiers:modifiers["fixture_mutated"]=attempts
 if mutate_config:change_config()
 if success_limit>=0 and children.size()>=success_limit:return null
 var actor=Node2D.new()
 actor.position=point
 actor.set_meta("split_child",split)
 for key in modifiers:actor.set_meta(key,modifiers[key])
 children.append(actor)
 return actor
'''
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),header,flags=re.M)
 for name in ['MANUAL_SPAWN_MARGIN','CASTLE_TOP_SPAWN_MARGIN']:
  s+=re.search(r'^const '+name+r'.*$',text,re.M).group()+'\n'
 names=['_process_special_death_spawn','_spawn_extra_normal_summon_monsters','_get_spawn_top_margin']
 if label=='after':names+=['_spawn_secondary_monsters']
 for name in names:s+='\n'+method(text,name)
 s+='\n'+method(text,'_clamp_manual_spawn_position').replace('func _clamp_manual_spawn_position(','func _fixture_actual_clamp(',1)
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/secondary_spawn_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="SecondarySpawnPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual Catalog dependencies:',len(seen),'; scene references null')
