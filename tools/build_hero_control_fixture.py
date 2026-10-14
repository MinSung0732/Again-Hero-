"""Production weapon runtime and physics wrapper; omit native art actors."""
from pathlib import Path
import subprocess
import sys

repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable, str(repo/'tools/build_hero_weapon_art_fixture.py'), str(out)], check=True)
for path in ['tests/hero_control_status_smoke.gd','src/hero_mode/hero_control_gauge.gd']:
    (out/path).write_bytes((repo/path).read_bytes())
source = (repo/'src/hero/hero.gd').read_text()
start = source.index('func _physics_process(delta: float)')
end = source.index('\nfunc _physics_process_actions', start)
wrapper = source[start:end]
base = '''extends Node2D
class Weapons extends RefCounted:
	var normal_ticks := 0
	var blocked_ticks := 0
	func tick(_delta: float, allow: bool = true) -> void:
		if allow: normal_ticks += 1
		else: blocked_ticks += 1
var player_weapons := Weapons.new()
var player_control_gauge := preload("res://src/hero_mode/hero_control_gauge.gd").new()
var player_controlled := true
var controlled := true
var player_input_suspended := true
var player_moved_this_frame := false
var player_weapon_tick_done := false
var channel_after_tick := false
var current_hp := 100
var is_dying := false
var channeling := false
var purifier_gungnir_casting := false
var fighter_charge_active := false
var rogue_assassination_active := false
var silence_timer := 0.0
var imposed_skill_cooldown := 0.0
var paralysis_timer := 0.0
var paralysis_ratio := 0.0
var petrify_timer := 0.0
var fear_timer := 2.0
var stun_timer := 0.0
var charm_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var velocity := Vector2.ZERO
var status_overlay: Node2D
func _ready() -> void: set_physics_process(false)
func _physics_process_actions(delta: float) -> void:
	player_input_suspended = controlled
	if controlled:
		position.x += 40; fear_timer = maxf(0,fear_timer-delta)
	else:
		player_weapon_tick_done = true; player_weapons.tick(delta)
		if channel_after_tick: player_input_suspended = true
func _move_and_slide_with_obstacle_escape() -> void: pass
func _clamp_to_battlefield() -> void: pass
'''
(out/'tests/hero_control_physics_harness.gd').write_text(base+wrapper)
gauge = (repo/'src/hero_mode/hero_control_gauge.gd').read_text()
gauge = gauge.replace('canvas: CanvasItem','canvas').replace('canvas.draw_','canvas.record_draw_')
(out/'tests/hero_control_gauge_draw_harness.gd').write_text(gauge)
