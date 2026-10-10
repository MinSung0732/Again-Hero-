"""Compare actual pre-migration RunMetrics with the new clock implementation.

Only catalog display names are stubbed, identically on both sides. The event
buffer, metrics/reward algorithms and new clock are actual repository sources.
Full checkout: python3 tests/build_run_clock_fixture.py /tmp/run-clock-fixture
Thin source checkout: add --baseline-file FILE --event-buffer-file FILE.
"""
import argparse
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("target", type=Path)
parser.add_argument("--baseline-file", type=Path)
parser.add_argument("--event-buffer-file", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
target = args.target.resolve()
if target == root or root in target.parents:
    raise SystemExit("Use a separate temporary fixture directory")
target.mkdir(parents=True, exist_ok=True)
(target / "project.godot").write_text('[application]\nconfig/name="Run clock fixture"\n')
for name in ["src/systems/battle_run_clock.gd", "tests/run_clock_smoke.gd"]:
    dest = target / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / name, dest)
buffer = args.event_buffer_file or root / "src/systems/timed_event_buffer.gd"
shutil.copy2(buffer, target / "src/systems/timed_event_buffer.gd")
baseline = (args.baseline_file.read_text() if args.baseline_file else
            subprocess.check_output(["git", "show",
                "a3b3b7efbd332a17e4b62556179ed40ca9e0f98c:src/systems/run_metrics.gd"],
                cwd=root, text=True))
current = (root / "src/systems/run_metrics.gd").read_text()
catalog_preload = 'preload("res://src/data/monster_catalog.gd")'
for name, source in [("run_metrics_before.gd", baseline), ("run_metrics_after.gd", current)]:
    if source.count(catalog_preload) != 1:
        raise SystemExit("Unexpected RunMetrics catalog boundary")
    source = source.replace("class_name RunMetrics\n", "")
    source = source.replace(catalog_preload, 'preload("res://tests/clock_catalog_spy.gd")')
    (target / "tests" / name).write_text(source)
(target / "tests/clock_catalog_spy.gd").write_text('''extends RefCounted
static func get_ids() -> Array:
	return ["slime", "orc"]
static func get_monster_name(id: String) -> String:
	return id
''')
print("Run clock comparison fixture created:", target)
