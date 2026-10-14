"""Real popup UI/data/textures; asset-light battle hosts."""
from pathlib import Path
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_inventory_detail_smoke.gd'],check=True)
path = 'assets/art/UI/newUI_frame/frame_06.png'
target = out/path; target.parent.mkdir(parents=True,exist_ok=True)
target.write_bytes(subprocess.check_output(['git','show','HEAD:'+path],cwd=repo))
p = out/'project.godot'; p.write_text(p.read_text()+'\n[input_devices]\npointing/emulate_mouse_from_touch=true\n')
source = (repo/'src/hero_mode/hero_mode.gd').read_text()
def method(name):
    start = source.index('func '+name+'('); end = source.find('\nfunc ',start+1)
    return source[start:end]+'\n'
base = '''extends Control
const PAUSE_VIEW := preload("res://src/ui/hero_pause_view.gd")
const INVENTORY_DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
class HUD extends RefCounted:
	const BATTLE_TOP := 470.0
class Pad extends RefCounted:
	var enabled := true
	func reset() -> void: pass
var pad := Pad.new()
var run_chest_gold := 0
var choosing := false
var rolling := false
var entry_ready := true
var account_invalid := false
var paused := false
var battle
var settings_panel: Control
var inventory_dim := ColorRect.new()
var overlay := PanelContainer.new()
var overlay_rows := VBoxContainer.new()
var overlay_default_style: StyleBox
func _ready() -> void:
	add_child(inventory_dim); inventory_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); inventory_dim.hide()
	add_child(overlay); overlay.add_child(overlay_rows); overlay.hide()
var last_action := ""
func _kill_count() -> int: return 2238
func _restart_from_pause(): last_action = "restart"
func _open_settings(): last_action = "settings"
func _leave(): last_action = "leave"
'''
(out/'tests/hero_inventory_binding_harness.gd').write_text(base+''.join(method(n) for n in ['_pause','_show_weapon_info','_show_passive_info','_show_inventory_detail','_clear_overlay','_resume','_unhandled_input']))
