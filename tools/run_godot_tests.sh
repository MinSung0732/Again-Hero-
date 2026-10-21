#!/usr/bin/env bash
# Run SceneTree test scripts in parallel, one Godot process per test.
# Each test gets its own user:// (APPDATA / XDG_DATA_HOME), so parallel tests
# never share saves and never touch the real player data directory.
#
# Usage: tools/run_godot_tests.sh GODOT_BIN OUT_FILE [JOBS] [TIMEOUT_SEC] < test_list
#   test_list: one res-relative path per line (e.g. tests/foo_smoke.gd)
# Output lines: "<exit code> <test> :: <last PASS/FAIL/error lines>", sorted.
# Tests listed in tests/FIXTURE_ONLY_TESTS.txt are reported as "SKIP".
set -u
GODOT="$1"; OUT="$2"; JOBS="${3:-6}"; TIMEOUT_SEC="${4:-200}"
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
export GODOT PROJECT WORK TIMEOUT_SEC

run_one() {
	local test="$1" home out code reason
	reason=$(grep -F "$test  #" "$PROJECT/tests/FIXTURE_ONLY_TESTS.txt" 2>/dev/null | head -1 | sed 's/^[^#]*#\s*//')
	if [ -n "$reason" ]; then
		printf 'SKIP %s :: fixture-only: %s\n' "$test" "$reason"
		return
	fi
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
echo "ran $(wc -l < "$OUT") tests: $(grep -c '^0 ' "$OUT") passed, $(grep -c '^SKIP ' "$OUT") skipped (tests/FIXTURE_ONLY_TESTS.txt) -> $OUT"
# Failures outside the known baseline are regressions (or newly broken tests).
KNOWN="$PROJECT/tests/KNOWN_FAILING_TESTS.txt"
NEW=$(grep -vE '^(0|SKIP) ' "$OUT" | while read -r _ test _; do
	grep -qF "$test  #" "$KNOWN" 2>/dev/null || echo "$test"
done)
FIXED=$(grep '^0 ' "$OUT" | while read -r _ test _; do
	grep -qF "$test  #" "$KNOWN" 2>/dev/null && echo "$test"
done)
echo "failures: $(grep -vcE '^(0|SKIP) ' "$OUT"), NEW (not in KNOWN_FAILING_TESTS.txt): $(printf '%s' "$NEW" | grep -c .)"
[ -n "$NEW" ] && printf 'NEW FAILURE %s\n' $NEW
[ -n "$FIXED" ] && printf 'NOW PASSING (remove from KNOWN_FAILING_TESTS.txt) %s\n' $FIXED
exit 0
