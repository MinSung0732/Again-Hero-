"""Actual ready startup slice + actual selection loaders; store/catalog/UI are spies."""
from pathlib import Path
import argparse,re,shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--baseline-file',type=Path,required=True);p.add_argument('--policy-file',type=Path,default=ROOT/'src/systems/dungeon_entry_policy.gd');a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary directory outside checkout')
before=a.baseline_file.read_text();after=(ROOT/'src/lobby/lobby.gd').read_text()
def function(s,name):
 m=re.search(r'^func '+name+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail);return (tail[:end.start()] if end else tail).rstrip()
hook='\t# Entry validation needs saved selections even before the team tab is opened.\n\t_setup_team_preview()\n\t_setup_demon_skill_preview()\n'
assert after.count(hook)==1
for name in re.findall(r'^func ([^(]+)\(',before,re.M):assert function(before,name)==function(after,name).replace(hook,''),name
print('All original lobby bodies preserved except exact ready load hooks')
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Formation startup fixture"\n')
for path,source in [('tests/lobby_formation_startup_smoke.gd',(ROOT/'tests/lobby_formation_startup_smoke.gd').read_text()),('src/systems/dungeon_entry_policy.gd',a.policy_file.read_text())]:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(source)
header='''extends Node
const TEAM_MAX_SLOTS=3
class Monsters:
	var ORDER=["a","b","c","locked","transcendent"]
	var MONSTERS={"a":{},"b":{},"c":{},"locked":{},"transcendent":{}}
class Transcendence:
	func is_transcendent(id):return id=="transcendent"
class Collection:
	var loads:=0
	var unlocked=["a","b","c"]
	func load_state() -> Dictionary:
		loads+=1
		return {"unlocked":unlocked}
	func get_unlocked_ids(state) -> Array:return state.unlocked
class Skills:
	func get_ordered_ids():return ["s1","s2","s3","unimplemented"]
	func get_skill(id) -> Dictionary:return {"implemented":id!="unimplemented"}
class Loadout:
	var saved: Array=[]
	var loads:=0
	func load_ids(available,fallback) -> Array:
		loads+=1
		# spy for persistence filtering; real loader call and fallback inputs retained
		var result: Array=[]
		for id in (saved if not saved.is_empty() else fallback):
			if id in available and id not in result:result.append(id)
			if result.size()==3:break
		return result
class Cache:
	var installed:=false
	var clears:=0
	var rebuilds:=0
	func install(_actor):installed=true
	func clear_grid():assert(installed);clears+=1
var MONSTER_CATALOG=Monsters.new()
var TRANSCENDENCE_DATA=Transcendence.new()
var MONSTER_COLLECTION_STORE: Collection=Collection.new()
var DEMON_ULTIMATES: Skills=Skills.new()
var TEAM_LOADOUT_STORE=Loadout.new()
var DEMON_SKILL_LOADOUT_STORE=Loadout.new()
var _formation_card_cache=Cache.new()
var team_catalog_ids: Array=[]
var team_available_ids: Array=[]
var team_selected_ids: Array=[]
var demon_skill_catalog_ids: Array=[]
var demon_skill_selected_ids: Array=[]
var monster_collection_state: Dictionary={}
var formation_mode="team"
var team_status_label=Label.new()
var team_summary_label=Label.new()
var current_tab=""
func _switch_tab(id):current_tab=id
func _refresh_team_preview():pass
func dispose():team_status_label.free();team_summary_label.free()
'''
for variant,source in [('before',before),('after',after)]:
 ready=function(source,'_ready');start=ready.index('\t_formation_card_cache.install(self)');end=ready.index('\n\t_refresh_header()',start)
 result=header+'func initialize_from_real_ready_slice():\n'+ready[start:end]+'\n\n'
 for name in ['_setup_team_preview','_setup_demon_skill_preview','_restore_saved_team_selection','_clear_team_monster_cards']:result+=function(source,name)+'\n\n'
 (out/f'tests/formation_{variant}.gd').write_text(result)
