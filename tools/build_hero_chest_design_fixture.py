"""Production chest popup methods and cards, with a deterministic reward host."""
from pathlib import Path
import subprocess,sys
repo=Path(__file__).resolve().parents[1]; out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_hud_fixture.py'),str(out)],check=True)
p=out/'assets/art/UI/newUI_frame/frame_06.png';p.parent.mkdir(parents=True,exist_ok=True)
p.write_bytes(subprocess.check_output(['git','show','HEAD:assets/art/UI/newUI_frame/frame_06.png'],cwd=repo))
p=out/'project.godot';p.write_text(p.read_text()+'\n[input_devices]\npointing/emulate_mouse_from_touch=true\n')
s=(repo/'src/hero_mode/hero_mode.gd').read_text()
def method(name):
    start=s.index('func '+name+'('); end=s.find('\nfunc ',start+1)
    return s[start:end]+'\n'
base='''extends Control
const REEL := preload("res://src/ui/hero_chest_reel.gd")
const INVENTORY_DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
class STORE extends RefCounted:
	static var fail := false
	static var calls := 0
	static func record_chest(_entry,_serial,_bonus):
		calls += 1
		return {"success":not fail,"pending":8}
class GameAudio extends RefCounted:
	static func play_battle(_id,_node): pass
class Pad extends RefCounted:
	var enabled := true
	func reset(): pass
var pad := Pad.new()
var battle
var entry := {}
var chest_gold_saved := false
var run_chest_gold := 0
var rolling := false
var pending_chests := 1
var opening_chest_claimed := false
var roulette_tween: Tween
var roulette_reel: Control
var roulette_label: Label
var roulette_details: VBoxContainer
var roulette_continue: Button
var roulette_pool: Array = []
var roulette_receipt := {}
var roulette_index := -1
var inventory_dim := ColorRect.new()
var overlay := PanelContainer.new()
var overlay_rows := VBoxContainer.new()
var overlay_default_style: StyleBox
var refresh_count := 0
func _ready():
	add_child(inventory_dim); inventory_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); inventory_dim.hide()
	add_child(overlay); overlay.add_child(overlay_rows); overlay.hide()
func _refresh_hud(): refresh_count += 1
func _skin_action_button(_button): pass
'''
(out/'tests/hero_chest_binding_harness.gd').write_text(base+''.join(method(n) for n in ['_label','_button','_clear_overlay','_begin_roulette','_roulette_tick','_finish_roulette','_close_roulette']))
(out/'tests/hero_chest_design_smoke.gd').write_text((repo/'tests/hero_chest_design_smoke.gd').read_text())
