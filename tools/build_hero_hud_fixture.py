"""Asset-light UI test: exact HeroMode HUD method, no Battle/autoload dependencies."""
from pathlib import Path
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(output),'--script','tests/hero_hud_inventory_smoke.gd'],check=True)
source = (repo/'src/hero_mode/hero_mode.gd').read_text()
method = source[source.index('func _build_ui()'):source.index('func _label(')]
label = source[source.index('func _label('):source.index('func _button(')]
refresh = source[source.index('func _refresh_hud('):source.index('func _show_choices(')]
kills = source[source.index('func _kill_count('):source.index('func _on_finished(')]
frame = source[source.index('func _apply_battle_frame('):source.index('func _restart_from_pause(')]
method = method.replace('SKIN.skin_style(frame)','frame').replace('SKIN.skin_style(style)','style')
base = '''extends Control
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
var battle
class Director extends RefCounted:
	var encounters: Node
var director := Director.new()
class BGM extends Node:
	func update_hero_hp(_hp: int, _max: int) -> void: pass
func _ready() -> void:
	var bgm := BGM.new(); bgm.name = "HeroBGMManager"; add_child(bgm)
const HUD := preload("res://src/ui/hero_survival_hud.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const MOVE_PAD := preload("res://src/hero_mode/hero_move_pad.gd")
var player_hero_id := "sage_astra"
var timer: Label
var opening_chest_claimed := false
var hero_title: Label
var kills_label: Label
var population_label: Label
var battle_frame: Control
var battle_frame_enabled := true
var hp: ProgressBar
var xp: ProgressBar
var status: Label
var stats_panel: PanelContainer
var pad
var pad_mode := "fixed"
var weapon_buttons: Array[Button] = []
var passive_buttons: Array[Button] = []
var overlay: PanelContainer
var inventory_dim: ColorRect
var overlay_default_style: StyleBox
var overlay_rows: VBoxContainer
func _pause() -> void: pass
func _show_weapon_info(_index: int) -> void: pass
func _show_passive_info(_index: int) -> void: pass
func _skin_action_button(_button: Button) -> void: pass
'''
(output/'tests/hero_hud_harness.gd').write_text(base+method+label+refresh+kills+frame)
# Harness reference in test uses load(), so dependencies are explicitly queued there.

# Stage portrait paths are dynamic load() references: fetch only these exact
# tracked PNG blobs into the fixture, without checking out combat frames.
import re
catalog = (repo/'src/data/stage_catalog.gd').read_text()
for path in re.findall(r'"portrait_path": "res://([^"\n]+)"',catalog):
    destination = output/path
    destination.parent.mkdir(parents=True,exist_ok=True)
    local = repo/path
    if local.is_file():
        destination.write_bytes(local.read_bytes())
    elif not destination.is_file():
        data = subprocess.check_output(['git','show','HEAD:'+path],cwd=repo)
        destination.write_bytes(data)
