#!/usr/bin/env bash
# Offline test for tests/run-trigger-tests.sh using a fake headless CLI that
# replays canned stream-json. No model, no network.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

# Hermetic copy of the runner so its relative paths resolve inside TMP.
FIX="$TMP/repo"
mkdir -p "$FIX/tests" "$FIX/skillet/.claude-plugin" "$FIX/skillet/skills/mise" "$FIX/skillet/skills/refire"
cp "$ROOT/tests/run-trigger-tests.sh" "$FIX/tests/"
cp -r "$ROOT/tests/lib" "$FIX/tests/lib"
printf 'x\n' >"$FIX/skillet/skills/mise/SKILL.md"
printf 'x\n' >"$FIX/skillet/skills/refire/SKILL.md"
printf '{"name":"skillet"}\n' >"$FIX/skillet/.claude-plugin/plugin.json"
printf '%s\t%s\t%s\n' \
  'build' 'mise' "Let's build a thing." \
  'ci' 'refire' 'Just make it work.' \
  'future' 'not-yet-shipped' 'A prompt for a skill that does not exist yet.' \
  >"$FIX/tests/trigger-prompts.tsv"

FAKE="$TMP/fake-claude"
cat >"$FAKE" <<'FAKE_EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$FAKE_ARGV_LOG"
touch "$FAKE_RAN_MARKER"
cat >/dev/null
tool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"%s","input":%s}]}}\n' "$1" "$2"; }
echo '{"type":"system","subtype":"init"}'
case "$FAKE_BEHAVIOR" in
  skill-first) tool Read '{"file_path":"x"}'; tool Skill '{"skill":"skillet:mise"}'; tool Bash '{"command":"ls"}' ;;
  bash-first) tool Bash '{"command":"ls"}'; tool Skill '{"skill":"skillet:mise"}' ;;
  wrong-skill) tool Skill '{"skill":"skillet:pass"}'; tool Edit '{"file_path":"x"}' ;;
  no-tool) echo '{"type":"assistant","message":{"content":[{"type":"text","text":"just text"}]}}' ;;
  crash) echo "boom" >&2; exit 3 ;;
esac
echo '{"type":"result","result":"done"}'
FAKE_EOF
chmod +x "$FAKE"

run() {
  FAKE_BEHAVIOR="$1" FAKE_ARGV_LOG="$TMP/argv.log" FAKE_RAN_MARKER="$TMP/ran" \
    bash "$FIX/tests/run-trigger-tests.sh" --claude "$FAKE" --out "$TMP/out" --timeout 20 "${@:2}" 2>&1
}

rm -f "$TMP/ran"
out="$(run skill-first --only build)"; rc=$?
[ "$rc" -eq 0 ] && pass "skill before any action passes" || fail "skill-first exit $rc: $out"
printf '%s' "$out" | grep -q 'PASS' && pass "table reports PASS" || fail "no PASS row: $out"
for needle in '--print' '--output-format' 'stream-json' '--verbose' '--disallowedTools' 'Task,Agent' '--plugin-dir' "$FIX/skillet" '--model' 'opus' '--no-session-persistence'; do
  grep -Fxq -- "$needle" "$TMP/argv.log" && pass "command carries $needle" || fail "command is missing $needle"
done
grep -Fq "Let's build" "$TMP/argv.log" && fail "prompt leaked into argv (must go on stdin)" || pass "prompt is sent on stdin, not argv"

out="$(run bash-first --only build)"; rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'FAIL.*first action Bash' && pass "action before the skill fails" || fail "bash-first rc=$rc: $out"

out="$(run wrong-skill --only build)"; rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'skills called: skillet:pass' && pass "wrong skill fails and names what fired" || fail "wrong-skill rc=$rc: $out"

out="$(run no-tool --only build)"; rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'no matching skill call' && pass "no skill call fails" || fail "no-tool rc=$rc: $out"

out="$(run crash --only build)"; rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'ERROR.*exit 3' && pass "runner crash is an error, not a pass" || fail "crash rc=$rc: $out"

out="$(run skill-first)"; rc=$?
printf '%s' "$out" | grep -q 'SKIP.*not shipped yet' && pass "row for an unshipped skill is skipped" || fail "no SKIP row: $out"

rm -f "$TMP/ran"
out="$(run skill-first --dry-run)"; rc=$?
[ "$rc" -eq 0 ] && [ ! -e "$TMP/ran" ] && pass "--dry-run exits 0 and never starts the CLI" || fail "dry-run rc=$rc ran=$([ -e "$TMP/ran" ] && echo yes || echo no)"
printf '%s' "$out" | grep -q 'stream-json' && pass "--dry-run prints the command" || fail "dry-run printed no command"

out="$(bash "$FIX/tests/run-trigger-tests.sh" --claude "$TMP/does-not-exist" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "missing CLI is a setup error (exit 2)" || fail "missing CLI rc=$rc"

if [ "$FAILURES" -ne 0 ]; then
  echo "[fail] run-trigger-tests: $FAILURES failure(s)"
  exit 1
fi
echo "[ok] run-trigger-tests"
