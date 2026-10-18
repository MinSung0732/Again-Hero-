"""Actual summon/fusion/candidate/consume methods; spatial/spawn services adapted."""
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
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text()
def normalize(text):return text.replace('kobolt_fusion_scratch','fusion_scratch').replace('kobolt_fusion_candidates','fusion_candidates')
changed={'_perform_summon','_try_fuse_nearby_kobolts','_is_normal_kobolt_fusion_candidate'};count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in changed:
  assert normalize(method(before,name))==method(after,name),name;count+=1
left=normalize(method(before,'_perform_summon')).replace('if monster_type == "kobolt" and is_instance_valid(primary_monster):\n\t\tprimary_monster = _try_fuse_nearby_kobolts(primary_monster)','FUSION_BINDING')
right=method(after,'_perform_summon');start=right.index('var fusion_profile :=');end=right.index('\n\trun_metrics.record_summon',start);right=right[:start]+'FUSION_BINDING'+right[end:];assert left==right
print('Other Battle methods identical after scratch rename:',count,'; summon owner order identical outside binding')
queue=['src/data/monster_catalog.gd','src/data/transcendence_catalog.gd','src/data/demon_ultimate_catalog.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);s=(repo/path).read_text();queue+=re.findall(r'preload\("res://([^"\n]+\.gd)"\)',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','');(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
header='''extends Node2D
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
const TRANSCENDENCE_DATA=preload("res://src/data/transcendence_catalog.gd")
const DEMON_ULTIMATES=preload("res://src/data/demon_ultimate_catalog.gd")
signal transcendence_changed(id,active,consumed)
signal transcendent_summoned(id,actor)
signal command_changed(power,capacity)
signal summon_result(id,ok,message)
var fusion_scratch=[]
var fusion_candidates=[]
var configs={}
var events=[]
var query=[]
var direct_population_ids={}
var monster_summon_costs={}
var active_monsters={}
var active_elite_skeletons={}
var monster_spatial_grid_physics_frame=27
var monsters_alive=0
var spawn_count=0
var spawn_failure_call=-1
var spawn_mutates=false
var append_primary=false
var command_power:float=100.0
var max_command:float=100.0
var demon_exp_gain_multiplier:float=1.25
var hero
var run_metrics
var transcendence
class Actor extends Node2D:
 var monster_type="kobolt"
 var current_hp=10
class Recorder extends RefCounted:
 var owner
 var monster_id="zeus"
 func record_command(cost):owner.events.append(["command",cost]);return false
 func consume():owner.events.append("consume_transcendence")
 func record_summon(id,cost):owner.events.append(["metric_summon",id,cost])
 func record_summon_demon_exp(id,xp):owner.events.append(["metric_xp",id,xp])
func _init():
 run_metrics=Recorder.new();run_metrics.owner=self
 transcendence=Recorder.new();transcendence.owner=self
 command_changed.connect(func(power,capacity):events.append(["command_signal",power,capacity]))
 summon_result.connect(func(id,ok,msg):events.append(["result",id,ok,msg]))
func _get_special_augment_config(id) -> Dictionary:
 events.append(["config",String(id)])
 return configs.get(id,{})
func fill_monsters_near(point,radius,output):
 events.append(["query",point,radius])
 output.append_array(query)
func _clamp_manual_spawn_position(point):events.append(["clamp",point]);return point.clamp(Vector2(0,0),Vector2(200,300))
func _spawn_monster(id,point,cost,split,modifiers={}):
 spawn_count+=1
 events.append(["spawn",id,point,cost,split,modifiers.duplicate(),monsters_alive])
 if spawn_mutates:modifiers["mutated"]=true
 if spawn_count==spawn_failure_call:return null
 var actor=Actor.new();actor.name="spawn%d"%spawn_count;actor.monster_type=id;add_child(actor);actor.global_position=point
 for key in modifiers:actor.set_meta(key,modifiers[key])
 active_monsters[actor.get_instance_id()]=actor;monster_summon_costs[actor.get_instance_id()]=cost
 if modifiers.get("counts_population",false):direct_population_ids[actor.get_instance_id()]=true
 monsters_alive+=1
 if append_primary and spawn_count==1:query.push_front(actor)
 return actor
func _unregister_monster(id):
 events.append(["unregister",active_monsters[id].name])
 active_monsters.erase(id);direct_population_ids.erase(id)
func _roll_giant_monster_for_normal_summon():return false
func _spawn_extra_normal_summon_monsters(id,point):events.append(["extra",id,point])
func _emit_stats():events.append(["stats",monsters_alive,command_power])
func _get_monster_name(id):return id
func _gain_demon_exp(value):events.append(["xp",value])
func _add_demon_ultimate_charge(value):events.append(["ultimate",value])
'''
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),header,flags=re.M)
 names=['_perform_summon','_consume_monster_for_fusion']
 names+=['_try_fuse_nearby_kobolts','_is_normal_kobolt_fusion_candidate'] if label=='before' else ['_try_fuse_nearby_monsters','_is_normal_fusion_candidate']
 for name in names:s+='\n'+normalize(method(text,name))
 s+='\nfunc invoke(actor,profile):\n\treturn '+('_try_fuse_nearby_kobolts(actor)' if label=='before' else '_try_fuse_nearby_monsters(actor,profile)')+'\n'
 s+='\nfunc candidate(actor,profile):\n\treturn '+('_is_normal_kobolt_fusion_candidate(actor)' if label=='before' else '_is_normal_fusion_candidate(actor,profile)')+'\n'
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/summon_fusion_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="SummonFusionFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual Catalog dependencies:',len(seen),'; scene references null')

# Existing summon EXP regression reads production methods without importing Battle scenes.
(out/'battle_source.txt').write_text(after)
(out/'summon_exp_smoke.gd').write_text((repo/'tests/summon_demon_exp_smoke.gd').read_text().replace('res://src/battle/battle.gd','res://battle_source.txt'))
