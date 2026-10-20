#!/usr/bin/env bash
# Run SceneTree test scripts in parallel, one Godot process per test.
# Each test gets its own user:// (APPDATA / XDG_DATA_HOME), so parallel tests
# never share saves and never touch the real player data directory.
#
# Usage: tools/run_godot_tests.sh GODOT_BIN OUT_FILE [JOBS] [TIMEOUT_SEC] < test_list
#   test_list: one res-relative path per line (e.g. tests/foo_smoke.gd)
# Output lines: "<exit code> <test> :: <last PASS/FAIL/error lines>", sorted.
set -u
GODOT="$1"; OUT="$2"; JOBS="${3:-6}"; TIMEOUT_SEC="${4:-200}"
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
export GODOT PROJECT WORK TIMEOUT_SEC

run_one() {
	local test="$1" home out code
	home="$WORK/$(basename "$test" .gd)"
	mkdir -p "$home"
	if command -v cygpath > /dev/null; then home="$(cygpath -w "$home")"; fi
	out=$(cd "$PROJECT" && APPDATA="$home" XDG_DATA_HOME="$home" \
		timeout "$TIMEOUT_SEC" "$GODOT" --headless --path . --script "res://$test" 2>&1)
	code=$?
	printf '%s %s :: %s\n' "$code" "$test" \
		"$(printf '%s\n' "$out" | grep -E 'PASS|FAIL|SCRIPT ERROR|Parse Error|checks' | tail -2 | tr '\n' ' ' | cut -c1-140)"
}
export -f run_one

grep -v '^\s*$' | xargs -P "$JOBS" -I{} bash -c 'run_one "$1"' _ {} | sort -k2 > "$OUT"
rm -rf "$WORK"
echo "ran $(wc -l < "$OUT") tests, $(grep -c '^0 ' "$OUT") passed -> $OUT"
