#!/usr/bin/env bash
# Deterministic test for skillet/hooks/session-start. No model, no network.
#
# Covers:
#   - runs with an empty environment and an empty PATH (bash invoked by
#     absolute path), the failure mode of a SessionStart hook spawned before
#     PATH is repaired
#   - emits valid JSON with exactly one context field per platform mode
#   - injects the real using-skillet skill text
#   - fails closed: when the skill file is unreadable the hook exits non-zero
#     and emits no stdout and no stderr, never an error string as skill content
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR="$ROOT/skillet/hooks"
HOOK="$HOOKS_DIR/session-start"
WRAPPER="$HOOKS_DIR/run-hook.cmd"
SKILL="$ROOT/skillet/skills/using-skillet/SKILL.md"
# Absolute path of the bash running this test, so the hook can be started with
# no PATH at all.
BASH_BIN="$(command -v bash)"
PY="$(command -v python3)"

FAILURES=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

[ -x "$BASH_BIN" ] && [ -n "$PY" ] || { echo "[fail] bash and python3 are required"; exit 1; }

# check_json <description> <expected-field> <json-file>
# expected-field is one of: nested | snake | flat
check_json() {
  local description="$1" shape="$2" file="$3"
  if "$PY" -I - "$shape" "$file" "$SKILL" <<'PY'
import json
import sys

shape, out_path, skill_path = sys.argv[1:]
try:
    payload = json.load(open(out_path, encoding="utf-8"))
except Exception as error:
    print(f"invalid JSON: {error}")
    raise SystemExit(1)

expected = {
    "nested": ["hookSpecificOutput"],
    "snake": ["additional_context"],
    "flat": ["additionalContext"],
}[shape]
if sorted(payload) != sorted(expected):
    print(f"top-level keys {sorted(payload)} != {sorted(expected)}")
    raise SystemExit(1)

if shape == "nested":
    inner = payload["hookSpecificOutput"]
    if sorted(inner) != ["additionalContext", "hookEventName"]:
        print(f"nested keys {sorted(inner)}")
        raise SystemExit(1)
    if inner["hookEventName"] != "SessionStart":
        print("hookEventName is not SessionStart")
        raise SystemExit(1)
    context = inner["additionalContext"]
else:
    context = payload[expected[0]]

if not isinstance(context, str) or "You have skillet." not in context:
    print("context missing the skillet preamble")
    raise SystemExit(1)
skill_text = open(skill_path, encoding="utf-8").read().strip()
if skill_text not in context:
    print("context does not contain the full using-skillet skill text")
    raise SystemExit(1)
PY
  then
    pass "$description"
  else
    fail "$description"
  fi
}

# run_hook <outfile> <errfile> <env assignments...> -- <command...>
run_clean() {
  local out="$1" err="$2"
  shift 2
  env -i "$@" >"$out" 2>"$err"
}

# 1. Empty environment, empty PATH, each platform mode.
run_clean "$TMP/claude.json" "$TMP/claude.err" PATH= CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK"
rc=$?
[ "$rc" -eq 0 ] && pass "claude mode exits 0 with empty PATH" || fail "claude mode exit $rc"
check_json "claude mode emits only hookSpecificOutput.additionalContext" nested "$TMP/claude.json"

run_clean "$TMP/cursor.json" "$TMP/cursor.err" PATH= CURSOR_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK"
check_json "cursor mode emits only additional_context" snake "$TMP/cursor.json"

run_clean "$TMP/both.json" "$TMP/both.err" PATH= CURSOR_PLUGIN_ROOT=/x CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK"
check_json "cursor plus claude variables emit one field (cursor)" snake "$TMP/both.json"

run_clean "$TMP/copilot.json" "$TMP/copilot.err" PATH= CLAUDE_PLUGIN_ROOT=/x COPILOT_CLI=1 "$BASH_BIN" "$HOOK"
check_json "copilot mode emits only top-level additionalContext" flat "$TMP/copilot.json"

run_clean "$TMP/bare.json" "$TMP/bare.err" "$BASH_BIN" "$HOOK"
check_json "no platform variables emit top-level additionalContext" flat "$TMP/bare.json"

if [ -s "$TMP/claude.err" ]; then fail "claude mode wrote to stderr"; else pass "claude mode wrote nothing to stderr"; fi

# 1b. A normal absolute PATH works and produces the same JSON.
run_clean "$TMP/normal.json" "$TMP/normal.err" PATH=/usr/bin:/bin CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK"
rc=$?
[ "$rc" -eq 0 ] && pass "normal PATH exits 0" || fail "normal PATH exit $rc"
check_json "normal PATH emits claude-mode JSON" nested "$TMP/normal.json"

# 1c. A planted ./cat must never run, with an empty PATH or a "." or empty
# PATH entry (bash searches the working directory for those).
mkdir -p "$TMP/planted"
printf '#!/bin/sh\n# shell builtin only: PATH is empty here\n: >"%s/planted-cat-ran"\nwhile IFS= read -r l; do printf "%%s\\n" "$l"; done\n\n' "$TMP" >"$TMP/planted/cat"
chmod +x "$TMP/planted/cat"
for planted_path in "" "." ":/nonexistent" "/nonexistent:" "relative/bin"; do
  rm -f "$TMP/planted-cat-ran"
  (cd "$TMP/planted" && env -i PATH="$planted_path" CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK" >"$TMP/planted.json" 2>/dev/null)
  rc=$?
  if [ -e "$TMP/planted-cat-ran" ]; then
    fail "planted ./cat ran with PATH='$planted_path'"
  elif [ "$rc" -ne 0 ]; then
    fail "hook exited $rc with PATH='$planted_path'"
  else
    pass "planted ./cat ignored with PATH='$planted_path'"
    check_json "JSON still valid with PATH='$planted_path'" nested "$TMP/planted.json"
  fi
done

# 2. Through the wrapper with an empty PATH.
run_clean "$TMP/wrap.json" "$TMP/wrap.err" PATH= CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$WRAPPER" session-start
rc=$?
[ "$rc" -eq 0 ] && pass "run-hook.cmd exits 0 with empty PATH" || fail "run-hook.cmd exit $rc"
check_json "run-hook.cmd emits claude-mode JSON" nested "$TMP/wrap.json"

# 3. Run from an unrelated working directory (script root comes from $0).
mkdir -p "$TMP/elsewhere"
(cd "$TMP/elsewhere" && env -i PATH= CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$HOOK" >"$TMP/cwd.json" 2>/dev/null)
check_json "plugin root is derived from \$0, not the working directory" nested "$TMP/cwd.json"

# 4. Fail closed. Build a plugin root whose skill file is missing, empty or
# unreadable, and assert nothing reaches stdout or stderr.
assert_closed() {
  local description="$1" plugin="$2" rc
  env -i PATH= CLAUDE_PLUGIN_ROOT=/x "$BASH_BIN" "$plugin/hooks/session-start" \
    >"$TMP/closed.out" 2>"$TMP/closed.err"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "$description: expected non-zero exit"
  elif [ -s "$TMP/closed.out" ]; then
    fail "$description: stdout must be empty, got: $(head -c 120 "$TMP/closed.out")"
  elif [ -s "$TMP/closed.err" ]; then
    fail "$description: stderr must be empty, got: $(head -c 120 "$TMP/closed.err")"
  elif cat "$TMP/closed.out" "$TMP/closed.err" 2>/dev/null | grep -qiE 'error reading|using-skillet|EXTREMELY_IMPORTANT|You have skillet'; then
    fail "$description: output contains skill-looking text"
  else
    pass "$description"
  fi
}

new_plugin() {
  local dir="$TMP/$1"
  mkdir -p "$dir/hooks" "$dir/skills/using-skillet"
  cp "$HOOK" "$dir/hooks/session-start"
  printf '%s' "$dir"
}

plugin="$(new_plugin missing-skill)"
assert_closed "fail closed: skill file missing" "$plugin"

plugin="$(new_plugin empty-skill)"
: >"$plugin/skills/using-skillet/SKILL.md"
assert_closed "fail closed: skill file empty" "$plugin"

plugin="$(new_plugin unreadable-skill)"
printf 'content\n' >"$plugin/skills/using-skillet/SKILL.md"
chmod 000 "$plugin/skills/using-skillet/SKILL.md"
if [ -r "$plugin/skills/using-skillet/SKILL.md" ]; then
  echo "  [skip] fail closed: unreadable skill (running as a user that ignores file modes)"
else
  assert_closed "fail closed: skill file unreadable" "$plugin"
fi
chmod 600 "$plugin/skills/using-skillet/SKILL.md"

# 5. hooks.json stays valid and keeps the fields the harness reads.
if "$PY" -I - "$HOOKS_DIR/hooks.json" <<'PY'
import json
import sys

entry = json.load(open(sys.argv[1], encoding="utf-8"))["hooks"]["SessionStart"][0]
hook = entry["hooks"][0]
ok = (
    entry["matcher"] == "startup|clear|compact"
    and hook["type"] == "command"
    and hook["async"] is False
    and hook.get("shell") == "bash"
)
raise SystemExit(0 if ok else 1)
PY
then
  pass "hooks.json keeps matcher, async false and shell bash"
else
  fail "hooks.json lost matcher, async false or shell bash"
fi

if [ "$FAILURES" -ne 0 ]; then
  echo "[fail] session-start hook: $FAILURES failure(s)"
  exit 1
fi
echo "[ok] session-start hook"
