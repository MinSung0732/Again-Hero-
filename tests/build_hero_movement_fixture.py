"""Compare real specialized action tails and no-target movement before/after.

Unmodified timer/skill prefixes are checked by canonical source comparison.
Queries, steering, collision, skill activation and attack bodies are spies.
"""
import argparse
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("target", type=Path)
parser.add_argument("--baseline-file", type=Path)
args = parser.parse_args()
target = args.target.resolve()
if target == ROOT or ROOT in target.parents:
    raise SystemExit("Use a separate temporary fixture directory")
before = (args.baseline_file.read_text() if args.baseline_file else
          subprocess.check_output(["git", "show",
              "51ebf2e426e4df88f27020a2f489fe9f9afd1030:src/hero/hero.gd"],
              cwd=ROOT, text=True))
after = (ROOT / "src/hero/hero.gd").read_text()


def function(source, name):
    m = re.search(r"^func " + re.escape(name) + r"\(", source, re.M)
    if m is None:
        raise RuntimeError("Missing function " + name)
    tail = source[m.start():]
    end = re.search(r"\nfunc ", tail)
    return (tail[:end.start()] if end else tail).rstrip() + "\n\n"


ATTACKS = {"SUMMONER": "_summoner_basic_attack", "ALCHEMIST": "_start_alchemist_basic_attack",
           "GUNNER": "_gunner_attack", "ROGUE_COMBO": "_rogue_combo_attack",
           "BERSERKER": "_berserker_basic_attack", "FIGHTER": "_fighter_basic_attack"}


def expand_port_calls(source):
    """Mechanically restore original statements for whole-body comparison."""
    lines = source.replace("action_intent", "ranged_action_intent").splitlines(keepends=True)
    output = []
    i = 0
    while i < len(lines):
        m = re.match(r"^(\t+)_execute_ai_movement\((.*)\n$", lines[i])
        if m:
            indent, expression = m.groups()
            if expression == "":
                output.append(indent + "velocity = (\n")
                balance = 1
                while balance and i + 1 < len(lines):
                    i += 1
                    output.append(lines[i])
                    balance += lines[i].count("(") - lines[i].count(")")
            else:
                output.append(indent + "velocity = " + expression[:-1] + "\n")
            output.extend([indent + "_move_and_slide_with_obstacle_escape()\n",
                           indent + "_clamp_to_battlefield()\n"])
        else:
            m = re.match(r"^(\t+)_execute_ai_basic_attack\(HERO_ACTION_INTENT.AttackKind.(\w+), (.*)\)\n$", lines[i])
            if m:
                indent, kind, argument = m.groups()
                output.append(indent + ATTACKS[kind] + "(" + argument + ")\n")
            else:
                output.append(lines[i])
        i += 1
    return "".join(output)


names = re.findall(r"^func ([^(]+)\(", before, re.M)
changed = 0
for name in names:
    old, new = function(before, name), function(after, name)
    assert old == expand_port_calls(new), "Original semantics changed in " + name
    changed += old != new
print("All original Hero bodies preserved after port expansion:", len(names))
print("Unchanged functions:", len(names) - changed, "; routed/renamed functions:", changed)
target.mkdir(parents=True, exist_ok=True)
baseline_path = target / "hero_before.txt"
baseline_path.write_text(before)
subprocess.run(["python3", str(ROOT / "tests/build_hero_action_fixture.py"), str(target),
                "--baseline-file", str(baseline_path)], check=True)
header = (target / "tests/hero_action_after_fixture.gd").read_text().split("func _physics_process(")[0]
for name in ["_move_without_monsters"] + ["_physics_process_" + a for a in
             ["rogue", "fighter", "gunner", "berserker", "alchemist", "summoner"]]:
    header = header.replace(function(header, name).rstrip(), "")
header += '''
const WANDER_REACHED_DISTANCE := 80.0
var heal_item_target: Node2D
var magnet_item_target: Node2D
var chest_target: Node2D
var exp_target: Node2D
var material_target_spy: Node2D
var wander_target := Vector2(1400, 1500)
var steer_enabled := true
var no_target_branch := ""
var attack_damage := 220.0
var attack_cooldown := 1.5
var gunner_reloading := false
var gunner_reload_move_speed_bonus := 0.5
var deadeye_ready := false
var rogue_combo_index := 2
var rogue_combo_direction := Vector2.RIGHT
var rogue_slash_active := false
var rogue_slash_config := {"move_speed_multiplier": 0.48}
var fighter_guard_active := false
var fighter_guard_move_multiplier_bonus := 0.0
var fighter_charge_cooldown_timer := 1.0
var charge_ready := false
var ultimate_config := {"move_speed_multiplier": 0.62}
var berserker_madness_active := false
var berserker_config := {"madness_target_radius": 375.0}
var contextual_skill := false
var alchemist_config := {"basic_gas_cost": 10.0}
var alchemist_gas := 100.0
var alchemist_throw_index := 0
var alchemist_throw_positions: Array = []
var kite_distance := 280.0
var chest_attack_target: Node2D
var reenter_port := false
var replay_rejected := false
func _choose_melee_spacing_direction(_target: Node2D, distance: float, spacing: float) -> Vector2:
	events.append(["melee_choose", distance, spacing])
	return Vector2(0.75, -0.25) if steer_enabled else Vector2.ZERO
func _apply_gunner_boundary_steering(direction: Vector2) -> Vector2:
	events.append("gunner_boundary")
	return direction.rotated(-0.2)
func _apply_summoner_open_gate_tether(direction: Vector2) -> Vector2:
	events.append("gate_tether")
	return direction * 0.85
func _get_alchemist_field_speed_multiplier() -> float:
	return 0.7
func _find_nearest_active_alchemy_material() -> Node2D:
	events.append("material_query")
	return material_target_spy
func _get_alchemist_chest_attack_target() -> Node2D:
	events.append("alchemy_chest_target")
	return chest_attack_target
func _gunner_should_start_deadeye() -> bool:
	events.append("deadeye_decide")
	return deadeye_ready
func _start_gunner_deadeye() -> void:
	events.append("deadeye_start")
func _fighter_should_start_charge() -> bool:
	events.append("charge_decide")
	return charge_ready
func _start_fighter_charge() -> void:
	events.append("charge_start")
func _try_use_berserker_contextual_skill(_target: Node2D, distance: float) -> bool:
	events.append(["contextual", distance])
	return contextual_skill
func _find_nearest_exp_orb() -> Node2D:
	events.append("exp_query")
	return exp_target
func _pick_new_wander_target() -> void:
	events.append("pick_wander")
	wander_target = Vector2(1500, 1400)
	wander_timer = 3.0
func _get_common_attack_interval(interval: float) -> float:
	return interval * 0.9
'''
# Let zero steering scenarios reach the existing no-move branches, while
# normal scenarios use the same noncommutative steering spies as prior tests.
header = header.replace('return direction + Vector2(0.1, 0.0)',
                        'return direction + Vector2(0.1, 0.0) if steer_enabled else Vector2.ZERO')
header = header.replace('return direction.rotated(0.1)',
                        'return direction.rotated(0.1) if steer_enabled else Vector2.ZERO')
header = header.replace('return direction * 0.8\n',
                        'return direction * 0.8 if steer_enabled else Vector2.ZERO\n')
header = header.replace('events.append("move")', '''events.append("move")
	if reenter_port:
		replay_rejected = not HERO_ACTION_PORT.execute_movement(self, action_intent)''')
for method in ATTACKS.values():
    header += f'''func {method}(current_target: Node2D) -> void:
	events.append(["{method}", current_target.get_instance_id() if is_instance_valid(current_target) else 0])
	if reenter_port:
		replay_rejected = not HERO_ACTION_PORT.execute_basic_attack(self, action_intent, current_target)
	attack_timer = 1.5
'''
for name in ["rogue", "fighter", "gunner", "berserker", "alchemist", "summoner"]:
    header += f'func _update_{name}_pose_visual(_delta: float) -> void:\n\tevents.append("{name}_pose")\n'

for label, source in [("before", before), ("after", after)]:
    methods = ""
    for archetype in ["rogue", "fighter", "gunner", "berserker", "alchemist", "summoner"]:
        name = "_physics_process_" + archetype
        full = function(source, name)
        marker = ("\tvar alchemist_move_speed :=" if archetype == "alchemist" else
                  "\t_update_heal_item_goal(delta)")
        methods += f"func {name}(delta: float) -> void:\n" + full[full.index(marker):]
    for name in ["_move_without_monsters", "_fighter_move_without_monsters",
                 "_move_summoner_without_monsters_near_open_gate"]:
        methods += function(source, name)
    if label == "after":
        methods += function(source, "_execute_ai_movement") + function(source, "_execute_ai_basic_attack")
    (target / f"tests/hero_movement_{label}_fixture.gd").write_text(header + methods)
shutil.copy2(ROOT / "tests/hero_movement_port_smoke.gd", target / "tests/hero_movement_port_smoke.gd")
print("Hero movement fixture created:", target)
