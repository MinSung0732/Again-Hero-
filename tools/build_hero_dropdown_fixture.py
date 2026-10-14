from pathlib import Path
import subprocess,sys
repo=Path(__file__).resolve().parents[1];out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_dropdown_smoke.gd'],check=True)
p=out/'assets/art/UI/newUI_frame/frame_06.png';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(subprocess.check_output(['git','show','HEAD:assets/art/UI/newUI_frame/frame_06.png'],cwd=repo))
s=(repo/'src/hero_mode/hero_mode.gd').read_text()
a=s.index('\tvar pad_row := HBoxContainer.new()');b=s.index('\tvar pad_guide :=',a)
def method(n):
 a=s.index('func '+n+'(');b=s.find('\nfunc ',a+1);return s[a:b]+'\n'
(out/'tests/hero_dropdown_harness.gd').write_text('''extends Control
const INVENTORY_DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
var pad_mode_selector: OptionButton
var selected := -1
func _set_pad_mode(value): selected = value
func build(tabs: TabContainer):
'''+s[a:b]+method('_label')+method('_skin_action_button'))
