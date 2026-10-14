"""Reuse the HUD fixture and extract real Hero/choice methods for reroll tests."""
from pathlib import Path
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_hud_fixture.py'),str(output)],check=True)
source = (repo/'src/hero_mode/hero_mode.gd').read_text()
p = output/'tests/hero_hud_harness.gd'
s = p.read_text()
s += '\nvar choosing := false\nvar choice_generation := 0\nvar paused := false\n'
s += source[source.index('func _clear_overlay()'):source.index('func _show_blocked(')]
s += source[source.index('func _show_choices('):source.index('func _pause()')]
p.write_text(s)
hero = (repo/'src/hero/hero.gd').read_text()
method = hero[hero.index('func reroll_player_augment()'):hero.index('signal ultimate_used')]
(output/'tests/hero_reroll_actor.gd').write_text('''extends "res://tests/hero_weapon_extension_smoke.gd".Hero
signal player_augment_requested(candidates: Array)
signal augment_selected(level: int,candidates: Array,chosen_name: String,reason: String,build_summary: String)
signal progression_changed(level: int,current_exp: int,required: int)
var player_controlled := true
var player_weapons
var player_augment_candidates: Array = []
var level := 1
var current_exp := 0
var exp_to_next_level := 60
func _apply_augment(_card: Dictionary) -> void: pass
func get_build_summary() -> String: return "test"
func _level_up() -> void:
	level += 1
	player_augment_candidates = player_weapons.candidates()
	player_augment_requested.emit(player_augment_candidates)
'''+method)
(output/'tests/hero_augment_reroll_smoke.gd').write_text((repo/'tests/hero_augment_reroll_smoke.gd').read_text())
