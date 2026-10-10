"""Real tooltip UI/mouse events and extracted entry gate; persistence/loading are spies."""
from pathlib import Path
import argparse,re,shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--lobby-baseline',type=Path,required=True);p.add_argument('--view-baseline',type=Path,required=True);p.add_argument('--policy-file',type=Path,default=ROOT/'src/systems/dungeon_entry_policy.gd');a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
def function(s,name):
 m=re.search(r'^func '+re.escape(name)+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail);return (tail[:end.start()] if end else tail).rstrip()
before=a.lobby_baseline.read_text();after=(ROOT/'src/lobby/lobby.gd').read_text()
for name in re.findall(r'^func ([^(]+)\(',before,re.M):
 new=function(after,name)
 if name=='_enter_selected_stage':new=new.replace('\tif stamina_view != null:\n\t\tstamina_view.close_info()\n','').replace('stamina_view.show_entry_notice(','stamina_view.show_info(')
 assert function(before,name)==new,name
print('All original lobby bodies preserved except reviewed entry feedback hooks')
out.mkdir(parents=True,exist_ok=True)
(out/'project.godot').write_text('[application]\nconfig/name="Entry input fixture"\n[display]\nwindow/size/viewport_width=1080\nwindow/size/viewport_height=1920\nwindow/subwindows/embed_subwindows=true\n')
for path in ['src/ui/lobby_stamina_view.gd','tests/dungeon_entry_input_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
(out/'tests/stamina_view_before.gd').write_text(a.view_baseline.read_text())
stubs={
 'src/systems/stamina_store.gd':'''extends RefCounted
static func read_state() -> Dictionary: return {"success":true,"amount":30}
static func invalidate(): pass
''',
 'src/data/stamina_catalog.gd':'''extends RefCounted
const ENTRY_COST=5
const MAX_NATURAL=30
const RECOVERY_SECONDS=3600
const EARLY_EXIT_WINDOW_MS=30000
const EARLY_EXIT_REFUND=4
const ICON_PATH=""
''',
 'src/ui/commerce_frame_skin.gd':'''extends RefCounted
static func style(_a,_b=0,_c=Color.WHITE) -> StyleBox: return StyleBoxFlat.new()
''',
 'src/ui/shop_frame_skin.gd':'''extends RefCounted
static func style(_a,_b=0) -> StyleBox: return StyleBoxFlat.new()
static func apply_button(_b): pass
''',
 'src/systems/dungeon_entry_policy.gd':a.policy_file.read_text(),
 'src/systems/transcendence_loadout_store.gd':'''extends RefCounted
static func load_id(): return "zeus"
''',
 'src/ui/transcendence_entry_confirm.gd':'''extends RefCounted
func install(_a): pass
func open(_a): pass
''',
 'tests/Battle.tscn':'[gd_scene format=3]\n[node name="Battle" type="Node"]\n'
}
for path,s in stubs.items():dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(s)
header='''extends Control
class Transition:
	func is_transitioning(): return false
class Tutorial:
	func active() -> bool: return false
class LocalMode:
	var active := false
class StageCatalog:
	func get_stage(_id) -> Dictionary: return {"number":1}
class Progress:
	func is_stage_unlocked(_n): return true
class Modes:
	func blocks_entry(): return false
class Stamina:
	var result := {"success":true,"charged":5}
	var calls := 0
	func try_enter(_id,_exempt) -> Dictionary:
		calls += 1
		return result
class View:
	var info_calls := 0
	var notice_calls := 0
	var closes := 0
	var message := ""
	func close_info(): closes += 1
	func show_info(text): info_calls += 1; message=text
	func show_entry_notice(text): notice_calls += 1; message=text
	func play_entry_cost(_n): pass
var SceneTransition = Transition.new()
var TutorialFlow: Tutorial = Tutorial.new()
var LocalTestMode: LocalMode = LocalMode.new()
var STAGE_CATALOG = StageCatalog.new()
var STAGE_PROGRESS = Progress.new()
var STAMINA = Stamina.new()
var main_modes_view = Modes.new()
var stamina_view = View.new()
var _battle_entry_pending := false
var _scene_load_pending := false
var stage_ids: Array[String] = ["stage_1"]
var selected_stage_index := 0
var team_selected_ids: Array = ["a","b","c"]
var demon_skill_selected_ids: Array = ["a","b","c"]
var _transcendence_entry_confirm
var _stamina_entry: Dictionary = {}
const BATTLE_SCENE_PATH="res://tests/Battle.tscn"
var enter_stage_button: Button
var entered := 0
func _ready():
	enter_stage_button=Button.new()
	add_child(enter_stage_button)
func _begin_threaded_scene_change(_path): entered += 1
'''
(out/'tests/entry_actor.gd').write_text(header+function(after,'_enter_selected_stage')+'\n')
