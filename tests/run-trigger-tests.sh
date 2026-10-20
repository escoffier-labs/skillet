#!/usr/bin/env bash
# run-trigger-tests.sh [--dry-run] [--model M] [--claude CMD] [--prompts FILE]
#                      [--timeout SECONDS] [--out DIR] [--only ID]...
#
# Opt-in trigger test. NEVER run from CI: it makes one real model call per
# prompt and spends subscription quota.
#
# For each row of tests/trigger-prompts.tsv it runs ONE flat headless pass
# (`claude --print --output-format stream-json --verbose`) with this repo's
# skillet/ directory loaded as a plugin and Task/Agent disallowed, parses the
# stream, and asserts that the expected skillet:<name> Skill tool call happens
# before the first Edit, Write, MultiEdit, NotebookEdit or Bash tool use. Read-only tools
# (Read, Grep, Glob) before the Skill call are allowed. The run stops as soon
# as the verdict is known, so most passes end after the first few tool calls.
#
# Use it to guard changes to skill descriptions, using-skillet and the
# SessionStart hook: run it before and after and compare the table.
#
# Environment (flags win over environment):
#   TRIGGER_MODEL    model alias or id passed to --model (default: opus)
#   TRIGGER_CLAUDE   headless CLI to run (default: claude)
#   TRIGGER_TIMEOUT  per-prompt wall-clock limit in seconds (default: 240)
#   TRIGGER_OUT      directory for raw stream logs
#                    (default: .skill-eval-workspace/triggers/<timestamp>)
#
# Exit status: 0 when every non-skipped prompt hits, 1 on any miss or error,
# 2 on a usage or setup problem. Skipped rows (expected skill not shipped yet)
# never fail the run.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT/skillet"
SKILLS_DIR="$PLUGIN_DIR/skills"
PROMPTS="$ROOT/tests/trigger-prompts.tsv"
MODEL="${TRIGGER_MODEL:-opus}"
CLAUDE_BIN="${TRIGGER_CLAUDE:-claude}"
TIMEOUT="${TRIGGER_TIMEOUT:-240}"
OUT_DIR="${TRIGGER_OUT:-}"
DRY_RUN=0
ONLY=()

usage() {
  sed -n '2,/^set -uo/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --model) MODEL="${2:?--model needs a value}"; shift 2 ;;
    --claude) CLAUDE_BIN="${2:?--claude needs a value}"; shift 2 ;;
    --prompts) PROMPTS="${2:?--prompts needs a value}"; shift 2 ;;
    --timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    --out) OUT_DIR="${2:?--out needs a value}"; shift 2 ;;
    --only) ONLY+=("${2:?--only needs an id}"); shift 2 ;;
    *) echo "[fail] unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$TIMEOUT" in
  ''|*[!0-9]*) echo "[fail] --timeout must be a whole number of seconds" >&2; exit 2 ;;
esac
[ -f "$PROMPTS" ] || { echo "[fail] prompt fixture not found: $PROMPTS" >&2; exit 2; }
[ -d "$PLUGIN_DIR/.claude-plugin" ] || { echo "[fail] plugin directory not found: $PLUGIN_DIR" >&2; exit 2; }

if [ "$DRY_RUN" -eq 0 ]; then
  command -v python3 >/dev/null 2>&1 || { echo "[fail] python3 is required" >&2; exit 2; }
  command -v "$CLAUDE_BIN" >/dev/null 2>&1 || { echo "[fail] headless CLI not found: $CLAUDE_BIN (set --claude or TRIGGER_CLAUDE)" >&2; exit 2; }
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "[warn] ANTHROPIC_API_KEY is set: these runs may bill the API instead of the subscription. Unset it to use subscription quota." >&2
  fi
  echo "[note] this run makes one real model call per prompt and spends quota (model: $MODEL)" >&2
fi

if [ -z "$OUT_DIR" ]; then
  OUT_DIR="$ROOT/.skill-eval-workspace/triggers/$(date -u +%Y%m%dT%H%M%SZ)"
fi

# The exact argv for one pass. The prompt is sent on stdin, never as an
# argument, because --disallowedTools is variadic. --setting-sources project
# plus a temp scratch directory (and CLAUDE_CODE_DISABLE_CLAUDE_MDS=1, set by
# tests/lib/headless_stream.py) keep user-level settings, memory files and
# installed plugins out of the measurement, so only this checkout's skillet is
# under test.
build_command() {
  CMD=(
    "$CLAUDE_BIN" --print --output-format stream-json --verbose
    --model "$MODEL"
    --plugin-dir "$PLUGIN_DIR"
    --disallowedTools "Task,Agent"
    --setting-sources project
    --strict-mcp-config
    --no-session-persistence
  )
}

skill_exists() {
  # Any one of the |-separated alternatives shipping is enough to run the row.
  local alt IFS='|'
  for alt in $1; do
    [ -f "$SKILLS_DIR/$alt/SKILL.md" ] && return 0
  done
  return 1
}

selected() {
  local id="$1" want
  [ "${#ONLY[@]}" -eq 0 ] && return 0
  for want in "${ONLY[@]}"; do
    [ "$want" = "$id" ] && return 0
  done
  return 1
}

VERDICT_PY='
import json, sys
sys.path.insert(0, sys.argv[1])
from headless_stream import run_stream, tool_uses

expected = set(sys.argv[2].split("|"))
timeout = int(sys.argv[3])
log_path = sys.argv[4]
workdir = sys.argv[5]
prompt = sys.stdin.read()
cmd = sys.argv[6:]

ACTION_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit", "Bash"}
state = {"skills": [], "verdict": None, "detail": ""}

def on_event(event):
    if event.get("type") == "system" and event.get("subtype") == "init":
        # Built-in harness skills carry no namespace. A namespaced skill that is
        # not skillet:* comes from another installed plugin and would skew the
        # measurement, so the row fails instead of reporting a misleading hit.
        foreign = [s for s in event.get("skills") or [] if ":" in s and not s.startswith("skillet:")]
        if foreign:
            state["verdict"] = "FAIL"
            state["detail"] = "init lists skills from outside the plugin: " + ", ".join(foreign[:3])
            return True
    for name, tool_input in tool_uses(event):
        if name == "Skill":
            skill = str(tool_input.get("skill") or tool_input.get("name") or "")
            state["skills"].append(skill)
            if skill in {"skillet:" + e for e in expected}:
                state["verdict"] = "PASS"
                state["detail"] = "skill " + skill + " fired before any action"
                return True
        elif name in ACTION_TOOLS:
            state["verdict"] = "FAIL"
            called = ", ".join(state["skills"]) or "none"
            state["detail"] = "first action " + name + " came before the expected skill (skills called: " + called + ")"
            return True
    return False

result = run_stream(cmd, prompt, workdir, timeout, log_path, on_event)

if state["verdict"] is None:
    if result["timed_out"]:
        state["verdict"], state["detail"] = "ERROR", "timed out after " + str(timeout) + "s"
    elif result["returncode"] not in (0, None):
        tail = result["stderr"].strip().splitlines()[-1:] or ["no stderr"]
        state["verdict"], state["detail"] = "ERROR", "exit " + str(result["returncode"]) + ": " + tail[0][:120]
    else:
        called = ", ".join(state["skills"]) or "none"
        state["verdict"], state["detail"] = "FAIL", "no matching skill call (skills called: " + called + ")"

print(state["verdict"] + "\t" + state["detail"])
sys.exit(0 if state["verdict"] == "PASS" else 1)
'

build_command
WORKDIR=""
if [ "$DRY_RUN" -eq 0 ]; then
  # A dry run creates nothing on disk.
  mkdir -p "$OUT_DIR"
  SCRATCH="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH"' EXIT
  WORKDIR="$SCRATCH/work"
  mkdir -p "$WORKDIR"
  printf '# demo\n' >"$WORKDIR/README.md"
fi

printf '%-16s %-18s %-6s %s\n' "PROMPT" "EXPECTED" "RESULT" "DETAIL"
FAILED=0
RAN=0
SKIPPED=0

while IFS=$'\t' read -r id expected prompt; do
  case "$id" in ''|'#'*) continue ;; esac
  selected "$id" || continue
  if [ -z "$expected" ] || [ -z "$prompt" ]; then
    printf '%-16s %-18s %-6s %s\n' "$id" "${expected:--}" "ERROR" "malformed fixture row"
    FAILED=1
    continue
  fi
  if ! skill_exists "$expected"; then
    printf '%-16s %-18s %-6s %s\n' "$id" "$expected" "SKIP" "expected skill is not shipped yet"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%-16s %-18s %-6s ' "$id" "$expected" "DRY"
    printf '(cd <scratch dir> && printf %%s %q | env CLAUDE_CODE_DISABLE_CLAUDE_MDS=1' "$prompt"
    printf ' %q' "${CMD[@]}"
    printf ')\n'
    RAN=$((RAN + 1))
    continue
  fi
  RAN=$((RAN + 1))
  verdict="$(printf '%s' "$prompt" | python3 -I -c "$VERDICT_PY" \
    "$ROOT/tests/lib" "$expected" "$TIMEOUT" "$OUT_DIR/$id.jsonl" "$WORKDIR" "${CMD[@]}")"
  rc=$?
  result="${verdict%%$'\t'*}"
  detail="${verdict#*$'\t'}"
  [ -n "$verdict" ] || { result="ERROR"; detail="runner produced no verdict"; }
  [ "$rc" -eq 0 ] || FAILED=1
  printf '%-16s %-18s %-6s %s\n' "$id" "$expected" "$result" "$detail"
done <"$PROMPTS"

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[ok] dry run: $RAN command(s) printed, $SKIPPED skipped, nothing executed"
  exit 0
fi
echo "raw stream logs: $OUT_DIR"
if [ "$RAN" -eq 0 ]; then
  echo "[fail] no prompts ran (check --only and the fixture)" >&2
  exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "[fail] trigger test: at least one prompt missed or errored ($RAN run, $SKIPPED skipped)"
  exit 1
fi
echo "[ok] trigger test: $RAN hit, $SKIPPED skipped"
