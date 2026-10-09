#!/usr/bin/env python3
"""Inventory tracked GDScript at a revision; counts are review hints, not profiling."""
import argparse
import json
import re
import subprocess
from pathlib import Path


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", default="HEAD")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    revision = git("rev-parse", args.revision).strip()
    paths = git("ls-tree", "-r", "--name-only", revision, "src").splitlines()
    files = []
    patterns = {
        "group_scans": "get_nodes_in_group(",
        "pop_front": "pop_front(",
        "await": "await ",
        "instantiate": "instantiate(",
        "queue_free": "queue_free(",
    }
    for path in paths:
        if not path.endswith(".gd"):
            continue
        source = git("show", f"{revision}:{path}")
        functions = list(re.finditer(r"^(?:static )?func (\w+)", source, re.M))
        spans = []
        for index, match in enumerate(functions):
            end = functions[index + 1].start() if index + 1 < len(functions) else len(source)
            spans.append({
                "name": match.group(1),
                "line": source[:match.start()].count("\n") + 1,
                "lines": source[match.start():end].count("\n"),
            })
        files.append({
            "path": path,
            "lines": len(source.splitlines()),
            "functions": len(functions),
            "largest_functions": sorted(spans, key=lambda row: row["lines"], reverse=True)[:5],
            **{name: source.count(pattern) for name, pattern in patterns.items()},
        })
    report = {
        "revision": revision,
        "scope": "tracked src/**/*.gd; lexical counts, including comments/fallbacks",
        "scripts": len(files),
        "lines": sum(row["lines"] for row in files),
        "functions": sum(row["functions"] for row in files),
        "files": files,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"{report['scripts']} scripts / {report['lines']} lines / {report['functions']} function declarations")


if __name__ == "__main__":
    main()
