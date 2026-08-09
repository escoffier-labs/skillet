#!/usr/bin/env bash
# lint-evals.sh [skill-id]
# Validate skillet.evals.v1 manifests under skillet/skills/*/evals/evals.json.
# Absence of evals/ is allowed. Presence must match docs/specs/2026-08-08-skill-evals.md.
# With no argument, also runs structural self-tests. Exits non-zero on any failure.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skillet/skills"
FAIL=0
MANIFEST_COUNT=0

validate_manifest() {
  local skill_dir="$1"
  local skill_id
  skill_id="$(basename "$skill_dir")"
  local manifest="$skill_dir/evals/evals.json"

  if [ ! -f "$manifest" ]; then
    return 0
  fi
  MANIFEST_COUNT=$((MANIFEST_COUNT + 1))

  if ! python3 - "$manifest" "$skill_id" "$skill_dir" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
skill_id = sys.argv[2]
skill_dir = Path(sys.argv[3])


def fail(msg):
    print(f"[fail] {skill_id}: {msg}", file=sys.stderr)
    raise SystemExit(1)


try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    fail(f"evals/evals.json is not valid JSON: {exc}")

if not isinstance(data, dict):
    fail("evals/evals.json must be a JSON object")

schema = data.get("schema_version")
if schema != "skillet.evals.v1":
    fail(f"schema_version must be 'skillet.evals.v1', got {schema!r}")

name = data.get("skill_name")
if name != skill_id:
    fail(f"skill_name {name!r} does not match directory {skill_id!r}")

evals = data.get("evals")
if not isinstance(evals, list) or not evals:
    fail("evals must be a non-empty array")

seen_ids = set()
for index, case in enumerate(evals):
    prefix = f"evals[{index}]"
    if not isinstance(case, dict):
        fail(f"{prefix} must be an object")

    case_id = case.get("id")
    if isinstance(case_id, bool) or not isinstance(case_id, (int, str)):
        fail(f"{prefix}.id must be an integer or string")
    if isinstance(case_id, str) and not case_id.strip():
        fail(f"{prefix}.id must be non-empty")
    if case_id in seen_ids:
        fail(f"duplicate eval id {case_id!r}")
    seen_ids.add(case_id)

    prompt = case.get("prompt")
    if not isinstance(prompt, str) or not prompt.strip():
        fail(f"{prefix}.prompt must be a non-empty string")

    expected = case.get("expected_output")
    if not isinstance(expected, str) or not expected.strip():
        fail(f"{prefix}.expected_output must be a non-empty string")

    files = case.get("files", [])
    if files is None:
        files = []
    if not isinstance(files, list):
        fail(f"{prefix}.files must be an array when present")
    for file_index, rel in enumerate(files):
        if not isinstance(rel, str) or not rel.strip():
            fail(f"{prefix}.files[{file_index}] must be a non-empty string")
        if Path(rel).is_absolute() or rel.startswith("../") or "/../" in f"/{rel}/":
            fail(f"{prefix}.files[{file_index}] must be a path under the skill directory")
        target = (skill_dir / rel).resolve()
        try:
            target.relative_to(skill_dir.resolve())
        except ValueError:
            fail(f"{prefix}.files[{file_index}] escapes the skill directory")
        if not target.is_file():
            fail(f"{prefix}.files[{file_index}] missing: {rel}")

    assertions = case.get("assertions")
    if not isinstance(assertions, list) or not assertions:
        fail(f"{prefix}.assertions must be a non-empty array (skillet.evals.v1)")
    for assertion_index, assertion in enumerate(assertions):
        if not isinstance(assertion, str) or not assertion.strip():
            fail(f"{prefix}.assertions[{assertion_index}] must be a non-empty string")

raise SystemExit(0)
PY
  then
    return 1
  fi
  echo "[ok] evals/$skill_id"
  return 0
}

run_self_tests() {
  local tmp fixture_root skill_dir manifest output
  tmp="$(mktemp -d)"
  fixture_root="$tmp/repo"
  mkdir -p "$fixture_root/tests" "$fixture_root/skillet/skills"
  cp "$ROOT/tests/lint-evals.sh" "$fixture_root/tests/lint-evals.sh"
  skill_dir="$fixture_root/skillet/skills/fixture-skill"
  mkdir -p "$skill_dir/evals/files"
  printf '%s\n' '{"id":"fixture-skill","version":"0.1.0","tests":["true"],"trust_level":"workspace"}' \
    >"$skill_dir/skill.json"
  : >"$skill_dir/SKILL.md"
  : >"$skill_dir/CHANGELOG.md"
  manifest="$skill_dir/evals/evals.json"

  run_fixture() {
    LINT_EVALS_SKIP_SELF_TESTS=1 bash "$fixture_root/tests/lint-evals.sh" "$@"
  }

  assert_fixture_rejected() {
    local label="$1" expected="$2"
    if output="$(run_fixture fixture-skill 2>&1)"; then
      echo "[fail] self-test: $label was accepted"
      rm -rf "$tmp"
      return 1
    fi
    if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
      echo "[fail] self-test: $label did not mention $expected"
      printf '%s\n' "$output" >&2
      rm -rf "$tmp"
      return 1
    fi
    return 0
  }

  printf '%s\n' '{not json' >"$manifest"
  assert_fixture_rejected "malformed JSON" "not valid JSON" || return 1

  printf '%s\n' '{
    "schema_version": "skillet.evals.v1",
    "skill_name": "other-skill",
    "evals": [{"id": 1, "prompt": "p", "expected_output": "e", "assertions": ["a"]}]
  }' >"$manifest"
  assert_fixture_rejected "wrong skill_name" "does not match directory" || return 1

  printf '%s\n' '{
    "schema_version": "skillet.evals.v1",
    "skill_name": "fixture-skill",
    "evals": [{"id": 1, "prompt": "p", "expected_output": "e", "files": ["evals/files/missing.txt"], "assertions": ["a"]}]
  }' >"$manifest"
  assert_fixture_rejected "missing fixture file" "missing: evals/files/missing.txt" || return 1

  printf '%s\n' '{
    "schema_version": "skillet.evals.v1",
    "skill_name": "fixture-skill",
    "evals": [{"id": 1, "prompt": "p", "expected_output": "e", "assertions": []}]
  }' >"$manifest"
  assert_fixture_rejected "empty assertions" "assertions must be a non-empty array" || return 1

  printf 'fixture\n' >"$skill_dir/evals/files/ok.txt"
  printf '%s\n' '{
    "schema_version": "skillet.evals.v1",
    "skill_name": "fixture-skill",
    "evals": [{
      "id": "happy",
      "prompt": "do the thing",
      "expected_output": "thing done",
      "files": ["evals/files/ok.txt"],
      "assertions": ["output mentions done"]
    }]
  }' >"$manifest"
  if ! output="$(run_fixture fixture-skill 2>&1)"; then
    echo "[fail] self-test: valid manifest was rejected"
    printf '%s\n' "$output" >&2
    rm -rf "$tmp"
    return 1
  fi
  printf '%s\n' "$output" | grep -Fq "[ok] evals/fixture-skill" || {
    echo "[fail] self-test: valid manifest missing ok line"
    printf '%s\n' "$output" >&2
    rm -rf "$tmp"
    return 1
  }

  rm -rf "$tmp"
  echo "[ok] evals self-tests"
  return 0
}

if [ "$#" -ge 1 ]; then
  id="$1"
  dir="$SKILLS_DIR/$id"
  if [ ! -d "$dir" ]; then
    echo "[fail] unknown skill: $id"
    exit 1
  fi
  validate_manifest "$dir" || FAIL=1
else
  if [ "${LINT_EVALS_SKIP_SELF_TESTS:-0}" != "1" ]; then
    run_self_tests || FAIL=1
  fi
  for d in "$SKILLS_DIR"/*/; do
    validate_manifest "$d" || FAIL=1
  done
  echo "[ok] evals ($MANIFEST_COUNT manifests)"
fi

exit $FAIL
