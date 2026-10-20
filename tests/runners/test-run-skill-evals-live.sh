#!/usr/bin/env bash
# Offline test for `tests/run-skill-evals.sh --live` using a fake headless CLI.
# No model, no network. Runs in a hermetic copy so the repo workspace stays clean.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

FIX="$TMP/repo"
SKILL="$FIX/skillet/skills/demo"
mkdir -p "$FIX/tests" "$SKILL/evals/files" "$SKILL/tests"
cp "$ROOT/tests/run-skill-evals.sh" "$ROOT/tests/lint-evals.sh" "$FIX/tests/"
cp -r "$ROOT/tests/lib" "$FIX/tests/lib"
printf -- '---\nname: demo\n---\n# demo\n' >"$SKILL/SKILL.md"
printf '{"id":"demo"}\n' >"$SKILL/skill.json"
printf 'fixture text\n' >"$SKILL/evals/files/input.txt"
printf 'secret assertion text\n' >"$SKILL/tests/test-marker"
cat >"$SKILL/evals/evals.json" <<'JSON'
{
  "schema_version": "skillet.evals.v1",
  "skill_name": "demo",
  "evals": [
    {
      "id": "case-one",
      "prompt": "Do the demo thing.",
      "expected_output": "It does the demo thing.",
      "files": ["evals/files/input.txt"],
      "assertions": ["The output mentions the demo thing", "The output is polite"]
    }
  ]
}
JSON

FAKE="$TMP/fake-runner"
cat >"$FAKE" <<'FAKE_EOF'
#!/usr/bin/env bash
mode="plain"
for arg in "$@"; do [ "$arg" = "--plugin-dir" ] && mode="skill"; done
prompt="$(cat)"
printf '%s|%s\n' "$mode" "$*" >>"$FAKE_CALL_LOG"
echo '{"type":"system","subtype":"init"}'
if [ "$mode" = "skill" ]; then
  echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"skillet-eval:demo"}}]}}'
fi
case "$prompt" in
  *"grading one agent response"*)
    echo '{"type":"result","result":"{\"results\":[{\"text\":\"a\",\"passed\":true,\"evidence\":\"quote\"},{\"text\":\"b\",\"passed\":true,\"evidence\":\"\"}]}","usage":{"input_tokens":1,"output_tokens":1}}' ;;
  *)
    ls >/dev/null
    [ -f evals/files/input.txt ] && staged=staged || staged=missing
    echo "{\"type\":\"result\",\"result\":\"demo thing $mode $staged\",\"duration_ms\":10,\"usage\":{\"input_tokens\":100,\"output_tokens\":20}}" ;;
esac
FAKE_EOF
chmod +x "$FAKE"
export FAKE_CALL_LOG="$TMP/calls.log"

out="$(bash "$FIX/tests/run-skill-evals.sh" --live 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "--live without a skill-id is refused" || fail "--live without id rc=$rc"
[ ! -e "$FAKE_CALL_LOG" ] && pass "refusal spent no model call" || fail "refusal still invoked the runner"

out="$(bash "$FIX/tests/run-skill-evals.sh" --live demo --runner "$TMP/does-not-exist" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "missing runner is a setup error" || fail "missing runner rc=$rc"

out="$(bash "$FIX/tests/run-skill-evals.sh" --live demo --runner "$FAKE" --model testmodel --timeout 30 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "--live run exits 0" || fail "--live rc=$rc: $out"
IT="$FIX/.skill-eval-workspace/demo/iteration-1"
[ "$(wc -l <"$FAKE_CALL_LOG")" -eq 2 ] && pass "two passes per case (with and without)" || fail "expected 2 runner calls, got $(wc -l <"$FAKE_CALL_LOG")"
grep -q '^skill|' "$FAKE_CALL_LOG" && grep -q '^plain|' "$FAKE_CALL_LOG" && pass "only the with-skill arm gets --plugin-dir" || fail "arms are not differentiated"
grep -q -- '--disallowedTools Task,Agent' "$FAKE_CALL_LOG" && pass "Task and Agent are disallowed" || fail "Task/Agent not disallowed"
grep -q -- '--model testmodel' "$FAKE_CALL_LOG" && pass "model is configurable" || fail "model flag missing"
[ -f "$IT/eval-case-one/with_skill/plugin/skills/demo/SKILL.md" ] && pass "with-skill arm loads the skill" || fail "skill not copied into the arm"
[ ! -e "$IT/eval-case-one/with_skill/plugin/skills/demo/evals" ] && [ ! -e "$IT/eval-case-one/with_skill/plugin/skills/demo/tests" ] && pass "assertions and tests are withheld from the arm" || fail "evals/ or tests/ leaked into the arm"
grep -q 'demo thing skill staged' "$IT/eval-case-one/with_skill/outputs/response.md" && pass "files are staged and the response is captured" || fail "with_skill response wrong: $(cat "$IT/eval-case-one/with_skill/outputs/response.md" 2>/dev/null)"
python3 -I - "$IT" <<'PY' && pass "timing and benchmark artifacts are written" || fail "artifact shape is wrong"
import json, sys
from pathlib import Path
it = Path(sys.argv[1])
timing = json.loads((it / "eval-case-one/with_skill/timing.json").read_text())
assert timing["status"] == "ok" and timing["total_tokens"] == 120, timing
assert timing["skills_called"] == ["skillet-eval:demo"], timing
bench = json.loads((it / "benchmark.json").read_text())
assert bench["run_summary"]["delta"]["pass_rate"] is None
grading = json.loads((it / "eval-case-one/with_skill/grading.json").read_text())
assert grading["summary"]["status"] == "not_graded"
PY

rm -f "$FAKE_CALL_LOG"
out="$(bash "$FIX/tests/run-skill-evals.sh" --live demo --runner "$FAKE" --grade 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "--live --grade exits 0" || fail "--grade rc=$rc: $out"
[ "$(wc -l <"$FAKE_CALL_LOG")" -eq 4 ] && pass "--grade adds one judge pass per arm" || fail "expected 4 runner calls with --grade, got $(wc -l <"$FAKE_CALL_LOG")"
python3 -I - "$FIX/.skill-eval-workspace/demo/iteration-2" <<'PY' && pass "a pass without evidence is downgraded to a fail" || fail "grading result is wrong"
import json, sys
from pathlib import Path
grading = json.loads((Path(sys.argv[1]) / "eval-case-one/with_skill/grading.json").read_text())
rows = grading["assertion_results"]
assert [r["passed"] for r in rows] == [True, False], rows
assert grading["summary"]["pass_rate"] == 0.5, grading["summary"]
PY

out="$(bash "$FIX/tests/run-skill-evals.sh" --dry-run demo 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ -f "$FIX/.skill-eval-workspace/demo/iteration-dry-run/plan.json" ] && pass "--dry-run behavior is unchanged" || fail "dry-run rc=$rc"
out="$(bash "$FIX/tests/run-skill-evals.sh" --validate demo 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "--validate behavior is unchanged" || fail "validate rc=$rc: $out"

if [ "$FAILURES" -ne 0 ]; then
  echo "[fail] run-skill-evals --live: $FAILURES failure(s)"
  exit 1
fi
echo "[ok] run-skill-evals --live"
