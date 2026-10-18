"""Extract unchanged production method bodies; isolate external Battle services.
Scene preloads are null in this fixture. This is not a full Battle/AI test.
"""
from pathlib import Path
import argparse, re, shutil, subprocess
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);p.add_argument('--allow-changed-method',action='append',default=[],help='Explicitly audited changes outside this historical phase');a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents: raise SystemExit('Use a directory outside repository')
out.mkdir(parents=True,exist_ok=True)
def method(text,name):
 m=re.search(r'^func '+re.escape(name)+r'\(',text,re.M);assert m,name
 n=re.search(r'^func ',text[m.end():],re.M)
 return text[m.start():m.end()+n.start() if n else len(text)].rstrip()+'\n'
def baseline(path):return subprocess.check_output(['git','show',a.baseline+':'+path],cwd=repo,text=True)
# Recursively copy actual Catalog dependencies. Only scene references are replaced.
queue=['src/data/monster_catalog.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);text=(repo/path).read_text()
 queue+=re.findall(r'preload\("res://([^"\n]+\.gd)"\)',text)
 text=re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',text)
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(text)
old_battle=baseline('src/battle/battle.gd')
new_battle=(repo/'src/battle/battle.gd').read_text()
changed={'get_monster_run_detail','_spawn_monster','_apply_special_monster_modifiers','_apply_normal_augments_to_existing_monster'}
changed.update(a.allow_changed_method)
unchanged=0
for name in re.findall(r'^func (\w+)\(',old_battle,re.M):
 if name not in changed:
  assert method(old_battle,name)==method(new_battle,name),name+' unexpectedly changed'
  unchanged+=1
print('Untouched Battle methods identical:',unchanged)
old_catalog=baseline('src/data/monster_catalog.gd').replace('class_name MonsterCatalog','')
old_catalog=re.sub(r'preload\("res://[^"\n]+\.tscn"\)','null',old_catalog)
(out/'catalog_before.gd').write_text(old_catalog)
header='''extends Node
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
var hero_player_mode = false
var hero_control_spawns = Recorder.new()
var elite_monster_skill_runtime = Recorder.new()
var current_stage_data = {"number": 4}
var run_metrics = {"elapsed_seconds": 27.0}
var monster_speed_multiplier: float = 1.13
var monster_damage_multiplier: float = 1.27
var monster_hp_multiplier: float = 1.38
var monster_attack_speed_multiplier = 0.82
var orc_hp_multiplier = 1.71
var trace = []
class Recorder extends RefCounted:
 func register(_a,_b,_c,_d,_e): pass
 func register_elite(_a,_b,_c): pass
func _get_monster_augment_multiplier(_id,stat) -> float:
 return {"hp":1.14,"damage":1.23,"speed":1.19,"attack_cooldown":0.91}.get(stat,1.0)
func _get_special_stat_multiplier(_id,_stat,_elite=false):return 0.76
func _hero_survival_multiplier(_stat,seconds) -> float:return 1.34 + seconds * 0.001
func _get_augment_refresh_profile(_id):
 return {"rarity":{"hp_multiplier":1.2,"damage_multiplier":1.3,"move_speed_multiplier":1.4,"attack_cooldown_multiplier":0.7},"collection_hp":1.17,"collection_damage":1.29}
func _apply_special_augments_to_monster(_monster,_id):trace.append("excluded")
func _apply_demon_level_scaling_to_monster(monster,heal):
 trace.append(["scale",heal,monster.self_destruct_fuse,monster.explosion_damage,monster.get_meta("demon_level_base_max_hp",null)])
func _apply_elite_monster_visual(_monster,_id):trace.append("visual")
func set_elite_skeleton_alive(_monster,_alive):trace.append("skeleton")
func _get_catalog_monster_display_name(id):return id
'''
for label,text in [('before',baseline('src/battle/battle.gd')),('after',(repo/'src/battle/battle.gd').read_text())]:
 result=re.sub(r'^ ', '\t', header, flags=re.M)
 for name in ['_apply_special_monster_modifiers','_apply_normal_augments_to_existing_monster']:
  result+='\n'+method(text,name)
 if label=='after':result+='\n'+method(text,'_get_monster_hp_upgrade_multiplier')
 # Copy actual HP calculation blocks for UI/spawn (other systems are outside scope).
 for name,begin,end,var,idvar in [('detail_hp','\tif base_stats.has("max_hp"):', '\n\tif base_stats.has("attack_damage"):', 'hp_value','monster_id'),('spawn_hp','\tvar max_hp_value = monster.get("max_hp")','\n\tvar base_damage_meta =', 'level_base_hp','monster_type')]:
  source=method(text,'get_monster_run_detail' if name=='detail_hp' else '_spawn_monster')
  block=source[source.index(begin):source.index(end,source.index(begin))]
  if name=='detail_hp':
   # return the value at the exact pre-rounding boundary; surrounding final formula remains statically checked.
   block=block[:block.index('\n\t\tdetail["max_hp"]')]+ '\n\t\treturn hp_value\n\treturn 0.0\n'
  else:block+='\n\treturn monster.get_meta("demon_level_base_max_hp",null)\n'
  result+='\nfunc '+name+'('+idvar+': String, monster: Node) -> float:\n\tvar base_stats = {"max_hp":monster.max_hp}\n\tvar rarity_hp_multiplier: float = 1.2\n\tvar collection_hp_multiplier: float = 1.17\n\tvar spawn_modifiers = monster.get_meta("spawn_modifiers",{})\n'+block+'\n'
 (out/(label+'.gd')).write_text(result)
shutil.copy2(repo/'tests/monster_scaling_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="MonsterScalingPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Extracted before/after Battle methods + HP blocks; scene-free actual Catalog:',len(seen),'dependencies')
