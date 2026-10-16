#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHKIT="${ROOT}/bin/shkit"
PASS=0
FAIL=0

assert() {
	local name="$1"
	shift
	if "$@"; then
		echo "  ok  ${name}"
		PASS=$((PASS + 1))
	else
		echo "  FAIL ${name}"
		FAIL=$((FAIL + 1))
	fi
}

echo "shkit smoke tests"
assert "version" bash -c "\"$SHKIT\" version | grep -q shkit"
assert "help" bash -c "\"$SHKIT\" help | grep -q Commands"
assert "env detects drift" bash -c "! \"$SHKIT\" env \"$ROOT/examples/env\""
assert "json pretty" bash -c "\"$SHKIT\" json -q -f \"$ROOT/examples/sample.json\" | grep -q shkit"
assert "rename dry-run" bash -c "
	tmpdir=\$(mktemp -d)
	touch \"\$tmpdir/a.txt\"
	\"$SHKIT\" rename -d -p 'x_' \"\$tmpdir/a.txt\" | grep -q 'x_a.txt'
	rm -rf \"\$tmpdir\"
"
assert "ports once" bash -c "\"$SHKIT\" ports --once >/dev/null"

echo
echo "passed=${PASS} failed=${FAIL}"
[[ "$FAIL" -eq 0 ]]
