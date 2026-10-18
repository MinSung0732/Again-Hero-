"""Whole production death callback before/after; external services are adapters.
Actual Catalog/secondary spawn/clamp code, with scene preload references removed.
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
queue=['src/data/monster_catalog.gd','src/data/transcendence_catalog.gd','src/data/hero_mode_catalog.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);s=(repo/path).read_text();queue+=re.findall(r'preload\("res://([^"\n]+\.gd)"\)',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text();count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name!='_on_monster_died':
  assert method(before,name)==method(after,name),name+' unexpectedly changed';count+=1
# Strip only the two moved blocks and fallback binding to verify owner ordering.
normalized=[]
for legacy,text in [(True,before),(False,after)]:
 s=method(text,'_on_monster_died').replace('MONSTER_CATALOG.DEFAULT_DEATH_MONSTER_ID','"slime"')
 starts=['\tif monster_type == "banshee"','\tif (\n\t\tmonster_type == "slime"'] if legacy else ['\tvar death_profile :=','\t_try_spawn_legacy_death_child(']
 for start,end in zip(starts,['\n\tif reward > 0:','\n\t_process_special_death_spawn(']):
  left=s.index(start);right=s.index(end,left);s=s[:left]+'\t# unchanged-phase-policy\n'+s[right:]
 normalized.append(s)
assert normalized[0]==normalized[1],'death owner changed outside policy binding'
print('Untouched Battle methods identical:',count,'; death owner order identical outside bindings')
header='''extends Node2D
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
const TRANSCENDENCE_DATA=preload("res://src/data/transcendence_catalog.gd")
const HERO_SURVIVAL=preload("res://src/data/hero_mode_catalog.gd")
signal command_changed(power,capacity)
signal transcendence_changed(id,active,consumed)
signal transcendent_died(id,actor)
var events=[]
var configs={}
var children=[]
var hero_player_mode=false
var battle_over=false
var hero
var run_metrics
var anubis_army_runtime
var transcendence
var transcendent_actor=null
var battle_command_router
var raw_allied_deaths=0
var raw_tank_deaths=0
var hero_elite_kills_toward_chest=0
var hero_kills_toward_heal_item=0
var hero_kills_toward_chest=0
var hero_kills_toward_magnet=0
var monster_summon_costs={}
var active_monsters={}
var active_elite_skeletons={}
var monster_spatial_grid_physics_frame=27
var death_refund_ratio:float=0.25
var command_power:float=20.0
var max_command:float=30.0
var monsters_alive=3
var banshee_deaths_toward_elite:int=0
var slime_split_chance:float=0.0
var hero_changes_chance=false
var refund_changes_chance=false
var changed_chance:float=1.0
var spawn_failure=false
var mutate_modifiers=false
var spawn_rng=false
var current_stage_id="normal"
var current_map_size:Vector2=Vector2(1080,1920)
class Actor extends Node2D:
 var monster_type="slime"
 var exp_reward=7
class Hero extends Node2D:
 var authority
 func notify_monster_kill(id):
  authority.events.append(["hero_kill",id])
  if authority.hero_changes_chance:authority.slime_split_chance=authority.changed_chance
class Recorder extends RefCounted:
 var authority
 var monster_id="zeus"
 func retire(_id,dead):authority.events.append(["retire",dead])
 func record_ally_death():return false
 func record_monster_death(id):authority.events.append(["metric",id])
 func get_session_id():return 1
func _init():
 hero=Hero.new();hero.authority=self;add_child(hero)
 run_metrics=Recorder.new();run_metrics.authority=self
 anubis_army_runtime=Recorder.new();anubis_army_runtime.authority=self
 transcendence=Recorder.new();transcendence.authority=self
 battle_command_router=Recorder.new();battle_command_router.authority=self
 command_changed.connect(func(power,cap):
  events.append(["refund",power,cap,active_monsters.size()])
  if refund_changes_chance:slime_split_chance=changed_chance
 )
 transcendence_changed.connect(func(id,active,consumed):events.append(["transcendence",id,active,consumed]))
 transcendent_died.connect(func(id,_actor):events.append(["transcendent_died",id,monsters_alive]))
func _get_special_augment_config(id) -> Dictionary:
 events.append(["config",id])
 return configs.get(id,{})
func _spawn_monster(id,point,cost,split,modifiers={}):
 events.append(["spawn",id,point,cost,split,modifiers.duplicate(true),monster_spatial_grid_physics_frame,monsters_alive,banshee_deaths_toward_elite])
 if spawn_rng:events.append(["spawn_rng",randi()])
 if mutate_modifiers:modifiers["fixture_mutation"]=true
 if spawn_failure:return null
 var actor=Actor.new();actor.monster_type=id;actor.position=point
 actor.set_meta("split_child",split)
 for key in modifiers:actor.set_meta(key,modifiers[key])
 children.append(actor)
 monsters_alive+=1
 active_monsters[actor.get_instance_id()]=actor
 monster_summon_costs[actor.get_instance_id()]=cost
 add_child(actor)
 return actor
func _apply_special_monster_modifiers(_actor,id,data):
 events.append(["elite",id,data.duplicate(true)])
 if mutate_modifiers:data["fixture_mutation"]=true
func _apply_ghost_death_empower(actor):events.append(["ghost",actor.monster_type])
func _get_demon_level_monster_exp_multiplier() -> float:return 1.25
func _spawn_exp_orb(point,reward):events.append(["exp",point,reward])
func _spawn_transcendent_exp_drop(point,reward,data):events.append(["trans_exp",point,reward,data])
func _try_spawn_heal_item_from_kills():events.append("heal")
func _try_spawn_chest_from_kills():events.append("chest")
func _try_spawn_magnet_from_kills():events.append("magnet")
func _hero_chest_eligible(_source):return false
func _unregister_monster(id):
 events.append("unregister")
 active_monsters.erase(id)
func _emit_stats():events.append(["stats",monsters_alive,command_power])
func _finish_hero_boss_victory():events.append("boss_victory")
func _spawn_chest_for_session(_session,_source):events.append("elite_chest")
func _uses_castle_battlefield(_id):return current_stage_id=="castle"
'''
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),header,flags=re.M)
 for name in ['HEAL_ITEM_KILLS_REQUIRED','CHEST_KILLS_REQUIRED','MAGNET_KILLS_REQUIRED','MANUAL_SPAWN_MARGIN','CASTLE_TOP_SPAWN_MARGIN']:
  s+=re.search(r'^const '+name+r'.*$',text,re.M).group()+'\n'
 names=['_on_monster_died','_process_special_death_spawn','_spawn_secondary_monsters','_get_spawn_top_margin','_clamp_manual_spawn_position','_chest_kill_requirement']
 if label=='after':names+=['_apply_pre_reward_death_reactions','_try_spawn_legacy_death_child']
 for name in names:s+='\n'+method(text,name)
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/death_reaction_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="DeathReactionPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual Catalog dependencies:',len(seen),'; scene references null')
