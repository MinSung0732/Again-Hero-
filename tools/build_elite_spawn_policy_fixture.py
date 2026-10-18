"""Before/after production spawn, geometry, elite conversion and liveness methods.
Scene resources are removed from Catalog fixtures; full Battle services are stubs.
"""
import argparse,re,subprocess,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);a=p.parse_args()
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
 s=re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(s)
s=old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
(out/'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',s))
header='''extends Node2D
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const HERO_SURVIVAL = Survival
var hero_player_mode = false
var campaign_difficulty = "easy"
var current_stage_data = {"number":4}
var current_stage_id = "stage_1"
var current_map_size: Vector2 = Vector2(1080,1920)
var hero: Node2D
var hero_control_roster = {}
var hero_control_spawns = Recorder.new()
var elite_monster_skill_runtime = Recorder.new()
var run_metrics = {"elapsed_seconds":27.0}
var active_elite_skeletons = {}
var trace = []
var actors = []
var spawn_failure = false
var remapped_id = ""
class Survival extends RefCounted:
 static var allowed = true
 static func monster_allowed(_id,_stage,_difficulty):return allowed
class Recorder extends RefCounted:
 func register(_a,_b,_c,_d,_e):pass
 func register_elite(_a,_b,_c):pass
class Actor extends Node2D:
 var attack_cooldown = 0.8
 var self_destruct_fuse = 0.3
 var explosion_damage = 28
 var current_hp = 16
 var max_hp = 140
 var exp_reward = 7
func hero_spawn_candidate(id,_roster,_elite):return id if remapped_id.is_empty() else ("" if remapped_id=="deny" else remapped_id)
func _spawn_monster(id,point,cost,split,modifiers):
 trace.append(["spawn",id,point,cost,split,modifiers])
 if spawn_failure:return null
 var actor=Actor.new()
 actor.position=point
 actor.set_meta("demon_level_base_max_hp",140.0)
 actor.set_meta("demon_level_base_move_speed",78.0)
 actor.set_meta("demon_level_base_attack_damage",18.0)
 add_child(actor)
 actors.append(actor)
 return actor
func _emit_stats():trace.append("stats")
func _apply_special_augments_to_monster(_monster,_id):trace.append("augments")
func _apply_demon_level_scaling_to_monster(_monster,_heal):trace.append("scaling")
func _apply_elite_monster_visual(_monster,_id):trace.append("visual")
func _get_catalog_monster_display_name(id):return id
func _uses_castle_battlefield(_id):return current_stage_id=="castle"
'''
before=old('src/battle/battle.gd');after=(repo/'src/battle/battle.gd').read_text()
changed={'spawn_special_monster','_apply_special_monster_modifiers','_get_farthest_kobolt_attack_spawn_position','_get_stage_event_spawn_position'}
count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in changed:
  assert method(before,name)==method(after,name),name+' unexpectedly changed'
  count+=1
# Geometry is a pure rename/comment edit. Assert all mathematical operations identical.
assert method(before,'_get_farthest_kobolt_attack_spawn_position').replace('_get_farthest_kobolt_attack_spawn_position','_get_farthest_attack_range_spawn_position').replace('stationary kobolt','stationary actor')==method(after,'_get_farthest_attack_range_spawn_position')
assert method(before,'_get_stage_event_spawn_position').replace('spawn_distance: float = 720.0','spawn_distance: float = MONSTER_CATALOG.DEFAULT_ELITE_SPAWN_DISTANCE')==method(after,'_get_stage_event_spawn_position')
print('Untouched Battle methods identical:',count,'; range geometry identical after rename')
for label,text in [('before',before),('after',after)]:
 s=re.sub(r'^ ', '\t',header,flags=re.M)
 for name in ['MANUAL_SPAWN_MARGIN','CASTLE_TOP_SPAWN_MARGIN']:
  s+=re.search(r'^const '+name+r'.*$',text,re.M).group()+'\n'
 names=['spawn_special_monster','_apply_special_monster_modifiers','_get_stage_event_spawn_position','_get_farthest_stage_event_spawn_position','_get_spawn_top_margin','_clamp_manual_spawn_position','set_elite_skeleton_alive','_on_elite_skeleton_tree_exited','has_living_elite_skeleton']
 names+=['_get_farthest_kobolt_attack_spawn_position'] if label=='before' else ['_get_farthest_attack_range_spawn_position','_get_special_monster_spawn_position']
 for name in names:s+='\n'+method(text,name)
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/elite_spawn_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="EliteSpawnPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual Catalog dependencies:',len(seen),'; scene preloads null')
