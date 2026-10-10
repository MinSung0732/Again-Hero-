"""Extract actual before/after Hero physics dispatch for isolated regression.

Rendering, collision, targeting, effects and archetype bodies are explicit spies;
the common gates/timers/order, new decision method and action port are real.
Default baseline requires a full clone; thin checkouts use --baseline-file.
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
              "349513c0cc117f06df6228d84b08aced1340a54a:src/hero/hero.gd"],
              cwd=ROOT, text=True))
after = (ROOT / "src/hero/hero.gd").read_text()


def function(source, name):
    match = re.search(r"^func " + re.escape(name) + r"\(", source, re.M)
    if match is None:
        raise RuntimeError("Missing actual Hero function: " + name)
    tail = source[match.start():]
    end = re.search(r"\nfunc ", tail)
    return (tail[:end.start()] if end else tail).rstrip() + "\n\n"


# Every unrelated function must stay byte-identical, including all actual
# target queries, AI scoring, wander, projectile and specialization bodies.
names = re.findall(r"^func ([^(]+)\(", before, re.M)
for name in names:
    if name not in {"_physics_process_actions", "_prepare_ranged_ai_intent",
                    "_physics_process_summoner", "_physics_process_alchemist",
                    "_physics_process_gunner", "_physics_process_rogue",
                    "_physics_process_berserker", "_physics_process_fighter",
                    "_move_without_monsters", "_fighter_move_without_monsters"}:
        assert function(before, name) == function(after, name), name
print("Unrelated Hero functions unchanged (movement paths checked by dedicated fixture)")
target.mkdir(parents=True, exist_ok=True)
(target / "project.godot").write_text('[application]\nconfig/name="Hero action fixture"\n')
for path in ["src/hero/hero_action_intent.gd", "src/hero/hero_action_port.gd",
             "tests/hero_action_port_smoke.gd"]:
    dest = target / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / path, dest)

header = '''extends CharacterBody2D
const HERO_ACTION_INTENT := preload("res://src/hero/hero_action_intent.gd")
const HERO_ACTION_PORT := preload("res://src/hero/hero_action_port.gd")
var action_intent = HERO_ACTION_INTENT.new()
# Baseline compatibility only; the real Hero owns one action_intent.
var ranged_action_intent = action_intent
class TargetPolicy:
	static func is_detectable(node: Node) -> bool:
		return is_instance_valid(node) and bool(node.get_meta("detectable", true))
class BurnSpy:
	var remaining := 0.0
	func update(actor, _delta: float) -> void:
		actor.events.append("burn")
const HERO_TARGET_POLICY = TargetPolicy
var burn_runtime = BurnSpy.new()
var events: Array = []
var target: Node2D
var candidate: Node2D
var fighter_charge_target: Node2D
var fighter_charge_active := false
var current_hp := 100
var is_dying := false
var hero_archetype := "ranged_kiter"
var channeling := false
var purifier_gungnir_casting := false
var attack_timer := 0.0
var retarget_timer := 0.0
var wander_timer := 0.0
var attack_pose_timer := 0.0
var hit_pose_timer := 0.0
var ultimate_flash_timer := 0.0
var level_flash_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var possession_immunity_timer := 0.0
var ai_memory_clock := 0.0
var ai_observation_timer := 0.0
var silence_timer := 0.0
var imposed_skill_cooldown := 0.0
var paralysis_timer := 0.0
var paralysis_ratio := 0.0
var petrify_timer := 0.0
var move_speed := 235.0
var attack_range := 650.0
var purifier_speed := 1.0
var stunned := false
var feared := false
var charmed := false
var poison_kills := false
var channel_starts := false
var range_after_move := -1.0
var timer_after_move := -1.0
var replace_target_after_move := false
var replacement_target: Node2D
func _update_poison(_delta: float) -> void:
	events.append("poison")
	if poison_kills:
		current_hp = 0
func _tick_petrify(delta: float) -> void:
	events.append("petrify")
	petrify_timer = maxf(petrify_timer - delta, 0.0)
func _tick_charm_timers(_delta: float) -> bool:
	events.append("charm_timers")
	return charmed
func _tick_stun_state(_delta: float) -> bool:
	events.append("stun")
	if stunned:
		velocity = Vector2.ZERO
	return stunned
func _tick_fear_state(_delta: float) -> bool:
	events.append("fear")
	if feared:
		velocity = Vector2(19, 23)
	return feared
func _tick_charm_state(_delta: float) -> void:
	events.append("charm")
	velocity = Vector2(-13, 7)
func _finish_fighter_charge() -> void:
	events.append("finish_charge")
	fighter_charge_active = false
func _refresh_ai_observation() -> void:
	events.append("observe")
	ai_observation_timer = 0.35
func get_paralysis_attack_multiplier() -> float:
	return 1.0 - paralysis_ratio
func _update_channel_skill(_delta: float) -> void:
	events.append("channel")
	if channel_starts:
		channeling = true
func _find_nearest_monster() -> Node2D:
	events.append("retarget")
	return candidate
func _move_without_monsters() -> void:
	events.append("wander")
	velocity = Vector2(-15, 30)
func _choose_move_direction(_target: Node2D, distance: float) -> Vector2:
	events.append(["choose", distance])
	return Vector2(0.75, -0.25)
func _apply_heal_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("heal_steer")
	return direction + Vector2(0.1, 0.0)
func _apply_chest_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("chest_steer")
	return direction.rotated(0.1)
func _apply_magnet_item_steering(direction: Vector2, _delta: float) -> Vector2:
	events.append("magnet_steer")
	return direction * 0.8
func _apply_archmage_boundary_steering(direction: Vector2) -> Vector2:
	events.append("archmage_boundary")
	return direction.rotated(-0.15)
func _apply_ranged_boundary_escape(direction: Vector2) -> Vector2:
	events.append("ranged_boundary")
	return direction.rotated(0.2)
func _get_effective_move_multiplier() -> float:
	return move_multiplier
func _get_purifier_move_speed_multiplier() -> float:
	return purifier_speed
func _move_and_slide_with_obstacle_escape() -> void:
	events.append("move")
	global_position += velocity * 0.016
	if range_after_move >= 0.0:
		attack_range = range_after_move
	if timer_after_move >= 0.0:
		attack_timer = timer_after_move
	if replace_target_after_move:
		target = replacement_target
func _clamp_to_battlefield() -> void:
	events.append("clamp")
	global_position = global_position.clamp(Vector2.ZERO, Vector2(2000, 2000))
func _fire_projectile(current_target: Node2D) -> void:
	events.append(["fire", current_target.get_instance_id() if is_instance_valid(current_target) else 0])
	if is_instance_valid(current_target) and not channeling:
		attack_timer = 1.5
'''
for name in ["_update_hero_hit_flash", "_update_bleed", "_update_damage_poison",
             "_tick_received_modifiers", "_update_combat_reposition",
             "_update_invulnerability", "_update_ultimate", "_update_purifier_gauge",
             "_update_sage_runtime", "_update_shield_skill", "_update_archmage_skill_runtime",
             "_update_heal_item_goal", "_update_chest_goal", "_update_magnet_item_goal",
             "_update_stage1_pose_visual"]:
    header += f'func {name}(_delta: float) -> void:\n\tevents.append("{name}")\n'
for name in ["_prune_offensive_memory", "_prune_status_memory"]:
    header += f'func {name}() -> void:\n\tevents.append("{name}")\n'
for name in ["rogue", "fighter", "gunner", "berserker", "alchemist", "summoner"]:
    header += f'func _physics_process_{name}(_delta: float) -> void:\n\tevents.append("{name}")\n\tvelocity = Vector2(17, -9)\n'

for label, source in [("before", before), ("after", after)]:
    methods = function(source, "_physics_process") + function(source, "_physics_process_actions")
    if re.search(r"^func _prepare_ranged_ai_intent\(", source, re.M):
        methods += function(source, "_prepare_ranged_ai_intent")
    (target / f"tests/hero_action_{label}_fixture.gd").write_text(header + methods)
print("Hero fixture created:", target)
