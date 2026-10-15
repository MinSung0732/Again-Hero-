"""Real Hero shield callback + real native dispatcher with controlled native host.
All source behavior is retained; missing presentation uses the online fixture.
"""
from pathlib import Path
import subprocess,sys
r=Path(__file__).resolve().parents[1];out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(r/'tools/build_online_fixture.py'),str(out)],check=True)
(out/'tests/hero_max_native_host.gd').write_text('''extends "res://tests/hero_weapon_extension_smoke.gd".Hero
var native_calls := 0
var target: Node2D
var attack_range := 500.0
var projectile_speed := 800.0
var rogue_bonus_combo_hits := 0
var sage_attack_serial := 0
var sage_config := {"third_attack_interval":3}
func native_attack(_target: Node2D) -> void: native_calls += 1
func _fill_monster_nodes_near(_point: Vector2,_radius: float,result: Array) -> void:
 result.clear()
 if is_instance_valid(target): result.append(target)
''')
# Quantity regression records the exact production draw dispatch, without GPU.
s=(r/'src/hero_mode/hero_weapon_runtime.gd').read_text();draw=s[s.index('func draw()'):].replace('hero.draw_','hero.record_draw_')
(out/'tests/projectile_draw_harness.gd').write_text('''extends RefCounted
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const EMPTY_ART: Array[Texture2D] = []
var hero
var delivery = null
var evolution = null
var effects: Array = []
var projectiles: Array = []
var fields: Array = []
var research := {}
var visual_clock := 0.25
'''+draw)
