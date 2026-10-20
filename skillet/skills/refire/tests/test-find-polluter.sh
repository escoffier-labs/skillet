#!/usr/bin/env bash
# test-find-polluter.sh - deterministic unit tests for scripts/find-polluter.sh.
# Plain bash, no model in the loop. Exits non-zero on failure.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../scripts/find-polluter.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MARK="$TMP/pollution"
export MARK

# Fake "test runner": a file whose name contains "bad" leaves the marker,
# one containing "fail" also exits non-zero. Everything else is clean.
TEST_CMD='case "$1" in *bad*) touch "$MARK";; esac; case "$1" in *fail*) exit 3;; esac; exit 0'
CHECK_CMD='test -e "$MARK"'

FAILURES=0
OUT=""
CODE=0

run() { # <args...>; sets OUT and CODE
  OUT="$("$SCRIPT" "$@" 2>&1)"
  CODE=$?
}

expect() { # <label> <want-exit> <pattern|-> ; checks last run
  local label="$1" want="$2" pattern="$3"
  if [ "$CODE" -ne "$want" ]; then
    echo "[fail] $label: exit $CODE, wanted $want"
    printf '%s\n' "$OUT" | sed 's/^/    /'
    FAILURES=$((FAILURES + 1))
    return
  fi
  if [ "$pattern" != "-" ] && ! printf '%s\n' "$OUT" | grep -qF -- "$pattern"; then
    echo "[fail] $label: output missing: $pattern"
    printf '%s\n' "$OUT" | sed 's/^/    /'
    FAILURES=$((FAILURES + 1))
    return
  fi
  echo "[ok] $label"
}

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" a.test good.test bad.test z.test
expect "names the polluting file" 1 "POLLUTER: bad.test"

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" a.test bad1.test bad2.test
expect "stops at the first polluter" 1 "POLLUTER: bad1.test"
if printf '%s\n' "$OUT" | grep -qF "bad2.test"; then
  echo "[fail] did not stop at first polluter"
  FAILURES=$((FAILURES + 1))
else
  echo "[ok] later files not run after a hit"
fi

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" a.test b.test
expect "clean run exits 0" 0 "no polluter found among 2 file(s)"

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" fail-bad.test
expect "failing test that pollutes is still caught" 1 "POLLUTER: fail-bad.test"

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" fail-only.test a.test
expect "failing but clean test does not abort the scan" 0 "no polluter found"

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" "dir with space/bad one.test"
expect "path with spaces reaches the test command intact" 1 "POLLUTER: dir with space/bad one.test"

touch "$MARK"
run "$TEST_CMD" "$CHECK_CMD" a.test
expect "pre-existing pollution refuses to blame a file" 2 "already present"
rm -f "$MARK"

run "$TEST_CMD" "no_such_command_find_polluter_xyz" a.test
expect "broken check command (127) is an error, not a clean pass" 2 "check command errored"

run "$TEST_CMD" "exit 5" a.test
expect "check exiting 5 is an error, not a clean pass" 2 "check command errored"

rm -f "$MARK"
run "$TEST_CMD" "$CHECK_CMD" "it's bad.test"
expect "rerun hint is shell-quoted" 1 "it\\'s\\ bad.test"

run "$TEST_CMD" "$CHECK_CMD"
expect "no test files is a usage error" 2 "usage:"

run "$TEST_CMD"
expect "missing check command is a usage error" 2 "usage:"

if [ "$FAILURES" -ne 0 ]; then
  echo "$FAILURES failure(s)"
  exit 1
fi
echo "all find-polluter tests passed"
