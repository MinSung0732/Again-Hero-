#!/usr/bin/env python3
"""Run Godot checks sequentially with isolated Linux user data and capture evidence."""
import argparse
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

DEFAULT_TESTS = [
    "optimization_20261010_smoke", "optimization_network_smoke", "cloud_save_smoke",
    "slime_swarm_performance_smoke", "status_action_growth_smoke", "wolf_smoke",
    "yuki_onna_smoke", "manticore_combat_smoke", "shuten_doji_combat_smoke",
    "izanami_combat_smoke", "formation_mobile_drag_smoke", "demon_codex_smoke",
    "skill_icon_smoke", "startup_smoke",
]


def run_one(engine: str, project: Path, test: str, label: str, output: Path, timeout: float) -> dict:
    started = time.monotonic()
    # Existing smoke fixtures sometimes change shared settings. Each invocation
    # must receive its own user:// namespace, including Before/After comparisons.
    with tempfile.TemporaryDirectory(prefix="again-opt-check-") as folder:
        env = os.environ.copy()
        env["XDG_DATA_HOME"] = folder + "/data"
        env["XDG_CONFIG_HOME"] = folder + "/config"
        command = [engine, "--headless", "--path", str(project), "--script", f"res://tests/{test}.gd"]
        try:
            result = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=timeout)
            status = result.returncode
            log = result.stdout.decode("utf-8", errors="replace")
        except subprocess.TimeoutExpired as error:
            status = "timeout"
            log = (error.stdout or b"").decode("utf-8", errors="replace")
    output.parent.mkdir(parents=True, exist_ok=True)
    log_path = output.parent / f"{label}-{test}.log"
    log_path.write_text(log)
    return {
        "test": test, "project": label, "exit": status,
        "seconds": round(time.monotonic() - started, 3),
        "errors": [line for line in log.splitlines() if "ERROR:" in line],
        "warnings": sum("WARNING:" in line for line in log.splitlines()),
        "log": log_path.name,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--baseline-project", type=Path)
    parser.add_argument("--tests", nargs="+", default=DEFAULT_TESTS)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    projects = [("after", args.project.resolve())]
    if args.baseline_project:
        projects.insert(0, ("before", args.baseline_project.resolve()))
    rows = []
    for test in args.tests:
        if not test.replace("_", "").isalnum():
            parser.error("test names must be identifiers")
        for label, project in projects:
            row = run_one(args.godot, project, test, label, args.output, args.timeout)
            rows.append(row)
            args.output.write_text(json.dumps({"user_data": "isolated per invocation via XDG_DATA_HOME",
                                              "rows": rows}, ensure_ascii=False, indent=2) + "\n")
            print(f"{label}: {test}: {row['exit']}", flush=True)
    # Runtime diagnostics are retained even when an old fixture exits with 0.
    raise SystemExit(1 if any(row["exit"] != 0 for row in rows) else 0)


if __name__ == "__main__":
    main()
