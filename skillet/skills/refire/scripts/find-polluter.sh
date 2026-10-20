#!/usr/bin/env bash
# find-polluter.sh - find which test file leaves shared state behind.
#
# Usage: find-polluter.sh <test-command> <check-command> <test-file>...
#
#   <test-command>   run with bash -c; the test file path arrives as "$1".
#                    Its exit status is ignored (failing tests still pollute).
#   <check-command>  run with bash -c after each test file. Exit 0 = pollution
#                    PRESENT, exit 1 = ABSENT, anything else = the check itself
#                    is broken (typo, missing tool) and the run stops. Example:
#                    test -e .state/lock
#   <test-file>...   candidates, run one at a time, in the order given.
#
# Exit codes: 0 no polluter found, 1 polluter found (first one wins),
#             2 usage error, check command errored, or pollution already
#             present before the first run.
#
# Each file runs alone, so this finds files that pollute by themselves. A
# file that only misbehaves after another test ran first needs an ordered
# two-file reproduction: list the suspected earlier file before the suspected
# later one and rerun. This script does not search pairs itself.
# Set FIND_POLLUTER_VERBOSE=1 to see test output.
set -uo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: find-polluter.sh <test-command> <check-command> <test-file>..." >&2
  exit 2
fi

TEST_CMD="$1"
CHECK_CMD="$2"
shift 2

# Returns 0 when pollution is present, 1 when absent. Any other exit status
# from the check command stops the run: a broken check must not read as clean.
polluted() {
  bash -c "$CHECK_CMD" >/dev/null 2>&1
  local rc=$?
  case "$rc" in
    0) return 0 ;;
    1) return 1 ;;
    *)
      echo "check command errored (exit $rc); it must exit 0 (present) or 1 (absent). Fix it before trusting this script" >&2
      exit 2
      ;;
  esac
}

if polluted; then
  echo "pollution already present before any test ran; clean it first so a file can be blamed" >&2
  exit 2
fi

TOTAL="$#"
COUNT=0
for FILE in "$@"; do
  COUNT=$((COUNT + 1))
  echo "[$COUNT/$TOTAL] $FILE"
  if [ "${FIND_POLLUTER_VERBOSE:-0}" = "1" ]; then
    bash -c "$TEST_CMD" find-polluter "$FILE" || true
  else
    bash -c "$TEST_CMD" find-polluter "$FILE" >/dev/null 2>&1 || true
  fi
  if polluted; then
    echo "POLLUTER: $FILE"
    printf 'rerun alone: bash -c <test-command> find-polluter %q\n' "$FILE"
    exit 1
  fi
done

echo "no polluter found among $TOTAL file(s)"
exit 0
