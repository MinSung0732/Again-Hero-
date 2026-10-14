"""Actual formation/modal UI and extracted in-place loading/portrait warmup."""
from pathlib import Path
import re,subprocess,sys
repo=Path(__file__).resolve().parents[1]; out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_formation_view_smoke.gd'],check=True)
def method(source,name):
 start=source.index('func '+name+'('); end=source.find('\nfunc ',start+1)
 return source[start:end if end>=0 else len(source)]+'\n'
warm=(repo/'src/systems/presentation_warmup.gd').read_text()
base='''extends Node
const STAGES := preload("res://src/data/stage_catalog.gd")
const LOAD_BATCH_SIZE := 4
const MAIN_THREAD_BUDGET_US := 4000
signal progress_changed(completed: int,total: int)
var _busy := false
var _common := {}
var _destination := {}
var _cropped := {}
var texture_load_count := 0
'''
(out/'tests/formation_warmup.gd').write_text(base+''.join(method(warm,n) for n in ['get_texture','unique_paths','prepare_hero_lobby','_prepare','_load_texture']))
transition=(repo/'src/systems/scene_transition.gd').read_text()
base='''extends CanvasLayer
signal transition_completed
class View extends Control:
	var progress := 0.0
	func configure(_title: String,_description: String) -> void: progress = 0.0
	func set_progress(value: float) -> void: progress = value
var _view := View.new()
var _retry := Button.new()
func _ready() -> void:
	add_child(_view); add_child(_retry); visible = false
func is_transitioning() -> bool: return visible
'''
(out/'tests/formation_transition.gd').write_text(base+method(transition,'prepare_in_place'))
# Real atlas PNGs and all ten portrait sources; no combat animation directories.
paths=re.findall(r'"portrait_path": "res://([^"\n]+)"',(repo/'src/data/stage_catalog.gd').read_text())
paths.append('assets/art/UI/hero_mode/hero_guild_lobby.png')
paths.append('assets/art/UI/newUI_frame/frame_06.png')
for path in paths:
 target=out/path; target.parent.mkdir(parents=True,exist_ok=True)
 local=repo/path
 target.write_bytes(local.read_bytes() if local.is_file() else subprocess.check_output(['git','show','HEAD:'+path],cwd=repo))
