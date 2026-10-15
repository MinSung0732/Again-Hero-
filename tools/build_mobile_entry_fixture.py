"""Entry controller regression: real code, asset-light loading view/destinations.

The real Battle scope, Hero resource loader, visual caches, cinematic install and
SceneTransition run; destination stubs isolate entry ordering from GPU artwork.
"""
from pathlib import Path
import argparse, subprocess, sys
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[1];out=a.destination.resolve()
subprocess.run([sys.executable,str(r/'tools/build_online_fixture.py'),str(out)],check=True)
(out/'tests/mobile_warm_stub.gd').write_text('''extends Node
const MAIN_THREAD_BUDGET_US := 4000
signal progress_changed(done: int,total: int)
var previous: WeakRef
var saw_released := false
var release_count := 0
func get_texture(_path: String) -> Texture2D: return null
func release_destination() -> void: release_count += 1
func prepare_common() -> bool:
 saw_released = previous == null or previous.get_ref() == null
 await get_tree().process_frame
 return true
func prepare_scene(_path: String,_options: Dictionary = {}) -> bool:
 progress_changed.emit(1,1)
 await get_tree().process_frame
 return true
''')
text=(out/'project.godot').read_text().replace('*res://src/systems/presentation_warmup.gd','*res://tests/mobile_warm_stub.gd')
(out/'project.godot').write_text(text)
(out/'tests/mobile_destination.gd').write_text('''extends Node
var prepared := false
var options := {}
func _ready(): options = SceneTransition.consume_entry_options()
func prepare_presentation():
 await get_tree().process_frame
 prepared = true
''')
for path in ['src/main/Main.tscn','src/hero_mode/HeroMode.tscn']:
 (out/path).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/mobile_destination.gd" id="1"]\n[node name="Destination" type="Node"]\nscript = ExtResource("1")\n')
Image.new('RGBA',(8,8),'white').save(out/'tests/mobile_probe.png')
print('Entry test destination stubs written; production files unchanged.')
