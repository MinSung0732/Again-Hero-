"""Real account/clear/name stores, actual codex UI and extracted Main entry handlers."""
import argparse
from pathlib import Path
import subprocess
from build_hero_combat_effect_fixture import method

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('destination', type=Path)
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]
out = a.destination.resolve()
for script in ['tests/hero_true_name_smoke.gd', 'tests/hero_true_name_entry_smoke.gd', 'tests/hero_codex_smoke.gd']:
    subprocess.run(['python', str(repo/'tools/build_hero_weapon_extension_fixture.py'), str(out), '--script', script], check=True)
for path in ['assets/art/UI/hero_codex/lock_closed.svg', 'assets/art/UI/hero_codex/lock_open.svg']:
    dest = out/path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes((repo/path).read_bytes() if (repo/path).exists() else subprocess.check_output(['git','show','HEAD:'+path],cwd=repo))
source = (repo/'src/main/main.gd').read_text()
header = '''extends RefCounted
const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
const STAGE_INTRO_DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
class BattleSpy:
    var practice_mode := false
    var current_stage_id := "stage_1"
    var current_hero_profile := {"id": "ranged_rookie", "display_name": "alias"}
    func get_snapshot() -> Dictionary: return {"hero_name": current_hero_profile.display_name}
class IntroSpy:
    var received := {}
    func play_dialogue(data): received = data
class HudSpy:
    var visible := true
var battle := BattleSpy.new()
var stage_intro_cutscene := IntroSpy.new()
var hud_layer := HudSpy.new()
var _skip_entry_dialogue := false
var _stage_intro_active := false
var _stage_intro_stage_id := ""
var reveal_count := 0
var battle_count := 0
var snapshot := {}
func _begin_hero_reveal(_data): reveal_count += 1
func _start_battle_after_intro(_stage): battle_count += 1
func _apply_stage_snapshot(data): snapshot = data
'''
header = header.replace('    ', '\t')
for name in ['_begin_stage_entry', '_on_stage_intro_dialogue_event']:
    header += '\n' + method(source, name)
(out/'entry_fixture.gd').write_text(header)
