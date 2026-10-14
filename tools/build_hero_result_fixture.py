"""Result view and exact production settlement handler, asset-light host."""
from pathlib import Path
import subprocess,sys
repo=Path(__file__).resolve().parents[1];out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_result_smoke.gd'],check=True)
p=out/'assets/art/UI/newUI_frame/frame_06.png';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(subprocess.check_output(['git','show','HEAD:assets/art/UI/newUI_frame/frame_06.png'],cwd=repo))
p=out/'project.godot';p.write_text(p.read_text()+'\n[input_devices]\npointing/emulate_mouse_from_touch=true\n')
s=(repo/'src/hero_mode/hero_mode.gd').read_text()
def method(n):
 a=s.index('func '+n+'(');b=s.find('\nfunc ',a+1);return s[a:b]+'\n'
base='''extends Control
const RESULT_VIEW := preload("res://src/ui/hero_result_view.gd")
const INVENTORY_DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
class HUD extends RefCounted:
	const BATTLE_TOP := 470.0
class STAGES extends RefCounted:
	static var next_id := "stage_2"
	static func get_stage(_id): return {"next_stage_id":next_id}
class STORE extends RefCounted:
	static var calls := 0
	static var fail := false
	static func award_run(_stage,_entry,_seconds,_kills,won,_difficulty,_outcome,_gold_bonus):
		calls += 1
		return {"success":not fail,"research":100 if won else 5,"gold":76 if won else 9,"chest_earned":16,"chest_paid":16 if won else 6,"chest_rate":1.0 if won else 0.4}
	static func can_enter(id,_difficulty): return id == "stage_2"
var battle
var run_abandoned := false
var settled := false
var result_reward := {}
var finished_won := true
var finished_message := "최종 보스를 처치했습니다!"
var stage := "stage_1"
var entry := {}
var run_difficulty := "easy"
var last_action := ""
var inventory_dim := ColorRect.new()
var overlay := PanelContainer.new()
var overlay_rows := VBoxContainer.new()
var overlay_default_style: StyleBox
func _ready():
	add_child(inventory_dim); inventory_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); inventory_dim.hide()
	add_child(overlay); overlay.add_child(overlay_rows)
func _kill_count(): return 7066
func _next_stage(_id): last_action = "next"
func _retry(): last_action = "retry"
func _leave(): last_action = "leave"
'''
(out/'tests/hero_result_binding_harness.gd').write_text(base+method('_clear_overlay')+method('_show_result'))
